# restore session
restore_session("02")

# load functions
source("code/R/functions/spatial_interpolation.R")

# load data
study_area_data <- terra::rast(study_area_path)
hfi_data <-
  "data/raw/human-footprint-index-2013/hfp2013_merisINT.tif" %>%
  terra::rast()

# prepare data
cost_data <-
  hfi_data %>%
  terra::project(
    study_area_data %>% terra::disagg(fact = 10),
    method = "bilinear"
  ) %>%
  terra::aggregate(fact = 10) %>%
  raster_na_approx_idw(study_area_data) %>%
  terra::mask(study_area_data)
cost_data <- cost_data + 1

# sanity checks
assertthat::assert_that(
  identical(
    terra::cells(!is.na(study_area_data), 1)[[1]],
    terra::cells(!is.na(cost_data), 1)[[1]]
  )
)

# save results
cost_path <- "data/intermediate/cost.tif"
terra::writeRaster(
  cost_data, cost_path,
  NAflag = -9999, overwrite = TRUE, datatype = "FLT4S",
  gdal = c("COMPRESS=ZSTD", "TILED=YES", "ZSTD_LEVEL=9")
)

# clean up
rm(cost_data, study_area_data)

# save session
save_session("03")
