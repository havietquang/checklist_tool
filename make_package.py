"""Dong goi tool thanh 1 file .zip de gui cho nguoi khac.

  python tools/gold_review/make_package.py                 # -> gold_review.zip o thu muc repo
  python tools/gold_review/make_package.py --out D:\\x.zip   # chi dinh duong dan
  python tools/gold_review/make_package.py --with-input     # kem ca input/sql + input/mapping dang co

Giai nen ra la co thu muc 'gold_review/', doc QUICKSTART.md la chay duoc ngay.

KHONG dong goi: __pycache__, ket qua trong output/, va (mac dinh) du lieu trong
input/sql + input/mapping vi do la code/thiet ke cua tung batch, khong phai cua tool.
Van GIU: input/checklist (template checklist) va tests/ (self-test chay truoc moi lan cham,
thieu la run_check.py bao loi import).
"""
from __future__ import annotations

import argparse
import os
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ARCNAME = "gold_review"

SKIP_DIRS = {"__pycache__", ".pytest_cache", ".ipynb_checkpoints"}
SKIP_EXT = (".pyc", ".pyo")
# Thu muc chua du lieu cua tung batch - mac dinh khong dong goi
DATA_DIRS = (os.path.join("input", "sql"), os.path.join("input", "mapping"))


def _keep(rel: str, with_input: bool) -> bool:
    parts = rel.replace("\\", "/").split("/")
    if any(p in SKIP_DIRS for p in parts):
        return False
    if rel.lower().endswith(SKIP_EXT) or os.path.basename(rel).startswith("~$"):
        return False
    if parts[0] == "output" and len(parts) > 1 and parts[1] != "README.md":
        return False                                  # ket qua lan chay truoc
    if not with_input and any(rel.replace("\\", "/").startswith(d.replace("\\", "/") + "/")
                              for d in DATA_DIRS):
        return False
    return True


def build(out_path: str, with_input: bool) -> tuple:
    files = []
    for dirpath, dirnames, filenames in os.walk(HERE):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, HERE)
            if full == os.path.abspath(out_path) or not _keep(rel, with_input):
                continue
            files.append((full, rel))

    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for full, rel in sorted(files, key=lambda x: x[1]):
            zf.write(full, os.path.join(ARCNAME, rel))
        # thu muc rong cho nguoi dung bo file vao
        for d in ("input/sql", "input/mapping", "output"):
            zf.writestr(f"{ARCNAME}/{d}/.keep", "")
    return len(files), os.path.getsize(out_path)


def main() -> int:
    ap = argparse.ArgumentParser(description="Dong goi tools/gold_review thanh 1 file zip")
    ap.add_argument("--out", default=os.path.join(ROOT, "gold_review.zip"))
    ap.add_argument("--with-input", action="store_true",
                    help="kem ca file .sql va workbook dang co trong input/")
    args = ap.parse_args()

    n, size = build(args.out, args.with_input)
    print(f"Da tao: {args.out}")
    print(f"  {n} file, {size / 1024:.0f} KB"
          f"{' (kem du lieu input)' if args.with_input else ' (khong kem du lieu input)'}")
    print("\nNguoi nhan lam 3 buoc:")
    print("  1. Giai nen -> duoc thu muc gold_review/")
    print("  2. python -m pip install -r gold_review/requirements.txt")
    print("  3. Bo workbook thiet ke vao gold_review/input/mapping/ roi chay:")
    print("     python gold_review/run_check.py --batch \"Batch 2\" --pic <ten>")
    print("\nChi tiet: gold_review/QUICKSTART.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
