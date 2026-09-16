select
    {{ normalize_id('id') }} as contact_id,
    {{ epoch_to_timestamp('created_at') }} as created_at_timestamp,
    {{ epoch_to_timestamp('updated_at') }} as updated_at_timestamp,
    {{ epoch_to_timestamp('last_seen_at') }} as last_seen_at_timestamp,
    *
from {{ source('airbyte_intercom','contacts') }}
