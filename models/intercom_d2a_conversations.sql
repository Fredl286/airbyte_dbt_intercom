with raw as (

    select *
    from {{ source('airbyte_intercom','conversations') }}

),

tags_exploded as (

    select distinct
        r.id as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        r.contacts:"contacts""id"::string as contact_id
    from raw r,
         lateral flatten(input => r.tags:"tags") t
    where t.value:"name"::string in (
        '15K+ Agent (C) 31Mar26 Split test',
        '33% Helpline Triage Split Test 15k D2A 09-07-2026 (A)'
    )

),

-- ensure one row per contact_id
contacts as (

    select distinct
        c.id as contact_id,

        nullif(
            trim(lower(c.custom_attributes:"vulcan_id"::string)),
            ''
        )::varchar(50) as vulcan_id,

        c.phone,
        c.email,

        round(try_to_number(c.custom_attributes:"Surplus"::string), 2) as surplus,
        round(try_to_number(c.custom_attributes:"Vulcan Surplus"::string), 2) as vulcan_surplus,
        round(try_to_number(c.custom_attributes:"Total Unsecured Debt VSAPI"::string), 2) as total_unsecured_debt_vsapi,
        round(try_to_number(c.custom_attributes:"Total Household Income"::string), 2) as total_household_income,
        round(try_to_number(c.custom_attributes:"Total Household Expenditure"::string), 2) as total_household_expenditure

    from {{ source('airbyte_intercom','contacts') }} c

),

pivoted as (

    select
        te.conversation_id,
        te.contact_id,

        max(
            case
                when te.tag_name in (
                    '15K+ Agent (C) 31Mar26 Split test',
                    '33% Helpline Triage Split Test 15k D2A 09-07-2026 (A)'
                )
                then to_timestamp(te.applied_at_unix)
            end
        ) as d2a_at,

        listagg(distinct te.tag_name, ', ') as tags_applied

    from tags_exploded te
    group by te.conversation_id, te.contact_id

)

select
    p.conversation_id,
    p.contact_id,
    p.d2a_at as d2a_at,
    p.tags_applied,

    ct.vulcan_id::varchar(50) as vulcan_id,

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