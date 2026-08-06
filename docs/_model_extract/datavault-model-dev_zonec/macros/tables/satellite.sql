{#
    Macro: satellite
    Sinh SQL cho một Satellite table trong mô hình Data Vault.

    Có 2 chế độ vận hành:
    - transaction_table = True  : satellite dạng transaction/event (append-only, insert phần delta so với target).
    - transaction_table = False : satellite dạng snapshot theo hashdiff (chỉ insert khi hashdiff thay đổi so với bản ghi mới nhất).

    Tham số:
    - source_model    : tên model dbt chứa dữ liệu nguồn (dùng ref()), bắt buộc nếu không truyền raw_sql.
    - source_name     : tên hệ thống nguồn, dùng để build record_source.
    - source_table    : tên bảng nguồn, dùng để build record_source.
    - hub_hashkey     : tên cột hashkey liên kết tới Hub tương ứng.
    - hashdiff_name   : tên cột hashdiff dùng để so sánh thay đổi dữ liệu.
    - list_cols       : danh sách các cột descriptive/payload cần lấy thêm. Nếu chứa 'ma_key' thì cột này
                        sẽ được dùng làm khóa phụ (multi-active key) khi xác định bản ghi mới nhất.
    - raw_sql         : cho phép truyền thẳng câu SELECT nguồn thay vì để macro tự sinh (dùng cho case đặc thù).
    - transaction_table : True nếu đây là satellite transaction/event, False nếu là satellite snapshot.
#}
{% macro satellite(
    source_model=None,
    source_name=None,
    source_table=None,
    hub_hashkey=None,
    hashdiff_name=None,
    list_cols=None,
    raw_sql=None,
    transaction_table=False
) %}

{% set list_cols = list_cols or [] %}
{# ma_key: khóa phụ dùng cho satellite multi-active (nhiều bản ghi active cùng lúc cho 1 hub_hashkey) #}
{% set ma_key = 'ma_key' if 'ma_key' in list_cols else None %}
{% set has_raw_sql = raw_sql is not none and raw_sql | trim != '' %}

{# --- Validate tham số đầu vào --- #}
{% if raw_sql is not none and raw_sql | trim == '' %}
    {{ exceptions.raise_compiler_error("satellite macro: `raw_sql` cannot be empty when provided.") }}
{% endif %}

{% if not has_raw_sql and (
    source_model is none or source_model | trim == '' or
    source_name is none or source_name | trim == '' or
    source_table is none or source_table | trim == '' or
    hub_hashkey is none or hub_hashkey | trim == '' or
    hashdiff_name is none or hashdiff_name | trim == ''
) %}
    {{ exceptions.raise_compiler_error("satellite macro: missing required params when `raw_sql` is not provided.") }}
{% endif %}

{% if transaction_table %}
{# ============================================================
   CHẾ ĐỘ TRANSACTION: satellite dạng event/transaction, append-only.
   Không cần xác định "bản ghi mới nhất" vì mỗi dòng là 1 sự kiện độc lập.
   ============================================================ #}

with source_data as (

    {% if has_raw_sql %}
        {{ raw_sql }}
    {% else %}
        -- Lấy dữ liệu nguồn theo target_date, sinh thêm các cột chuẩn của satellite
        select
            hashkey as {{ hub_hashkey }},
            {{ hashdiff_name }} as hashdiff,
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

-- Chỉ insert các bản ghi chưa tồn tại trong target (so sánh theo hub_hashkey + hashdiff)
, target_data as (
    select *
    from {{ this }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
)

, delta as (
    select s.*
    from source_data s
    left anti join target_data t
        on s.{{ hub_hashkey }} = t.{{ hub_hashkey }}
        and s.hashdiff = t.hashdiff
)

select *, current_timestamp as load_timestamp
from delta

{% else %}

-- Full load lần đầu: insert toàn bộ source_data
select *, current_timestamp as load_timestamp
from source_data

{% endif %}

{% else %}
{# ============================================================
   CHẾ ĐỘ SNAPSHOT: satellite dạng chuẩn Data Vault.
   Chỉ insert bản ghi mới khi hashdiff thay đổi so với bản ghi mới nhất hiện có.
   ============================================================ #}

with source_data as (

    {% if has_raw_sql %}
        {{ raw_sql }}
    {% else %}
        -- Lấy dữ liệu nguồn theo target_date, sinh thêm các cột chuẩn của satellite
        select
            hashkey as {{ hub_hashkey }},
            {{ hashdiff_name }} as hashdiff,
            to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
            current_timestamp as load_timestamp,
            concat('{{ source_name }}', '__', '{{ source_table }}') as record_source
            {% for col in list_cols %}
            , {{ col }}
            {% endfor %}
        from {{ ref(source_model) }}
        where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {% endif %}

)

{% if is_incremental() %}

-- Với mỗi hub_hashkey (và ma_key nếu có), lấy hashdiff của bản ghi mới nhất hiện có trong target.
-- Chỉ xét các hub_hashkey xuất hiện trong source_data của batch hiện tại (thay vì toàn bộ lịch sử
-- satellite) để giảm data scan khi chạy row_number(), và chỉ lấy cột cần cho so sánh/join.
, target_data as (
    select
        t.{{ hub_hashkey }}
        {% if ma_key is not none %}, t.{{ ma_key }}{% endif %}
        , t.hashdiff
    from {{ this }} t
    where t.{{ hub_hashkey }} in (select {{ hub_hashkey }} from source_data)
    qualify row_number() over (
        partition by t.{{ hub_hashkey }}{% if ma_key is not none %}, t.{{ ma_key }}{% endif %}
        order by t.source_event_date desc, t.load_timestamp desc
    ) = 1
)

-- Chỉ insert bản ghi mới (chưa có hashkey/ma_key trong target)
-- hoặc bản ghi đã đổi hashdiff so với bản ghi mới nhất
, insert_data as (
    select s.*
    from source_data s
    left join target_data t
        on s.{{ hub_hashkey }} = t.{{ hub_hashkey }}
        {% if ma_key is not none %}and s.{{ ma_key }} = t.{{ ma_key }}{% endif %}
    where t.{{ hub_hashkey }} is null
       or s.hashdiff is distinct from t.hashdiff
)

select * from insert_data

{% else %}

-- Full load lần đầu: insert toàn bộ source_data
select * from source_data

{% endif %}

{% endif %}

{% endmacro %}
