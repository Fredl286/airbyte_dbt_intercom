select
    contact_id,
    name,
    coalesce(nullif(email, ''), custom_attributes:"email_address"::string)::varchar(255) as email,
    phone,
    last_seen_at_timestamp,
    created_at_timestamp
from {{ ref('int_latest_contact') }}