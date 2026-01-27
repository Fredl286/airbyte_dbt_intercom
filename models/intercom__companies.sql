with companies as (

    select
        company_id,
        company_name,
        created_at_timestamp,
        industry,
        monthly_spend,
        session_count,
        updated_at_timestamp,
        user_count,
        website,
        "_AIRBYTE_RAW_ID" as raw_id   -- 👈 quoted and aliased
    from {{ ref('int_intercom__latest_company') }}

)

select * from companies