# restore session
restore_session("05")

# copy data to export location
file.copy(cost_path, paste0("article/", basename(cost_path)))
file.copy(pa_path, paste0("article/", basename(pa_path)))
file.copy(spp_path, paste0("article/", basename(spp_path)))



# save session
save_session("final")
