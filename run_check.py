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

DOI CHIEU DONG BO - cung 1 object ma code duoc dan o nhieu workbook thi workbook nao dang giu
ban cu. Luot cham BINH THUONG da in canh bao nay (dau + cuoi output); 2 lenh duoi de xem chi
tiet, khong cham checklist:
  python tools/gold_review/run_check.py --sync-object T24_CRB    # diff day du cua 1 object
  python tools/gold_review/run_check.py --sync-report            # ca bang + output/Sync_Report.xlsx
Mac dinh chi so GIUA CAC WORKBOOK; them --src-dir src/tckh de so ca voi code deploy.

Yeu cau thu vien: sqlglot, openpyxl  ->  pip install -r tools/gold_review/requirements.txt

Exit code: 0 = tat ca dat | 1 = con object khong dat | 2 = khong tim thay file .sql
            | 3 = self-test rule truot | 4 = thieu thu vien.
            --sync-report: 0 = da dong bo het | 1 = con object lech | 2 = khong doc duoc gi.
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
import sync  # noqa: E402
from core import (P_LEGACY, P_SCORED, P_SCRIPT, SRC_EXCEL, Ctx,  # noqa: E402
                  build_ctx, read_ctx, same_object)
from rules import (BLOCKING, FAIL, G1, G2, G3, NA, PASS, RULES, WARN,  # noqa: E402
                   active_signatures, declared_upload)

# ---- Duong dan CO DINH: bo file vao input/, ket qua ra output/ ----
INPUT_DIR = os.path.join(HERE, "input")
DEFAULT_DIR = os.path.join(INPUT_DIR, "sql")            # file .sql can cham
DEFAULT_MAPPING_DIR = os.path.join(INPUT_DIR, "mapping")  # workbook thiet ke
CHECKLIST_DIR = os.path.join(INPUT_DIR, "checklist")     # file checklist lam template
DEFAULT_OUT = os.path.join(HERE, "output")
# Code THAT dang deploy - dung lam ban doi chieu thu 2 cho --sync-report.
DEFAULT_SRC_DIR = os.path.join(ROOT, "src", "tckh")

SKIP = ("*.bak*", "*_OLD_*", "*_CHECK_DATA*")
# Ket qua doi chieu dong bo cua luot cham hien tai (sync.ObjSync). Dat o module de in nhac
# lai o CUOI output: canh bao in luc doc workbook nam tan dau output, da bi cuon mat khi
# nguoi doc xem den bang tong hop.
SYNC_RESULTS: list = []
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
    items, variants = [], {}
    for key, (path, sheet, sql) in sorted(
            mapping.discover_scripts(dirs, None, variants).items()):
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
    _report_script_conflicts(variants)
    if mapping.SKIPPED_FILES:
        print(f"\n[!] {len(mapping.SKIPPED_FILES)} workbook KHONG lay duoc code nao"
              " -> object trong do KHONG duoc cham:")
        for base, why in mapping.SKIPPED_FILES:
            print(f"  - {base:<46} {why}")
    if mapping.SQL_REF_ISSUES:
        print(f"\n[!] {len(mapping.SQL_REF_ISSUES)} o Script SQL ghi duong dan file .sql"
              " nhung KHONG TIM THAY file do -> object do KHONG duoc cham:")
        for base, why in mapping.SQL_REF_ISSUES:
            print(f"  - {base:<46} {why}")
    if mapping.DROPPED_CELLS:
        print(f"\n[!] {len(mapping.DROPPED_CELLS)} o Script SQL bi BO QUA (khong chua than SQL"
              " nao). Neu do la code bi CAT DOAN thi phai de TRONG cot View/Table o cac dong"
              " sau de tool noi lai:")
        for base, why in mapping.DROPPED_CELLS:
            print(f"  - {base:<46} {why}")
    out = _dedupe_by_target(_only_owner_objects(items))
    _warn_workbooks_without_row(dirs, out, variants)
    # Sap xep theo STT cua workbook thiet ke (khop dung thu tu OCB da danh san), khong
    # con lai o cuoi giu nguyen thu tu phat hien duoc (sort on tinh, khong xao thu tu goc).
    out.sort(key=lambda c: (c.stt is None, c.stt if c.stt is not None else 0))
    return out


