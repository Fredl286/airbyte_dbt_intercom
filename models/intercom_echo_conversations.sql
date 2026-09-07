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
        'Started ECHO Main',
        'Completed ECHO main',
        '15K+ Agent (C) 31Mar26 Split test',
        '33% Helpline Triage Split test 15k D2A 09-07-2026 (A)'
    )
),
-- ensure one row per contact_id
contacts as (
    select distinct
        c.id as contact_id,
        cast(nullif(rtrim(c.custom_attributes:"vulcan_id"::string), '') as varchar(50)) as vulcan_id,
        c.phone,
        c.email,
        CAST(ROUND(TRY_TO_DECIMAL(c.custom_attributes:"Surplus"::string, 18, 2), 2) AS NUMBER(18,2)) as surplus,
        CAST(ROUND(TRY_TO_DECIMAL(c.custom_attributes:"Vulcan Surplus"::string, 18, 2), 2) AS NUMBER(18,2)) as vulcan_surplus,
        CAST(ROUND(TRY_TO_DECIMAL(c.custom_attributes:"total_debt"::string, 18, 2), 2) AS NUMBER(18,2)) as total_debt,
        CAST(ROUND(TRY_TO_DECIMAL(c.custom_attributes:"TotalUnsecuredAndCcjs"::string, 18, 2), 2) AS NUMBER(18,2)) as total_debt_with_ccjs,
        CAST(ROUND(TRY_TO_DECIMAL(c.custom_attributes:"Total Unsecured Debt VSAPI"::string, 18, 2), 2) AS NUMBER(18,2)) as total_unsecured_debt_vsapi,
        CAST(ROUND(TRY_TO_DECIMAL(c.custom_attributes:"Total Household Income"::string, 18, 2), 2) AS NUMBER(18,2)) as total_household_income,
        CAST(ROUND(TRY_TO_DECIMAL(c.custom_attributes:"Total Household Expenditure"::string, 18, 2), 2) AS NUMBER(18,2)) as total_household_expenditure
    from {{ source('airbyte_intercom','contacts') }} c
),
pivoted as (
    select
        te.conversation_id,
        te.contact_id,
        max(case when te.tag_name = 'Started ECHO Main'
                 then to_timestamp(te.applied_at_unix) end) as started_at,
        max(case when te.tag_name = 'Completed ECHO main'
                 then to_timestamp(te.applied_at_unix) end) as completed_at,
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
    ct.total_debt as total_debt_form,
    ct.total_unsecured_debt_vsapi,
    ct.total_debt_with_ccjs,
    ct.total_household_income,
    ct.total_household_expenditure
from pivoted p
left join contacts ct
  on p.contact_id = ct.contact_id