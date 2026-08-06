/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record cua PIT
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<source_name>'] = filter khi run (dbt run --select tag:<source_name>)
====================================================================
*/
{{ config(
      alias = 'pit_account',
      materialized = 'incremental',
      incremental_strategy = 'merge',
      skip_matched_step = true,
      tags = ['t24', 'deposit', 'account'],
      unique_key = ['account_hashkey', 'snapshot_date']
) }}

/*
========================================================================
PIT RAW_SQL GUIDE
========================================================================
   - PIT (Point In Time) dung de xac dinh moc source_event_date moi nhat
     cua tung Satellite tai thoi diem target_date.
   - raw_sql : Cau SELECT custom truyen vao pit macro cho cac case join dac thu.
   - raw_sql can tra ve cac cot:
      + account_hashkey : Khoa chinh cua PIT.
      + snapshot_date : Moc thoi gian snapshot.
      + cac cot <satellite>_src_ev_dt : source_event_date moi nhat cua moi Satellite.
========================================================================
*/
{% set raw_sql %}
with hub_account as (
   select account_hashkey
   from {{ source('raw_vault','hub_account') }}
   where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
),
hub_deposits as (
   select deposit_hashkey
   from {{ source('raw_vault','hub_deposits') }}
   where source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
)
select
   h.account_hashkey as account_hashkey,
   to_date('{{ var("target_date") }}', 'yyyyMMdd') as snapshot_date,
   max(sdr.source_event_date) as sat_deposits_rate_src_ev_dt,
   max(sdi.source_event_date) as sat_deposits_information_src_ev_dt,
   max(sdt.source_event_date) as sat_deposits_terms_src_ev_dt,
   max(sab.source_event_date) as sat_account_balance_src_ev_dt,
   max(sai.source_event_date) as sat_account_information_src_ev_dt,
   max(sac.source_event_date) as sat_account_classification_src_ev_dt
from hub_account h
left join hub_deposits hd
   on h.account_hashkey = hd.deposit_hashkey
left join {{ source('raw_vault','sat_deposits_rate')}} sdr
   on hd.deposit_hashkey = sdr.deposit_hashkey
   and sdr.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
left join {{ source('raw_vault','sat_deposits_information')}} sdi
   on hd.deposit_hashkey = sdi.deposit_hashkey
   and sdi.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
left join {{ source('raw_vault','sat_deposits_terms')}} sdt
   on hd.deposit_hashkey = sdt.deposit_hashkey
   and sdt.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
left join {{ source('raw_vault','sat_account_balance')}} sab
   on h.account_hashkey = sab.account_hashkey
   and sab.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
left join {{ source('raw_vault','sat_account_information')}} sai
   on h.account_hashkey = sai.account_hashkey
   and sai.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
left join {{ source('raw_vault','sat_account_classification')}} sac
   on h.account_hashkey = sac.account_hashkey
   and sac.source_event_date <= to_date('{{ var("target_date") }}', 'yyyyMMdd')
group by h.account_hashkey
{% endset %}

{{ pit(raw_sql=raw_sql) }}
