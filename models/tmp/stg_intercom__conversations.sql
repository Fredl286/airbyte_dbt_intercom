with conversations as (

    select
        id as conversation_id,
        created_at as created_at_timestamp,
        updated_at as updated_at_timestamp,
        {{ dbt_date.from_unixtimestamp('created_at') }} as created_at_date,
        {{ dbt_date.from_unixtimestamp('updated_at') }} as updated_at_date,
        type as conversation_type,
        title as conversation_title,
        state as conversation_state,
        read as is_read,

        -- Extract nested JSON fields from VARIANT columns
        conversation_rating:rating::integer as conversation_rating_value,
        conversation_rating:remark::string as conversation_remark,

        sla_applied:sla_name::string as sla_name,
        sla_applied:sla_status::string as sla_status,

        assignee:id::string as assignee_id,
        assignee:name::string as assignee_name,
        assignee:type::string as assignee_type,
        assignee:email::string as assignee_email,

        statistics:last_closed_by_id::string as last_closed_by_id,

        _AIRBYTE_RAW_ID
    from {{ source('airbyte_intercom','conversations') }}

)

select *
from conversations