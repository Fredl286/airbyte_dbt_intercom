cleaned as (
    select
        -- EXACT ORDER YOU SPECIFIED
        conversation_id,
        contact_id,
        completed_at,
        vulcan_id_filled as vulcan_id,
        phone,
        email,
        total_unsecured_debt_vsapi as total_unsecured_debt,
        total_household_income,
        total_household_expenditure,
        surplus,

        -- MONTHLY BUDGET FIELDS
        monthly_buildings_and_content_insurance_cost,
        monthly_child_maintenance_payment,
        monthly_childcare_costs,
        monthly_clothing_cost,
        monthly_council_tax_amount,
        monthly_electric_cost,
        monthly_energy_costs,
        monthly_fuel_costs,
        monthly_gas_cost,
        monthly_groceries_cost,
        monthly_hobbies_and_leisure_costs,
        monthly_internet_and_subscription_costs,
        monthly_life_insurance_cost,
        monthly_medical_costs,
        monthly_mortgage_amount,
        monthly_public_transport_costs,
        monthly_rent_amount,
        monthly_tv_licence_cost,
        monthly_tv_internet_and_subscription_costs,
        monthly_vehicle_finance_costs,
        monthly_vehicle_insurance_costs,
        monthly_vehicle_tax_cost,
        monthly_water_cost,

        -- ADDITIONAL CUSTOM ATTRIBUTES
        buildings_and_contents,
        bundle_costs,
        car_maintenance,
        car_maintenance_cost,
        child_maintenance,
        clothing_and_footwear,
        council_tax,
        electric,
        fuel,
        gas,
        gas_and_electric,
        groceries,
        hair_costs,
        life_insurance,
        medical_prescriptions,
        mortgage,
        phone_costs,
        rent,
        tv_licence,
        vehicle_finance,
        vehicle_insurance,
        vehicle_tax,
        water,

        -- 🔥 NEW FIELDS YOU ADDED IN THE UPSTREAM MODEL
        tv_internet_and_subscriptions,
        fuel_non_monthly,
        vehicle_insurance_non_monthly,
        vehicle_tax_non_monthly,
        car_maintenance_non_monthly,
        public_transport_non_monthly,
        hobbies_and_leisure_non_monthly,
        childcare_costs_non_monthly

    from ranked_vulcan
    where rn_vulcan = 1
      and completed_at is not null
)