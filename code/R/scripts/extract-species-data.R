# Initialization
## load packages
library(dplyr)
library(archive)
library(tibble)

## define parameters
input_path <- "Maxent_results_statistical_information_data.tar.gz"
meta_path <- "contents.txt"
export_path <- "archibald-vert-data.zip"
taxa <- c("amphibians", "birds", "reptiles", "mammals")

# Preliminary processing
## create archive file listing
system(paste0("tar -tf ", input_path, " > contents.txt"))

## load data
meta_data <-
  readLines(meta_path) %>%
  {tibble(path = .)} %>%
  filter(
    endsWith(path, "_AUS_5km_EnviroSuit.tif") |
    endsWith(path, "maxentResults.csv") |
    endsWith(path, "boyce_index_score.csv")
  )

# Main processing
## process each class separately
result <- vapply(
  seq_along(taxa),
  FUN.VALUE = logical(1),
  function(i) {
    ## create file paths
    curr_dir <- paste0("export/", taxa[[i]])
    curr_temp <- tempfile()
    ## create temporary location
    dir.create(curr_dir, showWarnings = FALSE, recursive = TRUE)
    dir.create(curr_temp, showWarnings = FALSE, recursive = TRUE)
    ## subset data for class and set filenames
    curr_data <-
      meta_data %>%
      filter(grepl(taxa[[i]], path, fixed = TRUE)) %>%
      mutate(,
        species = basename(dirname(path))
      ) %>%
      mutate(
        name = if_else(
          endsWith(path, ".csv"),
          paste0(species, "_", basename(path)),
          basename(path)
        )
      )
    ## extract files to temporary location
    archive::archive_extract(
      archive = input_path,
      dir = curr_temp,
      file = curr_data$path
    )
    ## copy files
    file.copy(
      paste0(curr_temp, "/", curr_data$path),
      paste0(curr_dir, "/",  curr_data$name)
    )
    ## clean up
    unlink(curr_temp, force = TRUE)
    ## return success
    TRUE
  }
)

# Exports
## zip files for export
archive::archive_write_dir(export_path, "export")
