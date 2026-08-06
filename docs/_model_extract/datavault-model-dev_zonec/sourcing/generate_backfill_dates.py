import argparse
import json
from datetime import date, datetime, timedelta
from typing import List


MIN_DATE = date(2018, 1, 1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate inclusive backfill dates for Databricks Jobs."
    )
    parser.add_argument(
        "--start-date",
        required=True,
        help="Start date in YYYYMMDD or YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--end-date",
        required=True,
        help="End date in YYYYMMDD or YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--task-value-key",
        default="backfill_dates",
        help="Databricks task value key to publish.",
    )
    return parser.parse_args()


def normalize_date(raw_value: str) -> date:
    candidate = raw_value.strip()
    for fmt in ("%Y%m%d", "%Y-%m-%d"):
        try:
            return datetime.strptime(candidate, fmt).date()
        except ValueError:
            continue
    raise ValueError(
        f"Unsupported date format '{raw_value}'. Expected YYYYMMDD or YYYY-MM-DD."
    )


def build_dates(start_day: date, end_day: date) -> List[str]:
    today = date.today()
    if start_day < MIN_DATE:
        raise ValueError(
            f"--start-date must be >= {MIN_DATE.strftime('%Y%m%d')} (got {start_day.strftime('%Y%m%d')})"
        )
    if end_day > today:
        raise ValueError(
            f"--end-date must be <= {today.strftime('%Y%m%d')} (current date, got {end_day.strftime('%Y%m%d')})"
        )
    if start_day > end_day:
        raise ValueError("--start-date must be less than or equal to --end-date")

    total_days = (end_day - start_day).days
    return [
        (start_day + timedelta(days=offset)).strftime("%Y%m%d")
        for offset in range(total_days + 1)
    ]


def publish_task_value(task_value_key: str, payload: list[str]) -> None:
    json_payload = json.dumps(payload)

    try:
        dbutils.jobs.taskValues.set(key=task_value_key, value=json_payload)
        print(f"Published task value '{task_value_key}' with payload: {json_payload}")
        return
    except NameError:
        pass
    except Exception as exc:
        print(
            "Could not publish Databricks task value, fallback to stdout only: "
            f"{exc}"
        )

    print(json_payload)


def main() -> None:
    args = parse_args()
    start_day = normalize_date(args.start_date)
    end_day = normalize_date(args.end_date)
    backfill_dates = build_dates(start_day=start_day, end_day=end_day)
    publish_task_value(args.task_value_key, backfill_dates)


if __name__ == "__main__":
    main()
