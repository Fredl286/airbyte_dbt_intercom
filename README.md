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

- IDs are normalized to `VARCHAR(50)` using `normalize_id(...)`.
- Budget/currency fields are normalized to `NUMBER(38,2)` using `safe_to_number_38_2(...)`.

Macro files:

- `macros/id_normalization.sql`
- `macros/numeric_normalization.sql`
- `macros/echo_dedupe.sql`
- `macros/epoch_to_timestamp.sql`

## ECHO Dedupe Logic

The ECHO deduped models use a shared macro to enforce consistent conversion logic:

- `fct_intercom__echo_conversations_deduped`
- `fct_intercom__echo_budget_items_deduped`

Macro used:

- `echo_dedupe_rows(...)` in `macros/echo_dedupe.sql`

Current behavior:

1. Filter out internal/test emails (`%payplan.com%`, `%@test.com%`).
2. Merge records with the same `conversation_id` so split rows are consolidated:
	- `started_at` keeps the earliest non-null value.
	- `completed_at` keeps the latest non-null value.
	- `tags_applied` is combined across rows (distinct values).
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

- `dim_intercom__contacts`
- `dim_intercom__admins`
- `dim_intercom__teams`
- `dim_intercom__segments`
- `dim_intercom__contact_attributes`
- `fct_intercom__admin_metrics`
- `fct_intercom__conversations`
- `fct_intercom__conversation_metrics`
- `fct_intercom__customer_response_times`
- `fct_intercom__agent_only_responses_3_months`
- `fct_intercom__echo_conversations`
- `fct_intercom__echo_conversations_deduped`
- `fct_intercom__echo_budget_items`
- `fct_intercom__echo_budget_items_deduped`
- `fct_intercom__d2a_conversations`
- `fct_intercom__conversations_alltags`
- `fct_intercom__useful_guides_ugtags`

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
- Build `models/tmp/*` into `INTERCOM_STAGING_UAT`.
- Build mart models into `INTERCOM_ANALYTICS_UAT`.