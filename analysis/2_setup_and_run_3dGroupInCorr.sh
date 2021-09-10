#!/bin/bash

# this code runs a whole brain seed-based functional connectivity analysis using the same precuneus seed as afni qc does as seed to determine areas that exhibit functional connectivity

# define path
path="/storage/shared/research/cinn/2018/MAGMOT"

# define directories
deriv_dir=$path/derivatives

anal_dir=$deriv_dir/analysis
MMC_dir=$anal_dir/MMC_paper

CS_dir=$anal_dir/3dClustSim

FC_dir=$MMC_dir/sFC
mkdir -p $FC_dir

code_dir=$path/code/neuro-MMC/analysis/

task=rest

# define which template to use and where to find them
template=MNI152_2009_template_SSW.nii.gz
template_path=`@FindAfniDsetPath $template`

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

############### create spherical ROIs ###############

cd $FC_dir

# copy template to directory
if [ ! -f "$template" ]; then
    cp $template_path/$template $FC_dir/
fi

# resample template to RAI orientation
3dresample -orient RAI -prefix t1_MNI_RAI.nii.gz -input $template

# create files with coordinates X_COORD Y_COORD Z_COORD VALUE SPHERE_RADIUS
echo "5 49 40 1 6" > lh-PCC.txt
echo "-4 91 -3 1 6" > rh-cort-vis.txt
echo "64 12 2 1 6" > lh-cort-aud.txt

# create spherical ROI
3dUndump -prefix t1_lh-PCC.nii.gz -master t1_MNI_RAI.nii.gz -xyz lh-PCC.txt
3dUndump -prefix t1_rh-cort-vis.nii.gz -master t1_MNI_RAI.nii.gz -xyz rh-cort-vis.txt
3dUndump -prefix t1_lh-cort-aud.nii.gz -master t1_MNI_RAI.nii.gz -xyz lh-cort-aud.txt

# resample to EPI grid
3dresample -master $MMC_dir/$epi_mask -prefix lh-PCC.nii.gz -input t1_lh-PCC.nii.gz
3dresample -master $MMC_dir/$epi_mask -prefix rh-cort-vis.nii.gz -input t1_rh-cort-vis.nii.gz
3dresample -master $MMC_dir/$epi_mask -prefix lh-cort-aud.nii.gz -input t1_lh-cort-aud.nii.gz
3dresample -master $MMC_dir/$epi_mask -prefix MNI_RAI.nii.gz -input t1_MNI_RAI.nii.gz 

rm t1_*


############### create binary masks for eac resting state network ###############

cd "$deriv_dir"/ROI_masks/input/Yeo_JNeurophysiol11_MNI152/
rm AFNI*

# 1. resample to AFNI template
3dresample -prefix AFNI_FSL_MNI152_FreeSurferConformed_1mm.nii.gz -master $MMC_dir/$epi_mask -input FSL_MNI152_FreeSurferConformed_1mm.nii.gz
3dresample -prefix AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -master $MMC_dir/$epi_mask -input Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii.gz
3dresample -prefix AFNI_Yeo2011_17Networks_MNI152_liberal.nii.gz -master $MMC_dir/$epi_mask -input Yeo2011_17Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii.gz

# 2. refit from orig to MNI space
3drefit -space MNI AFNI_FSL_MNI152_FreeSurferConformed_1mm.nii.gz
3drefit -space MNI AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz
3drefit -space MNI AFNI_Yeo2011_17Networks_MNI152_liberal.nii.gz

# 3. create all 7 networks liberal
3dcalc -a AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -expr 'amongst(a,1)' -short -prefix AFNI_Yeo2011_network1_visual_liberal.nii.gz
3dcalc -a AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -expr 'amongst(a,2)' -short -prefix AFNI_Yeo2011_network2_somatomotor_liberal.nii.gz
#3dcalc -a AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -expr 'amongst(a,3)' -short -prefix AFNI_Yeo2011_network3_dorsalattention_liberal.nii.gz
#3dcalc -a AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -expr 'amongst(a,4)' -short -prefix AFNI_Yeo2011_network4_ventralattention_liberal.nii.gz
#3dcalc -a AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -expr 'amongst(a,5)' -short -prefix AFNI_Yeo2011_network5_limbic_liberal.nii.gz
#3dcalc -a AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -expr 'amongst(a,6)' -short -prefix AFNI_Yeo2011_network6_frontoparietal_liberal.nii.gz
3dcalc -a AFNI_Yeo2011_7Networks_MNI152_liberal.nii.gz -expr 'amongst(a,7)' -short -prefix AFNI_Yeo2011_network7_default_liberal.nii.gz

