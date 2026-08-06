{%- macro hash_key(columns_list, is_upper=true) -%}
{%- set hex_columns = [] -%}
{%- set len = columns_list | length -%}
{%- for column in columns_list -%}
    {%- if is_upper -%}
        {%- set value_expr = "COALESCE(UPPER(TRIM(CAST(" ~ column ~ " AS string))), '')" -%}
    {%- else -%}
        {%- set value_expr = "COALESCE(TRIM(CAST(" ~ column ~ " AS string)), '')" -%}
    {%- endif -%}
    {%- if loop.index != len -%}
        {%- set column_string = value_expr ~ " || '$' || " -%}
    {%- else -%}
        {%- set column_string = value_expr -%}
    {%- endif -%}
    {%- do hex_columns.append(column_string) -%}
{%- endfor -%}
{%- set str = hex_columns | join('') -%}
sha2({{ str }}, 256)
{%- endmacro -%}

-------

{%- macro hash_column(columns_list, source_name, is_upper=true) -%}
-- bỏ tạm source_name theo comment của huyndt
{% set source_name = '' %}
{%- set hex_columns = [] -%}
{%- set len = columns_list | length -%}
{%- for column in columns_list -%}
    {%- if is_upper -%}
        {%- set value_expr = "COALESCE(UPPER(TRIM(CAST(" ~ column ~ " AS string))), '')" -%}
    {%- else -%}
        {%- set value_expr = "COALESCE(TRIM(CAST(" ~ column ~ " AS string)), '')" -%}
    {%- endif -%}
    {%- if loop.index != len -%}
        {%- set column_string = value_expr ~ " || '$' || " -%}
    {%- else -%}
        {%- set column_string = value_expr -%}
    {%- endif -%}
    {%- do hex_columns.append(column_string) -%}
{%- endfor -%}
{%- set str = hex_columns | join('') -%}
sha2({{ str }}, 256)
{%- endmacro -%}