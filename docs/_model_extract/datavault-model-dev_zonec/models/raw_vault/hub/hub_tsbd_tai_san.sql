/*
NOTE: File nay dinh nghia hub_tsbd_tai_san voi hashkey la 'tsbd_tai_san_hashkey'
theo mapping logical moi. File hien co hub_tai_san.sql dung hashkey 'tai_san_hashkey'
la ten cu - can xem xet thong nhat.
*/
{{ config(
    alias = 'hub_tsbd_tai_san',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_tai_san_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'tsbd_tai_san_hashkey' %}
{% set business_key = 'ma_tai_san' %}
{% set source_table = 'tsbd_tai_san' %}
{% set source_model = 'v_stg_bpm_tsbd_tai_san' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}

