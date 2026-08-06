# gold_review — tự chấm checklist Silver → Gold (ZoneC OCB)

Đọc code SQL Gold + workbook thiết kế, chấm theo 29 tiêu chí, xuất ra **bản Excel checklist đã
điền sẵn Pass/Fail kèm note chi tiết**. File checklist gốc không bị sửa.

## Chạy

```bash
pip install sqlglot openpyxl          # chỉ lần đầu

python tools/gold_review/run_check.py
```

Không cần tham số — **mặc định lấy code từ sheet `Script SQL` của workbook thiết kế**
(dòng `Type = Code mới`). Kết quả: `output/Checklist_Review_AUTOFILLED.xlsx`

Muốn chấm file `.sql` trong `input/sql/` thì thêm `--from-sql`.

## Cấu trúc

```
tools/gold_review/
│
├── run_check.py          ← CHẠY FILE NÀY
│
├── input/                ← BỎ FILE VÀO ĐÂY          (xem input/README.md)
│   ├── mapping/              workbook thiết kế .xlsx  ← NGUỒN CODE MẶC ĐỊNH
│   ├── sql/                  file .sql code Gold — chỉ dùng khi chạy --from-sql
│   └── checklist/            file checklist OCB làm template
│
├── output/               ← KẾT QUẢ RA ĐÂY           (xem output/README.md)
│   ├── Checklist_Review_AUTOFILLED.xlsx    ← file để xem và gửi OCB
│
├── engine/               ← code chấm, không cần sửa khi dùng bình thường
│   ├── core.py               đọc + parse SQL, phân loại object
│   ├── mapping.py            đọc workbook thiết kế
│   ├── rules.py              29 tiêu chí, mỗi tiêu chí 1 hàm
│   ├── rule_text.py          tên tiêu chí + cách sửa (tiếng Việt) ghi vào note
│   ├── report.py             ghi kết quả vào Excel
│   ├── doc_standard.py       49 bảng transaction + mapping PIT (trích Technical Document)
│   ├── known_issues.json     antipattern OCB đã từng bắt
│   └── standard_pattern.sql  pattern chuẩn đọc Silver, trích nguyên văn từ tài liệu
│
├── docs/
│   ├── USAGE.md          ← input gì, output gì, cách chạy
│   └── RULES.md          ← TỪNG TIÊU CHÍ chấm thế nào: máy đọc gì, ví dụ FAIL/PASS
│
└── tests/                self-test giữ cho rule không hồi quy
    ├── test_rules.py         30 assertion
    ├── fixtures/             SQL cố tình sai + SQL đúng chuẩn
    └── make_fixture_mapping.py   sinh workbook thiết kế mẫu
```

## Luồng xử lý

```
MẶC ĐỊNH:
input/mapping/*.xlsx ──► sheet 'Script SQL' (dòng Code mới) = code cần chấm
                     └─► FIELD MAPPING + JOIN SCHEMA = đặc tả để đối chiếu
                                          │
                                          ├──► chấm 29 tiêu chí ──► output/
                                          │
                              input/checklist/ (template)

--from-sql:
input/sql/*.sql ─────┐
                     ├──► ghép cặp theo tên object ──► chấm 30 tiêu chí ──► output/
input/mapping/*.xlsx ┘  (chỉ lấy FIELD MAPPING + JOIN SCHEMA)
```

## Lệnh khác

```bash
python tools/gold_review/run_check.py --batch "Batch 2" --pic QuangHV   # điền cột Batch / PIC
python tools/gold_review/run_check.py --from-sql                        # chấm file .sql trong input/sql
python tools/gold_review/run_check.py --file input/sql/holiday.sql      # chấm 1 file (tự bật chế độ file)
python tools/gold_review/run_check.py --rule 2.4                        # soi 1 tiêu chí
python tools/gold_review/run_check.py --rule "2.*"                      # soi cả nhóm Logic
python tools/gold_review/tests/test_rules.py                            # chỉ chạy self-test
```

| Exit code | Nghĩa |
|---|---|
| `0` | Mọi object đạt |
| `1` | Còn object "Không đạt" |
| `3` | **Self-test rule trượt → kết quả chấm không đáng tin**, sửa rule trước |

## Script tổng làm 2 việc

1. **Self-test 30 rule** trên fixture cố tình sai/đúng — chấm bằng rule chưa kiểm chứng thì kết
   quả vô nghĩa, nên bước này chạy trước. Bỏ qua bằng `--skip-selftest`.
2. **Chấm 29 tiêu chí × mọi file**: 20 tiêu chí OCB (1.1, 1.2, 2.1–2.12, 3.1–3.6) + 9 tiêu
   chí bổ sung Raffles (nhóm `X`, không tính vào điểm OCB).

