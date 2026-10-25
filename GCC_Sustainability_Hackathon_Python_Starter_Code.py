"""GCC Sustainability Hackathon — PYTHON STUDENT STARTER
Run: python GCC_Sustainability_Hackathon_Python_Starter_Code.py
Install: python -m pip install pandas matplotlib
Complete TODO challenges using the finished example and Python Glossary.
"""
# ================ STEP 0: STUDENT CONFIGURATION ================
DATASET_NAME = "2015_Street_Tree_Census"
DATASET_ID = "uvpi-gqnh"
MAX_ROW_COUNT = 1000
# FIRST RUN: [] lists all available fields and stops after exploration.
# NEXT RUN: paste exact fields printed in your first run.
COLUMN_NAMES = []
# Example: COLUMN_NAMES = ["tree_id", "boroname", "spc_common", "health", "tree_dbh"]
GROUP_COLUMN = "boroname"
VALUE_COLUMN = ""  # Optional: "tree_dbh" for average measurements
SECOND_GROUP_COLUMN = ""  # Optional: "spc_common"
TOP_N = 10
REQUIRED_PACKAGES = ["pandas", "matplotlib"]
DOMAIN = "https://data.cityofnewyork.us"
OUTPUT_FOLDER = "hackathon_results_python"
REMOVE_EXACT_DUPLICATES = False

# ================ STEP 1: PREPARE ================
from pathlib import Path
import re
import sys
try:
    import pandas as pd
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
except ImportError as error:
    sys.exit(f"Install packages: python -m pip install {' '.join(REQUIRED_PACKAGES)} ({error})")
output_dir = Path(OUTPUT_FOLDER)
output_dir.mkdir(parents=True, exist_ok=True)
print("STEP 1: Output folder:", output_dir.resolve())

# ================ STEP 2: COLLECT ================
print("\nSTEP 2: COLLECT")
if not re.fullmatch(r"[a-z0-9]{4}-[a-z0-9]{4}", DATASET_ID):
    sys.exit("Check DATASET_ID (example: uvpi-gqnh).")
if type(MAX_ROW_COUNT) is not int or MAX_ROW_COUNT < 1:
    sys.exit("MAX_ROW_COUNT must be a positive whole number.")
api_url = f"{DOMAIN}/resource/{DATASET_ID}.csv?$limit={MAX_ROW_COUNT}"
print("Downloading:", api_url)
try:
    df = pd.read_csv(api_url, low_memory=False)
except Exception as error:
    sys.exit(f"Download failed: {error}")
if df.empty:
    sys.exit("No data was returned.")
print("Downloaded shape:", df.shape)
print(df.head(3).to_string(index=False))

# ================ STEP 3: EXPLORE AND CHOOSE FIELDS ================
print("\nSTEP 3: EXPLORE")
for index, name in enumerate(df.columns, 1):
    print(f"{index:3}. {name}")
COLUMN_NAMES = list(dict.fromkeys(str(x).strip() for x in COLUMN_NAMES if str(x).strip()))
if not COLUMN_NAMES:
    print("DISCOVERY MODE: enter names in COLUMN_NAMES and run the program again.")
    sys.exit(0)
invalid = [x for x in COLUMN_NAMES if x not in df.columns]
if invalid:
    sys.exit(f"Columns not found: {invalid}. Copy the exact names above.")
GROUP_COLUMN, VALUE_COLUMN, SECOND_GROUP_COLUMN = [x.strip() for x in (GROUP_COLUMN, VALUE_COLUMN, SECOND_GROUP_COLUMN)]
if GROUP_COLUMN not in COLUMN_NAMES:
    sys.exit("GROUP_COLUMN must be one of your chosen COLUMN_NAMES.")
if any(x and x not in COLUMN_NAMES for x in [VALUE_COLUMN, SECOND_GROUP_COLUMN]):
    sys.exit("VALUE_COLUMN and SECOND_GROUP_COLUMN must be selected columns or blank.")
df_selected = df.loc[:, COLUMN_NAMES].copy()
df_selected.to_csv(output_dir / f"{DATASET_ID}_selected_columns.csv", index=False)
print("Exported selected columns.\n", df_selected.head().to_string(index=False))

# ================ STEP 4: TIDY ================
print("\nSTEP 4: TIDY")
print("Missing values:\n", df_selected.isna().sum().to_string())
# TODO 1: Make df_tidy as a copy of df_selected.
# TODO 2: Trim text using .str.strip(); turn empty strings into missing values.
# TODO 3: Drop rows missing only GROUP_COLUMN (not every incomplete row).
# TODO 4: Optionally remove exact duplicates if there is a reason.
# TIP: Consult the completed Python example and glossary.
# Uncomment and complete the next line once ready:
# df_tidy = ...

# ================ STEP 5: TRANSFORM ================
# TODO 5: Copy tidy data to df_transformed.
# TODO 6: Create group_label from GROUP_COLUMN.
# TODO 7: If VALUE_COLUMN is set, create numeric_value using pd.to_numeric().

# ================ STEP 6: ANALYZE ================
# TODO 8: Group rows by group_label; count rows with .groupby().size().
# TODO 9: Optionally calculate a numeric group average with .agg().
# TODO 10: Save a summary as <DATASET_ID>_summary.csv.

# ================ STEP 7: VISUALIZE ================
# TODO 11: Use plt.subplots() and ax.barh() to plot top categories.
# TODO 12: Add labels and title; save PNG using fig.savefig().

# ================ STEP 8: COMMUNICATE ================
# TODO 13: Give one finding (with a number), one limitation, and one action.
# TODO 14: Prepare a 2-minute pitch or 3 slides.
print("\nSTARTER COMPLETE THROUGH EXPLORE. Continue TODO steps using the reference example.")
