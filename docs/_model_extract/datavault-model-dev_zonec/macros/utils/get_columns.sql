{%- macro get_columns(relation) -%}
{%- set sql -%}
    describe {{ relation }}
  {%- endset -%}
  {%- set result = run_query(sql) -%}

  {%- set columns = [] -%}
  {%- set seen_cols = [] -%}
  {%- set ns = namespace(past_partition_info=false) -%}
  {%- for row in result -%}
    {%- if row['col_name'].strip().startswith('#') -%}
      {%- set ns.past_partition_info = true -%}
    {%- elif not ns.past_partition_info and row['data_type'] | length > 0 and row['col_name'].strip().lower() not in seen_cols -%}
      {%- do seen_cols.append(row['col_name'].strip().lower()) -%}
      {%- do columns.append(api.Column.from_description(row['col_name'].lower(), row['data_type'])) -%}
    {%- endif -%}
  {%- endfor -%}
  {%- do return(columns) -%}
{%- endmacro -%}