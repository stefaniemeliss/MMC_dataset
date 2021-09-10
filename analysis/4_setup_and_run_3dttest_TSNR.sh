#!/bin/bash
source ~/.bashrc

# this code runs a whole brain seed-based functional connectivity analysis using the same precuneus seed as afni qc does as seed to determine areas that exhibit functional connectivity

# define directories
BIDS_dir="$path"/rawdata
deriv_dir=$path/derivatives

anal_dir=$deriv_dir/analysis
MMC_dir=$anal_dir/MMC_paper

tsnr_dir=$MMC_dir/tsnr
mkdir -p $tsnr_dir

code_dir=$path/code/neuro-MMC/analysis

# define which template to use and where to find them
template=MNI152_2009_template_SSW.nii.gz
template_path=`@FindAfniDsetPath $template`

# change directory to BIDS folder
cd $BIDS_dir

# define subjects based on folder names in the BIDS directory
subjects=($(ls -d sub*))
#subjects=(sub-control001)
# sort array
subjects=($(echo ${subjects[*]}| tr " " "\n" | sort -n))

# go to tsnr folder
cd $tsnr_dir
clustsim=true

# cope template to use as underlay
if [ ! -f "$template" ]; then
    cp $template_path/$template .
fi

############### specify masks and p value ###############

# specify mask (created in previous script)
epi_mask=sample_label-dilatedGM_mask.nii.gz
gm_mask=sample_label-gm_mask.nii.gz

# define number of voxel in mask
nvox=$(3dBrickStat -count -non-zero $MMC_dir/$gm_mask)
ntests=8
ntot=$(echo "$nvox * $ntests" | bc -l)

# bonferoni correction
p=0.05
p_cor=$(echo "$p / $ntot " | bc -l)
echo $p_cor

############### copy tsnr maps and create an average tsnr map for each subject ###############

# copy all tsnr files
cp $deriv_dir/afni_proc/sub*/sub*task-rest.results/TSNR.*_task-rest+tlrc*  $tsnr_dir
cp $deriv_dir/afni_proc/sub*/sub*task-magictrickwatching.results/TSNR.*_task-magictrickwatching+tlrc*  $tsnr_dir

# create mean tsnr map for each each subject

for subject in "${subjects[@]}"; do

	echo $subject

	tsnr_rest=TSNR."$subject"*_task-rest+tlrc*
	tsnr_task=TSNR."$subject"*_task-magictrickwatching+tlrc*

	3dMean -prefix TSNR.combined."$subject" $tsnr_rest $tsnr_task 

done

############### One Sample t-test for each task seperately ###############

# run one sample t-test for each task
if ($clustsim); then 
	3dttest++ -setA TSNR*rest* -labelA "rest" -mask $MMC_dir/$gm_mask -prefix 1sample_rest -Clustsim
	3dttest++ -setA TSNR*magictrickwatching* -labelA "task" -mask $MMC_dir/$gm_mask -prefix 1sample_task -Clustsim
else
	3dttest++ -setA TSNR*rest* -labelA "rest" -mask $MMC_dir/$gm_mask -prefix 1sample_rest
	3dttest++ -setA TSNR*magictrickwatching* -labelA "task" -mask $MMC_dir/$gm_mask -prefix 1sample_task
fi


# compute similarity between task and rest
corr_TSNR=$(3ddot 1sample_rest+tlrc[0] 1sample_task+tlrc[0])
echo $corr_TSNR
corr_TSNR=$(3ddot 1sample_rest+tlrc[1] 1sample_task+tlrc[1])
echo $corr_TSNR

# create images (FIGURE 5)
#@chauffeur_afni -ulay $template -olay 1sample_rest+tlrc -thr_olay_p2stat $p_cor -thr_olay_pside 2sided -set_subbricks 0 0 1 -cbar Spectrum:red_to_blue -pbar_posonly -prefix 1sample_rest -pbar_saveim 1sample_rest_pbar.png -pbar_dim 64x1351H -func_range 350 -opacity 6 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 2 -box_focus_slices AMASK_FOCUS_OLAY

#@chauffeur_afni -ulay $template -olay 1sample_task+tlrc -thr_olay_p2stat $p_cor -thr_olay_pside 2sided -set_subbricks 0 0 1 -cbar Spectrum:red_to_blue -pbar_posonly -prefix 1sample_task -pbar_saveim 1sample_task_pbar.png -pbar_dim 64x1351H -func_range 350 -opacity 6 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 2 -box_focus_slices AMASK_FOCUS_OLAY