# 4. copy files to FC_dir
rm $FC_dir/AFNI*
3dcopy AFNI_Yeo2011_network1_visual_liberal.nii.gz $FC_dir/AFNI_Yeo2011_network1_visual_liberal.nii.gz
3dcopy AFNI_Yeo2011_network2_somatomotor_liberal.nii.gz $FC_dir/AFNI_Yeo2011_network2_somatomotor_liberal.nii.gz
3dcopy AFNI_Yeo2011_network7_default_liberal.nii.gz $FC_dir/AFNI_Yeo2011_network7_default_liberal.nii.gz

############### set up the file used to compute correlations (pearson) ###############

cd "$deriv_dir" # change directory to where pre-processed files are

# define prefix
out_GroupInCorr=FC_task-"$task"_wholebrain_pearson

# set up FC for LL 
3dSetupGroupInCorr -mask $MMC_dir/$epi_mask -prefix "$FC_dir"/$out_GroupInCorr -byte ./sub-*/func/*_task-"$task"_desc-fullpreproc_bold.nii.gz


############### compute functional connectivity using the three seeds ###############

cd "$FC_dir"

# copy ClustSim output
cp $CS_dir/ClustSim_rest* "$FC_dir"/

# compute whole brain connectivity with HPC seed using smoothed data
3dGroupInCorr -setA "$FC_dir"/$out_GroupInCorr.grpincorr.niml -verb -batch MASKAVE "$code_dir"/seeds_MMC

############### copy output from 3dClustSim to output from seed based correlations ###############

# define seeds
seeds=(seedFC_aud seedFC_vis seedFC_pcc)
num_seeds=${#seeds[@]}


rm Cluster* corr_* all_*

for (( r=0; r<${num_seeds}; r++)); do

	echo "${seeds[$r]}"

    # 0th sub brick shows mean of arctanh(correlation)
    # 1st sub brick shows Z score of t-statistic for above mean

    3dcopy ${seeds[$r]}+tlrc all_${seeds[$r]}+tlrc

    # compute actual correlation values
    3dcalc -a all_${seeds[$r]}+tlrc[0] -expr 'tanh(a)' -prefix corr_${seeds[$r]}

    # append volume
    3dTcat all_${seeds[$r]}+tlrc -glueto corr_${seeds[$r]}+tlrc

	# remove file
	rm all_${seeds[$r]}+tlrc*

	# threshold output so that only voxel with significant correlation after bonferroni correction survive  --> creates mask
	# clust alpha (0.05) = 3
    3dClusterize -inset corr_"${seeds[$r]}"+tlrc -ithr 1 -NN 1 -binary -2sided p=$p_cor -clust_nvox 3 -pref_map mask_pcor_"${seeds[$r]}".nii.gz -mask $MMC_dir/$gm_mask

	# use mask to multiply it with output of sFC
	3dcalc -a mask_pcor_"${seeds[$r]}".nii.gz -b corr_"${seeds[$r]}"+tlrc[0] -expr 'a*b' -prefix mean_arctanh_corr_"${seeds[$r]}".nii.gz
	3dcalc -a mask_pcor_"${seeds[$r]}".nii.gz -b corr_"${seeds[$r]}"+tlrc[1] -expr 'a*b' -prefix mean_zscore_corr_"${seeds[$r]}".nii.gz
	3dcalc -a mask_pcor_"${seeds[$r]}".nii.gz -b corr_"${seeds[$r]}"+tlrc[2] -expr 'a*b' -prefix mean_corr_"${seeds[$r]}".nii.gz

	# put them all together: this file only contains significant voxels (Bonferroni-corrected)
	3dcopy mask_pcor_"${seeds[$r]}".nii.gz out_"${seeds[$r]}"
	3dbucket mean_corr_"${seeds[$r]}".nii.gz -glueto out_"${seeds[$r]}"+tlrc
	3dbucket mean_zscore_corr_"${seeds[$r]}".nii.gz -glueto out_"${seeds[$r]}"+tlrc
	3dbucket mean_arctanh_corr_"${seeds[$r]}".nii.gz -glueto out_"${seeds[$r]}"+tlrc
	
	# declare sub-brick to be z values
    3drefit -substatpar 1 fizt  out_"${seeds[$r]}"+tlrc

	# rename sub-bricks
	3drefit -sublabel 0 "mean_arctanh_corr" -sublabel 1 "mean_zscore_corr" -sublabel 2 "mean_corr" out_"${seeds[$r]}"+tlrc

	# remove file
	rm corr_${seeds[$r]}+tlrc*

    # copy information from 3dClustSim into files
    3drefit -atrstring 'AFNI_CLUSTSIM_NN1_1sided' file:ClustSim_rest.NN1_1sided.niml  \
    -atrstring AFNI_CLUSTSIM_NN2_1sided file:ClustSim_rest.NN2_1sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN3_1sided file:ClustSim_rest.NN3_1sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN1_2sided file:ClustSim_rest.NN1_2sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN2_2sided file:ClustSim_rest.NN2_2sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN3_2sided file:ClustSim_rest.NN3_2sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN1_bisided file:ClustSim_rest.NN1_bisided.niml    \
    -atrstring AFNI_CLUSTSIM_NN2_bisided file:ClustSim_rest.NN2_bisided.niml    \
    -atrstring AFNI_CLUSTSIM_NN3_bisided file:ClustSim_rest.NN3_bisided.niml    \
    out_${seeds[$r]}+tlrc

    # save thresholded map
    3dClusterize -inset out_"${seeds[$r]}"+tlrc -ithr 2 -NN 1 -binary -2sided -0.3 0.3 -clust_nvox 3 -pref_map Cluster_"${seeds[$r]}".nii.gz -mask $MMC_dir/$gm_mask
    
    # multiply thresholded map with BA map
    3dcalc -a $MMC_dir/BA_MNI.nii.gz -b Cluster_"${seeds[$r]}".nii.gz -expr 'a*b' -prefix BA_"${seeds[$r]}".nii.gz

done

# remove clustsim output
rm $FC_dir/ClustSim_rest*

############### compute Dice coefficients for each network ###############

rm dice*

echo "precuneus seed"
dice_pcc=$(3ddot -dodice Cluster_seedFC_pcc.nii.gz AFNI_Yeo2011_network7_default_liberal.nii.gz)
echo $dice_pcc
echo "auditory seed"
dice_aud=$(3ddot -dodice Cluster_seedFC_aud.nii.gz AFNI_Yeo2011_network2_somatomotor_liberal.nii.gz)
echo $dice_aud
echo "visual seed"
dice_vis=$(3ddot -dodice Cluster_seedFC_vis.nii.gz AFNI_Yeo2011_network1_visual_liberal.nii.gz)
echo $dice_vis

# put all maps in one file as sub-bricks
rm out_networks+tlrc*
3dcopy BA_seedFC_pcc.nii.gz out_networks
3dbucket BA_seedFC_aud.nii.gz -glueto out_networks+tlrc
3dbucket BA_seedFC_vis.nii.gz -glueto out_networks+tlrc
3dbucket Cluster_seedFC_pcc.nii.gz -glueto out_networks+tlrc
3dbucket Cluster_seedFC_aud.nii.gz -glueto out_networks+tlrc
3dbucket Cluster_seedFC_vis.nii.gz -glueto out_networks+tlrc
3dbucket AFNI_Yeo2011_network7_default_liberal.nii.gz -glueto out_networks+tlrc
3dbucket AFNI_Yeo2011_network2_somatomotor_liberal.nii.gz -glueto out_networks+tlrc
3dbucket AFNI_Yeo2011_network1_visual_liberal.nii.gz -glueto out_networks+tlrc

# rename sub-bricks
3drefit -sublabel 0 "network1_visual" -sublabel 1 "network2_somatosensory" -sublabel 2 "network7_default" -sublabel 3 "sFC_vis" -sublabel 4 "sFC_aud" -sublabel 5 "sFC_pcc" -sublabel 6 "BA_vis" -sublabel 7 "BA_aud" -sublabel 8 "BA_pcc" out_networks+tlrc

# compute dice coefficients and plot the matrix
3ddot -NIML -dodice out_networks+tlrc  > dicemat.1D
1dRplot -save dice.jpg -i dicemat.1D

############### compute size of seed spheres and overlap with network ###############

# create output file
printf "seed\tdice\tvoxel B\t voxel (A int B)\t%(B \\ A)" > "$FC_dir"/data_sFC.txt 

### precuneus seed ###
# add seed name and dice coef to file
printf "\nprecuneus\t$dice_pcc" >> "$FC_dir"/data_sFC.txt 

# add mask size and % non-overlap
3dABoverlap -no_automask $FC_dir/AFNI_Yeo2011_network7_default_liberal.nii.gz $FC_dir/lh-PCC.nii.gz > out.aboverlap.txt
out_ab=$(awk 'NR==3' out.aboverlap.txt)
echo $out_ab > out.aboverlap.txt

awk '{printf("%d\t%d\t%f", $2, $4, $8)}' out.aboverlap.txt >> "$FC_dir"/data_sFC.txt
rm out.aboverlap.txt

### auditory seed ###
# add seed name and dice coef to file
printf "\nauditory\t$dice_aud" >> "$FC_dir"/data_sFC.txt 

# add mask size and % non-overlap
3dABoverlap -no_automask $FC_dir/AFNI_Yeo2011_network2_somatomotor_liberal.nii.gz $FC_dir/lh-cort-aud.nii.gz > out.aboverlap.txt
out_ab=$(awk 'NR==3' out.aboverlap.txt)
echo $out_ab > out.aboverlap.txt

awk '{printf("%d\t%d\t%f", $2, $4, $8)}' out.aboverlap.txt >> "$FC_dir"/data_sFC.txt
rm out.aboverlap.txt

### visual seed ###
# add seed name and dice coef to file
printf "\nvisual\t$dice_vis" >> "$FC_dir"/data_sFC.txt 

# add mask size and % non-overlap
3dABoverlap -no_automask $FC_dir/AFNI_Yeo2011_network1_visual_liberal.nii.gz $FC_dir/rh-cort-vis.nii.gz > out.aboverlap.txt
out_ab=$(awk 'NR==3' out.aboverlap.txt)
echo $out_ab > out.aboverlap.txt

awk '{printf("%d\t%d\t%f", $2, $4, $8)}' out.aboverlap.txt >> "$FC_dir"/data_sFC.txt
rm out.aboverlap.txt

# add end of line character to file
printf "\n" >> "$FC_dir"/data_sFC.txt 

############### save images of each network ###############

# create images (FIGURE 7)

# pcc
@chauffeur_afni -ulay $template -olay out_seedFC_pcc+tlrc -thr_olay 0.3 -olay_alpha Yes -olay_boxed Yes -thr_olay_pside 2sided -set_subbricks 0 2 2 -cbar green_monochrome -pbar_posonly -prefix seedFC_pcc -pbar_saveim seedFC_pcc_pbar.png -pbar_dim 64x1351H -func_range 0.6 -opacity 9 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 1 -box_focus_slices AMASK_FOCUS_OLAY
# aud
@chauffeur_afni -ulay $template -olay out_seedFC_aud+tlrc -thr_olay 0.3 -olay_alpha Yes -olay_boxed Yes -thr_olay_pside 2sided -set_subbricks 0 2 2 -cbar red_monochrome -pbar_posonly -prefix seedFC_aud -pbar_saveim seedFC_aud_pbar.png -pbar_dim 64x1351H -func_range 0.6 -opacity 9 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 1 -box_focus_slices AMASK_FOCUS_OLAY
# vis
@chauffeur_afni -ulay $template -olay out_seedFC_vis+tlrc -thr_olay 0.3 -olay_alpha Yes -olay_boxed Yes -thr_olay_pside 2sided -set_subbricks 0 2 2 -cbar blue_monochrome -pbar_posonly -prefix seedFC_vis -pbar_saveim seedFC_vis_pbar.png -pbar_dim 64x1351H -func_range 0.6 -opacity 9 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 1 -box_focus_slices AMASK_FOCUS_OLAY



