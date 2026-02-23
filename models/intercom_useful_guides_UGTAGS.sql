with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),

tags_exploded as (
    select
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
)

select
    te.conversation_id,
    te.contact_id,
    te.tag_name,
    to_timestamp(te.applied_at_unix) as tag_applied_at,
    ct.vulcan_id,
    ct.phone,
    ct.email
from tags_exploded te
left join contacts ct
  on te.contact_id = ct.contact_id;
