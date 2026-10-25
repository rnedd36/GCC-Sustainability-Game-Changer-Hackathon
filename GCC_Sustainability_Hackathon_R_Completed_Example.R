##############################################################################
# GCC SUSTAINABILITY GAME CHANGER HACKATHON — COMPLETED R EXAMPLE
# PURPOSE: Collect -> Tidy -> Transform -> Analyze -> Visualize -> Communicate
# AUDIENCE: First-time R users | IDE: RStudio Desktop or Posit Cloud
# REFERENCE: Read alongside the R Glossary and event PowerPoint.
# EXAMPLE: NYC 2015 Street Tree Census (historical data, NOT a current count).
# DATASET: https://data.cityofnewyork.us/d/uvpi-gqnh
# IMPORTANT: Read the dataset description and field definitions before analysis.
##############################################################################

# HOW TO USE THIS COMPLETED EXAMPLE
# A. RUN the example as provided and examine the console, CSV and PNG files.
# B. CHANGE only the student settings to use a different compatible CSV dataset.
# C. RUN again. Compare the output and describe what it actually means.
# D. REFER to this completed file when working on your separate STARTER script.
# Use RStudio's Source button to run the whole script from top to bottom.

##############################################################################
# STEP 0 — CONFIGURATION: ALL EDITABLE VALUES LIVE HERE
##############################################################################

# PART A — STUDENT SETTINGS: EDIT THESE VALUES
DATASET_NAME <- "2015_Street_Tree_Census"
DATASET_ID <- "uvpi-gqnh"     # Code after /d/ in the NYC Open Data URL
MAX_ROW_COUNT <- 5000         # Begin small. A sample may not be representative.

# Choose columns AFTER seeing the available column names on the first run.
# LEAVE BLANK c("") to list all column names and stop before analysis.
# When filled, export only these columns as a CSV and continue the workflow.
COLUMN_NAMES <- c("tree_id", "boroname", "spc_common", "health", "tree_dbh")

# Choose ONE category/group field included in COLUMN_NAMES.
# Example: "boroname", "spc_common", "health"
GROUP_COLUMN <- "boroname"

# OPTIONAL: choose ONE numeric field included in COLUMN_NAMES.
# Blank "" means count records only; otherwise also calculate a group average.
# Example: "tree_dbh" (tree trunk diameter in inches)
VALUE_COLUMN <- "tree_dbh"

# Optional second category for a two-way summary; blank "" skips it.
SECOND_GROUP_COLUMN <- "spc_common"
TOP_N <- 10                 # How many groups appear in the chart

# PART B — PROGRAM SETTINGS: GENERALLY DO NOT EDIT
REQUIRED_PACKAGES <- c("dplyr", "readr", "ggplot2")
DOMAIN <- "https://data.cityofnewyork.us"
OUTPUT_FOLDER <- "hackathon_results"
REMOVE_EXACT_DUPLICATES <- FALSE  # Never remove rows without a reason.

##############################################################################
# STEP 1 — PREPARE THE SESSION AND OUTPUT DIRECTORY
##############################################################################
cat("\n========== STEP 1: PREPARE ==========\n")
# Do NOT use rm(list = ls()) here: it would erase the settings above.
if (!dir.exists(OUTPUT_FOLDER)) dir.create(OUTPUT_FOLDER, recursive = TRUE)
cat("Output folder:", normalizePath(OUTPUT_FOLDER), "\n")

##############################################################################
# STEP 2 — LOAD PACKAGES (from configuration)
##############################################################################
cat("\n========== STEP 2: LOAD PACKAGES ==========\n")
for (pkg in REQUIRED_PACKAGES) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing missing package: ", pkg)
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}
cat("Packages are ready.\n")

