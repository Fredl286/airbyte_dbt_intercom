select
    team_id,
    name as team_name,
    team_type,
    admin_ids
from {{ ref('int_latest_team') }}
