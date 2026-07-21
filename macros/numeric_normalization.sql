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


{% macro safe_to_number_38_2(field) %}
    CAST(
        ROUND(
            TRY_TO_NUMBER(
                REGEXP_REPLACE({{ field }}, '[^0-9.\-]', '')
            ),
            2
        ) AS NUMBER(38,2)
    )
{% endmacro %}


{% macro safe_to_number_38_0(field) %}
    CAST(
        ROUND(
            TRY_TO_NUMBER(
                REGEXP_REPLACE({{ field }}, '[^0-9.\-]', '')
            ),
            0
        ) AS NUMBER(38,0)
    )
{% endmacro %}
