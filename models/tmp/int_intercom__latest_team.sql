with teams as (
    select *
    from {{ ref('stg_intercom__teams') }}
),

latest_team as (
    select
        *,
        row_number() over(partition by team_id order by _airbyte_extracted_at desc) as latest_team_index
    from teams
)

select *
from latest_team
where latest_team_index = 1
