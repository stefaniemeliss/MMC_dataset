#!/bin/bash
source ~/.bashrc

###############################################################################
########################## set up and run 3dClustSim ##########################
###############################################################################


# define task
task=magictrickwatching
tasks=(magictrickwatching rest)
tasks=(magictrickwatching)

# define path
DIR="/storage/shared/research/cinn/2018/MAGMOT"

# define derivatves dir
deriv_dir="$DIR"/derivatives

# create and set working directory
anal_root="$deriv_dir"/analysis
mkdir -p $anal_root

# copy mask
cp $anal_root/MMC_paper/sample_label-dilatedGM_mask.nii.gz ./sample_label-dilatedGM_mask.nii.gz


for task in "${tasks[@]}"; do

    out_dir="$anal_root"/3dClustSim
    mkdir -p $out_dir
    cd $out_dir
    
    # extract and average smoothness of data sets
    params=$(grep -h ACF $deriv_dir/afni_proc/sub*/sub*task-"$task".results/out.ss*.txt | awk -F: '{print $2}' | 3dTstat -mean -prefix - 1D:stdin\')

    echo $params

    # simulate cluster extent threshold
    3dClustSim -acf $params -both -prefix ClustSim_"$task" -mask sample_label-dilatedGM_mask.nii.gz
    
done
