{{ config(materialized='table') }}

-- 0. Bring in conversations + contact attributes together
with base as (
    select
        conv.*,
        ct.vulcan_id,
        ct.phone,
        ct.email,

        -- BUDGET FIELDS (all preserved)
        ct.surplus,
        ct.total_unsecured_debt_vsapi,
        ct.total_household_income,
        ct.total_household_expenditure,
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
        ct.vehicle_finance,
        ct.vehicle_insurance,
        ct.vehicle_tax,
        ct.water,
        ct.childcare_costs,
        ct.hobbies_and_leisure,
        ct.public_transport

    from {{ ref('intercom_echo_conversations') }} conv
    left join {{ ref('intercom_echo_contacts') }} ct
        on conv.contact_id = ct.contact_id
    where coalesce(conv.email, '') not ilike '%payplan.com%'
      and coalesce(conv.email, '') not ilike '%@test.com%'
),

-- 1. Score for conversation-level dedupe
scored as (
    select
        *,
        (case when completed_at is not null then 2 else 0 end) +
        (case when vulcan_id is not null then 1 else 0 end) as score
    from base
),

-- 2. Pick best row per conversation_id
ranked_conversation as (
    select
        *,
        row_number() over (
            partition by conversation_id
            order by score desc, completed_at desc, started_at desc
        ) as rn
    from scored
),

deduped_conversation as (
    select *
    from ranked_conversation
    where rn = 1
),

-- 3. Backfill vulcan_id within same contact/day
vulcan_backfilled as (
    select
        *,
        coalesce(
            vulcan_id,
            max(vulcan_id) over (
                partition by contact_id, date(started_at)
            )
        ) as vulcan_id_filled
    from deduped_conversation
),

-- 4. Add daily grouping
daily_scored as (
    select
        *,
        date(started_at) as started_date,
        (case when completed_at is not null then 2 else 0 end) +
        (case when vulcan_id_filled is not null then 1 else 0 end) as daily_score
    from vulcan_backfilled
),

-- 5. Dedupe per contact per day
ranked_daily as (
    select
        *,
        row_number() over (
            partition by contact_id, started_date
            order by daily_score desc, completed_at desc, started_at desc
        ) as rn_daily
    from daily_scored
),

deduped_daily as (
    select *
    from ranked_daily
    where rn_daily = 1
),

-- 6. Dedupe per contact per day per phone/email
phone_email_scored as (
    select
        *,
        (case when completed_at is not null then 2 else 0 end) +
        (case when vulcan_id_filled is not null then 1 else 0 end) as pe_score
    from deduped_daily
),

ranked_phone_email as (
    select
        *,
        row_number() over (
            partition by contact_id, started_date, phone, email
            order by pe_score desc, completed_at desc, started_at desc
        ) as rn_pe
    from phone_email_scored
),

deduped_phone_email as (
    select *
    from ranked_phone_email
    where rn_pe = 1
),

-- 7. Dedupe per contact per day per vulcan_id
vulcan_scored as (
    select
        *,
        (case when completed_at is not null then 2 else 0 end) +
        (case when vulcan_id_filled is not null then 1 else 0 end) as v_score
    from deduped_phone_email
),

ranked_vulcan as (
    select
        *,
        row_number() over (
            partition by contact_id, started_date, vulcan_id_filled
            order by v_score desc, completed_at desc, started_at desc
        ) as rn_vulcan
    from vulcan_scored
),

-- 8. Final cleaned output
cleaned as (
    select *
    from ranked_vulcan
    where rn_vulcan = 1
)

select * from cleaned