{% macro pit(source_model = none, src_hashkey = none, satellites = none , raw_sql = none, sts_hub_table = none, sts_hub_pk = none) %}
 
{% if raw_sql is not none and raw_sql | trim != '' %}
    {{raw_sql}}
{% else %}
 
{% if satellites is none or satellites | length == 0 %}
    {{ exceptions.raise_compiler_error("pit macro: `satellites` is required when `raw_sql` is not provided.") }}
{% endif %}
 
with
{% for sat_name, hashkey in satellites.items() %}
    {{ sat_name }} as (
        select {{ hashkey }}, max(source_event_date) as source_event_date
        from {{ source('raw_vault', sat_name) }}
        where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
        group by {{ hashkey }}
    )
    {% if not loop.last %}, {% endif %}
{% endfor %}
 
{% if sts_hub_table is not none %}
, sts_hub_cte as (
    select {{ sts_hub_pk }}, source_event_date as end_date
    from {{ source('raw_vault', sts_hub_table) }}
    where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
    qualify row_number() over (partition by {{ sts_hub_pk }} order by source_event_date desc) = 1
        and cdc_status = 'D'
)
{% endif %}
 
, new_rows as (
    select
        a.{{ src_hashkey }},
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as snapshot_date,
        {% for sat_name, hashkey in satellites.items() %}
        {{ sat_name }}.source_event_date as {{ sat_name }}_src_ev_dt {% if not loop.last %}, {% endif %}
        {% endfor %}
    from {{ source('raw_vault', source_model) }} a
    {% for sat_name, hashkey in satellites.items() %}
    left join {{ sat_name }} on a.{{ src_hashkey }} = {{ sat_name }}.{{ hashkey }}
    {% endfor %}
    {% if sts_hub_table is not none %}
    left join sts_hub_cte on a.{{ src_hashkey }} = sts_hub_cte.{{ sts_hub_pk }}
    {% endif %}
    where a.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {% if sts_hub_table is not none %}
    and sts_hub_cte.{{ sts_hub_pk }} is null
    {% endif %}
)
 
select * from new_rows
{% endif %}
{% endmacro %}
 