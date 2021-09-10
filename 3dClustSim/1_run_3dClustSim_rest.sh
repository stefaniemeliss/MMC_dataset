#!/bin/bash
source ~/.bashrc

module load afni19.3.03

###############################################################################
########################## set up and run 3dClustSim ##########################
###############################################################################


# define task
task=rest

# define path
DIR="/storage/shared/research/cinn/2018/MAGMOT"

# define derivatves dir
deriv_dir="$DIR"/derivatives

# create and set working directory
anal_root="$deriv_dir"/analysis
mkdir $anal_root

task_root="$anal_root"/"$task"
mkdir $task_root

out_dir="$task_root"/3dClustSim
mkdir $out_dir
cd $out_dir

# extract and average smoothness of data sets
params=$(grep -h ACF $deriv_dir/afniproc/sub*/sub*task-"$task".results/out.ss*.txt | awk -F: '{print $2}' | 3dTstat -mean -prefix - 1D:stdin\')

echo $params

# simulate cluster extent threshold
3dClustSim -acf $params -both -prefix ClustSim_"$task" -nxyz 64 64 76 -dxyz 3 3 3
