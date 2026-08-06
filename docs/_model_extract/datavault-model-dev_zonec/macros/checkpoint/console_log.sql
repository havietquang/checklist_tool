{% macro log_run_start_to_console() %}
  {% if execute %}
    {%- set source_name = var('source_name', 'None') -%}
    {%- set etl_date    = var('target_date', '1900-01-01') -%}
    {%- set run_id      = var('run_id',      'None') -%}
    {%- set job_id      = var('job_id',      'None') -%}
    {%- set task_key     = var('task_key',     'None') -%}

    {%- set select_raw = invocation_args_dict.get('select', []) -%}
    {%- set select_str = select_raw if select_raw is string
                         else (select_raw | join(', ') if select_raw | length > 0 else 'None') -%}

    {{ log(" ", info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log("                       STARTING DBT RUN", info=True) }}
    {{ log("--------------------------------------------------------------------------------", info=True) }}
    {{ log("  -- Source Name : " ~ source_name, info=True) }}
    {{ log("  -- Run ID      : " ~ run_id,       info=True) }}
    {{ log("  -- Job ID      : " ~ job_id,       info=True) }}
    {{ log("  -- Task Key    : " ~ task_key,      info=True) }}
    {{ log("  -- ETL Date    : " ~ etl_date,     info=True) }}
    {{ log("  -- Select Run  : " ~ select_str,   info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log(" ", info=True) }}
  {% endif %}
{% endmacro %}


{% macro log_run_end_to_console(results) %}
  {% if execute %}
    {%- set source_name = var('source_name', 'None') -%}
    {%- set etl_date    = var('target_date', '1900-01-01') -%}
    {%- set run_id      = var('run_id',      'None') -%}
    {%- set job_id      = var('job_id',      'None') -%}
    {%- set task_key     = var('task_key',     'None') -%}

    {%- set select_raw = invocation_args_dict.get('select', []) -%}
    {%- set select_str = select_raw if select_raw is string
                         else (select_raw | join(', ') if select_raw | length > 0 else 'None') -%}

    {%- set ns = namespace(success=0, warn=0, error=0, skip=0) -%}
    {%- for res in results -%}
      {%- if   res.status in ('success', 'pass') -%} {%- set ns.success = ns.success + 1 -%}
      {%- elif res.status == 'warn'    -%}           {%- set ns.warn    = ns.warn    + 1 -%}
      {%- elif res.status in ('fail', 'error') -%}   {%- set ns.error   = ns.error   + 1 -%}
      {%- elif res.status == 'skipped' -%}           {%- set ns.skip    = ns.skip    + 1 -%}
      {%- endif -%}
    {%- endfor -%}

    {{ log(" ", info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log("           on-run-end [1/2] SUMMARIZING RUN RESULTS", info=True) }}
    {{ log("--------------------------------------------------------------------------------", info=True) }}
    {{ log("  -- Source Name : " ~ source_name,      info=True) }}
    {{ log("  -- Run ID      : " ~ run_id,            info=True) }}
    {{ log("  -- Job ID      : " ~ job_id,            info=True) }}
    {{ log("  -- Task Key    : " ~ task_key,           info=True) }}
    {{ log("  -- ETL Date    : " ~ etl_date,          info=True) }}
    {{ log("  -- Select Run  : " ~ select_str,        info=True) }}
    {{ log("--------------------------------------------------------------------------------", info=True) }}
    {{ log(" Total    : " ~ (results | length),   info=True) }}
    {{ log(" Success  : " ~ ns.success,           info=True) }}
    {{ log(" Warning  : " ~ ns.warn,              info=True) }}
    {{ log(" Error    : " ~ ns.error,             info=True) }}
    {{ log(" Skip     : " ~ ns.skip,              info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log(" ", info=True) }}
  {% endif %}
{% endmacro %}
