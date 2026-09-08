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

-- 5. Add daily grouping (same-day dedupe restored)
daily_scored as (
    select
        *,
        date(started_at) as started_date,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id_filled is not null then 1 else 0 end
        as daily_score
    from vulcan_backfilled
),

-- 6. Dedupe per contact_id per day
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

-- 7. Dedupe per contact_id per day per phone+email
phone_email_scored as (
    select
        *,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id_filled is not null then 1 else 0 end
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

deduped_phone_email as (
    select *
    from ranked_phone_email
    where rn_pe = 1
),

-- 8. Dedupe per contact_id per day per vulcan_id
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
            partition by contact_id, started_date, vulcan_id_filled
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
        coalesce(d2a_flag, 0)::int as D2A_FLAG,
        vulcan_id_filled as vulcan_id,
        phone,
        email,
        surplus,
        vulcan_surplus,
        total_debt_form,
        total_unsecured_debt_vsapi as total_unsecured_debt,
        total_debt_with_ccjs,
        coalesce(total_debt_with_ccjs, total_unsecured_debt_vsapi) as "CLEAN_TOTAL_DEBT",
        total_household_income,
        total_household_expenditure

    from ranked_vulcan
    where rn_vulcan = 1
)

select * from cleaned