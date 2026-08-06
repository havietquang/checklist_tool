/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chỉ tạo view, không lưu dữ liệu vật lý.
               Staging luôn dùng view để đảm bảo dữ liệu mới nhất
               từ source được đọc trực tiếp mỗi khi downstream
               model chạy.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['clevertap'] = filter khi run (dbt run --select tag:clevertap)
====================================================================
*/
{{ config(
    alias = 'v_stg_clevertap_campaigns',
    materialized = 'view',
    tags = ['clevertap', 'campaign', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Tên hệ thống nguồn ('clevertap'), dùng để tạo
                            giá trị cho cột `record_source` ở downstream.
  - source_table          : Tên bảng nghiệp vụ nguồn ('campaigns'),
                            dùng để map đúng snapshot/source table.
  - business_key_cols     : Danh sách cột tạo thành Business Key duy nhất
                            của entity. ['campaign_id'] = mã chiến dịch CleverTap.
                            Macro sẽ hash các cột này thành hashkey.
  - source_event_date_col : Cột ngày sự kiện từ nguồn ('run_date'),
                            dùng làm `source_event_date` ở downstream.
  - hashdiff_satellite_dict: Dictionary ánh xạ tên hashdiff → danh sách
                            cột tương ứng. Mỗi entry sinh ra một cột
                            hashdiff riêng, phục vụ một Satellite riêng
                            biệt ở tầng raw_vault.
                            - hashdiff_campaigns_information : thông tin & KPI chiến dịch
                            - hashdiff_campaigns_configuration: cấu hình gửi & control group
========================================================================
*/
{% set source_name = "clevertap" -%}
{% set source_table = "campaigns" -%}
{% set business_key_cols = ['campaign_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_campaigns_information': ['total_sent_events','total_clicked_users','total_viewed_users','total_viewed_events','total_clicked_events','unique_sent_users','unique_viewed_within_conversion_time','unique_clicked_within_conversion_time','error_user_not_reachable','error_push_unregistered_android','influenced_conversions_pct','influenced_conversions','error_user_dnd','click_through_conversions_pct','total_sent_users','error_apns_bad_device_token','estimated_reach','click_through_conversions','unique_converted_within_conversion_time','errors','status','error_inbox_ttl_expired'],
    'hashdiff_campaigns_classification': ['sent_influenced_conversions_pct','title','message','start_date','start_time','device','who_query','constant_property','safety_check_limit','campaign_per_day_limit','reach','created_by','created_time','labels','total_delivered_users','total_unsubscribes100','ios_badge_count','ios_deep_link','ios_mutable_content','android_summary','android_large_icon_url','android_small_app_icon_colour','android_sound_file','android_notification_tray_priority','android_notification_delivery_priority','notification_channels','badge_icon','send_to_app_inbox_as_well','service_provider','conversion_event','conversion_time_in_minutes','campaign_url','push_amplification_applied','web_priority','time_to_live_type','time_to_live_value','template_name','provider_name','waba_number','total_control_group_count','total_control_group_conversions_pct','revenue_within_conversion_time','system_control_group_conversions_pct','system_control_group_revenue','campaign_control_group_count','campaign_control_group_conversions_pct','campaign_control_group_revenue','custom_control_group_count','custom_control_group_conversions_pct','custom_control_group_revenue','custom_control_group_name','sent_influenced_revenue','total_html_viewed_events','total_amp_viewed_events','total_html_clicked_events','total_amp_clicked_events','campaign_name','channel','delivery','type','variant','os','dnd','timezone','cutoff','fcap','throttle','campaign_overall_limit','end_date','total_delivered_events','total_unsubscribes78','ios_rich_media_type','ios_rich_media_url','ios_sound_file','ios_category','android_subtitle','android_image_url','android_deep_link','collapse_notification','badge_id','rendermax_enabled','click_through_conversion_revenue','total_control_group_conversions','total_control_group_revenue','influenced_revenue','system_control_group_count','system_control_group_conversions','campaign_control_group_conversions','custom_control_group_conversions','sent_influenced_conversions','total_html_unsubscribes','total_amp_unsubscribes']
} -%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngăn macro chạy lúc dbt parse/compile
(tránh lỗi khi chưa có context thực thi).
Macro `stage()` sẽ sinh ra câu SELECT đầy đủ gồm:
  - Tất cả cột gốc từ source
  - Cột hashkey (hash của business_key_cols)
  - Các cột hashdiff theo hashdiff_satellite_dict
  - Cột record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/
{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name
        )
}}
{% endif -%}
