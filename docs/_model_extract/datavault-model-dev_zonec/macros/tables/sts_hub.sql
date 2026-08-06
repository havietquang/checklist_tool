{% macro sts_hub(
    source_model = none,
    source_name = none,
    source_table = none,
    unique_key = none,
    source_business_key_cols = none,
    source_filter = none,
    raw_sql = none,
    hub_model = none,
    source_event_date_dttype = none
) %}

{% set has_raw_sql = raw_sql is not none and raw_sql | trim != '' %}

{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("sts_hub: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if hub_model is none or hub_model | trim == '' or unique_key is none or unique_key | trim == '' %}
    {{ exceptions.raise_compiler_error("sts_hub: `unique_key` and `hub_model` are required.") }}
{% endif %}

{% if not has_raw_sql and (
    source_model is none or source_model | trim == '' or
    source_name is none or source_name | trim == '' or
    source_table is none or source_table | trim == '' or
    source_business_key_cols is none or source_business_key_cols | length == 0 or
    source_event_date_dttype is none or source_event_date_dttype | trim == ''
) %}
    {{ exceptions.raise_compiler_error("sts_hub: missing required params when `raw_sql` is not provided.") }}
{% endif %}

{% if not has_raw_sql %}
    {% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) %}
{% endif %}

{% if not is_incremental() %}

select
    cast(null as string) as {{ unique_key }},
    cast(null as date)   as source_event_date,
    cast(null as string) as cdc_status
where 1 = 0

{% elif has_raw_sql %}

with raw_candidates as (
    {{ raw_sql }}
)

, valid_candidates as (
    select distinct
        d.{{ unique_key }},
        d.source_event_date,
        d.cdc_status
    from raw_candidates d
    inner join {{ ref(hub_model) }} h
        on d.{{ unique_key }} is not distinct from h.{{ unique_key }}
)

-- Avoid emitting D twice in a row for custom candidates.
, last_status_per_key as (
    select {{ unique_key }}, cdc_status, source_event_date
    from {{ this }}
    qualify row_number() over (
        partition by {{ unique_key }}
        order by source_event_date desc
    ) = 1
)

select distinct
    c.{{ unique_key }},
    c.source_event_date,
    c.cdc_status
from valid_candidates c
left join last_status_per_key l
    on c.{{ unique_key }} is not distinct from l.{{ unique_key }}
where not (
    c.cdc_status = 'D'
    and l.cdc_status = 'D'
)

{% else %}

-- Current key set from this source table.
with current_staging as (
    select distinct
        hashkey as {{ unique_key }}
    from {{ ref(source_model) }}
    {% if source_event_date_col is not none %}
    where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
    {% else %}
    -- Fullload source: source_event_date_col = null
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {% endif %}
    {% for col in source_business_key_cols %}
    and {{ col }} is not null
    {% endfor %}
    {% if source_filter is not none and source_filter | trim != '' %}
    and {{ source_filter }}
    {% endif %}
)

-- Guard against full-source load gaps.
, staging_count as (
    select count(*) as row_count
    from current_staging
)

-- Full hub population up to target_date. This intentionally scans the whole
-- hub, even when the hub is fed by multiple source tables.
, hub_snapshot as (
    select distinct {{ unique_key }}
    from {{ ref(hub_model) }}
    where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
)

-- Latest status per key in this STS table.
, last_status_per_key as (
    select {{ unique_key }}, cdc_status, source_event_date
    from {{ this }}
    qualify row_number() over (
        partition by {{ unique_key }}
        order by source_event_date desc
    ) = 1
)

-- If a deleted key appears again in current staging, emit I.
, reinsert_candidates as (
    select
        s.{{ unique_key }},
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        cast('I' as string)                              as cdc_status
    from current_staging s
    inner join last_status_per_key l
        on s.{{ unique_key }} is not distinct from l.{{ unique_key }}
    where l.cdc_status = 'D'
)

-- Keys already deleted do not emit D again until they are reinserted.
, already_deleted as (
    select {{ unique_key }}
    from last_status_per_key
    where cdc_status = 'D'
)

, delete_candidates as (
    select
        h.{{ unique_key }},
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        cast('D' as string)                              as cdc_status
    from hub_snapshot h
    cross join staging_count c
    where c.row_count > 0
      and not exists (
          select 1 from current_staging s
          where s.{{ unique_key }} is not distinct from h.{{ unique_key }}
      )
      and not exists (
          select 1 from already_deleted a
          where a.{{ unique_key }} is not distinct from h.{{ unique_key }}
      )
)

select distinct
    d.{{ unique_key }},
    d.source_event_date,
    d.cdc_status
from delete_candidates d

union all

select distinct
    r.{{ unique_key }},
    r.source_event_date,
    r.cdc_status
from reinsert_candidates r

{% endif %}

{% endmacro %}
