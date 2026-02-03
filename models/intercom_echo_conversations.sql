with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),

tags_exploded as (
    select
        r.id as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        r.contacts
    from raw r,
         lateral flatten(input => r.tags:"tags") t
    where t.value:"name"::string in ('Started ECHO Main', 'Completed ECHO Main')
),

-- join to contacts to get latest custom_attributes
contacts as (
    select
        c.id as contact_id,
        c.custom_attributes
    from {{ source('airbyte_intercom','contacts') }} c
),

transformed as (
    select
        te.conversation_id,
        te.tag_name,
        to_timestamp(te.applied_at_unix) as applied_at,
        coalesce(rtrim(ct.custom_attributes:"vulcan_id"::string), '') as vulcan_id,
        te.contacts:"contacts"[0]:"id"::string as contact_id
    from tags_exploded te
    left join contacts ct
      on te.contacts:"contacts"[0]:"id"::string = ct.contact_id
)

select * from transformed