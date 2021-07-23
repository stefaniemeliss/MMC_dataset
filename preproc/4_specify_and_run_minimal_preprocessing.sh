#!/bin/tcsh
source ~/.cshrc

################################################################################
# pre-processing for functional data using anfi_proc.py
################################################################################

# --------------------------------------------------------------------
# Script: s.2016_ChenEtal_02_ap.tcsh
#
# From:
# Chen GC, Taylor PA, Shin Y-W, Reynolds RC, Cox RW (2016). Untangling
# the Relatedness among Correlations, Part II: Inter-Subject
# Correlation Group Analysis through Linear Mixed-Effects
# Modeling. Neuroimage (in press).
#
# Originally run using: AFNI_16.1.16
# --------------------------------------------------------------------

# further modified based on Example 11. (see afni_proc.py -help)

# FMRI processing script, ISC movie data.
# Assumes previously run FS and SUMA commands, respectively:
# $ recon-all -all -subject $subj -i $anat
# $ @SUMA_Make_Spec_FS -sid $subj -NIFTI

# Set top level directory structure
cd ~
set topdir = ~/Dropbox/Reading/PhD/Magictricks/fmri_study/MMC #study folder
echo $topdir
set desc = minpreproc
set derivroot = $topdir/derivatives
set outroot = $derivroot/afni_proc

# define subject listecho $
set BIDSdir = $topdir/rawdata

cd $BIDSdir
set subjects	=(`ls -d sub*`) # this creates an array containing all subjects in the BIDS directory
#set subjects	=(`ls -d sub-control*`) # this creates an array containing all subjects in the BIDS directory
#set subjects	=(`ls -d sub-experimental*`) # this creates an array containing all subjects in the BIDS directory
echo $subjects
echo $#subjects

#set subjects	= sub-experimental005
#set subjects	= sub-control002

# create header of TSNR output file
echo "scan\tTSNR" > $outroot/data_TSNR.txt

echo "scan\tdL\tdP\tdS\tpitch\troll\tyaw" > $outroot/data_motion.txt

echo "scan\txmin\txmax\tymin\tymax\tzmin\tzmax" > $outroot/data_extents.txt


