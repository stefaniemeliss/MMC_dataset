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
set topdir = /storage/shared/research/cinn/2018/MAGMOT #study folder
echo $topdir

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

# determine variables to regulate flow
set run_preproc = true
set run_after = true

#set subjects	= (sub-experimental024)
#set subjects	= sub-control003
#set subjects	= sub-control017
#set subjects	= sub-experimental032
#set subjects    = (sub-experimental032 sub-experimental034 sub-experimental036 sub-experimental038 sub-experimental040 sub-experimental042 sub-experimental044 sub-experimental046 sub-experimental048 sub-experimental050)


# define tasks to loop through
set tasks = (magictrickwatching rest)
#set tasks = (rest)
#set tasks = (magictrickwatching)

# for each task
foreach task ($tasks)

	# for each subject in the subjects array
	foreach subj ($subjects)

		# determine subjstr
		echo $subj
		set subjstr = "$subj"_task-"$task"

		# Output directory: name for output
		set outdir  = $outroot/$subj
		cd $outdir # define PWD in which the script and results should get saved

		# Input directory: unprocessed FMRI data
		set indir   = $BIDSdir/$subj/func

		# Input directory: anatomical derivatives
		set derivindir = $derivroot/$subj/anat
		set derivoutdir = $derivroot/$subj/func
		mkdir -p $derivoutdir

		# Input directory: SSWarper output (anatomical non-linear aligned to MNI)
		set sswindir = $outdir/SSwarper

		# Input data: FreeSurfer results (anatomy, ventricle and WM maps)
		set anatUAC	= "${subj}"_space-orig_desc-anatUAC_T1w.nii.gz
		set anatSS	= "${subj}"_space-orig_desc-skullstripped_T1w.nii.gz
		#set anatQQ	= "${subj}"_space-MNI152NLin2009cAsym_desc-skullstripped_T1w.nii.gz
		set anatQQ	= anatQQ."${subj}".nii
		#set	warp		= "${subj}"_warp.nii.gz
		set	warp		= anatQQ."${subj}"_WARP.nii
		#set matrix	= "${subj}"_aff12.1D
		set matrix	= anatQQ."${subj}".aff12.1D

		set fsvent = ${subj}_space-orig_label-vent_mask.nii.gz
		set fswm   = ${subj}_space-orig_label-WM_mask.nii.gz
		set fsgm   = ${subj}_space-orig_label-GM_mask.nii.gz
	    set fsparc = ${subj}_space-orig_desc-Destrieux_dseg.nii.gz
	  
        set fsvent = vent.nii.gz
        set fswm   = wm.nii.gz
        set fsgm   = gm.nii.gz
        set fsparc = desikan.nii.gz


		###################################################################################
	    ############################## SET UP PRE-PROCESSING ##############################
	    ###################################################################################

	    if ($run_preproc == true) then

			#echo "run_preproc is true"

			##### determine input files #####

			# Input data: list of partitioned EPIs (movie clips)
            set epi_dpattern = $outdir"/epi_b0_correct/"${subj}"_task-"${task}"_run-*_desc-b0corrected_EPI.nii.gz"
		    echo $epi_dpattern

			# set up different input pattern for sub-experimental016
		    if ($subj == sub-experimental016) then

				if ($task == magictrickwatching) then

				set epi_dpattern = ($outdir"/epi_b0_correct/sub-experimental016_task-magictrickwatching_run-1_desc-b0corrected_EPI.nii.gz" 		\
								    		$outdir"/epi_b0_correct/sub-experimental016_task-magictrickwatching_acq-1_run-2_desc-b0corrected_EPI.nii.gz" 	\
								    		$outdir"/epi_b0_correct/sub-experimental016_task-magictrickwatching_acq-2_run-2_desc-b0corrected_EPI.nii.gz"	\
								    		$outdir"/epi_b0_correct/sub-experimental016_task-magictrickwatching_run-3_desc-b0corrected_EPI.nii.gz")

				endif

			endif

			##### determine minimal outlier in first run to use in volreg #####

			# set up polort depending on task
			if ($task == magictrickwatching) then
				set POLORT = 6
			else
				set POLORT = 5
			endif

			# determine first run
			set first_run = $outdir"/epi_b0_correct/"${subj}"_task-"${task}"_run-1_desc-b0corrected_EPI.nii.gz"
			# run outlier count
			3dToutcount -automask -fraction -polort $POLORT -legendre  $first_run > outcount.first_run.1D
			# determine vol that has min outlier
			set min_out_first_run = `3dTstat -argmin -prefix - outcount.first_run.1D\'`
			# delete file
			rm outcount.first_run.1D

			##### specify actual afni_proc.py #####

			afni_proc.py -subj_id "${subjstr}"																\
			-blocks despike tshift align tlrc volreg mask blur scale regress					            \
			-radial_correlate_blocks tcat volreg															\
			-copy_anat $derivindir/$anatSS																	\
			-anat_has_skull no																				\
			-anat_follower anat_w_skull anat $derivindir/$anatUAC											\
		    -anat_follower_ROI aaseg  anat $sswindir/$fsparc												\
		    -anat_follower_ROI aeseg  epi  $sswindir/$fsparc												\
		    -anat_follower_ROI FSvent epi  $sswindir/$fsvent												\
		    -anat_follower_ROI FSWMe  epi  $sswindir/$fswm													\
		    -anat_follower_ROI FSGMe  epi  $sswindir/$fsgm													\
		    -anat_follower_erode FSvent FSWMe																\
		    -dsets $epi_dpattern																			\
			-outlier_polort $POLORT																			\
		    -tcat_remove_first_trs 0																		\
			-tshift_opts_ts -tpattern altplus																\
	  	    -align_opts_aea -cost lpc+ZZ -giant_move -check_flip											\
	  	    -align_epi_strip_method 3dSkullStrip                                                            \
		    -tlrc_base MNI152_2009_template_SSW.nii.gz														\
		    -tlrc_NL_warp																					\
			-tlrc_NL_warped_dsets $sswindir/$anatQQ															\
			$sswindir/$matrix																				\
			$sswindir/$warp																					\
		    -volreg_base_ind 1 $min_out_first_run															\
	  	    -volreg_post_vr_allin yes																		\
	        -volreg_pvra_base_index MIN_OUTLIER																\
		    -volreg_align_e2a																				\
		    -volreg_tlrc_warp																				\
	        -volreg_no_extent_mask																			\
	        -mask_dilate 8																					\
			-mask_epi_anat yes																				\
			-blur_to_fwhm -blur_size 8																		\
			-regress_motion_per_run																			\
		    -regress_ROI_PC FSvent 3																		\
			-regress_ROI_PC_per_run FSvent																	\
		    -regress_make_corr_vols aeseg FSvent															\
		    -regress_anaticor_fast																			\
		    -regress_anaticor_label FSWMe																	\
		    -regress_censor_motion 0.3																		\
		    -regress_censor_outliers 0.1																	\
		    -regress_apply_mot_types demean deriv															\
		    -regress_est_blur_epits																			\
		    -regress_est_blur_errts																			\
		    -regress_run_clustsim no																		\
			-regress_polort 2																				\
			-regress_bandpass 0.01 1																		\
			-html_review_style pythonic

			# note: regress_polort https://afni.nimh.nih.gov/afni/community/board/read.php?1,165243,165256
			# trpattern = altplus due to slice_code = 3 (i.e. interleaved ascending) and slice_start = 0 in DICOM header

			# execute script
			tcsh -xef proc."${subjstr}" |& tee output.proc."${subjstr}".txt

		endif

		#############################################################################################
		############################# AFTER PRE-PROCESSING HAS FINISHED #############################
		#############################################################################################


	  if ($run_after == true) then

	  	set output_dir = $subjstr.results

	    ##### compute subject mask that includes dilated GM (slightly touching WM & ventricle) in epi grid #####

	    3dcalc -a $output_dir/mask_anat."$subjstr"+tlrc. -b $output_dir/follow_ROI_FSWMe+tlrc. -c $output_dir/follow_ROI_FSvent+tlrc. -expr 'a-b-c' \
	            -prefix $derivoutdir/"$subjstr"_space-MNI152NLin2009cAsym_label-dilatedGM_mask.nii.gz
	            
        # convert anat_follower_rois to nii and save to directory
        3dAFNItoNIFTI -prefix $derivoutdir/"$subjstr"_space-MNI152NLin2009cAsym_label-epiGM_mask.nii.gz $output_dir/follow_ROI_FSGMe+tlrc.BRIK.gz
        3dAFNItoNIFTI -prefix $derivoutdir/"$subjstr"_space-MNI152NLin2009cAsym_label-epiWM_mask.nii.gz $output_dir/follow_ROI_FSWMe+tlrc.BRIK.gz
        3dAFNItoNIFTI -prefix $derivoutdir/"$subjstr"_space-MNI152NLin2009cAsym_label-epiVent_mask.nii.gz $output_dir/follow_ROI_FSvent+tlrc.BRIK.gz 

		  ##### convert volreg output to nifti and copy to derivatives directory #####

		  # to enable others to use the data, copy EPIs in standard space to derivatives directory

		  set volreg_dpattern = $output_dir"/pb03*+tlrc.HEAD"
		  set volreg_files = (`ls $volreg_dpattern | xargs -n 1 basename`)

		  # for each file in the volreg array
		  foreach volreg ($volreg_files)

				echo $volreg

			  # define volreg_id to use as new file name
			  set volreg_id = ( ` echo $volreg | sed 's/.r0/_run-/'` )
			  set volreg_id = ( ` echo $volreg_id | sed 's/pb03.//'` )
			  set volreg_id = ( ` echo $volreg_id | sed 's/.volreg+tlrc.HEAD/_desc-MNIaligned_bold.nii.gz/'` )
			  echo $volreg_id

			  # do the AFNI to .nii conversion
			  3dAFNItoNIFTI -prefix $derivoutdir/$volreg_id $output_dir/$volreg

			end

		  ##### copy regressors to new directory #####

		  # create regressor folder
		  set regressdir = $derivroot/$subj/regressors
		  mkdir $regressdir

		  # copy and rename files: motion
		  cp $output_dir/dfile_rall.1D $regressdir/"$subjstr"_label-mot_regressor.1D
		  #cp $output_dir/dfile.r01.1D $regressdir/"$subjstr"_run-1_label-mot_regressor.1D
		  #cp $output_dir/dfile.r02.1D $regressdir/"$subjstr"_run-2_label-mot_regressor.1D
		  #cp $output_dir/dfile.r03.1D $regressdir/"$subjstr"_run-3_label-mot_regressor.1D

			if ($task == magictrickwatching) then

		        if ($subj == sub-experimental016) then

		            # copy and rename files: demeaned motion
		            cp $output_dir/mot_demean.r01.1D $regressdir/"$subjstr"_run-1_label-motdemean_regressor.1D
		            cp $output_dir/mot_demean.r02.1D $regressdir/"$subjstr"_acq-1_run-2_label-motdemean_regressor.1D
		            cp $output_dir/mot_demean.r03.1D $regressdir/"$subjstr"_acq-2_run-2_label-motdemean_regressor.1D
		            cp $output_dir/mot_demean.r04.1D $regressdir/"$subjstr"_run-3_label-motdemean_regressor.1D

		            # copy and rename files: motion derivatives
		            cp $output_dir/mot_deriv.r01.1D $regressdir/"$subjstr"_run-1_label-motderiv_regressor.1D
		            cp $output_dir/mot_deriv.r02.1D $regressdir/"$subjstr"_acq-1_run-2_label-motderiv_regressor.1D
		            cp $output_dir/mot_deriv.r03.1D $regressdir/"$subjstr"_acq-2_run-2_label-motderiv_regressor.1D
		            cp $output_dir/mot_deriv.r04.1D $regressdir/"$subjstr"_run-3_label-motderiv_regressor.1D

		            # copy and rename files: Principle Component Ventricle
		            cp $output_dir/ROIPC.FSvent.r01.1D $regressdir/"$subjstr"_run-1_label-ventriclePC_regressor.1D
		            cp $output_dir/ROIPC.FSvent.r02.1D $regressdir/"$subjstr"_acq-1_run-2_label-ventriclePC_regressor.1D
		            cp $output_dir/ROIPC.FSvent.r03.1D $regressdir/"$subjstr"_acq-2_run-2_label-ventriclePC_regressor.1D
		            cp $output_dir/ROIPC.FSvent.r04.1D $regressdir/"$subjstr"_run-3_label-ventriclePC_regressor.1D

	            else

		            # copy and rename files: demeaned motion
		            cp $output_dir/mot_demean.r01.1D $regressdir/"$subjstr"_run-1_label-motdemean_regressor.1D
		            cp $output_dir/mot_demean.r02.1D $regressdir/"$subjstr"_run-2_label-motdemean_regressor.1D
		            cp $output_dir/mot_demean.r03.1D $regressdir/"$subjstr"_run-3_label-motdemean_regressor.1D

		            # copy and rename files: motion derivatives
		            cp $output_dir/mot_deriv.r01.1D $regressdir/"$subjstr"_run-1_label-motderiv_regressor.1D
		            cp $output_dir/mot_deriv.r02.1D $regressdir/"$subjstr"_run-2_label-motderiv_regressor.1D
		            cp $output_dir/mot_deriv.r03.1D $regressdir/"$subjstr"_run-3_label-motderiv_regressor.1D

		            # copy and rename files: Principle Component Ventricle
		            cp $output_dir/ROIPC.FSvent.r01.1D $regressdir/"$subjstr"_run-1_label-ventriclePC_regressor.1D
		            cp $output_dir/ROIPC.FSvent.r02.1D $regressdir/"$subjstr"_run-2_label-ventriclePC_regressor.1D
		            cp $output_dir/ROIPC.FSvent.r03.1D $regressdir/"$subjstr"_run-3_label-ventriclePC_regressor.1D

	            endif

			else

				# copy and rename files: demeaned motion
				cp $output_dir/mot_demean.r01.1D $regressdir/"$subjstr"_run-1_label-motdemean_regressor.1D
				cp $output_dir/mot_demean.r02.1D $regressdir/"$subjstr"_run-2_label-motdemean_regressor.1D

				# copy and rename files: motion derivatives
				cp $output_dir/mot_deriv.r01.1D $regressdir/"$subjstr"_run-1_label-motderiv_regressor.1D
				cp $output_dir/mot_deriv.r02.1D $regressdir/"$subjstr"_run-2_label-motderiv_regressor.1D

				# copy and rename files: Principle Component Ventricle
				cp $output_dir/ROIPC.FSvent.r01.1D $regressdir/"$subjstr"_run-1_label-ventriclePC_regressor.1D
				cp $output_dir/ROIPC.FSvent.r02.1D $regressdir/"$subjstr"_run-2_label-ventriclePC_regressor.1D


			endif


		  # copy and rename censor file
		  cp $output_dir/censor_"$subjstr"_combined_2.1D $regressdir/"$subjstr"_label-censorTRs_regressor.1D

		  # copy and rename outlier file
		  cp $output_dir/outcount_rall.1D $regressdir/"$subjstr"_label-outlierfrac_regressor.1D

		  # convert fast anaticor output to NII
		  3dAFNItoNIFTI -prefix $regressdir/"$subjstr"_label-localWM_regressor.nii.gz $output_dir/Local_FSWMe_rall+tlrc.BRIK

		  ##### convert errts.anaticor output to nifti and copy to derivatives directory #####

		  # define files: final preprocessing output is errts.$subjects.magictrickwatching_perRun.fanaticor
	      set file_string = $output_dir/errts."$subjstr".fanaticor+tlrc*

		  set file = (`ls $file_string | xargs -n 1 basename`)

		  # define niifile
		  set niifile = "$subjstr"_desc-fullpreproc_bold.nii.gz

		  # do the AFNI to .nii conversion
		  3dAFNItoNIFTI -prefix $derivoutdir/$niifile $output_dir/$file

	  endif
	  
	  

	end

end
