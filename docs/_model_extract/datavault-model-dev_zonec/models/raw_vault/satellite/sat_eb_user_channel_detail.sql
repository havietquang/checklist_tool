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
unique_key          : Khoa dinh danh record (hub_hashkey + ma_key + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/

{{ config(
    alias = 'sat_eb_user_channel_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['eb_user_channel_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'eb_user_channel', 'zonec']
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
                          Co 'ma_key' -> macro tu bat logic multi-active.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
========================================================================
*/

{% set source_name = 'ocbchannel' %}
{% set source_table = 'eb_user_channel' %}
{% set hashdiff_col = 'hashdiff_eb_user_channel_detail' %}
{% set hub_hashkey = 'eb_user_channel_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_eb_user_channel' %}
{% set list_cols = ['ma_key', 'mobile_no', 'seri_hardtoken', 'user_assigned_token', 'assigned_token_datetime', 'user_role', 'channel_pincode', 'user_group', 'datetime_authorized', 'is_assigned_pki', 'user_assign_pki', 'datetime_assign_pki', 'source', 'fee_account', 'email', 'last_authen_update', 'omni_authentication_type', 'prev_mobile_no', 'soft_otp_company', 'is_asigned_using_api', 'first_login_time', 'last_login_time', 'last_change_pwd_date', 'last_change_pwd_channel', 'last_change_pwd_type', 'change_pwd_cust_type', 'login_attempt', 'soft_otp_active_status', 'soft_otp_active_date', 'signed_docs_downloadable', 'open_api_using', 'exception_limit', 'cd_using'] %}
{% set raw_sql = None %}

/*
Truong hop khong su dung marco satellite, co the su dung raw_sql nhu ben duoi de
viet SQL thu cong, sau do truyen vao macro satellite de tao satellite
*/
{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
