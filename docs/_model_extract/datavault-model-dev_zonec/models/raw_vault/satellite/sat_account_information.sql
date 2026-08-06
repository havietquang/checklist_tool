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
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'sat_account_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['account_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'account', 'phase1', 'all']
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

{% set source_name = 't24' %}
{% set source_table = 't24_account' %}
{% set cols_name = ['a.t_account_title_1', 'a.t_account_title_2', 'a.t_short_title', 'a.t_opening_date', 'a.t_create_date', 'a.t_mature_date', 'a.t_value_date', 'a.t_term_xau', 'a.t_posting_restrict', 'a.t_record_status', 'a.t_alt_acct_id', 'a.t_joint_holder', 'a.t_arrangement_id', 'a.t_source_of_fund', 'a.t_ocb_beauty_sts', 'b.t_acct_close_date'] %}
{% set hashdiff_col = 'hashdiff_account_information' %}
{% set hub_hashkey = 'account_hashkey' %}

{% set raw_sql -%}
SELECT
    a.hashkey AS account_hashkey,
    {{  hash_column(cols_name, source_name) }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    a.t_account_title_1 AS t_account_title_1,
    a.t_account_title_2 AS t_account_title_2,
    a.t_short_title AS t_short_title,
    a.t_opening_date AS t_opening_date,
    a.t_create_date AS t_create_date,
    a.t_mature_date AS t_mature_date,
    a.t_value_date AS t_value_date,
    b.t_acct_close_date as t_acct_close_date,
    a.t_term_xau AS t_term_xau,
    a.t_posting_restrict AS t_posting_restrict,
    a.t_record_status AS t_record_status,
    a.t_alt_acct_id AS t_alt_acct_id,
    a.t_joint_holder AS t_joint_holder,
    a.t_arrangement_id AS t_arrangement_id,
    a.t_source_of_fund AS t_source_of_fund,
    a.t_ocb_beauty_sts AS t_ocb_beauty_sts
FROM {{ ref('v_stg_t24_t24_account') }} a
left join {{ ref('v_stg_t24_t24_account_closed') }} b on a.ID = b.ID
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

