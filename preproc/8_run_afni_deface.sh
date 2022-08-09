#!/bin/bash

# run MRIQC for MMC data using docker #

# define input directory

bids_dir="/Users/nt807202/Dropbox/Reading/PhD/Magictricks/fmri_study/MMC/rawdata_deface"

# define subjects based on folder names in the BIDS directory
cd $bids_dir
subjects=($(ls -d sub*))

# for each subject in the subjects array
for subject in "${subjects[@]}"; do

  # go into anat folder
  cd $subject/anat/

  # define input file
  input="$subject""_rec-NORM_T1w.nii.gz"

  # deface file and overwrite
  \@afni_refacer_run -input $input -mode_deface -overwrite -prefix $input

  # go back to BIDS folder
  cd $bids_dir

done
