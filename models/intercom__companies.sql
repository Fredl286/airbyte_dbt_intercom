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
        airbyte_unique_id as raw_id
    from {{ ref('int_intercom__latest_company') }}
)

select * from companies