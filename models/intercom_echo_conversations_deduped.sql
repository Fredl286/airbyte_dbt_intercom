{{ config(materialized='table') }}

-- 1. Base table WITH SAFE REMOVAL of test/internal emails
with base as (
    select *
    from {{ ref('intercom_echo_conversations') }}
    where coalesce(email, '') not ilike '%payplan.com%'
      and coalesce(email, '') not ilike '%@test.com%'
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

-- 4. Backfill vulcan_id from other rows for the same contact/day
vulcan_backfilled as (
    select
        *,
        coalesce(
            vulcan_id,
            max(vulcan_id) over (
                partition by contact_id, date(started_at)
            )
        ) as vulcan_id_filled
    from deduped_conversation
),

-- 5. Create 3-day grouping key
three_day_grouped as (
    select
        *,
        floor(datediff('day', '1970-01-01', started_at) / 3) as three_day_group
    from vulcan_backfilled
),

-- 6. Dedupe per contact_id per 3-day window
ranked_3day as (
    select
        *,
        row_number() over (
            partition by contact_id, three_day_group
            order by 
                case when completed_at is not null then 2 else 0 end
              + case when vulcan_id_filled is not null then 1 else 0 end desc,
                completed_at desc,
                started_at desc
        ) as rn_3day
    from three_day_grouped
),

deduped_3day as (
    select *
    from ranked_3day
    where rn_3day = 1
),

-- 7. Dedupe per contact_id per 3-day window per phone+email
phone_email_scored as (
    select
        *,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id_filled is not null then 1 else 0 end
        as pe_score
    from deduped_3day
),

ranked_phone_email as (
    select
        *,
        row_number() over (
            partition by contact_id, three_day_group, phone, email
            order by pe_score desc, completed_at desc, started_at desc
        ) as rn_pe
    from phone_email_scored
),

deduped_phone_email as (
    select *
    from ranked_phone_email
    where rn_pe = 1
),

-- 8. Dedupe per contact_id per 3-day window per vulcan_id
vulcan_scored as (
    select
        *,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id_filled is not null then 1 else 0 end
        as v_score
    from deduped_phone_email
),

ranked_vulcan as (
    select
        *,
        row_number() over (
            partition by contact_id, three_day_group, vulcan_id_filled
            order by v_score desc, completed_at desc, started_at desc
        ) as rn_vulcan
    from vulcan_scored
),

-- 9. Final cleaned output
cleaned as (
    select
        conversation_id,
        contact_id,
        started_at,
        completed_at,
        tags_applied,
        vulcan_id_filled as vulcan_id,
        phone,
        email
    from ranked_vulcan
    where rn_vulcan = 1
)

select * from cleaned