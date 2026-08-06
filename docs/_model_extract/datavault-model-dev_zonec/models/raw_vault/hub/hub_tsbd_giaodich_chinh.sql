/*
NOTE: File nay dinh nghia hub_tsbd_giaodich_chinh voi hashkey la 'tsbd_giaodich_chinh_hashkey'
theo mapping logical moi. File hien co hub_giaodich_chinh_tsbd.sql dung hashkey 'ma_giao_dich_hashkey'
la ten cu - can xem xet thong nhat.
*/
{{ config(
    alias = 'hub_tsbd_giaodich_chinh',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_giaodich_chinh_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'tsbd_giaodich_chinh_hashkey' %}
{% set business_key = 'ma_giao_dich' %}
{% set source_table = 'tsbd_giaodich_chinh' %}
{% set source_model = 'v_stg_bpm_tsbd_giaodich_chinh' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}

