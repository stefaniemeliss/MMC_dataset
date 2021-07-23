#!/bin/bash

################################################################################
# converting FreeSurfer to AFNI to create masks for pre-processing
################################################################################


# this script has to be run after the FS recon-all command
export FREESURFER_HOME=/Applications/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# define DIR
cd ~
#root=/storage/shared/research/cinn/2018/MAGMOT
root=~/Dropbox/Reading/PhD/Magictricks/fmri_study/MMC
BIDS_dir=$root"/rawdata/"
deriv_dir=$root"/derivatives"
fs_dir=$deriv_dir"/freesurfer"

# change directory to the raw NIFI files
cd $BIDS_dir

# define subjects based on folder names in the BIDS directory
subjects=($(ls -d sub*))
#subjects=(sub-control001 sub-control002 sub-control003 sub-experimental004 sub-experimental005 sub-experimental006)
#subjects=(sub-experimental005)
subjects=(sub-control037)

# for each subject in the subjects array
for subject in "${subjects[@]}"; do

	echo $subject

	#determine folders
	fs_subj=$fs_dir/$subject

	# cd into subject folder
	cd $fs_subj

	##### use SUMA to convert FreeSurfer output #####
	echo START WITH SUMA CONVERSION
	@SUMA_Make_Spec_FS -sid ${subject} -NIFTI -fs_setup

	# define SUMA folder
	suma_dir=$fs_subj/SUMA

	##### create mask and QC images #####
	echo CREATE THE WM AND VENTRICLE MASK
	adjunct_suma_fs_mask_and_qc -sid ${subject} -suma_dir $suma_dir

	# copy discrete segmentation files to derivatives/${subject}/anat folder
	# note: REN = renumbered
	# for Desikan-Killiany, see https://afni.nimh.nih.gov/pub/dist/src/scripts_install/afni_fs_aparc+aseg_2000.txt

	# define derivative dir
	subj_deriv=$deriv_dir/"${subject}"
	mkdir $subj_deriv
	anat_deriv=$subj_deriv/anat
	mkdir $anat_deriv/

	# define final prefix
	surfvol=$"${subject}"_space-orig_desc-surfvol_T1w.nii.gz
	VENT="${subject}"_space-orig_label-VENT_mask.nii.gz
	WM="${subject}"_space-orig_label-WM_mask.nii.gz
	GM="${subject}"_space-orig_label-GM_mask.nii.gz
	brain="${subject}"_space-orig_label-brain_mask.nii.gz
	desikan="${subject}"_space-orig_desc-DesikanKilliany_dseg.nii.gz
	destrieux="${subject}"_space-orig_desc-Destrieux_dseg.nii.gz

	# copy FS SUMA output
	3dcopy $suma_dir/"${subject}"_SurfVol.nii $anat_deriv/$surfvol
	3dcopy $suma_dir/fs_ap_latvent.nii.gz $anat_deriv/$VENT
	3dcopy $suma_dir/fs_ap_wm.nii.gz $anat_deriv/$WM
	3dcopy $suma_dir/fs_parc_wb_mask.nii.gz $anat_deriv/$brain
	3dcopy $suma_dir/aparc+aseg_REN_gm.nii.gz $anat_deriv/$GM
	3dcopy $suma_dir/aparc.a2009s+aseg_REN_all.nii.gz $anat_deriv/$destrieux
	3dcopy $suma_dir/aparc+aseg_REN_all.nii.gz $anat_deriv/$desikan

done
