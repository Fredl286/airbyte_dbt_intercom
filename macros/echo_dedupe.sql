{% macro echo_poly_dedupe_rows(source_relation, require_completed=false, completed_weight=2, vulcan_weight=1, completeness_fields=[]) %}
with source_data as (
    select *
    from {{ source_relation }}
),
excluded_keys as (
    select distinct conversation_id, contact_id
    from source_data
    where coalesce(email, '') ilike '%payplan.com%'
       or coalesce(email, '') ilike '%@test.com%'
       or coalesce(email, '') ilike '%@payplanpolyconvo.com%'
       or coalesce(email, '') ilike '%@payplanpolyconvo.co.uk%'
),
base as (
    select s.*
    from source_data s
    where not exists (
        select 1
        from excluded_keys e
        where e.conversation_id = s.conversation_id
           or e.contact_id = s.contact_id
    )
      {% if require_completed %}
      and s.completed_at is not null
      {% endif %}
),
scored_conversation as (
    select
        *,
        case when completed_at is not null then 1 else 0 end as has_completed,
        case when vulcan_id is not null then 1 else 0 end as has_vulcan,
        (
            {% if completeness_fields | length == 0 %}
            0
            {% else %}
            {% for field in completeness_fields %}
            case
                when {{ field }} is null then 0
                when nullif(trim(to_varchar({{ field }})), '') is not null then 1
                else 0
            end{% if not loop.last %} +{% endif %}
            {% endfor %}
            {% endif %}
        ) as completeness_count,
        row_number() over (
            partition by conversation_id
            order by
                has_completed desc,
                has_vulcan desc,
                completeness_count desc,
                completed_at desc,
                started_at desc,
                conversation_id desc
        ) as rn_conversation
    from base
),
conversation_best as (
    select *
    from scored_conversation
    where rn_conversation = 1
),
conversation_aggregated as (
    select
        b.conversation_id,
        min(b.started_at) as started_at_merged,
        max(b.completed_at) as completed_at_merged,
        listagg(distinct nullif(trim(t.value::string), ''), ', ')
            within group (order by nullif(trim(t.value::string), '')) as tags_applied_merged
    from base b,
         lateral flatten(
             input => split(coalesce(b.tags_applied, ''), ','),
             outer => true
         ) t
    group by b.conversation_id
),
deduped_conversation as (
    select
        cb.* replace (
            ca.started_at_merged as started_at,
            ca.completed_at_merged as completed_at,
            coalesce(ca.tags_applied_merged, cb.tags_applied) as tags_applied
        )
    from conversation_best cb
    left join conversation_aggregated ca
      on cb.conversation_id = ca.conversation_id
),
person_day_base as (
    select
        *,
        date(coalesce(started_at, completed_at)) as event_date,
        coalesce(
            nullif(trim(contact_id::string), ''),
            nullif(lower(trim(email::string)), ''),
            nullif(trim(phone::string), ''),
            nullif(trim(conversation_id::string), '')
        ) as person_key
    from deduped_conversation
),
vulcan_backfilled as (
    select
        *,
        coalesce(
            vulcan_id,
            max(vulcan_id) over (
                partition by person_key, event_date
            )
        ) as vulcan_id_filled
    from person_day_base
),
scored_person_day as (
    select
        *,
        case when completed_at is not null then 1 else 0 end as has_completed_filled,
        case when vulcan_id_filled is not null then 1 else 0 end as has_vulcan_filled,
        (
            {% if completeness_fields | length == 0 %}
            0
            {% else %}
            {% for field in completeness_fields %}
            case
                when {{ field }} is null then 0
                when nullif(trim(to_varchar({{ field }})), '') is not null then 1
                else 0
            end{% if not loop.last %} +{% endif %}
            {% endfor %}
            {% endif %}
        ) as completeness_count_filled
    from vulcan_backfilled
),
ranked_person_day as (
    select
        *,
        row_number() over (
            partition by person_key, event_date
            order by
                has_completed_filled desc,
                has_vulcan_filled desc,
                completeness_count_filled desc,
                completed_at desc,
                started_at desc,
                conversation_id desc
        ) as rn_person_day
    from scored_person_day
)
select *
from ranked_person_day
where rn_person_day = 1
{% endmacro %}
