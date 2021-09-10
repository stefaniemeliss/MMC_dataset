#!/bin/bash
source ~/.bashrc

# define path
path="/storage/shared/research/cinn/2018/MAGMOT"


# change directory to BIDS folder
BIDS_dir="$path"/rawdata
cd $BIDS_dir

# declare deriv_dir
deriv_dir="$path"/derivatives

# declare ISC dir
ISC_root="$deriv_dir"/ISC
mkdir -p $ISC_root

# define subjects based on folder names in the BIDS directory
subjects=($(ls -d sub*))
#subjects=(sub-control001 sub-control002 sub-control003) # script development

# get length of subjects
num_subjects=${#subjects[@]}

# define task
task=magictrickwatching

for (( s=0; s<${num_subjects}; s++));
    do
    # define variable subj_id, change directory to where the bold data of subj_id is saved and define file for subj_id
    subj_id=${subjects[$s]}
    s1_dir="$deriv_dir"/"$subj_id"/func
    cd $s1_dir
    s1_file=($(ls "$subj_id"_task-"$task"_desc-concat_bold.nii.gz))
    
    for (( t=s+1; t<${num_subjects}; t++));
        do

        # define variable subj_corr, change directory to where the bold data of subj_corr is saved and define file for subj_corr
        subj_corr=${subjects[$t]}
        s2_dir="$deriv_dir"/"$subj_corr"/func
        cd $s2_dir
        s2_file=($(ls "$subj_corr"_task-"$task"_desc-concat_bold.nii.gz))


        # create folder and compute ISC for whole time courrse
        ISC_prefix="ISC_""$subj_id""$subj_corr""_task-"$task"_z.nii.gz"

        #mkdir $ISC_dir
        cd $ISC_root

        # compute ISC map
		if [ ! -f "$ISC_prefix" ]; then
        	echo s1_file $s1_file
        	echo s2_file $s2_file
			echo ISC_prefix $ISC_prefix
            echo ""

			# calculate ISC using pearson, do not detrend the data, save it in .nii, do Fisher-z transformation
        	3dTcorrelate -pearson -polort -1 -Fisher -prefix $ISC_prefix $s1_dir/$s1_file $s2_dir/$s2_file

		fi

	done
done
