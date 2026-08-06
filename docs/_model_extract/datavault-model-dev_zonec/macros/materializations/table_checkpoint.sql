{% materialization table_checkpoint, default %}
    {% do checkpoint_pre_hook(model) %}
    {%- set _skip = check_skip_model(model) -%}
    {%- if _skip == 'block' -%}
        {{ return(checkpoint_block_return('table')) }}
    {%- elif _skip -%}
        {{ return(checkpoint_skip_return('table')) }}
    {%- endif -%}
    {%- set result = run_base_materialization('table') -%}
    {% do checkpoint_post_hook(model) %}
    {{ return(result) }}
{% endmaterialization %}
