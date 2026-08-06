# Tài Liệu Kỹ Thuật — OCB Data Vault 2.0 on Databricks

> **Dự án**: datavaultmodel2  
> **Tổ chức**: OCB — Ngân hàng thương mại cổ phần Việt Nam
> **Nền tảng**: Databricks Lakehouse + dbt  
> **Phiên bản tài liệu**: 2026-05-22.  

---

## Mục Lục

1. [Tổng Quan Kiến Trúc](#1-tổng-quan-kiến-trúc)
2. [Cấu Trúc Thư Mục](#2-cấu-trúc-thư-mục)
3. [Cấu Hình dbt Project](#3-cấu-hình-dbt-project)
4. [Các Loại Bảng Data Vault](#4-các-loại-bảng-data-vault)
   - 4.1 Staging Views
   - 4.2 Hub
   - 4.3 Satellite
   - 4.4 Link
   - 4.5 Reference Table
   - 4.6 Soft-Delete Hub (STS)
   - 4.7 PIT (Point-in-Time)
   - 4.8 Bridge
   - 4.9 SAL / Computed Satellite
   - 4.10 Data Mart (Fact & Dimension)
5. [Nguyên Tắc Thiết Kế Data Vault 2.0](#5-nguyên-tắc-thiết-kế-data-vault-20)
6. [Luồng ETL End-to-End](#6-luồng-etl-end-to-end)
7. [Cơ Chế Checkpoint & Logging](#7-cơ-chế-checkpoint--logging)
8. [Các Bảng Metadata](#8-các-bảng-metadata)
9. [Macros Tổng Hợp](#9-macros-tổng-hợp)
10. [Kiểm Thử Dữ Liệu (dbt Tests)](#10-kiểm-thử-dữ-liệu-dbt-tests)
11. [Orchestration — Databricks Jobs](#11-orchestration--databricks-jobs)
12. [CI/CD — GitLab Pipeline](#12-cicd--gitlab-pipeline)
13. [Backfill & Lịch Sử](#13-backfill--lịch-sử)
14. [Các Hệ Thống Nguồn](#14-các-hệ-thống-nguồn)
15. [Thống Kê Dự Án](#15-thống-kê-dự-án)
16. [Init Data — Khởi Tạo Dữ Liệu Ban Đầu](#16-init-data--khởi-tạo-dữ-liệu-ban-đầu)

---

## 1. Tổng Quan Kiến Trúc:

Dự án triển khai **Data Vault 2.0** theo mô hình **Lakehouse** 4 tầng trên Databricks:

```
┌────────────────────────────────────────────────────────────────────┐
│  BRONZE LAYER — Ingestion (ocb_datavault_*_sourcing)               │
│  T24 · WAY4 · OMNI · BPM · CRM · CallCenter                       │
│  Dữ liệu thô, partitioned theo data_date (yyyyMMdd)                │
└──────────────────────────────┬─────────────────────────────────────┘
                               ↓  dbt staging macros
┌────────────────────────────────────────────────────────────────────┐
│  STAGING LAYER — Cleansing (ocb_datavault_*_cleaned · staging)     │
│  182 Views (v_stg_*)                                               │
│  Hash keys · hashdiff · type casting · date normalization          │
└──────────────────────────────┬─────────────────────────────────────┘
                               ↓  dbt raw_vault macros
┌────────────────────────────────────────────────────────────────────┐
│  RAW VAULT — Immutable History (ocb_datavault_*_cleaned · raw_vault)│
│  Hub (119) · Satellite (275) · Link (196) · Reference (67)         │
│  Soft-Delete Hub (sts_*) · Cross-Source Links                      │
└──────────────────────────────┬─────────────────────────────────────┘
                               ↓  dbt business_vault macros
┌────────────────────────────────────────────────────────────────────┐
│  BUSINESS VAULT — Derived Entities (business_vault schema)         │
│  PIT (4) · Bridge (5) · SAL · Calendar                             │
└──────────────────────────────┬─────────────────────────────────────┘
                               ↓  dbt data_mart models
┌────────────────────────────────────────────────────────────────────┐
│  DATA MART / GOLD (ocb_datavault_dev_curated · edw_mart)           │
│  Fact (5) · Dimension (1) · Aggregated Views (2)                   │
└────────────────────────────────────────────────────────────────────┘
```

**Công nghệ chính**:
- **dbt** (dbt-databricks adapter) — transformation engine, 20 threads
- **Databricks SQL Warehouse** — compute
- **Unity Catalog** — data governance & catalog
- **Delta Lake** — storage format (ACID, time travel)
- **OAuth M2M** — xác thực service principal
- **GitLab CI/CD** — deploy pipeline

---

## 2. Cấu Trúc Thư Mục

```
datavault-model/
├── dbt_project.yml                  # Cấu hình chính dbt
├── profiles.yml                     # Kết nối Databricks (dev/pilotcloud/prod)
├── databricks.yml                   # Databricks bundle config
├── package-lock.yml                 # dbt packages
├── .gitlab-ci.yml                   # CI/CD pipeline
│
├── models/
│   ├── staging/
│   │   ├── snp/
│   │   │   ├── t24/                 # v_stg_t24_* views
│   │   │   ├── way4/                # v_stg_way4_* views
│   │   │   ├── omni/                # v_stg_omni_* views
│   │   │   ├── BPM/                 # v_stg_bpm_* views
│   │   │   ├── crm/                 # v_stg_crm_* views
│   │   │   └── callcenter/          # v_stg_callcenter_* views
│   │   ├── bronze_sources.yml       # Source definitions (6 hệ thống)
│   │   └── source_stg.yml
│   │
│   ├── raw_vault/
│   │   ├── hub/                     # 119 Hub models
│   │   ├── satellite/               # 275 Satellite models
│   │   ├── link/                    # 196 Link models
│   │   ├── reference/               # 67 Reference models
│   │   ├── cross_source/            # Cross-source link models
│   │   └── raw_vault_schema_*.yml   # Schema contracts (t24/way4/omni/bpm/crm/callcenter)
│   │
│   ├── business_vault/
│   │   ├── pit/                     # 4 PIT tables
│   │   ├── bridge/                  # 5 Bridge tables
│   │   ├── sal/                     # SAL models
│   │   ├── calendar/                # Bảng lịch
│   │   ├── business_vault_schema.yml
│   │   └── raw_vault_sources.yml    # Source refs cho BV
│   │
│   └── data_mart/                   # 8 Gold models
│
├── macros/
│   ├── tables/                      # 14 table-type macros
│   ├── materializations/            # 4 custom materialization macros
│   ├── checkpoint/                  # 5 checkpoint/logging macros
│   └── utils/                       # 6 utility macros
│
├── tests/
│   └── generic/
│       └── unique_combination_of_columns.sql
│
├── ddl/                             # DDL scripts tạo bảng thủ công
├── resources/                       # Databricks job YAML definitions
├── sourcing/                        # Python backfill scripts
└── scripts/                         # Jupyter notebooks vận hành
```

---

## 3. Cấu Hình dbt Project

### Databases & Catalogs

| Biến | Giá Trị (dev) | Mô Tả |
|------|---------------|-------|
| `bronze_database` | `ocb_datavault_dev_sourcing` | Dữ liệu thô từ các hệ thống nguồn |
| `raw_vault_database` | `ocb_datavault_dev_cleaned` | Raw vault + staging |
| `business_vault_database` | `ocb_datavault_dev_cleaned` | Business vault |
| `curated_catalog` | `ocb_datavault_dev_curated` | Data Mart / Gold |
| `function_schema` | `audit_log` | Schema chứa bảng checkpoint |

### Cấu Hình Layer

| Layer | Schema | Materialization | Contract | Ghi Chú |
|-------|--------|-----------------|----------|---------|
| staging | staging | view | không bắt buộc | Disabled schema contract |
| raw_vault | raw_vault | incremental_checkpoint | **enforced** | Liquid cluster, fail on schema change |
| business_vault | business_vault | incremental_checkpoint | **enforced** | Liquid cluster |
| data_mart | edw_mart | incremental (append) | không | Curated catalog |

### Biến Hệ Thống Nguồn

```yaml
t24_schema: 't24'
way4_schema: 'way4'
omni_schema: 'omni'
bpm_schema: 'bpm'
crm_schema: 'crm'
callcenter_schema: 'callcenter'
```

### Hooks

| Hook | Macro | Điều Kiện |
|------|-------|-----------|
| on-run-start | `init_checkpoint_table()` | Luôn chạy |
| on-run-start | `log_run_start_to_console()` | Luôn chạy |
| on-run-end | `log_run_results_to_db(results)` | `checkpoint_hooks_enabled=true` |
| on-run-end | `log_test_results_to_db(results)` | **Luôn chạy** (không phụ thuộc flag) |
| on-run-end | `log_run_end_to_console(results)` | Luôn chạy |

### Flags Quan Trọng

```yaml
flags:
  indirect_selection: cautious    # Chỉ chạy test khi model được select rõ ràng
  use_materialization_v2: True
  warn_error_options:
    silence:
      - NoNodeForYamlKey
      - NodeNotFoundOrDisabled
```

---

## 4. Các Loại Bảng Data Vault

### 4.1 Staging Views

**Macro**: `macros/tables/stage.sql`  
**Số lượng**: 182 views  
**Quy ước đặt tên**: `v_stg_{source}_{table_name}`  

**Mục đích**: Tầng trung gian giữa Bronze và Raw Vault. Thực hiện:
- Chuẩn hóa kiểu dữ liệu theo metadata
- Tính toán `hashkey` (business key hash)
- Tính toán `hashdiff` cho từng satellite
- Lọc dữ liệu theo `source_event_date = target_date`
- Thêm `record_source`, `load_timestamp`

**Tham số macro**:
```sql
{{ config(
    source_table     = 'bronze_table_name',
    source_name      = 't24',
    business_key_cols = ['customer_no'],
    hashdiff_satellite_dict = {
        'sat_customer_profile': ['col1', 'col2', 'col3'],
        'sat_customer_address': ['addr1', 'addr2']
    },
    source_event_date_col   = 'data_date',
    source_event_date_dttype = 'yyyyMMdd',
    is_upper = true
) }}
```

**Các cột được sinh tự động**:
| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `hashkey` | string | SHA2-256 của business key |
| `hashdiff_full` | string | SHA2-256 của toàn bộ attribute columns |
| `hashdiff_{sat_name}` | string | SHA2-256 riêng cho từng satellite |
| `source_event_date` | date | Ngày xử lý (target_date) |
| `record_source` | string | `{source_name}.{table_name}` |
| `load_timestamp` | timestamp | Thời điểm load |
| *(tất cả cột gốc)* | varied | Với type casting từ metadata |

**Materialization**: VIEW — không lưu trữ dữ liệu, query trực tiếp Bronze.

---

### 4.2 Hub

**Macro**: `macros/tables/hub.sql`  
**Số lượng**: 119 models  
**Quy ước đặt tên**: `hub_{entity_name}`  

**Mục đích**: Lưu trữ **business keys** bất biến. Mỗi business key chỉ xuất hiện một lần trong Hub. Không bao giờ xóa, không bao giờ cập nhật.

**Tham số macro**:
```sql
{{ config(
    source_model  = 'v_stg_t24_t24_customer',
    source_name   = 't24',
    source_table  = 't24_customer',
    unique_key    = 'customer_hashkey',
    business_key  = ['customer_no'],
    raw_sql       = none   -- optional: override SQL
) }}
```

**Các cột chuẩn**:
| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `{entity}_hashkey` | string | PK — SHA2-256 của business key |
| `business_key` | string/bigint | Business key gốc |
| `source_event_date` | date | Ngày lần đầu xuất hiện |
| `record_source` | string | Nguồn dữ liệu |
| `load_timestamp` | timestamp | Thời điểm insert vào Hub |

**Incremental logic**: Chỉ insert khi `hashkey` chưa tồn tại (`skip_matched = true`).

**Ví dụ Hub models**: `hub_account`, `hub_customer`, `hub_loans`, `hub_deposits`, `hub_collateral`, `hub_branch`, `hub_user`, `hub_product_package_partner`, `hub_money_market`, `hub_forex`, `hub_security`, `hub_letter_of_credit`, `hub_md_deal`

---

### 4.3 Satellite

**Macro**: `macros/tables/satellite.sql`  
**Số lượng**: 275 models  
**Quy ước đặt tên**: `sat_{entity_name}_{attribute_group}`  

**Mục đích**: Lưu trữ **thuộc tính mô tả** của các entity trong Hub theo thời gian. Mỗi lần attribute thay đổi → thêm một bản ghi mới (full history).

**Tham số macro**:
```sql
{{ config(
    source_model   = 'v_stg_t24_t24_loans',
    source_name    = 't24',
    source_table   = 't24_loans',
    hub_hashkey    = 'loans_hashkey',
    hashdiff_name  = 'hashdiff_sat_loans_information',
    list_cols      = ['interest_rate', 'outstanding_balance', 'due_date', ...],
    raw_sql        = none
) }}
```

**Các cột chuẩn**:
| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `{entity}_hashkey` | string | FK → Hub |
| `hashdiff` | string | SHA2-256 của toàn bộ attribute, dùng để detect thay đổi |
| `source_event_date` | date | Ngày của bản ghi |
| `load_timestamp` | timestamp | Thời điểm load |
| `record_source` | string | Nguồn dữ liệu |
| *(attribute columns)* | varied | Các cột nghiệp vụ |

**Incremental logic**: Unique key = `[hub_hashkey, hashdiff, source_event_date]`. Nếu hashdiff giống → skip (dữ liệu không đổi). Nếu hashdiff khác → insert bản ghi mới.

**Ví dụ Satellite models**: `sat_loans_information`, `sat_loans_classification`, `sat_loans_rate`, `sat_loans_terms`, `sat_customer_profile`, `sat_account_additional_info`, `sat_deposit_attributes`, `sat_branch_information`, `sat_crb_balance`

---

### 4.4 Link

**Macro**: `macros/tables/link.sql`  
**Số lượng**: 196 models  
**Quy ước đặt tên**: `link_{entity1}_{entity2}` hoặc `link_{entity}_{relationship}`  

**Mục đích**: Lưu trữ **mối quan hệ** giữa các Hub. Một Link liên kết 2+ Hub. Không bao giờ cập nhật, chỉ insert mối quan hệ mới.

**Tham số macro**:
```sql
{{ config(
    source_model              = 'v_stg_t24_t24_account',
    source_name               = 't24',
    source_table              = 't24_account',
    unique_key                = 'account_customer_hashkey',
    source_business_key_cols  = ['account_no', 'customer_no'],
    foreign_business_key_cols = {
        'account_hashkey': ['account_no'],
        'customer_hashkey': ['customer_no']
    },
    raw_sql = none
) }}
```

**Các cột chuẩn**:
| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `{link_name}_hashkey` | string | PK — SHA2-256 của composite key |
| `{hub1}_hashkey` | string | FK → Hub 1 |
| `{hub2}_hashkey` | string | FK → Hub 2 |
| *(thêm hubs nếu có)* | string | FK → Hub N |
| `source_event_date` | date | Ngày mối quan hệ xuất hiện |
| `record_source` | string | Nguồn dữ liệu |
| `load_timestamp` | timestamp | Thời điểm insert |

**Ví dụ Link models**: `link_account_customer`, `link_account_limit`, `link_loans_limit`, `link_loans_saleid`, `link_collateral_right_limit`, `link_crb_customer`, `link_letter_of_credit_limit`, `link_payment_order_hierarchy`, `link_virtual_account_account_t24`, `link_account_contract_card`

---

### 4.5 Reference Table

**Macro**: `macros/tables/ref_table.sql`  
**Số lượng**: 67 models  
**Quy ước đặt tên**: `ref_{name}`  

**Mục đích**: Bảng tham chiếu mã — danh mục, loại, trạng thái. Tương tự SCD (Slowly Changing Dimension) nhưng trong chuẩn Data Vault.

**Tham số macro**:
```sql
{{ config(
    src_table   = 'bronze_currency_codes',
    src_type    = 'CURRENCY',
    src_code    = 'currency_code',
    src_des     = 'currency_description',
    source_name = 't24',
    where_clause = none
) }}
```

**Các cột chuẩn**:
| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `Ref_hashkey` | string | PK — SHA2-256 của code |
| `Ref_type` | string | Loại danh mục |
| `Ref_code` | string | Mã code gốc |
| `Ref_description` | string | Mô tả |
| `source_event_date` | date | Ngày hiệu lực |
| `Record_source` | string | Nguồn |
| `load_timestamp` | timestamp | Thời điểm load |

**Ví dụ**: `ref_holiday`, `ref_currency`, `ref_account_type`, `ref_transaction_type`, `ref_product_codes`

---

### 4.6 Status Tracking Satellite (STS Huh)

**Macro**: `macros/tables/sts_hub.sql`  
**Quy ước đặt tên**: `sts_hub_{entity_name}`  

**Mục đích**: Theo dõi các entity bị xóa hoặc thay đổi trạng thái CDC. Data Vault không xóa dữ liệu — thay vào đó STS Hub ghi lại lịch sử xóa/cập nhật.

**Các cột chuẩn**:
| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `{entity}_hashkey` | string | FK → Hub |
| `source_event_date` | date | Ngày sự kiện |
| `cdc_status` | string | `I` = Insert, `U` = Update, `D` = Delete |
| `record_source` | string | Nguồn |
| `load_timestamp` | timestamp | Thời điểm load |

**Dùng bởi**: PIT và Bridge tables để lọc entity không còn active.

---

### 4.7 PIT (Point-in-Time)

**Macro**: `macros/tables/pit.sql`  
**Số lượng**: 4 models  
**Quy ước đặt tên**: `pit_{entity_name}`  

**Mục đích**: Tạo snapshot tại một ngày cụ thể — lấy giá trị `source_event_date` mới nhất của từng Satellite tính đến `snapshot_date`. Phục vụ query analytics hiệu năng cao.

**Tham số macro**:
```sql
{{ config(
    source_model = 'hub_loans',
    src_hashkey  = 'loans_hashkey',
    satellites   = {
        'sat_loans_information':   'loans_hashkey',
        'sat_loans_classification': 'loans_hashkey',
        'sat_loans_rate':          'loans_hashkey',
        'sat_loans_terms':         'loans_hashkey'
    },
    sts_hub_table = 'sts_hub_loans',
    sts_hub_pk    = 'loans_hashkey'
) }}
```

**Các cột chuẩn**:
| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `{entity}_hashkey` | string | FK → Hub |
| `snapshot_date` | date | Ngày snapshot |
| `{sat_name}_source_event_date` | date | Ngày mới nhất của satellite tính đến snapshot_date |

**PIT Models hiện có**:
| Model | Hub | Satellites |
|-------|-----|-----------|
| `pit_loan` | hub_loans | sat_loans_information, sat_loans_classification, sat_loans_rate, sat_loans_terms |
| `pit_account` | hub_account | các satellite account |
| `pit_customer` | hub_customer | các satellite customer |
| `pit_acnt_contract` | hub_account | contract satellites |

---

### 4.8 Bridge

**Macro**: `macros/tables/bridge.sql`  
**Số lượng**: 5 models  
**Quy ước đặt tên**: `bridge_{base_entity}`  

**Mục đích**: Đường đi qua nhiều Hub-Link phức tạp trong một bảng dẹt (flattened). Cho phép JOIN hiệu quả thay vì phải traverse nhiều bảng.

**Tham số macro**:
```sql
{{ config(
    source_name = 't24',
    base_model  = 'hub_account',
    base_pk     = 'account_hashkey',
    bridge_walk = [
        {
            'link_table': 'link_account_customer',
            'link_fk': 'account_hashkey',
            'link_pk': 'customer_hashkey',
            'hub_table': 'hub_customer',
            'hub_pk': 'customer_hashkey',
            'join_type': 'left',
            'effsat_table': 'effsat_account_customer'  -- optional effective satellite
        },
        ...
    ],
    select_cols    = ['account_hashkey', 'customer_hashkey', ...],
    where_clause   = none,
    sts_hub_table  = 'sts_hub_account'
) }}
```

**Bridge Models hiện có**:
| Model | Base | Đi qua |
|-------|------|--------|
| `bridge_account` | hub_account | hub_crb, hub_loans, hub_branch, hub_customer |
| `bridge_loan` | hub_loans | hub_customer, hub_branch, hub_collateral |
| `bridge_card` | hub_card | hub_account, hub_customer |
| `bridge_doc` | hub_document | hub_customer, hub_account |
| `bridge_ft` | hub_funds_transfer | hub_account, hub_customer |

---

### 4.9 SAL / Computed Satellite

**Macros**: `macros/tables/sal.sql`, `macros/tables/computed_satellite.sql`

**Mục đích**: 
- **SAL (Satellite Applied Logic)**: Aggregate, tính toán business logic từ raw vault
- **Computed Satellite**: Các thuộc tính dẫn xuất không có trong nguồn gốc

Khác biệt với Satellite thông thường: dữ liệu được tính toán (aggregated/derived), không load trực tiếp từ source.

---

### 4.10 Data Mart (Fact & Dimension)

**Số lượng**: 8 models  
**Location**: `models/data_mart/`  
**Catalog**: `ocb_datavault_dev_curated` (tách biệt với raw/business vault)  

**Materialization**: `incremental` với strategy `append` + pre-hook xóa ngày hiện tại trước khi insert.

```sql
-- Pre-hook pattern
DELETE FROM {table} WHERE date_cob = '{{ var("target_date") }}'
```

| Model | Loại | Mô Tả |
|-------|------|-------|
| `fact_casa` | Fact | CASA accounts daily snapshot |
| `fact_loan` | Fact | Loan transactions & attributes |
| `fact_card` | Fact | Card transactions |
| `fact_funds_transfer` | Fact | Chuyển tiền |
| `fact_term_deposit` | Fact | Tiền gửi có kỳ hạn |
| `dim_card` | Dimension | Card attributes |
| `twt_cx_deposit` | Aggregated | Customer deposit view |
| `twt_cx_deposit_agg_m` | Aggregated | Monthly aggregation |

---

## 5. Nguyên Tắc Thiết Kế Data Vault 2.0

### 5.1 Bất Biến (Immutability)

- **Hub & Link**: Chỉ INSERT, không bao giờ UPDATE hoặc DELETE
- **Satellite**: INSERT bản ghi mới khi detect thay đổi qua `hashdiff`. Bản ghi cũ giữ nguyên để lưu lịch sử
- **Xóa mềm**: Dùng STS Hub thay vì xóa vật lý

### 5.2 Hash Key

Tất cả khóa chính đều là SHA2-256 hash:
```sql
-- Ví dụ trong macro hash.sql
SHA2(
    UPPER(TRIM(COALESCE(col1, ''))) || '$' || UPPER(TRIM(COALESCE(col2, ''))),
    256
)
```
- Delimiter: `$`
- NULL → empty string
- TRIM whitespace
- UPPER (mặc định)
- Cho phép join cross-source mà không cần ID sequence

### 5.3 HasDiff — Change Detection

Mỗi satellite row có `hashdiff` = hash của toàn bộ attribute columns. Incremental logic:
```
Nếu (hub_hashkey, source_event_date) đã tồn tại VÀ hashdiff BẰNG nhau → SKIP
Nếu hashdiff KHÁC → INSERT bản ghi mới
```

### 5.4 Source Event Date vs Load Timestamp

| Cột | Ý Nghĩa |
|-----|---------|
| `source_event_date` | Ngày **nghiệp vụ** của dữ liệu tại hệ thống nguồn (`data_date` trong Bronze) |
| `load_timestamp` | Thời điểm **thực tế** dữ liệu được load vào vault |

`source_event_date` = `target_date` trong job — cho phép backfill lịch sử.

### 5.5 Record Source

Format: `{source_name}.{table_name}` — ví dụ `t24.t24_account`  
Cho phép truy vết nguồn gốc của mỗi bản ghi.

### 5.6 Contract Enforcement

Raw vault và Business vault dùng `dbt contract: enforced: true` — đảm bảo schema không thay đổi ngầm. Nếu schema drift → job fail, ghi vào `etl_schema_drift_log`.

### 5.7 Liquid Clustering (Databricks)

Tất cả bảng raw vault và business vault dùng Liquid Clustering (thay vì partition):
- Tự động cluster theo access patterns
- Không cần chọn partition key thủ công
- Hiệu quả với incremental load

### 5.8 Cross-Source Links

Thư mục `models/raw_vault/cross_source/` chứa các Link nối entity từ 2 hệ thống nguồn khác nhau. Ví dụ: `link_virtual_account_account_t24` nối dữ liệu từ WAY4 và T24.

---

## 6. Luồng ETL End-to-End

### 6.1 Daily Run (Hàng Ngày)

```
Bước 1: generate_target_date
├─ Input: --target-date (để trống = ngày hôm qua)
└─ Output: target_date variable (yyyyMMdd)

Bước 2: run_stg_{source}
├─ Lệnh: dbt run --select path:models/staging/snp/{source}
├─ Biến: target_date, run_mode=daily, source_name={source}
├─ checkpoint_hooks_enabled=true
└─ Kết quả: Views v_stg_* lọc theo target_date

Bước 3: test_stg_{source}  [chạy ALL_DONE]
├─ Lệnh: dbt test --select path:models/staging/snp/{source}
└─ Kết quả: Ghi vào etl_quality_check

Bước 4: freshness_stg_{source}  [chạy ALL_DONE]
├─ Lệnh: dbt source freshness --select "source:staging.v_stg_{source}_*"
└─ Kết quả: Ghi vào etl_model_checkpoint, task_key='freshness'

Bước 5: run_raw_vault  [phụ thuộc bước 3 + 4]
├─ Lệnh: dbt run --select path:models/raw_vault,tag:{source}
├─ Thứ tự: Hub → Link → Satellite → Reference (dbt resolves automatically)
└─ Kết quả: Merge incremental vào Hub/Sat/Link/Ref

Bước 6: run_dbt_test  [phụ thuộc bước 5]
├─ Lệnh: dbt test --select path:models/raw_vault,tag:{source}
└─ Kết quả: Ghi vào etl_quality_check

Bước 7: run_business_vault  [phụ thuộc tất cả sources]
├─ Lệnh: dbt run --select path:models/business_vault
└─ Kết quả: PIT, Bridge, SAL, Calendar

Bước 8: run_edw_mart  [phụ thuộc bước 7]
├─ Lệnh: dbt run --select path:models/data_mart
└─ Kết quả: Fact/Dimension tables trong curated catalog
```

### 6.2 Chi Tiết Incremental Merge Logic

**Staging → Hub**:
```sql
MERGE INTO hub_account AS target
USING (SELECT * FROM v_stg_t24_t24_account WHERE source_event_date = target_date) AS source
ON target.account_hashkey = source.account_hashkey
WHEN NOT MATCHED THEN INSERT (...)
-- skip_matched = true: không UPDATE khi match
```

**Staging → Satellite**:
```sql
MERGE INTO sat_account_info AS target
USING (
    SELECT src.*
    FROM v_stg_t24_t24_account src
    LEFT JOIN sat_account_info tgt
        ON src.account_hashkey = tgt.account_hashkey
        AND src.source_event_date = tgt.source_event_date
    WHERE src.source_event_date = target_date
      AND tgt.account_hashkey IS NULL          -- New record
       OR src.hashdiff != tgt.hashdiff         -- Changed
) AS source
ON target.account_hashkey = source.account_hashkey
   AND target.hashdiff = source.hashdiff
   AND target.source_event_date = source.source_event_date
WHEN NOT MATCHED THEN INSERT (...)
```

### 6.3 Target Date Variable

Mỗi dbt run nhận `target_date` (yyyyMMdd format):
- Staging views: `WHERE data_date = target_date`
- Raw vault: insert chỉ record thuộc `source_event_date = target_date`
- Data mart: xóa rồi insert cho `date_cob = target_date`

---

## 7. Cơ Chế Checkpoint & Logging

### 7.1 Tổng Quan

Hệ thống checkpoint giải quyết hai vấn đề:
1. **Idempotency**: Chạy lại pipeline không gây duplicate dữ liệu
2. **Dependency guard**: Tự động block model nếu upstream có lỗi

Kiểm soát bằng biến `checkpoint_hooks_enabled` (default: `false`, bật trong production jobs).

### 7.2 Custom Materialization: `incremental_checkpoint`

Mọi model raw vault và business vault dùng materialization này thay vì `incremental` thông thường.

```
Khi dbt run một model:

1. checkpoint_pre_hook()
   └─ Ghi trạng thái 'started' vào log

2. check_skip_model(current_model)
   ├─ Kiểm tra 5 điều kiện (xem 7.3)
   ├─ Trả về: False (chạy bình thường) | True (skip) | 'block' (chặn)
   │
   ├─ Nếu 'block': ghi record status='block' → return no-op relation
   ├─ Nếu True (skip): return no-op relation (không thực thi SQL)
   └─ Nếu False: tiếp tục bước 3

3. run_base_materialization('incremental')
   └─ Thực thi MERGE SQL thực sự

4. checkpoint_post_hook()
   └─ Cleanup

Kết quả ghi vào etl_model_checkpoint (bởi on-run-end hook)
```

### 7.3 Skip Logic — 5 Điều Kiện

```
┌─ Điều kiện 1: Model đã chạy thành công hôm nay?
│  SELECT COUNT(*) FROM etl_model_checkpoint
│  WHERE name = '{model}' AND etl_date = '{target_date}'
│        AND task_key = 'run' AND status = 'success'
│  → Nếu > 0: SKIP ⏭️
│
├─ Điều kiện 2: Source freshness cảnh báo?
│  SELECT name FROM etl_model_checkpoint
│  WHERE name IN (upstream_sources)
│        AND etl_date = '{target_date}'
│        AND task_key = 'freshness' AND status = 'warning'
│  → Nếu có: BLOCK ⛔ (lý do: dữ liệu nguồn không tươi)
│
├─ Điều kiện 3: Staging test thất bại?
│  SELECT model_name FROM etl_model_checkpoint
│  WHERE model_name IN (upstream v_stg_* models)
│        AND etl_date = '{target_date}'
│        AND task_key = 'test' AND status IN ('fail','error')
│  → Nếu có: BLOCK ⛔ (lý do: data quality staging lỗi)
│
├─ Điều kiện 4: Staging chưa chạy hôm nay?
│  SELECT model_name FROM etl_model_checkpoint
│  WHERE model_name IN (upstream v_stg_* models)
│        AND etl_date = '{target_date}'
│        AND task_key = 'run' AND status = 'success'
│  → Nếu thiếu: BLOCK ⛔ (lý do: staging chưa chạy)
│
├─ Điều kiện 5: Upstream RV nằm ngoài selected run?
│  Kiểm tra: upstream raw_vault models (non v_stg_*) có trong
│            selected_resources của lần chạy hiện tại không?
│  → Nếu không: BLOCK ⛔ (ngăn invalid data từ partial run)
│
└─ Không có điều kiện nào: RUN ✅
```

### 7.4 Logging Test Results (log_test_results_to_db)

Chạy **luôn luôn** sau mỗi dbt run (kể cả khi `checkpoint_hooks_enabled=false`):

```
Phân loại test:
├─ Tests trên staging models (v_stg_*)
│  └─ Ghi vào: etl_model_checkpoint (task_key='test')
│
└─ Tests trên raw_vault models
   └─ Ghi vào: etl_quality_check
      ├─ Batch 200 rows / lần insert
      └─ Log: "↳ Batch 1/N appended (200 rows)"

Mỗi record gồm:
- test_name, model_name, column_name
- severity ('error'/'warn'), status ('pass'/'fail')
- message (failure details)
- compiled_sql (full SQL để debug)
- source_name, etl_date, timestamps
```

### 7.5 Console Logging

**log_run_start_to_console()**:
```
============================================================
  ETL RUN START
============================================================
  source_name     : t24
  run_id          : abc123
  job_id          : 12345
  task_key        : run
  etl_date        : 20240521
  selected_models : 119 models
------------------------------------------------------------
```

**log_run_end_to_console(results)**:
```
============================================================
  ETL RUN END
  Total: 119 | Success: 115 | Warning: 2 | Error: 1 | Skip: 1
============================================================
```

---

## 8. Các Bảng Metadata

Tất cả ghi vào schema `audit_log` (biến `function_schema`).

### 8.1 etl_model_checkpoint

Ghi lịch sử chạy của từng dbt model:

| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `id` | string | UUID |
| `run_id` | string | dbt invocation_id |
| `job_id` | string | Databricks job ID |
| `task_key` | string | `'run'` / `'test'` / `'freshness'` |
| `database_name` | string | Catalog |
| `schema_name` | string | Schema |
| `name` | string | Model alias / source identifier |
| `model_name` | string | dbt model name |
| `source_name` | string | t24 / way4 / omni / bpm / crm / callcenter |
| `execution_time` | float | Seconds |
| `etl_date` | string | Target date (yyyyMMdd) |
| `started_at` | timestamp | Thời điểm bắt đầu |
| `completed_at` | timestamp | Thời điểm hoàn thành |
| `rows_affected` | int | Số rows insert/update |
| `status` | string | `success` / `fail` / `error` / `warning` / `block` / `skip` |
| `message` | string | Error/warning message |
| `created_by` | string | Service principal |
| `created_at` | timestamp | |
| `updated_by` | string | |
| `updated_at` | timestamp | |

**Dùng để**: Skip logic, freshness check, staging test check, run summaries.

### 8.2 etl_quality_check

Ghi kết quả dbt tests trên raw vault:

| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `id` | string | UUID |
| `run_id` | string | dbt invocation_id |
| `job_id` | string | Databricks job ID |
| `task_key` | string | `'test'` |
| `test_name` | string | Ví dụ: `not_null_hub_account_account_hashkey` |
| `model_name` | string | Model được test |
| `column_name` | string | Cột được test |
| `severity` | string | `'error'` / `'warn'` |
| `status` | string | `'pass'` / `'fail'` |
| `message` | string | Chi tiết lỗi |
| `compiled_sql` | string | SQL đầy đủ của test (để debug) |
| `source_name` | string | Hệ thống nguồn |
| `etl_date` | string | Target date |
| `started_at` | timestamp | |
| `completed_at` | timestamp | |
| `created_by` | string | |
| `created_at` | timestamp | |

### 8.3 etl_schema_drift_log

Ghi lại các thay đổi schema (cột thêm/bớt):

| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `id` | string | UUID |
| `log_time` | timestamp | Thời điểm phát hiện drift |
| `run_id` | string | |
| `job_id` | string | |
| `model_name` | string | Model bị schema drift |
| `etl_date` | string | |
| `target_database` | string | |
| `target_schema` | string | |
| `added_columns` | string | JSON array cột được thêm |
| `removed_columns` | string | JSON array cột bị xóa |
| `action_taken` | string | `'ignored'` / `'failed'` / `'migrated'` |

### 8.4 etl_source_image_consolidate

Reconciliation row counts giữa source và target:

| Cột | Kiểu | Mô Tả |
|-----|------|-------|
| `id` | string | UUID |
| `check_time` | timestamp | |
| `run_id` | string | |
| `model_name` | string | |
| `etl_date` | string | |
| `source_count` | int | Row count ở Bronze/Staging |
| `target_count` | int | Row count ở Raw Vault |
| `diff_count` | int | Chênh lệch |

---

## 9. Macros Tổng Hợp

### 9.1 Table Macros (`macros/tables/`)

| Macro | File | Mục Đích |
|-------|------|---------|
| `hub` | hub.sql | Sinh SQL cho Hub tables |
| `satellite` | satellite.sql | Sinh SQL cho Satellite tables |
| `link` | link.sql | Sinh SQL cho Link tables |
| `pit` | pit.sql | Sinh SQL cho PIT snapshots |
| `bridge` | bridge.sql | Sinh SQL cho Bridge tables |
| `bridge_append` | bridge_append.sql | Bridge với append strategy |
| `ref_table` | ref_table.sql | Sinh SQL cho Reference tables |
| `sts_hub` | sts_hub.sql | Soft-delete hub |
| `effsat_link` | effsat_link.sql | Effective satellite cho links |
| `sal` | sal.sql | SAL aggregation |
| `computed_satellite` | computed_satellite.sql | Computed satellites |
| `link_computed_aggregate` | link_computed_aggregate.sql | Aggregated links |
| `link_exploration` | link_exploration.sql | Exploratory links |
| `stage` | stage.sql | Sinh SQL cho Staging views |

### 9.2 Utility Macros (`macros/utils/`)

| Macro | File | Mục Đích |
|-------|------|---------|
| `hash_key(cols, is_upper)` | hash.sql | Tính SHA2-256 hash key |
| `hash_column(cols, src)` | hash.sql | Alias của hash_key |
| `get_columns(relation)` | get_columns.sql | Lấy danh sách cột động từ DESCRIBE |
| `to_yyyymmdd_str(col, dtype)` | date_to_str.sql | Chuẩn hóa date format |
| `get_staging_config(...)` | get_staging_config.sql | Lấy cấu hình staging từ metadata |
| `generate_schema_name(...)` | generate_schema_name.sql | Sinh tên schema động |

### 9.3 Checkpoint Macros (`macros/checkpoint/`)

| Macro | File | Mục Đích |
|-------|------|---------|
| `init_checkpoint_table()` | init_checkpoint_table.sql | Tạo 4 bảng metadata nếu chưa có |
| `check_skip_model(model)` | check_model.sql | Logic skip/block/run |
| `log_test_results_to_db(results)` | log_test_results_to_db.sql | Ghi kết quả test vào DB |
| `log_run_results_to_db(results)` | log_results.sql | Ghi kết quả model run vào DB |
| `log_run_start_to_console()` | console_log.sql | In banner run start |
| `log_run_end_to_console(results)` | console_log.sql | In summary run end |
| `checkpoint_database()` | checkpoint.sql | Trả về checkpoint database name |
| `checkpoint_schema()` | checkpoint.sql | Trả về checkpoint schema name |

### 9.4 Materialization Macros (`macros/materializations/`)

| File | Mục Đích |
|------|---------|
| `incremental_checkpoint.sql` | Custom incremental với skip/block logic |
| `table_checkpoint.sql` | Custom table với skip/block logic |
| `view_checkpoint.sql` | Custom view với skip/block logic |
| `checkpoint_helpers.sql` | Helper functions dùng chung |

---

## 10. Kiểm Thử Dữ Liệu (dbt Tests)

### 10.1 Các Loại Test

| Test | Áp dụng trên | Mô Tả |
|------|-------------|-------|
| `unique` | Hub hashkey, Link hashkey | PK không được trùng |
| `not_null` | Hashkey, business_key, source_event_date | Cột bắt buộc |
| `relationships` | Sat/Link hashkey → Hub | FK integrity |
| `unique_combination_of_columns` | Satellite | Composite unique check |

### 10.2 Cấu Hình Severity

Mặc định test dùng `severity: error` (fail = job dừng).  
Có thể override thành `severity: warn`:

```yaml
# raw_vault_schema_bpm.yml
columns:
  - name: auth_to_chuc_don_vi_hashkey
    data_type: string
    tests:
      - unique:
          severity: warn
      - not_null:
          severity: warn
```

- `severity: error` → test fail → ghi `status='fail'` → staging block downstream
- `severity: warn` → test fail → ghi `status='warn'` → pipeline tiếp tục

### 10.3 Custom Test

**File**: `tests/generic/unique_combination_of_columns.sql`

```sql
{% test unique_combination_of_columns(model, combination_of_columns) %}
    SELECT {{ combination_of_columns | join(', ') }}, COUNT(*) AS cnt
    FROM {{ model }}
    GROUP BY {{ combination_of_columns | join(', ') }}
    HAVING COUNT(*) > 1
{% endtest %}
```

Dùng cho Satellite khi cần validate composite uniqueness.

### 10.4 Luồng Test trong Pipeline

```
run_stg_{source}     → test_stg_{source}  → kết quả vào etl_model_checkpoint (task_key='test')
                                          ↓
                       freshness_{source}  → kết quả vào etl_model_checkpoint (task_key='freshness')
                                          ↓
run_raw_vault ← check_skip_model đọc 2 bảng trên để quyết định block/run
                                          ↓
run_dbt_test (raw vault)                  → kết quả vào etl_quality_check
```

---

## 11. Orchestration — Databricks Jobs

### 11.1 Job Files

Định nghĩa trong `resources/`:

| File | Mô Tả |
|------|-------|
| `dbrjobs-run-daily-datavault-silver-t24.yml` | Daily job cho T24 |
| `dbrjobs-run-daily-datavault-silver-way4.yml` | Daily job cho WAY4 |
| `dbrjobs-run-daily-datavault-silver-omni.yml` | Daily job cho OMNI |
| `dbrjobs-run-daily-datavault-silver-bpm.yml` | Daily job cho BPM |
| `dbrjobs-run-daily-datavault-silver-crm.yml` | Daily job cho CRM |
| `dbrjobs-run-daily-datavault-silver-callcenter.yml` | Daily job cho CallCenter |
| `dbrjobs-run-daily-datavault-gold-edw-mart.yml` | Daily job cho Gold/Mart |
| `dbrjobs-run-history-datavault-silver-*.yml` | Backfill jobs (1 per source) |
| `job_run_dbt_test.yml` | Standalone test job |
| `job_run_dbt_loop_dates.yml` | Loop nhiều ngày |

### 11.2 Task Dependencies (Daily T24)

```
generate_target_date (Python)
        ↓
run_stg_t24 (dbt run staging)
        ↓ (ALL_DONE)
    ┌───────────┐
test_stg_t24  freshness_stg_t24
    └─────┬─────┘
          ↓
  run_raw_vault_t24 (dbt run raw_vault tag:t24)
          ↓
  run_dbt_test_t24
          ↓
  [merge với các sources khác]
          ↓
  run_business_vault
          ↓
  run_edw_mart
```

### 11.3 dbt Task Variables

Mỗi task truyền:
```
--vars '{
  "target_date": "{{ tasks.generate_target_date.values.target_date }}",
  "run_mode": "daily",
  "source_name": "t24",
  "checkpoint_hooks_enabled": "true"
}'
```

### 11.4 Dashboard Monitoring

**File**: `ETL Operations Monitor.lvdash.json`  
Databricks dashboard để theo dõi:
- Trạng thái các job runs
- Số models success/fail/block theo ngày
- Test failure trends
- Freshness status

---

## 12. CI/CD — GitLab Pipeline

**File**: `.gitlab-ci.yml`

### Stages

| Stage | Mô Tả |
|-------|-------|
| `checkout` | Xác định environment target từ branch name |
| `validate_bundle` | Validate Databricks bundle config |
| `deploy_bundle` | Deploy bundle lên Databricks workspace |

### Environments

| Branch | Target |
|--------|--------|
| `dev` | dev |
| `pilotcloud` | pilotcloud |
| `main`/`master` | prod |

### Bundle Deploy

Dùng `databricks bundle deploy`:
- Root path: `/Workspace/Users/{service_principal}/.bundle/{bundle_name}/{target}`
- Auth: OAuth service principal (client_id/client_secret từ CI variables)
- Deploy: Jobs, schemas, permissions

---

## 13. Backfill & Lịch Sử

### 13.1 Python Backfill Scripts (`sourcing/`)

| Script | Mô Tả |
|--------|-------|
| `generate_backfill_dates.py` | Sinh danh sách ngày từ start_date đến end_date |
| `generate_target_date.py` | Xác định target_date (default: hôm qua) |
| `run_stg_rv_backfill.py` | Chạy staging + raw_vault cho dải ngày |
| `run_business_vault_backfill.py` | Chạy business vault cho dải ngày |

### 13.2 Luồng Backfill

```bash
# Bước 1: Generate date list
python generate_backfill_dates.py --start 20240101 --end 20240531

# Bước 2: Run staging + raw vault cho từng ngày
python run_stg_rv_backfill.py --dates dates.json --source t24
# → dbt run --select path:models/staging,path:models/raw_vault
# → Dừng lại nếu có ngày bị lỗi

# Bước 3: Run business vault
python run_business_vault_backfill.py --dates '[20240101,20240102,...]'
# → dbt run --select path:models/business_vault
```

### 13.3 Backfill Jobs (Databricks)

`dbrjobs-run-history-datavault-silver-{source}.yml` — chạy backfill trên Databricks với:
- Số thread cao hơn
- Không bị giới hạn checkpoint skip (có thể force re-run)

### 13.4 Notebooks Backfill

`scripts/backfill_hub_history/`:
- `nb_backfill_hub_history_t24.ipynb`
- `nb_backfill_hub_history_way4.ipynb`
- `nb_backfill_hub_history_bpm.ipynb`

Dùng để backfill lịch sử đặc biệt cho Hub (edge cases không thể xử lý qua job thông thường).

---

## 14. Các Hệ Thống Nguồn

| Nguồn | Schema | Mô Tả | Cột Date | Format |
|-------|--------|-------|----------|--------|
| **T24** | t24 | Core banking — account, customer, loans, deposits, forex | `data_date` | yyyyMMdd |
| **WAY4** | way4 | Card management system — payment, card, device | `data_date` | yyyyMMdd |
| **OMNI** | omni | Omni-channel system — customer interactions | `data_date` | yyyyMMdd |
| **BPM** | bpm | Business Process Management — process events | `event_date` | yyyyMMdd |
| **CRM** | crm | Customer Relationship Management | `create_date` | yyyyMMdd |
| **CallCenter** | callcenter | Call center interactions | `call_date` | yyyyMMdd |

### Số Lượng Tables Per Source (ước tính)

| Nguồn | Bronze Tables | Staging Views | Hub | Sat | Link | Ref |
|-------|--------------|---------------|-----|-----|------|-----|
| T24 | ~89 | ~89 | ~60 | ~130 | ~90 | ~30 |
| WAY4 | ~50 | ~50 | ~25 | ~70 | ~50 | ~15 |
| OMNI | ~20 | ~20 | ~15 | ~35 | ~25 | ~10 |
| BPM | ~30 | ~30 | ~12 | ~25 | ~20 | ~8 |
| CRM | ~10 | ~10 | ~5 | ~10 | ~7 | ~3 |
| CallCenter | ~15 | ~15 | ~2 | ~5 | ~4 | ~1 |

### Source Metadata Configuration

Mỗi source table trong `bronze_sources.yml` có metadata:
```yaml
- name: t24_account
  meta:
    run_mode:
      backfill:
        - source_event_date_col: 'data_date'
        - source_event_date_dttype: 'yyyyMMdd'
      daily:
        - source_event_date_col: 'data_date'
        - source_event_date_dttype: 'yyyyMMdd'
  columns:
    - name: t_customer     # Override data type
      data_type: bigint
```

---

## 15. Thống Kê Dự Án

### Số Lượng Models

| Loại | Số Lượng |
|------|---------|
| Staging Views | 182 |
| Hub | 119 |
| Satellite | 275 |
| Link | 196 |
| Reference | 67 |
| PIT | 4 |
| Bridge | 5 |
| SAL / Computed | ~10 |
| Data Mart | 8 |
| **Tổng** | **~866** |

### Số Lượng Macros

| Loại | Số Lượng |
|------|---------|
| Table macros | 14 |
| Utility macros | 6 |
| Checkpoint macros | 5 |
| Materialization macros | 4 |
| **Tổng** | **29** |

### Metadata Tables

| Bảng | Mục Đích |
|------|---------|
| `etl_model_checkpoint` | Model run history + skip logic |
| `etl_quality_check` | Data quality test results |
| `etl_schema_drift_log` | Schema change tracking |
| `etl_source_image_consolidate` | Row count reconciliation |

### Infrastructure

| Hạng Mục | Giá Trị |
|----------|---------|
| dbt threads | 20 |
| Environments | 3 (dev / pilotcloud / prod) |
| Daily Databricks Jobs | 7+ (1 per source + BV + Gold) |
| Catalog Strategy | Unity Catalog với 3 catalogs |
| Storage Format | Delta Lake (ACID) |
| Clustering | Liquid Clustering |
| Auth | OAuth M2M service principal |

---

## 16. Init Data — Khởi Tạo Dữ Liệu Ban Đầu

### 16.1 Tổng Quan

"Init data" là quá trình khởi tạo toàn bộ hạ tầng bảng và nạp dữ liệu lịch sử lần đầu tiên vào một môi trường mới (dev / pilotcloud / prod). Gồm 3 giai đoạn:

```
Giai đoạn 1: Tạo bảng vật lý (DDL)
        ↓
Giai đoạn 2: Khởi tạo metadata tables (init_checkpoint_table)
        ↓
Giai đoạn 3: Nạp dữ liệu lịch sử (Backfill)
        ↓
Vận hành daily bình thường
```

---

### 16.2 Giai Đoạn 1 — Tạo Bảng Vật Lý (DDL)

**Thư mục**: `ddl/`

Các bảng Raw Vault và Business Vault **không được tạo tự động bởi dbt** trong lần chạy đầu tiên theo cơ chế thông thường. Thay vào đó, DDL scripts được chuẩn bị sẵn và chạy thủ công hoặc qua Databricks notebook trước khi pipeline được kích hoạt.

**Lý do dùng DDL thủ công thay vì để dbt tự tạo**:
- Cần khai báo **Liquid Clustering** (`CLUSTER BY`) ngay khi tạo bảng — dbt không hỗ trợ natively.
- Cần đặt đúng **catalog/schema/table name** theo từng environment (dev/pilotcloud/prod).
- Đảm bảo schema contract (`dbt contract: enforced: true`) khớp với DDL thực tế từ đầu.

**Cấu trúc DDL điển hình**:
```sql
-- Ví dụ: ddl/raw_vault/hub_account.sql
CREATE TABLE IF NOT EXISTS
  ocb_datavault_dev_cleaned.raw_vault.hub_account (
    account_hashkey   STRING    NOT NULL,
    business_key      BIGINT    NOT NULL,
    source_event_date DATE      NOT NULL,
    record_source     STRING    NOT NULL,
    load_timestamp    TIMESTAMP NOT NULL
)
USING DELTA
CLUSTER BY (account_hashkey, source_event_date);
```

**Thứ tự tạo bảng** (phải tuân thủ để tránh FK dependency):
```
1. Hub tables          (không phụ thuộc bảng khác)
2. Reference tables    (không phụ thuộc bảng khác)
3. Link tables         (phụ thuộc Hub)
4. STS Hub tables      (phụ thuộc Hub)
5. Satellite tables    (phụ thuộc Hub)
6. PIT tables          (phụ thuộc Hub + Satellite)
7. Bridge tables       (phụ thuộc Hub + Link)
8. SAL / Computed Sat  (phụ thuộc Raw Vault)
9. Data Mart tables    (phụ thuộc Business Vault)
```

---

### 16.3 Giai Đoạn 2 — Khởi Tạo Metadata Tables

**Macro**: `init_checkpoint_table()` (trong `macros/checkpoint/init_checkpoint_table.sql`)

Macro này được gọi tự động qua `on-run-start` hook **mỗi lần** dbt chạy. Trong lần init đầu tiên, nó sẽ tạo ra 4 bảng metadata:

```sql
-- Logic bên trong init_checkpoint_table()
CREATE TABLE IF NOT EXISTS audit_log.etl_model_checkpoint   (...);
CREATE TABLE IF NOT EXISTS audit_log.etl_quality_check      (...);
CREATE TABLE IF NOT EXISTS audit_log.etl_schema_drift_log   (...);
CREATE TABLE IF NOT EXISTS audit_log.etl_source_image_consolidate (...);
```

**Đặc điểm quan trọng**:
- Dùng `CREATE TABLE IF NOT EXISTS` → **idempotent**, an toàn khi chạy nhiều lần.
- Schema `audit_log` phải tồn tại trước (tạo thủ công trong catalog).
- Sau lần đầu, hook này chạy tiếp nhưng là no-op vì bảng đã có.

---

### 16.4 Giai Đoạn 3 — First Run của dbt Incremental Models

Khi một bảng Raw Vault đã được tạo bởi DDL nhưng **chưa có dữ liệu**, dbt xử lý như sau:

```
is_incremental() = FALSE  (bảng tồn tại nhưng rỗng, hoặc dbt full-refresh)
        ↓
Macro hub/satellite/link sinh ra câu INSERT đầy đủ (không có điều kiện WHERE lọc ngày)
        ↓
Toàn bộ dữ liệu từ staging được insert vào bảng
```

**Tuy nhiên**, với `incremental_checkpoint` materialization, lần đầu chạy vẫn nhận `target_date` — do đó staging view vẫn lọc theo `source_event_date = target_date`. Để init nhiều ngày lịch sử, phải dùng Backfill (xem 16.5).

**Điều kiện để `is_incremental()` = TRUE** (các lần chạy tiếp theo):
- Bảng đã tồn tại trong catalog.
- Không truyền flag `--full-refresh`.
- Materialization không phải `table` hoặc `view`.

---

### 16.5 Nạp Dữ Liệu Lịch Sử (Initial Backfill)

Sau khi bảng trống được tạo, cần nạp toàn bộ lịch sử (ví dụ: 2 năm) trước khi daily job vận hành. Quy trình:

**Bước 1**: Xác định khoảng ngày cần backfill
```bash
python sourcing/generate_backfill_dates.py \
  --start 20220101 \
  --end   20241231 \
  --output dates.json
```

**Bước 2**: Chạy staging + raw vault lần lượt từng ngày
```bash
python sourcing/run_stg_rv_backfill.py \
  --dates dates.json \
  --source t24
# → Với mỗi ngày D:
#   dbt run --select path:models/staging/snp/t24 --vars '{"target_date": "D", "checkpoint_hooks_enabled": "false"}'
#   dbt run --select path:models/raw_vault,tag:t24 --vars '{"target_date": "D", ...}'
#   Nếu ngày D lỗi → dừng lại, không tiếp tục các ngày sau
```

**Lưu ý quan trọng khi backfill**:

| Tham số | Giá Trị Backfill | Lý Do |
|---------|-----------------|-------|
| `checkpoint_hooks_enabled` | `false` | Tắt skip-logic để force chạy mọi model |
| `run_mode` | `backfill` | Staging dùng config backfill từ metadata |
| threads | tăng cao hơn daily | Chạy nhanh hơn, ít dependency |

**Bước 3**: Chạy Business Vault sau khi toàn bộ Raw Vault đã có dữ liệu
```bash
python sourcing/run_business_vault_backfill.py \
  --dates '[20220101, 20220102, ...]'
# → dbt run --select path:models/business_vault
#   Lặp lại cho từng snapshot_date (PIT/Bridge rebuild theo ngày)
```

**Bước 4**: Chạy Data Mart (thường không cần backfill nhiều năm, chỉ từ ngày Go-Live)
```bash
dbt run --select path:models/data_mart \
  --vars '{"target_date": "20240101", ...}'
```

---

### 16.6 Kiểm Tra Sau Init

Sau khi init xong, thực hiện kiểm tra:

```sql
-- 1. Kiểm tra row count Hub chính
SELECT COUNT(*) FROM ocb_datavault_dev_cleaned.raw_vault.hub_account;
SELECT COUNT(*) FROM ocb_datavault_dev_cleaned.raw_vault.hub_customer;
SELECT COUNT(*) FROM ocb_datavault_dev_cleaned.raw_vault.hub_loans;

-- 2. Kiểm tra date range đã load
SELECT MIN(source_event_date), MAX(source_event_date)
FROM ocb_datavault_dev_cleaned.raw_vault.hub_account;

-- 3. Kiểm tra không có ngày bị thiếu (gap check)
SELECT source_event_date, COUNT(*) AS records
FROM ocb_datavault_dev_cleaned.raw_vault.sat_loans_information
GROUP BY source_event_date
ORDER BY source_event_date;

-- 4. Kiểm tra metadata checkpoint
SELECT etl_date, COUNT(*) AS models_run, SUM(CASE WHEN status='success' THEN 1 ELSE 0 END) AS success
FROM audit_log.etl_model_checkpoint
WHERE task_key = 'run'
GROUP BY etl_date
ORDER BY etl_date;
```

---

### 16.7 Tóm Tắt Thứ Tự Init

```
[Môi trường mới]
       ↓
1. Tạo catalog + schema trên Databricks Unity Catalog (thủ công)
       ↓
2. Chạy DDL scripts trong ddl/ (thứ tự: Hub → Ref → Link → STS → Sat → PIT → Bridge → SAL → Mart)
       ↓
3. Deploy bundle: databricks bundle deploy --target dev
       ↓
4. Chạy dbt run lần đầu với target_date = ngày đầu của lịch sử
   → on-run-start: init_checkpoint_table() tạo 4 bảng audit_log.*
   → Models chạy với is_incremental()=FALSE (bảng rỗng)
       ↓
5. Backfill toàn bộ ngày lịch sử (sourcing/run_stg_rv_backfill.py)
   với checkpoint_hooks_enabled=false
       ↓
6. Backfill Business Vault (sourcing/run_business_vault_backfill.py)
       ↓
7. Kiểm tra row counts và date ranges
       ↓
8. Bật daily Databricks Job → vận hành bình thường
```

---

*Tài liệu này được sinh tự động từ source code ngày 2026-05-22.*  
*Cập nhật khi có thay đổi kiến trúc hoặc macro mới.*
