with segments as (
    select *
    from {{ ref('stg_intercom__segments') }}
),

latest_segment as (
    select
        *,
        row_number() over(partition by segment_id order by updated_at_timestamp desc) as latest_segment_index
    from segments
)

select *
from latest_segment
where latest_segment_index = 1
