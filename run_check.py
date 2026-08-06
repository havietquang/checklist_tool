"""SCRIPT TONG - cham file SQL Gold theo checklist Silver->Gold ZoneC OCB.

Duong dan CO DINH (khong can truyen tham so):
  INPUT   input/mapping/*.xlsx       workbook thiet ke - NGUON CODE MAC DINH
                                     (sheet 'Script SQL' dong Type='Code moi',
                                      cong block FIELD MAPPING + JOIN SCHEMA)
          input/sql/*.sql            file SQL Gold - chi dung khi chay --from-sql
          input/checklist/*.xlsx     file checklist dung lam template
  OUTPUT  output/Checklist_Review_AUTOFILLED.xlsx

  python tools/gold_review/run_check.py                                  # cham code trong workbook
  python tools/gold_review/run_check.py --from-sql                       # cham file .sql trong input/sql
  python tools/gold_review/run_check.py --file input/sql/holiday.sql     # cham 1 file (tu bat che do file)
  python tools/gold_review/run_check.py --rule 2.4                       # cham 1 tieu chi
  python tools/gold_review/run_check.py --dir <thu_muc> --mapping-dir <thu_muc> --out <thu_muc>

Yeu cau thu vien: sqlglot, openpyxl  ->  pip install -r tools/gold_review/requirements.txt

Exit code: 0 = tat ca dat | 1 = con object khong dat | 2 = khong tim thay file .sql
            | 3 = self-test rule truot | 4 = thieu thu vien.
"""
from __future__ import annotations

import argparse
import fnmatch
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ENGINE = os.path.join(HERE, "engine")

sys.path.insert(0, ENGINE)
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def require_deps() -> None:
    """Bao ro thieu thu vien nao va cach cai, thay vi de traceback ImportError."""
    missing = []
    for mod in ("sqlglot", "openpyxl"):
        try:
            __import__(mod)
        except ImportError:
            missing.append(mod)
    if not missing:
        return
    req = os.path.join(HERE, "requirements.txt")
    print(f"[!] Thieu thu vien: {', '.join(missing)}", file=sys.stderr)
    print(f"    Cai day du:  \"{sys.executable}\" -m pip install -r \"{req}\"", file=sys.stderr)
    print(f"    Hoac rieng:  \"{sys.executable}\" -m pip install {' '.join(missing)}", file=sys.stderr)
    sys.exit(4)


require_deps()

import mapping  # noqa: E402
import report  # noqa: E402
from core import (P_LEGACY, P_SCORED, P_SCRIPT, SRC_EXCEL, Ctx,  # noqa: E402
                  build_ctx, read_ctx, same_object)
from rules import (FAIL, G1, G2, G3, NA, PASS, RULES, WARN,  # noqa: E402
                   active_signatures, declared_upload)

# ---- Duong dan CO DINH: bo file vao input/, ket qua ra output/ ----
INPUT_DIR = os.path.join(HERE, "input")
DEFAULT_DIR = os.path.join(INPUT_DIR, "sql")            # file .sql can cham
DEFAULT_MAPPING_DIR = os.path.join(INPUT_DIR, "mapping")  # workbook thiet ke
CHECKLIST_DIR = os.path.join(INPUT_DIR, "checklist")     # file checklist lam template
DEFAULT_OUT = os.path.join(HERE, "output")

SKIP = ("*.bak*", "*_OLD_*", "*_CHECK_DATA*")
THRESHOLD = {"Batch 1": 0.30}
DEFAULT_THRESHOLD = 0.20


def default_template() -> str:
    """File checklist dung lam template: lay file .xlsx dau tien trong input/checklist."""
    found = sorted(glob.glob(os.path.join(CHECKLIST_DIR, "*.xlsx")))
    found = [f for f in found if not os.path.basename(f).startswith("~$")]
    return found[0] if found else os.path.join(
        ROOT, "Checklist_Review_Code_Silver_to_Gold_ZoneC_OCB.xlsx")


# ------------------------------------------------------------------ thu thap
def collect(dirs: list, files: list) -> list:
    paths = list(files)
    for d in dirs:
        paths += sorted(glob.glob(os.path.join(d, "*.sql")))
    out, seen = [], set()
    for p in paths:
        ap = os.path.abspath(p)
        if ap in seen or any(fnmatch.fnmatch(os.path.basename(p), s) for s in SKIP):
            continue
        seen.add(ap)
        out.append(p)
    return out


