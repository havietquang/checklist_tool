{% macro ref_table(raw_sql=None, src_table=None, src_type=None, src_code=None, src_des=None, source_name=None, list_cols=None, where_clause=None, record_source=None, hashdiff_name=None) %}

{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("ref_table macro: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if raw_sql is none and (
    src_table is none or src_table | trim == '' or
    src_code is none or src_code | trim == '' or
    src_des is none or src_des | trim == '' or
    source_name is none or source_name | trim == '' or
    hashdiff_name is none or hashdiff_name | trim == ''
) %}
    {{ exceptions.raise_compiler_error("ref_table macro: missing required params (`src_table`, `src_code`, `src_des`, `source_name`, `hashdiff_name`) when `raw_sql` is not provided.") }}
{% endif %}

{% if raw_sql is not none %}

{{ raw_sql }}

{% else %}

{%- if list_cols is none or list_cols | length == 0 -%}
    {{ exceptions.raise_compiler_error("ref_table macro: `list_cols` cannot be empty when `raw_sql` is not provided - danh sach cot nghiep vu dua vao bang ref.") }}
{%- endif -%}

select
    {% if src_type is none %}
    sha2(cast({{ src_code }} as string), 256) as ref_hashkey,
    NULL as ref_type,
    {% else %}
    sha2(('{{ src_type }}' || cast({{ src_code }} as string)), 256) as ref_hashkey,
    '{{ src_type }}' as ref_type,
    {% endif %}
    cast({{ src_code }} as string) as ref_code,
    cast({{ src_des }} as string) as ref_description,
    {%- for col in list_cols %}
    {{ col }},
    {%- endfor %}
    {{ hashdiff_name }} as hashdiff,
    source_event_date,
    cast('{{ record_source if record_source is not none else source_name ~ "__" ~ src_table }}' as string) as record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
from {{ ref('v_stg_' ~ source_name ~ '_' ~ src_table) }}

{% if where_clause %}
where {{ where_clause }}
{% endif %}

{% endif %}

{% endmacro %}
