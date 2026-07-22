with admin_table as (
    select *
    from {{ ref('stg_intercom__admins') }}
),

conversation_metrics as (
    select *
    from {{ ref('fct_intercom__conversation_metrics') }}
),

admin_conversation_metrics as (
    select
        a.admin_id,
        a.name as admin_name,
        a.job_title,
        cm.conversation_state,
        cm.conversation_rating,
        cm.count_reopens,
        cm.count_total_parts,
        cm.count_assignments,
        cm.time_to_first_response_minutes,
        cm.time_to_last_close_minutes
    from admin_table a
    left join conversation_metrics cm
        on cm.last_closed_by_id = a.admin_id
),

final as (
    select
        admin_id,
        admin_name,
        job_title,
        sum(case when conversation_state = 'closed' then 1 else 0 end) as total_conversations_closed,
        avg(count_total_parts) as average_conversation_parts,
        avg(conversation_rating) as average_conversation_rating,
        median(count_reopens) as median_conversations_reopened,
        median(count_assignments) as median_conversation_assignments,
        median(time_to_first_response_minutes) as median_time_to_first_response_time_minutes,
        median(time_to_last_close_minutes) as median_time_to_last_close_minutes
    from admin_conversation_metrics
    group by 1, 2, 3
)

select * from final