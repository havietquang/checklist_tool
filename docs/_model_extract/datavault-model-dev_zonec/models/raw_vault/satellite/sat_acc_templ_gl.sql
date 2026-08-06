/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/

{{ config(
    alias = 'sat_acc_templ_gl',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['acc_templ_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'accounting', 'phase2', 'all']
) }}


/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Ten he thong nguon, dung de tao gia tri cho cot `record_source`.
  - source_table        : Ten bang nghiep vu o he thong nguon.
  - hashdiff_col        : Ten cot hashdiff da duoc tinh san o tang staging.
  - hub_hashkey         : Ten khoa hash dung de lien ket ve bang Hub.
  - source_model        : Model staging lam nguon de doc du lieu.
  - list_cols           : Danh sach cac cot nghiep vu duoc luu trong Satellite.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
*/

{% set source_name = 'way4' %}
{% set source_table = 'ows_acc_templ' %}
{% set hashdiff_col = 'hashdiff_acc_templ_gl' %}
{% set hub_hashkey = 'acc_templ_hashkey' %}
{% set source_model = 'v_stg_way4_acc_templ' %}
{% set list_cols = ['gl_credit', 'gl_debit', 'gl_turnover', 'gl_type', 'gl_number', 'hd_gl_number', 'gl_tariff', 'use_gl', 'account_numeration', 'acc_number_counter'] %}
{% set raw_sql %}
select
    hashkey as acc_templ_hashkey,
    hashdiff_acc_templ_gl as hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    current_timestamp as load_timestamp,
    concat('way4', '__', 'acc_templ') as record_source
        , gl_credit
        , gl_debit
        , gl_turnover
        , gl_type
        , gl_number
        , hd_gl_number
        , gl_tariff
        , use_gl
        , account_numeration
        , acc_number_counter
from {{ ref('v_stg_way4_acc_templ') }}
where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  and amnd_state = 'A'
{% endset %}


/* 
Truong hop khong su dung marco satellite, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro satellite de tao satellite
*/
{{ satellite(raw_sql=raw_sql, hub_hashkey=hub_hashkey) }}
