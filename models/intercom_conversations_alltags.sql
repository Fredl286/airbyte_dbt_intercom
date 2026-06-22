with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),

tags_exploded as (
    select
        r.id as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        to_timestamp(t.value:"applied_at"::bigint) as tag_applied_at,
        r.contacts:"contacts"[0]:"id"::string as contact_id
    from raw r,
         lateral flatten(input => r.tags:"tags") t
),

-- optional: deduplicate in case of weird replays
deduped as (
    select distinct
        conversation_id,
        contact_id,
        tag_name,
        tag_applied_at
    from tags_exploded
)

select *
from deduped