def _warn_workbooks_without_row(dirs: list, kept: list, variants: dict) -> None:
    """Workbook DA DANH SO ma khong sinh duoc dong nao trong checklist -> phai bao.

    Checklist gui OCB liet ke theo danh sach workbook da danh so, moi file 1 dong. File
    nao khong ra dong nao la MAT BANG khoi ket qua, ma truoc day khong co canh bao nao:
    tong so chi hut di 1 (95 thay vi 96) nen rat de bo qua.

    Nguyen nhan hay gap nhat la GO SAI TEN OBJECT o cot 'View/Table' (vd '045.
    ..._TB_AR_BCN_DTL_QUANG.xlsx' khai 'TB_AR_BCN_DLT' - dao 2 chu cai): key khong khop
    ten file nen workbook khong duoc coi la chinh chu, ban trong no bi loai theo. Nen in
    kem ten object doc duoc tu chinh workbook do de nhin ra ngay cho go sai."""
    import glob as _glob
    # ctx.path o che do doc workbook la LABEL '<ten file>.xlsx [<sheet>: <OBJ>]' - chi co
    # TEN FILE, khong phai duong dan day du -> so theo basename, khong abspath.
    have = {os.path.basename(c.path.split(" [")[0]) for c in kept}
    keys_of: dict[str, list] = {}
    for key, cands in variants.items():
        for p, _sheet, _sql in cands:
            keys_of.setdefault(os.path.basename(p), []).append(key)

    missing = []
    for d in dirs:
        for p in sorted(_glob.glob(os.path.join(d, "*.xlsx"))):
            base = os.path.basename(p)
            if base.startswith("~$") or "Checklist_Review" in base:
                continue
            if base not in have:
                missing.append((base, keys_of.get(base, [])))
    if not missing:
        return
    print(f"\n[!] {len(missing)} workbook da danh so KHONG sinh duoc dong nao trong checklist"
          " -> bang trong do BI MAT khoi ket qua:")
    for base, keys in missing:
        want = mapping.object_from_filename(base)
        print(f"  - {base}")
        print(f"      ten object theo TEN FILE   : {want}")
        print(f"      ten khai o cot View/Table  : {', '.join(keys) or '<khong doc duoc dong nao>'}")
        near = [k for k in keys if k != want and sorted(k) == sorted(want)]
        if near:
            print(f"      -> GO SAI CHINH TA: '{near[0]}' dao chu so voi '{want}',"
                  " sua lai trong workbook cho khop ten file")


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


