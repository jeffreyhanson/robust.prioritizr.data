# restore session
restore_session("04")

# copy data to export location
file.copy(cost_path, paste0("article/", basename(cost_path)))
file.copy(pa_path, paste0("article/", basename(pa_path)))
file.copy(spp_path, paste0("article/", basename(spp_path)))
readr::write_csv(meta_data, "article/species.csv")


# save session
save_session("final")
