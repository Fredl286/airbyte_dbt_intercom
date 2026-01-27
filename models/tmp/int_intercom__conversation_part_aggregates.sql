with conversation_parts as (
    select
        conversation_id,
        part_id,
        author_id,
        created_at_timestamp,
        updated_at_timestamp,
        created_at_date,
        updated_at_date
    from {{ ref('stg_intercom__conversation_parts') }}
),

latest_conversation as (
    select *
    from {{ ref('int_intercom__latest_conversation') }}
),

aggregates as (
    select
        cp.conversation_id,
        count(*) as count_total_parts,              -- ✅ renamed to match downstream
        min(cp.created_at_timestamp) as first_part_timestamp,
        max(cp.updated_at_timestamp) as last_part_timestamp,
        min(cp.created_at_date) as first_part_date,
        max(cp.updated_at_date) as last_part_date,
        lc.updated_at_timestamp as latest_conversation_timestamp,
        lc.updated_at_date as latest_conversation_date
    from conversation_parts cp
    join latest_conversation lc
      on cp.conversation_id = lc.conversation_id
    group by cp.conversation_id, lc.updated_at_timestamp, lc.updated_at_date
)

select *
from aggregates