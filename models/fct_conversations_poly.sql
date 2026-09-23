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
    where (
        t.value:"name"::string in (
            'Poly consent asked',
            'Poly start',
            'Poly complete'
        )
        or t.value:"name"::string ilike 'auto ug%'
        or t.value:"name"::string ilike 'poly auto-ug%'
        or t.value:"name"::string = 'aug echo'
    )
),
contacts as (
    select distinct
        {{ normalize_id('c.id') }} as contact_id,
        {{ normalize_id('c.custom_attributes:"vulcan_id"') }} as vulcan_id,
        {{ normalize_id('c.phone') }} as phone,
        coalesce(nullif(c.email, ''), c.custom_attributes:"Email address"::string) as email,
        {{ safe_to_number_26_2('c.custom_attributes:"Surplus"::string') }} as surplus,
        {{ safe_to_number_26_2('c.custom_attributes:"Vulcan Surplus"::string') }} as vulcan_surplus,
        {{ safe_to_number_26_2('c.custom_attributes:"total_debt"::string') }} as total_debt_form,
        {{ safe_to_number_26_2('c.custom_attributes:"TotalUnsecuredAndCcjs"::string') }} as total_debt_with_ccjs,
        {{ safe_to_number_26_2('c.custom_attributes:"Total Unsecured Debt VSAPI"::string') }} as total_unsecured_debt_vsapi,
        coalesce(total_debt_with_ccjs, total_unsecured_debt_vsapi) as clean_total_debt,
        {{ safe_to_number_26_2('c.custom_attributes:"Total Household Income"::string') }} as total_household_income,
        {{ safe_to_number_26_2('c.custom_attributes:"Total Household Expenditure"::string') }} as total_household_expenditure
    from {{ source('airbyte_intercom','contacts') }} c
),
pivoted as (
    select
        te.conversation_id,
        te.contact_id,
        max(case when te.tag_name = 'Poly consent asked'
                 then {{ epoch_to_timestamp('te.applied_at_unix') }} end) as consent_asked_at,
        max(case when te.tag_name = 'Poly start'
                 then {{ epoch_to_timestamp('te.applied_at_unix') }} end) as started_at,
        max(case when te.tag_name = 'Poly complete'
                 then {{ epoch_to_timestamp('te.applied_at_unix') }} end) as completed_at,
        max(case when te.tag_name ilike 'auto ug%' or te.tag_name ilike 'poly auto-ug%' or te.tag_name = 'aug echo'
                 then {{ epoch_to_timestamp('te.applied_at_unix') }} end) as auto_ug_at,
        max(case when te.tag_name ilike 'auto ug%' or te.tag_name ilike 'poly auto-ug%' or te.tag_name = 'aug echo'
                 then 1 else 0 end) as auto_ug_flag,
        listagg(distinct case when te.tag_name ilike 'auto ug%' or te.tag_name ilike 'poly auto-ug%' or te.tag_name = 'aug echo'
                 then te.tag_name end, ', ') within group (order by case when te.tag_name ilike 'auto ug%' or te.tag_name ilike 'poly auto-ug%' or te.tag_name = 'aug echo' then te.tag_name end) as ug_tags_applied,
        listagg(distinct te.tag_name, ', ') as tags_applied
    from tags_exploded te
    group by te.conversation_id, te.contact_id
    having max(case when te.tag_name in ('Poly consent asked', 'Poly start', 'Poly complete')
                    then 1 else 0 end) = 1
)
select
    p.conversation_id,
    p.contact_id,
    p.consent_asked_at,
    p.started_at,
    p.completed_at,
    p.auto_ug_at,
    p.auto_ug_flag,
    p.ug_tags_applied,
    p.tags_applied,
    ct.vulcan_id,
    ct.phone,
    ct.email,
    ct.vulcan_surplus,
    ct.total_debt_form,
    ct.total_debt_with_ccjs,
    ct.total_unsecured_debt_vsapi,
        ct.clean_total_debt
from pivoted p
left join contacts ct
  on p.contact_id = ct.contact_id