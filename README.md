# robust.prioritizr data

[![Status](https://img.shields.io/badge/Status-release-brightgreen.svg?style=flat-square)]()
[![License (GPL version 3)](https://img.shields.io/badge/License-GNU%20GPL%20version%203-brightgreen.svg?style=flat-square)](http://opensource.org/licenses/GPL-3.0)

### Overview

This repository contains the code and data for preparing data for the _robust.prioritizr_ package. Briefly, these data were obtained from [Archibald et al. (2024)](https://doi.org/10.1093/gigascience/giae031), [Williams et al.f (2020)](https://doi.org/10.1016/j.oneear.2020.08.009), and the [Collaborative Australian Protected Areas Database (CAPAD)](https://arcg.is/1Dmb8b0). After downloading repository, you rerun the analysis on your own computer using the system command `make all`. The files in this repository are organized as follows:
* article
  + description of simulation methodology and figures showing simulated data.
* data
  + _raw_: raw data used to run the analysis.
  + _intermediate_: intermediate data generated during processing.
  + _final_: resulting data.
* code
  + _parameters_: settings for running the analyses in [TOML format](https://github.com/toml-lang/toml).
  + [_R_](www.r-project.org): code used to run the analysis.
  + [_rmarkdown_](wwww.rmarkdown.rstudio.com): files used to generate article files.

### Software

* Operating system
  + Ubuntu (24.04.2 LTS)
* System packages:
  + unzip
  + p7zip-full (version 15.14.1+)
* Software
  + GCC (version 11.4.0)
  + GNU make (version 4.3)
  + [R (version 4.4.1)](https://www.r-project.org) (default path is `/opt/R/R-4.4.1/bin/R`; see the Makefile)
