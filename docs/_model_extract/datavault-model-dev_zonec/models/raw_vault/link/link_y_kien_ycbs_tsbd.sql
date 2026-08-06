{{ config(
    alias = 'link_y_kien_ycbs_tsbd',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_y_kien_ycbs_tsbd_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set raw_sql -%}
SELECT
    {{ hash_column(['id', 'ma_giao_dich'], 'bpm') }} AS link_y_kien_ycbs_tsbd_hashkey,
    {{ hash_column(['id'], 'bpm') }} AS y_kien_ycbs_hashkey,
    {{ hash_column(['ma_giao_dich'], 'bpm') }} AS tsbd_giaodich_chinh_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT('bpm', '__', 'y_kien_ycbs') AS record_source,
    current_timestamp AS load_timestamp
FROM {{ ref('v_stg_bpm_y_kien_ycbs') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND ma_giao_dich IS NOT NULL
  AND quy_trinh = 2
{%- endset %}

{{ link(raw_sql=raw_sql) }}
