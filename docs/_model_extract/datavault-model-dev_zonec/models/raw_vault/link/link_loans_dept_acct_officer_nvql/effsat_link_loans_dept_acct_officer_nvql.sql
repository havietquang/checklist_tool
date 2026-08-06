{{ config(
    alias = 'effsat_link_loans_dept_acct_officer_nvql',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_loans_dept_acct_officer_nvql_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
) }}

{{ effsat(
    source_model = 'v_stg_t24_t24_loans_and_deposits',
    source_name = 't24',
    source_table = 't24_loans_and_deposits',
    unique_key = 'link_loans_dept_acct_officer_nvql_hashkey',
    source_business_key_cols = ['id', 't_mis_acct_officer'],
    link_model = 'link_loans_dept_acct_officer_nvql'
) }}
