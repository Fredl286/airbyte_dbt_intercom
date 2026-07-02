{{ config(materialized='view') }}

select
    customer_part_id,
    conversation_id,
    customer_message_at as created_at_timestamp,
    customer_author_id,
    customer_author_type,
    customer_message_body,
    customer_part_type,
    first_response_part_id,
    first_response_at,
    first_response_author_id,
    first_response_author_type,
    first_response_body,
    is_first_response_by_agent,
    response_time_seconds,
    response_time_minutes
from {{ ref('fct_intercom__customer_response_times') }}
where is_first_response_by_agent = true
  and customer_message_at >= dateadd(month, -3, current_timestamp())
order by created_at_timestamp desc