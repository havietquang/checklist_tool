/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record mới/thay đổi
                    : 'table' = full load
                    : 'view' = chỉ tạo view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chỉ insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khóa định danh record (thường: hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/

{{ config(
    alias = 'sat_document_target',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['document_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'transaction', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Tên hệ thống nguồn, dùng để tạo giá trị cho cột `record_source`.
  - source_table        : Tên bảng nghiệp vụ ở hệ thống nguồn.
  - hashdiff_col        : Tên cột hashdiff đã được tính sẵn ở tầng staging.
  - hub_hashkey         : Tên khóa hash dùng để liên kết về bảng Hub.
  - source_model        : Model staging làm nguồn để đọc dữ liệu.
  - list_cols           : Danh sách các cột nghiệp vụ được lưu trong Satellite.
  - raw_sql (optional)  : Câu SQL tự viết trong trường hợp logic phức tạp hoặc đặc biệt.
*/

{% set source_name = 'way4' %}
{% set source_table = 'doc' %}
{% set hashdiff_col = 'hashdiff_document_target' %}
{% set hub_hashkey = 'document_hashkey' %}

{% set raw_sql -%}
SELECT
    hashkey AS document_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    target_number,
    target_channel,
    target_code,
    target_fee_code,
    t_cat,
    target_idt_scheme,
    target_member_id,
    target_bin_id,
    target_spc,
    target_acc_type,
    target_service,
    target_fee_curr,
    target_fee_amount,
    target_country
FROM {{ ref('v_stg_way4_doc') }}
WHERE amnd_state = 'A'
AND source_event_date= to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

