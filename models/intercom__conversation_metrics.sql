with conversations as (
    select *
    from {{ ref('intercom__conversations') }}
),

part_aggregates as (
    select *
    from {{ ref('int_intercom__conversation_part_aggregates') }}
),

metrics as (
    select
        c.conversation_id,
        c.conversation_type,
        c.conversation_state,
        c.assignee_type,
        c.sla_status,
        c.conversation_rating,
        c.last_closed_by_id,

        -- bring in aggregates
        pa.total_parts as count_total_parts,
        pa.first_part_date,
        pa.last_part_date,

        -- example metrics
        datediff(day, c.created_at_timestamp, c.updated_at_timestamp) as days_open,
        datediff(hour, c.created_at_timestamp, c.updated_at_timestamp) as hours_open
    from conversations c
    left join part_aggregates pa
      on c.conversation_id = pa.conversation_id
)

select *
from metrics