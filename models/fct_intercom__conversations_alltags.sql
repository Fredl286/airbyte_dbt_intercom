with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),

tags_exploded as (
    select distinct
        {{ normalize_id('r.id') }} as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        {{ epoch_to_timestamp('t.value:"applied_at"::bigint') }} as tag_applied_at,
        {{ normalize_id('r.contacts:"contacts"[0]:"id"') }} as contact_id
    from raw r,
         lateral flatten(input => r.tags:"tags") t
),

contacts as (
    select distinct
        {{ normalize_id('c.id') }} as contact_id,

        {{ normalize_id('lower(c.custom_attributes:"vulcan_id")') }} as vulcan_id,

        c.phone,
        c.email,

        {{ safe_to_number_38_0('c.custom_attributes:"Surplus"::string') }} as surplus,
        {{ safe_to_number_38_0('c.custom_attributes:"Vulcan Surplus"::string') }} as vulcan_surplus,
        {{ safe_to_number_38_0('c.custom_attributes:"Total Unsecured Debt VSAPI"::string') }} as total_unsecured_debt_vsapi,
        {{ safe_to_number_38_0('c.custom_attributes:"Total Household Income"::string') }} as total_household_income,
        {{ safe_to_number_38_0('c.custom_attributes:"Total Household Expenditure"::string') }} as total_household_expenditure

    from {{ source('airbyte_intercom','contacts') }} c
),

final as (
    select
        te.conversation_id,
        te.contact_id,
        te.tag_name,
        te.tag_applied_at,

        ct.vulcan_id,
        ct.phone,
        ct.email,
        ct.surplus,
        ct.vulcan_surplus,
        ct.total_unsecured_debt_vsapi,
        ct.total_household_income,
        ct.total_household_expenditure

    from tags_exploded te
    left join contacts ct
        on te.contact_id = ct.contact_id
)

select *
from final