{#
  check_skip_model(current_model)
  Trả về:
    True     → đã success từ trước → SKIP
    'block'  → bị chặn do: freshness warning, test error, STG chưa run, hoặc RV upstream ngoài run → BLOCK (SQL OK, job xanh)
    False    → chạy bình thường
#}
{% macro check_skip_model(current_model) %}
    {%- if execute -%}
        {%- if not var('checkpoint_hooks_enabled', false) -%}
            {{ return(False) }}
        {%- endif -%}

        {# 1. Model này đã success từ trước → skip #}
        {%- if check_is_model_finished(current_model) -%}
            {{ return(True) }}
        {%- endif -%}

        {# 2. STG freshness warning → block (SQL OK, ghi 'block' vào checkpoint) #}
        {%- set freshness_result = check_is_source_freshness_failed(current_model) -%}
        {%- if freshness_result -%}
            {%- set reason = 'Blocked: freshness warning [' ~ freshness_result ~ ']' -%}
            {{ log("🚫 BLOCK: Model [" ~ current_model.name ~ "] " ~ reason, info=True) }}
            {%- do write_checkpoint_block(current_model, reason) -%}
            {{ return('block') }}
        {%- endif -%}

        {# 3. STG test error/fail → block (SQL OK, ghi 'block' vào checkpoint) #}
        {%- set test_result = check_is_staging_test_failed(current_model) -%}
        {%- if test_result -%}
            {%- set reason = 'Blocked: test error [' ~ test_result ~ ']' -%}
            {{ log("🚫 BLOCK: Model [" ~ current_model.name ~ "] " ~ reason, info=True) }}
            {%- do write_checkpoint_block(current_model, reason) -%}
            {{ return('block') }}
        {%- endif -%}

        {# 4. STG run chưa có success hôm nay → block #}
        {%- set stg_missing = check_is_staging_run_missing(current_model) -%}
        {%- if stg_missing -%}
            {%- set reason = 'Blocked: STG run not completed [' ~ stg_missing ~ ']' -%}
            {{ log("🚫 BLOCK: Model [" ~ current_model.name ~ "] " ~ reason, info=True) }}
            {%- do write_checkpoint_block(current_model, reason) -%}
            {{ return('block') }}
        {%- endif -%}

        {# 5. Upstream RV model ngoài run → block (ghi record, không raise error) #}
        {%- if check_has_rv_upstream_outside_run(current_model) -%}
            {%- set reason = 'Blocked: RV upstream outside current run' -%}
            {{ log("🚫 BLOCK: Model [" ~ current_model.name ~ "] " ~ reason, info=True) }}
            {%- do write_checkpoint_block(current_model, reason) -%}
            {{ return('block') }}
        {%- endif -%}

    {%- endif -%}
    {{ return(False) }}
{% endmacro %}


{% macro check_is_staging_test_failed(model_node) %}
    {%- set upstream_names = [] -%}
    {%- for node_id in model_node.depends_on.nodes -%}
        {%- if node_id.startswith('model.') -%}
            {%- set upstream_name = node_id.split('.')[-1] -%}
            {%- if upstream_name.startswith('v_stg_') -%}
                {%- do upstream_names.append("'" ~ upstream_name ~ "'") -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}

    {%- if upstream_names | length == 0 -%}
        {{ return(False) }}
    {%- endif -%}

    {%- if execute -%}
        {%- if not var('checkpoint_hooks_enabled', false) -%}
            {{ return(False) }}
        {%- endif -%}
        {%- set etl_date = var('target_date', '1900-01-01') -%}
        {%- set explicit_source_name = var('source_name', none) -%}
        {%- set node_tags = model_node.tags if model_node.tags is defined else [] -%}
        {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
            else (node_tags[0] if node_tags is iterable and node_tags is not string and (node_tags | length) > 0 else 'unknown') -%}
        {%- set query -%}
            WITH latest AS (
                SELECT
                    model_name,
                    status,
                    completed_at,
                    ROW_NUMBER() OVER (PARTITION BY model_name ORDER BY completed_at DESC) AS rn
                FROM `{{ var('checkpoint_database', target.database) }}`
                    .`{{ var('checkpoint_schema',   target.schema)   }}`
                    .`{{ var('checkpoint_table',    'etl_model_checkpoint') }}`
                WHERE model_name  IN ({{ upstream_names | join(', ') }})
                  AND etl_date    = '{{ etl_date }}'
                  AND source_name = '{{ source_name }}'
                  AND task_key    = 'test'
            )
            SELECT model_name FROM latest WHERE rn = 1 AND status IN ('fail', 'error')
        {%- endset -%}
        {%- set res = run_query(query) -%}
        {%- set failed_tests = res.columns[0].values() | list -%}

        {%- if failed_tests | length > 0 -%}
            {{ log("⚠️ TEST ERROR: Model [" ~ model_node.name ~ "] bị block vì staging test lỗi: ["
                   ~ failed_tests | join(', ') ~ "]", info=True) }}
            {{ return(failed_tests | join(', ')) }}
        {%- endif -%}
    {%- endif -%}

    {{ return(False) }}
{% endmacro %}


{% macro check_is_model_finished(node) %}
    {%- set model_name  = node.alias -%}
    {%- set etl_date    = var('target_date', '1900-01-01') -%}
    {%- set explicit_source_name = var('source_name', none) -%}
    {%- set node_tags = node.tags if node.tags is defined else [] -%}
    {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
        else (node_tags[0] if node_tags is iterable and node_tags is not string and (node_tags | length) > 0 else 'unknown') -%}

    {%- if execute -%}
        {%- set query -%}
            SELECT COUNT(1)
            FROM `{{ var('checkpoint_database', target.database) }}`
                .`{{ var('checkpoint_schema',   target.schema)   }}`
                .`{{ var('checkpoint_table',    'etl_model_checkpoint') }}`
            WHERE name        = '{{ model_name }}'
              AND etl_date    = '{{ etl_date }}'
              AND source_name = '{{ source_name }}'
              AND task_key    = 'run'
              AND status      = 'success'
        {%- endset -%}
        {%- set res = run_query(query) -%}
        {%- set cnt = res.columns[0].values()[0] | int -%}
        {%- if cnt > 0 -%}
            {{ log("⏭️ SKIP: Model [" ~ model_name ~ "] đã success cho etl_date=" ~ etl_date, info=True) }}
            {{ return(True) }}
        {%- else -%}
            {{ log("RUNNING: Model [" ~ model_name ~ "]...", info=True) }}
            {{ return(False) }}
        {%- endif -%}
    {%- else -%}
        {{ return(False) }}
    {%- endif -%}
{% endmacro %}


{% macro check_is_source_freshness_failed(model_node) %}
    {%- set freshness_keys = [] -%}
    {%- for node_id in model_node.depends_on.nodes -%}
        {%- if node_id.startswith('source.') -%}
            {%- set parts      = node_id.split('.') -%}
            {%- set identifier = parts[3] -%}
            {%- do freshness_keys.append("'" ~ identifier ~ "'") -%}
        {%- elif node_id.startswith('model.') -%}
            {%- set upstream_name = node_id.split('.')[-1] -%}
            {%- if upstream_name.startswith('v_stg_') -%}
                {%- do freshness_keys.append("'" ~ upstream_name ~ "'") -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}

    {%- if freshness_keys | length == 0 -%}
        {{ return(False) }}
    {%- endif -%}

    {%- if execute -%}
        {%- set explicit_source_name = var('source_name', none) -%}
        {%- set node_tags = model_node.tags if model_node.tags is defined else [] -%}
        {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
            else (node_tags[0] if node_tags is iterable and node_tags is not string and (node_tags | length) > 0 else 'unknown') -%}
        {%- set query -%}
            WITH latest AS (
                SELECT name, status,
                       ROW_NUMBER() OVER (PARTITION BY name ORDER BY completed_at DESC) AS rn
                FROM `{{ var('checkpoint_database', target.database) }}`
                    .`{{ var('checkpoint_schema',   target.schema)   }}`
                    .`{{ var('checkpoint_table',    'etl_model_checkpoint') }}`
                WHERE name        IN ({{ freshness_keys | join(', ') }})
                  AND etl_date    = '{{ var("target_date", "1900-01-01") }}'
                  AND source_name = '{{ source_name }}'
                  AND task_key    = 'freshness'
            )
            SELECT name FROM latest WHERE rn = 1 AND status = 'warning'
        {%- endset -%}
        {%- set res = run_query(query) -%}
        {%- set failed_sources = res.columns[0].values() | list -%}

        {%- if failed_sources | length > 0 -%}
            {{ log("⚠️ FRESHNESS WARNING: Model [" ~ model_node.name ~ "] bị block vì source không fresh: ["
                   ~ failed_sources | join(', ') ~ "]", info=True) }}
            {{ return(failed_sources | join(', ')) }}
        {%- endif -%}
    {%- endif -%}

    {{ return(False) }}
{% endmacro %}


{#
  Kiểm tra upstream v_stg_* chưa có record success hôm nay (task_key='run').
  Nếu thiếu → trả tên các model chưa chạy để check_skip_model ghi 'block'.
#}
{% macro check_is_staging_run_missing(model_node) %}
    {%- set upstream_names = [] -%}
    {%- for node_id in model_node.depends_on.nodes -%}
        {%- if node_id.startswith('model.') -%}
            {%- set upstream_name = node_id.split('.')[-1] -%}
            {%- if upstream_name.startswith('v_stg_') -%}
                {%- do upstream_names.append(upstream_name) -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}

    {%- if upstream_names | length == 0 -%}
        {{ return(False) }}
    {%- endif -%}

    {%- if execute -%}
        {%- if not var('checkpoint_hooks_enabled', false) -%}
            {{ return(False) }}
        {%- endif -%}
        {%- set etl_date = var('target_date', '1900-01-01') -%}
        {%- set explicit_source_name = var('source_name', none) -%}
        {%- set node_tags = model_node.tags if model_node.tags is defined else [] -%}
        {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
            else (node_tags[0] if node_tags is iterable and node_tags is not string and (node_tags | length) > 0 else 'unknown') -%}

        {%- set quoted_names = [] -%}
        {%- for n in upstream_names -%}
            {%- do quoted_names.append("'" ~ n ~ "'") -%}
        {%- endfor -%}

        {%- set query -%}
            SELECT DISTINCT model_name
            FROM `{{ var('checkpoint_database', target.database) }}`
                .`{{ var('checkpoint_schema',   target.schema)   }}`
                .`{{ var('checkpoint_table',    'etl_model_checkpoint') }}`
            WHERE model_name  IN ({{ quoted_names | join(', ') }})
              AND etl_date    = '{{ etl_date }}'
              AND source_name = '{{ source_name }}'
              AND task_key    = 'run'
              AND status      = 'success'
        {%- endset -%}
        {%- set res = run_query(query) -%}
        {%- set ran_ok = res.columns[0].values() | list -%}

        {%- set missing = [] -%}
        {%- for name in upstream_names -%}
            {%- if name not in ran_ok -%}
                {%- do missing.append(name) -%}
            {%- endif -%}
        {%- endfor -%}

        {%- if missing | length > 0 -%}
            {{ log("⚠️ STG NOT RUN: Model [" ~ model_node.name ~ "] bị block vì staging chưa run thành công: ["
                   ~ missing | join(', ') ~ "]", info=True) }}
            {{ return(missing | join(', ')) }}
        {%- endif -%}
    {%- endif -%}

    {{ return(False) }}
{% endmacro %}


{#
  Kiểm tra upstream là RV model (không phải v_stg_) nằm ngoài selected_resources.
  Nếu có → trả True để check_skip_model ghi 'block' và return 'block' (không raise error).
#}
{% macro check_has_rv_upstream_outside_run(model_node) %}
    {%- for node_id in model_node.depends_on.nodes -%}
        {%- if node_id.startswith('model.') and node_id not in selected_resources -%}
            {%- set upstream_name = node_id.split('.')[-1] -%}
            {%- if not upstream_name.startswith('v_stg_') -%}
                {{ return(True) }}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(False) }}
{% endmacro %}


{#
  Ghi trực tiếp record status='block' vào bảng checkpoint.
  Gọi khi model bị block do freshness warning hoặc test error.
#}
{% macro write_checkpoint_block(model, reason) %}
    {%- if not execute -%}{{ return('') }}{%- endif -%}
    {%- set cp_db     = var('checkpoint_database', target.database) -%}
    {%- set cp_schema = var('checkpoint_schema',   target.schema)   -%}
    {%- set cp_table  = var('checkpoint_table',    'etl_model_checkpoint') -%}
    {%- set etl_date  = var('target_date', '1900-01-01') -%}
    {%- set job_id    = var('job_id',   'None')        -%}
    {%- set task_key  = var('task_key', 'run')         -%}
    {%- set run_id    = var('run_id',   invocation_id) -%}
    {%- set explicit_source_name = var('source_name', none) -%}
    {%- set node_tags = model.tags if model.tags is defined else [] -%}
    {%- set source_name = explicit_source_name if explicit_source_name not in (none, '', 'unknown', 'None')
        else (node_tags[0] if node_tags is iterable and node_tags is not string and (node_tags | length) > 0 else 'unknown') -%}
    {%- set now_str = modules.datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S') -%}
    {%- set safe_reason = reason | replace("'", "\\'") -%}
    {%- set insert_q -%}
        INSERT INTO `{{ cp_db }}`.`{{ cp_schema }}`.`{{ cp_table }}`
        (id, database_name, schema_name, name, model_name, source_name,
         execution_time, etl_date, started_at, completed_at, rows_affected,
         status, message, run_id, job_id, task_key,
         created_by, created_at, updated_by, updated_at)
        SELECT
            uuid(),
            '{{ model.database }}', '{{ model.schema }}',
            '{{ model.alias }}', '{{ model.name }}', '{{ source_name }}',
            0.0, '{{ etl_date }}',
            CAST('{{ now_str }}' AS TIMESTAMP), CAST('{{ now_str }}' AS TIMESTAMP),
            0, 'block', '{{ safe_reason }}',
            '{{ run_id }}', '{{ job_id }}', '{{ task_key }}',
            'dbt', CURRENT_TIMESTAMP, NULL, NULL
    {%- endset -%}
    {%- do run_query(insert_q) -%}
{% endmacro %}
