-- depends_on: {{ ref('v_stg_t24_t24_prod_package_cb') }}

{{ config(
    alias = 'ref_t24_prod_package_cb',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference','phase2', 'all']
) }}

{% set list_cols = ['data_date', 't_ac_manage_fee_per', 't_ext_ft_fee_per', 't_ib_fee_per', 't_tax_fee_per', 't_sms_fee_per', 't_record_status', 't_curr_no', 't_inputter', 't_date_time', 't_authoriser', 't_co_code', 't_dept_code', 't_package_fdate', 't_package_tdate', 't_ac_manage_fee_term', 't_ext_ft_fee_term', 't_ib_fee_term', 't_tax_fee_term', 't_sms_fee_term', 't_ac_min_avr_balance', 't_batch_ft_fee_per', 't_batch_ft_fee_term', 't_ft_8s_fee_per', 't_ft_8s_fee_term', 't_ext_fo_fee_per', 't_ext_fo_fee_term', 't_avr_balance_from', 't_avr_balance_to', 't_ac_manage_fee'] -%}

{{ ref_table(
    src_table='t24_prod_package_cb',
    src_type='prod_package_cb',
    src_code="id",
    src_des="t_package_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
