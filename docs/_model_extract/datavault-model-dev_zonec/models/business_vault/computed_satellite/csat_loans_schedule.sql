/*
================================================================================
DBT CONFIGURATION GUIDE
================================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record cua Bridge
skip_matched_step   : true = bo qua record khong doi de tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
where_clause        : Dieu kien loc bo sung cho tap du lieu bridge
================================================================================
*/
{{ config(
    alias = 'csat_loans_schedule',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    unique_key = ['loans_hashkey', 't_k_date', 'k_date_seq', 't_sch_type', 't_cycled_dates', 'cycled_dates_seq', 'hashdiff', 'source_event_date'],
    tags = ['t24', 'loan', 'zonec', 'bv_zonec']
) }}

/*
========================================================================
COMPUTED SATELLITE: csat_loans_schedule
Explode các cột multi-value (phân cách '::') của sat_loans_schedule
           theo từng kỳ hạn (t_k_date), sau đó tiếp tục explode t_cycled_dates
           theo từng ngày cycled (phân cách '!!').
========================================================================
*/

{% set hashkey_col = 'loans_hashkey' %}
{% set target_date_sql = "to_date('" ~ var("target_date") ~ "', 'yyyyMMdd')" %}

{% set computed_cols = [
    {'alias': 't_k_date'},
    {'alias': 'k_date_seq'},
    {'alias': 't_sch_type'},
    {'alias': 't_frequency'},
    {'alias': 't_number'},
    {'alias': 't_cycled_dates'},
    {'alias': 'cycled_dates_seq'},
    {'alias': 't_currency'},
    {'alias': 't_amount'},
    {'alias': 't_date_time'}
] %}

{% set raw_sql %}
-- Lấy các hashkey bị xóa
WITH deleted_loans AS (
    SELECT loans_hashkey
    FROM (
        SELECT
            loans_hashkey,
            cdc_status,
            ROW_NUMBER() OVER (PARTITION BY loans_hashkey ORDER BY source_event_date DESC) AS rn
        FROM {{ source('raw_vault','sts_hub_loans_ld_schedule_define') }}
        WHERE source_event_date <= {{ target_date_sql }}
    )
    WHERE rn = 1 AND cdc_status = 'D'
),

-- lấy giá trị mới nhất từ sat
latest_schedule AS (
    SELECT *
    FROM {{ source('raw_vault','sat_loans_schedule') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey ORDER BY source_event_date DESC) = 1
),

loans_schedule_explode AS (
    -- Step 1: Explode t_k_date (phân cách '::') và các cột multi-value cùng vị trí
    SELECT
        sat.loans_hashkey,
        sat.source_event_date,
        t_k_date_exploded,
        pos AS k_date_pos,
        get(split(sat.t_sch_type,    '::'), pos) AS t_sch_type_exploded,
        get(split(sat.t_frequency,   '::'), pos) AS t_frequency_exploded,
        get(split(sat.t_number,      '::'), pos) AS t_number_exploded,
        get(split(sat.t_cycled_dates,'::'), pos) AS t_cycled_dates_exploded,
        sat.t_currency AS t_currency,
        -- t_amount: nếu có '::' thì split theo vị trí (phần tử rỗng để NULL, bù ở bước sau);
        -- nếu không có '::' thì lặp lại nguyên giá trị gốc cho toàn bộ dòng sau split
        CASE
            WHEN sat.t_amount IS NOT NULL AND sat.t_amount LIKE '%::%'
                THEN NULLIF(TRIM(get(split(sat.t_amount, '::'), pos)), '')
            ELSE sat.t_amount
        END AS t_amount_raw_exploded,
        -- sat.t_co_code AS t_co_code_exploded,
        CASE
            WHEN sat.t_date_time LIKE '%::%' THEN get(split(sat.t_date_time, '::'), pos)
            ELSE sat.t_date_time
        END AS t_date_time_exploded
    FROM latest_schedule sat
    LATERAL VIEW posexplode(split(sat.t_k_date, '::')) t AS pos, t_k_date_exploded
    WHERE NOT EXISTS (
        SELECT 1 FROM deleted_loans del WHERE del.loans_hashkey = sat.loans_hashkey
    )
),

loans_schedule_ordered AS (
    -- Step 2: Thêm cột sequence theo thứ tự ngày tăng dần trong cùng khoản vay và ngày dữ liệu
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY loans_hashkey
            ORDER BY TO_DATE(t_k_date_exploded, 'yyyyMMdd'), k_date_pos     -- thêm k_date_pos cho trường hợp t_k_date_exploded có giá trị bằng nhau
        ) AS k_date_seq
    FROM loans_schedule_explode
),

