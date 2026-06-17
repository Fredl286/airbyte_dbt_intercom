{% macro safe_to_number(field) %}
    TRY_TO_NUMBER(
        REGEXP_REPLACE({{ field }}, '[^0-9.\-]', '')
    )
{% endmacro %}