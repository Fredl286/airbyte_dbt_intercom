select
    cast(id as bigint) as admin_id,
    type as admin_type,
    *
from {{ source('airbyte_intercom','admins') }}
