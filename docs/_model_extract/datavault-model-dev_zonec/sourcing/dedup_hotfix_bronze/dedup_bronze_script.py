# Databricks notebook source
success_tables = []
error_tables = []

# Tables with duplicates: (schema.table, DATA_DATE)
duplicates = [
    ("t24.t24_az_account", "20251020"),
    ("t24.t24_az_account", "20251021"),
    ("t24.t24_consolidate_prft_loss", "20210924"),
    ("t24.t24_customer", "20240420"),
    ("t24.t24_funds_transfer", "20260421"),
    ("t24.t24_re_consol_spec_entry", "20221010"),
    ("t24.t24_stmt_entry", "20210525"),
    ("t24.t24_stmt_entry", "20220811"),
    ("t24.t24_stmt_entry", "20221010"),
    ("t24.t24_stmt_entry", "20231021"),
]

catalog = "ocb_datavault_prod_sourcing"

for table, data_date in duplicates:
    full_table = f"{catalog}.{table}"
    print(f"Deduplicating {full_table} | DATA_DATE = {data_date}")
    try:
        before_count = spark.sql(f"SELECT COUNT(*) FROM {full_table} WHERE DATA_DATE = '{data_date}'").collect()[0][0]

        spark.sql(f"""
            INSERT INTO {full_table}
            REPLACE WHERE DATA_DATE = '{data_date}'
            SELECT *
            FROM {full_table}
            WHERE DATA_DATE = '{data_date}'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY id, DATA_DATE ORDER BY etl_time DESC) = 1
        """)

        after_count = spark.sql(f"SELECT COUNT(*) FROM {full_table} WHERE DATA_DATE = '{data_date}'").collect()[0][0]
        print(f"  Before: {before_count:,} -> After: {after_count:,} (removed {before_count - after_count:,})")
        success_tables.append(f"{table} [{data_date}]")
    except Exception as e:
        error_tables.append({"table": table, "data_date": data_date, "error": str(e)})
        print(f"  Error: {e}")

print(f"\nDone. Success: {len(success_tables)} | Errors: {len(error_tables)}")
if error_tables:
    print("Failed:", error_tables)
