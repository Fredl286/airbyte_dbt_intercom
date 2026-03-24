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
    where t.value:"name"::string in ('Started ECHO Main', 'Completed ECHO main')
),

-- EXPAND ALL CUSTOM ATTRIBUTES
contact_attributes as (
    select
        c.id as contact_id,
        c.phone,
        c.email,
        c.custom_attributes,
        attr.key::string as attribute_name,
        attr.value::string as attribute_value
    from {{ source('airbyte_intercom','contacts') }} c,
         lateral flatten(input => c.custom_attributes) attr
),

-- PIVOT ALL ATTRIBUTES INTO COLUMNS
pivoted_attributes as (
    select *
    from contact_attributes
    pivot (
        max(attribute_value) for attribute_name in (
            -- dynamically generate list of attribute names
            {{ dbt_utils.get_column_values(
                table=source('airbyte_intercom','contacts'),
                column='custom_attributes',
                flatten_json=True
            ) }}
        )
    )
),

pivoted as (
    select
        te.conversation_id,
        te.contact_id,
        max(case when te.tag_name = 'Started ECHO Main'
                 then to_timestamp(te.applied_at_unix) end) as started_at,
        max(case when te.tag_name = 'Completed ECHO main'
                 then to_timestamp(te.applied_at_unix) end) as completed_at,
        listagg(distinct te.tag_name, ', ') as tags_applied
    from tags_exploded te
    group by te.conversation_id, te.contact_id
)

select
    p.conversation_id,
    p.contact_id,
    p.started_at,
    p.completed_at,
    p.tags_applied,
    pa.*
from pivoted p
left join pivoted_attributes pa
  on p.contact_id = pa.contact_id
