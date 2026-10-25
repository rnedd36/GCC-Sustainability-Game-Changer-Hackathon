"""GCC Sustainability Game Changer Hackathon — COMPLETE PYTHON EXAMPLE
Collect -> Explore -> Tidy -> Transform -> Analyze -> Visualize -> Communicate.
Run with: python GCC_Sustainability_Hackathon_Python_Completed_Example.py
Requires pandas and matplotlib; install with: python -m pip install pandas matplotlib
2015 Street Tree Census is HISTORICAL, not a current count of NYC trees.
"""

# ============================================================
# STEP 0 — CONFIGURATION: EDIT STUDENT SETTINGS ONLY
# ============================================================
# PART A: STUDENT SETTINGS
DATASET_NAME = "2015_Street_Tree_Census"
DATASET_ID = "uvpi-gqnh"  # NYC Open Data catalog ID from /d/uvpi-gqnh
MAX_ROW_COUNT = 5000       # Downloaded subset is not necessarily representative

# FIRST RUN: set COLUMN_NAMES = [] to print columns and stop after exploration.
# NEXT RUN: use exact field names from the printed list.
COLUMN_NAMES = ["tree_id", "boroname", "spc_common", "health", "tree_dbh"]
GROUP_COLUMN = "boroname"           # Category to compare; must be selected
VALUE_COLUMN = "tree_dbh"           # Numeric measure for optional average; or ""
SECOND_GROUP_COLUMN = "spc_common"  # Optional secondary category; or ""
TOP_N = 10

# PART B: PROGRAM SETTINGS — GENERALLY DO NOT CHANGE
REQUIRED_PACKAGES = ["pandas", "matplotlib"]  # install with pip, not in the script
DOMAIN = "https://data.cityofnewyork.us"
OUTPUT_FOLDER = "hackathon_results_python"
REMOVE_EXACT_DUPLICATES = False  # Duplicates can represent legitimate observations

# ============================================================
# STEP 1 — PREPARE: IMPORT PACKAGES AND MAKE OUTPUT FOLDER
# ============================================================
from pathlib import Path
import re
import sys
from urllib.error import HTTPError, URLError

try:
    import pandas as pd
    import matplotlib
    matplotlib.use("Agg")  # save PNG even on lab computers without a display
    import matplotlib.pyplot as plt
except ImportError as error:
    sys.exit(f"Missing package: {error}. Run: python -m pip install {' '.join(REQUIRED_PACKAGES)}")

output_dir = Path(OUTPUT_FOLDER)
output_dir.mkdir(parents=True, exist_ok=True)
print("\n========== STEP 1: PREPARE ==========\nOutput folder:", output_dir.resolve())

# ============================================================
# STEP 2 — COLLECT: REQUEST DATA FROM NYC OPEN DATA API
# Python/R comparison: pd.read_csv() = readr::read_csv()
# ============================================================
print("\n========== STEP 2: COLLECT ==========")
if not re.fullmatch(r"[a-z0-9]{4}-[a-z0-9]{4}", DATASET_ID):
    sys.exit("DATASET_ID should look like 'uvpi-gqnh'.")
if isinstance(MAX_ROW_COUNT, bool) or not isinstance(MAX_ROW_COUNT, int) or MAX_ROW_COUNT < 1:
    sys.exit("MAX_ROW_COUNT must be a positive whole number.")
if isinstance(TOP_N, bool) or not isinstance(TOP_N, int) or TOP_N < 1:
    sys.exit("TOP_N must be a positive whole number.")
api_url = f"{DOMAIN}/resource/{DATASET_ID}.csv?$limit={MAX_ROW_COUNT}"
source_url = f"{DOMAIN}/d/{DATASET_ID}"
print("Dataset:", DATASET_NAME, "\nSource:", source_url, "\nAPI:", api_url)
try:
    df = pd.read_csv(api_url, low_memory=False)
except (HTTPError, URLError, OSError, ValueError) as error:
    sys.exit(f"Download failed. Check internet, ID, and CSV availability: {error}")
if df.empty:
    sys.exit("Dataset has no downloaded records. Select another dataset.")
print(f"Downloaded {len(df):,} records and {len(df.columns)} columns.")
print(df.head(3).to_string(index=False))

