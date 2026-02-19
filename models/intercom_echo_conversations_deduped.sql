{{ config(materialized='table') }}

-- 1. Base table
with base as (
    select *
    from {{ ref('intercom_echo_conversations') }}
),

-- 2. Score for conversation-level dedupe
scored as (
    select
        *,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id is not null then 1 else 0 end
        as score
    from base
),

-- 3. Pick best row per conversation_id
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

-- 4. Add daily grouping
daily_scored as (
    select
        *,
        date(started_at) as started_date,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id is not null then 1 else 0 end
        as daily_score
    from deduped_conversation
),

-- 5. Dedupe per contact_id per day
ranked_daily as (
    select
        *,
        row_number() over (
            partition by contact_id, started_date
            order by daily_score desc, completed_at desc, started_at desc
        ) as rn_daily
    from daily_scored
),

deduped_daily as (
    select *
    from ranked_daily
    where rn_daily = 1
),

-- 6. NEW: dedupe per contact_id per day per phone+email
phone_email_scored as (
    select
        *,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id is not null then 1 else 0 end
        as pe_score
    from deduped_daily
),

ranked_phone_email as (
    select
        *,
        row_number() over (
            partition by contact_id, started_date, phone, email
            order by pe_score desc, completed_at desc, started_at desc
        ) as rn_pe
    from phone_email_scored
),

-- 7. Email cleaning AFTER all deduping
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
    from ranked_phone_email
    where rn_pe = 1
)

select * from cleaned
