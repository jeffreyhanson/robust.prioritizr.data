# restore session
restore_session("03")

# load parameters
spp_parameters <-
  RcppTOML::parseTOML("code/parameters/species.toml")[[MODE]]

# load data
study_area_data <- terra::rast(study_area_path)

# unzip data
temp_dir <- tempfile()
dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)
archive::archive_extract(
  "data/raw/species/archibald-vert-data.zip",
  dir = temp_dir
)

# extract file names
all_files <- dir(temp_dir, recursive = TRUE, full.names = TRUE)
tiff_files <- all_files[endsWith(all_files, ".tif")]

# extract information from file names
class_names =
  dirname(tiff_files[grepl("_historic_", tiff_files)]) %>%
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
  lapply(seq_along(spp_names), function(i) {
    ## build paths
    maxent_path <- paste0(
      temp_dir, "/", class_names[[i]], "/",
      spp_names[[i]], "_maxentResults.csv"
    )
    boyce_path <- paste0(
      temp_dir, "/", class_names[[i]], "/",
      spp_names[[i]], "_boyce_index_score.csv"
    )
    ## load data
    maxent_data <- readr::read_csv(maxent_path, show_col_types = FALSE)
    boyce_data <- readr::read_csv(boyce_path, show_col_types = FALSE)
    ## return data
    tibble::tibble(
      species = spp_names[[i]],
      auc = maxent_data[["Training AUC"]],
      boyce = boyce_data[["Spearman.cor (the Boyce index value)"]]
    )
  }) %>%
  dplyr::bind_rows()

# prepare metadata
meta_data <-
  expand.grid(species = spp_names, model = model_names) %>%
  tibble::as_tibble() %>%
  dplyr::left_join(
    tibble::tibble(
      species = spp_names,
      class = class_names
    ),
    by = "species"
  ) %>%
  mutate(
    id = seq_along(species)
  ) %>%
  mutate(
    path = paste0(
      temp_dir, "/", class, "/", species, "_", model,
      "_AUS_5km_EnviroSuit.tif"
    )
  ) %>%
  left_join(model_perf_data, by = "species") %>%
  select(id, species, class, model, auc, boyce, path)

# sanity check
assertthat::assert_that(
  all(file.exists(meta_data$path))
)

# subset species data based on models with adequate performance
meta_data <-
  meta_data %>%
  filter(
    auc >= spp_parameters$auc,
    boyce >= spp_parameters$boyce
  )

# resample species data to study area
study_area_bbox <-
  sf::st_buffer(sf::st_as_sfc(sf::st_bbox(study_area_data)), 1e4)
spp_data <-
  lapply(seq_along(meta_data$path), function(i) {
    message("starting ", i, " / ", nrow(meta_data))
    # note that 1st layer has mean, and 2nd is sd
    curr_r <- terra::rast(meta_data$path[[i]])[[1]]
    curr_bbox <-
      study_area_bbox %>%
      sf::st_transform(sf::st_crs(terra::crs(curr_r))) %>%
      sf::st_bbox() %>%
      terra::ext()
    curr_r <-
      curr_r %>%
      terra::crop(curr_bbox, snap = "out") %>%
      terra::project(study_area_data, method = "bilinear")
    curr_r
  }) %>%
  terra::rast() %>%
  setNames(
    paste0(
      meta_data$class, "-", meta_data$species, "-",
      gsub("-", "_", meta_data$model, fixed = TRUE)
    )
  ) %>%
  terra::mask(study_area_data)

# calculate total sum of values within each raster
meta_data <-
  meta_data %>%
  mutate(max_value = terra::global(spp_data, "max", na.rm = TRUE)[[1]])
meta_data <-
  meta_data %>%
  left_join(
    meta_data %>%
    summarize(spp_max_value = max(max_value), .by = c("species", "class")),
    by = c("species", "class")
  )

# subset species data based on threshold
## note that we want to retain species that are associated with
## any layers that meet the threshold
meta_data <-
  meta_data %>%
  filter(spp_max_value >= spp_parameters$threshold)
spp_data <- spp_data[[meta_data$id]]

# convert raster values to percentages
spp_data <- spp_data / 100

# save results
spp_path <- "data/intermediate/species.tif"
terra::writeRaster(
  spp_data, spp_path,
  NAflag = -9999, overwrite = TRUE, datatype = "FLT4S"
)

# clean up
rm(spp_data, study_area_data, study_area_bbox)

# save session
save_session("04")
