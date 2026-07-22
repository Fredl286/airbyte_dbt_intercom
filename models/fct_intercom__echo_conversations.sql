with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),
tags_exploded as (
    select distinct
        {{ normalize_id('r.id') }} as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        {{ normalize_id('r.contacts:"contacts"[0]:"id"') }} as contact_id
    from raw r,
         lateral flatten(input => r.tags:"tags") t
    where t.value:"name"::string in (
        'Started ECHO Main',
        'Completed ECHO main',
        '15K+ Agent (C) 31Mar26 Split test',
        '33% Helpline Triage Split test 15k D2A 09-07-2026 (A)'
    )
),
contacts as (
    select distinct
        {{ normalize_id('c.id') }} as contact_id,
        {{ normalize_id('c.custom_attributes:"vulcan_id"') }} as vulcan_id,
        c.phone,
        c.email,
        {{ safe_to_number_38_2('c.custom_attributes:"Surplus"::string') }} as surplus,
        {{ safe_to_number_38_2('c.custom_attributes:"Vulcan Surplus"::string') }} as vulcan_surplus,
        {{ safe_to_number_38_2('c.custom_attributes:"Total Unsecured Debt VSAPI"::string') }} as total_unsecured_debt_vsapi,
        {{ safe_to_number_38_2('c.custom_attributes:"Total Household Income"::string') }} as total_household_income,
        {{ safe_to_number_38_2('c.custom_attributes:"Total Household Expenditure"::string') }} as total_household_expenditure
    from {{ source('airbyte_intercom','contacts') }} c
),
pivoted as (
    select
        te.conversation_id,
        te.contact_id,
        max(case when te.tag_name = 'Started ECHO Main'
                 then {{ epoch_to_timestamp('te.applied_at_unix') }} end) as started_at,
        max(case when te.tag_name = 'Completed ECHO main'
                 then {{ epoch_to_timestamp('te.applied_at_unix') }} end) as completed_at,
        max(case when te.tag_name in (
                    '15K+ Agent (C) 31Mar26 Split test',
                    '33% Helpline Triage Split test 15k D2A 09-07-2026 (A)'
                 )
                 then 1 else 0 end) as d2a_flag,
        listagg(distinct te.tag_name, ', ') as tags_applied
    from tags_exploded te
    group by te.conversation_id, te.contact_id
    having max(case when te.tag_name in ('Started ECHO Main', 'Completed ECHO main')
                    then 1 else 0 end) = 1
)
select
    p.conversation_id,
    p.contact_id,
    p.started_at,
    p.completed_at,
    p.d2a_flag,
    p.tags_applied,
    ct.vulcan_id,
    ct.phone,
    ct.email,
    ct.surplus,
    ct.vulcan_surplus,
    ct.total_unsecured_debt_vsapi,
    ct.total_household_income,
    ct.total_household_expenditure
from pivoted p
left join contacts ct
  on p.contact_id = ct.contact_id