def collect_from_excel(mapping_dirs: list) -> list:
    """Lay SQL thang tu sheet 'Script SQL' cua workbook thiet ke, khong dung input/sql.

    Moi dong 'Code moi' trong sheet do -> 1 Ctx. Dung khi workbook da chua san code that,
    khoi phai dong bo 2 noi. Duong dan hien thi dang '<workbook> [Script SQL: <OBJ>]'."""
    dirs = [d for d in mapping_dirs if os.path.isdir(d)]
    items, conflicts = [], []
    for key, (path, sheet, sql) in sorted(mapping.discover_scripts(dirs, conflicts).items()):
        label = f"{os.path.basename(path)} [{sheet}: {key}]"
        # target_hint tach tu TEN FILE workbook (khong phai 'label' o tren, label co dinh
        # them '[Sheet: key]' lam sai lech). Vd '088. OCB_GOLD_TTDL_TBL_BPM_QLNS_LINH.xlsx'
        # -> 'TBL_BPM_QLNS', khop dung ten object trong mapping.discover(), khong dinh PIC.
        hint = mapping.object_from_filename(path)
        ctx = build_ctx(label, sql, source_kind=SRC_EXCEL, target_hint=hint)
        # PIC lay theo TUNG object tu doan cuoi ten workbook (moi object do 1 nguoi lam),
        # thay vi 1 gia tri chung ca batch. --pic tren dong lenh se ghi de gia tri nay.
        ctx.pic = mapping.pic_from_filename(path)
        ctx.stt = mapping.stt_from_filename(path)
        # SQL loi cu phap / khong co CREATE -> build_ctx khong suy duoc ten object, cot
        # ten se hien nguyen ten file rat kho doc. Lay ten khai o cot View/Table lam ten
        # hien thi (van giu profile de evaluate() biet la khong phan tich duoc).
        if not ctx.target:
            ctx.target = mapping.clean_key(key) or hint
        items.append((ctx, path, key))
    _report_script_conflicts(conflicts)
    if mapping.SKIPPED_FILES:
        print(f"\n[!] {len(mapping.SKIPPED_FILES)} workbook KHONG lay duoc code nao"
              " -> object trong do KHONG duoc cham:")
        for base, why in mapping.SKIPPED_FILES:
            print(f"  - {base:<46} {why}")
    out = _dedupe_by_target(_only_owner_objects(items))
    # Sap xep theo STT cua workbook thiet ke (khop dung thu tu OCB da danh san), khong
    # con lai o cuoi giu nguyen thu tu phat hien duoc (sort on tinh, khong xao thu tu goc).
    out.sort(key=lambda c: (c.stt is None, c.stt if c.stt is not None else 0))
    return out


def _only_owner_objects(items: list) -> list:
    """Moi workbook DA DANH SO chi sinh DUNG 1 dong: object mang ten cua chinh file do.

    Checklist gui OCB liet ke theo danh sach object da danh so (64 file = 64 dong). Nhieu
    workbook khai kem trong sheet Script ca SQL cua bang nguon/bang dung chung (vd
    '010. V_FTP_003' khai them FTP_PARAM, FTP_ACCRUAL...) - do la tai lieu tham khao, neu
    tinh thanh dong rieng thi so dong phong len va lech voi danh sach da danh so. Bang nao
    can dong rieng thi phai co workbook danh so cua chinh no."""
    keep, extra = [], []
    for ctx, path, key in items:
        name = ctx.target.split(".")[-1] if ctx.target else key
        (keep if mapping.owns(path, name) or mapping.owns(path, key) else extra).append(
            (ctx, path, key))
    if extra:
        print(f"\n[i] {len(extra)} object khai KEM trong workbook cua object khac -> khong"
              " tinh thanh dong rieng (chi bang co workbook danh so moi co dong):")
        for ctx, path, key in extra:
            print(f"  - {key:<28} khai trong {os.path.basename(path)}")
    return keep


