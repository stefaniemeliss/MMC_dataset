#!/bin/bash

################################################################################
# B0 distortion correction
################################################################################

# define DIR
cd ~
#root=/storage/shared/research/cinn/2018/MAGMOT
root=~/Dropbox/Reading/PhD/Magictricks/fmri_study/MMC
# change directory to BIDS folder
BIDS_dir=$root"/rawdata/"
# change directory to the raw NIFI files
cd $BIDS_dir

# define deriv dir
deriv_dir=$root"/derivatives"

# define subjects based on folder names in the BIDS directory
subjects=($(ls -d sub*))
#subjects=($(ls -d sub-control*))
#subjects=($(ls -d sub-experimental*))
#subjects=(sub-control001)
#subjects=(sub-control003 sub-control017 sub-experimental008 sub-experimental010 sub-experimental018 sub-experimental030)
#subjects=(sub-experimental024)

# define search and replace strings
searchstring="_bold.nii.gz"
replacestring_json="_bold.json"
replacestring_b0corr="_desc-b0corrected.nii.gz"

# for each subject in the subjects array
for subject in "${subjects[@]}"; do

    echo "###################################################################################"
    echo "epi_b0_correct.py for subject $subject"
    echo "###################################################################################"

	# create output folder
  out_root=$deriv_dir/afni_proc
  mkdir -p $out_root
  mkdir -p $out_root/$subject
	out_dir=$out_root/$subject/epi_b0_correct
	mkdir -p $out_dir
    #cd $out_dir

	# define BIDS folder for subject
	BIDS_subj=$BIDS_dir/"${subject}"

    # create array with files
    cd $BIDS_subj/func
    func_files=($(ls *_bold.nii.gz))
    cd $BIDS_subj

    # loop through epi files
    for file in "${func_files[@]}"; do

        echo $file

        # define file names
        epi=$file
        json="${file/$searchstring/$replacestring_json}"
        prefix="${file/$searchstring/$replacestring_b0corr}"

        # run b0 correction
        epi_b0_correct.py                        \
            -prefix       $out_dir/$prefix        \
            -in_freq      fmap/"${subject}"_phasediff.nii.gz \
            -in_epi       func/$epi \
            -in_epi_json  func/$json \
            -in_magn      fmap/"${subject}"_magnitude1.nii.gz \
            -in_anat      anat/"${subject}"_rec-NORM_T1w.nii.gz \
            -scale_freq   0.311785               \
            -do_recenter_freq  NONE

    done

    echo ""
    echo ""
    echo ""

done
