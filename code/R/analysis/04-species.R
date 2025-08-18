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
    ## sanity check
    assertthat::assert_that(
      assertthat::has_name(maxent_data, spp_parameters$method_threshold),
      is.numeric(maxent_data[[spp_parameters$method_threshold]]),
      assertthat::noNA(maxent_data[[spp_parameters$method_threshold]])
    )
    ## return data
    tibble::tibble(
      species = spp_names[[i]],
      auc = maxent_data[["Training AUC"]],
      boyce = boyce_data[["Spearman.cor (the Boyce index value)"]],
      threshold = maxent_data[[spp_parameters$method_threshold]]
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
  select(id, species, class, model, auc, boyce, threshold, path)

# clean up
rm(class_names, spp_names, model_names, model_perf_data)

# subset species data based on taxa
if (!identical(spp_parameters$class_name, "all")) {
  meta_data <-
    meta_data %>%
    filter(class %in% spp_parameters$class_name) %>%
    mutate(id = seq_along(species))
}

# subset species data based on models with adequate performance
meta_data <-
  meta_data %>%
  filter(
    auc >= spp_parameters$auc_threshold,
    boyce >= spp_parameters$boyce_threshold
  ) %>%
  mutate(id = seq_along(species))

# sanity check
assertthat::assert_that(
  nrow(meta_data) >= 1,
  all(file.exists(meta_data$path))
)

# resample species data to study area
study_area_bbox <-
  sf::st_buffer(sf::st_as_sfc(sf::st_bbox(study_area_data)), 1e4)
spp_data <-
  lapply(seq_along(meta_data$path), function(i) {
    message("starting ", i, " / ", nrow(meta_data))
    # spatially prepare data
    ## note that 1st layer has mean, and 2nd is sd
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
    ## threshold data
    curr_r <- terra::as.int(curr_r >= meta_data$threshold[[i]])
    ## return data
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
  filter(spp_max_value >= spp_parameters$min_area_threshold)

# subset raster data
spp_data <- spp_data[[meta_data$id]]

# update metadata
meta_data <-
  meta_data %>%
  mutate(
    id = seq_along(id),
    name =  names(spp_data)
  ) %>%
  rename(proj = model) %>%
  select(id, name, species, class, proj, auc, boyce, threshold)

# save results
spp_path <- "data/intermediate/species.tif"
terra::writeRaster(
  spp_data, spp_path,
  NAflag = 2, overwrite = TRUE, datatype = "INT1U",
  gdal = c("COMPRESS=ZSTD", "NBITS=2", "TILED=YES", "ZSTD_LEVEL=9")
)

# clean up
rm(spp_data, study_area_data, study_area_bbox)

# save session
save_session("04")
