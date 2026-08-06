{% macro log_test_results_to_db(results) %}
    {%- if not execute -%}{{ return('') }}{%- endif -%}
    {%- if not var('checkpoint_hooks_enabled', false) -%}
        {{ return('') }}
    {%- endif -%}
 
    {%- set test_results = [] -%}
    {%- for r in results -%}
        {%- set d    = r.to_dict() -%}
        {%- set node = d.get('node', {}) -%}
        {%- if node.get('resource_type') == 'test' -%}
            {%- do test_results.append(r) -%}
        {%- endif -%}
    {%- endfor -%}
 
    {%- if test_results | length == 0 -%}{{ return('') }}{%- endif -%}
 
    {{ log(" ", info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log("          🧪 on-run-end [2/2] WRITING QUALITY CHECK TO DATABASE", info=True) }}
    {{ log("--------------------------------------------------------------------------------", info=True) }}
 
    {%- set cp_db     = var('checkpoint_database', target.database) -%}
    {%- set cp_schema = var('checkpoint_schema',   target.schema)   -%}
    {%- set cp_table  = var('checkpoint_table', 'etl_model_checkpoint') -%}
    {%- set qc_table  = var('quality_check_table', 'etl_quality_check') -%}
    {%- set etl_date    = var('etl_date', var('target_date', '1900-01-01'))  -%}
    {%- set explicit_source_name = var('source_name', none) -%}
    {%- set run_id      = var('run_id',      invocation_id) -%}
    {%- set job_id      = var('job_id',      'None')        -%}
    {%- set task_key    = var('task_key',    'None')        -%}
 
    {%- set checkpoint_rows = [] -%}
    {%- set quality_rows = [] -%}
    {%- for r in test_results -%}
        {%- set d    = r.to_dict() -%}
        {%- set node = d.get('node', {}) -%}
 
        {# test_name: lấy từ alias (vd: not_null_stg_customers_customer_id) #}
        {%- set test_name   = node.get('alias', node.get('name', 'unknown')) -%}
 
        {# model_name: lấy từ attached_node (model đang được test) #}
        {%- set attached    = node.get('attached_node', '') -%}
        {%- set model_name  = attached.split('.')[-1] if attached else '' -%}
        {%- set attached_model = graph.nodes.get(attached, {}) if attached else {} -%}
        {%- set attached_path = attached_model.get('original_file_path', '') -%}
        {%- set attached_database = attached_model.get('database', target.database) -%}
        {%- set attached_schema = attached_model.get('schema', target.schema) -%}
        {%- set attached_tags = attached_model.get('tags', []) -%}
        {%- set is_staging_test = attached_path.startswith('models/staging/') -%}
 
        {# column_name: lấy từ column_name trong test config #}
        {%- set col         = node.get('column_name', '') -%}
        {%- set column_name = col if col else '' -%}
 
        {# source_name: ưu tiên var explicit, fallback sang tag đầu tiên của test node #}
        {%- set node_tags = node.get('tags', []) -%}
        {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
            else (
                node_tags[0] if node_tags is iterable and node_tags is not string and (node_tags | length) > 0
                else (
                    attached_tags[0] if attached_tags is iterable and attached_tags is not string and (attached_tags | length) > 0
                    else 'unknown'
                )
            ) -%}
 
        {%- set severity     = node.get('config', {}).get('severity', 'error') | lower -%}
        {%- set raw_status   = d.get('status', 'error') | lower -%}
        {%- set compiled_sql = node.get('compiled_code', node.get('compiled_sql', '')) | replace("'", "\\'") -%}
 
        {# pass/warn → pass, fail/error → fail #}
        {%- set status  = 'pass' if raw_status in ('pass', 'warn') else 'fail' -%}
        {%- set message = d.get('message', '') | replace("'", "\\'") -%}
 
        {%- set timing = d.get('timing', []) -%}
        {%- if timing | length > 0 -%}
            {%- set sa = "CAST('" ~ timing[-1].get('started_at')   ~ "' AS TIMESTAMP)" -%}
            {%- set ca = "CAST('" ~ timing[-1].get('completed_at') ~ "' AS TIMESTAMP)" -%}
        {%- else -%}
            {%- set sa = 'NULL' -%}
            {%- set ca = 'NULL' -%}
        {%- endif -%}
 
        {{ log("  " ~ ("✅" if status == 'pass' else "❌") ~ " [" ~ status ~ "] " ~ test_name, info=True) }}
 
        {%- if is_staging_test -%}
            {%- set checkpoint_message = "Test [" ~ severity ~ "] " ~ test_name ~ " => " ~ status
                ~ (" | " ~ message if message else "") -%}
            {%- do checkpoint_rows.append(
                "SELECT uuid() AS id"
                ~ ", '" ~ attached_database ~ "' AS database_name"
                ~ ", '" ~ attached_schema   ~ "' AS schema_name"
                ~ ", '" ~ test_name         ~ "' AS name"
                ~ ", '" ~ model_name        ~ "' AS model_name"
                ~ ", '" ~ source_name       ~ "' AS source_name"
                ~ ", 0.0 AS execution_time"
                ~ ", '" ~ etl_date          ~ "' AS etl_date"
                ~ ", "  ~ sa                ~ " AS started_at"
                ~ ", "  ~ ca                ~ " AS completed_at"
                ~ ", 0 AS rows_affected"
                ~ ", '" ~ status            ~ "' AS status"
                ~ ", '" ~ checkpoint_message ~ "' AS message"
                ~ ", '" ~ run_id            ~ "' AS run_id"
                ~ ", '" ~ job_id            ~ "' AS job_id"
                ~ ", '" ~ task_key          ~ "' AS task_key"
            ) -%}
        {%- else -%}
            {%- do quality_rows.append(
                "SELECT uuid() AS id"
                ~ ", '" ~ run_id      ~ "' AS run_id"
                ~ ", '" ~ job_id      ~ "' AS job_id"
                ~ ", '" ~ task_key    ~ "' AS task_key"
                ~ ", '" ~ test_name   ~ "' AS test_name"
                ~ ", '" ~ model_name  ~ "' AS model_name"
                ~ ", '" ~ column_name ~ "' AS column_name"
                ~ ", '" ~ severity    ~ "' AS severity"
                ~ ", '" ~ status      ~ "' AS status"
                ~ ", '" ~ message     ~ "' AS message"
                ~ ", '" ~ compiled_sql ~ "' AS compiled_sql"
                ~ ", '" ~ source_name ~ "' AS source_name"
                ~ ", '" ~ etl_date    ~ "' AS etl_date"
                ~ ", "  ~ sa          ~ " AS started_at"
                ~ ", "  ~ ca          ~ " AS completed_at"
            ) -%}
        {%- endif -%}
    {%- endfor -%}
 
    {%- if checkpoint_rows | length > 0 -%}
        {%- set checkpoint_insert_q -%}
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
                {{ checkpoint_rows | join('\nUNION ALL\n') }}
            ) AS src
        {%- endset -%}
        {%- do run_query(checkpoint_insert_q) -%}
    {%- endif -%}

    {# Chia batch để tránh query quá lớn khi append raw_vault test history #}
    {%- set batch_size = 200 -%}
    {%- if quality_rows | length > 0 -%}
        {%- for i in range(0, quality_rows | length, batch_size) -%}
            {%- set batch = quality_rows[i:i+batch_size] -%}
            {%- set insert_q -%}
                INSERT INTO `{{ cp_db }}`.`{{ cp_schema }}`.`{{ qc_table }}`
                (
                    id, run_id, job_id, task_key,
                    test_name, model_name, column_name, severity,
                    status, message, compiled_sql, source_name, etl_date,
                    started_at, completed_at,
                    created_by, created_at, updated_by, updated_at
                )
                SELECT
                    src.id, src.run_id, src.job_id, src.task_key,
                    src.test_name, src.model_name, src.column_name, src.severity,
                    src.status, src.message, src.compiled_sql, src.source_name, src.etl_date,
                    src.started_at, src.completed_at,
                    'dbt', CURRENT_TIMESTAMP, NULL, NULL
                FROM (
                    {{ batch | join('\nUNION ALL\n') }}
                ) AS src
            {%- endset -%}
            {%- do run_query(insert_q) -%}
            {{ log("    ↳ Batch " ~ loop.index ~ "/" ~ ((quality_rows | length - 1) // batch_size + 1) ~ " appended (" ~ batch | length ~ " rows)", info=True) }}
        {%- endfor -%}
    {%- endif -%}
 
    {{ log("  ✓ Appended " ~ checkpoint_rows | length ~ " staging test record(s) to checkpoint.", info=True) }}
    {{ log("  ✓ Appended " ~ quality_rows | length ~ " raw_vault test record(s) to quality check in "
        ~ ((quality_rows | length - 1) // batch_size + 1 if quality_rows | length > 0 else 0) ~ " batch(es).", info=True) }}
    {{ log("================================================================================", info=True) }}
    {{ log(" ", info=True) }}
    {{ return('') }}
{% endmacro %}