def _report_script_conflicts(variants: dict) -> None:
    """Bao ro object nao bi khai SQL o nhieu workbook va noi nao dang giu ban CU.

    Bang dung chung hay bi dan lai SQL vao sheet Script cua nhieu workbook tieu thu; im
    lang chon 1 ban la nguy hiem khi cac ban da LECH - luc do co the dang cham ban khong
    phai ban chuan. Dung sync.analyse() de tach LECH THAT (khac logic) voi chi khac
    FORMAT/COMMENT: truoc day so chuoi tho nen 1 dau ';' hay 1 dong comment le cung bi bao
    'LECH NOI DUNG', lan trong danh sach dai khong ai doc nua.

    `SYNC_RESULTS` giu lai ket qua de in nhac lai o cuoi luot cham (dau output bi cuon mat)."""
    places = {key: [sync.Place(p, sheet, sql) for p, sheet, sql in cands]
              for key, cands in variants.items()}
    results = sync.analyse(places)
    SYNC_RESULTS[:] = results
    if not results:
        return
    lech = [r for r in results if r.status == "LECH"]
    unknown = [r for r in results if r.status == "KHONG RO BAN CHUAN"]
    fmt = [r for r in results if r.status == "khac format"]
    print(f"\n[i] {len(results)} object duoc khai SQL o nhieu workbook: {len(lech)} LECH"
          f" | {len(unknown)} khong ro ban chuan | {len(fmt)} chi khac format | "
          f"{len(results) - len(lech) - len(unknown) - len(fmt)} trung khop."
          "  Cham ban trong workbook CHINH CHU (ten file mang dung ten object).")
    for r in lech + unknown:
        if r.canon:
            print(f"  [!] LECH  {r.object:<26} cham ban trong: {os.path.basename(r.canon.path)}")
            for p in r.stale:
                cut = "  <-- O EXCEL BI CAT CUT" if p.truncated else ""
                print(f"{'':>12}ban CU o: {p.label}   ({p.nchars} ky tu){cut}")
        else:
            print(f"  [?] KHONG RO BAN CHUAN  {r.object:<20} "
                  f"{len({sync.fingerprint(p.sql) for p in r.others})} phien ban khac nhau"
                  " (khong workbook nao mang dung ten object)")
            for p in r.others:
                print(f"{'':>12}{sync.fingerprint(p.sql)}  {p.nchars:>7} ky tu  {p.label}")
    if lech or unknown:
        print("    -> Xem diff:  --sync-object <TEN_OBJECT>   |  ca bang:  --sync-report")
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
            "known_sat_columns": {}, "uncertain_sat_tables": set(), "gold_list": None,
            "cancelled_models": set(), "renamed_models": {},
            "multiactive_sats": set(), "sum_money_cols": {}, "pit_filtered": {}}
    ki = os.path.join(ENGINE, "known_issues.json")
    if os.path.exists(ki):
        with open(ki, encoding="utf-8") as fh:
            repo["known_issues"] = json.load(fh)
    km = os.path.join(ENGINE, "known_models.json")
    if os.path.exists(km):
        with open(km, encoding="utf-8") as fh:
            data = json.load(fh)
        # 2 nguon, gop lam mot de X.10 doi chieu:
        #   "models"                 - trich tu zip dbt (anh chup 1 thoi diem, de cu);
        #   "models_tai_lieu_mapping"- bang Zone C da mapping/dev nhung chua vao zip do
        #                              (vd nhom accountbc_save nguon SBV).
        # Thieu nguon thu 2 thi X.10 bao "KHONG TON TAI trong Data Vault model" oan.
        # Sinh lai: python tools/gold_review/update_known_models.py <file mapping silver>
        repo["known_models"] = set(data["models"]) | set(data.get("models_tai_lieu_mapping", []))
        # "models_cancel" - bang bi danh Cancel o tai lieu mapping (Mapping Status HOAC Dev
        # Status). Van co the con file model trong zip dbt nen X.10 phai check RIENG, khong
        # suy ra tu "khong ton tai". Tru cac bang OCB da xac nhan van dung.
        repo["cancelled_models"] = ({t.lower() for t in data.get("models_cancel", [])}
                                    - {t.lower() for t in data.get("models_cancel_mien_tru", [])})
        # "models_doi_ten" - bang da doi ten / tach bang o tai lieu mapping. File model TEN CU
        # van con trong zip dbt nen script chay khong loi, khong rule nao bat duoc ngoai day.
        repo["renamed_models"] = {k.lower(): v for k, v in data.get("models_doi_ten", {}).items()}
        # Satellite MULTIACTIVE (unique_key co ma_key): 1 hashkey nhieu dong trong CUNG 1 ngay
        # -> GROUP BY phai kem ma_key (X.12), va max_by o day KHONG thua (X.13 bo qua).
        repo["multiactive_sats"] = {t.lower() for t in data.get("sat_multiactive", [])}
        repo["sum_money_cols"] = {k.lower(): [c.lower() for c in v]
                                  for k, v in data.get("sat_cot_tien_phai_sum", {}).items()}
        # PIT co khai sts_hub_table -> da tu loc ban ghi da xoa, join them hub/*_active la thua.
        repo["pit_filtered"] = {k.lower(): v for k, v in data.get("pit_da_loc_sts_hub", {}).items()}
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
    block = sorted(rid for rid, f in findings.items()
                   if rid in BLOCKING and f.status == FAIL)
    return {"n1": grp[G1], "n2": grp[G2], "n3": grp[G3], "ratio": ratio, "warn": warned,
            "block": block}


# ------------------------------------------------------------------ in ket qua
def print_file(ctx: Ctx, findings: dict, sc: dict, thr: float) -> None:
    verdict = "DAT" if sc["ratio"] <= thr and not sc["block"] else "KHONG DAT"
    src = "" if ctx.target_source == "AST" else f"  (target suy tu {ctx.target_source})"
    chan = f"   [CHAN boi {', '.join(sc['block'])}]" if sc["block"] else ""
    print(f"\n{'=' * 100}\n{ctx.short}   [{ctx.profile}]{src}   {ctx.path}")
    print(f"  ty le loi = {sc['ratio']:.0%}  (N1={sc['n1']} N2={sc['n2']} N3={sc['n3']})   nguong {thr:.0%}"
          f"   -> {verdict}{chan}   | canh bao: {len(sc['warn'])}")
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


def _sync_notes() -> dict:
    """{ten_workbook: [dong ghi chu]} de report.write ghi vao cot Ghi chu cua checklist.

    Ghi cho CA HAI phia, vi moi phia can biet mot viec khac nhau:
      - workbook TIEU THU dang giu ban cu -> phai cap nhat lai theo workbook chinh chu;
      - workbook CHINH CHU -> biet con nhung workbook nao dang phat tan ban cu cua minh."""
    notes: dict[str, list] = {}

    def add(path: str, lines: list) -> None:
        notes.setdefault(os.path.basename(path), []).extend(lines)

    for r in SYNC_RESULTS:
        if r.status not in ("LECH", "KHONG RO BAN CHUAN"):
            continue
        if not r.canon:
            n_ver = len({sync.fingerprint(q.sql) for q in r.others})
            for p in r.others:
                add(p.path, [f"Script bảng {r.object} đang có {n_ver} bản khác nhau ở"
                             f" {len(r.others)} file, chưa rõ file nào là bản chính."])
            continue
        for p in r.stale:
            cut = " (ô code ở đây còn bị Excel cắt mất đoạn cuối)" if p.truncated else ""
            add(p.path, [f"Script bảng {r.object} ở đây đang khác bản chính trong"
                         f" {os.path.basename(r.canon.path)}{cut}."])
        if r.stale:
            add(r.canon.path, [
                f"Script bảng {r.object} ở đây là bản chính; {len(r.stale)} file khác đang"
                f" để bản khác: {', '.join(os.path.basename(p.path) for p in r.stale)}."])
    return notes