Tiêu chí **1.2 (đủ job/task trong luồng)** đã bỏ khỏi checklist: job khai ở `resources/*.job.yml`,
không nằm trong phạm vi code SQL nên không chấm ở đây.

## Nguồn chuẩn của logic chấm

Nhóm 2 (Logic) lấy từ **`OCB_DBX_ZONEC - Technical_Document_v1.1`, mục III.4.2 "Quy tắc khi xử lí
các bảng từ Silver"** — không phải suy đoán:

| Đối tượng | Pattern bắt buộc | Mục |
|---|---|---|
| STS Hub | `GROUP BY hk HAVING max_by(cdc_status, source_event_date) = 'D'` rồi anti-join `IS NULL` | III.4.2.1 |
| Satellite | `max_by(<col>, source_event_date)` + `GROUP BY hk`, **LEFT JOIN**, **không** lọc `cdc_status` | III.4.2.2 |
| Link 1:N | `GROUP BY <driving_hk>` + `max_by(<target_hk>, …)` — rút current *trước* khi join | III.4.2.3 |
| Link M:N | `GROUP BY <link_hashkey>`, không partition theo một phía | III.4.2.3 |
| PIT | `LEFT JOIN sat ON sat.source_event_date = p.<sat>_src_ev_dt` | III.4.2.4 |
| Effsat Link | `HAVING max_by(active_flag, source_event_date) = 1` | III.4.2.5 |
| DIM SCD2 | `APPLY CHANGES INTO … SEQUENCE BY source_event_date STORED AS SCD TYPE 2` | mục LDP |

Hai ngoại lệ dễ chấm sai:

1. **49 bảng transaction** (mục "Các trường hợp đặc biệt") dùng `source_event_date = :DATADT`,
   **không** phải `<=`. Danh sách ở [engine/doc_standard.py](engine/doc_standard.py).
2. **Không lọc `cdc_status` trong satellite** — trạng thái xóa lọc ở `sts_hub_*`. Lọc trong
   satellite là sai tầng.

Pattern trích nguyên văn: [engine/standard_pattern.sql](engine/standard_pattern.sql).
Tài liệu đổi → sửa [engine/doc_standard.py](engine/doc_standard.py) + file trên.

## Nhóm X — 9 tiêu chí bổ sung Raffles

| Mã | Tiêu chí | Nguồn |
|---|---|---|
| `X.1` | Link phải rút về current trước khi join | Technical Document III.4.2.3 |
| `X.2` | Catalog/schema nhất quán theo môi trường | Code từng trộn `dev` và `pilotcloud` |
| `X.3` | `INSERT INTO` phải liệt kê cột | Thêm cột vào DDL là lệch toàn bộ, không báo lỗi |
| `X.4` | Idempotent: có DELETE/TRUNCATE khớp khóa | Chạy lại 2 lần là nhân đôi dữ liệu |
| `X.5` | Join key NULL-safe | `NULL = NULL` trả FALSE → mất dòng âm thầm |
| `X.6` | Satellite phải LEFT JOIN | Technical Document III.4.2.2 nguyên tắc 1 |
| `X.7` | Không hard-code catalog | Dùng `IDENTIFIER(:cleaned \|\| …)` / `${curated_catalog}` |
| `X.8` | JOIN SCHEMA trong thiết kế khớp bảng nguồn trong SQL | Thiết kế và code đi 2 đường |
| `X.9` | Mọi bảng phải dev lại từ Silver | Quy định đã chốt, truy nguồn theo chuỗi |

## Thêm / sửa tiêu chí

Mỗi tiêu chí là 1 hàm trong [engine/rules.py](engine/rules.py):

```python
@rule("2.4", G2, "source_event_date dung dang <= / = theo loai bang", (P_SILVER,))
def r24(ctx, repo) -> Finding:
    ...
    return Finding(FAIL, ["mô tả + số dòng"])
```

- `profiles=()` → áp dụng mọi object; `(P_SILVER,)` → chỉ object đọc Silver, còn lại tự `N-A`
- `ctx` = 1 file (AST sqlglot + text gốc + workbook đã ghép), `repo` = ngữ cảnh toàn batch
- Câu chữ tiếng Việt + cách sửa đặt ở [engine/rule_text.py](engine/rule_text.py)

Sau khi sửa rule **bắt buộc** chạy lại self-test, và thêm case sai tương ứng vào
`tests/fixtures/` + `EXPECT` trong `tests/test_rules.py`:

```bash
python tools/gold_review/tests/test_rules.py
```

Sửa rule thì cập nhật luôn mô tả cách chấm ở [docs/RULES.md](docs/RULES.md) — đó là file DE và
OCB đọc để biết máy kết luận dựa vào đâu.
