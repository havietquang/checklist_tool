{% macro checkpoint_pre_hook(model) %}
    {%- if var('checkpoint_hooks_enabled', false) -%}
        {% do log("[checkpoint] Pre-hook: " ~ model.name, info=True) %}
    {%- endif -%}
{% endmacro %}

{% macro checkpoint_post_hook(model) %}
    {%- if var('checkpoint_hooks_enabled', false) -%}
        {% do log("[checkpoint] Post-hook: " ~ model.name ~ " done", info=True) %}
    {%- endif -%}
{% endmacro %}

{#
  Trả về relation khi model bị skip.
  Dùng this.incorporate(type=...) thay vì load_cached_relation để tránh trả None.
  Mỗi materialization tự truyền đúng type vào.
#}
{% macro checkpoint_skip_return(relation_type='view') %}
    {#
      dbt bắt buộc statement('main') phải được gọi trong mỗi materialization.
      Khi skip sớm (model đã success), cần chạy một no-op để thỏa điều kiện đó.
    #}
    {%- call statement('main') -%}
        select 1 -- checkpoint skip no-op
    {%- endcall -%}
    {{ return({'relations': [this.incorporate(type=relation_type)]}) }}
{% endmacro %}

{#
  Trả về relation khi model bị block (freshness warning hoặc test error).
  Record 'block' đã được ghi vào checkpoint trong check_skip_model.
  Chạy no-op SELECT 1 để dbt không báo lỗi.
#}
{% macro checkpoint_block_return(relation_type='view') %}
    {%- call statement('main') -%}
        select 1 -- checkpoint block no-op
    {%- endcall -%}
    {{ return({'relations': [this.incorporate(type=relation_type)]}) }}
{% endmacro %}


{#
  Tìm và gọi materialization gốc theo tên động.
  Databricks naming: materialization_{name}_databricks → fallback materialization_{name}_default
#}
{% macro run_base_materialization(base_materialized) %}
    {%- set adapter_type = adapter.type() -%}
    {%- set mat_adapter  = 'materialization_' ~ base_materialized ~ '_' ~ adapter_type -%}
    {%- set mat_default  = 'materialization_' ~ base_materialized ~ '_default' -%}

    {%- if context.get(mat_adapter) is not none -%}
        {{ return(context[mat_adapter]()) }}
    {%- elif context.get(mat_default) is not none -%}
        {{ return(context[mat_default]()) }}
    {%- else -%}
        {{ exceptions.raise_compiler_error(
            "checkpoint: không tìm thấy materialization '" ~ base_materialized ~ "' "
            ~ "(đã thử: " ~ mat_adapter ~ ", " ~ mat_default ~ ")"
        ) }}
    {%- endif -%}
{% endmacro %}
