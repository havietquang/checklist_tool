{% macro effsat(source_model = none, source_name = none, source_table = none, unique_key = none, source_business_key_cols = none, raw_sql = none, link_model = none) %}

{% set has_raw_sql = raw_sql is not none and raw_sql | trim != '' %}

{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("effsat macro: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if has_raw_sql and (
    unique_key is none or unique_key | trim == '' or
    link_model is none or link_model | trim == ''
) %}
    {{ exceptions.raise_compiler_error("effsat macro: `unique_key` and `link_model` are required when `raw_sql` is provided.") }}
{% endif %}

{% if not has_raw_sql and (
    source_model is none or source_model | trim == '' or
    source_name is none or source_name | trim == '' or
    source_table is none or source_table | trim == '' or
    unique_key is none or unique_key | trim == '' or
    source_business_key_cols is none or source_business_key_cols | length == 0 or
    link_model is none or link_model | trim == ''
) %}
    {{ exceptions.raise_compiler_error("effsat macro: missing required params when `raw_sql` is not provided.") }}
{% endif %}

with source_data as (

    select distinct
        src.{{ unique_key }},
        src.source_event_date,
        src.record_source,
        src.load_timestamp
    from (
    {% if has_raw_sql %}
        {{ raw_sql }}
    {% else %}
    select distinct
            {{ hash_column(source_business_key_cols, source_name) }} as {{ unique_key }},
            to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
            concat('{{ source_name }}', '__', '{{ source_table }}') as record_source,
            current_timestamp as load_timestamp
        from {{ ref(source_model) }}
        where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
        {% for col in source_business_key_cols %}
        and {{ col }} is not null
        {% endfor %}
    {% endif %}
    ) src
    inner join {{ ref(link_model) }} l
        on src.{{ unique_key }} = l.{{ unique_key }}

)

{% if is_incremental() %}

, source_count as (
    select count(*) as row_count
    from source_data
)

, target_data_latest as (
    select t.*
    from {{ this }} t
    qualify row_number() over (
        partition by t.{{ unique_key }}
        order by t.source_event_date desc, t.load_timestamp desc
    ) = 1
)

, target_data_active as (
    select * from target_data_latest
    where active_flag = 1
)

-- Thêm mới: link xuất hiện trong source mà chưa có active record cho (hashkey, date) này
, insert_data as (
    select s.*, cast(1 as int) as active_flag
    from source_data s
    where not exists (
        select 1 from target_data_latest t
        where s.{{ unique_key }} is not distinct from t.{{ unique_key }}
        and t.active_flag = 1
    )
)

-- Xoá: link biến mất khỏi source → đóng active record cũ
, close_data as (
    select
        t.{{ unique_key }},
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        t.record_source,
        t.load_timestamp,
        cast(0 as int) as active_flag
    from target_data_active t
    cross join source_count sc
    where sc.row_count > 0
    and not exists (
        select 1
        from source_data s
        where s.{{ unique_key }} is not distinct from t.{{ unique_key }}
    )
)

select * from insert_data
union all
select * from close_data

{% else %}

select
    s.*,
    cast(1 as int) as active_flag
from source_data s

{% endif %}

{% endmacro %}
