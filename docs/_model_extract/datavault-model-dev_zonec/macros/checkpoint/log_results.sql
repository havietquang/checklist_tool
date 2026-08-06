{% macro log_run_results_to_db(results) %}
    {%- if not execute -%}{{ return('') }}{%- endif -%}

    {%- set cp_db     = var('checkpoint_database', target.database) -%}
    {%- set cp_schema = var('checkpoint_schema',   target.schema)   -%}
    {%- set cp_table  = var('checkpoint_table',    'etl_model_checkpoint') -%}
    {%- set job_id      = var('job_id',      'None')        -%}
    {%- set task_key    = var('task_key',     'None')        -%}
    {%- set run_id      = var('run_id',      invocation_id) -%}
    {%- set etl_date    = var('target_date', '1900-01-01')  -%}
    {%- set explicit_source_name = var('source_name', none) -%}

    {%- set model_rows     = [] -%}
    {%- set freshness_rows = [] -%}

    {# Build map: unique_id → name cho các model bị error trong run này, để tra cứu khi gặp skipped #}
    {%- set failed_in_run = {} -%}
    {%- for r in results -%}
        {%- set d = r.to_dict() -%}
        {%- set n = d.get('node', {}) -%}
        {%- if n.get('resource_type') == 'model' and d.get('status') in ('error', 'fail') -%}
            {%- do failed_in_run.update({n.get('unique_id'): n.get('alias', n.get('name'))}) -%}
        {%- endif -%}
    {%- endfor -%}

    {%- for run_result in results -%}
        {%- set d    = run_result.to_dict() -%}
        {%- set node = d.get('node', {}) -%}
        {%- set rtype = node.get('resource_type') -%}

        {%- if rtype == 'model' -%}
            {%- set ar = d.get('adapter_response', {}) -%}
            {%- set node_tags = node.get('tags', []) -%}
            {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
                else (node_tags[0] if node_tags is iterable and node_tags is not string and (node_tags | length) > 0 else 'unknown') -%}
            {%- set rows = ar.get('rows_affected') or ar.get('num_rows_inserted') or 0 -%}
            {%- if rows is none -%}{%- set rows = 0 -%}{%- endif -%}
            {%- set timing = d.get('timing', []) -%}
            {%- if timing | length > 0 -%}
                {%- set sa = timing[-1].get('started_at') -%}
                {%- set ca = timing[-1].get('completed_at') -%}
            {%- else -%}
                {%- set now = modules.datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S') -%}
                {%- set sa = now -%}
                {%- set ca = now -%}
            {%- endif -%}
            {%- set status  = d.get('status') -%}
            {%- set message = d.get('message', '') | replace("'", "\\'") -%}
            {%- if status == 'skipped' -%}
                {%- set status = 'error' -%}
                {# Tìm dependency nào của model này bị error trong run hiện tại #}
                {%- set culprits = [] -%}
                {%- for dep_id in node.get('depends_on', {}).get('nodes', []) -%}
                    {%- if dep_id in failed_in_run -%}
                        {%- do culprits.append(failed_in_run[dep_id]) -%}
                    {%- endif -%}
                {%- endfor -%}
                {%- if culprits | length > 0 -%}
                    {%- set message = 'Skipped: upstream failed [' ~ culprits | join(', ') ~ ']' -%}
                {%- else -%}
                    {%- set message = 'Skipped: Dependency model failed' -%}
                {%- endif -%}
            {%- endif -%}
            {%- do model_rows.append({
                'database_name':  node.get('database'),
                'schema_name':    node.get('schema'),
                'name':           node.get('alias', node.get('name')),
                'model_name':     node.get('name'),
                'source_name':    source_name,
                'execution_time': d.get('execution_time', 0),
                'rows_affected':  rows,
                'status':         status,
                'message':        message,
                'started_at':     sa,
                'completed_at':   ca
            }) -%}

        {%- elif rtype == 'source' -%}
            {%- set raw_status = d.get('status', 'error') | lower -%}
            {%- set status     = 'success' if raw_status == 'pass' else 'warning' -%}
            {%- set src_name   = node.get('source_name', 'unknown') -%}
            {%- set identifier = node.get('identifier', node.get('name', 'unknown')) -%}
            {%- set identifier_parts = identifier.split('_') if identifier is string else [] -%}
            {%- set inferred_source_name = src_name -%}
            {%- if identifier is string and identifier.startswith('v_stg_') and (identifier_parts | length) >= 3 -%}
                {%- set inferred_source_name = identifier_parts[2] -%}
            {%- elif identifier_parts | length > 0 and identifier_parts[0] in ['t24', 'omni', 'bpm', 'way4'] -%}
                {%- set inferred_source_name = identifier_parts[0] -%}
            {%- endif -%}
            {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
                else inferred_source_name -%}
            {%- set timing = d.get('timing', []) -%}
            {%- if timing | length > 0 -%}
                {%- set sa = "CAST('" ~ timing[-1].get('started_at')   ~ "' AS TIMESTAMP)" -%}
                {%- set ca = "CAST('" ~ timing[-1].get('completed_at') ~ "' AS TIMESTAMP)" -%}
            {%- else -%}
                {%- set sa = 'NULL' -%}
                {%- set ca = 'NULL' -%}
            {%- endif -%}
            {%- do freshness_rows.append({
                'database_name': node.get('database', target.database),
                'schema_name':   node.get('schema',   target.schema),
                'name':          identifier,
                'model_name':    identifier,
                'source_name':   source_name,
                'sa':            sa,
                'ca':            ca,
                'status':        status,
                'message':       'Freshness ' ~ raw_status
            }) -%}
        {%- endif -%}
    {%- endfor -%}

    {%- if model_rows | length == 0 and freshness_rows | length == 0 -%}
        {{ return('') }}
    {%- endif -%}

    {{ log(" ", info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log("           on-run-end [2/2] WRITING CHECKPOINT TO DATABASE", info=True) }}
    {{ log("--------------------------------------------------------------------------------", info=True) }}

    {# Lấy danh sách đã success của model run → bảo toàn, không ghi đè model đã hoàn tất #}
    {%- set already_ok_model = [] -%}
    {%- set detect_q -%}
        SELECT DISTINCT name, source_name
        FROM `{{ cp_db }}`.`{{ cp_schema }}`.`{{ cp_table }}`
        WHERE etl_date = '{{ etl_date }}'
          AND task_key    = 'run'
          AND status      IN ('success', 'block')
    {%- endset -%}
    {%- set res = run_query(detect_q) -%}
    {%- for row in res -%}
        {%- do already_ok_model.append(row['name'] ~ '|' ~ row['source_name']) -%}
    {%- endfor -%}

    {# --- Model rows --- #}
    {%- set to_insert = [] -%}
    {%- for r in model_rows -%}
        {%- set model_key = r.get('name') ~ '|' ~ r.get('source_name') -%}
        {%- if model_key not in already_ok_model -%}
            {%- set sa = "CAST('" ~ r.get('started_at')   ~ "' AS TIMESTAMP)"
                          if r.get('started_at')   not in ('NULL', None, '') else 'NULL' -%}
            {%- set ca = "CAST('" ~ r.get('completed_at') ~ "' AS TIMESTAMP)"
                          if r.get('completed_at') not in ('NULL', None, '') else 'NULL' -%}
            {%- do to_insert.append(
                "SELECT uuid() AS id"
                ~ ", '" ~ r.get('database_name') ~ "' AS database_name"
                ~ ", '" ~ r.get('schema_name')   ~ "' AS schema_name"
                ~ ", '" ~ r.get('name')          ~ "' AS name"
                ~ ", '" ~ r.get('model_name')    ~ "' AS model_name"
                ~ ", '" ~ r.get('source_name')    ~ "' AS source_name"
                ~ ", "  ~ r.get('execution_time') ~ " AS execution_time"
                ~ ", '" ~ etl_date               ~ "' AS etl_date"
                ~ ", "  ~ sa                     ~ " AS started_at"
                ~ ", "  ~ ca                     ~ " AS completed_at"
                ~ ", "  ~ r.get('rows_affected')  ~ " AS rows_affected"
                ~ ", '" ~ r.get('status')         ~ "' AS status"
                ~ ", '" ~ r.get('message')        ~ "' AS message"
                ~ ", '" ~ run_id   ~ "' AS run_id"
                ~ ", '" ~ job_id   ~ "' AS job_id"
                ~ ", '" ~ task_key ~ "' AS task_key"
            ) -%}
        {%- endif -%}
    {%- endfor -%}

    {# --- Freshness rows --- #}
    {%- for r in freshness_rows -%}
        
            {{ log("  " ~ (" " if r.get('status') == 'success' else " ") ~ " " ~ r.get('name') ~ " → " ~ r.get('message'), info=True) }}
            {%- do to_insert.append(
                "SELECT uuid() AS id"
                ~ ", '" ~ r.get('database_name') ~ "' AS database_name"
                ~ ", '" ~ r.get('schema_name')   ~ "' AS schema_name"
                ~ ", '" ~ r.get('name')          ~ "' AS name"
                ~ ", '" ~ r.get('model_name')    ~ "' AS model_name"
                ~ ", '" ~ r.get('source_name')    ~ "' AS source_name"
                ~ ", 0.0 AS execution_time"
                ~ ", '" ~ etl_date              ~ "' AS etl_date"
                ~ ", "  ~ r.get('sa')           ~ " AS started_at"
                ~ ", "  ~ r.get('ca')           ~ " AS completed_at"
                ~ ", 0 AS rows_affected"
                ~ ", '" ~ r.get('status')        ~ "' AS status"
                ~ ", '" ~ r.get('message')       ~ "' AS message"
                ~ ", '" ~ run_id   ~ "' AS run_id"
                ~ ", '" ~ job_id   ~ "' AS job_id"
                ~ ", '" ~ task_key ~ "' AS task_key"
            ) -%}
    {%- endfor -%}

    {%- if to_insert | length > 0 -%}
        {%- set insert_q -%}
            INSERT INTO `{{ cp_db }}`.`{{ cp_schema }}`.`{{ cp_table }}`
            (
                id, database_name, schema_name, name, model_name, source_name,
                execution_time, etl_date, started_at, completed_at, rows_affected,
                status, message, run_id, job_id, task_key,
                created_by, created_at, updated_by, updated_at
            )
            SELECT
                src.id, src.database_name, src.schema_name, src.name, src.model_name, src.source_name,
                src.execution_time, src.etl_date, src.started_at, src.completed_at, src.rows_affected,
                src.status, src.message, src.run_id, src.job_id, src.task_key,
                'dbt', CURRENT_TIMESTAMP, NULL, NULL
            FROM (
                {{ to_insert | join('\nUNION ALL\n') }}
            ) AS src
        {%- endset -%}
        {%- do run_query(insert_q) -%}
    {%- endif -%}

    {%- set skipped = (model_rows | length + freshness_rows | length) - to_insert | length -%}
    {{ log("  ✓ Appended " ~ to_insert | length ~ " record(s)." ~
           (" Kept " ~ skipped ~ " (already success/block, no overwrite)." if skipped > 0 else ""), info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log(" ", info=True) }}
    {{ return('') }}
{% endmacro %}
