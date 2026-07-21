{% macro normalize_id(field, length=50) %}
    CAST(NULLIF(TRIM({{ field }}::string), '') AS VARCHAR({{ length }}))
{% endmacro %}
