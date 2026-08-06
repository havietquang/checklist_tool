
{% macro link(source_model = none, source_name = none, source_table = none, unique_key = none, source_business_key_cols = none, foreign_business_key_cols = none, raw_sql = none) %}

{% set has_raw_sql = raw_sql is not none and raw_sql | trim != '' %}

{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("link macro: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if not has_raw_sql and (
    source_model is none or source_model | trim == '' or
    source_name is none or source_name | trim == '' or
    source_table is none or source_table | trim == '' or
    unique_key is none or unique_key | trim == '' or
    source_business_key_cols is none or source_business_key_cols | length == 0 or
    foreign_business_key_cols is none or foreign_business_key_cols | length == 0
) %}
    {{ exceptions.raise_compiler_error("link macro: missing required params when `raw_sql` is not provided.") }}
{% endif %}

{% if has_raw_sql %}
        {{ raw_sql }}
{% else %}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS {{ unique_key }},
    {% for name_hashkey, cols in foreign_business_key_cols.items() %}
        {{ hash_column(cols, source_name) }} AS {{ name_hashkey }}{% if not loop.last %},{% endif %}
    {% endfor %},
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT('{{ source_name }}', '__', '{{ source_table }}') AS record_source,
    current_timestamp AS load_timestamp
FROM {{ ref(source_model) }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{% for col in source_business_key_cols %}
AND {{ col }} IS NOT NULL
{% endfor %}
{% endif %}
{% endmacro %}
