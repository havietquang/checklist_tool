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
unique_key          : Khoa dinh danh record
skip_matched_step   : true = bo record khong doi → tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'link_payment_history_funds_transfer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_payment_history_funds_transfer_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'payment_order', 'phase1', 'all']
) }}
 
-- Extraction
{% set source_name = 'omni' %}
{% set source_table = 'payment_history' %}
{% set payment_history_business_key_cols = ['a.id'] %}
 
{%- set raw_sql -%}
-- Cross-source catchup mechanism (auto-detect via ref_holiday):
-- T24 không có dữ liệu ngày nghỉ. Ngày bù (ngày làm việc đầu tiên sau kỳ nghỉ),
-- T24 gửi kèm data cho các ngày nghỉ (data_date = ngày_nghỉ).
-- Phát hiện ngày bù: target_date là ngày làm việc (bsn_day_f=1) VÀ last_wk_dt+1 < target_date.
-- t24_active_dates = {target_date} ∪ {các ngày nằm giữa last_wk_dt và target_date}.
-- OMNI filter theo đúng bộ ngày này để match đủ dữ liệu ngày nghỉ.
with hol_raw as (
    select
        right(id, 4) as hol_year,
        t_mth_01_table, t_mth_02_table, t_mth_03_table, t_mth_04_table,
        t_mth_05_table, t_mth_06_table, t_mth_07_table, t_mth_08_table,
        t_mth_09_table, t_mth_10_table, t_mth_11_table, t_mth_12_table
    from {{ source('t24', 't24_holiday') }}
    where data_date = '{{ var("target_date") }}'
      and id like 'VN%'
),
month_unpivot as (
    select hol_year, '01' as month_no, t_mth_01_table as t_mth from hol_raw union all
    select hol_year, '02', t_mth_02_table from hol_raw union all
    select hol_year, '03', t_mth_03_table from hol_raw union all
    select hol_year, '04', t_mth_04_table from hol_raw union all
    select hol_year, '05', t_mth_05_table from hol_raw union all
    select hol_year, '06', t_mth_06_table from hol_raw union all
    select hol_year, '07', t_mth_07_table from hol_raw union all
    select hol_year, '08', t_mth_08_table from hol_raw union all
    select hol_year, '09', t_mth_09_table from hol_raw union all
    select hol_year, '10', t_mth_10_table from hol_raw union all
    select hol_year, '11', t_mth_11_table from hol_raw union all
    select hol_year, '12', t_mth_12_table from hol_raw
),
day_expand as (
    select
        concat(hol_year, month_no, lpad(cast(pos as string), 2, '0')) as msr_prd_id,
        substr(t_mth, pos, 1) as day_char
    from month_unpivot
    lateral view explode(sequence(1, length(t_mth))) s as pos
),
calendar_inline as (
    select
        msr_prd_id,
        to_date(msr_prd_id, 'yyyyMMdd') as msr_prd_dt,
        cast(case when day_char = 'W' then 1 else 0 end as int) as bsn_day_f,
        max(case when day_char = 'W' then to_date(msr_prd_id, 'yyyyMMdd') end) over (
            order by msr_prd_id
            rows between unbounded preceding and 1 preceding
        ) as last_wk_dt
    from day_expand
    where day_char <> 'X'
),
t24_active_dates as (
    -- target_date luôn được include
    select to_date('{{ var("target_date") }}', 'yyyyMMdd') as biz_date
    union all
    -- thêm các ngày nghỉ/cuối tuần trước target_date nếu là ngày bù
    select c.msr_prd_dt
    from calendar_inline c
    inner join (
        select last_wk_dt, msr_prd_dt
        from calendar_inline
        where msr_prd_id = '{{ var("target_date") }}'
          and bsn_day_f = 1
          and date_add(last_wk_dt, 1) < msr_prd_dt  -- có khoảng trống = tồn tại ngày nghỉ
    ) gap on c.msr_prd_dt > gap.last_wk_dt
         and c.msr_prd_dt < gap.msr_prd_dt
),
catchup_dates as (
    -- các ngày bù (không phải target_date), dùng để filter bronze trực tiếp
    select biz_date from t24_active_dates
    where biz_date != to_date('{{ var("target_date") }}', 'yyyyMMdd')
),
funds_transfer as (
    -- T24 ngày bù vẫn có đủ dữ liệu các ngày nghỉ, data_date = target_date
    -- nên dùng bronze trực tiếp filter theo DATA_DATE = target_date
    select id, substring_index(trim(id), ';', 1) as funds_transfer_id
    from {{ source('t24', 't24_funds_transfer') }}
    where id is not null
      and data_date = '{{ var("target_date") }}'
),
payment_history as (
    -- target_date: đọc thẳng bronze filter theo data_date = target_date
    select id, bank_reference_id, data_date
    from {{ source('omni', 'payment_history') }}
    where to_date(data_date, 'yyyyMMdd') = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    union all
    -- ngày bù: OMNI không có catchup, phải đọc thẳng từ bronze cho các ngày nghỉ
    select id, bank_reference_id, data_date
    from {{ source('omni', 'payment_history') }}
    where to_date(data_date, 'yyyyMMdd') in (select biz_date from catchup_dates)
)
 
SELECT
    {{ hash_column(['a.id', 'b.id'], source_name) }} AS link_payment_history_funds_transfer_hashkey,
    {{ hash_column(payment_history_business_key_cols, source_name) }} AS payment_history_hashkey,
    {{ hash_column(['b.id'], source_name) }} AS funds_transfer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM payment_history a
LEFT JOIN funds_transfer b ON a.bank_reference_id = b.funds_transfer_id
WHERE a.bank_reference_id is not null
and a.id is not null
and a.bank_reference_id like 'FT%'
{%- endset %}
-------------
 
--Main part
{{ link(raw_sql = raw_sql) }}