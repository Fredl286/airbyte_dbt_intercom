with raw as (
    select *
    from {{ source('airbyte_intercom','conversations') }}
),

tags_exploded as (
    select distinct
        r.id as conversation_id,
        t.value:"name"::string as tag_name,
        t.value:"applied_at"::bigint as applied_at_unix,
        to_timestamp(t.value:"applied_at"::bigint) as tag_applied_at,
        r.contacts:"contacts"[0]:"id"::string as contact_id
    from raw r,
         lateral flatten(input => r.tags:"tags") t
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
        ct.total_debt as total_debt_form,
        ct.total_debt_with_ccjs,
        coalesce(ct.total_debt_with_ccjs, ct.total_unsecured_debt_vsapi) as "CLEAN_TOTAL_DEBT",
        ct.total_unsecured_debt_vsapi,
        ct.total_household_income,
        ct.total_household_expenditure

    from tags_exploded te
    left join contacts ct
        on te.contact_id = ct.contact_id
)

select *
from final