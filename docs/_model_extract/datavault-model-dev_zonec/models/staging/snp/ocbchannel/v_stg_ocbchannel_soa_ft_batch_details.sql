/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/

{{ config(
    alias = 'v_stg_ocbchannel_soa_ft_batch_details',
    materialized = 'view',
    tags = ['ocbchannel', 'soa_ft_batch_details', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('ocbchannel'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('soa_ft_batch_details'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['batch_id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "ocbchannel" -%}
{% set source_table = "soa_ft_batch_details" -%}
{% set business_key_cols = ['batch_id'] -%}
{% set ma_key_expr = "cast(src.item_id as string)" -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}
{% set hashdiff_satellite_dict =
{
    'hashdiff_soa_ft_batch_details': ['ma_key', 'item_id', 'item_no', 'serial_no', 'ft_no', 'debit_account', 'credit_account', 'beneficiary_account', 'trans_type', 'amount_input', 'amount', 'currency', 'cif', 'beneficiary_bank_branch_code', 'beneficiary_bank_name', 'fee_amount', 'validate_status', 'validate_code', 'validate_string', 'is_processing', 'time_begin_process', 'date_created', 'item_type', 'err_code', 'err_message', 'branch_code', 't24_trans_type', 'description', 'status', 'trans_no', 'last_access', 'processing_by', 'status_description', 'ft_date', 'beneficiary', 'prev_status', 'last_updated', 'commissioncode', 'comissiontype', 'user_t24_created', 'source', 'source_ref', 'note', 'bc_bank_sort_code', 'account_name_input', 'beneficiary_address', 'profit_cif', 'virtual_account']
}
-%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngan macro chay luc dbt parse/compile
(tranh loi khi chua co context thuc thi).
Macro `stage()` se sinh ra cau SELECT day du gom:
  - Tat ca cot goc tu source
  - Cot hashkey (hash cua business_key_cols)
  - Cac cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
with source_data as (
    select
        {% for column in columns %}src.{{ column.name }},
        {% endfor %}
        {{ ma_key_expr }} as ma_key
    from {{ source(source_name, source_table) }} src
    where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
)

select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}{{ column.name }},
    {% endfor %}

    --DERIVED BUSINESS KEYS
    ma_key,

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from source_data
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_event_date_dttype=source_event_date_dttype,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
