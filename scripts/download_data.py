import kagglehub
import shutil
import os

# Download Kaggle Dataset
path = kagglehub.dataset_download("olistbr/brazilian-ecommerce")
print("Downloaded to:", path)

# Copies CSVs into /data
os.makedirs("data", exist_ok=True)
for f in os.listdir(path):
    if f.endswith(".csv"):
        shutil.copy(os.path.join(path, f), os.path.join("data", f))
        print("Copied:", f)

print("Done. CSVs in ./data/")