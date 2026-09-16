select
    {{ normalize_id('id') }} as id,
    name,
    type
from {{ source('airbyte_intercom', 'tags') }}
