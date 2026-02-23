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
    where t.value:"name"::string in (
        'Auto UG | Error',
        'AUTO UG - Not Sent',
        'Auto UG - DMP/DAS',
        'auto ug | error | no debt level',
        'Auto UG | Error 19-02-26',
        'aug echo',
        'Auto UG - Short Time To Repay',
        'Auto UG - Zero Offer'
    )
),

contacts as (
    select distinct
        c.id as contact_id,
        nullif(rtrim(c.custom_attributes:"vulcan_id"::string), '') as vulcan_id,
        c.phone,
        c.email
    from {{ source('airbyte_intercom','contacts') }} c
),

pivoted as (
    select
        te.conversation_id,
        te.contact_id,
        max(to_timestamp(te.applied_at_unix)) as latest_tag_time,
        listagg(distinct te.tag_name, ', ') as tags_applied
    from tags_exploded te
    group by te.conversation_id, te.contact_id
)

select
    p.conversation_id,
    p.contact_id,
    p.latest_tag_time,
    p.tags_applied,
    ct.vulcan_id,
    ct.phone,
    ct.email
from pivoted p
left join contacts ct
  on p.contact_id = ct.contact_id