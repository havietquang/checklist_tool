{% macro bridge(bridge_cfg) %}

{% set bridge_cfg = bridge_cfg or {} %}
{% set source_name = bridge_cfg.get('source_name', 'raw_vault') %}
{% set base_model = bridge_cfg.get('base_model', bridge_cfg.get('source_model', '')) %}
{% set base_as = bridge_cfg.get('base_as', base_model) %}
{% set bridge_walk = bridge_cfg.get('bridge_walk', []) %}
{% set select_cols = bridge_cfg.get('select_cols', []) %}
{% set where_clause = bridge_cfg.get('where_clause') %}
{% set base_pk = bridge_cfg.get('base_pk', '') %}
{% set sts_hub_table = bridge_cfg.get('sts_hub_table') %}
{% set sts_hub_as = bridge_cfg.get('sts_hub_as', sts_hub_table) %}
{% set sts_hub_pk = bridge_cfg.get('sts_hub_pk', base_pk) %}
{% set sts_hub_source_name = bridge_cfg.get('sts_hub_source_name', source_name) %}
{% set base_effsat_table = bridge_cfg.get('base_effsat_table') %}
{% set base_effsat_as = bridge_cfg.get('base_effsat_as', base_effsat_table) %}
{% set base_effsat_hashkey = bridge_cfg.get('base_effsat_hashkey', base_pk) %}
{% set base_effsat_source_name = bridge_cfg.get('base_effsat_source_name', source_name) %}
{% set base_latest_by_expr = bridge_cfg.get('base_latest_by_expr') %}
{% set base_latest_order_expr = bridge_cfg.get('base_latest_order_expr') %}
{% set base_date_filter = bridge_cfg.get('base_date_filter', '<=') %}
{% set ns = namespace(link_aliases=[], hub_aliases=[], effsat_filters=[]) %}

