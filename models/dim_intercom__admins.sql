select
    admin_id,
    name as admin_name,
    admin_type,
    email,
    job_title,
    has_inbox_seat,
    away_mode_enabled,
    away_mode_reassign,
    team_ids,
    avatar
from {{ ref('stg_intercom__admins') }}
