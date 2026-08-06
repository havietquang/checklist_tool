-- Đang sử dụng ở staging. 
-- Mục đích là chuyển đổi các dạng date khác nhau của các trường trong bảng Bronze về kiểu string yyyyMMdd 
{% macro to_yyyymmdd_str(col, dttypep) %}


{% if dttypep == 'bigint'%}

    date_format(cast({{ col }} as timestamp), 'yyyyMMdd')

{% elif dttypep == 'yyyyMMdd' %}

    {{ col }}

{% elif dttypep == 'event_date' %}

    -- yyyy-mm-dd hh:mm:ss

    CASE
        WHEN regexp_like({{ col }}, '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$') THEN

            regexp_replace(substr({{ col }}, 1, 10), '-', '')
    END

{% elif dttypep == 'str+date'%}
    CASE
        WHEN {{ col }} IS NULL THEN NULL

        -- Timestamp / Date types

        WHEN typeof({{ col }}) IN ('date', 'timestamp', 'timestamp with time zone') THEN

            date_format(to_date({{ col }},'yyyyMMdd'), 'yyyyMMdd')
 
        -- String already yyyymmdd

        WHEN regexp_like({{ col }}, '^[0-9]{8}$') THEN

            date_format(to_date({{ col }},'yyyyMMdd'), 'yyyyMMdd')

        -- String yyyyMMddhhmmss (14 digits) -> yyyyMMdd

        WHEN regexp_like({{ col }}, '^[0-9]{14}$') THEN

            substr({{ col }}, 1, 8)

        -- yyyy-mm-dd

        WHEN regexp_like({{ col }}, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN

            regexp_replace({{ col }}, '-', '')

        -- yyyy-mm-ddThh:mm:ss:SSS +zz:zz (ISO-like)

        WHEN regexp_like({{ col }}, '^[0-9]{4}-[0-9]{2}-[0-9]{2}T') THEN

            regexp_replace(substr({{ col }}, 1, 10), '-', '')

        -- yyyy/mm/dd

        WHEN regexp_like(cast({{ col }} as string),
            '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$')
        THEN date_format(
            cast(try_to_timestamp({{ col }}, 'M/d/yyyy') as date),
            'yyyyMMdd'
        )

        WHEN regexp_like({{ col }}, '^[0-9]{4}/[0-9]{2}/[0-9]{2}$') THEN

            regexp_replace({{ col }}, '/', '')

        WHEN regexp_like(cast({{ col }} as string),
                '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}$')
            THEN date_format(
                cast(try_to_timestamp(cast({{ col }} as string), 'M/d/yyyy H:mm') as date),
                'yyyyMMdd'
            )
            
        WHEN regexp_like({{ col }}, '(AM|PM)') THEN

            date_format(
  coalesce(try_to_timestamp({{ col }}, 'M/d/yyyy HH:mm:ss a'), try_to_timestamp({{ col }}, 'M/d/yyyy H:mm:ss a'),try_to_timestamp({{ col }}, 'M/d/yyyy h:mm:ss a'))
  , 'yyyyMMdd') 
        -- fallback: try parsing as date

        ELSE

            date_format(

                cast(

                    try_cast({{ col }} as date)

                    as date

                ),

                'yyyyMMdd'

            )

    END
{%- endif -%}
{% endmacro %}