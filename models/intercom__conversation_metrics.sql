with conversations as (
    select *
    from {{ ref('intercom__conversations') }}
),

metrics as (
    select
        conversation_id,
        conversation_type,
        conversation_state,
        assignee_type,
        sla_status,
        conversation_rating,
        -- Example metric: time between creation and last update
        datediff(day, created_at_timestamp, updated_at_timestamp) as days_open,
        datediff(hour, created_at_timestamp, updated_at_timestamp) as hours_open
    from conversations
)

select *
from metrics