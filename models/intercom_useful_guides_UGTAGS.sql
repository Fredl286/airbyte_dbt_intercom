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

-- pick the newest version of each contact
contacts as (
    select *
    from (
        select
            c.id as contact_id,
            nullif(rtrim(c.custom_attributes:"vulcan_id"::string), '') as vulcan_id,
            c.phone,
            c.email,

            -- CORRECT ATTRIBUTE NAMES + 2 DECIMAL FORMATTING
            ROUND(TO_NUMBER(c.custom_attributes:"Surplus"::string), 2) as surplus,
            ROUND(TO_NUMBER(c.custom_attributes:"Vulcan Surplus"::string), 2) as vulcan_surplus,
            ROUND(TO_NUMBER(c.custom_attributes:"Total Unsecured Debt VSAPI"::string), 2) as total_unsecured_debt_vsapi,
            ROUND(TO_NUMBER(c.custom_attributes:"Total Household Income"::string), 2) as total_household_income,
            ROUND(TO_NUMBER(c.custom_attributes:"Total Household Expenditure"::string), 2) as total_household_expenditure,

            row_number() over (
                partition by c.id
                order by c.updated_at desc nulls last
            ) as rn

        from {{ source('airbyte_intercom','contacts') }} c
    )
    where rn = 1
),

pivoted as (
    select
        te.conversation_id,
        te.contact_id,
        max(to_timestamp(te.applied_at_unix)) as latest_tag_time,
        listagg(distinct te.tag_name, ', ') as tags_applied
    from tags_exploded te
    group by te.conversation_id, te.contact_id
),

-- dedupe at conversation level: keep the most complete row
final as (
    select *
    from (
        select
            p.conversation_id,
            p.contact_id,
            p.latest_tag_time,
            p.tags_applied,

            ct.vulcan_id,
            ct.phone,
            ct.email,
            ct.surplus,
            ct.vulcan_surplus,
            ct.total_unsecured_debt_vsapi,
            ct.total_household_income,
            ct.total_household_expenditure,

            -- NEW FLAGS
            case when ct.surplus >= 35 then 1 else 0 end as surplus_flag,
            case when ct.total_unsecured_debt_vsapi >= 3000 then 1 else 0 end as debt_flag,

            -- completeness score
            (
                (case when ct.email is not null then 1 else 0 end) +
                (case when ct.surplus is not null then 1 else 0 end) +
                (case when ct.vulcan_surplus is not null then 1 else 0 end) +
                (case when ct.total_unsecured_debt_vsapi is not null then 1 else 0 end) +
                (case when ct.total_household_income is not null then 1 else 0 end) +
                (case when ct.total_household_expenditure is not null then 1 else 0 end)
            ) as completeness_score,

            row_number() over (
                partition by p.conversation_id
                order by 
                    (
                        (case when ct.email is not null then 1 else 0 end) +
                        (case when ct.surplus is not null then 1 else 0 end) +
                        (case when ct.vulcan_surplus is not null then 1 else 0 end) +
                        (case when ct.total_unsecured_debt_vsapi is not null then 1 else 0 end) +
                        (case when ct.total_household_income is not null then 1 else 0 end) +
                        (case when ct.total_household_expenditure is not null then 1 else 0 end)
                    ) desc
            ) as rn

        from pivoted p
        left join contacts ct
          on p.contact_id = ct.contact_id
    )
    where rn = 1
)

select *
from final