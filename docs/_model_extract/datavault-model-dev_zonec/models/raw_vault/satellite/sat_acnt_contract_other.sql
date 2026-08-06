{{ config(
    alias = 'sat_acnt_contract_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['acnt_contract_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set hashdiff_col = 'hashdiff_acnt_contract_other' %}
{% set hub_hashkey = 'acnt_contract_hashkey' %}

{% set raw_sql -%}
SELECT
    hashkey AS acnt_contract_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    terminal_category,
    f_i,
    service_group,
    old_pack,
    old_scheme,
    parent_product,
    product_prev,
    main_product,
    client_type,
    behavior_type_prev,
    old_curr,
    production_status,
    report_type,
    max_pin_attempts,
    pin_attempts,
    risk_scheme,
    risk_factor,
    risk_factor_prev,
    share_balance,
    is_multycurrency,
    enables_item,
    cycle_length,
    interval_type,
    status_category,
    limit_is_active,
    routing_idt,
    is_ready,
    settlement_type,
    auth_seq_n,
    apply_dt,
    local_version,
    remote_version,
    acnt_contract__id,
    liab_contract,
    product,
    liab_balance,
    liab_blocked,
    card_expire,
    rbs_member_id,
    chip_scheme,
    merchant_id,
    tr_title,
    tr_company,
    tr_country,
    tr_first_nam,
    tr_last_nam,
    tr_sic
FROM {{ ref('v_stg_way4_acnt_contract') }} 
WHERE amnd_state = 'A' AND source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

