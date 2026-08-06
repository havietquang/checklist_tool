{% macro non_his_satellite(
    source_model=None,
    source_name=None,
    source_table=None,
    hub_hashkey=None,
    list_cols=None,
    raw_sql=None
) %}

{% set list_cols = list_cols or [] %}
{% set has_raw_sql = raw_sql is not none and raw_sql | trim != '' %}

{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("non_his_satellite macro: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if not has_raw_sql and (
    source_model is none or source_model | trim == '' or
    source_name is none or source_name | trim == '' or
    source_table is none or source_table | trim == '' or
    hub_hashkey is none or hub_hashkey | trim == ''
) %}
    {{ exceptions.raise_compiler_error("non_his_satellite macro: missing required params when `raw_sql` is not provided.") }}
{% endif %}

{#
  ------------------------------------------------------------------
  source_data: du lieu nguon cua target_date, KHONG chua load_timestamp.
    - Neu truyen raw_sql: raw_sql phai tra ve cot theo dung thu tu bang dich
      (tru load_timestamp) — macro se tu gan load_timestamp o buoc cuoi.
    - Neu khong: dung select chuan tu source_model.
  ------------------------------------------------------------------
#}
with source_data as (
    {% if has_raw_sql %}
        {{ raw_sql }}
    {% else %}
        select
            hashkey as {{ hub_hashkey }},
            to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
            concat('{{ source_name }}', '__', '{{ source_table }}') as record_source
            {% for col in list_cols %}
            , {{ col }}
            {% endfor %}
        from {{ ref(source_model) }}
        where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {% endif %}
)

{% if is_incremental() %}

, delta as (
    select * from source_data
    except all
    select * except (load_timestamp)
    from {{ this }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
)

select *, current_timestamp as load_timestamp
from delta

{% else %}

select *, current_timestamp as load_timestamp
from source_data

{% endif %}

{% endmacro %}
