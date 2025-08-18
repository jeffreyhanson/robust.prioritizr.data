## variables
MODE=release# set parameters for inference
# MODE=debug# set parameters for debugging code
R=/opt/R/R-4.4.1/bin/R # path to R 4.4.1 installation

## main operations
R:
	$(R) --quiet --no-save

all: install analysis

clean:
	@rm -rf data/intermediate/*
	@rm -rf data/final/*
	@rm article/* -f
	@touch data/intermediate/.gitkeep
	@touch data/final/.gitkeep
	@touch article/.gitkeep

upload:
	$(R) -e "piggyback::pb_upload('article/cost.tif',repo='jeffreyhanson/robust.prioritizr.data',tag='v1.0.0'),overwrite=TRUE"
	$(R) -e "piggyback::pb_upload('article/pa.tif',repo='jeffreyhanson/robust.prioritizr.data',tag='v1.0.0'),overwrite=TRUE"
	$(R) -e "piggyback::pb_upload('article/species.tif',repo='jeffreyhanson/robust.prioritizr.data',tag='v1.0.0'),overwite=TRUE"
	$(R) -e "piggyback::pb_upload('article/species.csv',repo='jeffreyhanson/robust.prioritizr.data',tag='v1.0.0'),overwite=TRUE"

# commands for updating time-stamps
touch:
	touch data/intermediate/00*.rda
	touch data/intermediate/01*.rda
	touch data/intermediate/02*.rda
	touch data/intermediate/03*.rda
	touch data/intermediate/04*.rda

# commands for running analysis
analysis: data/final/results.rda

data/final/results.rda: data/intermediate/04-*.rda code/R/analysis/05-*.R
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/05-*.R
	mv -f *.Rout data/intermediate/

data/intermediate/04-*.rda: data/intermediate/03-*.rda code/R/analysis/04-*.R  code/parameters/species.toml
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/04-*.R
	mv -f *.Rout data/intermediate/

data/intermediate/03-*.rda: data/intermediate/02-*.rda code/R/analysis/03-*.R code/R/functions/spatial_interpolation.R
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/03-*.R
	mv -f *.Rout data/intermediate/

data/intermediate/02-*.rda: data/intermediate/01-*.rda code/R/analysis/02-*.R code/parameters/protected-areas.toml
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/02-*.R
	mv -f *.Rout data/intermediate/

data/intermediate/01-*.rda: data/intermediate/00-*.rda code/R/analysis/01-*.R code/parameters/study-area.toml
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/01-*.R
	mv -f *.Rout data/intermediate/

data/intermediate/00-*.rda: code/R/analysis/00-*.R code/parameters/general.toml code/R/functions/misc.R code/R/functions/session.R
	$(R) CMD BATCH --no-restore --no-save '--args MODE=$(MODE)' code/R/analysis/00-*.R
	mv -f *.Rout data/intermediate/

# commands to fetch external data
raw_data: data/raw/human-footprint-index-2013/hfp2013_merisINT.tif data/raw/gadm/gadm41_AUS.gpkg data/raw/capad-terrestrial-2024/Collaborative_Australian_Protected_Areas_Database_(CAPAD)_2024_-_Terrestrial__.zip data/raw/species/archibald-vert-data.zip

data/raw/human-footprint-index-2013/hfp2013_merisINT.tif:
	$(R) -e "piggyback::pb_download('hfp2013_merisINT.tif',repo='jeffreyhanson/robust.prioritizr.data',dest='data/raw/human-footprint-index-2013',tag='v0.0.1')"

data/raw/gadm/gadm41_AUS.gpkg:
	$(R) -e "piggyback::pb_download('gadm41_AUS.gpkg',repo='jeffreyhanson/robust.prioritizr.data',dest='data/raw/gadm',tag='v0.0.1')"

data/raw/capad-terrestrial-2024/Collaborative_Australian_Protected_Areas_Database_(CAPAD)_2024_-_Terrestrial__.zip:
	$(R) -e "piggyback::pb_download('Collaborative_Australian_Protected_Areas_Database_(CAPAD)_2024_-_Terrestrial__.zip',repo='jeffreyhanson/robust.prioritizr.data',dest='data/raw/capad-terrestrial-2024/data',tag='v0.0.1')"

data/raw/species/archibald-vert-data.zip:
	$(R) -e "source('code/R/scripts/fetch_zip.R');fetch_zip('archibald-vert-data.zip',repo='jeffreyhanson/robust.prioritizr.data',dest='data/raw/species',tag='v0.0.1')"

# command to install dependencies
install:
	$(R) CMD BATCH --no-restore --no-save code/R/scripts/init.R
	mv -f *.Rout data/intermediate/

# renv commands
renv_snapshot:
	$(R) -e "renv::snapshot()"

.PHONY: install clean all analysis article figures
