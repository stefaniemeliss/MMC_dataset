#!/bin/bash

# run MRIQC for MMC data using docker #

# define input and output directory

bids_dir="/Users/nt807202/Dropbox/Reading/PhD/Magictricks/fmri_study/MMC/rawdata"
out_dir="/Users/nt807202/Dropbox/Reading/PhD/Magictricks/fmri_study/MMC/derivatives/mriqc_0.16.1"

# docker command for participant level
docker run -it --rm -v $bids_dir:/data:ro -v $out_dir:/out poldracklab/mriqc:0.16.1 /data /out participant --verbose-reports --write-graph --fd_thres 0.5 --despike --correct-slice-timing --no-sub

# create group reports
docker run -it --rm -v $bids_dir:/data:ro -v $out_dir:/out poldracklab/mriqc:0.16.1 /data /out group
