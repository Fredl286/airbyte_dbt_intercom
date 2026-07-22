with contact_attributes as (
    select *
    from {{ ref('stg_intercom__contact_attributes') }}
    where attribute_id is not null
),

latest_contact_attribute as (
    select
        *,
        row_number() over(partition by attribute_id order by updated_at_timestamp desc, _airbyte_extracted_at desc) as latest_attribute_index
    from contact_attributes
)

select *
from latest_contact_attribute
where latest_attribute_index = 1
