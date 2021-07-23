#!/bin/bash

# load FreeSurfer
module load freesurfer6.0.0
source /usr/share/freesurfer/SetUpFreeSurfer.sh 

# change dir
export FREESURFER_HOME=/usr/share/freesurfer/
export SUBJECTS_DIR=/storage/shared/research/cinn/2018/MAGMOT/MAGMOT_BIDS

# change directory to the raw NIFI files
cd /storage/shared/research/cinn/2018/MAGMOT/MAGMOT_BIDS/


# define subjects based on folder names in the BIDS directory
subjects=($(ls -d sub*))

# for each subject in the subjects array
for subject in "${subjects[@]}"; do
	# FreeSurfer recon-all
recon-all -all -subject  ${subject} -i /storage/shared/research/cinn/2018/MAGMOT/MAGMOT_BIDS/"${subject}"/anat/"${subject}"_rec-NORM_T1w.nii.gz -sd /storage/shared/research/cinn/2018/MAGMOT/derivatives/FreeSurfer/

# to continue pre-processing of a subject
#recon-all -all -subject  ${subject} -sd /storage/shared/research/cinn/2018/MAGMOT/derivatives/FreeSurfer/	
	
done

