{% macro checkpoint_database() %}
    {{ return(var('raw_vault_database', target.database)) }}
{% endmacro %}

{% macro checkpoint_schema() %}
    {{ return(var('raw_vault_schema', target.schema)) }}
{% endmacro %}

{% macro checkpoint_metadata_relation() %}
    {{ return(checkpoint_database() ~ '.' ~ checkpoint_schema() ~ '.checkpoint_etlpipeline_dbt_metadata') }}
{% endmacro %}

{% macro dq_test_log_relation() %}
    {{ return(checkpoint_database() ~ '.' ~ checkpoint_schema() ~ '.dq_test_log') }}
{% endmacro %}

{% macro parse_dbt_results(results) %}
    -- Create a list of parsed results
    {%- set parsed_results = [] %}
    -- Flatten results and add to list
    {% for run_result in results %}
        {% if run_result.node.resource_type == 'model' %}
        -- Convert the run result object to a simple dictionary
            {% set run_result_dict = run_result.to_dict() %}
            -- Get the underlying dbt graph node that was executed
            {% set node = run_result_dict.get('node') %}
            {% set rows_affected = run_result_dict.get('adapter_response', {}).get('rows_affected', 0) %}
            {%- if not rows_affected -%}
                {% set rows_affected = 0 %}
            {%- endif -%}

            {% set timing = run_result_dict.get('timing', []) %}
            {% if timing and timing | length > 0 %}
                {% set last_index = timing | length - 1 %}
                {% set started_at = timing[last_index].get('started_at') %}
                {% set completed_at = timing[last_index].get('completed_at') %}
            {% else %}
                {% set started_at = 'NULL' %}
                {% set completed_at = 'NULL' %}
            {% endif %}

            {% set table_name = node.get('alias', node.get('name')) %}

            {% set parsed_result_dict = {
                    'result_id': invocation_id ~ '.' ~ node.get('unique_id'),
                    'source_name': node.get('tags')[0],
                    'database_name': node.get('database'),
                    'schema_name': node.get('schema'),
                    'name': table_name,
                    'model_name': node.get('name'),
                    'execution_time': run_result_dict.get('execution_time'),
                    'rows_affected': rows_affected,
                    'status': run_result_dict.get('status'),
                    'message': run_result_dict.get('message'),
                    'started_at': started_at,
                    'completed_at': completed_at
                    } %}
                
            {% if parsed_result_dict['status'] == 'skipped' %}
                {% set parsed_result_dict = {
                    
                    'result_id': parsed_result_dict['result_id'],
                    'database_name': parsed_result_dict['database_name'],
                    'schema_name': parsed_result_dict['schema_name'],
                    'name': parsed_result_dict['name'],
                    'model_name': parsed_result_dict['model_name'],
                    'execution_time': parsed_result_dict['execution_time'],
                    'rows_affected': parsed_result_dict['rows_affected'],
                    'status': 'error',
                    'message': 'Error due to the ref table of ' ~ parsed_result_dict['model_name'] ~ ' having an issue',
                    'started_at': parsed_result_dict['started_at'],
                    'completed_at': parsed_result_dict['completed_at']
                } %}
            {% endif %}

            {% do parsed_results.append(parsed_result_dict) %}
        {% endif %}
    {% endfor %}
    {{ return(parsed_results) }}
{% endmacro %}

---

