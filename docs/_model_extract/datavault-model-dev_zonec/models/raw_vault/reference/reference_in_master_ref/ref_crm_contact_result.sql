-- depends_on: {{ ref('v_stg_crm_crm_contact_result') }}

{{ config(
    alias = 'ref_crm_contact_result',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['crm', 'reference','phase2', 'all']
) }}

{% set list_cols = ['status', 'position', 'insurance', 'expired_card_prio', 'cust_group'] -%}

{{ ref_table(
    src_table='crm_contact_result',
    src_type='crm_contact_result',
    src_code="contact_result_id",
    src_des="contact_result_name",
    source_name='crm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
