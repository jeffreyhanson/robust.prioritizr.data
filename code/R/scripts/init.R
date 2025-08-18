# restore library
renv::restore()

# install gurobi R package
renv::install(
  dir(
    paste0(Sys.getenv("GUROBI_HOME"), "/R"), "^.*\\.tar\\.gz",
    full.names = TRUE
  )
)

# install maxent executable file
file.copy(
  "code/java/maxent.jar",
  paste0(system.file("java", package = "dismo"), "/maxent.jar"),
  overwrite = TRUE
)

# ensure optional package dependencies are installed
tmp1 <- piggyback::pb_download

# print success
message("successfully initialized packages!")
