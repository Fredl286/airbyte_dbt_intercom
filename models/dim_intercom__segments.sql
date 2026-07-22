select
    segment_id,
    name as segment_name,
    segment_type,
    count as member_count,
    person_type,
    created_at_timestamp,
    updated_at_timestamp
from {{ ref('int_intercom__latest_segment') }}
