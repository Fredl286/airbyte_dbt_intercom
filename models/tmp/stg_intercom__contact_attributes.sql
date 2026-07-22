select
    id as attribute_id,
    {{ epoch_to_timestamp('created_at') }} as created_at_timestamp,
    {{ epoch_to_timestamp('updated_at') }} as updated_at_timestamp,
    type as attribute_type,
    *
from {{ source('airbyte_intercom','contact_attributes') }}
