raster_na_approx_idw <- function(x, y) {
  # validate data
  terra::compareGeom(x, y, res = TRUE)
  # check if approximation required
  cells <- terra::cells(!is.na(y) & is.na(x), 1)[[1]]
  if (length(cells) == 0) return(x)
  # interpolate missing values using inverse distance weighting
  d <- terra::as.data.frame(x, na.rm = FALSE, xy = TRUE)
  d <- sp::SpatialPointsDataFrame(
    coords = d[, c("x", "y"),], data = d, proj4string = sp::CRS(terra::crs(x))
  )
  names(d) <- c("x", "y", "value")
  train <- d[!is.na(d$value), , drop = FALSE]
  pred <- d[cells, c("x", "y")]
  idw <- gstat::idw(formula = value ~ 1, locations = train, newdata = pred)
  x[cells] <- idw@data$var1.pred
  x
}
