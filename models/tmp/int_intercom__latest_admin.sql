with admins as (
    select *
    from {{ ref('stg_intercom__admins') }}
),

latest_admin as (
    select
        *,
        row_number() over(partition by admin_id order by _airbyte_extracted_at desc) as latest_admin_index
    from admins
)

select *
from latest_admin
where latest_admin_index = 1
