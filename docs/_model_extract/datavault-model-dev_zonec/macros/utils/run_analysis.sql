/*
================================================================================
MACRO: run_analysis / run_analyses
================================================================================
Mục đích:
  Chạy các file SQL trong thư mục analyses/ trên Databricks Serverless Warehouse.
  File analyses được compile bởi dbt, lưu lên Unity Catalog Volume, rồi đọc lại
  qua read_files() để execute.

--------------------------------------------------------------------------------
SETUP (một lần)
--------------------------------------------------------------------------------
Đảm bảo Unity Catalog Volume đã tồn tại:
  /Volumes/<catalog>/<schema>/<volume_name>/

--------------------------------------------------------------------------------
BƯỚC 1 — dbt compile
--------------------------------------------------------------------------------
Compile để resolve Jinja {{ var() }} và ghi file SQL thuần vào Volume:

  dbt compile \
    --select <tên_file_analyses> \
    --target-path /Volumes/<catalog>/<schema>/<volume_name> \
    --vars '{"env":"dev","start_date":"20250101","end_date":"20250101"}'

Ví dụ:
  dbt compile \
    --select reinstalls \
    --target-path /Volumes/ocb_datavault_dev_cleaned/raw_vault/dbt-target/\
    --vars '{"env":"dev","start_date":"20250101","end_date":"20250101"}'

--------------------------------------------------------------------------------
BƯỚC 2 — dbt run-operation
--------------------------------------------------------------------------------
Chạy 1 file:
  dbt run-operation run_analysis \
    --args '{"analysis_path": "phase2/appsflyer/reinstalls"}' \
    --vars '{"dbt_target_volume": "/Volumes/ocb_datavault_dev_cleaned/raw_vault/dbt-target"}'

Chạy nhiều file:
  dbt run-operation run_analyses \
    --args '{"analysis_paths": ["phase2/appsflyer/reinstalls", "phase2/appsflyer/in_app_events_report"]}' \
    --vars '{"dbt_target_volume": "/Volumes/ocb_datavault_dev_cleaned/raw_vault/dbt-target"}'

--------------------------------------------------------------------------------
THAM SỐ
--------------------------------------------------------------------------------
  analysis_path  : đường dẫn tương đối trong analyses/, không có .sql
                   ví dụ: "phase2/appsflyer/reinstalls"
  analysis_paths : list các analysis_path để chạy tuần tự

  var bắt buộc:
    dbt_target_volume : đường dẫn Volume dùng làm target-path ở Bước 1
                        ví dụ: /Volumes/ocb_datavault_dev_cleaned/raw_vault/dbt-target
================================================================================
*/


{% macro _execute_sql_content(content) %}
  {% set statements = content.split(';') %}
  {% for stmt in statements %}
    {% set clean = stmt.strip() %}
    {% if clean | length > 0 %}
      {% do log('>> ' ~ clean[:100] ~ '...', info=True) %}
      {% do run_query(clean) %}
      {% do log('OK', info=True) %}
    {% endif %}
  {% endfor %}
{% endmacro %}


{% macro run_analysis(analysis_path) %}
  {% set volume_root = var('dbt_target_volume') %}
  {% set file_path = volume_root ~ '/compiled/' ~ project_name ~ '/analyses/' ~ analysis_path ~ '.sql' %}

  {% do log('=== Reading: ' ~ file_path ~ ' ===', info=True) %}
  {% if execute %}
    {% set results = run_query("SELECT cast(content as STRING) FROM read_files('" ~ file_path ~ "', format => 'binaryFile') LIMIT 1") %}
    {% if results and results.rows | length > 0 %}
      {% do log('=== Executing ===', info=True) %}
      {{ _execute_sql_content(results.rows[0][0]) }}
      {% do log('=== DONE: ' ~ analysis_path ~ ' ===', info=True) %}
    {% else %}
      {{ exceptions.raise_compiler_error('File not found: ' ~ file_path ~ '. Chạy dbt compile trước.') }}
    {% endif %}
  {% endif %}
{% endmacro %}


{% macro run_analyses(analysis_paths) %}
  {% for path in analysis_paths %}
    {{ run_analysis(path) }}
  {% endfor %}
{% endmacro %}
