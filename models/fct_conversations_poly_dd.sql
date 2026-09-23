{{ config(materialized='table') }}

with deduped as (
    {{ echo_poly_dedupe_rows(
        ref('fct_conversations_poly'),
        completeness_fields=[
            'consent_asked_at',
            'started_at',
            'completed_at',
            'tags_applied',
            'vulcan_id',
            'phone',
            'email',
            'vulcan_surplus',
            'total_debt_form',
            'total_debt_with_ccjs',
            'total_unsecured_debt_vsapi',
            'clean_total_debt'
        ]
    ) }}
),
cleaned as (
    select
        {{ normalize_id('conversation_id') }} as conversation_id,
        {{ normalize_id('contact_id') }} as contact_id,
        consent_asked_at,
        started_at,
        completed_at,
        tags_applied,
        {{ normalize_id('vulcan_id_filled') }} as vulcan_id,
        phone,
        email,
        cast(vulcan_surplus as number(38,0)) as vulcan_surplus,
        cast(total_debt_form as number(38,2)) as total_debt_form,
        cast(total_debt_with_ccjs as number(38,2)) as total_debt_with_ccjs,
        cast(total_unsecured_debt_vsapi as number(38,2)) as total_unsecured_debt_vsapi,
        cast(clean_total_debt as number(38,2)) as clean_total_debt
    from deduped
)

select * from cleaned
