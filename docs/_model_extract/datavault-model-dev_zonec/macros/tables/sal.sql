{% macro sal(source_model) %}

{% if source_model is none or source_model | trim == '' %}
    {{ exceptions.raise_compiler_error("sal macro: `source_model` is required.") }}
{% endif %}

  {%- set source_relation = ref(source_model) -%}
  {%- set columns = adapter.get_columns_in_relation(source_relation) -%}
  {%- set cols_name = [] -%}
  
  {%- for column in columns -%}
    {%- do cols_name.append(column.name) -%}
  {%- endfor -%}

with new_rows as (
    select 
        {% for col in cols_name[:3] -%}
          {% if loop.first %} a.{{ col }} as sal{{ col[4:] }}, {% else %} a.{{ col }} as {{ col }}, {% endif %}
        {% endfor -%}
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as load_date
    from {{ source('raw_vault', source_model) }} a
    where a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
)

select * from new_rows

{% endmacro %}
