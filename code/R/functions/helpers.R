# define helper functions
pretty_number <- function(x) {
  assertthat::assert_that(assertthat::is.scalar(x))
  if (is.na(x)) return ("NA")
  assertthat::assert_that(assertthat::is.number(x))
  formatC(x, big.mark = ",", digits = 2, format = "f", drop0trailing = TRUE)
}

english_number <- function(x) {
  assertthat::assert_that(assertthat::is.scalar(x))
  if (is.na(x)) return ("NA")
  assertthat::assert_that(assertthat::is.number(x))
  as.character(english::as.english(x))
}

numeric_list <- function(x) {
  assertthat::assert_that(is.numeric(x), length(x) > 0, assertthat::noNA(x))
  strsplit(R.utils::seqToHumanReadable(x), ", ")[[1]]
}

multiply <- function(x, y) x * y

divide <- function(x, y) x / y

subtract <- function(x, y) x - y

clamp <- function(x) pmax(x, 0)

pluck <- function(x, y) x[[y]]

paste_list <- function(x, y = "and") {
  if (length(x) == 1)
    return(x)
  if (length(x) == 2)
    return(paste(x[1], y, x[2]))
  paste0(paste(x[-length(x)], collapse = ", "), ", ", y, " ", x[length(x)])
}

italicize <- function(x) {
  paste0("_", x, "_")
}

math_notation <- function(x) {
  output <- format(x, scientific = TRUE)
  output <- sub("e", " \\times 10^{", output, fixed = TRUE)
  output <- sub("\\+0?", "", output)
  output <- sub("-0?", "-", output)
  output <- paste0(output, "}")
  output[x == 0] <- x[x == 0]
  output <- paste0("$", output, "$")
  output
}

pretty_pvalue <- function(x) {
  x <- lazyWeave::pvalString(x)
  if (!startsWith(x, ">"))
    x <- paste("=", x)
  x
}

adjust_label_y <- function(name, statistic, value) {
  # validate arguments
  assertthat::assert_that(
    length(name) == length(statistic),
    length(name) == length(value))
  # return middle point for current and optimized schemes
  if (name[1] == "no additional\nsurveys") return(value)
  if (name[1] == "optimized") return(value)
  # initialize output
  out <- value
  # initialize variables
  buffer_factor <- 0.52
  adjust_factor <- 0.6
  min_pos <- which(statistic == "min")
  med_pos <- which(statistic == "med")
  max_pos <- which(statistic == "max")
  # determine label buffering
  if (abs(value[min_pos] - value[med_pos]) < buffer_factor) {
    out[min_pos] <- out[med_pos] - adjust_factor
  }
  if (abs(value[max_pos] - value[med_pos]) < buffer_factor) {
    out[max_pos] <- out[med_pos] + adjust_factor
  }
  # return output
  out
}

square_extent <- function(x, y) {
  xr <- range(x, na.rm = TRUE)
  yr <- range(y, na.rm = TRUE)
  xb <- abs(diff(xr)) / 2
  yb <- abs(diff(yr)) / 2
  xc <- mean(xr)
  yc <- mean(yr)
  # if x-axis is shorter then y-axis, then pad out x-axis
  if (xb < yb) {
    xr <- c(xc - yb, xc + yb)
  } else {
    # otherwise if y-axis is shorter then x-axis, pad out y-axis
    yr <- c(yc - xb, yc + xb)
  }
  list(x = xr, y = yr)
}

consecutive_duplicate <- function(x) {
  out <- x == dplyr::lag(x, 1)
  out[is.na(out)] <- FALSE
  out
}

pretty_parameter_names <- function(x) {
  paste0("\\texttt{", gsub("_", "\\_", x, fixed = TRUE), "}")
}

subfigure_number <- function(x, n) {
  assertthat::assert_that(assertthat::is.number(x), assertthat::is.number(n))
  if (x < n) {
    i <- rep(1, x)
  }
  else {
    v <- 1
    i <- numeric(x)
    for (j in seq_along(i)) {
      i[j] <- v
      if (sum(i == v) == n) {
        v <- v + 1
      }
    }
  }
  i
}

render_gvis <- function(x) {
  file = tempfile(fileext='.png')
  rsvg::rsvg_png(charToRaw(
    DiagrammeRsvg::export_svg(DiagrammeR::grViz(x))), file)
  grid::grid.raster(png::readPNG(file))
}

title_case <- function(x) {
  stringr::str_replace(x, "^\\w{1}", toupper)
}

wrap_text <- function(x, equal_newline = TRUE, equal_end = TRUE, width = 22) {
  x <- vapply(x, FUN.VALUE = character(1), function(z) {
    paste(strwrap(z, width = width), collapse = "\n")
  })
  if (equal_newline) {
    pos <- !grepl("\n", x)
    if (equal_end) {
      x[pos] <- paste0(x[pos], "\n")
    } else {
      x[pos] <- paste0("\n", x[pos])
    }
  }
  unname(x)
}

wrap_text2 <- function(x) {
  x <- wrap_text(x, FALSE)
  pos <- !grepl("\n", x)
  x[pos] <- gsub(" ", "\n", x[pos], fixed = TRUE)
  x
}

as_knitr_units <- function(x) {
  paste0(as.numeric(x), attr(x, "units")$numerator)
}

rgb2col = function(x) {
  rgb(
    rgbmat[1, ],
    rgbmat[2, ],
    rgbmat[3, ],
    maxColorValue = 255
  )
}

pad_spaces <- function(x) {
  assertthat::assert_that(assertthat::is.string(x))
  split <- strsplit(x, "\n", fixed = TRUE)[[1]]
  nc <- max(nchar(split))
  out <- vapply(split, FUN.VALUE = character(1), function(x) {
    if (nchar(x) == nc) return(x)
    npad <- ceiling((nc - nchar(x)) / 2)
    paste0(
      paste(rep(" ", npad), collapse = ""),
      x,
      paste(rep(" ", npad), collapse = "")
    )
  })
  paste(out, collapse = "\n")
}
pad_spaces("Annual & perennial\nnon-timber crops")
