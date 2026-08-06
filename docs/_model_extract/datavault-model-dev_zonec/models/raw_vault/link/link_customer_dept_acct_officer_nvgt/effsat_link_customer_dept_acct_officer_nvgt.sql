{{ config(
    alias = 'effsat_link_customer_dept_acct_officer_nvgt',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_customer_dept_acct_officer_nvgt_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'entity', 'phase1', 'all']
) }}

{{ effsat(
    source_model = 'v_stg_t24_t24_customer',
    source_name = 't24',
    source_table = 't24_customer',
    unique_key = 'link_customer_dept_acct_officer_nvgt_hashkey',
    source_business_key_cols = ['id', 'ac_middleman'],
    link_model = 'link_customer_dept_acct_officer_nvgt'
) }}
