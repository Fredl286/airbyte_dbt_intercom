with conversation_parts as (

    select
        part_id,
        conversation_id,
        created_at_timestamp,
        author_id,
        lower(coalesce(author_type, 'unknown')) as author_type,
        body,
        part_type,
        nullif(trim(body), '') is not null as has_body
    from {{ ref('stg_intercom__conversation_parts') }}

),

classified as (

    select
        *,
        author_type in ('admin', 'agent', 'staff', 'teammate', 'operator') as is_admin_author,
        author_type in ('bot', 'ai_agent', 'assistant') as is_bot_author,
        author_type in ('user', 'customer', 'contact', 'lead') as is_customer_author,
        (
            author_type in ('user', 'customer', 'contact', 'lead')
            and has_body
        ) as is_customer_message,
        (
            author_type in ('admin', 'agent', 'staff', 'teammate', 'operator', 'bot', 'ai_agent', 'assistant')
            and has_body
        ) as is_reply_candidate
    from conversation_parts

),

customer_messages as (

    select
        part_id as customer_part_id,
        conversation_id,
        created_at_timestamp as customer_message_at,
        author_id as customer_author_id,
        author_type as customer_author_type,
        body as customer_message_body,
        part_type as customer_part_type
    from classified
    where is_customer_message

),

first_response_any as (

    select
        c.customer_part_id,
        r.part_id as first_response_part_id,
        r.created_at_timestamp as first_response_at,
        r.author_id as first_response_author_id,
        r.author_type as first_response_author_type,
        r.is_admin_author as first_response_is_admin,
        r.is_bot_author as first_response_is_bot,
        r.body as first_response_body,
        row_number() over (
            partition by c.customer_part_id
            order by r.created_at_timestamp, r.part_id
        ) as rn
    from customer_messages c
    join classified r
        on c.conversation_id = r.conversation_id
        and r.created_at_timestamp > c.customer_message_at
        and r.is_reply_candidate
        and not r.is_customer_author

),

first_admin_response as (

    select
        c.customer_part_id,
        r.part_id as first_admin_response_part_id,
        r.created_at_timestamp as first_admin_response_at,
        r.author_id as first_admin_response_author_id,
        r.author_type as first_admin_response_author_type,
        r.body as first_admin_response_body,
        row_number() over (
            partition by c.customer_part_id
            order by r.created_at_timestamp, r.part_id
        ) as rn
    from customer_messages c
    join classified r
        on c.conversation_id = r.conversation_id
        and r.created_at_timestamp > c.customer_message_at
        and r.is_admin_author
        and r.has_body

),

final as (

    select
        c.customer_part_id,
        c.conversation_id,
        c.customer_message_at,
        c.customer_author_id,
        c.customer_author_type,
        c.customer_message_body,
        c.customer_part_type,

        fa.first_response_part_id,
        fa.first_response_at,
        fa.first_response_author_id,
        fa.first_response_author_type,
        fa.first_response_is_admin,
        fa.first_response_is_bot,
        fa.first_response_body,

        fad.first_admin_response_part_id,
        fad.first_admin_response_at,
        fad.first_admin_response_author_id,
        fad.first_admin_response_author_type,
        fad.first_admin_response_body,

        fa.first_response_part_id is not null as has_any_response,
        fad.first_admin_response_part_id is not null as has_admin_response,

        datediff('second', c.customer_message_at, fa.first_response_at) as response_time_seconds,
        datediff('minute', c.customer_message_at, fa.first_response_at) as response_time_minutes,

        datediff('second', c.customer_message_at, fad.first_admin_response_at) as admin_response_time_seconds,
        datediff('minute', c.customer_message_at, fad.first_admin_response_at) as admin_response_time_minutes,

        coalesce(fa.first_response_is_admin, false) as is_first_response_by_agent,
        coalesce(fa.first_response_is_bot, false) as is_first_response_by_bot,

        case
            when fad.first_admin_response_part_id is not null then true
            else false
        end as include_in_agent_sla
    from customer_messages c
    left join first_response_any fa
        on c.customer_part_id = fa.customer_part_id
        and fa.rn = 1
    left join first_admin_response fad
        on c.customer_part_id = fad.customer_part_id
        and fad.rn = 1

)

select *
from final