def _dedupe_by_target(items: list) -> list:
    """Gop cac Ctx cung tao ra MOT object Gold thanh 1 dong.

    _report_script_conflicts() chi gop duoc khi ten khai o cot 'View/Table' GIONG NHAU.
    Go sai chinh ta la ra 2 khoa khac nhau (vd 'BRACH_LIST' thieu chu N so voi
    'BRANCH_LIST') -> cung bang BRANCH_LIST bi cham 2 lan, ra 2 dong trong file gui OCB.
    O day gop theo TEN OBJECT THAT lay tu cau CREATE/INSERT nen khong phu thuoc chu go
    trong sheet; giu ban o workbook CHINH CHU."""
    groups: dict[str, list] = {}
    for i, (ctx, path, key) in enumerate(items):
        name = ctx.target.split(".")[-1].upper() if ctx.target else f"<khong ro #{i}>"
        groups.setdefault(name, []).append((ctx, path, key))

    out, dups = [], []
    for name, grp in groups.items():
        if len(grp) == 1:
            out.append(grp[0][0])
            continue
        owned = [g for g in grp if mapping.owns(g[1], name)]
        pick = (owned or grp)[0]
        out.append(pick[0])
        dups.append((name, pick, [g for g in grp if g is not pick]))

    if dups:
        print(f"\n[!] {len(dups)} object bi khai TRUNG duoi TEN KHAC NHAU (go sai chinh ta"
              " o cot View/Table) - da gop theo ten trong cau CREATE, chi cham 1 lan:")
        for name, pick, others in dups:
            print(f"  - {name:<24} cham ban khai '{pick[2]}' trong {os.path.basename(pick[1])}")
            for ctx, path, key in others:
                print(f"{'':>28}bo ban khai '{key}' trong {os.path.basename(path)}"
                      f"{'   <-- ten khai SAI CHINH TA, sua lai trong workbook' if key != name else ''}")
    return sorted(out, key=lambda c: c.short)


def _report_script_conflicts(conflicts: list) -> None:
    """Bao ro object nao bi khai SQL o nhieu workbook va tool dang cham ban nao.

    Bang dung chung hay bi dan lai SQL vao sheet Script cua nhieu workbook tieu thu;
    im lang chon 1 ban la nguy hiem khi cac ban da LECH NOI DUNG - luc do co the dang
    cham ban khong phai ban chuan."""
    if not conflicts:
        return
    differs = [c for c in conflicts if c["differs"]]
    print(f"\n[i] {len(conflicts)} object duoc khai SQL o nhieu workbook"
          f"{f' - trong do {len(differs)} object CO CAC BAN LECH NOI DUNG' if differs else ''}."
          "  Uu tien ban trong workbook CHINH CHU (ten file mang dung ten object).")
    for c in sorted(conflicts, key=lambda x: (not x["differs"], x["object"])):
        mark = "[!] LECH NOI DUNG" if c["differs"] else "    trung nhau"
        owner = "" if c["owned"] else "  (KHONG co workbook chinh chu -> lay theo alphabet)"
        print(f"  {mark}  {c['object']:<26} cham ban trong: {os.path.basename(c['chosen'])}{owner}")
        for p in c["others"]:
            print(f"{'':>21}bo qua ban trong: {os.path.basename(p)}")
    if differs:
        print("    -> Moi object chi nen co SQL o DUNG 1 workbook (workbook mang ten no);"
              " o workbook tieu thu chi khai ten bang o block JOIN SCHEMA, khong dan lai code.")


def attach_mapping(ctxs: list, mapping_dirs: list) -> None:
    """Ghep moi file SQL voi workbook mapping thiet ke theo ten object."""
    dirs = [d for d in mapping_dirs if os.path.isdir(d)]
    docs = mapping.discover(dirs) if dirs else {}
    for ctx in ctxs:
        # ctx.target la ten object THAT (tu CREATE/INSERT hoac hint) -> dung clean_key,
        # KHONG dung norm_key (se cat nham hau to that nhu '_NEW' trong 'V_CUST_STATUS_NEW',
        # gay dam khoa voi object khac ten 'V_CUST_STATUS'). ctx.path la fallback tu ten
        # file/label ghep, co the con dinh rac (PIC, hau to file) nen van dung norm_key.
        for key in (mapping.clean_key(ctx.target.split(".")[-1]) if ctx.target else "",
                    mapping.norm_key(ctx.path)):
            if key and key in docs:
                ctx.mapping = docs[key]
                break


