{{ config(
    alias = 'sat_passbook',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['passbook_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = 'newfo' %}
{% set source_table = 'passbook' %}
{% set hashdiff_col = 'hashdiff_passbook' %}
{% set hub_hashkey = 'passbook_hashkey' %}
{% set source_model = 'v_stg_newfo_passbook' %}
{% set list_cols = [
    'serialno',
    'branchcode',
    'status',
    'price',
    'passbooktype',
    'useddate',
    'accountno',
    'damageddate',
    'canceleddate',
    'lostdate',
    'lastdate',
    'prevbranch',
    'importdate',
    'cif',
    'note',
    'custname',
    'amount',
    'checkstatus',
    'checktrandetailid',
    'lostreceiptdate',
    'desposittranid'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
