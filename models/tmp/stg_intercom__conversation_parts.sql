with conversation_parts as (

    select
        id as part_id,
        conversation_id,
        {{ dbt_date.from_unixtimestamp('created_at') }} as created_at_timestamp,
        {{ dbt_date.from_unixtimestamp('updated_at') }} as updated_at_timestamp,
        author:id::string as author_id,
        body,
        _AIRBYTE_RAW_ID
    from {{ source('airbyte_intercom','conversation_parts') }}

)

select *
from conversation_parts
