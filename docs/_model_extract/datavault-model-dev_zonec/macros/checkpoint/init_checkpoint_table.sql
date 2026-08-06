{% macro init_checkpoint_table() %}
    {%- if execute -%}

        {%- set cp_db     = var('checkpoint_database', target.database) -%}
        {%- set cp_schema = var('checkpoint_schema',   target.schema)   -%}

        {# 1. Bảng checkpoint chính #}
        {%- set q -%}
            CREATE TABLE IF NOT EXISTS `{{ cp_db }}`.`{{ cp_schema }}`.`{{ var('checkpoint_table', 'etl_model_checkpoint') }}` (
                id              STRING,
                run_id          STRING,
                job_id          STRING,
                task_key        STRING,
                database_name   STRING,
                schema_name     STRING,
                name            STRING,
                model_name      STRING,
                source_name     STRING,
                execution_time  DOUBLE,
                etl_date        STRING,
                started_at      TIMESTAMP,
                completed_at    TIMESTAMP,
                rows_affected   BIGINT,
                status          STRING,
                message         STRING,
                created_by      STRING,
                created_at      TIMESTAMP,
                updated_by      STRING,
                updated_at      TIMESTAMP
            ) USING DELTA
        {%- endset -%}
        {%- do run_query(q) -%}

        {# 2. Bảng log schema drift #}
        {%- set q -%}
            CREATE TABLE IF NOT EXISTS `{{ cp_db }}`.`{{ cp_schema }}`.`{{ var('checkpoint_drift_table', 'etl_schema_drift_log') }}` (
                id              STRING,
                log_time        TIMESTAMP,
                run_id          STRING,
                job_id          STRING,
                task_key        STRING,
                model_name      STRING,
                etl_date        STRING,
                target_database STRING,
                target_schema   STRING,
                added_columns   STRING,
                removed_columns STRING,
                action_taken    STRING,
                created_by      STRING,
                created_at      TIMESTAMP,
                updated_by      STRING,
                updated_at      TIMESTAMP
            ) USING DELTA
        {%- endset -%}
        {%- do run_query(q) -%}

        {# 3. Bảng consolidate test #}
        {%- set q -%}
            CREATE TABLE IF NOT EXISTS `{{ cp_db }}`.`{{ cp_schema }}`.`{{ var('checkpoint_table_consolidate', 'etl_source_image_consolidate') }}` (
                id            STRING,
                check_time    TIMESTAMP,
                run_id        STRING,
                job_id        STRING,
                task_key      STRING,
                model_name    STRING,
                etl_date      STRING,
                source_count  BIGINT,
                target_count  BIGINT,
                diff_count    BIGINT,
                created_by    STRING,
                created_at    TIMESTAMP,
                updated_by    STRING,
                updated_at    TIMESTAMP
            ) USING DELTA
        {%- endset -%}
        {%- do run_query(q) -%}

        {# 4. Bảng quality check (dbt test results) #}
        {%- set q -%}
            CREATE TABLE IF NOT EXISTS `{{ cp_db }}`.`{{ cp_schema }}`.`{{ var('quality_check_table', 'etl_quality_check') }}` (
                id            STRING,
                run_id        STRING,
                job_id        STRING,
                task_key      STRING,
                test_name     STRING,
                model_name    STRING,
                column_name   STRING,
                severity      STRING,
                status        STRING,
                message       STRING,
                compiled_sql  STRING,
                source_name   STRING,
                etl_date      STRING,
                started_at    TIMESTAMP,
                completed_at  TIMESTAMP,
                created_by    STRING,
                created_at    TIMESTAMP,
                updated_by    STRING,
                updated_at    TIMESTAMP
            ) USING DELTA
        {%- endset -%}
        {%- do run_query(q) -%}

    {%- endif -%}
{% endmacro %}
