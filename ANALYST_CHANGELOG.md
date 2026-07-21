# Analyst Change Log

Purpose: Track only data/model changes that analysts can see in reporting outputs.

## Analyst Action Required

### 1. Update Dataset References

Use the renamed datasets in reporting queries/models:

- `fct_intercom__admin_metrics`
- `fct_intercom__conversations`
- `fct_intercom__conversation_metrics`
- `fct_intercom__echo_conversations`
- `fct_intercom__echo_conversations_deduped`
- `fct_intercom__echo_budget_items`
- `fct_intercom__echo_budget_items_deduped`
- `fct_intercom__d2a_conversations`
- `fct_intercom__conversations_alltags`
- `fct_intercom__useful_guides_ugtags`
- `dim_intercom__contacts`

Removed outputs:

- `echo_dd`
- companies transformed datasets (raw source still available)

### 2. Update Field References

- Use `d2a_flag` (lowercase).
- Join IDs are standardized as string IDs (`VARCHAR(50)`):
  - `conversation_id`
  - `contact_id`
  - `vulcan_id`

### 3. Expect Metric Shifts

- Budget GBP amounts now retain pence (`NUMBER(38,2)`) instead of being rounded to whole pounds.
- Totals and aggregates over budget fields may differ from historical outputs that used integer rounding.

## 2026-07-21

### Change Set 1 - ID Standardization Across Analyst Models

Files changed:
- fct_intercom__echo_conversations
- fct_intercom__echo_conversations_deduped
- fct_intercom__echo_budget_items
- fct_intercom__echo_budget_items_deduped
- fct_intercom__d2a_conversations
- fct_intercom__conversations_alltags
- fct_intercom__useful_guides_ugtags

What changed:
- Standardized key join identifiers to a consistent string format (`VARCHAR(50)`):
  - `conversation_id`
  - `contact_id`
  - `vulcan_id`

Potential reporting impact:
- Joins between these models and external systems should be more reliable.
- Some previously blank/whitespace IDs may now appear as null.

Validation status:
- Structural/type change; validate in dbt Cloud run.

### Change Set 2 - Naming and Dataset Rationalization

Files changed:
- `echo_dd` removed
- Custom marts renamed to consistent lowercase `fct_intercom__*`
- Legacy `intercom__*` marts converted to `fct_`/`dim_` naming where retained

What changed:
- Removed redundant output table (`echo_dd`) to avoid duplicate analyst endpoints.
- Standardized model names and prefixes for clearer discovery in BI.
- Standardized `d2a_flag` column naming to lowercase.
- Corrected contact extraction path in D2A model.

Potential reporting impact:
- Any existing queries using old model names must be updated to new names.
- Case-sensitive consumers need to reference `d2a_flag` (lowercase).

Validation status:
- Structural rename change; validate in dbt Cloud run.

### Change Set 3 - Companies Dataset Removed from Transformed Layer

Files changed:
- Companies staging/intermediate/dimension models removed

What changed:
- Removed transformed companies outputs due low volume and low analytical value.
- Raw companies source data remains available if needed later.

Potential reporting impact:
- Any downstream use of transformed companies model must be removed/replaced.

Validation status:
- Structural removal; validate in dbt Cloud run.

### Change Set 4 - Budget Currency Precision Correction

Files changed:
- fct_intercom__echo_budget_items
- fct_intercom__echo_budget_items_deduped

What changed:
- Changed GBP amount parsing and output typing to 2 decimal places (`NUMBER(38,2)`).
- Replaced prior whole-number rounding behavior for budget monetary fields.

Potential reporting impact:
- Monetary totals now include pence and may differ from earlier integer-rounded reports.

Validation status:
- Structural/type correction; validate totals in dbt Cloud run.
