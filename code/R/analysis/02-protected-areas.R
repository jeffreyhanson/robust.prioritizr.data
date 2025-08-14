# restore session
restore_session("01")

# load parameters
pa_parameters <-
  RcppTOML::parseTOML("code/parameters/protected-parameters.toml")[[MODE]]

# load data

# prepare data

# save results-

# clean up
rm()

# save session
save_session("02")
