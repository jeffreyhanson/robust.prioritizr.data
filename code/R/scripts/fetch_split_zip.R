# Initialization
## load packages
library(dplyr)

## load scripts
source('code/R/scripts/fetch_zip.R')

## set parameters
gh_repo <- "jeffreyhanson/action-prioritization"
gh_tag <- "v0.0.1"

## extract command line arguments
cmd_args <- commandArgs(TRUE)
file_name <- cmd_args[[1]]
output_dir <- cmd_args[[2]]

# Main processing
## find files to download from archive
file_pattern <- tools::file_path_sans_ext(file_name)
dl_files <-
  piggyback::pb_list(repo = gh_repo, tag = gh_tag) %>%
  dplyr::filter(
    tools::file_path_sans_ext(.$file_name) == file_pattern
  )

## print files to download
print(dl_files)

## download separate zip files to temporary directory
td <- tempfile()
dir.create(td, showWarnings = FALSE, recursive = TRUE)
invisible(
  sapply(
    dl_files$file_name,
    fetch_zip,
    dl_files$file_name,
    dest = td,
    repo = gh_repo,
    tag = gh_tag,
    show_progress = TRUE
  )
)

## merge into a single zip file
withr::with_dir(
  td,
  system(paste0("zip -F ", file_name, " --out ", paste0("full-", file_name)))
)

## copy file to destination
file.copy(
  file.path(td, paste0("full-", file_name)),
  file.path(output_dir, file_name),
  overwrite = TRUE
)
assertthat::assert_that(file.exists(file.path(output_dir, file_name)))

# Clean up
unlink(td, force = TRUE, recursive = TRUE)
