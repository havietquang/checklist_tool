# input/ — bỏ file cần kiểm tra vào đây

| Thư mục | Bỏ gì vào | Bắt buộc |
|---|---|---|
| `sql/` | File `.sql` code Gold — **mỗi object 1 file** | Có |
| `mapping/` | Workbook thiết kế `.xlsx` — 1 file có thể mô tả nhiều object | Có |
| `checklist/` | File checklist OCB dùng làm template để điền kết quả | Có (đã có sẵn) |

Không cần đổi tên file theo quy tắc gì — tool tự ghép cặp SQL ↔ workbook theo **tên object**
(bỏ các hậu tố `_Silver_to_Gold`, `_mapping`, `_v2`, `_backup`, `(1)`, `_20260717`).

---

## sql/ — code Gold

Mỗi file là 1 object. Tool nhận cả 3 dạng:

```sql
-- Dạng 1: CREATE
USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;
CREATE OR REPLACE VIEW v_cdtk_daily AS SELECT ...

-- Dạng 2: DELETE + INSERT
DELETE FROM ocb_datavault_dev_curated.tckh.FTP_FACT WHERE CDR_DT_ID = CAST(:DATADT AS INT);
INSERT INTO ocb_datavault_dev_curated.tckh.FTP_FACT (COT_1, COT_2, ...) SELECT ...

-- Dạng 3: chỉ SELECT (bước load do DBX Workflow lo)
-- Dich Gold : ocb_datavault_dev_curated.tckh.RT_PL_DTL     <- tool đọc dòng comment này
SELECT ...
```

## mapping/ — workbook thiết kế

Tool đọc **2 khối**. Tên cột nhận nhiều biến thể nên không cần sửa workbook đang có.
Sheet `Script` / `SQL` / `Code` (dump code) được bỏ qua khi đọc đặc tả.

**Khối 1 — `JOIN SCHEMA`** (dùng cho tiêu chí X.8: thiết kế khớp code)

```
JOIN SCHEMA — <TÊN_OBJECT>
 # | Table / View        | Alias | JOIN Type  | ON Condition / Ghi chú
 1 | hub_customer        | h     | BASE       |
 2 | sat_customer_class  | s     | LEFT JOIN  | s.customer_hashkey = h.customer_hashkey
```

**Khối 2 — `FIELD MAPPING`** (dùng cho tiêu chí 1.1: SQL đủ cột chưa)

```
FIELD MAPPING — <TÊN_OBJECT>
 STT | Fields      | Data Type     | Type      | Transform          | Source
 1   | CST_ID      | STRING        | 1:1       | h.customer_hashkey | hub_customer
 2   | BAL_AMT_LCY | DECIMAL(20,4) | Aggregate | COALESCE(SUM(b),0) | sat_account_balance
```
- Tên cột `Fields` nhận cả: `Field`, `Field (Output Col)`, `Target column`, `Column`
- Cột `STT` có hay không đều được

Mẫu đầy đủ: `../tests/fixtures/mapping/GOOD_FCT_Silver_to_Gold.xlsx`

### Một workbook mô tả nhiều object

Được. Tool index theo tên object, không theo tên file:
- **Mỗi sheet 1 object** — tên sheet = tên object
- **Hoặc 2 object cạnh nhau theo cột** trên cùng sheet — tool tách theo tiêu đề block:

```
     A                              G
1  LV0 — VIEW đích (V_CDTK_DAILY)   LV1 — VIEW (V_CDTK_DAILY_1)
2  JOIN SCHEMA — V_CDTK_DAILY       JOIN SCHEMA — V_CDTK_DAILY_1
7  FIELD MAPPING — V_CDTK_DAILY     FIELD MAPPING — V_CDTK_DAILY_1
```

- **Hoặc dạng lineage**: `Summary` + các sheet `1.0 <OBJ>` (object đích) và `1.x <bảng>` (nguồn)

## checklist/ — template

File checklist OCB. Tool **copy** ra `output/` rồi điền vào bản copy — file trong `input/checklist/`
không bị sửa. Có nhiều file thì lấy file đầu theo thứ tự tên; muốn chỉ định thì dùng `--template <đường dẫn>`.
