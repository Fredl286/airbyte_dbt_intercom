{{ config(materialized='table') }}

with base as (
    select *
    from {{ ref('intercom_echo_conversations') }}
    where email not ilike '%payplan.com%'
      and email not ilike '%@test.com%'
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
)

select
    conversation_id,
    contact_id,
    started_at,
    completed_at,
    tags_applied,
    vulcan_id,
    phone,
    email
from ranked
where rn = 1