def build_repo(ctxs: list, gold_list_path: str | None) -> dict:
    repo = {"sigs": set(), "cdc": set(), "known_issues": {}, "known_models": None,
            "known_sat_columns": {}, "uncertain_sat_tables": set(), "gold_list": None}
    ki = os.path.join(ENGINE, "known_issues.json")
    if os.path.exists(ki):
        with open(ki, encoding="utf-8") as fh:
            repo["known_issues"] = json.load(fh)
    km = os.path.join(ENGINE, "known_models.json")
    if os.path.exists(km):
        with open(km, encoding="utf-8") as fh:
            repo["known_models"] = set(json.load(fh)["models"])
    ksc = os.path.join(ENGINE, "known_sat_columns.json")
    if os.path.exists(ksc):
        with open(ksc, encoding="utf-8") as fh:
            data = json.load(fh)
            repo["known_sat_columns"] = {k: set(v) for k, v in data["columns"].items()}
            repo["uncertain_sat_tables"] = set(data["uncertain_tables"])
    for ctx in ctxs:
        s = active_signatures(ctx)
        repo["sigs"] |= s["sigs"]
        repo["cdc"] |= s["cdc"]
    if gold_list_path:
        repo["gold_list"] = _read_gold_list(gold_list_path)
    repo["silver_chain"] = _silver_chain(ctxs)
    # Object co mat trong luot chay nay - dung de X.9 phan biet 'khong truy duoc ve Silver'
    # voi 'chua cham object do trong luot nay nen chua biet'.
    repo["batch_objects"] = {c.target.split(".")[-1].lower() for c in ctxs if c.target}
    return repo


def _silver_chain(ctxs: list) -> dict:
    """{ten_bang_gold: True} cho cac object trong batch truy duoc ve Silver.

    Doc truc tiep raw_vault/business_vault -> True. Doc bang Gold khac da True -> True.
    Object ma MOI nguon deu la bang upload/thu cong DA KHAI o cot NOTE cua JOIN SCHEMA
    cung -> True, de ca chuoi phia sau no khong bi bao loi lay (vd. tb_cdkt_daily_dtl la
    bang upload -> v_cdtk_daily_1 dat -> v_cdtk_daily doc v_cdtk_daily_1 cung dat).
    Lap lai cho den khi khong co gi moi (xu ly chuoi nhieu tang:
    v_cdtk_daily -> holiday -> calendar)."""
    reads, upload, chain = {}, {}, {}
    for ctx in ctxs:
        if not ctx.target:
            continue
        name = ctx.target.split(".")[-1].lower()
        reads[name] = [t.split(".")[-1].lower() for t in ctx.tables
                       if not same_object(t, ctx.target)]
        upload[name] = declared_upload(ctx)
        if ctx.silver_tables:
            chain[name] = True

    for _ in range(len(reads) + 1):          # lan truyen, tranh vong lap vo han
        grown = False
        for name, srcs in reads.items():
            if name in chain or not srcs:
                continue
            ok = [s for s in srcs if chain.get(s) or s in upload.get(name, ())]
            if any(chain.get(s) for s in srcs) or len(ok) == len(srcs):
                chain[name] = True
                grown = True
        if not grown:
            break
    return chain


def _read_gold_list(path: str) -> set:
    import openpyxl
    wb = openpyxl.load_workbook(path, data_only=True, read_only=True)
    names = set()
    for ws in wb.worksheets:
        for row in ws.iter_rows(values_only=True):
            for v in row:
                if isinstance(v, str) and 3 < len(v) < 60:
                    names.add(v.strip().split(".")[-1].upper())
    return names


# ------------------------------------------------------------------ tam hoan cham
# Object CHUA THE cham vi ly do ngoai code (chua co schema/moi truong de deploy, chua co
# bang nguon...). Moi tieu chi -> WARN: Excel ghi 'WARN' (vang nhat) kem ly do,
# nen ra Dat ma khong khai gian la "da kiem chung". XOA khoi dict nay ngay khi cham duoc.
# Khoa = ten object (khong catalog/schema), khong phan biet chu hoa/thuong.
# CANH BAO: dua object vao day la BO QUA TOAN BO 20 tieu chi cua no -> se giau luon ca
# loi code that. Ca 20 tieu chi deu la phan tich TINH tren text SQL (khong can bang/schema
# ton tai de cham), nen gan nhu KHONG BAO GIO can hoan. Chi dung khi that su khong doc
# duoc code (vd chua co script), va phai co ly do ro rang. Van ban ly do di thang vao file
# gui OCB -> viet tieng Viet co dau, ngan gon.
DEFERRED: dict[str, str] = {}


