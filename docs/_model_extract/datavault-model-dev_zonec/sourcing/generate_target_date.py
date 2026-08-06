import argparse
import sys
from datetime import datetime, timedelta, timezone


VN_TZ = timezone(timedelta(hours=7))
MIN_DATE = datetime(2018, 1, 1)
VALID_TARGETS = ["dev", "pilotcloud", "prod"]
VALID_RUN_MODES = ["backfill", "daily"]
VALID_SOURCES = ["t24", "omni", "way4", "bpm", "crm", "callcenter", "appsflyer", "clevertap"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve and validate daily job parameters for Databricks Jobs."
    )
    parser.add_argument(
        "--target-date",
        default="",
        help="Optional target date in YYYYMMDD or YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--threads",
        default="20",
        help="dbt threads (positive integer).",
    )
    parser.add_argument(
        "--run-mode",
        default="daily",
        choices=VALID_RUN_MODES,
        dest="run_mode",
        help=f"dbt run mode: {VALID_RUN_MODES}.",
    )
    parser.add_argument(
        "--environment",
        default="",
        choices=[""] + VALID_TARGETS,
        help=f"dbt target environment: {VALID_TARGETS}.",
    )
    parser.add_argument(
        "--source-name",
        default="",
        dest="source_name",
        choices=[""] + VALID_SOURCES,
        help=f"Source system (optional): {VALID_SOURCES}.",
    )
    return parser.parse_args()


def normalize_date(raw_value: str) -> str:
    candidate = raw_value.strip()
    if not candidate:
        return ""

    for fmt in ("%Y%m%d", "%Y-%m-%d"):
        try:
            parsed = datetime.strptime(candidate, fmt)
            today = datetime.now(VN_TZ).replace(hour=0, minute=0, second=0, microsecond=0, tzinfo=None)
            if parsed < MIN_DATE:
                raise ValueError(
                    f"--target-date must be >= {MIN_DATE.strftime('%Y%m%d')} (got {parsed.strftime('%Y%m%d')})"
                )
            if parsed > today:
                raise ValueError(
                    f"--target-date must be <= {today.strftime('%Y%m%d')} (current date, got {parsed.strftime('%Y%m%d')})"
                )
            return parsed.strftime("%Y%m%d")
        except ValueError as e:
            if "--target-date must be" in str(e):
                raise
            continue

    raise ValueError(
        f"Unsupported date format '{raw_value}'. Expected YYYYMMDD or YYYY-MM-DD."
    )


def validate_threads(value: str) -> str:
    try:
        n = int(value)
        if n < 1:
            raise ValueError
    except (ValueError, TypeError):
        raise ValueError(f"--threads must be a positive integer (got {value!r})")
    return value


def publish_task_values(target_date: str, threads: str, run_mode: str) -> None:
    try:
        dbutils.jobs.taskValues.set(key="target_date", value=target_date)
        dbutils.jobs.taskValues.set(key="threads", value=threads)
        dbutils.jobs.taskValues.set(key="run_mode", value=run_mode)
        print(f"Published task values — target_date: {target_date}, threads: {threads}, run_mode: {run_mode}")
        return
    except NameError:
        pass
    except Exception as exc:
        print(
            "Could not publish Databricks task values, fallback to stdout only: "
            f"{exc}"
        )

    print(f"target_date={target_date} threads={threads} run_mode={run_mode}")


def main() -> None:
    args = parse_args()

    try:
        target_date = normalize_date(args.target_date)
        if not target_date:
            # print(f"Using yesterday's date as target date: {datetime.now(VN_TZ) - timedelta(days=1)}")
            target_date = (datetime.now(VN_TZ) - timedelta(days=1)).strftime("%Y%m%d")
        threads = validate_threads(args.threads)
    except ValueError as e:
        print(f"Validation error: {e}")
        sys.exit(1)

    publish_task_values(target_date, threads, args.run_mode)


if __name__ == "__main__":
    main()
