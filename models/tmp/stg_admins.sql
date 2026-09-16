select
    {{ normalize_id('id') }} as admin_id,
    type as admin_type,
    *
from {{ source('airbyte_intercom','admins') }}
