with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),

tags_exploded as (
    select distinct
        r.id as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        r.contacts:"contacts"[0]:"id"::string as contact_id
    from raw r,
         lateral flatten(input => r.tags:"tags") t
    where t.value:"name"::string in ('Started ECHO Main', 'Completed ECHO Main')
),

contacts as (
    select
        c.id as contact_id,
        c.custom_attributes
    from {{ source('airbyte_intercom','contacts') }} c
),

pivoted as (
    select
        te.conversation_id,
        te.contact_id,
        max(case when te.tag_name = 'Started ECHO Main'
                 then to_timestamp(te.applied_at_unix) end) as started_at,
        max(case when te.tag_name = 'Completed ECHO Main'
                 then to_timestamp(te.applied_at_unix) end) as completed_at,
        listagg(distinct te.tag_name, ', ') within group (order by te.applied_at_unix) as tags_applied
    from tags_exploded te
    group by te.conversation_id, te.contact_id
),

transformed as (
    select
        p.conversation_id,
        p.contact_id,
        p.started_at,
        p.completed_at,
        p.tags_applied,
        coalesce(rtrim(ct.custom_attributes:"vulcan_id"::string), '') as vulcan_id
    from pivoted p
    left join contacts ct
      on p.contact_id = ct.contact_id
)

select * from transformed
