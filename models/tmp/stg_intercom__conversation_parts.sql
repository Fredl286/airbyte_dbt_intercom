with conversation_parts as (

    select
        {{ normalize_id('id') }} as part_id,
        {{ normalize_id('conversation_id') }} as conversation_id,

        -- raw epoch values
        created_at as created_at_epoch,
        updated_at as updated_at_epoch,

        -- converted to TIMESTAMP
        {{ epoch_to_timestamp('created_at') }} as created_at_timestamp,
        {{ epoch_to_timestamp('updated_at') }} as updated_at_timestamp,

        -- also expose as *_date for downstream models that expect that alias
        {{ epoch_to_timestamp('created_at') }} as created_at_date,
        {{ epoch_to_timestamp('updated_at') }} as updated_at_date,

        AUTHOR:id::string as author_id,
        AUTHOR:type::string as author_type,

        body,
        part_type,
        _AIRBYTE_RAW_ID
    from {{ source('airbyte_intercom','conversation_parts') }}

)

select *
from conversation_parts