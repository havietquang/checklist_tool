{{ config(
    alias = 'effsat_link_forex_dept_acct_officer',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_forex_dept_acct_officer_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'forex', 'phase1', 'all']
) }}

{{ effsat(
    source_model = 'v_stg_t24_t24_forex',
    source_name = 't24',
    source_table = 't24_forex',
    unique_key = 'link_forex_dept_acct_officer_hashkey',
    source_business_key_cols = ['id', 't_account_officer'],
    link_model = 'link_forex_dept_acct_officer'
) }}