def deferred_reason(ctx: Ctx) -> str | None:
    """Ly do tam hoan cham object nay, None neu cham binh thuong."""
    if not ctx.target:
        return None
    return DEFERRED.get(ctx.target.split(".")[-1].upper())


def cannot_check(ctx: Ctx) -> str | None:
    """Ly do KHONG the phan tich code cua object nay, None neu cham binh thuong.

    Hai truong hop: SQL loi cu phap (sqlglot khong parse duoc) va SQL khong co cau
    CREATE/INSERT nao nen khong xac dinh duoc object Gold. Ca hai deu la loi that phai
    sua, khong phai ly do de bo object ra khoi checklist."""
    if ctx.profile == P_LEGACY:
        return None                       # code cu on-prem, khong thuoc pham vi cham
    if ctx.parse_error:
        return f"SQL lỗi cú pháp, không phân tích được: {ctx.parse_error}"
    if ctx.profile == P_SCRIPT:
        return ("SQL không có câu CREATE/INSERT nào nên không xác định được object Gold"
                " tạo ra — bổ sung câu tạo bảng/view rồi chấm lại")
    return None


# ------------------------------------------------------------------ cham diem
def evaluate(ctx: Ctx, repo: dict, only: str | None) -> dict:
    out = {}
    defer = deferred_reason(ctx)
    blocked = cannot_check(ctx)
    for rid, rule in RULES.items():
        if only and not fnmatch.fnmatch(rid, only):
            continue
        if blocked:                       # khong doc duoc code -> khong ket luan Dat duoc
            out[rid] = _err(blocked) if not report.in_checklist(rid) else _fail(blocked)
            continue
        if rule.profiles and ctx.profile not in rule.profiles:
            out[rid] = _na(f"khong ap dung cho profile {ctx.profile}")
            continue
        if defer:                       # giu N-A o tren de note khong bi dai vo ich
            out[rid] = _defer(f"tạm hoãn chấm — {defer}")
            continue
        try:
            out[rid] = rule.fn(ctx, repo)
        except Exception as exc:  # noqa: BLE001
            out[rid] = _err(f"loi rule: {type(exc).__name__}: {exc}")
    return out


def _defer(msg):
    from rules import Finding
    return Finding(WARN, [msg])


def _fail(msg):
    from rules import Finding
    return Finding(FAIL, [msg])


def _na(msg):
    from rules import Finding
    return Finding(NA, [msg])


def _err(msg):
    from rules import Finding
    return Finding(WARN, [msg])


def selftest() -> int:
    """Kiem chung rule tren fixture co tinh sai/dung truoc khi cham code that.
    Cham bang rule chua duoc kiem chung thi ket qua vo nghia. Tra ve so assertion truot."""
    import os.path
    sys.path.insert(0, os.path.join(HERE, "tests"))
    from test_rules import EXPECT, FIX  # noqa: PLC0415

    ctxs = {os.path.basename(p): read_ctx(os.path.join(FIX, p))
            for p in sorted(os.listdir(FIX)) if p.endswith(".sql")}
    attach_mapping(list(ctxs.values()), [os.path.join(FIX, "mapping")])
    repo = build_repo(list(ctxs.values()), None)
    miss, total = [], 0
    for fname, expect in EXPECT.items():
        findings = evaluate(ctxs[fname], repo, None)
        for rid, want in expect.items():
            total += 1
            got = findings[rid].status
            if got != want:
                miss.append(f"{fname} {rid}: mong doi {want}, nhan {got}")
    if miss:
        print(f"[!] SELF-TEST TRUOT {len(miss)}/{total} - RULE DANG SAI, ket qua cham ben duoi khong dang tin:")
        for m in miss:
            print(f"    - {m}")
    else:
        print(f"self-test rule: {total}/{total} dat")
    return len(miss)