##############################################################################
# STEP 3 — COLLECT: CONNECT TO THE NYC OPEN DATA API
# Glossary: read_csv(), nrow(), ncol(), head(), colnames(), glimpse()
##############################################################################
cat("\n========== STEP 3: COLLECT ==========\n")
if (!grepl("^[a-z0-9]{4}-[a-z0-9]{4}$", DATASET_ID)) {
  stop("DATASET_ID should look like 'uvpi-gqnh'.")
}
if (!is.numeric(MAX_ROW_COUNT) || length(MAX_ROW_COUNT) != 1 ||
    is.na(MAX_ROW_COUNT) || MAX_ROW_COUNT < 1 || MAX_ROW_COUNT != floor(MAX_ROW_COUNT)) {
  stop("MAX_ROW_COUNT must be a positive whole number.")
}
api_url <- sprintf("%s/resource/%s.csv?$limit=%d",
                   DOMAIN, DATASET_ID, as.integer(MAX_ROW_COUNT))
cat("Dataset:", DATASET_NAME, "\n")
cat("Dataset page:", sprintf("%s/d/%s", DOMAIN, DATASET_ID), "\n")
cat("Download API:", api_url, "\n")

df <- tryCatch(
  readr::read_csv(api_url, show_col_types = FALSE, progress = FALSE),
  error = function(e) stop("Could not download data. Check dataset ID, internet, and CSV access: ", conditionMessage(e))
)
if (nrow(df) == 0) stop("The download returned zero rows. Choose another dataset or query.")
cat("Downloaded", nrow(df), "rows and", ncol(df), "columns.\n")
print(head(df, 3))

##############################################################################
# STEP 4 — EXPLORE: DISPLAY COLUMN NAMES / SELECT FIELDS
# Glossary: colnames(), seq_along(), select(), all_of(), write_csv()
##############################################################################
cat("\n========== STEP 4: EXPLORE AND SELECT ==========\n")
cat("\nAvailable columns:\n")
for (i in seq_along(names(df))) cat(sprintf("%3d. %s\n", i, names(df)[i]))

# Remove empty entries and accidental spaces in student settings.
COLUMN_NAMES <- unique(trimws(COLUMN_NAMES))
COLUMN_NAMES <- COLUMN_NAMES[!is.na(COLUMN_NAMES) & nzchar(COLUMN_NAMES)]
GROUP_COLUMN <- trimws(GROUP_COLUMN)
VALUE_COLUMN <- trimws(VALUE_COLUMN)
SECOND_GROUP_COLUMN <- trimws(SECOND_GROUP_COLUMN)

