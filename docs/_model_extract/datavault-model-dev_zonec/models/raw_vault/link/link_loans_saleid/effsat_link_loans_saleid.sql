{{ config(
    alias = 'effsat_link_loans_saleid',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_loans_saleid_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
) }}

{{ effsat(
    source_model = 'v_stg_t24_t24_ld_extra_info',
    source_name = 't24',
    source_table = 't24_ld_extra_info',
    unique_key = 'link_loans_saleid_hashkey',
    source_business_key_cols = ['id', 't_sales_id'],
    link_model = 'link_loans_saleid'
) }}
