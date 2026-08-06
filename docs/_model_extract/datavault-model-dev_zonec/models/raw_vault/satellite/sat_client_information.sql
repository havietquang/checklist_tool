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
    alias = 'sat_client_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['client_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'entity', 'phase1', 'all']
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
{% set source_table = 'client' %}
{% set hashdiff_col = 'hashdiff_client_information' %}
{% set hub_hashkey = 'client_hashkey' %}
{% set raw_sql -%}
SELECT
    hashkey AS client_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    short_name,
    first_nam,
    last_nam,
    tr_first_nam,
    tr_last_nam,
    tr_title,
    birth_date,
    birth_place,
    gender,
    reg_number_type,
    reg_number,
    reg_details,
    citizenship,
    profession,
    marital_status,
    language,
    delivery_type,
    father_s_nam,
    mother_s_nam,
    itn,
    social_number,
    tax_position,
    company_nam,
    trade_nam,
    company_department,
    tr_company_nam,
    date_open,
    date_expire,
    enable_affiliation,
    affiliation_type
FROM {{ ref('v_stg_way4_client') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND amnd_state = 'A'
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    source_name=source_name,
    hub_hashkey=hub_hashkey,
    raw_sql=raw_sql
) }}

