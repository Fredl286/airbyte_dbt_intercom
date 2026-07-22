select
    attribute_id,
    name as attribute_name,
    attribute_type,
    label,
    model,
    custom,
    data_type,
    full_name,
    description,
    admin_id,
    archived,
    ui_writable,
    api_writable,
    messenger_writable,
    created_at_timestamp,
    updated_at_timestamp
from {{ ref('int_intercom__latest_contact_attribute') }}
