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
unique_key          : Khoa dinh danh record cua Computed Satellite
skip_matched_step   : true = bo qua record khong doi de tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'csat_crb_balance',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    unique_key = ['crb_hashkey', 'currency', 'hashdiff', 'source_event_date'],
    tags = ['t24', 'crb', 'zonec', 'bv_zonec']
) }}

/*
========================================================================
COMPUTED SATELLITE MACRO PARAMETERS
========================================================================
source_model        : bang satellite lam base
hashkey_col         : hashkey cua base
base_date_filter    : '='  -> base lay ban source_event_date = target_date (sat chup theo ngay)
                      '<=' -> base lay ban moi nhat <= target_date (mac dinh)
source_name/table   : ten bang source bronze
sts_model           : ten sts de loc hashkey da xoa
joins               : list cac bang join voi base.
                        model      : ten bang raw_vault de join
                        alias      : alias
                        on         : dieu kien join
                        key        : cot partition de dedup lay ban moi nhat (can khi date_filter='<=')
                        join_type  : 'inner' / 'left join' ... (mac dinh 'left join')
                        date_filter: '<=' -> ban moi nhat <= target_date (mac dinh, can 'key')
                                     '='  -> ban source_event_date = target_date
                                     none -> lay TOAN bang (vd hub 1 dong/key, khong loc ngay)
computed_cols       : {'alias','expr'}
group_by            : cac cot grain (ngoai hashkey)
dependent_child_keys: PK phu ngoai hashkey
========================================================================
*/

{% set source_name       = 't24' %}
{% set source_table      = 't24_crb' %}
{% set source_model      = 'sat_crb_balance' %}
{% set hashkey_col       = 'crb_hashkey' %}
{% set base_date_filter  = '=' %}
{% set sts_model         = 'sts_hub_crb' %}

-- join hub_crb de lay business key gl & tieukhoan (hub 1 dong/key -> lay toan bang)
{% set joins = [
    {
        'model': 'hub_crb',
        'alias': 'hub',
        'join_type': 'inner',
        'date_filter': none,
        'on': 'base_src.crb_hashkey = hub.crb_hashkey'
    }
] %}

-- source_event_date = target_date: dua vao computed_cols de vao hashdiff (moi ngay 1 ban).
{% set computed_cols = [
    {'alias': 'gl',                'expr': 'hub.gl'},
    {'alias': 'tieukhoan',         'expr': 'hub.tieukhoan'},
    {'alias': 'currency',          'expr': 'base_src.ngoaite'},
    {'alias': 'ngoaite',           'expr': 'SUM(TRY_CAST(base_src.ngoaite1 AS decimal(38,10)))'},
    {'alias': 'noite',             'expr': 'SUM(TRY_CAST(base_src.noite AS decimal(38,10)))'},
    {'alias': 'source_event_date', 'expr': "to_date('" ~ var('target_date') ~ "', 'yyyyMMdd')"}
] %}

{% set group_by = ['hub.gl', 'hub.tieukhoan', 'base_src.ngoaite'] %}

{{ computed_satellite(
    source_model=source_model,
    hashkey_col=hashkey_col,
    base_date_filter=base_date_filter,
    source_name=source_name,
    source_table=source_table,
    sts_model=sts_model,
    joins=joins,
    computed_cols=computed_cols,
    group_by=group_by,
    dependent_child_keys=['currency']
) }}
