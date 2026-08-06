{%- macro stage (source_table, business_key_cols, hashdiff_satellite_dict, source_event_date_col = None, source_event_date_dttype="str+date",source_name = 't24', is_upper=true, raw_sql=None, extra_where=None, list_cols=None ) -%}

  {%- set columns = get_columns(source(source_name, source_table )) -%}
  {%- set cols_name = [] -%}

  {%- for column in columns -%}
    {%- do cols_name.append(column.name) -%}
  {%- endfor -%}

  {%- set col_type_overrides = {} -%}
  {%- if execute -%}
    {%- for node in graph.get('sources', {}).values() -%}
      {%- if node.source_name == source_name and node.name == source_table -%}
        {%- for col_name, col_meta in node.columns.items() -%}
          {%- if col_meta.data_type -%}
            {%- do col_type_overrides.update({col_name: col_meta.data_type}) -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}

  {%- if raw_sql is not none -%}
    {%- set cols_to_cast = [] -%}
    {%- for col in columns -%}
      {%- if col.name in col_type_overrides -%}
        {%- do cols_to_cast.append(col.name) -%}
      {%- endif -%}
    {%- endfor -%}
    {%- if cols_to_cast | length > 0 -%}
with __base as (
{{ raw_sql }}
)
select
  * except ({{ cols_to_cast | join(', ') }}),
      {%- for col_name in cols_to_cast %}
  cast({{ col_name }} as {{ col_type_overrides[col_name] }}) as {{ col_name }}{{ ',' if not loop.last }}
      {%- endfor %}
from __base
    {%- else -%}
{{ raw_sql }}
    {%- endif -%}
  {%- else -%}

select
  --HASH KEY
  {{ hash_column(business_key_cols, source_name, is_upper) }} as hashkey,

  --ALL COLUMNS FROM SOURCE TABLE
  {{ '\n  ' }}
  {%- for column in columns -%}
  {%- if column.name in col_type_overrides -%}
  cast(src.{{column.name}} as {{col_type_overrides[column.name]}}) as {{column.name}} , {{ '\n  ' }}
  {%- else -%}
  src.{{column.name}} , {{ '\n  ' }}
  {%- endif -%}
  {%- endfor -%}

  --HASHDIFF FULL (chi sinh khi model co truyen list_cols - tuc co feed ref table)
  {%- if list_cols is not none %}
  {{ hash_column(list_cols, source_name, is_upper) }} as hashdiff_full,
  {%- endif %}

  --HASHDIFF SATELLITES
  {{ '\n  ' }}
  {% if hashdiff_satellite_dict is not none  %}
  {%- for k, v in hashdiff_satellite_dict.items() -%}
  {{ hash_column(v, source_name, is_upper) }} as {{k}} , {{ '\n  ' }}
  {%- endfor -%}
  {%- endif -%}
  {{ '\n  ' }}
  --TIME & SOURCE COLUMNS
  to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date, {{ '\n  ' }}
  '{{ source_name }}' as record_source,
  cast(current_timestamp as timestamp) as load_timestamp
from  {{source(source_name, source_table) }}  src {{ '\n  ' }}
{%- if source_event_date_col is not none -%}
where {{to_yyyymmdd_str(source_event_date_col, source_event_date_dttype)}} = '{{ var("target_date") }}'
{%- for col in business_key_cols -%}
{{ '\n' }}and {{ col }} is not null
{%- endfor -%}
{%- if extra_where is not none -%}
{{ '\n' }}and {{ extra_where }}
{%- endif -%}
{%- endif -%}
  {%- endif -%}

{%- endmacro -%}
