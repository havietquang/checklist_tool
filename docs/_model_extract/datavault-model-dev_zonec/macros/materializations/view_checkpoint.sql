{% materialization view_checkpoint, default %}
    {% do checkpoint_pre_hook(model) %}
    {%- set _skip = check_skip_model(model) -%}
    {%- if _skip == 'block' -%}
        {{ return(checkpoint_block_return('view')) }}
    {%- elif _skip -%}
        {{ return(checkpoint_skip_return('view')) }}
    {%- endif -%}
    {%- set result = run_base_materialization('view') -%}
    {% do checkpoint_post_hook(model) %}
    {{ return(result) }}
{% endmaterialization %}
