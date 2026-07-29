import os
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
    if "reviews" in filename:      # <-- agregar esta línea
        continue                    # <-- y esta

    # Table names
    table_name = filename.replace(".csv", "").replace("_dataset", "")
    table_id = f"{PROJECT}.{DATASET}.{table_name}"

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,       # skip header
        autodetect=True,           # infer schema
        write_disposition="WRITE_TRUNCATE",  # Overwrite
    )

    filepath = os.path.join(DATA_DIR, filename)
    with open(filepath, "rb") as f:
        load_job = client.load_table_from_file(f, table_id, job_config=job_config)

    load_job.result() 
    table = client.get_table(table_id)
    print(f"Loaded {table.num_rows} rows into {table_name}")

print("All tables loaded.")