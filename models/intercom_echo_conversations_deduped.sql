{{ config(materialized='table') }}

with base as (
    select *
    from {{ ref('intercom_echo_conversations') }}
),

scored as (
    select
        *,
        case when completed_at is not null then 2 else 0 end
        + case when vulcan_id is not null then 1 else 0 end
        as score
    from base
),

ranked as (
    select
        *,
        row_number() over (
            partition by conversation_id
            order by score desc, completed_at desc, started_at desc
        ) as rn
    from scored
),

deduped as (
    select *
    from ranked
    where rn = 1
),

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
    from deduped
)

select * from cleaned