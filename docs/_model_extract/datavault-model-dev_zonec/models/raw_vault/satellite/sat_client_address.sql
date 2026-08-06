/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record mới/thay đổi
                    : 'table' = full load
                    : 'view' = chỉ tạo view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chỉ insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khóa định danh record (thường: hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/

{{ config(
    alias = 'sat_client_address',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['client_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'entity', 'phase1', 'all']
) }}

with source_data as (
    SELECT
        hashkey AS client_hashkey,
        ma_key,
        hashdiff_client_address AS hashdiff,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
        CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
        CONCAT('way4', '__', 'client_address') AS record_source,
        address_name,
        address_line_1,
        address_line_2,
        address_line_3,
        address_line_4,
        title,
        salutation_suffix,
        first_nam,
        last_nam,
        birth_nam,
        address_zip,
        city,
        state,
        country,
        zip_code,
        phone,
        phone_h,
        phone_m,
        fax,
        fax_h,
        e_mail AS email,
        url,
        location,
        address_type,
        date_from,
        date_to,
        is_active,
        parent_address,
        copy_to_address,
        language,
        municipality_code,
        delivery_type,
        add_info,
        is_ready
    FROM {{ ref('v_stg_way4_client_address') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    AND amnd_state = 'A'
    AND client__oid IS NOT NULL
)

{% if is_incremental() %}

, target_data as (
    select t.*
    from {{ this }} t
    qualify row_number() over (
        partition by t.client_hashkey, t.ma_key
        order by t.source_event_date desc, t.load_timestamp desc
    ) = 1
)

, insert_data as (
    select s.*
    from source_data s
    left join target_data t
        on s.client_hashkey = t.client_hashkey
        and s.ma_key = t.ma_key
    where t.client_hashkey is null
       or s.hashdiff is distinct from t.hashdiff
)

select * from insert_data

{% else %}

select * from source_data

{% endif %}
