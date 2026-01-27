with latest_conversation as (

    select
        conversation_id,
        created_at_timestamp,
        updated_at_timestamp,
        updated_at_date,
        conversation_type,
        conversation_title,
        conversation_state,
        is_read,
        conversation_rating_value,
        conversation_remark,
        sla_name,
        sla_status,
        assignee_id,
        assignee_name,
        assignee_type,
        assignee_email,
        last_closed_by_id,
        _AIRBYTE_RAW_ID
    from {{ ref('stg_intercom__conversations') }}

    -- Get the most recent conversation by updated_at
    qualify row_number() over (
        partition by conversation_id
        order by updated_at_timestamp desc
    ) = 1

)

select *
from latest_conversation