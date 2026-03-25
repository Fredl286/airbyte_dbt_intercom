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

        -- EXISTING FIELDS
        ROUND(TO_NUMBER(c.custom_attributes:"Surplus"::string), 2) as surplus,
        ROUND(TO_NUMBER(c.custom_attributes:"Vulcan Surplus"::string), 2) as vulcan_surplus,
        ROUND(TO_NUMBER(c.custom_attributes:"Total Unsecured Debt VSAPI"::string), 2) as total_unsecured_debt_vsapi,
        ROUND(TO_NUMBER(c.custom_attributes:"Total Household Income"::string), 2) as total_household_income,
        ROUND(TO_NUMBER(c.custom_attributes:"Total Household Expenditure"::string), 2) as total_household_expenditure,

        -- NEW BUDGET FIELDS (already present)
        ROUND(TO_NUMBER(c.custom_attributes:"monthly buildings and content insurance cost"::string), 2)
            as monthly_buildings_and_content_insurance_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Child Maintenance Payment"::string), 2)
            as monthly_child_maintenance_payment,
        ROUND(TO_NUMBER(c.custom_attributes:"monthly childcare costs"::string), 2)
            as monthly_childcare_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Clothing Cost"::string), 2)
            as monthly_clothing_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Council Tax Amount"::string), 2)
            as monthly_council_tax_amount,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Electric Cost"::string), 2)
            as monthly_electric_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Energy Costs"::string), 2)
            as monthly_energy_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"monthly fuel costs"::string), 2)
            as monthly_fuel_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Gas Cost"::string), 2)
            as monthly_gas_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Groceries Cost"::string), 2)
            as monthly_groceries_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Hobbies and Leisure Costs"::string), 2)
            as monthly_hobbies_and_leisure_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Income"::string), 2)
            as monthly_income,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Internet and Subscription Costs"::string), 2)
            as monthly_internet_and_subscription_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Life Insurance Cost"::string), 2)
            as monthly_life_insurance_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Medical Costs"::string), 2)
            as monthly_medical_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Mortgage Amount"::string), 2)
            as monthly_mortgage_amount,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Public Transport Costs"::string), 2)
            as monthly_public_transport_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Rent Amount"::string), 2)
            as monthly_rent_amount,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly TV Licence Cost"::string), 2)
            as monthly_tv_licence_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly TV, Internet and Subscription costs"::string), 2)
            as monthly_tv_internet_and_subscription_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Vehicle Finance Costs"::string), 2)
            as monthly_vehicle_finance_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Vehicle Insurance Cost"::string), 2)
            as monthly_vehicle_insurance_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Vehicle Tax Cost"::string), 2)
            as monthly_vehicle_tax_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Monthly Water Cost"::string), 2)
            as monthly_water_cost,

        -- EXISTING NON-MONTHLY FIELDS
        ROUND(TO_NUMBER(c.custom_attributes:"Buildings and Contents"::string), 2)
            as buildings_and_contents,
        ROUND(TO_NUMBER(c.custom_attributes:"Bundle Costs"::string), 2)
            as bundle_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Car Maintenance"::string), 2)
            as car_maintenance,
        ROUND(TO_NUMBER(c.custom_attributes:"car maintenance cost"::string), 2)
            as car_maintenance_cost,
        ROUND(TO_NUMBER(c.custom_attributes:"Child Maintenance"::string), 2)
            as child_maintenance,
        ROUND(TO_NUMBER(c.custom_attributes:"Clothing and Footwear"::string), 2)
            as clothing_and_footwear,
        ROUND(TO_NUMBER(c.custom_attributes:"Council Tax"::string), 2)
            as council_tax,
        ROUND(TO_NUMBER(c.custom_attributes:"Electric"::string), 2)
            as electric,
        ROUND(TO_NUMBER(c.custom_attributes:"Fuel"::string), 2)
            as fuel,
        ROUND(TO_NUMBER(c.custom_attributes:"Gas"::string), 2)
            as gas,
        ROUND(TO_NUMBER(c.custom_attributes:"Gas and Electric"::string), 2)
            as gas_and_electric,
        ROUND(TO_NUMBER(c.custom_attributes:"Groceries"::string), 2)
            as groceries,
        ROUND(TO_NUMBER(c.custom_attributes:"Hair Costs"::string), 2)
            as hair_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Life Insurance"::string), 2)
            as life_insurance,
        ROUND(TO_NUMBER(c.custom_attributes:"Medical Prescriptions"::string), 2)
            as medical_prescriptions,
        ROUND(TO_NUMBER(c.custom_attributes:"Mortgage"::string), 2)
            as mortgage,
        ROUND(TO_NUMBER(c.custom_attributes:"Phone Costs"::string), 2)
            as phone_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Rent"::string), 2)
            as rent,
        ROUND(TO_NUMBER(c.custom_attributes:"TV Licence"::string), 2)
            as tv_licence,
        c.custom_attributes:"Type of Benefit"::string
            as type_of_benefit,
        ROUND(TO_NUMBER(c.custom_attributes:"Vehicle Finance"::string), 2)
            as vehicle_finance,
        ROUND(TO_NUMBER(c.custom_attributes:"Vehicle Insurance"::string), 2)
            as vehicle_insurance,
        ROUND(TO_NUMBER(c.custom_attributes:"Vehicle Tax"::string), 2)
            as vehicle_tax,
        ROUND(TO_NUMBER(c.custom_attributes:"Water"::string), 2)
            as water,

        -- ⭐ NEW FIELDS YOU REQUESTED ⭐
        ROUND(TO_NUMBER(c.custom_attributes:"Childcare Costs"::string), 2)
            as childcare_costs,
        ROUND(TO_NUMBER(c.custom_attributes:"Hobbies and Leisure"::string), 2)
            as hobbies_and_leisure,
        ROUND(TO_NUMBER(c.custom_attributes:"Public Transport"::string), 2)
            as public_transport

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
    ct.vulcan_id,
    ct.phone,
    ct.email,
    ct.surplus,
    ct.vulcan_surplus,
    ct.total_unsecured_debt_vsapi,
    ct.total_household_income,
    ct.total_household_expenditure,

    -- MONTHLY FIELDS
    ct.monthly_buildings_and_content_insurance_cost,
    ct.monthly_child_maintenance_payment,
    ct.monthly_childcare_costs,
    ct.monthly_clothing_cost,
    ct.monthly_council_tax_amount,
    ct.monthly_electric_cost,
    ct.monthly_energy_costs,
    ct.monthly_fuel_costs,
    ct.monthly_gas_cost,
    ct.monthly_groceries_cost,
    ct.monthly_hobbies_and_leisure_costs,
    ct.monthly_income,
    ct.monthly_internet_and_subscription_costs,
    ct.monthly_life_insurance_cost,
    ct.monthly_medical_costs,
    ct.monthly_mortgage_amount,
    ct.monthly_public_transport_costs,
    ct.monthly_rent_amount,
    ct.monthly_tv_licence_cost,
    ct.monthly_tv_internet_and_subscription_costs,
    ct.monthly_vehicle_finance_costs,
    ct.monthly_vehicle_insurance_cost,
    ct.monthly_vehicle_tax_cost,
    ct.monthly_water_cost,

    -- NON-MONTHLY FIELDS
    ct.buildings_and_contents,
    ct.bundle_costs,
    ct.car_maintenance,
    ct.car_maintenance_cost,
    ct.child_maintenance,
    ct.clothing_and_footwear,
    ct.council_tax,
    ct.electric,
    ct.fuel,
    ct.gas,
    ct.gas_and_electric,
    ct.groceries,
    ct.hair_costs,
    ct.life_insurance,
    ct.medical_prescriptions,
    ct.mortgage,
    ct.phone_costs,
    ct.rent,
    ct.tv_licence,
    ct.type_of_benefit,
    ct.vehicle_finance,
    ct.vehicle_insurance,
    ct.vehicle_tax,
    ct.water,

    -- ⭐ NEW FIELDS ⭐
    ct.childcare_costs,
    ct.hobbies_and_leisure,
    ct.public_transport

from pivoted p
left join contacts ct
  on p.contact_id = ct.contact_id