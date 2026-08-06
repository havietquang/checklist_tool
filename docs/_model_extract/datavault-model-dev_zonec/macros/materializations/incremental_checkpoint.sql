{#
  Override is_incremental() để nhận 'incremental_checkpoint'.
  Dùng builtins.is_incremental() để gọi lại logic gốc của thư viện — không hardcode.
  → Library update vẫn an toàn, ta chỉ mở rộng thêm, không thay thế.
#}
{% macro is_incremental() %}
    {%- if dbt.is_incremental() -%}
        {{ return(True) }}
    {%- elif flags.FULL_REFRESH -%}
        {{ return(False) }}
    {%- elif config.get('materialized') == 'incremental_checkpoint' -%}
        {%- set relation = adapter.get_relation(this.database, this.schema, this.identifier) -%}
        {{ return(relation is not none) }}
    {%- else -%}
        {{ return(False) }}
    {%- endif -%}
{% endmacro %}


{% materialization incremental_checkpoint, adapter='databricks' %}
    {% do checkpoint_pre_hook(model) %}
    {%- set _skip = check_skip_model(model) -%}
    {%- if _skip == 'block' -%}
        {{ return(checkpoint_block_return('table')) }}
    {%- elif _skip -%}
        {{ return(checkpoint_skip_return('table')) }}
    {%- endif -%}
    {%- set result = context['materialization_incremental_databricks']() -%}
    {% do checkpoint_post_hook(model) %}
    {{ return(result) }}
{% endmaterialization %}


{% materialization incremental_checkpoint, default %}
    {% do checkpoint_pre_hook(model) %}
    {%- set _skip = check_skip_model(model) -%}
    {%- if _skip == 'block' -%}
        {{ return(checkpoint_block_return('table')) }}
    {%- elif _skip -%}
        {{ return(checkpoint_skip_return('table')) }}
    {%- endif -%}
    {%- set result = run_base_materialization('incremental') -%}
    {% do checkpoint_post_hook(model) %}
    {{ return(result) }}
{% endmaterialization %}


{#
  process_config_changes của adapter không được expose ổn định để gọi lại từ project macro.
  Nếu override rồi cố gọi fallback "macro gốc" sai cách sẽ làm vỡ cả incremental thường
  (vd data_mart) với lỗi compile.

  Ở project này, checkpoint chỉ cần tránh fail khi materialization là incremental_checkpoint.
  Vì vậy ta biến process_config_changes thành no-op an toàn cho mọi incremental model.
  Đổi lại: nếu tags/tblproperties/config metadata thay đổi, dbt sẽ không auto-apply ở bước này.
#}
{% macro process_config_changes(target_relation) %}
    {%- if var('checkpoint_hooks_enabled', false) -%}
        {%- if config.get('materialized') == 'incremental_checkpoint' -%}
            {%- do log("[checkpoint] Skip config_changes for incremental_checkpoint", info=True) -%}
        {%- else -%}
            {%- do log("[checkpoint] Skip config_changes for incremental materialization", info=True) -%}
        {%- endif -%}
    {%- endif -%}
    {{ return('') }}
{% endmacro %}
