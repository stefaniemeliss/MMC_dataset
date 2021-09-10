#!/bin/bash

source ~/.bashrc


# define path
path="/storage/shared/research/cinn/2018/MAGMOT"

# define directories
deriv_dir=$path/derivatives
anal_dir=$deriv_dir/analysis
MMC_dir=$anal_dir/MMC_paper

ISC_dir=$MMC_dir/ISC
mkdir -p $ISC_dir
cd $ISC_dir

ISC_path=$deriv_dir/ISC

code_dir=$path/code/neuro-MMC/analysis

# define which template to use and where to find them
template=MNI152_2009_template_SSW.nii.gz
rm $ISC_dir/$template
template_path=`@FindAfniDsetPath $template`
3dcopy $template_path/$template $ISC_dir/$template

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

############### create ISC command ###############

cd $ISC_dir

cp $code_dir/dataTable_magictrickwatching.txt ./dataTable_magictrickwatching.txt

# copy ISC maps
cp $ISC_path/ISC_sub*sub*_task-magictrickwatching_z.nii.gz  $ISC_dir

# specify and run 3dISC command
3dISC -prefix ISC_magictrickwatching -jobs 2                       \
      -model  '1+(1|Subj1)+(1|Subj2)'            \
	  -mask $MMC_dir/$gm_mask  \
	  -dataTable @dataTable_magictrickwatching.txt  


# copy ClustSim output
cp $CS_dir/ClustSim_magictrickwatching* ./

# copy information from 3dClustSim into files
3drefit -atrstring 'AFNI_CLUSTSIM_NN1_1sided' file:ClustSim_magictrickwatching.NN1_1sided.niml  \
    -atrstring AFNI_CLUSTSIM_NN2_1sided file:ClustSim_magictrickwatching.NN2_1sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN3_1sided file:ClustSim_magictrickwatching.NN3_1sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN1_2sided file:ClustSim_magictrickwatching.NN1_2sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN2_2sided file:ClustSim_magictrickwatching.NN2_2sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN3_2sided file:ClustSim_magictrickwatching.NN3_2sided.niml      \
    -atrstring AFNI_CLUSTSIM_NN1_bisided file:ClustSim_magictrickwatching.NN1_bisided.niml    \
    -atrstring AFNI_CLUSTSIM_NN2_bisided file:ClustSim_magictrickwatching.NN2_bisided.niml    \
    -atrstring AFNI_CLUSTSIM_NN3_bisided file:ClustSim_magictrickwatching.NN3_bisided.niml    \
    ISC_magictrickwatching+tlrc

rm ClustSim_magictrickwatching*

############### create binary masks for eac resting state network ###############

# threshold output so that only voxel with significant correlation after bonferroni correction survive  --> creates mask
# clust alpha (0.05) = 5
3dClusterize -inset ISC_magictrickwatching+tlrc -ithr 1 -NN 1 -binary -2sided p=$p_cor -clust_nvox 3 -pref_map mask_ISC_magictrickwatching.nii.gz -mask $MMC_dir/$gm_mask

# use mask to multiply it with output of sFC
3dcalc -a mask_ISC_magictrickwatching.nii.gz -b ISC_magictrickwatching+tlrc[0] -expr 'a*b' -prefix masked_ISC.nii.gz
3dcalc -a mask_ISC_magictrickwatching.nii.gz -b ISC_magictrickwatching+tlrc[1] -expr 'a*b' -prefix masked_ISC_t.nii.gz
3dcalc -a mask_ISC_magictrickwatching.nii.gz -b $MMC_dir/BA_MNI.nii.gz -expr 'a*b' -prefix masked_ISC_BA.nii.gz

# put them all together
3dcopy mask_ISC_magictrickwatching.nii.gz  out_ISC_magictrickwatching
3dbucket masked_ISC_BA.nii.gz -glueto out_ISC_magictrickwatching+tlrc
3dbucket masked_ISC_t.nii.gz -glueto out_ISC_magictrickwatching+tlrc
3dbucket masked_ISC.nii.gz -glueto out_ISC_magictrickwatching+tlrc

# declare sub-brick to be t values
3drefit -substatpar 1 fitt  out_ISC_magictrickwatching+tlrc

# rename sub-bricks
3drefit -sublabel 0 "ISC" -sublabel 1 "ISC_t" -sublabel 2 "ISC_BA" -sublabel 3 "mask" out_ISC_magictrickwatching+tlrc

# ISC map thresholded but not cluster-extent corrected
@chauffeur_afni -ulay $template -olay ISC_magictrickwatching+tlrc -thr_olay_p2stat $p_cor -thr_olay_pside 2sided -set_subbricks 0 0 1 -cbar Spectrum:red_to_blue -pbar_posonly -prefix ISC -pbar_saveim ISC_pbar.png -pbar_dim 64x1351H -func_range 0.2 -opacity 6 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 2 -box_focus_slices AMASK_FOCUS_OLAY

# ISC map thresholded and cluster extent corrected (Figure 6)
@chauffeur_afni -ulay $template -olay out_ISC_magictrickwatching+tlrc -thr_olay_p2stat $p_cor -thr_olay_pside 2sided -set_subbricks 0 0 1 -cbar Spectrum:red_to_blue -pbar_posonly -prefix out_ISC -pbar_saveim out_ISC_pbar.png -pbar_dim 64x1351H -func_range 0.2 -opacity 6 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 2 -box_focus_slices AMASK_FOCUS_OLAY

# ISC map thresholded and cluster extent corrected with alpha (Figure 7)
@chauffeur_afni -ulay $template -olay out_ISC_magictrickwatching+tlrc -thr_olay 0.1 -olay_alpha Yes -olay_boxed Yes -thr_olay_pside 2sided -set_subbricks 0 0 0 -cbar amber_monochrome -pbar_posonly -prefix out_ISC_box -pbar_saveim out_ISC_box_pbar.png -pbar_dim 64x1351H -func_range 0.3 -opacity 9 -label_mode 1 -label_setback 0.5 -label_color black -zerocolor white -montx 7 -monty 1 -box_focus_slices AMASK_FOCUS_OLAY


