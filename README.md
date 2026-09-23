# Intercom Analytics dbt Project

This project transforms Intercom data landed by Airbyte into analyst-facing models in Snowflake.

## Data Flow

1. Airbyte syncs raw Intercom tables into the configured source database/schema.
2. dbt staging and intermediate models normalize payload fields and timestamps.
3. dbt mart models produce analyst-facing fact and dimension tables.

## Naming Conventions

- `stg_*`: source-shaped staging models.
- `int_*`: reusable intermediate transformations.
- `fct_*`: event/metric models at a defined business grain.
- `dim_*`: descriptive entity models for slicing facts.

Additional standards used in marts:

- IDs are normalized to `VARCHAR(50)` using `normalize_id(...)` (this includes `phone`).
- Budget/currency fields are normalized to `NUMBER(26,2)` using `safe_to_number_26_2(...)`.
- Contact email falls back to custom attributes when blank: `coalesce(nullif(c.email, ''), c.custom_attributes:"Email address"::string)`.
- Auto-UG tags are matched by pattern rather than a hardcoded list, so new tag variants don't require code changes: `tag_name ilike 'auto ug%'`, `tag_name ilike 'poly auto-ug%'`, or `tag_name = 'aug echo'`.

Macro files:

- `macros/id_normalization.sql`
- `macros/numeric_normalization.sql`
- `macros/echo_dedupe.sql`
- `macros/epoch_to_timestamp.sql`
- `macros/generate_schema_name.sql`

## ECHO Dedupe Logic

The ECHO/Poly deduped models use a shared macro to enforce consistent conversion logic:

- `fct_conversations_echo_dd`
- `fct_echo_budget_items_dd`
- `fct_conversations_poly_dd`

Macro used:

- `echo_poly_dedupe_rows(...)` in `macros/echo_dedupe.sql`

Current behavior:

1. Filter out internal/test emails (`%payplan.com%`, `%@test.com%`, `%@payplanpolyconvo.com%`, `%@payplanpolyconvo.co.uk%`).
2. Merge records with the same `conversation_id` so split rows are consolidated:
	- `started_at` keeps the earliest non-null value.
	- `completed_at` keeps the latest non-null value.
	- `tags_applied` is combined across rows (distinct values).
	- `auto_ug_flag` (1/0) and `ug_tags_applied` (distinct list of matching tags) track whether any Auto-UG tag was applied, alongside `auto_ug_at`.
3. Build a person key using this fallback order:
	- `contact_id`, then `email`, then `phone`, then `conversation_id`.
4. Keep one record per person per day (`person_key` + `event_date`).
5. Ranking priority is strict (not weighted blending):
	- records with `completed_at` first,
	- then records with `vulcan_id` (or filled Vulcan ID),
	- then records with more populated completeness fields,
	- then latest timestamps as tie-breakers.

This ensures conversion reporting prefers completed and Vulcan-linked ECHO records, even when another record has more non-critical fields populated.

## Current Mart Models

Primary models currently in use:

- `dim_contacts`
- `dim_admins`
- `dim_teams`
- `dim_segments`
- `dim_contact_attributes`
- `dim_tags`
- `fct_admin_metrics`
- `fct_conversations`
- `fct_conversations_metrics`
- `fct_customer_response_times`
- `fct_agent_only_responses_3_months`
- `fct_conversations_echo`
- `fct_conversations_echo_dd`
- `fct_echo_budget_items`
- `fct_echo_budget_items_dd`
- `fct_conversations_d2a`
- `fct_conversations_alltags`
- `fct_conversations_autoug`
- `fct_conversations_poly`
- `fct_conversations_poly_dd`

## Dependencies

Defined in `packages.yml`:

- `fivetran/fivetran_utils`
- `godatadriven/dbt_date`

`package-lock.yml` is committed for reproducible dependency resolution.

## Configuration

Project variables in `dbt_project.yml`:

- `intercom_schema`
- `intercom_database`
- `intercom_mart_schema`
- `intercom_staging_schema`


Schema Structure:

- Keep raw data in `AIRBYTE_SCHEMA`.
- Build `models/tmp/*` into `INTERCOM_STAGING`.
- Build mart models into `INTERCOM_ANALYTICS`.