# ============================================================
# STEP 3 — EXPLORE: SEE FIELDS, THEN SELECT / EXPORT
# Python/R comparison: df.columns = names(df); df[cols] = select()
# ============================================================
print("\n========== STEP 3: EXPLORE ==========")
for index, column in enumerate(df.columns, start=1):
    print(f"{index:3}. {column}")
print("\nTypes and nonmissing counts:")
print(df.info())
COLUMN_NAMES = list(dict.fromkeys(str(item).strip() for item in COLUMN_NAMES if str(item).strip()))
GROUP_COLUMN = GROUP_COLUMN.strip()
VALUE_COLUMN = VALUE_COLUMN.strip()
SECOND_GROUP_COLUMN = SECOND_GROUP_COLUMN.strip()
if not COLUMN_NAMES:
    print("\nDISCOVERY MODE: COLUMN_NAMES is blank. Copy exact columns into the settings, then run again.")
    sys.exit(0)
unknown = [name for name in COLUMN_NAMES if name not in df.columns]
if unknown:
    sys.exit(f"Unknown COLUMN_NAMES: {unknown}. Choose exact names printed above.")
if GROUP_COLUMN not in COLUMN_NAMES:
    sys.exit("GROUP_COLUMN must be included in COLUMN_NAMES.")
for setting, field in (("VALUE_COLUMN", VALUE_COLUMN), ("SECOND_GROUP_COLUMN", SECOND_GROUP_COLUMN)):
    if field and field not in COLUMN_NAMES:
        sys.exit(f"{setting} must be blank or included in COLUMN_NAMES.")
df_selected = df.loc[:, COLUMN_NAMES].copy()
selected_path = output_dir / f"{DATASET_ID}_selected_columns.csv"
df_selected.to_csv(selected_path, index=False)
print("Selected data saved:", selected_path)
print(df_selected.head().to_string(index=False))

# ============================================================
# STEP 4 — TIDY: EXAMINE MISSING VALUES, TRIM TEXT, KEEP RECORDS
# Python/R comparison: .isna() = is.na(); .drop_duplicates() = distinct()
# ============================================================
print("\n========== STEP 4: TIDY ==========")
print("Missing values before cleaning:\n", df_selected.isna().sum().to_string())
df_tidy = df_selected.copy()
for column in df_tidy.select_dtypes(include=["object", "string"]).columns:
    # preserve missing values; trim extra whitespace; treat empty strings as missing
    df_tidy[column] = df_tidy[column].astype("string").str.strip().replace("", pd.NA)
before = len(df_tidy)
df_tidy = df_tidy.dropna(subset=[GROUP_COLUMN]).copy()
print("Rows excluded for missing group:", before - len(df_tidy))
if REMOVE_EXACT_DUPLICATES:
    before = len(df_tidy)
    df_tidy = df_tidy.drop_duplicates().copy()
    print("Exact duplicate rows removed:", before - len(df_tidy))
else:
    print("Duplicate removal OFF: repeated-looking rows may be valid.")
if df_tidy.empty:
    sys.exit("No records have a valid grouping value after tidying.")

# ============================================================
# STEP 5 — TRANSFORM: CREATE COMMON GROUP/MEASUREMENT FIELDS
# Python/R comparison: .assign() = mutate(); pd.to_numeric() = as.numeric()
# ============================================================
print("\n========== STEP 5: TRANSFORM ==========")
df_transformed = df_tidy.copy()
df_transformed["group_label"] = df_transformed[GROUP_COLUMN].astype("string")
if VALUE_COLUMN:
    # Convert only fields whose documentation indicates they are numeric.
    raw_measure = df_transformed[VALUE_COLUMN].astype("string").str.replace(",", "", regex=False)
    df_transformed["numeric_value"] = pd.to_numeric(raw_measure, errors="coerce")
    failures = (df_transformed[VALUE_COLUMN].notna() & df_transformed["numeric_value"].isna()).sum()
    print("Nonmissing measurements not converted to numbers:", failures)
    print("Check original units in the NYC Open Data field descriptions.")
print(df_transformed.head(3).to_string(index=False))

