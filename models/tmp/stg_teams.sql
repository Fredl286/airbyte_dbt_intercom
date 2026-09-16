select
    {{ normalize_id('id') }} as team_id,
    type as team_type,
    *
from {{ source('airbyte_intercom','teams') }}