{% macro log_dbt_results(results) %}
    {%- if execute -%}
        {%- set parsed_results = parse_dbt_results(results) -%}
        -- get status of table in results
        {%- set table_names = [] %}
        {%- for parsed_result_dict in parsed_results -%}
            {%- set table_name = parsed_result_dict.get('name') -%}
            {%- set source_name = parsed_result_dict.get('source_name') -%}
            {%- set _ = table_names.append(table_name) %}
        {%- endfor -%}
        {%- set table_names_need_delete = [] %}
        -- delete table already success
        {%- for table_name in table_names -%}
            {%- set query -%}
                select
                    case 
                        when status = 'success' then 1
                        else 0
                    end as should_run
                from {{ checkpoint_metadata_relation() }}
                where name = '{{ table_name }}' and etl_date = '{{ var("target_date") }}' and source_name = '{{ source_name }}'
            {%- endset %}
            {%- set results = run_query(query) %}
            {%- set result_array = [] %}
            {% for row in results %}
                {%- set _ = result_array.append(row['should_run']) %}
            {% endfor %}

            {%- if result_array | max == 1 %}
                {%- set _ = table_names_need_delete.append(table_name) %}
            {%- endif %}
        {%- endfor -%}

        {%- set filtered_parsed_results = [] %}
        {%- for parsed_result_dict in parsed_results -%}
            {%- if parsed_result_dict.get('name') not in table_names_need_delete -%}
                {%- set _ = filtered_parsed_results.append(parsed_result_dict) %}
            {%- endif -%}
        {%- endfor -%}

        -- insert values into checkpoint
        {%- if filtered_parsed_results | length  > 0 -%}
            {% set insert_dbt_results_query -%}
                insert into {{ checkpoint_metadata_relation() }}
                    (
                        id,
                        database_name,
                        schema_name,
                        name,
                        model_name,
                        source_name,
                        execution_time,
                        etl_date,
                        started_at,
                        completed_at,
                        rows_affected,
                        status,
                        message,
                        run_id
                ) values
                    {%- for parsed_result_dict in filtered_parsed_results -%}

                        -- define start_time and end_time for model
                        {% if parsed_result_dict.get('started_at') == 'NULL' or parsed_result_dict.get('completed_at') == 'NULL' %}
                            {%- set started_at_time = "null" %}
                            {%- set completed_at_time = "null" %}
                        {% else %}
                            {%- set started_at_time = "'" ~ parsed_result_dict.get("started_at") ~ "'" %}
                            {%- set completed_at_time = "'" ~ parsed_result_dict.get("completed_at") ~ "'" %}
                        {% endif %}

                        (
                            '{{ parsed_result_dict.get('result_id') }}',
                            '{{ parsed_result_dict.get('database_name') }}',
                            '{{ parsed_result_dict.get('schema_name') }}',
                            '{{ parsed_result_dict.get('name') }}',
                            '{{ parsed_result_dict.get('model_name') }}',
                            '{{ parsed_result_dict.get("source_name") }}',
                            {{ parsed_result_dict.get('execution_time') }},
                            '{{ var("target_date") }}',
                            CAST({{started_at_time}} AS TIMESTAMP),
                            CAST({{completed_at_time}} AS TIMESTAMP),
                            {{ parsed_result_dict.get('rows_affected') }},
                            '{{ parsed_result_dict.get('status') }}',
                            '{{ parsed_result_dict.get('message') | replace("'", '"') }}',
                            '{{ env_var("_RUN_ID", invocation_id) }}'
                        ) {{- "," if not loop.last else "" -}}
                    {%- endfor -%}
            {%- endset -%}
            {%- do run_query(insert_dbt_results_query) -%}
        {%- endif -%}
    {%- endif -%}
    -- This macro is called from an on-run-end hook and therefore must return a query txt to run. Returning an empty string will do the trick
    {{ return ('') }}
{% endmacro %}

-- Check table metadata to create table
{% macro check_checkpoint_table() %}
    {{ return('') }}
{% endmacro %}

-- Check models that have run successfully to skip and run models that have not been successful
{% macro enable_model(i) %}
    {%- set model_name = i.alias -%}
    {%- set source_name = i.tags[0] -%}
    {%- set query -%}
        select
            case    
                when status = 'success' then 1
                else 0
            end as should_run
        from {{ checkpoint_metadata_relation() }}
        where name = '{{ model_name }}' and etl_date = '{{ var("target_date") }}' and source_name = '{{ source_name }}'
    {%- endset %}

    {%- if execute %}
        {%- set results = run_query(query) %}
        {%- set result_array = [] %}
        {% for row in results %}
            {%- set _ = result_array.append(row['should_run']) %}
        {% endfor %}

        {%- if result_array | max == 1 %}
            {%- if 'check_ref_tables' not in caller  %}
                {% do log("###### Model " ~ model_name ~ " has already run successfully. Skipping this model. ######", info=True) %}
            {%- endif %}
            {{ return(false) }}
        {%- else %}
            {%- if 'check_ref_tables' not in caller  %}
                {% do log("###### Prepare to run model " ~ model_name ~ " ######", info=True) %}
            {%- endif %}
            {{ return(true) }}
        {%- endif %}
    {%- endif %}

{%- endmacro %}

