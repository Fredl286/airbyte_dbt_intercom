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

-- ensure one row per contact_id
contacts as (
    select distinct
        c.id as contact_id,
        nullif(rtrim(c.custom_attributes:"vulcan_id"::string), '') as vulcan_id,
        c.phone,
        c.email,

        -- EXISTING FIELDS (no rounding)
        TO_NUMBER(c.custom_attributes:"Surplus"::string) as surplus,
        TO_NUMBER(c.custom_attributes:"Vulcan Surplus"::string) as vulcan_surplus,
        TO_NUMBER(c.custom_attributes:"Total Unsecured Debt VSAPI"::string) as total_unsecured_debt_vsapi,
        TO_NUMBER(c.custom_attributes:"Total Household Income"::string) as total_household_income,
        TO_NUMBER(c.custom_attributes:"Total Household Expenditure"::string) as total_household_expenditure,

        -- NEW BUDGET FIELDS (already present)
        TO_NUMBER(c.custom_attributes:"monthly buildings and content insurance cost"::string)
            as monthly_buildings_and_content_insurance_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Child Maintenance Payment"::string)
            as monthly_child_maintenance_payment,
        TO_NUMBER(c.custom_attributes:"monthly childcare costs"::string)
            as monthly_childcare_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Clothing Cost"::string)
            as monthly_clothing_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Council Tax Amount"::string)
            as monthly_council_tax_amount,
        TO_NUMBER(c.custom_attributes:"Monthly Electric Cost"::string)
            as monthly_electric_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Energy Costs"::string)
            as monthly_energy_costs,
        TO_NUMBER(c.custom_attributes:"monthly fuel costs"::string)
            as monthly_fuel_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Gas Cost"::string)
            as monthly_gas_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Groceries Cost"::string)
            as monthly_groceries_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Hobbies and Leisure Costs"::string)
            as monthly_hobbies_and_leisure_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Income"::string)
            as monthly_income,
        TO_NUMBER(c.custom_attributes:"Monthly Internet and Subscription Costs"::string)
            as monthly_internet_and_subscription_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Life Insurance Cost"::string)
            as monthly_life_insurance_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Medical Costs"::string)
            as monthly_medical_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Mortgage Amount"::string)
            as monthly_mortgage_amount,
        TO_NUMBER(c.custom_attributes:"Monthly Public Transport Costs"::string)
            as monthly_public_transport_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Rent Amount"::string)
            as monthly_rent_amount,
        TO_NUMBER(c.custom_attributes:"Monthly TV Licence Cost"::string)
            as monthly_tv_licence_cost,
        TO_NUMBER(c.custom_attributes:"Monthly TV, Internet and Subscription costs"::string)
            as monthly_tv_internet_and_subscription_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Vehicle Finance Costs"::string)
            as monthly_vehicle_finance_costs,
        TO_NUMBER(c.custom_attributes:"Monthly Vehicle Insurance Cost"::string)
            as monthly_vehicle_insurance_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Vehicle Tax Cost"::string)
            as monthly_vehicle_tax_cost,
        TO_NUMBER(c.custom_attributes:"Monthly Water Cost"::string)
            as monthly_water_cost,

        TO_NUMBER(c.custom_attributes:"Buildings and Contents"::string) as buildings_and_contents,
        TO_NUMBER(c.custom_attributes:"Bundle Costs"::string) as bundle_costs,
        TO_NUMBER(c.custom_attributes:"Car Maintenance"::string) as car_maintenance,
        TO_NUMBER(c.custom_attributes:"car maintenance cost"::string) as car_maintenance_cost,
        TO_NUMBER(c.custom_attributes:"Child Maintenance"::string) as child_maintenance,
        TO_NUMBER(c.custom_attributes:"Clothing and Footwear"::string) as clothing_and_footwear,
        TO_NUMBER(c.custom_attributes:"Council Tax"::string) as council_tax,
        TO_NUMBER(c.custom_attributes:"Electric"::string) as electric,
        TO_NUMBER(c.custom_attributes:"Fuel"::string) as fuel,
        TO_NUMBER(c.custom_attributes:"Gas"::string) as gas,
        TO_NUMBER(c.custom_attributes:"Gas and Electric"::string) as gas_and_electric,
        TO_NUMBER(c.custom_attributes:"Groceries"::string) as groceries,
        TO_NUMBER(c.custom_attributes:"Hair Costs"::string) as hair_costs,
        TO_NUMBER(c.custom_attributes:"Life Insurance"::string) as life_insurance,
        TO_NUMBER(c.custom_attributes:"Medical Prescriptions"::string) as medical_prescriptions,
        TO_NUMBER(c.custom_attributes:"Mortgage"::string) as mortgage,
        TO_NUMBER(c.custom_attributes:"Phone Costs"::string) as phone_costs,
        TO_NUMBER(c.custom_attributes:"Rent"::string) as rent,
        TO_NUMBER(c.custom_attributes:"TV Licence"::string) as tv_licence,
        c.custom_attributes:"Type of Benefit"::string as type_of_benefit,
        TO_NUMBER(c.custom_attributes:"Vehicle Finance"::string) as vehicle_finance,
        TO_NUMBER(c.custom_attributes:"Vehicle Insurance"::string) as vehicle_insurance,
        TO_NUMBER(c.custom_attributes:"Vehicle Tax"::string) as vehicle_tax,
        TO_NUMBER(c.custom_attributes:"Water"::string) as water,
        TO_NUMBER(c.custom_attributes:"Childcare Costs"::string) as childcare_costs,
        TO_NUMBER(c.custom_attributes:"Hobbies and Leisure"::string) as hobbies_and_leisure,
        TO_NUMBER(c.custom_attributes:"Public Transport"::string) as public_transport,
        TO_NUMBER(c.custom_attributes:"TV, Internet and Subscriptions"::string) as tv_internet_and_subscriptions

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

    ct.*

from pivoted p
left join contacts ct
  on p.contact_id = ct.contact_id;
