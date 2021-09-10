#!/bin/bash

################################################################################
# concatenating task BOLD series after pre-processing
################################################################################

# define path
DIR="/storage/shared/research/cinn/2018/MAGMOT"

# define derivatves dir
deriv_dir="$DIR"/derivatives

# change directory to BIDS folder
BIDS_dir="$DIR"/rawdata
# change directory to the raw NIFI files
cd $BIDS_dir

# define subjects based on folder names in the BIDS directory
subjects=($(ls -d sub*))

#subjects=(sub-control003)
#subjects=(sub-experimental016 sub-control045)

# define TSV file to read in
input=$DIR/"scripts/fmri/bold/concat/MMC_inputForConcatenation.tsv"

# define search and replace string for file prefix
searchstring="desc-fullpreproc_bold.nii.gz"
replacestring="desc-concat_bold.nii.gz"

# define task
task=magictrickwatching

# for each subject in the subjects array
for subject in "${subjects[@]}"; do

	echo $subject
	
	# define concat directory
	outdir=$deriv_dir/$subject/func

	# load in pre-processed task file
	cd $outdir
	
	# define niifile
    taskfile="$subject"_task-"$task"_"$searchstring"


    ############### concatenate pre-processed file ###############

	# set variable to track appearance of first magic trick
	i=0
	first=1

	# read in file with information about scan duration
	{
	IGNORE_FL=T
	while read ID stim_file start_vol end_vol
		do

		# if the line is header set IGNORE_FL to F and skip line
		if [[ ${ID} = "ID" ]]; then
			IGNORE_FL=F
				continue
		fi

		# Ignore all lines until actual columns are found
		if [[ ${IGNORE_FL} = T  ]]; then
			continue
		fi

		# when the right information are available for the subject
		if [[ "$ID" == *"$subject"* ]]; then

			# update variable that tracks appearance of magictricks
			((i=i+1))

			# when we're dealing with the first magic trick
			if [[ $i -eq $first ]]; then

				echo "processing concatenation"

				# determine start and end vol for the first magic trick and save them in select
				select=`echo $start_vol..$end_vol`

			else

				# determine start and end vol for the next magic trick and save them in select_temp
				select_temp=`echo $start_vol..$end_vol`
				#update select to include start and end of all magic tricks processed so far
				select=`echo $select,$select_temp`

			fi


		fi

		done < "$input"
		}


		# define prefix
		prefix="${taskfile/$searchstring/$replacestring}"

		# create task concat
		if [ ! -f "$prefix" ]; then

			echo $prefix

			# once input file is processed
			echo "selected vols: $select"

			# 3dTcat to concatenate data using selected volumes
			3dTcat $taskfile[$select] -prefix $prefix -session $outdir

			# extract final file length
			3dinfo $prefix > info.txt
			numvol=$(awk 'NR==18 {print $6}' info.txt)
			echo "final number of vols: $numvol"
			rm info.txt

		fi

done
