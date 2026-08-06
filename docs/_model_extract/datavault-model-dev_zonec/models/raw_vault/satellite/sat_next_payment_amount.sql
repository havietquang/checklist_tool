{{ config(
    alias = 'sat_next_payment_amount',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['consumer_loan_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_name = 'comb' %}
{% set source_table = 'next_payment_amount' %}
{% set hashdiff_col = 'hashdiff_next_payment_amount' %}
{% set hub_hashkey = 'consumer_loan_hashkey' %}
{% set source_model = 'v_stg_comb_next_payment_amount' %}
{% set list_cols = [
    'ma_key',
    'valuedate',
    'appid',
    'tenor',
    'period',
    'frequency',
    'duedate',
    'principal',
    'interest',
    'remainprincipal',
    'remaininterest',
    'remainppenalty',
    'remainipenalty',
    'remainpenalty',
    'currentdpd',
    'remainperiod',
    'createddate'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
