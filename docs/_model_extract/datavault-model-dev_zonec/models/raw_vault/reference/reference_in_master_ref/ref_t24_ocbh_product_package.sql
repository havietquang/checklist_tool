-- depends_on: {{ ref('v_stg_t24_t24_ocbh_product_package') }}

{{ config(
    alias = 'ref_t24_ocbh_product_package',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 'package_register_fee', 'min_balance', 'begin_date', 'expire_date', 'service', 'ft_transaction_type', 'province_type', 'high_low_value', 'external_ft_fee', 'external_ft_comm_type', 'condition_group', 'min_average_balance', 'below_aver_bal_fee', 'atm_max_amt_trans', 'atm_max_daily_amt', 'atm_not_ocb_fee', 'withdraw_cash_tt_amt', 'withdraw_cash_tt_fee', 'withdraw_cash_tt_pl', 'ft_channel', 'internal_ft_fee', 'internal_ft_comm_type', 'bill_payment_fee', 'bill_payment_comm_type', 'package_customer_type', 'package_register_pl', 'below_aver_bal_pl', 'atm_not_ocb_pl'] -%}

{{ ref_table(
    src_table='t24_ocbh_product_package',
    src_type='product_package',
    src_code="id",
    src_des="package_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
