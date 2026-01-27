select
    id as conversation_part_id,
    created_at as created_at_timestamp,
    updated_at as updated_at_timestamp,
    {{ dbt_date.from_unixtimestamp('created_at') }} as created_at_date,
    {{ dbt_date.from_unixtimestamp('updated_at') }} as updated_at_date,
    author:"id"::string as author_id,
    author:"type"::string as author_type,
    *
from {{ var('conversation_parts') }}
