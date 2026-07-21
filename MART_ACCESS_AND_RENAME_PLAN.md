# Mart Access and Model Rename Plan

Purpose: Record implemented naming/access standards and the remaining checks before promotion.

## Target Layering

- Raw layer: Airbyte landing tables in source schemas (outside dbt model naming).
- Staging layer: `stg_*` models, source-shaped and lightly cleaned.
- Intermediate layer: `int_*` models, joins and reusable transformations.
- Mart layer: analyst-facing models only:
  - `fct_*` for measurable events.
  - `dim_*` for descriptive entities.
  - `bridge_*` for many-to-many mappings where needed.
  - `rpt_*` for presentation/consumer-specific wide tables.

## Access Policy

- Analysts: read access to mart schema only.
- Analytics engineering: read/write access to staging, intermediate, and mart schemas.
- BI tools: point semantic models to mart schema only.

## Implemented Model Set

Mart models currently present:

- models/fct_intercom__admin_metrics.sql
- models/dim_intercom__contacts.sql
- models/fct_intercom__conversations.sql
- models/fct_intercom__conversation_metrics.sql
- models/fct_intercom__echo_conversations.sql
- models/fct_intercom__echo_conversations_deduped.sql
- models/fct_intercom__echo_budget_items.sql
- models/fct_intercom__echo_budget_items_deduped.sql
- models/fct_intercom__d2a_conversations.sql
- models/fct_intercom__conversations_alltags.sql
- models/fct_intercom__useful_guides_ugtags.sql
- models/fct_intercom__customer_response_times.sql
- models/fct_intercom__agent_only_responses_3_months.sql

Removed model outputs:

- models/echo_dd.sql
- transformed companies chain (staging/intermediate/dimension)

Internal support models:

- models/tmp/stg_intercom__admins.sql
- models/tmp/stg_intercom__contacts.sql
- models/tmp/stg_intercom__conversation_parts.sql
- models/tmp/stg_intercom__conversations.sql
- models/tmp/int_intercom__latest_contact.sql
- models/tmp/int_intercom__latest_conversation.sql
- models/tmp/int_intercom__conversation_part_aggregates.sql

## Analyst Exposure Recommendation

Expose these models in mart schema:

- fct_intercom__conversations
- fct_intercom__conversation_metrics
- fct_intercom__admin_metrics
- dim_intercom__contacts
- fct_intercom__echo_conversations_deduped
- fct_intercom__echo_budget_items_deduped
- fct_intercom__d2a_conversations
- fct_intercom__customer_response_times
- fct_intercom__agent_only_responses_3_months

Keep these internal only:

- All `stg_*` and `int_*`
- Raw Airbyte sources

## Test Deployment Sequence

1. Configure test outputs to isolated schemas:
  - `intercom_staging_schema = INTERCOM_STAGING_UAT`
  - `intercom_mart_schema = INTERCOM_ANALYTICS_UAT`
2. Run dbt build in test environment.
3. Validate key marts for row count changes and null-rate changes on IDs.
4. Validate budget marts retain 2dp currency fields.
5. Smoke-test BI queries on exposed marts.
6. Promote to production only after analyst sign-off.

## Acceptance Checks

- No downstream query failures in BI.
- Identical or expected row counts for deduped marts.
- Joins on `vulcan_id`, `contact_id`, `conversation_id` remain stable.
- Analysts confirm semantic clarity of marts.
