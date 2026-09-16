select
    {{ normalize_id('id') }} as segment_id,
    {{ epoch_to_timestamp('created_at') }} as created_at_timestamp,
    {{ epoch_to_timestamp('updated_at') }} as updated_at_timestamp,
    type as segment_type,
    *
from {{ source('airbyte_intercom','segments') }}
