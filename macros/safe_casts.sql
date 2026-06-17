{% macro safe_to_number(field) %}
    TRY_TO_NUMBER(
        REGEXP_REPLACE({{ field }}, '[^0-9.\-]', '')
    )
{% endmacro %}


{% macro safe_to_number_2dp(field) %}
    ROUND(
        TRY_TO_NUMBER(
            REGEXP_REPLACE({{ field }}, '[^0-9.\-]', '')
        ),
        2
    )
{% endmacro %}