def score(findings: dict) -> dict:
    """Cham diem DUNG nhu gia tri ghi vao Excel (report.CELL):
    chi FAIL -> 'Fail' (tinh loi); WARN -> 'WARN'; PASS / N-A -> 'Pass'.
    WARN la canh bao toi uu, KHONG tinh loi (xem giai thich o report.CELL).
    Neu doi quy doi o report.CELL thi phai doi o day cho khop."""
    grp = {G1: 0, G2: 0, G3: 0}
    for rid, f in findings.items():
        if rid.startswith("X."):          # nhom X khong co cot tren sheet OCB
            continue
        if f.status == FAIL:
            grp[RULES[rid].group] = 1
    ratio = 0.1 * grp[G1] + 0.8 * grp[G2] + 0.1 * grp[G3]
    warned = [rid for rid, f in findings.items() if f.status == WARN]
    return {"n1": grp[G1], "n2": grp[G2], "n3": grp[G3], "ratio": ratio, "warn": warned}


# ------------------------------------------------------------------ in ket qua
def print_file(ctx: Ctx, findings: dict, sc: dict, thr: float) -> None:
    verdict = "DAT" if sc["ratio"] <= thr else "KHONG DAT"
    src = "" if ctx.target_source == "AST" else f"  (target suy tu {ctx.target_source})"
    print(f"\n{'=' * 100}\n{ctx.short}   [{ctx.profile}]{src}   {ctx.path}")
    print(f"  ty le loi = {sc['ratio']:.0%}  (N1={sc['n1']} N2={sc['n2']} N3={sc['n3']})   nguong {thr:.0%}"
          f"   -> {verdict}   | canh bao: {len(sc['warn'])}")
    for rid in sorted(findings, key=lambda r: (r.split(".")[0], int(r.split(".")[1]))):
        f = findings[rid]
        if f.status == NA:
            continue
        # icon phan anh dung gia tri se ghi vao Excel (chi FAIL moi la 'Fail')
        icon = {FAIL: "FAIL  ", WARN: "warn  ", PASS: "pass  "}[f.status]
        # nhom X khong co trong checklist OCB -> khong ghi vao file gui OCB, chi hien
        # o day cho doi DE tu xem (danh dau [noi bo] de khoi nham la tieu chi OCB).
        tag = "" if report.in_checklist(rid) else "  [noi bo, khong gui OCB]"
        print(f"    {icon} {rid:<5} {RULES[rid].title}{tag}")
        if f.status != PASS:
            for e in f.evidence:
                print(f"             - {e}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Check code Silver->Gold theo checklist ZoneC OCB")
    ap.add_argument("--dir", action="append", default=[], help=f"thu muc SQL (mac dinh {DEFAULT_DIR})")
    ap.add_argument("--file", action="append", default=[], help="file SQL cu the (lap lai duoc)")
    ap.add_argument("--rule", help="chay rieng 1 tieu chi hoac nhom, vd 2.4 hoac '2.*'")
    ap.add_argument("--batch", default="Batch 2")
    ap.add_argument("--pic", default="")
    ap.add_argument("--template", default=default_template())
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--gold-list", help="xlsx chua danh sach bang Gold da duyet (tieu chi 1.2)")
    ap.add_argument("--mapping-dir", action="append", default=[],
                    help=f"thu muc chua workbook mapping thiet ke (mac dinh {DEFAULT_MAPPING_DIR})")
    ap.add_argument("--from-sql", action="store_true",
                    help=f"lay SQL tu file .sql trong {DEFAULT_DIR} thay vi sheet 'Script SQL'")
    ap.add_argument("--from-excel", action="store_true",
                    help="(mac dinh) lay SQL tu sheet 'Script SQL' cua workbook")
    ap.add_argument("--no-excel", action="store_true")
    ap.add_argument("--skip-selftest", action="store_true", help="bo qua buoc kiem chung rule")
    args = ap.parse_args()

    broken = 0 if args.skip_selftest else selftest()

    mapping_dirs = args.mapping_dir or [DEFAULT_MAPPING_DIR]
    # Mac dinh doc code tu sheet 'Script SQL' cua workbook thiet ke.
    # --dir / --file la yeu cau cham file cu the -> tu chuyen sang doc file.
    use_files = args.from_sql or bool(args.dir) or bool(args.file)
    if not use_files:
        ctxs = collect_from_excel(mapping_dirs)
        if not ctxs:
            print("Khong doc duoc script nao tu sheet 'Script SQL' cua workbook trong"
                  f" {mapping_dirs}.\n"
                  "    Sheet phai co cot Type | View / Table | Script SQL,"
                  " dong code Databricks ghi Type = 'Code moi'.\n"
                  "    Muon cham file .sql trong input/sql thi chay lai voi --from-sql")
            return 2
        print(f"Nguon SQL: sheet 'Script SQL' cua workbook ({len(ctxs)} object)"
              "   [them --from-sql de cham file .sql trong input/sql]")
    else:
        dirs = args.dir or ([] if args.file else [DEFAULT_DIR])
        paths = collect(dirs, args.file)
        if not paths:
            print("Khong tim thay file .sql nao")
            return 2
        ctxs = [read_ctx(p) for p in paths]
        where = args.dir or ([os.path.dirname(f) for f in args.file] if args.file else [DEFAULT_DIR])
        print(f"Nguon SQL: file .sql trong {where} ({len(ctxs)} file)")

    attach_mapping(ctxs, mapping_dirs)
    # Object khong phan tich duoc code (loi cu phap / khong co CREATE) VAN phai co dong
    # trong checklist - moi workbook da danh so la 1 dong. Bo ra ngoai thi so dong hut di
    # ma nguoi doc tuong object do khong ton tai. evaluate() se cham chung la Fail toan bo
    # kem ly do (khong kiem chung duoc gi thi khong the ket luan Dat).
    scored = [c for c in ctxs if c.profile in P_SCORED or cannot_check(c)]
    skipped = [c for c in ctxs if c not in scored]
    repo = build_repo(scored, args.gold_list)

    thr = THRESHOLD.get(args.batch, DEFAULT_THRESHOLD)
    results, rows = [], []
    for ctx in scored:
        findings = evaluate(ctx, repo, args.rule)
        sc = score(findings)
        print_file(ctx, findings, sc, thr)
        results.append((ctx, findings))
        rows.append((ctx, sc))

    print(f"\n{'=' * 100}\nTONG HOP {args.batch} (nguong loi <= {thr:.0%})")
    print("Quy doi khi ghi Excel:  FAIL -> 'Fail'   |   pass / warn(canh bao, o to vang nhat)"
          " / pass?(chua co so lieu) -> 'Pass'\n")
    print(f"{'Object':<36}{'PIC':<10}{'Profile':<17}{'Ty le':>7}{'Ket luan':>12}{'Canh bao':>10}")
    ndat = 0
    for ctx, sc in rows:
        ok = sc["ratio"] <= thr
        ndat += ok
        note = "  <- TAM HOAN CHAM" if deferred_reason(ctx) else ""
        print(f"{ctx.short[:35]:<36}{(args.pic or ctx.pic)[:9]:<10}{ctx.profile:<17}"
              f"{sc['ratio']:>6.0%}{'DAT' if ok else 'KHONG DAT':>12}{len(sc['warn']):>10}{note}")
    print(f"\n{ndat}/{len(rows)} bang DAT; "
          f"{sum(len(s['warn']) for _, s in rows)} CANH BAO"
          " (khong tinh loi, o ghi 'WARN' to vang nhat - soi lai khi can toi uu)")

    held = [c for c, _ in rows if deferred_reason(c)]
    if held:
        print(f"\n[!] {len(held)} object TAM HOAN CHAM - dang ghi 'Pass' nhung"
              " CHUA duoc kiem chung, phai cham lai truoc khi gui OCB:")
        for c in held:
            print(f"  - {c.short:<34} {deferred_reason(c)}")
        print("    (bo hoan: xoa object khoi dict DEFERRED trong run_check.py roi chay lai)")
    print(f"pattern active toan batch: {sorted(repo['sigs']) or ['<khong co>']}"
          f" | huong loc cdc_status: {sorted(repo['cdc']) or ['<khong co>']}")
    if skipped:
        print("\nBo qua (khong phai object Gold can cham):")
        for c in skipped:
            why = c.parse_error or ("code cu on-prem" if c.profile == P_LEGACY else "khong tao object Gold")
            print(f"  - {os.path.basename(c.path):<44} {c.profile:<14} {why}")

    if not args.no_excel:
        os.makedirs(args.out, exist_ok=True)
        xlsx = os.path.join(args.out, "Checklist_Review_AUTOFILLED.xlsx")
        xlsx = report.write(results, args.template, xlsx, args.batch, args.pic)
        print(f"\nExcel: {xlsx}")

    if broken:
        print(f"\n[!] CANH BAO: {broken} assertion self-test truot - sua rule roi cham lai truoc khi gui OCB")
        return 3
    return 1 if ndat < len(rows) else 0


if __name__ == "__main__":
    sys.exit(main())
