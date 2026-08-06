-- depends_on: {{ ref('v_stg_t24_t24_currency') }}
 
{{ config(
    alias = 'ref_currency',
    materialized = 'view',
    unique_key = ['id'],
    tags = ['t24', 'reference', 'phase1', 'all', 'bv_zonec']
) }}

{% set raw_sql -%}
select
    id,
    data_date,
    t_numeric_ccy_code,
    t_ccy_name,
    t_no_of_decimals,
    t_interest_day_basis,
    t_currency_market,
    t_mid_reval_rate,
    t_default_spread,
    t_buy_rate,
    t_sell_rate,
    t_negotiable_amt,
    t_reval_rate,
    t_central_rate,
    t_blocked_date,
    to_date(data_date, 'yyyyMMdd') as source_event_date,
    CONCAT('t24', '__', 't24_currency') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
from {{ ref('v_stg_t24_t24_currency') }}   
{%- endset %}
 
 
{{ raw_sql }}

