with conversations as (
	select *
	from {{ ref('fct_intercom__conversations') }}
),

part_aggregates as (
	select *
	from {{ ref('int_intercom__conversation_part_aggregates') }}
),

final as (
	select
		c.conversation_id,
		c.assignee_type,
		c.last_closed_by_id,
		c.conversation_state,
		c.conversation_rating,
		c.conversation_remark,
		coalesce(a.count_reopens, 0) as count_reopens,
		coalesce(a.count_total_parts, 0) as count_total_parts,
		coalesce(a.count_assignments, 0) as count_assignments,
		a.time_to_first_response_minutes,
		a.time_to_last_close_minutes
	from conversations c
	left join part_aggregates a
		on c.conversation_id = a.conversation_id
)

select *
from final