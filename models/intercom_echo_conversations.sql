with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),

tags_exploded as (
    select
        r.id as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        r.contacts,
        r.custom_attributes
    from raw r,
         lateral flatten(input => r.tags:"tags") t
    where t.value:"name"::string in ('Started ECHO Main', 'Completed ECHO main')
),

transformed as (
    select
        conversation_id,
        tag_name,
        to_char(to_timestamp(applied_at_unix), 'DD/MM/YYYY HH24:MI:SS') as applied_at,
        coalesce(rtrim(custom_attributes:"Vulcan ID"::string), '') as vulcan_id,
        contacts:"contacts"[0]:"id"::string as contact_id
    from tags_exploded
)

select * from transformed