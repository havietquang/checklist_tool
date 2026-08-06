{% macro link_computed_aggregate(
    source_model=None,
    source_name=None,
    source_table=None,
    link_hashkey=None,
    foreign_hashkeys=None,
    aggregate_cols=None,
    joins=None,
    filter_clause=None,
    raw_sql=None
) %}

{% set has_raw_sql = raw_sql is not none and raw_sql | trim != '' %}
{% set foreign_hashkeys = foreign_hashkeys or {} %}
{% set aggregate_cols   = aggregate_cols   or [] %}
{% set joins            = joins            or [] %}

{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("link_computed_aggregate macro: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if not has_raw_sql and (
    source_model is none or source_model | trim == '' or
    source_name is none or source_name | trim == '' or
    source_table is none or source_table | trim == '' or
    link_hashkey is none or link_hashkey | trim == '' or
    foreign_hashkeys | length == 0 or
    aggregate_cols | length == 0
) %}
    {{ exceptions.raise_compiler_error("link_computed_aggregate macro: `foreign_hashkeys` and `aggregate_cols` must not be empty when `raw_sql` is not provided.") }}
{% endif %}

{% if has_raw_sql %}
    {{ raw_sql }}
{% else %}

{%- set fk_exprs = [] -%}
{%- for fk_expr in foreign_hashkeys.values() -%}
    {%- do fk_exprs.append(fk_expr) -%}
{%- endfor -%}

select
    {{ hash_key(fk_exprs) }} as {{ link_hashkey }},

    {% for fk_col, fk_expr in foreign_hashkeys.items() %}
    {{ fk_expr }} as {{ fk_col }},
    {% endfor %}

    {% for agg in aggregate_cols %}
    {%- set use_safe_numeric = agg.get('safe_numeric', false) -%}
    {%- if use_safe_numeric %}
    {%- set cast_type = agg.get('cast_type', 'DECIMAL(38,2)') -%}
    {{ agg.get('agg') | lower }}(coalesce(try_cast({{ agg.get('col') }} as {{ cast_type }}), 0)) as {{ agg.get('alias') }}{% if not loop.last %},{% endif %}
    {%- else %}
    {{ agg.get('agg') | lower }}({{ agg.get('col') }}) as {{ agg.get('alias') }}{% if not loop.last %},{% endif %}
    {%- endif %}
    {% endfor %}

    {% if aggregate_cols | length > 0 %},{% endif %}
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    concat('{{ source_name }}', '__', '{{ source_table }}') as record_source,
    current_timestamp as load_timestamp

from {{ source(source_name, source_model) }} base_src
{% for j in joins %}
{% set join_type = j.get('join_type', 'left') %}
{{ join_type if 'join' in join_type | lower else join_type ~ ' join' }} {{ source(j.get('source_name', source_name), j.get('model')) }} {{ j.get('alias') }}
    on {{ j.get('on') }}
    {% if j.get('date_filter', true) %}
    and {{ j.get('alias') }}.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {% endif %}
{% endfor %}

where base_src.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
{% if filter_clause %}
and {{ filter_clause }}
{% endif %}

group by
{% for fk_col, fk_expr in foreign_hashkeys.items() %}
{{ fk_expr }}{% if not loop.last %},{% endif %}
{% endfor %}

{% endif %}

{% endmacro %}