############### One Sample t-test for combined tSNR ###############

# run one sample t-test for each task
if ($clustsim); then 
	3dttest++ -setA TSNR.combined* -labelA "combined" -mask $MMC_dir/$gm_mask -prefix 1sample_combined -Clustsim
else
	3dttest++ -setA TSNR.combined* -labelA "combined" -mask $MMC_dir/$gm_mask -prefix 1sample_combined
fi


# create image (FIGURE 5)
@chauffeur_afni -ulay $template -olay 1sample_combined+tlrc -thr_olay_p2stat $p_cor -thr_olay_pside 2sided -set_subbricks 0 0 1 -cbar Spectrum:red_to_blue -pbar_posonly -prefix 1sample_combined -pbar_saveim 1sample_combined_pbar.png -pbar_dim 64x1351H -func_range 350 -opacity 6 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 2 -box_focus_slices AMASK_FOCUS_OLAY

############### Paired Sample t-test for whole sample ###############

if ($clustsim); then 
	3dttest++ -setA TSNR*rest* -setB TSNR*magictrickwatching* -labelA "rest" -labelB "task" -paired -mask $MMC_dir/$gm_mask -prefix 2sample_paired -Clustsim
else
	3dttest++ -setA TSNR*rest* -setB TSNR*magictrickwatching* -labelA "rest" -labelB "task" -paired -mask $MMC_dir/$gm_mask -prefix 2sample_paired
fi

############### Two Sample t-test for each task seperately and the combined maps ###############


# define groups
g1=control
g2=experimental

# run 3dttest++ with Clustsim for thresholding
if ($clustsim); then 
	#3dttest++ -setA TSNR*$g1*rest* -setB TSNR*$g2*rest* -labelA $g1 -labelB $g2 -unpooled -mask $MMC_dir/$gm_mask -prefix 2sample_rest -Clustsim
	#3dttest++ -setA TSNR*$g1*magictrickwatching* -setB TSNR*$g2*magictrickwatching* -labelA $g1 -labelB $g2 -unpooled -mask $MMC_dir/$gm_mask -prefix 2sample_task -Clustsim
	3dttest++ -setA TSNR.combined*$g1* -setB TSNR.combined*$g2* -labelA $g1 -labelB $g2 -unpooled -mask $MMC_dir/$gm_mask -prefix 2sample_combined -ClustSim
else
	#3dttest++ -setA TSNR*$g1*rest* -setB TSNR*$g2*rest* -labelA $g1 -labelB $g2 -unpooled -mask $MMC_dir/$gm_mask -prefix 2sample_rest
	#3dttest++ -setA TSNR*$g1*magictrickwatching* -setB TSNR*$g2*magictrickwatching* -labelA $g1 -labelB $g2 -unpooled -mask $MMC_dir/$gm_mask -prefix 2sample_task
	3dttest++ -setA TSNR.combined*$g1* -setB TSNR.combined*$g2* -labelA $g1 -labelB $g2 -unpooled -mask $MMC_dir/$gm_mask -prefix 2sample_combined
fi


# extract cluster
#3dClusterize -inset 2sample_rest+tlrc -ithr 1 -NN 1 -2sided p=$p_cor -clust_nvox 2 -binary -pref_map Cluster_rest.nii.gz -mask $MMC_dir/$gm_mask 
#3dClusterize -inset 2sample_task+tlrc -ithr 1 -NN 1 -2sided p=$p_cor -clust_nvox 2 -binary -pref_map Cluster_task.nii.gz -mask $MMC_dir/$gm_mask

3dClusterize -inset 2sample_combined+tlrc -ithr 1 -NN 1 -2sided p=$p_cor -clust_nvox 2 -binary -pref_map Cluster_combined.nii.gz -mask $MMC_dir/$gm_mask 

# extract values for each subject
#3dmaskdump -mask Cluster_rest.nii.gz -xyz -index -o out_rest TSNR*rest*.HEAD
#3dmaskdump -mask Cluster_task.nii.gz -xyz -index -o out_task TSNR*magictrickwatching*.HEAD

# extract values
3dmaskave -mask Cluster_combined.nii.gz 2sample_combined+tlrc[0]

rm TSNR*+tlrc*
