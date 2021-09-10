#!/bin/bash

# https://afni.nimh.nih.gov/pub/dist/doc/program_help/gen_ss_review_table.py.html

# define directories
topdir=/storage/shared/research/cinn/2018/MAGMOT #study folder

derivroot=$topdir/derivatives
outroot=$derivroot/afni_proc

cd $outroot

# define tasks
tasks=(magictrickwatching rest)

for task in "${tasks[@]}"; do

    # generate overall review table
    gen_ss_review_table.py -write_table review_table_$task.csv        \
                    -infiles sub-*/*task-$task.results/out.ss_review.*

    # generate outlier table
    gen_ss_review_table.py                                                \
                  -outlier_sep comma                                      \
                  -report_outliers 'censor fraction' GE 0.1               \
                  -report_outliers 'average motion (per TR)' GE 0.1       \
                  -report_outliers 'average censored motion' GE 0.1       \
                  -report_outliers 'max censored displacement' GE 3       \
                  -report_outliers 'TSNR average' LT 200                  \
                  -report_outliers 'degrees of freedom left' SHOW         \
                  -report_outliers 'anat/EPI mask Dice coef' LT 0.9       \
                  -report_outliers 'anat/templ mask Dice coef' LT 0.9     \
                  -infiles sub-*/*task-$task.results/out.ss_review.*      \
                  -write_outliers outliers_review_table_$task.csv

done
