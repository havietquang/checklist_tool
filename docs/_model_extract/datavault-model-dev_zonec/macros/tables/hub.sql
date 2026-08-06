{% macro hub(
    source_model = none, source_name = none, source_table = none, unique_key = none, business_key = none, raw_sql = none
) %}

    {% set use_raw_sql = raw_sql is not none and raw_sql | trim != '' %}

    {% if raw_sql is not none and raw_sql | trim == '' %}
        {{ exceptions.raise_compiler_error("hub macro: `raw_sql` cannot be empty when provided.") }}
    {% endif %}

    {% if not use_raw_sql and (
        source_model is none or source_model | trim == '' or
        source_name is none or source_name | trim == '' or
        source_table is none or source_table | trim == '' or
        business_key is none or business_key | trim == '' or
        unique_key is none or unique_key | trim == ''
    ) %}
        {{ exceptions.raise_compiler_error("hub macro: missing required params when `raw_sql` is not provided.") }}
    {% endif %}

    {% if use_raw_sql %}
        {{ raw_sql }}
    {% else %}
        SELECT
            hashkey AS {{ unique_key }},
            {{ business_key }} AS business_key,
            to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
            CONCAT('{{ source_name }}', '__', '{{ source_table }}') AS record_source,
            CURRENT_TIMESTAMP AS load_timestamp
        FROM {{ ref(source_model) }}
        WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {% endif %}

{% endmacro %}
