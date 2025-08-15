# restore session
restore_session("01")

# load parameters
pa_parameters <-
  RcppTOML::parseTOML("code/parameters/protected-areas.toml")[[MODE]]

# load data
pa_data <- read_sf_from_zip(
  paste0(
    "data/raw/capad-terrestrial-2024/",
    "Collaborative_Australian_Protected_Areas_Database_",
    "(CAPAD)_2024_-_Terrestrial__.zip"
   ),
  paste0(
    "Collaborative_Australian_Protected_Areas_Database_",
    "(CAPAD)_2024_-_Terrestrial__.shp"
  )
)
study_area_data <- terra::rast(study_area_path)

# prepare data
pa_data <-
  pa_data %>%
  sf::st_make_valid() %>%
  sf::st_transform(sf::st_crs(general_parameters$crs)) %>%
  sf::st_make_valid() %>%
  sf::st_union() %>%
  sf::st_sf(id = 1) %>%
  terra::vect() %>%
  terra::rasterize(study_area_data, cover = TRUE) %>%
  {terra::as.int(. >= pa_parameters$threshold)} %>%
  terra::subst(NA, 0) %>%
  terra::mask(study_area_data)

# save results-
pa_path <- "data/intermediate/pa.tif"
terra::writeRaster(
  pa_data, pa_path,
  NAflag = -9999, overwrite = TRUE
)

# clean up
rm(pa_data, study_area_data)

# save session
save_session("02")