# for each subject in the subjects array
foreach subj ($subjects)

	#set subj	= "sub-experimental005"
	echo $subj

	# Output directory: name for output
	set outdir  = $outroot/$subj
	cd $outdir # define PWD in which the script and results should get saved

	# Input directory: anatomical derivatives
	set derivindir = $derivroot/$subj/anat

	# Input directory: SSWarper output (anatomical non-linear aligned to MNI)
	set sswindir = $outdir/SSwarper

	# Input data: FreeSurfer results (anatomy, ventricle and WM maps)
	# all these files are in the ../derivatives/FreeSurfer/$SUBJ_ID/SUMA directory

	# as a last step, move anat_with_skull (anatUAC) anat anat_without_skull (anatSS) into derivatives folder
	set anatSS = "${subj}"_space-orig_desc-skullstripped_T1w.nii.gz

	# Input directory: unprocessed FMRI data
	set indir   = $BIDSdir/$subj/func

	# Input data: list of partitioned EPIs (movie clips)
	set epi_dpattern = $indir"/*.nii.gz"
	set epi_files = (`ls $epi_dpattern | xargs -n 1 basename`)

	echo $epi_files

	# for each subject in the subjects array
	foreach epi ($epi_files)

		echo $epi

		# define epi_id to use as subj_id
		set epi_id = ( ` echo $epi | sed 's/_bold.nii.gz//'` )
		echo $epi_id

	# specify actual afni_proc.py
	afni_proc.py -subj_id $epi_id																						\
	    -blocks despike tshift align volreg mask         										\
	    -copy_anat $derivindir/$anatSS                                       	\
			-anat_has_skull no																									\
	    -anat_follower_ROI aaseg  anat $sswindir/desikan_shft.nii.gz				\
	    -anat_follower_ROI aeseg  epi  $sswindir/desikan_shft.nii.gz				\
	    -anat_follower_ROI FSvent epi  $sswindir/vent_shft.nii.gz           \
		  -anat_follower_ROI FSWMe  epi  $sswindir/wm_shft.nii.gz							\
	    -anat_follower_ROI FSGMe  epi  $sswindir/gm_shft.nii.gz							\
	    -dsets $indir/$epi                                                	\
	    -tcat_remove_first_trs 0                                            \
			-tshift_opts_ts -tpattern altplus																		\
      -align_opts_aea -cost lpc+ZZ -giant_move            								\
	    -volreg_align_to MIN_OUTLIER                                        \
	    -volreg_align_e2a                                                   \
			-volreg_compute_tsnr yes																						\
			-mask_epi_anat yes																									\
			-html_review_style pythonic

	# trpattern = altplus due to slice_code = 3 (i.e. interleaved ascending) and slice_start = 0 in DICOM header

	# execute script
	tcsh -xef proc."${epi_id}" |& tee output.proc."${epi_id}".txt

  set output_dir = $epi_id.results
	cd $output_dir

	############################################################################
	# once the minimal pre-processing has finished, compute and extract motion #
	############################################################################

	# rearrange motion columns
	# from roll pitch yaw interior-superior right-left anterior-posterior
	# to right-left anterior-posterior inferior-superior pitch roll yaw
	awk '{printf("%f\t%f\t%f\t%f\t%f\t%f\n", $5, $6, $4, $2, $1, $3)}' dfile_rall.1D > motion.$epi_id

	# create files that have file name as first column and motion values as second column, once just for this run and once in the root directory for ALL scans
	awk -F, 'BEGIN{print "scan", "\t", "dL", "\t", "dP", "\t", "dS", "\t", "pitch", "\t", "roll", "\t", "yaw"}{print FILENAME"\t"$0}' motion.$epi_id > absolute.motion.$epi_id.txt
	awk -F, '{print FILENAME"\t"$0}' motion."$epi_id" >> $outdir/"$subj".motion.txt
	awk -F, '{print FILENAME"\t"$0}' motion."$epi_id" >> $outroot/data_motion.txt


	############################################################################
	# quantify overlap between anatomical and EPI coverage #
	############################################################################

	# create brainstem mask
	3dcalc -a follow_ROI_aeseg+orig. -datum byte -prefix mask_brainstem -expr 'amongst(a,13)'

	# make mask from FS parcelation
	3dmask_tool -input follow_ROI_aeseg+orig. -prefix mask_aeseg -fill_holes

	# create mask without brainstem
	3dcalc -a mask_aeseg+orig. -b mask_brainstem+orig. -expr 'a-b' -prefix mask_FS

	# dilate mask and fill holes
	3dmask_tool -input mask_FS+orig. -prefix mask_brain -fill_holes -dilate_inputs 1 -1

	# intersect EPI brain mask and FS parc mask
	3dmask_tool -input mask_brain+orig. full_mask."$epi_id"+orig. -inter -prefix mask_epi_brain

	# compute extents of both masks
	3dAutobox -extent_ijk_to_file extents_brain_"$epi_id" mask_brain+orig
	3dAutobox -extent_ijk_to_file extents_epi_"$epi_id" mask_epi_brain+orig

	# replace spaces
	sed 's/       /\t/g' extents_brain_"$epi_id" > brain_"$epi_id"
	sed 's/       /\t/g' extents_epi_"$epi_id" > epi_"$epi_id"

	# summarise information in file
	awk -F, '{print FILENAME"\t"$0}' brain_"$epi_id" >> $outroot/data_extents.txt
	awk -F, '{print FILENAME"\t"$0}' epi_"$epi_id" >> $outroot/data_extents.txt

	##########################################################################
	# once the minimal pre-processing has finished, compute and extract tSNR #
	##########################################################################

    ##### compute subject mask that includes dilated GM (slightly touching WM & ventricle) in epi grid ###

    # dilate subject anatomy mask (mask_anat.$subj_$task+tlrc is already in MNI space and on EPI grid)
    3dmask_tool -dilate_inputs 2 -2 -fill_holes -input mask_aeseg+orig. -prefix mask_aeseg_dilated."$epi_id"+orig.

    # remove eroded WM and eroded ventricle masks (anatomical follower, already in MI space & anatomical grid)
    3dcalc -a mask_aeseg_dilated."$epi_id"+orig. -b follow_ROI_FSWMe+orig. -c follow_ROI_FSvent+orig. -expr 'a-b-c' \
        -prefix "$epi_id"_space-orig_res-epi_label-dilatedGM_mask.nii.gz

    # remove dilated subject anatomy mask
    #rm $output_dir/mask_anat_dilated."$subj"_task-"$task"+tlrc.*

	# use the created map to extract the tSNR values
	3dmaskdump -mask "$epi_id"_space-orig_res-epi_label-dilatedGM_mask.nii.gz -o values.TSNR."$epi_id" -noijk TSNR.vreg.r01."$epi_id"+orig.BRIK

	# create files that have file name as first column and TSNR values as second column, once just for this run and once in the root directory for ALL scans
	awk -F, 'BEGIN{print "scan", "\t", "TSNR"}{print FILENAME"\t"$0}' values.TSNR."$epi_id" > TSNR.$epi_id.txt
	awk -F, '{print FILENAME"\t"$0}' values.TSNR."$epi_id" >> $outdir/"$subj".TSNR.txt
	awk -F, '{print FILENAME"\t"$0}' values.TSNR."$epi_id" >> $outroot/data_TSNR.txt


	# go back to outdir
	cd $outdir


	end


end
