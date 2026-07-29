import os
import csv
from google.cloud import bigquery

# CREDENTIALS
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.expanduser(
    "~/.dbt/bigquery-keyfile.json"
)

PROJECT = "data-eng-portfolio-503716"
DATASET = "olist_raw"
DATA_DIR = "data"

client = bigquery.Client(project=PROJECT)

for filename in os.listdir(DATA_DIR):
    if not filename.endswith(".csv"):
        continue
    if "reviews" in filename:
        continue

    # Table names
    table_name = filename.replace(".csv", "").replace("_dataset", "")
    table_id = f"{PROJECT}.{DATASET}.{table_name}"
    filepath = os.path.join(DATA_DIR, filename)

    # This table's headers aren't detected correctly by autodetect,
    # so we pass an explicit schema built from the CSV header (all STRING).
    if "category_name_translation" in filename:
        with open(filepath, "r", encoding="utf-8-sig") as f:
            header = next(csv.reader(f))
        schema = [bigquery.SchemaField(col, "STRING") for col in header]
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            schema=schema,
            write_disposition="WRITE_TRUNCATE",
        )
    else:
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            autodetect=True,
            write_disposition="WRITE_TRUNCATE",
        )

    with open(filepath, "rb") as f:
        load_job = client.load_table_from_file(f, table_id, job_config=job_config)

    load_job.result()
    table = client.get_table(table_id)
    print(f"Loaded {table.num_rows} rows into {table_name}")

print("All tables loaded.")