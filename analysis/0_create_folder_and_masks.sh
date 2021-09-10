#!/bin/bash

# this code creates the directory and gm masks

# define path
path="/storage/shared/research/cinn/2018/MAGMOT"

# define directories
deriv_dir=$path/derivatives
anal_dir=$deriv_dir/analysis
mkdir -p $anal_dir
MMC_dir=$anal_dir/MMC_paper
mkdir -p $MMC_dir

code_dir=$path/code/neuro-MMC/analysis/

# define which template to use and where to find them
template=MNI152_2009_template_SSW.nii.gz
template_path=`@FindAfniDsetPath $template`

############### create average EPI and gray matters masks ###############

#cd "$deriv_dir" # change directory to where pre-processed files are
rm $MMC_dir/sample*

task=rest
task=magictrickwatching
task=both

# define prefix
epi_ave=sample_task-"$task"_label-automask_average.nii.gz
epi_mask=sample_label-dilatedGM_mask.nii.gz

gm_ave=sample_task-"$task"_label-gm_average.nii.gz
gm_mask=sample_label-gm_mask.nii.gz

# define string for the masks that are created during pre-processing
mask_ea=*_task-"$task"_space-MNI152NLin2009cAsym_label-dilatedGM_mask.nii.gz
mask_ea=*_space-MNI152NLin2009cAsym_label-dilatedGM_mask.nii.gz

# create average EPI masks restingstate: Combine individual EPI automasks into a group mask
3dMean -datum float -prefix $MMC_dir/$epi_ave  $deriv_dir/sub*/func/$mask_ea
3dcalc -datum float -prefix $MMC_dir/$epi_mask -a $MMC_dir/$epi_ave -expr 'ispositive(a-0.499)'

# remove average
rm $MMC_dir/$epi_ave

# define string for GM mask in EPI resolution and MNI space (note: this mask is the same for task and rest)
mask_gm=*_task-rest.results/follow_ROI_FSGMe+tlrc.BRIK.gz

# create average EPI masks restingstate: Combine individual EPI automasks into a group mask
3dMean -datum float -prefix $MMC_dir/$gm_ave  $deriv_dir/afni_proc/sub-*/$mask_gm
3dcalc -datum float -prefix $MMC_dir/$gm_mask -a $MMC_dir/$gm_ave -expr 'ispositive(a-0.09)'

# remove average
rm $MMC_dir/$gm_ave

############### create Brodman Areal map in MNI space ###############

cd $MMC_dir
3dresample -master $gm_mask -prefix BA_MNI.nii.gz -input /storage/shared/research/cinn/2018/MAGMOT/derivatives/ROI_masks/input/Mai_Brodmann/Brodmann_Mai_Matajnik.nii.gz

