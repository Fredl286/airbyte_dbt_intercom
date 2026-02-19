{{ config(materialized='table') }}

-- 1. Base table (no email filtering here)
with base as (
    select *
    from {{ ref('intercom_echo_conversations') }}
),

-- 2. Score each row for conversation-level dedupe
scored as (
    select
        *,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id is not null then 1 else 0 end
        as score
    from base
),

-- 3. Pick the best row per conversation_id
ranked_conversation as (
    select
        *,
        row_number() over (
            partition by conversation_id
            order by score desc, completed_at desc, started_at desc
        ) as rn
    from scored
),

deduped_conversation as (
    select *
    from ranked_conversation
    where rn = 1
),

-- 4. Now dedupe per contact_id per day
scored_daily as (
    select
        *,
        date(started_at) as started_date,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id is not null then 1 else 0 end
        as daily_score
    from deduped_conversation
),

ranked_daily as (
    select
        *,
        row_number() over (
            partition by contact_id, started_date
            order by daily_score desc, completed_at desc, started_at desc
        ) as rn_daily
    from scored_daily
),

-- 5. Apply email cleaning AFTER all deduping
cleaned as (
    select
        conversation_id,
        contact_id,
        started_at,
        completed_at,
        tags_applied,
        vulcan_id,
        phone,
        case
            when email ilike '%payplan.com%' then null
            when email ilike '%@test.com%' then null
            else email
        end as email
    from ranked_daily
    where rn_daily = 1
)

select * from cleaned