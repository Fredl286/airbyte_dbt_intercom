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
        last_closed_by_id,
        datediff(day, created_at_timestamp, updated_at_timestamp) as days_open,
        datediff(hour, created_at_timestamp, updated_at_timestamp) as hours_open,
        count_total_parts,
        count_reopens,
        count_assignments,
        time_to_first_response_minutes
    from conversations
)

select *
from metrics
