{{ config(materialized='view', tags = ['phase1', 'all']) }}

-- Tính lịch ngày làm việc từ staging t24_holiday.
-- Output: msr_prd_id, msr_prd_dt, bsn_day_f, last_wk_id — dùng cho cross_source catchup logic.
with t24_hol_raw as (
    select
        right(id, 4) as hol_year,
        t_mth_01_table, t_mth_02_table, t_mth_03_table, t_mth_04_table,
        t_mth_05_table, t_mth_06_table, t_mth_07_table, t_mth_08_table,
        t_mth_09_table, t_mth_10_table, t_mth_11_table, t_mth_12_table
    from {{ ref('v_stg_t24_t24_holiday') }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      and id like 'VN%'
      and right(id, 4) = cast(year(to_date('{{ var("target_date") }}', 'yyyyMMdd')) as string)
),
t24_hol_months as (
    select hol_year, '01' as month_no, t_mth_01_table as t_mth from t24_hol_raw union all
    select hol_year, '02', t_mth_02_table from t24_hol_raw union all
    select hol_year, '03', t_mth_03_table from t24_hol_raw union all
    select hol_year, '04', t_mth_04_table from t24_hol_raw union all
    select hol_year, '05', t_mth_05_table from t24_hol_raw union all
    select hol_year, '06', t_mth_06_table from t24_hol_raw union all
    select hol_year, '07', t_mth_07_table from t24_hol_raw union all
    select hol_year, '08', t_mth_08_table from t24_hol_raw union all
    select hol_year, '09', t_mth_09_table from t24_hol_raw union all
    select hol_year, '10', t_mth_10_table from t24_hol_raw union all
    select hol_year, '11', t_mth_11_table from t24_hol_raw union all
    select hol_year, '12', t_mth_12_table from t24_hol_raw
),
t24_hol_days as (
    select
        hol_year,
        month_no,
        pos as day_no,
        substr(t_mth, pos, 1) as day_char,
        concat(hol_year, month_no, lpad(cast(pos as string), 2, '0')) as msr_prd_id
    from t24_hol_months
    lateral view explode(sequence(1, length(t_mth))) s as pos
    where t_mth is not null
      and substr(t_mth, pos, 1) != 'X'
)
select
    msr_prd_id,
    to_date(msr_prd_id, 'yyyyMMdd') as msr_prd_dt,
    case when day_char = 'W' then 1 else 0 end as bsn_day_f,
    to_date(
        max(case when day_char = 'W' then msr_prd_id end) over (
            order by msr_prd_id
            rows between unbounded preceding and 1 preceding
        ), 'yyyyMMdd'
    ) as last_wk_dt
from t24_hol_days