# ============================================================
# STEP 6 — ANALYZE: RECORD COUNTS + OPTIONAL AVERAGE
# Python/R comparison: .groupby().agg() = group_by() %>% summarise()
# ============================================================
print("\n========== STEP 6: ANALYZE ==========")
if VALUE_COLUMN:
    df_summary = (df_transformed.groupby("group_label", dropna=False)
                  .agg(record_count=("group_label", "size"),
                       observed_values=("numeric_value", "count"),
                       average_value=("numeric_value", "mean"))
                  .reset_index().sort_values("record_count", ascending=False))
else:
    df_summary = (df_transformed.groupby("group_label", dropna=False)
                  .size().reset_index(name="record_count")
                  .sort_values("record_count", ascending=False))
print(df_summary.head(10).to_string(index=False))
if SECOND_GROUP_COLUMN:
    df_two_way = (df_transformed.groupby(["group_label", SECOND_GROUP_COLUMN], dropna=False)
                  .size().reset_index(name="record_count")
                  .sort_values("record_count", ascending=False))
    two_way_path = output_dir / f"{DATASET_ID}_two_way_summary.csv"
    df_two_way.to_csv(two_way_path, index=False)
    print("Two-way summary saved:", two_way_path)

# ============================================================
# STEP 7 — VISUALIZE: CHART OF TOP GROUPS
# Python/R comparison: matplotlib barh() = ggplot2 geom_col()+coord_flip()
# ============================================================
print("\n========== STEP 7: VISUALIZE ==========")
chart_data = df_summary.head(TOP_N).iloc[::-1]
fig, ax = plt.subplots(figsize=(10, 6))
ax.barh(chart_data["group_label"].astype(str), chart_data["record_count"])
ax.set_title(f"Records by {GROUP_COLUMN}\n{DATASET_NAME} — downloaded subset only")
ax.set_xlabel("Number of downloaded records (not automatically people/resources)")
ax.set_ylabel(GROUP_COLUMN)
fig.text(0.01, 0.01, f"Source: NYC Open Data | {DATASET_ID}", fontsize=9)
fig.tight_layout(rect=(0, 0.04, 1, 1))
chart_path = output_dir / f"{DATASET_ID}_chart.png"
fig.savefig(chart_path, dpi=180, bbox_inches="tight")
plt.close(fig)
print("Chart saved:", chart_path)

# ============================================================
# STEP 8 — SAVE: PRESERVE TRANSFORMED DATA AND SUMMARY
# ============================================================
print("\n========== STEP 8: SAVE ==========")
tidy_path = output_dir / f"{DATASET_ID}_tidy.csv"
summary_path = output_dir / f"{DATASET_ID}_summary.csv"
df_transformed.to_csv(tidy_path, index=False)
df_summary.to_csv(summary_path, index=False)
print("Saved:", tidy_path, "and", summary_path)

# ============================================================
# STEP 9 — COMMUNICATE: PROMPTS, NOT AUTOMATED CONCLUSIONS
# ============================================================
print("\n========== STEP 9: COMMUNICATE ==========")
questions = [
    f"DATASET: {DATASET_NAME}", f"SOURCE: {source_url}",
    f"DOWNLOADED RECORDS: {len(df)}", f"GROUPING FIELD: {GROUP_COLUMN}",
    f"NUMERIC FIELD: {VALUE_COLUMN or 'None'}", "",
    "1. QUESTION: Which NYC sustainability problem are you investigating?",
    "2. OBSERVATION: What number or pattern does the chart actually show?",
    "3. INTERPRETATION: Why might the pattern matter for residents?",
    "4. LIMITATION: What does a historical or limited download NOT tell you?",
    "5. RECOMMENDATION: What specific, feasible action do you propose?",
    "6. NEXT EVIDENCE: What should be compared before a policy decision?", "",
    "PITCH: Question -> Evidence -> Limitation -> Recommendation.",
    "CAUTION: Record counts do not by themselves prove environmental need or causation."
]
pitch_path = output_dir / f"{DATASET_ID}_pitch_prompts.txt"
pitch_path.write_text("\n".join(questions), encoding="utf-8")
print("Pitch worksheet saved:", pitch_path)
print("\nCOMPLETE: Collect -> Explore -> Tidy -> Transform -> Analyze -> Visualize -> Communicate")
