    /*
================================================================================
DBT CONFIGURATION GUIDE
================================================================================
materialized        : 'incremental' = load record moi/thay doi 
                    : 'table' = full load 
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert 
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record 
skip_matched_step   : true = bo record khong doi → tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'link_sc_trading_position_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_sc_trading_position_customer_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'security', 'phase1', 'all']
) }}

/*
================================================================================
LINK MACRO PARAMETERS
================================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + source_model       : model/view staging chua du lieu nguon (ten ref duoc dung trong FROM).
      + source_name        : namespace nguon (dung de tao record_source prefix).
      + source_table       : ten bang nguon cu the (dung de tao gia tri record_source).
      + unique_key         : ten cot hash key cua Link target.
      + source_business_key_cols: cot xac dinh duy nhat cung cap cho link hash.
      + foreign_business_key_cols: map hub_hashkey -> cot nguon.

================================================================================
*/

-- Extraction
{% set source_name = 't24' %}
{% set source_table = 't24_sc_trading_position' %}
{% set source_business_key_cols = ['id', 't_issuer'] %}
{% set sc_trading_position_business_key_cols = ['id'] %}
{% set customer_business_key_cols = ['t_issuer'] %}

{% set source_name = 't24' %}
{% set source_table = 't24_sc_trading_position' %}
{% set source_model = 'v_stg_t24_t24_sc_trading_position' %}
{% set unique_key = 'link_sc_trading_position_customer_hashkey' %}

/* 
Truong hop khong su dung marco link, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro link de tao link
*/
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['id', 't_issuer'],
    foreign_business_key_cols = {
        'sc_trading_position_hashkey': ['id'],
        'customer_hashkey': ['t_issuer']
    }
) }}