def _warn_sync_tail() -> None:
    """Nhac lai o CUOI output: object nao co code lech giua cac workbook.

    Cham 'DAT' o bang tong hop KHONG co nghia la tai lieu da dong bo: tool chi cham BAN
    CHUAN (workbook chinh chu), cac ban dan kem o workbook tieu thu van co the la ban cu."""
    lech = [r for r in SYNC_RESULTS if r.status in ("LECH", "KHONG RO BAN CHUAN")]
    cut = sum(len(r.truncated) for r in SYNC_RESULTS)
    if not lech and not cut:
        return
    print(f"\n[!] DONG BO TAI LIEU: {len(lech)} object co code LECH giua cac workbook"
          f"{f' + {cut} o Excel bi CAT CUT' if cut else ''}"
          " - ban duoc cham la ban trong workbook chinh chu, cac ban dan kem o workbook"
          " khac dang la BAN CU:")
    print(f"    {', '.join(r.object for r in lech)}")
    print("    Xem diff:  run_check.py --sync-object <TEN_OBJECT>   |  ca bang + Excel:"
          "  run_check.py --sync-report")


def run_sync(args) -> int:
    """Che do --sync-report / --sync-object: chi doi chieu dong bo, khong cham checklist.

    Exit code: 0 = da dong bo het | 1 = con object LECH hoac khong ro ban chuan
               | 2 = khong doc duoc noi nao co code."""
    mapping_dirs = args.mapping_dir or [DEFAULT_MAPPING_DIR]
    # Chi doi chieu GIUA CAC WORKBOOK mapping voi nhau. File src/tckh/*.sql khong tinh la
    # 1 'noi giu ban thiet ke' - do la code deploy, sua theo nhip khac, nen luon lech vai
    # cho va lam bao cao day nhieu. Muon so voi code that thi truyen --src-dir tuong minh.
    src_dirs = [d for d in args.src_dir if os.path.isdir(d)]
    print(f"Doi chieu: workbook trong {mapping_dirs}"
          + (f" + code that trong {src_dirs}" if src_dirs else " (chi giua cac workbook)"))
    places = sync.collect(mapping_dirs, src_dirs)
    if not places:
        print("Khong doc duoc script nao tu workbook lan file .sql.")
        return 2
    results = sync.analyse(places)
    if args.sync_object:
        return sync.print_object(results, args.sync_object)

    sync.print_report(results)
    if not args.no_excel:
        out = os.path.join(args.out, "Sync_Report.xlsx")
        # Object da dong bo khong can dong nao trong file doi soat - chi xuat cai can sua.
        need = [r for r in results if r.status != "dong bo"]
        print(f"\nExcel: {sync.write_excel(need, out)}   ({len(need)} object can xu ly)")
    unresolved = [r for r in results if r.status in ("LECH", "KHONG RO BAN CHUAN")]
    return 1 if unresolved else 0


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
    ap.add_argument("--sync-report", action="store_true",
                    help="chi doi chieu dong bo: object nao co code o nhieu noi va noi nao"
                         " dang giu ban cu (khong cham checklist)")
    ap.add_argument("--sync-object", metavar="OBJ",
                    help="in diff DAY DU giua ban chuan va cac ban khac cua 1 object")
    ap.add_argument("--src-dir", action="append", default=[],
                    help="them thu muc code that (.sql) vao luot doi chieu --sync-report;"
                         f" mac dinh CHI so giua cac workbook (vd {DEFAULT_SRC_DIR})")
    args = ap.parse_args()

    if args.sync_report or args.sync_object:
        return run_sync(args)

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
        ok = sc["ratio"] <= thr and not sc["block"]
        ndat += ok
        note = "  <- TAM HOAN CHAM" if deferred_reason(ctx) else ""
        if sc["block"]:
            note = f"  <- CHAN boi {', '.join(sc['block'])}" + note
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
    _warn_sync_tail()
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
        xlsx = report.write(results, args.template, xlsx, args.batch, args.pic, _sync_notes())
        print(f"\nExcel: {xlsx}")

    if broken:
        print(f"\n[!] CANH BAO: {broken} assertion self-test truot - sua rule roi cham lai truoc khi gui OCB")
        return 3
    return 1 if ndat < len(rows) else 0


if __name__ == "__main__":
    sys.exit(main())