-- join sat_loans_rate lấy t_tot_interest_amt mới nhất để bù cho các phần tử t_amount rỗng sau khi split
latest_rate AS (
    SELECT loans_hashkey, t_tot_interest_amt
    FROM {{ source('raw_vault','sat_loans_rate') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey ORDER BY source_event_date DESC) = 1
),

loans_schedule_amount AS (
    SELECT
        base.*,
        -- Chỉ dòng có k_date_seq nhỏ nhất trong nhóm (loans_hashkey, source_event_date, t_sch_type = 'I', t_amount rỗng)
        -- mới được bù giá trị từ sat_loans_rate.t_tot_interest_amt; các dòng còn lại trong nhóm nhận giá trị 0
        CASE
            WHEN base.t_amount_raw_exploded IS NOT NULL THEN base.t_amount_raw_exploded
            WHEN base.t_sch_type_exploded = 'I' AND base.k_date_seq = base.min_interest_k_date_seq
                THEN CAST(rate.t_tot_interest_amt AS string)
            ELSE '0'
        END AS t_amount_exploded
    FROM (
        SELECT
            e.*,
            MIN(CASE WHEN e.t_sch_type_exploded = 'I' AND e.t_amount_raw_exploded IS NULL THEN e.k_date_seq END)
                OVER (PARTITION BY e.loans_hashkey) AS min_interest_k_date_seq
        FROM loans_schedule_ordered e
    ) base
    LEFT JOIN latest_rate rate ON rate.loans_hashkey = base.loans_hashkey
),

loans_schedule_cycled AS (
    -- Step 3: Explode t_cycled_dates_exploded (phân cách '!!') và đánh cycled_dates_seq
    SELECT
        loans_hashkey,
        source_event_date,
        t_k_date_exploded,
        k_date_seq,
        t_sch_type_exploded,
        t_frequency_exploded,
        t_number_exploded,
        t_cycled_dates_exploded,
        t_currency,
        t_amount_exploded,
        -- t_co_code_exploded,
        t_date_time_exploded,
        cycled_date_exploded,
        cycled_pos + 1 AS cycled_dates_seq,
        -- t_amount_raw_exploded NOT NULL: giá trị lấy từ split '::' (hoặc repeat do không có '::') -> lặp lại cho toàn bộ dòng 
        -- t_amount_raw_exploded NULL: giá trị lấy bù từ sat_loans_rate -> nếu sch_type = 'I' chỉ cycled_date đầu tiên nhận giá trị, còn lại = 0
        CASE
            WHEN t_sch_type_exploded = 'I' AND t_amount_raw_exploded IS NULL AND cycled_pos = 0 THEN t_amount_exploded
            WHEN t_sch_type_exploded = 'I' AND t_amount_raw_exploded IS NULL AND cycled_pos <> 0 THEN '0'
            ELSE t_amount_exploded
        END AS t_amount_cycled
    FROM loans_schedule_amount
    LATERAL VIEW posexplode(split(t_cycled_dates_exploded, '!!')) c AS cycled_pos, cycled_date_exploded
)

SELECT
    loans_hashkey,
    to_date(t_k_date_exploded, 'yyyyMMdd')          AS t_k_date,
    CAST(k_date_seq AS int)                           AS k_date_seq,
    t_sch_type_exploded                             AS t_sch_type,
    t_frequency_exploded                            AS t_frequency,
    COALESCE(TRY_CAST(t_number_exploded AS int), 0)  AS t_number,
    cycled_date_exploded                             AS t_cycled_dates,
    cycled_dates_seq,
    t_currency                                       AS t_currency,
    TRY_CAST(t_amount_cycled AS decimal(38,10))       AS t_amount,
    t_date_time_exploded                             AS t_date_time,
    -- t_co_code_exploded AS t_co_code,
    {{ target_date_sql }} as source_event_date,
    current_timestamp as load_timestamp,
    concat('t24', '__', 't24_ld_schedule_define') as record_source
FROM loans_schedule_cycled
{% endset %}

{{ computed_satellite(
    hashkey_col=hashkey_col,
    computed_cols=computed_cols,
    raw_sql=raw_sql,
    dependent_child_keys=['t_k_date', 'k_date_seq', 't_sch_type', 't_cycled_dates', 'cycled_dates_seq']
) }}
