# restore session
restore_session("00")

# load parameters
study_area_parameters <-
  RcppTOML::parseTOML("code/parameters/study-area.toml")[[MODE]]

# define paths
gadm_path <- "data/raw/gadm/gadm41_AUS.gpkg"
species_path <- "data/raw/species/archibald-vert-data.zip"

# load data
gadm_data <- sf::read_sf(gadm_path, "ADM_ADM_1")

# import species template
archive::archive_extract(
  species_path, dir = tempdir(),
  files = paste0(
    "birds/",
    "Acanthagenys_rufogularis_historic_baseline_1990_AUS_5km_EnviroSuit.tif"
  )
)
species_data <- terra::rast(
  paste0(
    tempdir(), "/birds/",
    "Acanthagenys_rufogularis_historic_baseline_1990_AUS_5km_EnviroSuit.tif"
  )
)

# prepare data
gadm_data <-
  gadm_data %>%
  filter(NAME_1 == study_area_parameters$name) %>%
  sf::st_make_valid() %>%
  sf::st_transform(sf::st_crs(general_parameters$crs)) %>%
  sf::st_make_valid()

# mask raster to study area
study_area_data <-
  gadm_data %>%
  mutate(value = 1) %>%
  terra::vect() %>%
  terra::rasterize(
    species_data %>%
      terra::project(paste0("epsg:", general_parameters$crs)),
    touches = TRUE,
    field = "value"
  ) %>%
  terra::trim()

# save results-
study_area_path <- "data/intermediate/study_area.tif"
terra::writeRaster(
  study_area_data, study_area_path,
  NAflag = 2, overwrite = TRUE, datatype = "INT2U",
  gdal = c("COMPRESS=ZSTD", "NBITS=2", "TILED=YES", "ZSTD_LEVEL=9")
)

# clean up
rm(gadm_data, study_area_data, species_data)

# save session
save_session("01")
