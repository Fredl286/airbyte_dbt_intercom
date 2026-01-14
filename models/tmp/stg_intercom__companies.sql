select
    id as company_id,
    name as company_name,
    created_at as created_at_timestamp,
    updated_at as updated_at_timestamp,
    industry,
    monthly_spend,
    session_count,
    user_count,
    website,
    -- use the actual Airbyte metadata columns instead of the missing hashid
    _AIRBYTE_RAW_ID as airbyte_unique_id,
    _AIRBYTE_EXTRACTED_AT as airbyte_extracted_at
from {{ var('companies') }}
