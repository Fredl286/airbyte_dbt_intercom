with conversation_parts as (

    select
        id as part_id,
        conversation_id::varchar as conversation_id,

        -- raw epoch values
        created_at as created_at_epoch,
        updated_at as updated_at_epoch,

        -- converted to TIMESTAMP
        {{ dbt_date.from_unixtimestamp('created_at') }} as created_at_timestamp,
        {{ dbt_date.from_unixtimestamp('updated_at') }} as updated_at_timestamp,

        -- also expose as *_date for downstream models that expect that alias
        {{ dbt_date.from_unixtimestamp('created_at') }} as created_at_date,
        {{ dbt_date.from_unixtimestamp('updated_at') }} as updated_at_date,

        AUTHOR:id::string as author_id,
        AUTHOR:type::string as author_type,

        body,
        part_type,
        _AIRBYTE_RAW_ID
    from {{ source('airbyte_intercom','conversation_parts') }}

)

select *
from conversation_parts