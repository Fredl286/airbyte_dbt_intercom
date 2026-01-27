with companies as (
    select *
    from {{ ref('stg_intercom__companies') }}
),
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