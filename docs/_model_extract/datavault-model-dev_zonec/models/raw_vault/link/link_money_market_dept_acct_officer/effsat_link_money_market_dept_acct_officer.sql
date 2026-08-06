{{ config(
    alias = 'effsat_link_money_market_dept_acct_officer',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_money_market_dept_acct_officer_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'money_market', 'phase1', 'all']
) }}

{{ effsat(
    source_model = 'v_stg_t24_t24_money_market',
    source_name = 't24',
    source_table = 't24_money_market',
    unique_key = 'link_money_market_dept_acct_officer_hashkey',
    source_business_key_cols = ['id', 't_mm_officer'],
    link_model = 'link_money_market_dept_acct_officer'
) }}
