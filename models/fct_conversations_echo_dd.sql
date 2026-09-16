{{ config(materialized='table') }}

with deduped as (
    {{ echo_dedupe_rows(
        ref('fct_conversations_echo'),
        completeness_fields=[
            'started_at',
            'completed_at',
            'tags_applied',
            'd2a_flag',
            'vulcan_id',
            'phone',
            'email',
            'surplus',
            'vulcan_surplus',
            'total_debt_form',
            'total_debt_with_ccjs',
            'total_unsecured_debt_vsapi',
            'clean_total_debt',
            'total_household_income',
            'total_household_expenditure'
        ]
    ) }}
),
cleaned as (
    select
        {{ normalize_id('conversation_id') }} as conversation_id,
        {{ normalize_id('contact_id') }} as contact_id,
        started_at,
        completed_at,
        tags_applied,
        cast(coalesce(d2a_flag, 0) as number(1,0)) as d2a_flag,
        {{ normalize_id('vulcan_id_filled') }} as vulcan_id,
        phone,
        email,
        cast(surplus as number(38,0)) as surplus,
        cast(vulcan_surplus as number(38,0)) as vulcan_surplus,
        cast(total_debt_form as number(38,2)) as total_debt_form,
        cast(total_debt_with_ccjs as number(38,2)) as total_debt_with_ccjs,
        cast(total_unsecured_debt_vsapi as number(38,2)) as total_unsecured_debt_vsapi,
        cast(clean_total_debt as number(38,2)) as clean_total_debt,
        cast(total_household_income as number(38,0)) as total_household_income,
        cast(total_household_expenditure as number(38,0)) as total_household_expenditure
    from deduped
)

select * from cleaned