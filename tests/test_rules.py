"""Kiem chung rule: chay tren fixture co tinh sai/dung, doi chieu voi ky vong.

  python tools/gold_review/tests/test_rules.py
Rule nao khong bat duoc loi trong fixture -> test do bao FAIL.
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(TOOL, "engine"))
sys.path.insert(0, TOOL)
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from core import read_ctx  # noqa: E402
from run_check import attach_mapping, build_repo, evaluate  # noqa: E402

FIX = os.path.join(HERE, "fixtures")

EXPECT = {
    "bad_fct.sql": {
        "1.2": "FAIL",   # khong co workbook thiet ke
        "2.1": "FAIL",   # hub khong loc qua sts_hub + loc cdc_status sai tang trong satellite
        "2.3": "FAIL",   # a.rn = 1 long trong LEFT JOIN ON
        "2.4": "FAIL",   # thieu dieu kien source_event_date
        "3.1": "FAIL",   # SELECT *
        "3.5": "FAIL",   # ROW_NUMBER=1 thay vi MAX_BY
        "X.1": "FAIL",   # link_account_customer chua rut ve current
        "X.2": "FAIL",   # tron dev + pilotcloud
        "X.3": "FAIL",   # INSERT khong liet ke cot
        "X.4": "FAIL",   # khong DELETE truoc INSERT
        "X.6": "FAIL",   # INNER JOIN sat_customer_kyc
        "2.2": "FAIL",   # ROW_NUMBER tren sat_deposits_rate chi 2-3 cot (<=5) -> khong duoc
                         # mien tru, tinh khac pattern voi MAX_BY -> bat nhat trong batch
    },
    "good_fct.sql": {
        "1.1": "PASS",   # 3 field thiet ke khop 3 cot SQL
        "1.2": "PASS",   # co workbook thiet ke tuong ung
        "X.8": "PASS",   # JOIN SCHEMA khop bang nguon trong SQL
        "2.1": "PASS",   # sts_hub + HAVING max_by(cdc_status,...)='D' + anti-join IS NULL
        "2.2": "PASS", "2.3": "PASS",
        "2.4": "PASS",   # sat thuong dung <=, sat_account_balance (transaction) dung =
        "3.1": "PASS", "3.5": "N-A",
        "X.1": "PASS",   # link rut current bang GROUP BY + MAX_BY
        "X.2": "PASS", "X.3": "PASS", "X.4": "PASS", "X.6": "PASS",
        "2.12": "PASS",
    },
    "cb_ou_dim.sql": {
        "2.6": "FAIL",   # MAX(ID)+ROW_NUMBER + khong dung APPLY CHANGES SCD TYPE 2
    },
    # self-join trong cung 1 SELECT + filter dat trong ON: KHONG duoc bao loi
    "holiday_fx.sql": {
        "2.12": "PASS",  # 2 alias cua cung 1 bang trong 1 khoi SELECT = 1 snapshot
        "3.3": "PASS",   # filter rieng cua W nam trong ON, dung cho LEFT JOIN
    },
    "bad_two_cte.sql": {
        "2.12": "FAIL",  # cung 1 bang raw_vault doc o 2 CTE khac nhau
    },
    # bang upload/thu cong la nguon HOP LE khi khai o cot NOTE cua JOIN SCHEMA
    "upl_fct.sql": {
        "X.9": "PASS",
        "X.8": "PASS",
        "1.1": "PASS",
        "1.2": "PASS",   # ten khop ca 3 noi: CREATE, ten file, workbook -> khong bao lech
    },
    # file chi co DDL: bang dich KHONG duoc tinh la bang nguon cua chinh no
    "tb_manual_dtl.sql": {
        "X.9": "N-A",
    },
    # ten object trong CREATE khac ten file -> phai bat duoc
    "name_mismatch.sql": {
        "1.2": "FAIL",
    },
    # nguon khong nam trong luot chay: chua ket luan duoc, KHONG duoc bao Fail
    "v_unknown_src.sql": {
        "X.9": "WARN",
    },
}


def main() -> int:
    ctxs = {os.path.basename(p): read_ctx(p)
            for p in (os.path.join(FIX, f) for f in sorted(os.listdir(FIX))) if p.endswith(".sql")}
    attach_mapping(list(ctxs.values()), [os.path.join(FIX, "mapping")])
    repo = build_repo(list(ctxs.values()), None)

    bad = 0
    for fname, expect in EXPECT.items():
        ctx = ctxs[fname]
        findings = evaluate(ctx, repo, None)
        print(f"\n{fname}  [{ctx.profile}]  target={ctx.target}")
        for rid, want in expect.items():
            got = findings[rid].status
            ok = got == want
            bad += not ok
            print(f"  {'ok  ' if ok else 'MISS'} {rid:<5} mong doi {want:<7} nhan {got:<7}"
                  f" {'' if ok else '<<< RULE SAI'}")
            if not ok:
                for e in findings[rid].evidence:
                    print(f"          {e}")

    total = sum(len(v) for v in EXPECT.values())
    print(f"\n{total - bad}/{total} assertion dat")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
