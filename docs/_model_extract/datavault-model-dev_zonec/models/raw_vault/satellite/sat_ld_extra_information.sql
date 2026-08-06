{{ config(
    alias = 'sat_ld_extra_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['loans_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_ld_extra_info' %}
{% set hashdiff_col = 'hashdiff_ld_extra_information' %}
{% set hub_hashkey = 'loans_hashkey' %}
{% set source_model = 'v_stg_t24_t24_ld_extra_info' %}
{% set list_cols = ['t_note', 't_record_status', 't_curr_no', 't_inputter', 't_authoriser', 't_date_time', 't_ftp_int_rate_tp', 't_ocbint_chg_date', 't_ftp_nd_term_int', 't_ftp_fee_repaid'] %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}

