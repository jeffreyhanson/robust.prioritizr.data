# restore session
restore_session("03")

# load parameters
species_parameters <-
  RcppTOML::parseTOML("code/parameters/species.toml")[[MODE]]

# unzip data
temp_dir <- tempfile()
dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)
archive::archive_extract(data_path, dir = temp_dir)

# extract file names
all_files <- dir(temp_dir, recursive = TRUE, full.names = TRUE)
tiff_files <- all_files[endsWith(all_files, ".tif")]

# extract information from file names
class_names =
  basename(tiff_files[grepl("_historic_", tiff_files)]) %>%
  dirname() %>%
  basename()
spp_names =
  basename(tiff_files[grepl("_historic_", tiff_files)]) %>%
  strsplit("_historic_", fixed = TRUE) %>%
  lapply(`[[`, 1) %>%
  unlist()
model_names <-
  tiff_files %>%
  basename() %>%
  gsub(pattern = "_AUS_5km_EnviroSuit.tif", replacement = "", fixed = TRUE) %>%
  {dplyr::if_else(
    grepl("_GCM", ., fixed = TRUE),
    paste0("GCM", gsub(".*_GCM", "", .)),
    paste0("historic", gsub(".*_historic", "", .))
  )} %>%
  unique()

# prepare model performance data
model_perf_data <-
  lapply(seq_along(species_names), function(i) {
    ## build paths
    maxent_path <- paste0(
      temp_dir, "/", class_names[[i]], "/",
      species_names[[i]], "_maxentResults.csv"
    )
    ## load data
    maxent_data <- readr::read_csv(maxent_path, show_col_types = FALSE)

  }) %>%
  dplyr::bind_rows()

# prepare metadata
meta_data <-
  expand.grid(species = species_names, model = model_names) %>%
  dplyr::left_join(
    tibble::tibble(
      species = species_names,
      class = class_names
    ),
    by = "species"
  ) %>%
  mutate(
    path = paste0(
      temp_dir, "/", class, "/", species, "/", model,
      "AUS_5km_EnviroSuit.tif"
    )
  ) %>%
  mutate(exists = file.exists(path)) %>%
  select(species, class, model, exists, path)


# clean up
rm()

# save session
save_session("04")
