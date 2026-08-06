# gold_review — chạy trên máy mới (5 phút)

Tool tự chấm checklist review code Silver → Gold ZoneC OCB, xuất ra bản Excel checklist đã điền
Pass/Fail kèm ghi chú. Không cần kết nối Databricks, không cần dữ liệu thật — chỉ đọc code SQL và
workbook thiết kế.

---

## 1. Cần gì

| | Yêu cầu |
|---|---|
| Python | 3.10 trở lên (đã chạy trên 3.14) |
| Thư viện | `sqlglot >= 25`, `openpyxl >= 3.1` |
| Hệ điều hành | Windows / macOS / Linux đều được |

```powershell
python -m pip install -r gold_review\requirements.txt
```

Kiểm tra cài xong:

```powershell
python -c "import sqlglot, openpyxl; print('ok')"
```

---

## 2. Bỏ file vào đâu

```
gold_review/
└── input/
    ├── mapping/      ← workbook thiết kế .xlsx        (NGUỒN CODE MẶC ĐỊNH)
    ├── sql/          ← file .sql code Gold             (chỉ dùng khi chạy --from-sql)
    └── checklist/    ← file checklist OCB làm template (đã có sẵn, không cần thêm)
```

**Mặc định tool lấy code từ sheet `Script SQL` của workbook trong `input/mapping/`.** Sheet đó
phải ở dạng bảng, và dòng code Databricks phải ghi `Type = Code mới`:

```
 Type      | View / Table          | Script SQL
 Code cũ   | V_CDTK_DAILY_1        | CREATE VIEW [dbo].[V_CDTK_DAILY_1] AS ...   ← bỏ qua
 Code mới  | V_CDTK_DAILY_1 (Gold) | CREATE OR REPLACE VIEW ... AS ...           ← chấm dòng này
```

Ngoài ra tool đọc thêm 2 block trong workbook để đối chiếu:
- `FIELD MAPPING` → tiêu chí 1.1 (SQL đủ cột chưa)
- `JOIN SCHEMA` (kèm cột `NOTE`) → tiêu chí X.8, X.9

---

## 3. Chạy

```powershell
cd <thư mục vừa giải nén>
python gold_review\run_check.py --batch "Batch 2" --pic <tên bạn>
```

Dòng đầu console cho biết đang đọc nguồn nào:

```
Nguon SQL: sheet 'Script SQL' cua workbook (4 object)   [them --from-sql de cham file .sql trong input/sql]
```

Kết quả:

| File | Nội dung |
|---|---|
| `gold_review/output/Checklist_Review_AUTOFILLED.xlsx` | **file chính để xem và gửi OCB** |
| `gold_review/output/recon/<OBJ>_recon.sql` | cặp SQL đối chiếu số liệu, chạy tay khi UAT |

> **Đóng file Excel kết quả trước khi chạy lại**, không thì lỗi `PermissionError`.

---

## 4. Các lệnh hay dùng

```powershell
python gold_review\run_check.py                                  # chấm code trong workbook
python gold_review\run_check.py --from-sql                       # chấm file .sql trong input/sql
python gold_review\run_check.py --file input\sql\holiday.sql     # chấm 1 file
python gold_review\run_check.py --rule 2.4  --no-excel           # soi 1 tiêu chí, không xuất Excel
python gold_review\run_check.py --rule "2.*" --no-excel          # soi cả nhóm Logic
python gold_review\tests\test_rules.py                           # chỉ chạy self-test
```

| Exit code | Nghĩa |
|---|---|
| `0` | mọi object đạt |
| `1` | còn object "Không đạt" |
| `2` | không đọc được nguồn SQL nào |
| `3` | **self-test rule trượt → đừng tin kết quả**, sửa rule trước |
| `4` | thiếu thư viện |

---

## 5. Đọc kết quả

Sheet `Review theo bảng` — mỗi object 1 dòng từ dòng 4:

| Ô | Nghĩa |
|---|---|
| `Pass` trắng | đạt, hoặc tiêu chí không áp dụng cho object này |
| `Pass` + tên tiêu chí trong mục "CHƯA CÓ SỐ LIỆU" ở cột Ghi chú | chưa có số liệu để kết luận (có sau UAT test) — cập nhật lại ô sau khi có số |
| `Fail` | không đạt, hoặc có dấu hiệu nghi vấn cần giải trình |

Cột `AG` (Ghi chú) chỉ ghi các tiêu chí **Fail** và **chưa có số liệu**, mỗi cái gồm: tên tiêu chí →
lý do kèm số dòng code → cách sửa. Sheet `Auto-check chi tiết` có đầy đủ 30 tiêu chí × mọi object.

Công thức tỷ lệ lỗi và Kết luận là công thức gốc của OCB, tự tính khi mở Excel:
`tỷ lệ lỗi = 0.1×N1 + 0.8×N2 + 0.1×N3`, ngưỡng Batch 1 ≤ 30%, Batch 2/3 ≤ 20%.
**Chỉ cần 1 tiêu chí Nhóm 2 Fail là 80% → Không đạt.** Ưu tiên sửa Nhóm 2 trước.

---

## 6. Muốn biết từng tiêu chí chấm thế nào

Đọc [docs/RULES.md](docs/RULES.md) — mỗi tiêu chí có: máy đọc gì, luật kết luận, ví dụ FAIL, ví dụ
PASS, và dòng code thực thi. [docs/USAGE.md](docs/USAGE.md) mô tả input/output chi tiết hơn.

Thêm lỗi mới OCB trả về: thêm 1 regex vào `engine/known_issues.json`, lần sau tiêu chí 2.5 tự bắt.

Sửa rule thì **bắt buộc** chạy lại `tests/test_rules.py` — tool tự chạy self-test trước mỗi lần
chấm, trượt là trả exit code 3.
