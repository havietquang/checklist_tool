{{ config(
    alias = 'v_stg_bpm_giao_dich_thoi_gian_xu_ly_by_nhom',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "giao_dich_thoi_gian_xu_ly_by_nhom" %}
{% set business_key_cols = ['gd_id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_giao_dich_thoi_gian_xu_ly_by_nhom': ['ls_id_cuoi', 'nhom_2', 'nhom_5', 'nhom_6', 'nhom_7', 'nhom_11', 'nhom_12', 'nhom_13', 'nhom_21', 'nhom_22', 'nhom_30', 'nhom_31', 'nhom_32', 'nhom_33', 'nhom_34', 'nhom_35', 'nhom_118', 'nhom_158', 'nhom_164', 'nhom_169', 'nhom_198', 'nhom_199', 'nhom_200', 'nhom_201', 'nhom_202', 'nhom_203', 'nhom_205', 'nhom_207', 'nhom_217', 'nhom_238', 'nhom_282', 'nhom_283', 'nhom_284', 'nhom_285', 'nhom_286', 'nhom_287', 'nhom_288', 'nhom_289', 'nhom_290', 'nhom_291', 'nhom_292', 'nhom_293', 'nhom_294', 'nhom_295', 'nhom_296', 'nhom_297', 'nhom_298', 'nhom_299', 'nhom_303', 'nhom_304', 'nhom_305', 'nhom_306', 'nhom_307', 'nhom_308', 'nhom_323', 'nhom_343', 'nhom_371', 'nhom_377', 'nhom_378', 'nhom_379', 'nhom_380', 'nhom_381', 'nhom_382', 'nhom_391', 'nhom_393', 'nhom_394', 'nhom_395', 'nhom_396', 'nhom_397', 'nhom_398', 'nhom_399', 'nhom_400', 'nhom_401', 'nhom_402', 'nhom_403', 'nhom_408', 'nhom_415', 'nhom_416', 'nhom_417', 'nhom_418', 'nhom_420', 'nhom_422', 'nhom_423', 'nhom_424', 'nhom_427', 'nhom_428', 'nhom_432', 'nhom_433', 'nhom_434', 'nhom_435', 'nhom_436', 'nhom_437', 'nhom_438', 'nhom_439', 'nhom_440', 'nhom_441', 'nhom_442', 'nhom_443', 'nhom_444', 'nhom_447', 'nhom_448', 'nhom_449', 'nhom_450', 'nhom_451', 'nhom_457', 'nhom_458', 'nhom_459', 'nhom_460', 'nhom_461', 'nhom_462', 'nhom_473', 'nhom_475', 'nhom_476', 'nhom_477', 'nhom_483', 'nhom_484', 'nhom_485', 'nhom_486', 'nhom_487', 'nhom_488', 'nhom_489', 'nhom_494', 'nhom_495', 'nhom_496', 'nhom_500', 'nhom_501', 'nhom_502', 'nhom_505', 'nhom_10'],
} %}

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name)
}}
{% endif -%}
