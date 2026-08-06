{% macro computed_satellite(
    source_model=None,
    source_name=None,
    source_table=None,
    hashkey_col=None,
    computed_cols=None,
    joins=None,
    filter_clause=None,
    raw_sql=None,
    dependent_child_keys=None,
    group_by=None,
    sts_model=None,
    base_date_filter='<='
) %}

{% set has_raw_sql = raw_sql is not none and raw_sql | trim != '' %}
{% set computed_cols = computed_cols or [] %}
{% set joins         = joins         or [] %}
{% set group_by      = group_by      or [] %}

{% set computed_aliases = [] %}
{% for col in computed_cols %}{% do computed_aliases.append(col.get('alias')) %}{% endfor %}

{% set is_aggregate = (not has_raw_sql) and (group_by | length > 0) %}

{% set dependent_child_keys = dependent_child_keys or [] %}
{% if dependent_child_keys | length == 0 and computed_cols | selectattr('alias', 'equalto', 'ma_key') | list | length > 0 %}
    {% set dependent_child_keys = ['ma_key'] %}
{% endif %}

{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("computed_satellite macro: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if hashkey_col is none or hashkey_col | trim == '' %}
    {{ exceptions.raise_compiler_error("computed_satellite macro: `hashkey_col` is required.") }}
{% endif %}

{% if computed_cols | length == 0 %}
    {{ exceptions.raise_compiler_error("computed_satellite macro: `computed_cols` must not be empty.") }}
{% endif %}

{% if is_aggregate and (source_model is none or source_model | trim == '') %}
    {{ exceptions.raise_compiler_error("computed_satellite macro: `source_model` is required in aggregate mode.") }}
{% endif %}

{% if not has_raw_sql and not is_aggregate and (
    source_model is none or source_model | trim == '' or
    source_name is none or source_name | trim == '' or
    source_table is none or source_table | trim == ''
) %}
    {{ exceptions.raise_compiler_error("computed_satellite macro: missing required params when `raw_sql` is not provided.") }}
{% endif %}

{%- set hashdiff_exprs = [] -%}
{%- for col in computed_cols -%}
    {%- do hashdiff_exprs.append('computed_src.' ~ col.get('alias')) -%}
{%- endfor -%}

{% if has_raw_sql %}
with source_data as (
    {{ raw_sql }}
)
{% else %}

-- base: base_date_filter '<=' -> moi nhat moi grain; '=' -> dung target_date; none -> toan bang
with base_data as (
    select *
    from {{ source('raw_vault', source_model) }}
    {%- if base_date_filter is not none %}
    where source_event_date {{ base_date_filter }} to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {%- endif %}
    {%- if base_date_filter == '<=' %}
    qualify row_number() over (partition by {{ hashkey_col }} order by source_event_date desc) = 1
    {%- endif %}
)

-- computed_body: cot nghiep vu tu base + join phu, loc deleted (+ GROUP BY neu co group_by)
, computed_body as (
    select
        base_src.{{ hashkey_col }},
        {% for col in computed_cols %}
        {{ col.get('expr') }} as {{ col.get('alias') }}{{ "," if not loop.last }}
        {% endfor %}
    from base_data base_src

    -- join
    {% for j in joins %}
    {% set join_type = j.get('join_type', 'left join') %}
    {% set join_type = join_type if 'join' in join_type | lower else join_type ~ ' join' %}
    {% set jdf = j.get('date_filter', '<=') %}
    {% if jdf is none %}
    -- date_filter=none -> lay toan bang (vd hub 1 dong/key)
    {{ join_type }} {{ source('raw_vault', j.get('model')) }} {{ j.get('alias') }}
        on {{ j.get('on') }}
    {% else %}
    {{ join_type }} (
        select {{ j.get('columns', '*') }}
        from {{ source('raw_vault', j.get('model')) }}
        where source_event_date {{ jdf }} to_date('{{ var("target_date") }}', 'yyyyMMdd')
        {%- if jdf == '<=' %}
        qualify row_number() over (partition by {{ j.get('key') }} order by source_event_date desc) = 1
        {%- endif %}
    ) {{ j.get('alias') }}
        on {{ j.get('on') }}
    {% endif %}
    {% endfor %}

    {% set where_started = false %}

    -- sts
    {% if sts_model is not none %}
    where not exists (
        select 1
        from (
            select {{ hashkey_col }}, cdc_status,
                   row_number() over (partition by {{ hashkey_col }} order by source_event_date desc) as rn
            from {{ source('raw_vault', sts_model) }}
            where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
        ) del
        where del.rn = 1 and del.cdc_status = 'D'
          and del.{{ hashkey_col }} = base_src.{{ hashkey_col }}
    )
    {% set where_started = true %}
    {% endif %}

    -- filter
    {% if filter_clause %}
    {{ 'and' if where_started else 'where' }} {{ filter_clause }}
    {% endif %}

    -- group by
    {% if is_aggregate %}
    group by base_src.{{ hashkey_col }}{% for g in group_by %}, {{ g }}{% endfor %}
    {% endif %}
)

-- source_data: bo sung cot metadata (source_event_date/load_timestamp/record_source)
, source_data as (
    select
        computed_body.*
        {% if 'source_event_date' not in computed_aliases %}, to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date{% endif %}
        {% if 'load_timestamp' not in computed_aliases %}, current_timestamp as load_timestamp{% endif %}
        {% if 'record_source' not in computed_aliases %}, concat('{{ source_name }}', '__', '{{ source_table }}') as record_source{% endif %}
    from computed_body
)
{% endif %}

-- Tính hashdiff tự động từ toàn bộ computed columns
, source_with_hashdiff as (
    select
        computed_src.*,
        {{ hash_key(hashdiff_exprs) }} as hashdiff
    from source_data computed_src
)

{% if is_incremental() %}

-- Lấy bản ghi mới nhất trong target để so sánh hashdiff
, target_data as (
    select *
    from (
        select
            t.*,
            row_number() over (
                partition by t.{{ hashkey_col }}{% for k in dependent_child_keys %}, t.{{ k }}{% endfor %}
                order by t.source_event_date desc, t.load_timestamp desc
            ) as rn
        from {{ this }} t
    ) x
    where rn = 1
)

-- Insert khi: key chưa tồn tại HOẶC computed attributes thay đổi
, insert_data as (

    -- Key mới chưa có trong target
    select s.*
    from source_with_hashdiff s
    where not exists (
        select 1
        from target_data t
        where s.{{ hashkey_col }} = t.{{ hashkey_col }}
        {% for k in dependent_child_keys %}
          and coalesce(s.{{ k }}, '') = coalesce(t.{{ k }}, '')
        {% endfor %}
    )

    union all

    -- Key đã tồn tại nhưng computed attributes thay đổi
    select s.*
    from source_with_hashdiff s
    where exists (
        select 1
        from target_data t
        where s.{{ hashkey_col }} = t.{{ hashkey_col }}
        {% for k in dependent_child_keys %}
          and coalesce(s.{{ k }}, '') = coalesce(t.{{ k }}, '')
        {% endfor %}
          and coalesce(s.hashdiff, '') != coalesce(t.hashdiff, '')
    )

)

select * from insert_data

{% else %}

select * from source_with_hashdiff

{% endif %}

{% endmacro %}
