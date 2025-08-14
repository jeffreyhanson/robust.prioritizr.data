# restore session
restore_session("00")

# load parameters
study_area_parameters <-
  RcppTOML::parseTOML("code/parameters/study-area.toml")[[MODE]]

# load data

# prepare data

# save results-

# clean up
rm()

# save session
save_session("01")