if (length(COLUMN_NAMES) == 0) {
  cat("\nDISCOVERY MODE: COLUMN_NAMES is blank.\n")
  cat("Copy field names from above into COLUMN_NAMES, then source the script again.\n")
  cat("Example: COLUMN_NAMES <- c(\"boroname\", \"health\")\n")
} else {
  missing_fields <- setdiff(COLUMN_NAMES, names(df))
  if (length(missing_fields) > 0) {
    stop("Unknown COLUMN_NAMES: ", paste(missing_fields, collapse = ", "),
         ". Copy exact names from the list above.")
  }
  if (!nzchar(GROUP_COLUMN) || !(GROUP_COLUMN %in% COLUMN_NAMES)) {
    stop("GROUP_COLUMN must be one of the selected COLUMN_NAMES.")
  }
  if (nzchar(VALUE_COLUMN) && !(VALUE_COLUMN %in% COLUMN_NAMES)) {
    stop("VALUE_COLUMN must be blank or included in COLUMN_NAMES.")
  }
  if (nzchar(SECOND_GROUP_COLUMN) && !(SECOND_GROUP_COLUMN %in% COLUMN_NAMES)) {
    stop("SECOND_GROUP_COLUMN must be blank or included in COLUMN_NAMES.")
  }
  df_selected <- dplyr::select(df, dplyr::all_of(COLUMN_NAMES))
  selected_file <- file.path(OUTPUT_FOLDER, paste0(DATASET_ID, "_selected_columns.csv"))
  readr::write_csv(df_selected, selected_file)
  cat("Saved selected raw fields:", selected_file, "\n")
  cat("Selected field preview:\n")
  print(head(df_selected, 5))

  ############################################################################
  # STEP 5 — TIDY: CHECK MISSING VALUES, TRIM TEXT, AND HANDLE DUPLICATES
  # Glossary: is.na(), trimws(), mutate(), filter(), distinct(), nrow()
  # POLICY: Do not delete all rows containing any missing cell.
  ############################################################################
  cat("\n========== STEP 5: TIDY ==========\n")
  cat("Missing values in selected fields BEFORE cleaning:\n")
  print(colSums(is.na(df_selected)))

  # Trim extra spaces on character fields, preserving numeric columns.
  df_tidy <- df_selected %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.character), trimws))

  # Empty text is treated as missing data.
  df_tidy <- df_tidy %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.character),
                                 ~ dplyr::na_if(.x, "")))

  # Only the chosen grouping field is essential to count by group.
  # Do not exclude a record just because another field is blank.
  rows_before <- nrow(df_tidy)
  df_tidy <- df_tidy %>% dplyr::filter(!is.na(.data[[GROUP_COLUMN]]))
  cat("Rows without a usable grouping value excluded:",
      rows_before - nrow(df_tidy), "\n")

  if (REMOVE_EXACT_DUPLICATES) {
    before_dedup <- nrow(df_tidy)
    df_tidy <- dplyr::distinct(df_tidy)
    cat("Exact duplicate rows removed:", before_dedup - nrow(df_tidy), "\n")
  } else {
    cat("Duplicate removal skipped: repeated-looking records may be valid.\n")
  }
  if (nrow(df_tidy) == 0) stop("No rows remained after tidying the grouping column.")
  cat("Rows retained:", nrow(df_tidy), "\n")

  ############################################################################
  # STEP 6 — TRANSFORM: CREATE A STANDARDIZED GROUP AND OPTIONAL NUMBER
  # Glossary: mutate(), as.character(), as.numeric(), trimws()
  ############################################################################
  cat("\n========== STEP 6: TRANSFORM ==========\n")
  df_transformed <- df_tidy %>%
    dplyr::mutate(group_label = as.character(.data[[GROUP_COLUMN]]))

  if (nzchar(VALUE_COLUMN)) {
    # parse_number handles e.g. "12.5" or "1,200" but can turn invalid text into NA.
    # Verify the field's units and examine parsing failures before interpreting means.
    original_values <- df_transformed[[VALUE_COLUMN]]
    df_transformed <- df_transformed %>%
      dplyr::mutate(numeric_value = suppressWarnings(
        readr::parse_number(as.character(.data[[VALUE_COLUMN]]))))
    invalid_values <- sum(!is.na(original_values) & is.na(df_transformed$numeric_value))
    cat("Nonmissing measurement values that could not be parsed:", invalid_values, "\n")
    cat("Reminder: The numeric field's units come from the dataset documentation.\n")
  }
  print(head(df_transformed, 5))

  ############################################################################
  # STEP 7 — ANALYZE: COUNT RECORDS / OPTIONAL AVERAGE BY CATEGORY
  # Glossary: group_by(), summarise(), n(), mean(), arrange(), desc(), count()
  ############################################################################
  cat("\n========== STEP 7: ANALYZE ==========\n")
  if (nzchar(VALUE_COLUMN)) {
    df_summary <- df_transformed %>%
      dplyr::group_by(group_label) %>%
      dplyr::summarise(
        record_count = dplyr::n(),
        observed_values = sum(!is.na(numeric_value)),
        average_value = if (all(is.na(numeric_value))) NA_real_
                        else mean(numeric_value, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      dplyr::arrange(dplyr::desc(record_count))
  } else {
    df_summary <- df_transformed %>%
      dplyr::count(group_label, name = "record_count", sort = TRUE)
  }
  cat("Category summary (first 10):\n")
  print(head(df_summary, 10))

  if (nzchar(SECOND_GROUP_COLUMN)) {
    df_two_way <- df_transformed %>%
      dplyr::count(group_label, .data[[SECOND_GROUP_COLUMN]],
                   name = "record_count", sort = TRUE)
    readr::write_csv(df_two_way,
                     file.path(OUTPUT_FOLDER, paste0(DATASET_ID, "_two_way_summary.csv")))
    cat("Saved optional two-category summary.\n")
  }

  ############################################################################
  # STEP 8 — VISUALIZE: BAR CHART OF TOP GROUPS
  # Glossary: ggplot(), aes(), geom_col(), coord_flip(), labs(), ggsave()
  ############################################################################
  cat("\n========== STEP 8: VISUALIZE ==========\n")
  if (!is.numeric(TOP_N) || length(TOP_N) != 1 ||
      is.na(TOP_N) || TOP_N < 1) stop("TOP_N must be a positive number.")
  chart_data <- head(df_summary, as.integer(TOP_N))
  chart <- ggplot2::ggplot(chart_data,
                          ggplot2::aes(x = stats::reorder(group_label, record_count),
                                       y = record_count)) +
    ggplot2::geom_col(fill = "#157A88") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = paste("Records by", GROUP_COLUMN),
      subtitle = paste(DATASET_NAME, "| Downloaded subset only"),
      x = GROUP_COLUMN,
      y = "Number of records (not automatically the number of people or resources)",
      caption = paste("NYC Open Data | dataset", DATASET_ID)
    ) + ggplot2::theme_minimal(base_size = 12)
  print(chart)
  chart_path <- file.path(OUTPUT_FOLDER, paste0(DATASET_ID, "_chart.png"))
  ggplot2::ggsave(chart_path, chart, width = 10, height = 6, dpi = 180)

  ############################################################################
  # STEP 9 — SAVE: TIDY DATA, SUMMARY, CHART AND PITCH WORKSHEET
  ############################################################################
  cat("\n========== STEP 9: SAVE RESULTS ==========\n")
  tidy_path <- file.path(OUTPUT_FOLDER, paste0(DATASET_ID, "_tidy.csv"))
  summary_path <- file.path(OUTPUT_FOLDER, paste0(DATASET_ID, "_summary.csv"))
  readr::write_csv(df_transformed, tidy_path)
  readr::write_csv(df_summary, summary_path)
  cat("Saved:", tidy_path, "\n", summary_path, "\n", chart_path, "\n")

  ############################################################################
  # STEP 10 — COMMUNICATE: TURN A CHART INTO AN EVIDENCE-BASED RECOMMENDATION
  # This worksheet is a starting point, NOT an auto-generated conclusion.
  ############################################################################
  cat("\n========== STEP 10: COMMUNICATE ==========\n")
  prompt_lines <- c(
    paste("DATASET:", DATASET_NAME),
    paste("SOURCE:", sprintf("%s/d/%s", DOMAIN, DATASET_ID)),
    paste("RECORDS DOWNLOADED:", nrow(df)),
    paste("GROUPING FIELD:", GROUP_COLUMN),
    paste("NUMERIC FIELD:", if (nzchar(VALUE_COLUMN)) VALUE_COLUMN else "None"),
    "",
    "1. RESEARCH QUESTION: What NYC sustainability question did you investigate?",
    "   Your response: ___________________________________________",
    "2. OBSERVATION: What does the chart show (with a number)?",
    "   Your response: ___________________________________________",
    "3. INTERPRETATION: Why might this matter to residents?",
    "   Your response: ___________________________________________",
    "4. LIMITATION: Are these sampled/historical records? What is missing?",
    "   Your response: ___________________________________________",
    "5. RECOMMENDATION: What feasible action do you propose, and for whom?",
    "   Your response: ___________________________________________",
    "6. NEXT EVIDENCE: What more should NYC collect or compare before acting?",
    "   Your response: ___________________________________________",
    "",
    "PITCH: 3 - 5 slides or 2 minutes — Question / Evidence / Recommendation.",
    "Caution: Record counts do not automatically prove environmental need or cause."
  )
  pitch_path <- file.path(OUTPUT_FOLDER, paste0(DATASET_ID, "_pitch_prompts.txt"))
  writeLines(prompt_lines, pitch_path)
  cat("Pitch worksheet:", pitch_path, "\n")
  cat("\nDISCUSS: What is your most important finding, its limitation, and a\n")
  cat("realistic recommendation? Verify the source before presenting.\n")
  cat("\nCOMPLETED: Collect -> Tidy -> Transform -> Analyze -> Visualize -> Communicate\n")
}
