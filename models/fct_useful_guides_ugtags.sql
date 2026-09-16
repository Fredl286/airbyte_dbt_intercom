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
    select *
    from (
        select
            {{ normalize_id('c.id') }} as contact_id,
            {{ normalize_id('c.custom_attributes:"vulcan_id"') }} as vulcan_id,
            c.phone,
            c.email,

            {{ safe_to_number_38_2('c.custom_attributes:"Surplus"::string') }} as surplus,
            {{ safe_to_number_38_2('c.custom_attributes:"Vulcan Surplus"::string') }} as vulcan_surplus,
            {{ safe_to_number_38_2('c.custom_attributes:"Total Unsecured Debt VSAPI"::string') }} as total_unsecured_debt_vsapi,
            {{ safe_to_number_38_2('c.custom_attributes:"Total Household Income"::string') }} as total_household_income,
            {{ safe_to_number_38_2('c.custom_attributes:"Total Household Expenditure"::string') }} as total_household_expenditure,

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
        max({{ epoch_to_timestamp('te.applied_at_unix') }}) as latest_tag_time,
        listagg(distinct te.tag_name, ', ') as tags_applied
    from tags_exploded te
    group by te.conversation_id, te.contact_id
),

final as (
    select
        x.conversation_id,
        x.contact_id,
        x.latest_tag_time,
        x.tags_applied,
        x.vulcan_id,
        x.phone,
        x.email,
        x.surplus,
        x.vulcan_surplus,
        x.total_unsecured_debt_vsapi,
        x.total_household_income,
        x.total_household_expenditure,
        x.surplus_flag,
        x.debt_flag
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

            case when ct.surplus >= 35 then 1 else 0 end as surplus_flag,
            case when ct.total_unsecured_debt_vsapi >= 3000 then 1 else 0 end as debt_flag,

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
    ) x
    where x.rn = 1
)

select *
from final