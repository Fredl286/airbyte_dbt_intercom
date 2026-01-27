with conversation_parts as (
    select
        conversation_id,
        part_id,
        AUTHOR:id::string as author_id,
        AUTHOR:type::string as author_type,
        part_type,
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

        -- total parts
        count(*) as count_total_parts,

        -- reopen and assignment counts
        sum(case when lower(cp.part_type) = 'reopen' then 1 else 0 end) as count_reopens,
        sum(case when lower(cp.part_type) = 'assignment' then 1 else 0 end) as count_assignments,

        -- first/last part timestamps and dates
        min(cp.created_at_timestamp) as first_part_timestamp,
        max(cp.updated_at_timestamp) as last_part_timestamp,
        min(cp.created_at_date) as first_part_date,
        max(cp.updated_at_date) as last_part_date,

        -- time to first admin response (minutes)
        datediff(
            minute,
            min(cp.created_at_timestamp),
            min(case when cp.author_type = 'admin' then cp.created_at_timestamp end)
        ) as time_to_first_response_minutes,

        -- time to last close (minutes)
        datediff(
            minute,
            min(cp.created_at_timestamp),
            max(case when lower(cp.part_type) = 'close' then cp.created_at_timestamp end)
        ) as time_to_last_close_minutes,

        lc.updated_at_timestamp as latest_conversation_timestamp,
        lc.updated_at_date as latest_conversation_date
    from conversation_parts cp
    join latest_conversation lc
      on cp.conversation_id = lc.conversation_id
    group by cp.conversation_id, lc.updated_at_timestamp, lc.updated_at_date
)

select *
from aggregates