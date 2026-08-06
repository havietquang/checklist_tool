{{ config(
    alias = 'hub_tsbd_chu_so_huu',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_chu_so_huu_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'tsbd_chu_so_huu_hashkey' %}
{% set business_key = 'chu_shuu_id' %}
{% set source_table = 'tsbd_chu_so_huu' %}
{% set source_model = 'v_stg_bpm_tsbd_chu_so_huu' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