-- Check ref of table to run current model
{% macro check_ref_tables(i) %}
{%- set source_name = i.tags[0] -%}
{%- if enable_model(i)  %}
    {% do log("#### Checking ref tables ... ####", info=True) %}
    {%- set model_name = i.name -%}
    {%- set ref_models = i.refs -%}
    {%- set len_ref = ref_models | length -%}

    {%- set query_ref -%}
        WITH ranked_data AS (
            SELECT
                model_name,
                status,
                completed_at,
                ROW_NUMBER() OVER (PARTITION BY model_name ORDER BY completed_at DESC) AS row_num
            FROM {{ checkpoint_metadata_relation() }}
            WHERE 
                model_name IN (
                    {% for ref_model in ref_models %}
                        '{{ref_model.get('name')}}' {%- if not loop.last %} , {% endif %}
                    {% endfor %}
                )
                AND etl_date = '{{ var("target_date") }}'
                AND source_name = '{{ source_name }}'
        )
        SELECT
            CASE 
                WHEN status = 'error' OR status = 'skipped' THEN 1
                ELSE 0
            END AS should_run
        FROM ranked_data
        WHERE row_num = 1
    {%- endset %}

    {%- if execute -%}
        {%- set results_ref = run_query(query_ref) %}
        {%- set result_ref = [] %}
        {% for row in results_ref %}
            {%- set _ = result_ref.append(row['should_run']) %}
        {% endfor %}

        {%- set len_ref_with_status = result_ref | length -%}
        
        {%- if len_ref == 0 -%}
            {%- set _ = result_ref.append(0) %}
        {%- endif %}

        {%- if len_ref_with_status == 0 -%}
            {%- set _ = result_ref.append(1) %}
        {%- endif %}

        {%- if result_ref | max == 1 %}
            {{ exceptions.raise_compiler_error("#### Ref models " ~ ref_models ~ " have error => Can not start this model! ####") }}
        {% else %}
             {% do log("#### All ref models have run successfully! ####", info=True) %}
        {%- endif %}
    {%- endif -%}

{% do log("#### Checking test results ... ####", info=True) %}
    {%- set test_ref_query -%}
        WITH ranked_data AS (
            SELECT
                model_name,
                status,
                run_at,
                ROW_NUMBER() OVER (PARTITION BY model_name ORDER BY run_at DESC) AS row_num
            FROM {{ dq_test_log_relation() }}
            WHERE 
                model_name IN (
                    {% for ref_model in ref_models %}
                        '{{ref_model.get('name')}}' {%- if not loop.last %} , {% endif %}
                    {% endfor %}
                )
                AND etl_date = '{{ var("target_date") }}'
                AND record_source = '{{ source_name }}'
        )
        SELECT
            CASE 
                WHEN status = 'error' OR status = 'skipped' THEN 1
                ELSE 0
            END AS should_run
        FROM ranked_data
        WHERE row_num = 1
    {%- endset %}

    {%- if execute -%}
        {%- set failed_tests = run_query(test_ref_query) %}
        {%- set f_test = [] %}
        {% for row in failed_tests %}
            {%- set _ = f_test.append(row['should_run']) %}
        {% endfor %}

        {%- set len_test_with_status = f_test | length -%}
        
        {%- if len_ref == 0 -%}
            {%- set _ = f_test.append(0) %}
        {%- endif %}

        {%- if len_test_with_status == 0 -%}
            {%- set _ = f_test.append(1) %}
        {%- endif %}

        {%- if f_test | max == 1 %}
            {{ exceptions.raise_compiler_error("#### Ref models failed quality tests. Can not start this model! ####") }}
        {% else %}
            {% do log("#### All ref models have pass quality tests. Model " ~ model_name ~ "is ready to run. ####", info=True) %}
        {%- endif %}
    {%- endif -%}

{%- endif %}
{% endmacro %}

--LOG TEST RESULTS
{% macro log_test_results(results) %}
    {% for r in results %}
        {% if r.node.resource_type == 'test' %}

            {% set model_node_id = r.node.depends_on.nodes[0] %}
            {% set model_node = graph.nodes[model_node_id] %}
            {% set source_name = model_node.tags[0] if model_node.tags | length > 0 else 'unknown' %}

            {% set insert_sql %}
                insert into {{ dq_test_log_relation() }}
                values (
                    '{{var("target_date")}}',
                    '{{r.node.name}}',
                    '{{r.node.depends_on.nodes[0].split('.')[-1] if r.node.depends_on.nodes | length > 0 else 'unknown'}}',
                    '{{r.node.test_metadata.kwargs.get('column_name')}}',
                    '{{r.node.test_metadata.name}}',
                    '{{r.status}}',
                    {{r.failures | default(0)}},
                    {{"'" ~ (r.message|replace("'", "''")) ~ "'" if r.message else 'null'}},
                    {{r.execution_time | default(0)}},
                    current_timestamp(),
                    '{{source_name}}'
                )
            {% endset %}
            {%- do run_query(insert_sql) -%}
        {%- endif -%}
    {% endfor %}
{%- endmacro %}
