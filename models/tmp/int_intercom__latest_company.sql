with companies as (

    -- Pull in all the necessary fields from the staging model,
    -- making sure to include _AIRBYTE_RAW_ID explicitly
    select
        _AIRBYTE_RAW_ID,
        company_id,
        company_name,
        created_at_timestamp,
        updated_at_timestamp,
        industry,
        monthly_spend,
        session_count,
        user_count,
        website
    from {{ ref('stg_intercom__companies') }}

),

-- Returns the most recent company record by creating a row number
-- ordered by the updated_at_timestamp date, then filtering to only
-- return the #1 row per company.
latest_company as (

    select
        companies.*,
        row_number() over (
            partition by company_id
            order by updated_at_timestamp desc
        ) as latest_company_index
    from companies

)

select *
from latest_company
where latest_company_index = 1