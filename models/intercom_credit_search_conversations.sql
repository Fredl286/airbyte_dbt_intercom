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
        'Credit Search | KBA & CRA Started',
        'Credit Search | KBA & CRA Failed',
        'Credit Search | KBA & CRA Completed'
    )
),

-- ensure one row per contact_id
contacts as (
    select distinct
        c.id as contact_id,

        nullif(
            trim(lower(c.custom_attributes:"vulcan_id"::string)),
            ''
        )::VARCHAR(50) as vulcan_id,

        c.phone,
        c.email,

        ROUND(TRY_TO_NUMBER(c.custom_attributes:"Surplus"::string), 2) as surplus,
        ROUND(TRY_TO_NUMBER(c.custom_attributes:"Vulcan Surplus"::string), 2) as vulcan_surplus,
        ROUND(TRY_TO_NUMBER(c.custom_attributes:"Total Unsecured Debt VSAPI"::string), 2) as total_unsecured_debt_vsapi,
        ROUND(TRY_TO_NUMBER(c.custom_attributes:"Total Household Income"::string), 2) as total_household_income,
        ROUND(TRY_TO_NUMBER(c.custom_attributes:"Total Household Expenditure"::string), 2) as total_household_expenditure

    from {{ source('airbyte_intercom','contacts') }} c
),

final as (
    select
        te.conversation_id,
        te.contact_id,
        te.tag_name,
        to_timestamp(te.applied_at_unix) as tag_applied_at,

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