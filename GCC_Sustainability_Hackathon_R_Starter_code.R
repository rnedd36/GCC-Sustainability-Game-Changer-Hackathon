##############################################################################
# Title:
# Purpose: Download, explore, and analyze a NYC Open Data dataset in R
# Author:
# Created:
# Updated:
# Notes:
##############################################################################
# Step 1 - Prepare a clean R session
##############################################################################


if (requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()) {
  rstudioapi::executeCommand("consoleClear")
}

cat("=====================================\n")
cat("Step 1: Preparing a clean R session\n")
cat("=====================================\n")

rm(list = ls())

message("Workspace cleared. Starting clean.")
#
# 
# R Version: 4.5.1 (2025-06-13)
# IDE: RStudio (Posit Cloud) or RStudio Desktop
##############################################################################
# Settings - You only need change this section

# 1. What dataset are you studying?
# Give your dataset a descriptive name.
dataset_name <- "2015_Street_Tree_Census"

# 2. What is the NYC Open Data dataset ID?
# Copy the 8-character ID from the dataset URL.
dataset_id <- "uvpi-gqnh"

# 3. How many rows should the program download?
# Beginners: start with 1000 rows.
# Increase the number when ready.
max_row_count <- 1000

# 4. Required packages you may update as needed.
required_packages <- c(
  "dplyr",
  "readr",
  "ggplot2",
  "lubridate"
)
# 5. Open NYC Data URL
domain <- "https://data.cityofnewyork.us"

# 6. Column Selection
# Leave blank ("") to display all available columns.
# Enter column names to export their data to CSV.
#
# Example:
COLUMN_NAMES <- c("tree_id", "zip_city", "spc_common")

# COLUMN_NAMES <- c("")

# 7. Create an output folder
output_dir <- "data_out"

# The rest of the program uses these settings.
############################################################################


##############################################################################
# Step 2 - Load required packages
##############################################################################

cat("=====================================\n")
cat("Step 2: Loading required packages\n")
cat("=====================================\n")

required_packages <- c("dplyr", "readr", "ggplot2")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing package: ", pkg)
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}

message("Required packages loaded.")
##############################################################################
# Step 3 - Set dataset information
##############################################################################

cat("=====================================\n")
cat("Step 3: Setting dataset information\n")
cat("=====================================\n")

base_url     <- sprintf("%s/resource/%s.csv", domain, dataset_id)
lookup_url     <- sprintf("%s/resource/%s", domain, dataset_id)
download_url <- sprintf("%s?$limit=%s", base_url, max_row_count)

cat("Dataset Information:\n")
cat("=====================================\n")
cat("Name:       ", dataset_name, "\n")
cat("Dataset ID: ", dataset_id, "\n")
cat("Row limit:  ", max_row_count, "\n")
cat("Domain:     ", domain, "\n")
cat("URL:        ", download_url, "\n")
cat("Lookup URL: ", lookup_url, "\n")
cat("=====================================\n")
##############################################################################
# Step 4 - Download the dataset
##############################################################################

cat("=====================================\n")
cat("Step 4: Downloading the dataset\n")
cat("=====================================\n")
cat("This may take a few seconds depending on the dataset size.\n\n")

df <- tryCatch(
  read_csv(
    file = download_url,
    show_col_types = FALSE,
    progress = FALSE
  ),
  error = function(e) {
    stop(
      paste(
        "The dataset could not be downloaded.",
        "Check your internet connection and dataset ID.",
        "Original error:", e$message
      )
    )
  }
)

message("Dataset downloaded successfully into the data frame named df.")


##############################################################################
# Step 5 - Preview the data
##############################################################################

cat("=====================================\n")
cat("Step 5: Previewing the data\n")
cat("=====================================\n")

cat("Rows downloaded:   ", nrow(df), "\n", sep = "")
cat("Number of columns: ", ncol(df), "\n", sep = "")

message("The dataset is stored in the data frame named df.")

# Get all available column names
columns <- names(df)

# Remove blank entries and extra spaces
COLUMN_NAMES <- trimws(COLUMN_NAMES)
COLUMN_NAMES <- COLUMN_NAMES[COLUMN_NAMES != ""]

if (length(COLUMN_NAMES) == 0){
  cat("\nColumn names in ", dataset_name, " (", dataset_id, ")\n", sep = "")
  cat("\nUse these names later when selecting, cleaning, and graphing data.\n")
  
  
  
  for (i in seq_along(columns)){
    column <- columns[i]
    cat(sprintf("%3d. %s\n", i, column))
  }
  cat("\nTo export data, enter column names")
  cat("\nin COLUMN_NAMES and run the script again.\n")
  
} else {
  
  # ------------------------------------------------
  # OPTION 2: Columns have been selected
  # ------------------------------------------------
  
  # Check whether selected columns exist
  missing_columns <- setdiff(COLUMN_NAMES, columns)
  
  if (length(missing_columns) > 0) {
    
    cat("\nERROR: These columns were not found:\n")
    print(missing_columns)
    
    cat("\nAvailable columns:\n")
    print(columns)
    
    stop("Please correct COLUMN_NAMES and try again.")
    
  }
  
  # Select only the requested columns
  df_selected <- df %>%
    select(all_of(COLUMN_NAMES))
  
  
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  
  # Create CSV filename
  output_file <- file.path(
    output_dir,
    paste0(dataset_name, "_selected.csv")
  )
  
  # Export selected data
  write_csv(df_selected, output_file)
  
  cat("\nSelected columns:\n")
  print(COLUMN_NAMES)
  
  cat("\nRows exported:", nrow(df_selected), "\n")
  
  cat("\nCSV file created:\n")
  cat(output_file, "\n")
  
  # Preview selected data
  print(head(df_selected, 6))
}