{# Build {table_name: {col_name: data_type}} from raw_vault_sources.yml — mirrors stage.sql pattern #}
{%- set rv_col_types = {} -%}
{%- if execute -%}
  {%- for node in graph.get('sources', {}).values() -%}
    {%- if node.source_name == source_name -%}
      {%- set tbl_types = {} -%}
      {%- for col_name, col_meta in node.columns.items() -%}
        {%- if col_meta.data_type -%}
          {%- do tbl_types.update({col_name: col_meta.data_type}) -%}
        {%- endif -%}
      {%- endfor -%}
      {%- if tbl_types -%}
        {%- do rv_col_types.update({node.name: tbl_types}) -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

{# Build {alias: table_name} from base model + bridge_walk hub/link entries #}
{%- set alias_to_table = {base_as: base_model} -%}
{%- for step in bridge_walk -%}
  {%- do alias_to_table.update({step.get('link_as', step.get('link_table')): step.get('link_table')}) -%}
  {%- if step.get('hub_table') -%}
    {%- do alias_to_table.update({step.get('hub_as', step.get('hub_table')): step.get('hub_table')}) -%}
  {%- endif -%}
{%- endfor -%}

{% if not base_model %}
    {{ exceptions.raise_compiler_error("Missing 'source_model' or 'base_model' in bridge_cfg.") }}
{% endif %}
{% if not base_pk %}
    {{ exceptions.raise_compiler_error("Missing 'base_pk' in bridge_cfg.") }}
{% endif %}
{% if (base_latest_by_expr and not base_latest_order_expr) or (base_latest_order_expr and not base_latest_by_expr) %}
    {{ exceptions.raise_compiler_error("bridge_cfg requires both 'base_latest_by_expr' and 'base_latest_order_expr' when filtering latest base business key.") }}
{% endif %}
{% if base_date_filter not in ['=', '<='] %}
    {{ exceptions.raise_compiler_error("Invalid base_date_filter '" ~ base_date_filter ~ "' in bridge_cfg. Allowed values: '=', '<='.") }}
{% endif %}

with

{{ base_as }}_cte as (
    select
        {{ base_pk }},
        max(source_event_date) as source_event_date
    from {{ source(source_name, base_model) }}
    where source_event_date {{ base_date_filter }} to_date('{{ var("target_date") }}', 'yyyyMMdd')
    group by {{ base_pk }}
)

{% if base_latest_by_expr %}
, {{ base_as }}_latest_business_key_cte as (
    select
        {{ base_as }}.{{ base_pk }}
    from {{ source(source_name, base_model) }} {{ base_as }}
    inner join {{ base_as }}_cte
        on {{ base_as }}.{{ base_pk }} = {{ base_as }}_cte.{{ base_pk }}
       and {{ base_as }}.source_event_date = {{ base_as }}_cte.source_event_date
    qualify row_number() over (
        partition by {{ base_latest_by_expr }}
        order by {{ base_latest_order_expr }} desc,
                 {{ base_as }}.source_event_date desc,
                 {{ base_as }}.load_timestamp desc,
                 {{ base_as }}.{{ base_pk }} desc
    ) = 1
)
{% endif %}

{% if base_effsat_table %}
, {{ base_effsat_as }}_cte as (
    select
        {{ base_effsat_hashkey }},
        active_flag
    from {{ source(base_effsat_source_name, base_effsat_table) }}
    where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
    qualify row_number() over (
        partition by {{ base_effsat_hashkey }}
        order by source_event_date desc, load_timestamp desc
    ) = 1
)
{% endif %}

{% if sts_hub_table %}
, {{ sts_hub_as }}_cte as (
    select {{ sts_hub_pk }}, source_event_date as end_date
    from {{ source(sts_hub_source_name, sts_hub_table) }}
    where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
    qualify row_number() over (partition by {{ sts_hub_pk }} order by source_event_date desc) = 1
        and cdc_status = 'D'
)
{% endif %}

{% for step in bridge_walk %}
{% set link_table = step.get('link_table') %}
{% set link_as = step.get('link_as', link_table) %}
{% set link_fk = step.get('link_fk') %}
{% set link_partition_by = step.get('link_partition_by', link_fk) %}
{% set step_name = step.get('name', 'STEP_' ~ loop.index) %}

{% set step_date_filter = step.get('date_filter', '=') %}
{% set step_hub_date_filter = step.get('hub_date_filter', '<=') %}
{% if step_date_filter not in ['=', '<='] %}
    {{ exceptions.raise_compiler_error("Invalid date_filter '" ~ step_date_filter ~ "' in bridge step '" ~ step_name ~ "'. Allowed values: '=', '<='.") }}
{% endif %}
{% if step_hub_date_filter not in ['=', '<='] %}
    {{ exceptions.raise_compiler_error("Invalid hub_date_filter '" ~ step_hub_date_filter ~ "' in bridge step '" ~ step_name ~ "'. Allowed values: '=', '<='.") }}
{% endif %}

{% if not link_table %}
    {{ exceptions.raise_compiler_error("Missing 'link_table' in bridge step '" ~ step_name ~ "'.") }}
{% endif %}
{% if not link_fk %}
    {{ exceptions.raise_compiler_error("Missing 'link_fk' in bridge step '" ~ step_name ~ "'.") }}
{% endif %}
{% if not step.get('link_join_from') %}
    {{ exceptions.raise_compiler_error("Missing 'link_join_from' in bridge step '" ~ step_name ~ "'.") }}
{% endif %}
{% if link_as in ns.link_aliases %}
    {{ exceptions.raise_compiler_error("Duplicate link alias '" ~ link_as ~ "' in bridge step '" ~ step_name ~ "'.") }}
{% endif %}
{% set ns.link_aliases = ns.link_aliases + [link_as] %}

, {{ link_as }}_cte as (
    select
        {{ link_partition_by }},
        max(source_event_date) as source_event_date
    from {{ source(step.get('link_source_name', source_name), link_table) }}
    where source_event_date {{ step_date_filter }} to_date('{{ var("target_date") }}', 'yyyyMMdd')
    group by {{ link_partition_by }}
)

{% if step.get('effsat_table') %}
{% set effsat_table = step.get('effsat_table') %}
{% set effsat_as = step.get('effsat_as', effsat_table) %}
{% set effsat_hashkey = step.get('effsat_hashkey') %}
{% if not effsat_hashkey %}
    {{ exceptions.raise_compiler_error("Missing 'effsat_hashkey' in bridge step '" ~ step_name ~ "' because 'effsat_table' is provided.") }}
{% endif %}
{% set ns.effsat_filters = ns.effsat_filters + [effsat_as ~ '_cte.bridge_end_date is null'] %}

, {{ effsat_as }}_cte as (
    select
        {{ effsat_hashkey }},
        source_event_date as bridge_end_date
    from {{ source(step.get('effsat_source_name', source_name), effsat_table) }}
    where source_event_date {{ step_date_filter }} to_date('{{ var("target_date") }}', 'yyyyMMdd')
    qualify row_number() over (
        partition by {{ effsat_hashkey }}
        order by source_event_date desc, load_timestamp desc
    ) = 1
        and active_flag = 0
)
{% endif %}

{% if step.get('hub_table') %}
{% set hub_table = step.get('hub_table') %}
{% set hub_as = step.get('hub_as', hub_table) %}
{% set hub_pk = step.get('hub_pk') %}

{% if not hub_pk %}
    {{ exceptions.raise_compiler_error("Missing 'hub_pk' in bridge step '" ~ step_name ~ "' because 'hub_table' is provided.") }}
{% endif %}
{% if hub_as in ns.hub_aliases %}
    {{ exceptions.raise_compiler_error("Duplicate hub alias '" ~ hub_as ~ "' in bridge step '" ~ step_name ~ "'.") }}
{% endif %}
{% set ns.hub_aliases = ns.hub_aliases + [hub_as] %}

, {{ hub_as }}_cte as (
    select
        {{ hub_pk }},
        max(source_event_date) as source_event_date
    from {{ source(step.get('hub_source_name', source_name), hub_table) }}
    where source_event_date {{ step_hub_date_filter }} to_date('{{ var("target_date") }}', 'yyyyMMdd')
    group by {{ hub_pk }}
)

{% if step.get('sts_hub_table') %}
{% set step_sts_hub_table = step.get('sts_hub_table') %}
{% set step_sts_hub_as = step.get('sts_hub_as', step_sts_hub_table) %}
{% set step_sts_hub_pk = step.get('sts_hub_pk', hub_pk) %}
{% set step_sts_hub_source_name = step.get('sts_hub_source_name', source_name) %}
{% set ns.effsat_filters = ns.effsat_filters + [step_sts_hub_as ~ '_cte.' ~ step_sts_hub_pk ~ ' is null'] %}

, {{ step_sts_hub_as }}_cte as (
    select {{ step_sts_hub_pk }}, source_event_date as end_date
    from {{ source(step_sts_hub_source_name, step_sts_hub_table) }}
    where source_event_date {{ step_hub_date_filter }} to_date('{{ var("target_date") }}', 'yyyyMMdd')
    qualify row_number() over (partition by {{ step_sts_hub_pk }} order by source_event_date desc) = 1
        and cdc_status = 'D'
)
{% endif %}

{% endif %}
{% endfor %}

select
    {%- for col in select_cols %}
    {%- set ns_col = namespace(data_type=none) %}
    {%- set _expr = col.get('expr', '') %}
    {%- if '.' in _expr %}
      {%- set _parts = _expr.split('.') %}
      {%- set _src_tbl = alias_to_table.get(_parts[0]) %}
      {%- if _src_tbl %}
        {%- set ns_col.data_type = rv_col_types.get(_src_tbl, {}).get(_parts[-1]) %}
      {%- endif %}
    {%- endif %}
    {%- if ns_col.data_type %}
    cast({{ _expr }} as {{ ns_col.data_type }}) as {{ col.get('as') }}{% if not loop.last %},{% endif %}
    {%- else %}
    {{ _expr }} as {{ col.get('as') }}{% if not loop.last %},{% endif %}
    {%- endif %}
    {%- endfor %}
    {% if select_cols|length > 0 %},{% endif %}
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as snapshot_date

from {{ source(source_name, base_model) }} {{ base_as }}

inner join {{ base_as }}_cte
    on {{ base_as }}.{{ base_pk }} = {{ base_as }}_cte.{{ base_pk }}
   and {{ base_as }}.source_event_date = {{ base_as }}_cte.source_event_date

{% if base_latest_by_expr %}
inner join {{ base_as }}_latest_business_key_cte
    on {{ base_as }}.{{ base_pk }} = {{ base_as }}_latest_business_key_cte.{{ base_pk }}
{% endif %}

{% if base_effsat_table %}
inner join {{ base_effsat_as }}_cte
    on {{ base_as }}.{{ base_effsat_hashkey }} = {{ base_effsat_as }}_cte.{{ base_effsat_hashkey }}
   and {{ base_effsat_as }}_cte.active_flag = 1
{% endif %}

{% if sts_hub_table %}
left join {{ sts_hub_as }}_cte
    on {{ base_as }}.{{ sts_hub_pk }} = {{ sts_hub_as }}_cte.{{ sts_hub_pk }}
{% endif %}

{% for step in bridge_walk %}
{% set link_as = step.get('link_as', step.get('link_table')) %}
{% set link_fk = step.get('link_fk') %}
{% set link_pk = step.get('link_pk') %}
{% set hub_table = step.get('hub_table') %}
{% set join_type_raw = step.get('join_type', 'left') | lower | trim %}
{% set join_type = join_type_raw | replace(' join', '') %}
{% if join_type not in ['left', 'inner'] %}
    {{ exceptions.raise_compiler_error("Invalid join_type '" ~ join_type_raw ~ "' in bridge step '" ~ step.get('name', link_as) ~ "'. Allowed values: left, inner, left join, inner join.") }}
{% endif %}

{{ join_type }} join {{ link_as }}_cte
    on {{ step.get('link_join_from') }} = {{ link_as }}_cte.{{ link_fk }}

{{ join_type }} join {{ source(step.get('link_source_name', source_name), step.get('link_table')) }} {{ link_as }}
    on {{ link_as }}.{{ link_fk }} = {{ link_as }}_cte.{{ link_fk }}
   and {{ link_as }}.source_event_date = {{ link_as }}_cte.source_event_date

{% if step.get('effsat_table') %}
{% set effsat_as = step.get('effsat_as', step.get('effsat_table')) %}
{% set effsat_hashkey = step.get('effsat_hashkey') %}

left join {{ effsat_as }}_cte
    on {{ link_as }}.{{ effsat_hashkey }} = {{ effsat_as }}_cte.{{ effsat_hashkey }}

{% endif %}
{% if hub_table %}
{% set hub_as = step.get('hub_as', hub_table) %}
{% set hub_pk = step.get('hub_pk') %}

{{ join_type }} join {{ hub_as }}_cte
    on {{ hub_as }}_cte.{{ hub_pk }} = {{ link_as }}.{{ link_pk }}

{{ join_type }} join {{ source(step.get('hub_source_name', source_name), hub_table) }} {{ hub_as }}
    on {{ hub_as }}.{{ hub_pk }} = {{ hub_as }}_cte.{{ hub_pk }}
   and {{ hub_as }}.source_event_date = {{ hub_as }}_cte.source_event_date

{% if step.get('sts_hub_table') %}
{% set step_sts_hub_as = step.get('sts_hub_as', step.get('sts_hub_table')) %}
{% set step_sts_hub_pk = step.get('sts_hub_pk', hub_pk) %}

left join {{ step_sts_hub_as }}_cte
    on {{ hub_as }}.{{ step_sts_hub_pk }} = {{ step_sts_hub_as }}_cte.{{ step_sts_hub_pk }}
{% endif %}

{% endif %}
{% endfor %}

{% if where_clause or ns.effsat_filters|length > 0 or sts_hub_table %}
where 1=1
{% if where_clause %}
  and {{ where_clause }}
{% endif %}
{% if sts_hub_table %}
  and {{ sts_hub_as }}_cte.{{ sts_hub_pk }} is null
{% endif %}
{% for f in ns.effsat_filters %}
  and {{ f }}
{% endfor %}
{% endif %}

{% endmacro %}
