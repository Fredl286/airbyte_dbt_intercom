{# ------------------------------------------------------------- #}
{# 1. Discover all ECHO-related custom attribute keys            #}
{# ------------------------------------------------------------- #}

{% set echo_keys_query %}
    SELECT DISTINCT LOWER(f.key) AS key
    FROM {{ source('airbyte_intercom','contacts') }} c,
         LATERAL FLATTEN(input => c.custom_attributes) f
    WHERE LOWER(f.key) LIKE '%echo%'
{% endset %}

{% set echo_keys = run_query(echo_keys_query).columns[0].values() %}
{# echo_keys is now a Python list of strings #}


{# ------------------------------------------------------------- #}
{# 2. Base raw conversations                                     #}
{# ------------------------------------------------------------- #}

WITH raw AS (
    SELECT *
    FROM {{ source('airbyte_intercom','conversations') }}
),

tags_exploded AS (
    SELECT DISTINCT
        r.id AS conversation_id,
        t.value:"name"::string AS tag_name,
        t.value:"applied_at"::bigint AS applied_at_unix,
        r.contacts:"contacts"[0]:"id"::string AS contact_id
    FROM raw r,
         LATERAL FLATTEN(input => r.tags:"tags") t
    WHERE t.value:"name"::string IN ('Started ECHO Main', 'Completed ECHO main')
),

pivoted AS (
    SELECT
        te.conversation_id,
        te.contact_id,
        MAX(CASE WHEN te.tag_name = 'Started ECHO Main'
                 THEN TO_TIMESTAMP(te.applied_at_unix) END) AS started_at,
        MAX(CASE WHEN te.tag_name = 'Completed ECHO main'
                 THEN TO_TIMESTAMP(te.applied_at_unix) END) AS completed_at,
        LISTAGG(DISTINCT te.tag_name, ', ') AS tags_applied
    FROM tags_exploded te
    GROUP BY te.conversation_id, te.contact_id
),


{# ------------------------------------------------------------- #}
{# 3. Extract ALL custom attributes (including your existing ones) #}
{# ------------------------------------------------------------- #}

contacts_base AS (
    SELECT DISTINCT
        c.id AS contact_id,
        NULLIF(RTRIM(c.custom_attributes:"vulcan_id"::string), '') AS vulcan_id,
        c.phone,
        c.email,

        -- Your existing attributes
        ROUND(TO_NUMBER(c.custom_attributes:"Surplus"::string), 2) AS surplus,
        ROUND(TO_NUMBER(c.custom_attributes:"Vulcan Surplus"::string), 2) AS vulcan_surplus,
        ROUND(TO_NUMBER(c.custom_attributes:"Total Unsecured Debt VSAPI"::string), 2) AS total_unsecured_debt_vsapi,
        ROUND(TO_NUMBER(c.custom_attributes:"Total Household Income"::string), 2) AS total_household_income,
        ROUND(TO_NUMBER(c.custom_attributes:"Total Household Expenditure"::string), 2) AS total_household_expenditure
    FROM {{ source('airbyte_intercom','contacts') }} c
),

{# ------------------------------------------------------------- #}
{# 4. Flatten ALL ECHO attributes dynamically                     #}
{# ------------------------------------------------------------- #}

echo_attributes AS (
    SELECT
        c.id AS contact_id,
        LOWER(f.key) AS attr_key,
        f.value::string AS attr_value
    FROM {{ source('airbyte_intercom','contacts') }} c,
         LATERAL FLATTEN(input => c.custom_attributes) f
    WHERE LOWER(f.key) LIKE '%echo%'
),

{# ------------------------------------------------------------- #}
{# 5. Pivot ECHO attributes dynamically                           #}
{# ------------------------------------------------------------- #}

echo_pivot AS (
    SELECT
        contact_id,
        {% for k in echo_keys %}
            MAX(CASE WHEN attr_key = '{{ k }}' THEN attr_value END) AS {{ k }}{% if not loop.last %},{% endif %}
        {% endfor %}
    FROM echo_attributes
    GROUP BY contact_id
)


{# ------------------------------------------------------------- #}
{# 6. Final output: conversations + contacts + dynamic ECHO attrs #}
{# ------------------------------------------------------------- #}

SELECT
    p.conversation_id,
    p.contact_id,
    p.started_at,
    p.completed_at,
    p.tags_applied,

    -- Your existing contact fields
    ct.vulcan_id,
    ct.phone,
    ct.email,
    ct.surplus,
    ct.vulcan_surplus,
    ct.total_unsecured_debt_vsapi,
    ct.total_household_income,
    ct.total_household_expenditure,

    -- Dynamically added ECHO attributes
    ep.*
FROM pivoted p
LEFT JOIN contacts_base ct
    ON p.contact_id = ct.contact_id
LEFT JOIN echo_pivot ep
    ON p.contact_id = ep.contact_id;