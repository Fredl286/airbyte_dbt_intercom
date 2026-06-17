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
    where t.value:"name"::string IN (
        'Auto UG | Error',
        'AUTO UG - Not Sent',
        'Auto UG - DMP/DAS',
        'auto ug | error | no debt level',
        'Auto UG | Error 19-02-26',
        'aug echo',
        'Auto UG - Short Time To Repay',
        'Auto UG - Zero Offer',
        'Started ECHO Main',
        'Completed ECHO main'
    )
),

contacts as (
    select distinct
        c.id as contact_id,
        nullif(rtrim(c.custom_attributes:"vulcan_id"::string), '') as vulcan_id,
        c.phone,
        c.email,

        {{ safe_to_number_2dp('c.custom_attributes:"Surplus"::string') }} as surplus,
        {{ safe_to_number_2dp('c.custom_attributes:"Vulcan surplus"::string') }} as vulcan_surplus,
        {{ safe_to_number_2dp('c.custom_attributes:"Total Unsecured Debt VSAPI"::string') }} as total_unsecured_debt_vsapi,
        {{ safe_to_number_2dp('c.custom_attributes:"Total Household Income"::string') }} as total_household_income,
        {{ safe_to_number_2dp('c.custom_attributes:"Total Household Expenditure"::string') }} as total_household_expenditure,

        {{ safe_to_number_2dp('c.custom_attributes:"monthly buildings and content insurance cost"::string') }} as monthly_buildings_and_content_insurance_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Child Maintenance Payment"::string') }} as monthly_child_maintenance_payment,
        {{ safe_to_number_2dp('c.custom_attributes:"monthly childcare costs"::string') }} as monthly_childcare_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Clothing Cost"::string') }} as monthly_clothing_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Council Tax Amount"::string') }} as monthly_council_tax_amount,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Electric Cost"::string') }} as monthly_electric_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Energy Costs"::string') }} as monthly_energy_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"monthly fuel costs"::string') }} as monthly_fuel_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Gas Cost"::string') }} as monthly_gas_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Groceries Cost"::string') }} as monthly_groceries_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Hobbies and Leisure Costs"::string') }} as monthly_hobbies_and_leisure_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Income"::string') }} as monthly_income,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Internet and Subscription Costs"::string') }} as monthly_internet_and_subscription_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Life Insurance Cost"::string') }} as monthly_life_insurance_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Medical Costs"::string') }} as monthly_medical_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Mortgage Amount"::string') }} as monthly_mortgage_amount,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Public Transport Costs"::string') }} as monthly_public_transport_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Rent Amount"::string') }} as monthly_rent_amount,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly TV Licence Cost"::string') }} as monthly_tv_licence_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly TV, Internet and Subscription costs"::string') }} as monthly_tv_internet_and_subscription_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Vehicle Finance Costs"::string') }} as monthly_vehicle_finance_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Vehicle Insurance Cost"::string') }} as monthly_vehicle_insurance_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Vehicle Tax Cost"::string') }} as monthly_vehicle_tax_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Monthly Water Cost"::string') }} as monthly_water_cost,

        {{ safe_to_number_2dp('c.custom_attributes:"Buildings and Contents"::string') }} as buildings_and_contents,
        {{ safe_to_number_2dp('c.custom_attributes:"Bundle Costs"::string') }} as bundle_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Car Maintenance"::string') }} as car_maintenance,
        {{ safe_to_number_2dp('c.custom_attributes:"car maintenance cost"::string') }} as car_maintenance_cost,
        {{ safe_to_number_2dp('c.custom_attributes:"Child Maintenance"::string') }} as child_maintenance,
        {{ safe_to_number_2dp('c.custom_attributes:"Clothing and Footwear"::string') }} as clothing_and_footwear,
        {{ safe_to_number_2dp('c.custom_attributes:"Council Tax"::string') }} as council_tax,
        {{ safe_to_number_2dp('c.custom_attributes:"Electric"::string') }} as electric,
        {{ safe_to_number_2dp('c.custom_attributes:"Fuel"::string') }} as fuel,
        {{ safe_to_number_2dp('c.custom_attributes:"Gas"::string') }} as gas,
        {{ safe_to_number_2dp('c.custom_attributes:"Gas and Electric"::string') }} as gas_and_electric,
        {{ safe_to_number_2dp('c.custom_attributes:"Groceries"::string') }} as groceries,
        {{ safe_to_number_2dp('c.custom_attributes:"Hair Costs"::string') }} as hair_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Life Insurance"::string') }} as life_insurance,
        {{ safe_to_number_2dp('c.custom_attributes:"Medical Prescriptions"::string') }} as medical_prescriptions,
        {{ safe_to_number_2dp('c.custom_attributes:"Mortgage"::string') }} as mortgage,
        {{ safe_to_number_2dp('c.custom_attributes:"Phone Costs"::string') }} as phone_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Rent"::string') }} as rent,
        {{ safe_to_number_2dp('c.custom_attributes:"TV Licence"::string') }} as tv_licence,
        {{ safe_to_number_2dp('c.custom_attributes:"Vehicle Finance"::string') }} as vehicle_finance,
        {{ safe_to_number_2dp('c.custom_attributes:"Vehicle Insurance"::string') }} as vehicle_insurance,
        {{ safe_to_number_2dp('c.custom_attributes:"Vehicle Tax"::string') }} as vehicle_tax,
        {{ safe_to_number_2dp('c.custom_attributes:"Water"::string') }} as water,
        {{ safe_to_number_2dp('c.custom_attributes:"Childcare Costs"::string') }} as childcare_costs,
        {{ safe_to_number_2dp('c.custom_attributes:"Hobbies and Leisure"::string') }} as hobbies_and_leisure,
        {{ safe_to_number_2dp('c.custom_attributes:"Public Transport"::string') }} as public_transport

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
                'Auto UG | Error',
                'AUTO UG - Not Sent',
                'Auto UG - DMP/DAS',
                'auto ug | error | no debt level',
                'Auto UG | Error 19-02-26',
                'aug echo',
                'Auto UG - Short Time To Repay',
                'Auto UG - Zero Offer'
            )
            then to_timestamp(te.applied_at_unix)
        end) as auto_ug_at,

        listagg(distinct te.tag_name, ', ') as tags_applied

    from tags_exploded te
    group by te.conversation_id, te.contact_id
)

select
    p.*,
    ct.* exclude (contact_id)

from pivoted p
left join contacts ct
  on p.contact_id = ct.contact_id