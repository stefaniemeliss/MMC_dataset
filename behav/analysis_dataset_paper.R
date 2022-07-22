### this script contains the code used for the dataset paper 

################################################################################################
############################################ SETUPS ############################################
################################################################################################

#empty work space, load libraries and functions
rm(list=ls())

# define necessary directories
analysisDir <- getwd()

filename_tables <- "tables_dataset_paper.xlsx"

# delete output files
ifelse(file.exists(filename_tables), file.remove(filename_tables), FALSE)

# helper functions and packages 
devtools::source_url("https://github.com/stefaniemeliss/MAGMOT/blob/master/functions/errorbars.R?raw=TRUE")
devtools::source_url("https://github.com/stefaniemeliss/MAGMOT/blob/master/functions/rbindcolumns.R?raw=TRUE")

library(dplyr)
library(lme4)
library(ggplot2)
library(ggrepel)
library(data.table)
library(gt)


# define version --> double-check whether this is necessary or not
version <- "MAGMOT"
version_official <- "fmri"
dataset_name <- "MMC"

memoryLevels <- c("cuedRecallStrict", "cuedRecallLenient", 
                  "recognition", "recognitionConfLevel_4_5_6",
                  "rememberedStrictHigh", "rememberedLenientHigh")

memoryLabels <- c("cuedRecallStrict", "cuedRecallLenient", 
                  "allConf", "highConf", 
                  "rememberedStrictHigh", "rememberedLenientHigh")

# define table labels (copied from manuscript)
desc_t1 <- "Description of participants means (standard deviation) in each group. All participants were right-handed and fluent in English. Sex is expressed as percentage female. Ethnic background is expressed as percentage Black, Asian, and Minority Ethnic (BAME). Statistics of group comparison report Two-Sample Welch t-test and Chi-Square test for categorical (sex and percentage BAME) and continuous data (age, years of education, Corsi span, and n-back accuracy), respectively." 

desc_t2 <- "Descriptive summary of deviation (in ms) between programmed and observed duration of different trial components separately for each group. Group differences were tested for significance using Welch Two Sample t-Tests." 

desc_t3 <- "Encoding performance for different memory measurements and thresholds. Absolute performance captures the number of items that were encoded, relative performance relates to the percentage out of all 36 trails. One sample t-tests were carried out one-sided testing against a true mean of zero (recall & remembering) and 25% (recognition), respectively. Average ratings and encoding likelihood computed over all trials and results of their variance decomposition.  High subject x stimulus variance suggests that the data is suitable to investigate within-person variability."

desc_t4 <- "Missing slices for each scan separately for each group. The extents of the EPI mask in inferior-superior direction were compared with those of the FreeSurfer parcellation mask. The table shows the mean difference (standard deviation) [maximum] in slices for each group and scan separately together with the results of the Welch Two Sample t-Test."

desc_x1 <- "Description of the magic tricks used as stimulus in the study. Occurrence specifies whether the trick has been presented during practice or in the experiment. The information about name, credit, phenomena category, materials and description are from Ozono et al. The wording of the options for the recognition task has been piloted and tested in behavioural samples. Any deviations in wording between the pilot and current data collection have been highlighted." 

desc_x2 <- "Description of video files used in this study. For each magic trick, we included timings, file names, and descriptions for the frame of the cue image as well as for the moment(s) of surprise. The onsets of each of them have been added as markers in the PTB script and the experimental data files. All durations and timings are measured in seconds." 

desc_x3 <- "Variable dictionary referencing the variables included in the MMC_experimental_data.csv file. An explanation of each variable is given to enhance usability for other researchers."

# define TR
TR <- 2

# define geom and function for split violin plot
# from https://stackoverflow.com/questions/35717353/split-violin-plot-with-ggplot2 (written by jan-glx)
GeomSplitViolin <- ggproto("GeomSplitViolin", GeomViolin, 
                           draw_group = function(self, data, ..., draw_quantiles = NULL) {
                             data <- transform(data, xminv = x - violinwidth * (x - xmin), xmaxv = x + violinwidth * (xmax - x))
                             grp <- data[1, "group"]
                             newdata <- plyr::arrange(transform(data, x = if (grp %% 2 == 1) xminv else xmaxv), if (grp %% 2 == 1) y else -y)
                             newdata <- rbind(newdata[1, ], newdata, newdata[nrow(newdata), ], newdata[1, ])
                             newdata[c(1, nrow(newdata) - 1, nrow(newdata)), "x"] <- round(newdata[1, "x"])
                             
                             if (length(draw_quantiles) > 0 & !scales::zero_range(range(data$y))) {
                               stopifnot(all(draw_quantiles >= 0), all(draw_quantiles <=
                                                                         1))
                               quantiles <- ggplot2:::create_quantile_segment_frame(data, draw_quantiles)
                               aesthetics <- data[rep(1, nrow(quantiles)), setdiff(names(data), c("x", "y")), drop = FALSE]
                               aesthetics$alpha <- rep(1, nrow(quantiles))
                               both <- cbind(quantiles, aesthetics)
                               quantile_grob <- GeomPath$draw_panel(both, ...)
                               ggplot2:::ggname("geom_split_violin", grid::grobTree(GeomPolygon$draw_panel(newdata, ...), quantile_grob))
                             }
                             else {
                               ggplot2:::ggname("geom_split_violin", GeomPolygon$draw_panel(newdata, ...))
                             }
                           })

geom_split_violin <- function(mapping = NULL, data = NULL, stat = "ydensity", position = "identity", ..., 
                              draw_quantiles = NULL, trim = TRUE, scale = "area", na.rm = FALSE, 
                              show.legend = NA, inherit.aes = TRUE) {
  layer(data = data, mapping = mapping, stat = stat, geom = GeomSplitViolin, 
        position = position, show.legend = show.legend, inherit.aes = inherit.aes, 
        params = list(trim = trim, scale = scale, draw_quantiles = draw_quantiles, na.rm = na.rm, ...))
}

# define summary function showing median
data_summary <- function(x) { # median
  m <- median(x)
  ymin <- median(x)
  ymax <- median(x)
  return(c(y=m,ymin=ymin,ymax=ymax))
}

# function to determine outliers
is_outlier <- function(x) {
  return(x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x))
}


### downlaod data sets from OSF ###
project <- osfr::osf_retrieve_node("eyzwb")

# download all files
osfr::osf_ls_files(project, pattern = paste0(dataset_name)) %>%
  osfr::osf_download(conflicts = "overwrite")

### read in data sets ###

# data in wide format
scores <- read.csv(paste0(dataset_name, "_scores.csv"), stringsAsFactors = F)
other_information <- read.csv(paste0(dataset_name, "_other_information.csv"), stringsAsFactors = F)
demographics <- read.csv(paste0(dataset_name, "_demographics.csv"))
dfWide <- merge(demographics, scores, by = c("ID", "BIDS"))
dfWide <- merge(dfWide, other_information, by = c("ID", "BIDS"))
# data in long format
dfLong <- read.csv(paste0(dataset_name, "_experimental_data.csv"))
# raw quest data
raw <- read.csv(paste0(dataset_name, "_raw_quest_data.csv"))

# stimuli related files
ozono <- read.csv("stim_data/Ozono_et_al_2020_Detailed_information_about_MagicCATs.csv", stringsAsFactors = F)
duration <- read.table("stim_data/duration_magictrickfiles.txt", stringsAsFactors = F, header = T)
marker <- read.csv("stim_data/marker_magictrickfiles.csv", stringsAsFactors = F)
memory_test <- read.csv("stim_data/recognition_memory_test_incl_deviations_in_pilot.csv", stringsAsFactors = F)
memory_test <- memory_test[,c("stimID", "Recognition.option.1", "Recognition.option.2", "Recognition.option.3", "Recognition.option.4", "Different.wording.in.pilot")]


#################################################################################################
############################################ METHODS ############################################
#################################################################################################


########## 1. Look at demographics of the sample ########## 

# SECTION PARTICIPANTS AND DESIGN + TABLE 1 #

# age
psych::describe(dfWide$age)
age <- psych::describeBy(dfWide[,"age"], group=dfWide$group)
age <- as.data.frame(rbind(age$cont, age$exp))
age$mot <- rep(c("cont","exp"), each = 1)

# sex
plyr::count(dfWide, vars =  "sex")
N_per_group <- plyr::count(dfWide, vars = "group")
sex <- plyr::count(dfWide, vars = c("sex","group"))

# ethnicity
ethnicity <- plyr::count(dfWide, vars = c("ethnicity","group"))
dfWide$ethnicity_BAME <- ifelse(dfWide$ethnicity == "White British" | dfWide$ethnicity == "Other White", "White", "BAME")
BAME <- plyr::count(dfWide, vars = c("ethnicity_BAME","group"))

# education
dfWide$yearsOfEducation_num <- ifelse(dfWide$yearsOfEducation == "17 years", 17,
                                      ifelse(dfWide$yearsOfEducation == "20 (18.5 excluding time as phd student)", 20, 
                                             as.numeric(as.character(dfWide$yearsOfEducation))))

psych::describe(dfWide$yearsOfEducation_num)
edu <- psych::describeBy(dfWide[,"yearsOfEducation_num"], group=dfWide$group)
edu <- as.data.frame(rbind(edu$cont, edu$exp))
edu$mot <- rep(c("cont","exp"), each = 1)

degree <- plyr::count(dfWide, vars = c("education","group"))

# working memory
psych::describe(dfWide$corsiSpan)
corsi <- psych::describeBy(dfWide[,"corsiSpan"], group=dfWide$group)
corsi <- as.data.frame(rbind(corsi$cont, corsi$exp))
corsi$mot <- rep(c("cont","exp"), each = 1)

dfWide$nback_accurary <- dfWide$nback_accurary*100 # convert to percent
psych::describe(dfWide$nback_accurary)
nback <- psych::describeBy(dfWide[,"nback_accurary"], group=dfWide$group)
nback <- as.data.frame(rbind(nback$cont, nback$exp))
nback$mot <- rep(c("cont","exp"), each = 1)

# CREATE DEMOGRAPHICS TABLE FOR PAPER (i.e. Table 1)
demogs <- data.frame() # 1. col: variable, 2. col = control, 3. col = experimental
i = 0
varCol <- 1
contCol <- 2
expCol <- 3
testCol <- 4

i = i+1
demogs[i,varCol] <- "Age"
demogs[i,contCol] <- paste0(age$mean[1], " (", round(age$sd[1], 2), ")") # control group
demogs[i,expCol] <- paste0(age$mean[2], " (", round(age$sd[2], 2), ")") # experimental group
ttest <- t.test(dfWide$age ~ dfWide$group)
demogs[i,testCol] <- paste0("t(",round(ttest$parameter, digits = 3), ") = ", round(ttest$statistic, digits = 3), ", p = ", round(ttest$p.value, digits = 3))

# this currently produces error, but this is due to missing data in sex
i = i+1
demogs[i,varCol] <- "Sex assigned at birth (% female)"
demogs[i,contCol] <- paste0(sex$freq[sex$sex == "female" & sex$group == "cont"]/N_per_group$freq[N_per_group$group == "cont"]*100) # control group
demogs[i,expCol] <- paste0(sex$freq[sex$sex == "female" & sex$group == "exp"]/N_per_group$freq[N_per_group$group == "exp"]*100) # experimental group
chisqtest <- chisq.test(table(dfWide$sex, dfWide$group))
demogs[i,testCol] <- paste0("Chi-Square(",round(chisqtest$parameter, digits = 3), ") = ", round(chisqtest$statistic, digits = 3), ", p = ", round(chisqtest$p.value, digits = 3))

i = i+1
demogs[i,varCol] <- "Ethnicity (% BAME)"
demogs[i,contCol] <- paste0(BAME$freq[BAME$ethnicity_BAME == "BAME" & BAME$group == "cont"]/N_per_group$freq[N_per_group$group == "cont"]*100) # control group
demogs[i,expCol] <- paste0(BAME$freq[BAME$ethnicity_BAME == "BAME" & BAME$group == "exp"]/N_per_group$freq[N_per_group$group == "exp"]*100) # experimental group
chisqtest <- chisq.test(table(dfWide$ethnicity_BAME, dfWide$group))
demogs[i,testCol] <- paste0("Chi-Square(",round(chisqtest$parameter, digits = 3), ") = ", round(chisqtest$statistic, digits = 3), ", p = ", round(chisqtest$p.value, digits = 3))

i = i+1
demogs[i,varCol] <- "Years of Education"
demogs[i,contCol] <- paste0(edu$mean[1], " (", round(edu$sd[1], 2), ")") # control group
demogs[i,expCol] <- paste0(edu$mean[2], " (", round(edu$sd[2], 2), ")") # experimental group
ttest <- t.test(dfWide$yearsOfEducation_num ~ dfWide$group)
demogs[i,testCol] <- paste0("t(",round(ttest$parameter, digits = 3), ") = ", round(ttest$statistic, digits = 3), ", p = ", round(ttest$p.value, digits = 3))

i = i+1
demogs[i,varCol] <- "Corsi span"
demogs[i,contCol] <- paste0(corsi$mean[1], " (", round(corsi$sd[1], 2), ")") # control group
demogs[i,expCol] <- paste0(corsi$mean[2], " (", round(corsi$sd[2], 2), ")") # experimental group
ttest <- t.test(dfWide$corsiSpan ~ dfWide$group)
demogs[i,testCol] <- paste0("t(",round(ttest$parameter, digits = 3), ") = ", round(ttest$statistic, digits = 3), ", p = ", round(ttest$p.value, digits = 3))

i = i+1
demogs[i,varCol] <- "n-back (% accuracy)"
demogs[i,contCol] <- paste0(round(nback$mean[1],2), " (", round(nback$sd[1], 2), ")") # control group
demogs[i,expCol] <- paste0(round(nback$mean[2],2), " (", round(nback$sd[2], 2), ")") # experimental group
ttest <- t.test(dfWide$nback_accurary ~ dfWide$group)
demogs[i,testCol] <- paste0("t(",round(ttest$parameter, digits = 3), ") = ", round(ttest$statistic, digits = 3), ", p = ", round(ttest$p.value, digits = 3))

names(demogs) <- c("", "Control Group", "Experimental Group", "Statistics group comparison")

# save demogs
xlsx::write.xlsx(demogs, file=filename_tables, sheetName = "Table_1", append = T, row.names = F) # note: row.names contain variables

# create gt Table
names(demogs) <- c("Item", "Control Group", "Experimental Group", "Statistics group comparison")
gt_1 <- gt(data = demogs) %>% 
  tab_source_note(source_note = paste0(desc_t1)) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels(columns = everything())) 
# show gt Table  
gt_1


########## 2. Descriptives of magic tricks ########## 

# SECTION MATERIALS

# determine the IDs of all stimuli used
stim_exp <- as.character(unique(dfLong$stimID))
stim_prac <- c("H4_long", "K23")
stim_all <- c(stim_exp, stim_prac)
stim_all <- as.data.frame(stim_all)
names(stim_all) <- "stimID"
stim_all$stimID <- as.character(stim_all$stimID)

# prepare in information from Ozono et al 2020
ozono$X <- NULL #remove col
names(ozono) <- c("stimID", "Name", "Credit", "Phenomena Category", "Materials", "Length", "Subtitle", "Description")
ozono$stimID <- gsub("Short", "short", ozono$stimID)
ozono$stimID <- gsub("Long", "long", ozono$stimID)

# subset ozono to only include relevant tricks
stim_all <- merge(stim_all, ozono, by.x = "stimID")

# categorise stimuli whether they were used for experiment or practice
stim_all$experiment <- ifelse(stim_all$stimID == stim_prac[1] | stim_all$stimID == stim_prac[2], "practice", "experiment")

# convert length
stim_all$Length_secs <- as.numeric(gsub("00:00:", "", stim_all$Length))

# combine this with the actual length of the video files that were used
duration$stimID <- gsub("^\\d\\d_", "", duration$vidFileName)
duration$stimID <- gsub("_combined_small.mp4", "", duration$stimID)
stim_all <- merge(stim_all, duration, by.x = c("stimID", "experiment"))

# combine with memory test information
stim_all <- merge(stim_all, memory_test, by.x = c("stimID"), all.x = T)

# look at average video length
psych::describe(stim_all$vidFileDuration_withoutMock)
psych::describe(stim_all$vidFileDuration)

# look at average video length of tricks used in experiment only
psych::describe(stim_all$vidFileDuration_withoutMock[stim_all$experiment == "experiment"])
psych::describe(stim_all$vidFileDuration[stim_all$experiment == "experiment"]) # this is reported in the manuscript

vidFileDuration <- stim_all$vidFileDuration[stim_all$experiment == "experiment"]

########## 3. Determine average testing lengths etc. ########## 

# SECTION TASKS AND MEASUREMENTS

# duration of each trial
psych::describe(dfLong$durationTrial) # reported in manuscript

# duration jitters (jitter was held constant, so looking at one subject is sufficient)
psych::describe(dfLong$jitterVideo_trial[dfLong$BIDS == "sub-control003"]) # after video
psych::describe(dfLong$jitterRating_trial[dfLong$BIDS == "sub-control003"]) # after rating

# duration blank screen
psych::describe(dfLong$displayBlankDuration)

# percentage trials with to sloww for estimate rating
sum(dfLong$answer_tooSlow)
sum(dfLong$answer_tooSlow)/1800

# percentage trials with too slow for curiosity rating
sum(dfLong$curiosity_tooSlow)
sum(dfLong$curiosity_tooSlow)/1800

# CRONBACH'S ALPHA QHUESTIONNAIRES
scales <- c("BISBAS_inhibition", "BISBAS_rewardresponsiveness", "BISBAS_drive", "BISBAS_funseeking", 
           "NeedForCognition", "FearOfFailure", "ApproachTemperament", "AvoidanceTemperament",
           "TraitCuriosity", "StateCuriosity", 
           "IMI_intrinsicMotivation", "IMI_interest", "IMI_taskEngagement", "IMI_boredom",  "IMI_pressure", "IMI_effort")

#psych::alpha(raw[,grepl("TraitCuriosity", names(raw))])


# SECTION EXPERIMENTAL PROCEDURE

# duration pre-scanning online session
psych::describe(dfWide$durPre)

# duration of task blocks separately for each block
psych::describe(dfWide$durInMins_firstBlock)
psych::describe(dfWide$durInMins_secondBlock)
psych::describe(dfWide$durInMins_thirdBlock)

# duration of task blocks across all blocks
block_durInMins <- c(dfWide$durInMins_firstBlock, dfWide$durInMins_secondBlock, dfWide$durInMins_thirdBlock)
psych::describe(block_durInMins)

block_durInSecs <- c(dfWide$durInSecs_firstBlock, dfWide$durInSecs_secondBlock, dfWide$durInSecs_thirdBlock)
psych::describe(block_durInSecs)

# duration of whole experiment
psych::describe(dfWide$durInMins)

# SECTION CODING OF MEMORY MEASUREMENT

# how many trials were recalled in total
sum(dfLong$cuedRecallLenient)
sum(dfLong$cuedRecallStrict)

# how many trials were recalled in percentage
sum(dfLong$cuedRecallLenient)/1800
sum(dfLong$cuedRecallStrict)/1800

# calculate the difference between recall performance on strict and lenient criteria
sum(dfLong$cuedRecallLenient) - sum(dfLong$cuedRecallStrict)
sum(dfLong$cuedRecallLenient)/1800 - sum(dfLong$cuedRecallStrict)/1800

# SECTION FMRI ACQUISITION

# transform dur in secs into TR
dfWide$durInTR_firstBlock <- round(dfWide$durInSecs_firstBlock/TR)
dfWide$durInTR_secondBlock <- round(dfWide$durInSecs_secondBlock/TR)
dfWide$durInTR_thirdBlock <- round(dfWide$durInSecs_thirdBlock/TR)

# duration of task blocks in volumes
psych::describe(dfWide$durInTR_firstBlock)
psych::describe(dfWide$durInTR_secondBlock)
psych::describe(dfWide$durInTR_thirdBlock)

# time between experiment and memory tests
psych::describe(dfWide$daysBetweenExpAndMemory)
# convert to days and hours
0.43*24 # mean 7.43 days
0.57*24 # sd 0.57 days
0.83*24 # min 6.83 days
0.49*24 # max 9.49 days
# convert hours to minutes
0.32*60 # mean 10.32 hours
0.68*60 # sd 13.68 hours
0.92*60 # min 19.92 hours
0.76*24 # max 11.76 hours

# duration of memory assessment
psych::describe(dfWide$durMemory)

########## 4. duration of magic tricks in seconds vs TR ########## 

# SECTION INTERSUBJECT CORRELATION #

# transform long data into wide data
displayVidDuration <- reshape::cast(dfLong, ID~stimID,value="displayVidDuration")
vidFileDuration  <- reshape::cast(stim_all, ~stimID,value="vidFileDuration")
rownames(vidFileDuration) <- "vidFileDuration"

# compute mean, sd, min, max and range for the display duration of each magic trick
mean_displayVidDuration <- mapply(mean, displayVidDuration[-1])
sd_displayVidDuration <- mapply(sd, displayVidDuration[-1])
min_displayVidDuration <- mapply(min, displayVidDuration[-1])
max_displayVidDuration <- mapply(max, displayVidDuration[-1])
range_displayVidDuration <- max_displayVidDuration - min_displayVidDuration

# put all information into one data frame
descript_displayVidDuration <- rbind(mean_displayVidDuration, sd_displayVidDuration)
descript_displayVidDuration <- rbind(descript_displayVidDuration, min_displayVidDuration)
descript_displayVidDuration <- rbind(descript_displayVidDuration, max_displayVidDuration)
descript_displayVidDuration <- rbind(descript_displayVidDuration, range_displayVidDuration)

# merge this with actual file length and transpose
descript_displayVidDuration <- as.data.frame(descript_displayVidDuration)
descript_displayVidDuration <- rbind.match.columns(descript_displayVidDuration, vidFileDuration)
descript_displayVidDuration <- as.data.frame(t(descript_displayVidDuration))

# convert mean, min & max duration into volumes
descript_displayVidDuration$mean_displayVidDuration_TR <- ceiling(round(descript_displayVidDuration$mean_displayVidDuration, digits = 0)/TR)
descript_displayVidDuration$min_displayVidDuration_TR <- ceiling(round(descript_displayVidDuration$min_displayVidDuration, digits = 0)/TR)
descript_displayVidDuration$max_displayVidDuration_TR <- ceiling(round(descript_displayVidDuration$max_displayVidDuration, digits = 0)/TR)

# determine differences between mean, min & max duration volumes 
sum(descript_displayVidDuration$mean_displayVidDuration_TR != descript_displayVidDuration$min_displayVidDuration_TR) # 1
sum(descript_displayVidDuration$mean_displayVidDuration_TR != descript_displayVidDuration$max_displayVidDuration_TR) # 4

# non-systematic variation in stimulus presentation
psych::describe(descript_displayVidDuration$sd_displayVidDuration) # included in paper

# save data structure for TR and seconds
displayVidDuration <- reshape::cast(dfLong, ID~stimID,value="displayVidDuration")
displayVidDuration_TR <- ceiling(round(displayVidDuration[-1], digits = 0)/TR) # convert seconds into TR
displayVidDuration_s <- round(displayVidDuration[-1], digits = 5)

# make sure that row and column names are the same
names(displayVidDuration_TR) == row.names(descript_displayVidDuration)
names(displayVidDuration_s) == row.names(descript_displayVidDuration)

# compare converted TRs to mean TR used for concatenation for all 36 in 50 subjects
for (s in 1:dim(dfWide)[1]) { 
  
  if (s == 1){
    # compare converted TRs (row in displayVidDuration_TR) to mean TR used for concatenation FOR FIRST SUBJECT
    sum_TR_dev <- sum(displayVidDuration_TR[paste0(s),] != descript_displayVidDuration$mean_displayVidDuration_TR)
    # compute absolute difference between avg display of tricks and actual display FOR FIRST SUBJECT
    abs_diff <- c(abs(descript_displayVidDuration$mean_displayVidDuration - displayVidDuration_s[paste0(s),]))
  } else {
    # compare converted TRs (row in displayVidDuration_TR) to mean TR used for concatenation FOR SUBJECT and append
    temp_sum_TR_dev <- sum(displayVidDuration_TR[paste0(s),] != descript_displayVidDuration$mean_displayVidDuration_TR)
    sum_TR_dev <- sum_TR_dev + temp_sum_TR_dev
    # compute absolute difference between avg display of tricks and actual display FOR SUBJECT and append
    temp_abs_diff <- c(abs(descript_displayVidDuration$mean_displayVidDuration - displayVidDuration_s[paste0(s),]))
    abs_diff <- c(abs_diff, temp_abs_diff)
    
    # remove temp files
    rm(temp_sum_TR_dev, temp_abs_diff)
  }
}  
# print output over all 1800 trials (included in paper)
print(sum_TR_dev)
print(sum_TR_dev/dim(dfLong)[1]*100) # deviation in number of volumes

psych::describe(unlist(abs_diff)) # deviation in seconds
hist(unlist(abs_diff))


##############################################################################################################
############################################ TECHNICAL VALIDATION ############################################
##############################################################################################################


########## 5. manipulation check ########## 

# SECTION MANIPULATION CHECK #

# rewardEffort: I tried hard to increase my reward. 
psych::describe(dfWide$rewardEffort)
# rewardBelief: Did you believe that you would receive a bonus payment based on your performance?
# Please answer the following statement ONLY IF you have been offered additional £0.80 bonus per correct answer. If you have not been offered additional bonus, please select "not applicable."
dfWide$rewardBelief_score <- ifelse(dfWide$rewardBelief == "Not applicable", NA,
                                    ifelse(dfWide$rewardBelief == "Definitely agree ", 6,
                                           ifelse(dfWide$rewardBelief == "Somehow agree", 5,
                                                  ifelse(dfWide$rewardBelief == "Slightly agree", 4,
                                                         ifelse(dfWide$rewardBelief == "Slightly disagree", 3,
                                                                ifelse(dfWide$rewardBelief == "Somehow disagree", 2,
                                                                       ifelse(dfWide$rewardBelief == "Definitely disagree", 1, 0)))))))

psych::describe(dfWide$rewardBelief_score)

# rewardExpectations: How much additional bonus for correct answers do you expect?
dfWide$rewardExpectations_num <- ifelse(is.na(dfWide$rewardExpectations) == T, NA,
                                        ifelse(dfWide$rewardExpectations == "5 answers", 5*.8,
                                               ifelse(dfWide$rewardExpectations == "none", 0,
                                                      ifelse(dfWide$rewardExpectations == "4 POUNDS", 4,
                                                             ifelse(dfWide$rewardExpectations == "8 pounds", 8,
                                                                    ifelse(dfWide$rewardExpectations == "6 or 7? Iâ€™m not really sure.  ", 6.5,
                                                                           ifelse(dfWide$rewardExpectations == "Not much", NA,
                                                                                  ifelse(dfWide$rewardExpectations == "not sure", NA,
                                                                                         as.numeric(dfWide$rewardExpectations
                                                                                         )))))))))

psych::describe(dfWide$rewardExpectations_num)

# memoryTestKnown: When watching the magic tricks, I was aware that my memory of them will be tested later.
dfWide$memoryTestKnown_score <- ifelse(dfWide$memoryTestKnown == "Definitely agree ", 6,
                                       ifelse(dfWide$memoryTestKnown == "Somehow agree", 5,
                                              ifelse(dfWide$memoryTestKnown == "Slightly agree", 4,
                                                     ifelse(dfWide$memoryTestKnown == "Slightly disagree", 3,
                                                            ifelse(dfWide$memoryTestKnown == "Somehow disagree", 2,
                                                                   ifelse(dfWide$memoryTestKnown == "Definitely disagree", 1, 0))))))

psych::describe(dfWide$memoryTestKnown_score)

# memoryIntention: When watching the magic tricks, I tried to encode them.
dfWide$memoryIntention_score <- ifelse(dfWide$memoryIntention == "Definitely agree ", 6,
                                       ifelse(dfWide$memoryIntention == "Somehow agree", 5,
                                              ifelse(dfWide$memoryIntention == "Slightly agree", 4,
                                                     ifelse(dfWide$memoryIntention == "Slightly disagree", 3,
                                                            ifelse(dfWide$memoryIntention == "Somehow disagree", 2,
                                                                   ifelse(dfWide$memoryIntention == "Definitely disagree", 1, 0))))))

psych::describe(dfWide$memoryIntention_score)


########## 6. Check stimulus timing ########## 

# SECTION TIMING + TABLE 2 #

dfLong <- merge(dfLong, stim_all, by = c("stimID", "vidFileName"))
timings <- data.frame() # 1. col: variable, 2. col = control, 3. col = experimental
varCol <- 1
contCol <- 2
expCol <- 3
ttestCol <- 4
index_actual <- (c("displayVidDuration", "fixationPostVidDuration", "fixationPostAnswerDuration", "fixationPostCuriosityDuration"))
index_intended <- (c("vidFileDuration", "jitterVideo_trial", "betweenRatingFixation", "jitterRating_trial"))
name <- c("Stimulus display duration", "Fixation after stimulus display", "Fixation between ratings", "Fixation after ratings")

# create Table 2
for (i in 1:length(index_intended)){
  
  # calculate difference between intended and observed display durations and convert to mili seconds and make absolute
  dfLong$diff <- dfLong[[index_actual[i]]] - dfLong[[index_intended[i]]]
  dfLong$diff <- dfLong$diff * 1000
  #dfLong$diff <- abs(dfLong$diff)
  
  # calculate descriptives of difference
  output <- psych::describeBy(dfLong$diff, group = dfLong$group) # stimulus presentation (this is the actual magic trick + 6 seconds mock video)
  output <- as.data.frame(rbind(output$cont, output$exp))
  output$group <- rep(c("control","experimental"), each = 1)
  output$vars <- name[i]
  
  # put the information into timing dataframe
  timings[i,varCol] <- output$vars[1]
  timings[i,contCol] <- paste0(round(output$mean[1], digits = 3), " (", round(output$sd[1], digits = 3), ")",  " [", round(output$min[1], digits = 3),"; ", round(output$max[1], digits = 3),"]") # control group
  timings[i,expCol] <- paste0(round(output$mean[2], digits = 3), " (", round(output$sd[2], digits = 3), ")",  " [", round(output$min[2], digits = 3),"; ", round(output$max[2], digits = 3),"]") # control group
  
  # conduct t-test
  ttest <- t.test(dfLong$diff ~ dfLong$group)
  timings[i,ttestCol] <- paste0("t(",round(ttest$parameter, digits = 3), ") = ", round(ttest$statistic, digits = 3), ", p = ", round(ttest$p.value, digits = 3))
  
}

names(timings) <- c("Trial component", "Mean control group (SD) [min; max]", "Mean experimental group (SD) [min; max]", "Result Welch Two Sample t-Test")

# create gt Table
gt_2 <- gt(data = timings) %>% 
  tab_source_note(source_note = paste0(desc_t2)) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels(columns = everything())) 
# show gt Table  
gt_2

xlsx::write.xlsx(timings, file=filename_tables, sheetName = "Table_2", append = T, row.names = F) # note: row.names contain variables

########## 7. Check encoding ########## 

# SECTION ENCODING PERFORMANCE + TABLE 3 #

# compute mean of subject mean
dvlist_rel <- names(dfWide)[grepl("rel", names(dfWide))]

dvname <- c("Cued recall (strict)", "Cued recall (lenient)", 
            "Recognition (all confidence levels)", "Recognition (high confidence)",  
            "Remembered (strict or high)", "Remembered (lenient or high)")

encoding <- data.frame()
varCol <- 1
descCol_rel <- 2
testCol <- 3

# create Table 3
for (DV in 1:length(dvlist_rel)){
  print(dvlist_rel[DV])

  # compute descriptives
  output_rel <- psych::describe(dfWide[,c(dvlist_rel[DV])]*100)
  
  # test significance
  if (grepl("conf", dvlist_rel[DV])){
    mu <- .25
  } else {
    mu <- 0
  }
  test <- t.test(dfWide[,c(dvlist_rel[DV])], alternative = "greater", mu = mu)
  print(test)
  
  pval <- ifelse(test$p.value < 0.001, 0.001, test$p.value)
  
  
  # put data into table
  encoding[DV, varCol] <- dvname[DV]
  encoding[DV, descCol_rel] <-  paste0(round(output_rel$mean, digits = 3), "% (", round(output_rel$sd, digits = 3), "%)",  " [", round(output_rel$min, digits = 3),"%; ", round(output_rel$max, digits = 3),"%]") # control group
  encoding[DV, testCol] <- paste0("t(", test$parameter,") = ", round(test$statistic, digits = 3), ", p < ", pval)
  
}

names(encoding) <- c("","Mean relative encoding performance (SD) [min; max]", "Test statistics")


########## 8. variance decomposition ########## 

# SECTION VARIANCE DECOMPOSTION + TABLE 3 #

dvlist <- c("responseCuriosity", "responseConfidence", 
            "cuedRecallStrict", "cuedRecallLenient", 
            "recognition", "recognitionConfLevel_4_5_6", 
            "rememberedStrictHigh", "rememberedLenientHigh")
dvname <- c("Curiosity", "Confidence", 
            "Cued recall (strict)", "Cued recall (lenient)", 
            "Recognition (all confidence level)", "Recognition (high confidence)", 
            "Remembered (strict or high)", "Remembered (lenient or high)")

vardecom <- data.frame()
varCol <- 1
descCol_subj <- 2
descCol <- 3
subjCol <- 4
stimCol <- 5
interCol <- 6

# for each of the memory levels. apply variance decomposition
# note that accoring to goldstein (2002), we can use a LME as an approximation for GLME

# create table 4
for (DV in 1:length(dvlist)){
  # define model based on scaling of variable
  LMEmodel <- lmer(dfLong[, dvlist[DV]] ~ (1|ID)+(1|stimID), data = dfLong)
  
  # access variance components
  out_sV <- as.data.frame(VarCorr(LMEmodel))[,4]
  
  # compute mean of subject mean
  wide <- reshape::cast(dfLong, ID~stimID,value=paste0(dvlist[DV]))
  mean_per_subj <- rowMeans(wide[-1])
  rm(wide)
  
  # put data into table
  vardecom[DV, varCol] <- dvname[DV]
  vardecom[DV, descCol_subj] <- paste0(round(mean(mean_per_subj), digits = 3), " (", round(sd(mean_per_subj), digits = 3), ")", 
                                       " [", round(min(mean_per_subj), digits = 3),"; ", round(max(mean_per_subj), digits = 3),"]")
  vardecom[DV, descCol] <- paste0(round(sd(dfLong[, dvlist[DV]], na.rm = T), digits = 3))
  vardecom[DV, subjCol] <- paste0(round(out_sV[1]/sum(out_sV)*100, digits = 2), "%")
  vardecom[DV, stimCol] <- paste0(round(out_sV[2]/sum(out_sV)*100, digits = 2), "%")
  vardecom[DV, interCol] <- paste0(round(out_sV[3]/sum(out_sV)*100, digits = 2), "%")
  
}

# add header
names(vardecom) <- c("", "subject-wise mean (SD) [min; max]","SD (all trials)", "Subject variance", "Stimulus variance", "Subject x stimulus variance")

xlsx::write.xlsx(vardecom, file=filename_tables, sheetName = "Table_3", append = T, row.names = F) # note: row.names contain variables

# create gt Table
names(vardecom) <- c("Variable", "subject-wise mean (SD) [min; max]","SD (all trials)", "Subject variance", "Stimulus variance", "Subject x stimulus variance")

gt_3 <- gt(data = vardecom) %>% 
  tab_source_note(source_note = paste0(desc_t3)) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels(columns = everything())) 
# show gt Table  
gt_3

########## 9. imaging data quality assessments ########## 

# SECTION MRIQC #

# html markdown created using markdown_MRIQC_output.Rmd

# SECTION pyfMRIqc 

# html markdown created using markdown_pyfMRIqc_output.Rmd

########## 10. brain coverage ########## 

# SECTION BRAIN COVERAGE #

# download file from preliminary AFNI processing
osfr::osf_ls_files(project, pattern = "extents.txt") %>%
  osfr::osf_download(conflicts = "overwrite")

# read in file
extents <- read.table("data_extents.txt", header = T, stringsAsFactors = F)

# create new variables
extents$file <- gsub("brain_", "", extents$scan)
extents$file <- gsub("epi_", "", extents$file)

extents$source <- ifelse(grepl("brain", extents$scan) == T, "brain",
                         ifelse(grepl("epi", extents$scan) == T, "epi", NA))

extents$group <- ifelse(grepl("control", extents$scan)== T, "control", 
                        ifelse(grepl("experimental", extents$scan)== T, "experimental", NA))

extents$Task <- ifelse(grepl("magictrickwatching", extents$scan)== T, "Magic trick watching", 
                       ifelse(grepl("rest", extents$scan)== T, "Resting-state", NA))

extents$ID <- gsub("_task.*", "", extents$file)

extents$ID_f <- as.factor(extents$ID)

extents$id_number <- gsub("sub-control0", "", extents$ID)
extents$id_number <- gsub("sub-experimental0", "", extents$id_number)

extents$order_number <- recode(extents$id_number, 
                               "01" = "01", "02" = "02", "03" = "03", "07" = "04", "09" = "05",  
                               "11" = "06", "13" = "07", "15" = "08", "17" = "09", "19" = "10",  
                               "21" = "11", "23" = "12", "25" = "13", "27" = "14", "29" = "15",  
                               "31" = "16", "33" = "17", "35" = "18", "37" = "19", "39" = "20",  
                               "41" = "21", "43" = "22", "45" = "23", "47" = "24", "49" = "25",  
                               "04" = "01", "05" = "02", "06" = "03", "08" = "04", "10" = "05",  
                               "12" = "06", "14" = "07", "16" = "08", "18" = "09", "20" = "10",  
                               "22" = "11", "24" = "12", "26" = "13", "28" = "14", "30" = "15",  
                               "32" = "16", "34" = "17", "36" = "18", "38" = "19", "40" = "20",  
                               "42" = "21", "44" = "22", "46" = "23", "48" = "24", "50" = "25")

# check whether extents of brain is constant within each subject
sd <- dplyr::filter(extents, source == "brain") %>%
  dplyr::group_by(ID_f) %>%
  dplyr::summarise(sd_xmin = sd(xmin), sd_xmax = sd(xmax), sd_ymin = sd(ymin),
                   sd_ymax = sd(ymax), sd_zmin = sd(zmin), sd_zmax = sd(zmax), n = n())
sum(sd[,2:7])

# calculate slices covered in x, y, and z direction
extents <- dplyr::mutate(extents, xslice = xmax - xmin, yslice = ymax - ymin, zslice = zmax - zmin)

# transfer data into wide format
xslice <- reshape::cast(extents, file ~ source, value = "xslice")
names(xslice) <- c("scan", "x_brain", "x_epi")
yslice <- reshape::cast(extents, file ~ source, value = "yslice")
names(yslice) <- c("scan", "y_brain", "y_epi")
zslice <- reshape::cast(extents, file ~ source, value = "zslice")
names(zslice) <- c("scan", "z_brain", "z_epi")

# combine dfs
slices <- merge(xslice, yslice, by = "scan")
slices <- merge(slices, zslice, by = "scan")
rm(xslice, yslice, zslice)

# calculate deviation between epi coverage and brain coverage
slices <- dplyr::mutate(slices, x_diff = x_brain - x_epi, y_diff = y_brain - y_epi, z_diff = z_brain - z_epi)

# determine percentage covered
slices <- dplyr::mutate(slices, x_perc = x_epi / x_brain, y_perc = y_epi / y_brain, z_perc = z_epi / z_brain)

# quantify extent of overlap in z direction over scans
extents_scan <- slices[,c(grepl("scan",names(slices)) | grepl("id",names(slices)) | grepl("diff",names(slices)) | grepl("perc",names(slices)))]
names(extents_scan)[grepl("diff",names(extents_scan))] <- c("slice_diff_x", "slice_diff_y", "slice_diff_z")
names(extents_scan)[grepl("perc",names(extents_scan))] <- c("slice_perc_x", "slice_perc_y", "slice_perc_z")
extents_scan$ID <- gsub("_task.*", "", extents_scan$scan)

psych::describe(extents_scan$slice_perc_z*100)
psych::describe(extents_scan$slice_diff_z)

sum(extents_scan$slice_diff_z==0)/dim(extents_scan)[1]
sum(extents_scan$slice_diff_z==1)/dim(extents_scan)[1]
sum(extents_scan$slice_diff_z==0)/dim(extents_scan)[1] + sum(extents_scan$slice_diff_z==1)/dim(extents_scan)[1]

# quantify extent of overlap in z direction over subjects
extents_subj <- extents_scan %>% 
  dplyr::group_by(ID) %>%
  dplyr::summarise(slice_perc_z_mean_subj = mean(slice_perc_z), slice_perc_z_sd_subj = sd(slice_perc_z), 
                   slice_perc_z_min_subj = min(slice_perc_z), slice_perc_z_max_subj = max(slice_perc_z), 
                   slice_diff_z_mean_subj = mean(slice_diff_z), slice_diff_z_sd_subj = sd(slice_diff_z), 
                   slice_diff_z_min_subj = min(slice_diff_z), slice_diff_z_max_subj = max(slice_diff_z))

psych::describe(extents_subj$slice_perc_z_mean_subj*100)
psych::describe(extents_subj$slice_diff_z_mean_subj)

# create variables
slices$group <- ifelse(grepl("control", slices$scan) == T, "control",
                       ifelse(grepl("experimental", slices$scan) == T, "experimental",NA))
slices$acq <- ifelse(grepl("task-magictrickwatching_run-1", slices$scan) == T, 2,
                          ifelse(grepl("task-magictrickwatching_run-2", slices$scan) == T, 3,
                                 ifelse(grepl("task-magictrickwatching_run-3", slices$scan) == T, 4,
                                        ifelse(grepl("task-rest_run-1", slices$scan) == T, 1,
                                               ifelse(grepl("task-rest_run-2", slices$scan) == T, 5,
                                                      ifelse(grepl("task-magictrickwatching_acq-1_run-2", slices$scan) == T, 3,
                                                             ifelse(grepl("task-magictrickwatching_acq-2_run-2", slices$scan) == T, 3, NA)))))))

# look at mean for each cell
perc <- slices %>%
  dplyr::group_by(group, as.factor(acq)) %>%
  dplyr::summarise(x_mean = mean(x_perc), x_sd = sd(x_perc), x_min = min(x_perc), x_max = max(x_perc),
                   y_mean = mean(y_perc), y_sd = sd(y_perc), y_min = min(y_perc), y_max = max(y_perc),
                   z_mean = mean(z_perc), z_sd = sd(z_perc), z_min = min(z_perc), z_max = max(z_perc))

diff <- slices %>%
  dplyr::group_by(group, as.factor(acq)) %>%
  dplyr::summarise(x_mean = mean(x_diff), x_sd = sd(x_diff), x_min = min(x_diff), x_max = max(x_diff),
                   y_mean = mean(y_diff), y_sd = sd(y_diff), y_min = min(y_diff), y_max = max(y_diff),
                   z_mean = mean(z_diff), z_sd = sd(z_diff), z_min = min(z_diff), z_max = max(z_diff))

# CREATE TABLE 4 #

coverage <- data.frame()
acqCol <- 1
nameCol <- 2
conCol <- 3
expCol <- 4
ttestCol <- 5
#stimCol <- 5
#interCol <- 6

acq_name <- c("Pre-learning rest", "Magic trick task block 1", "Magic trick task block 2", 
                  "Magic trick task block 3", "Post-learing rest")

for (acq in 1:length(unique(slices$acq))){
  
  # put data into table
  coverage[acq, acqCol] <- paste(acq)
  coverage[acq, nameCol] <- paste0(acq_name[acq])
  coverage[acq, conCol] <- paste0(round(diff$z_mean[diff$group == "control" & diff$`as.factor(acq)` == acq], digits = 2), 
                                  " (", round(diff$z_sd[diff$group == "control" & diff$`as.factor(acq)` == acq], digits = 2), ")",
                                  " [", diff$z_max[diff$group == "control" & diff$`as.factor(acq)` == acq],"]")
  coverage[acq, expCol] <- paste0(round(diff$z_mean[diff$group == "experimental" & diff$`as.factor(acq)` == acq], digits = 2), 
                                  " (", round(diff$z_sd[diff$group == "experimental" & diff$`as.factor(acq)` == acq], digits = 2), ")",
                                  " [", diff$z_max[diff$group == "experimental" & diff$`as.factor(acq)` == acq],"]")
  
  # conduct t-test
  subset <- slices[slices$acq == acq, ]
  ttest <- t.test(subset$z_diff ~ subset$group)
  coverage[acq,ttestCol] <- paste0("t(",round(ttest$parameter, digits = 3), ") = ", round(ttest$statistic, digits = 3), ", p = ", round(ttest$p.value, digits = 3))
  
  # rm not needed stuff
  rm(subset, ttest)

}

# rename columns
names(coverage) <- c("", "Scan", "Mean control group (SD) [max]", "Mean experimental group (SD) [max]", "Result Welch Two Sample t-Test" )

# write file
xlsx::write.xlsx(coverage, file=filename_tables, sheetName = "Table_4", append = T, row.names = F, showNA = F) # note: row.names contain variables

# create gt Table
names(coverage) <- c(".", "Scan", "Mean control group (SD) [max]", "Mean experimental group (SD) [max]", "Result Welch Two Sample t-Test" )

gt_4 <- gt(data = coverage) %>% 
  tab_source_note(source_note = paste0(desc_t4)) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels(columns = everything())) 
# show gt Table  
gt_4

########## 11. subject motion ########## 

# SECTION SUBJECT MOTION #

# download file from preliminary AFNI processing
osfr::osf_ls_files(project, pattern = "motion.txt") %>%
  osfr::osf_download(conflicts = "overwrite")

# read in file
motion <- read.table("data_motion.txt", header = T, stringsAsFactors = F)

# add columns (group, task, id)
motion$group <- ifelse(grepl("control", motion$scan)== T, "control", 
                       ifelse(grepl("experimental", motion$scan)== T, "experimental", NA))

motion$Task <- ifelse(grepl("magictrickwatching", motion$scan)== T, "Magictrick watching", 
                      ifelse(grepl("rest", motion$scan)== T, "Resting-state", NA))

motion$scan <- gsub("motion.", "", motion$scan)

motion$ID <- gsub("_task.*", "", motion$scan)

motion$id_number <- gsub("sub-control0", "", motion$ID)
motion$id_number <- gsub("sub-experimental0", "", motion$id_number)

motion$order_number <- recode(motion$id_number, 
                              "01" = "01", "02" = "02", "03" = "03", "07" = "04", "09" = "05",  
                              "11" = "06", "13" = "07", "15" = "08", "17" = "09", "19" = "10",  
                              "21" = "11", "23" = "12", "25" = "13", "27" = "14", "29" = "15",  
                              "31" = "16", "33" = "17", "35" = "18", "37" = "19", "39" = "20",  
                              "41" = "21", "43" = "22", "45" = "23", "47" = "24", "49" = "25",  
                              "04" = "01", "05" = "02", "06" = "03", "08" = "04", "10" = "05",  
                              "12" = "06", "14" = "07", "16" = "08", "18" = "09", "20" = "10",  
                              "22" = "11", "24" = "12", "26" = "13", "28" = "14", "30" = "15",  
                              "32" = "16", "34" = "17", "36" = "18", "38" = "19", "40" = "20",  
                              "42" = "21", "44" = "22", "46" = "23", "48" = "24", "50" = "25")

# transfer roll, pitch & yaw from degrees to radians
motion$pitch <- motion$pitch * pi / 180.0
motion$roll <- motion$roll * pi / 180.0
motion$yaw <- motion$yaw * pi / 180.0

# transfer roll, pitch & yaw to mm assuming 5cm head radius
motion$pitch <- motion$pitch * 50
motion$roll <- motion$roll * 50
motion$yaw <- motion$yaw * 50

# write loop to compute motion derivatives for each scan
scans <- unique(motion$scan)
#scans <- scans[1:5]

for (i in seq_along(scans)){
  
  # subset data to match the current scan
  subset <- subset(motion, motion$scan == scans[i])
  
  # replace data with lagged difference (from row 2:end)
  subset[2:dim(subset)[1],2:7] <- diff(as.matrix(subset[,2:7]))
  # replace row 1 with zeroes
  subset[1,2:7] <- 0
  
  # make values absolute
  subset[,2:7] <- abs(subset[,2:7])
  
  # compute Framewise displacement (FD, )
  subset$fd <- rowSums(subset[,2:7])
  
  # determine whether fd is an outlier
  subset$outlier_fd <- is_outlier(subset$fd)
  
  # combine to new data frame
  if (i == 1){
    relmotion <- subset
  } else {
    relmotion <- rbind(relmotion, subset)
  }
  
}

# quantify framewise displacement over scans
fd_scan <- relmotion %>%
  dplyr::group_by(ID, scan) %>%
  dplyr::summarise(fd_mean_scan = mean(fd), fd_sd_scan = sd(fd), fd_med_scan = median(fd), fd_mad_scan = mad(fd),
                   fd_min_scan = min(fd), fd_max_scan = max(fd), volumes_scan = n())
psych::describe(fd_scan$fd_mean_scan)

# quantify framewise displacement over subjects
fd_subj <- fd_scan %>%
  dplyr::group_by(ID) %>%
  dplyr::summarise(fd_mean_subj = mean(fd_mean_scan), fd_sd_subj = sd(fd_mean_scan), 
                   #fd_med_subj = median(fd_med_scan), fd_mad_subj = mad(fd_med_scan),
                   fd_min_subj = min(fd_mean_scan), fd_max_subj = max(fd_mean_scan), number_scans = n())
psych::describe(fd_subj$fd_mean_subj)

# CREATE FIGURE 4 #

# create column with id for annotation
relmotion$annotation <- ifelse(relmotion$fd == 0 & grepl("magictrickwatching_run-1", relmotion$scan) == T, relmotion$id_number, "")

# define size of y coordinate
y_mot <- max(relmotion$fd)*1.2

# ggplot command figure 4a
gg_relmot <- ggplot(relmotion, aes(order_number, fd, fill = Task, label = annotation)) + 
  geom_hline(yintercept=0.5, linetype="dashed", color = "gray") +
  geom_split_violin() + 
  theme_bw() + 
  facet_grid(group ~ .) + 
  stat_summary(fun.data=data_summary, geom = "crossbar", width = 0.25, fatten = 1, show.legend = F, position = position_dodge(width = .25), color = "grey20") +
  scale_fill_grey(start = 0.5, end = .9) +
  #ggtitle("Plot of framewise displacement within each subject by group and task") +
  xlab("Subject number (within group)") + ylab("Framewise displacement (mm)") + 
  theme(legend.position="none") +
  coord_cartesian(ylim = c(0, y_mot)) +
  geom_label_repel(aes(label = annotation, fill = group), size = 3, nudge_y = y_mot, direction = "y", hjust = 0.5, segment.size = 0.2, segment.color = 'transparent', fill = "lightgray")

# ggplot command figure 4 violin
gg_relmot <- ggplot(relmotion, aes(order_number, fd, fill = Task, label = annotation)) + 
  geom_hline(yintercept=0.5, linetype="dashed", color = "gray") +
  geom_split_violin() + 
  theme_bw() + 
  facet_grid(group ~ .) + 
  stat_summary(fun.data=data_summary, geom = "crossbar", width = 0.25, fatten = 1, show.legend = F, position = position_dodge(width = .25), color = "grey20") +
  scale_fill_grey(start = 0.5, end = .9) +
  #ggtitle("Plot of framewise displacement within each subject by group and task") +
  xlab("Subject number (within group)") + ylab("Framewise displacement (mm)") + 
  theme(legend.position="bottom") +
  coord_cartesian(ylim = c(0, y_mot)) +
  geom_label_repel(aes(label = annotation, fill = group), size = 3, nudge_y = y_mot, direction = "y", hjust = 0.5, segment.size = 0.2, segment.color = 'transparent', fill = "lightgray")

# create column with id for annotation
relmotion$annotation <- ifelse(relmotion$fd == 0 & grepl("magictrickwatching_run-1", relmotion$scan) == T, relmotion$id_number, "")

# remove outlier
relmotion_clean <- subset(relmotion, relmotion$outlier_fd == F)

# define size of y coordinate
y_mot <- max(relmotion_clean$fd)*1.2

# ggplot command figure 4 hisogram
gg_relmot <- ggplot(relmotion_clean, aes(order_number, fd, fill = Task, label = annotation)) + 
  geom_hline(yintercept=0.5, linetype="dashed", color = "gray") +
  geom_boxplot(outlier.size = 0.5, notch = T) + 
  theme_bw() + 
  facet_grid(group ~ .) + 
  #stat_summary(fun.data=data_summary, geom = "crossbar", width = 0.25, fatten = 1, show.legend = F, position = position_dodge(width = .25), color = "grey20") +
  scale_fill_grey(start = 0.5, end = .9) +
  #ggtitle("Plot of framewise displacement within each subject by group and task") +
  ylab("Framewise displacement (mm)") + 
  theme(legend.position="bottom") +
  coord_cartesian(ylim = c(0, y_mot)) +
  geom_label_repel(aes(label = annotation, fill = group), size = 3, nudge_y = y_mot, direction = "y", hjust = 0.5, segment.size = 0.2, segment.color = 'transparent', fill = "lightgray") + 
  theme(axis.title.x=element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank())
gg_relmot

ggsave("Figure4.jpeg", width = 25, height = 15, unit = "cm")


########## 12. temporal signal-to-noise ratio ########## 

# SECTION tSNR #

# download file from preliminary AFNI processing
osfr::osf_ls_files(project, pattern = "TSNR.txt") %>%
  osfr::osf_download(conflicts = "overwrite")

# read in file
tsnr <- fread("data_TSNR.txt")

# add columns (group, task, id)
tsnr$scan <- gsub("values.TSNR.", "", tsnr$scan)
tsnr[, c('group'):=1]
tsnr$group <- ifelse(grepl("control", tsnr$scan)== T, "control", 
                     ifelse(grepl("experimental", tsnr$scan)== T, "experimental", NA))
tsnr[, c('Task'):=1]
tsnr$Task <- ifelse(grepl("magictrickwatching", tsnr$scan)== T, "Magic trick watching", 
                    ifelse(grepl("rest", tsnr$scan)== T, "Resting-state", NA))
tsnr[, c('ID'):=1]
tsnr$ID <- gsub("_task.*", "", tsnr$scan)

tsnr[, c('id_number'):=1]
tsnr$id_number <- gsub("sub-control0", "", tsnr$ID)
tsnr$id_number <- gsub("sub-experimental0", "", tsnr$id_number)

tsnr[, c('order_number'):=1]
tsnr$order_number <- recode(tsnr$id_number, 
                            "01" = "01", "02" = "02", "03" = "03", "07" = "04", "09" = "05",  
                            "11" = "06", "13" = "07", "15" = "08", "17" = "09", "19" = "10",  
                            "21" = "11", "23" = "12", "25" = "13", "27" = "14", "29" = "15",  
                            "31" = "16", "33" = "17", "35" = "18", "37" = "19", "39" = "20",  
                            "41" = "21", "43" = "22", "45" = "23", "47" = "24", "49" = "25",  
                            "04" = "01", "05" = "02", "06" = "03", "08" = "04", "10" = "05",  
                            "12" = "06", "14" = "07", "16" = "08", "18" = "09", "20" = "10",  
                            "22" = "11", "24" = "12", "26" = "13", "28" = "14", "30" = "15",  
                            "32" = "16", "34" = "17", "36" = "18", "38" = "19", "40" = "20",  
                            "42" = "21", "44" = "22", "46" = "23", "48" = "24", "50" = "25")

tsnr[, c('observation'):=1]
tsnr$observation <- with(tsnr, ave(TSNR, ID, FUN= function(x) rev(seq_along(x))))
sum(tsnr$observation == 1)

# quantify tsnr over scans
tsnr_scan <- tsnr %>%
  dplyr::group_by(ID, scan) %>%
  dplyr::summarise(tsnr_mean_scan = mean(TSNR), tsnr_sd_scan = sd(TSNR), tsnr_med_scan = median(TSNR), tsnr_mad_scan = mad(TSNR),
                   tsnr_min_scan = min(TSNR), tsnr_max_scan = max(TSNR), voxels_tsnr_mask = n())
psych::describe(tsnr_scan$tsnr_mean_scan)

# quantify tsnr over subjects
tsnr_subj <- tsnr_scan %>%
  dplyr::group_by(ID) %>%
  dplyr::summarise(tsnr_mean_subj = mean(tsnr_mean_scan), tsnr_sd_subj = sd(tsnr_mean_scan), 
                   tsnr_min_subj = min(tsnr_mean_scan), tsnr_max_subj = max(tsnr_mean_scan))
psych::describe(tsnr_subj$tsnr_mean_subj)

# CREATE FIGURE 4b #

# create column with id for annotation
tsnr$annotation <- ifelse(tsnr$observation == 1, tsnr$id_number, "")

# define size of y coordinate
y_tsnr <- max(tsnr$TSNR)*1.2

# ggplot command figure 4b
gg_tsnr <- ggplot(tsnr, aes(order_number, TSNR, fill = Task, label = annotation)) + 
  geom_split_violin() + 
  theme_bw() + 
  facet_grid(group ~ .) + 
  stat_summary(fun.data=data_summary, geom = "crossbar", width = 0.25, fatten = 1, show.legend = F, position = position_dodge(width = .25), color = "grey20") +
  #stat_summary(fun.data=data_summary, size = 0.1, position = position_dodge(0.5), show.legend = FALSE) + 
  scale_fill_grey(start = 0.5, end = .9) +
  xlab("Subject number (within group)") + ylab("tSNR  values (voxels inside mask)") + 
  theme(legend.position="none") +
  coord_cartesian(ylim = c(0, y_tsnr)) +
  geom_label_repel(aes(label = annotation, fill = group), size = 3, nudge_y = y_tsnr, direction = "y", hjust = 0.5, segment.size = 0.2, segment.color = 'transparent', fill = "lightgray")

# ggplot command figure 5a
gg_tsnr <- ggplot(tsnr, aes(order_number, TSNR, fill = Task, label = annotation)) + 
  geom_split_violin() + 
  theme_bw() + 
  facet_grid(group ~ .) + 
  stat_summary(fun.data=data_summary, geom = "crossbar", width = 0.25, fatten = 1, show.legend = F, position = position_dodge(width = .25), color = "grey20") +
  #stat_summary(fun.data=data_summary, size = 0.1, position = position_dodge(0.5), show.legend = FALSE) + 
  scale_fill_grey(start = 0.5, end = .9) +
  ylab("tSNR  values (voxels inside mask)") + 
  theme(legend.position="bottom") +
  coord_cartesian(ylim = c(0, y_tsnr)) +
  geom_label_repel(aes(label = annotation, fill = group), size = 3, nudge_y = y_tsnr, direction = "y", hjust = 0.5, segment.size = 0.2, segment.color = 'transparent', fill = "lightgray") +
  theme(axis.title.x=element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank())
gg_tsnr
ggsave("Figure5a.jpeg", width = 25, height = 8, unit = "cm")

# combine data from brain coverage, motion, and tSNR
all_scan <- merge(extents_scan, fd_scan, by = c("ID", "scan"))
all_scan <- merge(all_scan, tsnr_scan, by = c("ID", "scan"))

all_subj <- merge(extents_subj, fd_subj, by = c("ID"))
all_subj <- merge(all_subj, tsnr_subj, by = c("ID"))

# save data
write.csv(all_subj, file = paste0(dataset_name, "_scan_subj_sum.csv"), row.names = F)

########## LAST. Create Online-only Tables ########## 

# CREATE STIMULI TABLE FOR PAPER (i.e. Online-only Table 1)

# add cue image
stim_all$cue <- paste0(stim_all$stimID, "_cue.png")

# marker information
stim_all <- merge(stim_all, marker, by = "stimID", all.x = T)

# select relevant columns
stim_all$duration <- paste0(stim_all$vidFileDuration, " (", stim_all$vidFileDuration_withoutMock, ")")
stim_info <- stim_all[,c("experiment", "stimID", "Name", "Credit", #"vidFileName", "duration", "cue",
                         "Phenomena Category", "Materials", "Description", 
                         "Recognition.option.1", "Recognition.option.2", "Recognition.option.3", "Recognition.option.4" )]
# order by file name
stim_info <- stim_info[order(stim_info$experiment, stim_info$stimID),] 

# rename columns
names(stim_info) <- c("Occurance", "Stimulus ID", "Name", "Credit", #"Video file name", "Video duration (without mock video)", "Cue image file name",
                      "Phenomena category", "Materials", "Description", 
                      "Recognition option 1", "Recognition option 2", "Recognition option 3", "Recognition option 4")

# write file
xlsx::write.xlsx(stim_info, file=filename_tables, sheetName = "Online-only Table_1", append = T, row.names = F, showNA = F) # note: row.names contain variables

# create gt Table
gt_x1 <- gt(data = stim_info) %>% 
  tab_source_note(source_note = paste0(desc_x1)) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels(columns = everything())) 
# show gt Table  
gt_x1

# CREATE MARKER TABLE FOR PAPER (i.e. Online-only Table 2)

# create object containing the timings of each magic trick marker and transform this into long format
timing <- stim_all[,c("stimID",  "vidFileName", "duration", "cueImage", 
                      "momentOfSurprise_1",
                      "momentOfSurprise_2",
                      "momentOfSurprise_3", 
                      "momentOfSurprise_4",
                      "momentOfSurprise_5",
                      "momentOfSurprise_6", 
                      "momentOfSurprise_7",
                      "additionalMarker_momentOfSurprise_1", 
                      "additionalMarker_momentOfSurprise_2", 
                      "mainMomentOfSurprise")]
timing_long <- reshape2::melt(timing, id.vars=c("stimID",  "vidFileName", "duration",  "mainMomentOfSurprise"), value.name = "timing")

# create object containing the description of each magic trick marker and transform this into long format
description <- stim_all[,c("stimID",  "vidFileName", "duration", "cue",
                           "momentOfSurprise_1_DESCRIPTION",
                           "momentOfSurprise_2_DESCRIPTION", 
                           "momentOfSurprise_3_DESCRIPTION",
                           "momentOfSurprise_4_DESCRIPTION",
                           "momentOfSurprise_5_DESCRIPTION",
                           "momentOfSurprise_6_DESCRIPTION",
                           "momentOfSurprise_7_DESCRIPTION",
                           "ADDITIONAL.marker.for.moment.1.Description",
                           "ADDITIONAL.marker.for.moment.2.Description",
                           "mainMomentOfSurprise")]

description_long <- reshape2::melt(description, id.vars=c("stimID",  "vidFileName", "duration", "mainMomentOfSurprise"), value.name = "description")

# recode the names of description_long$variable and merge both data sets
description_long$variable <- ifelse(description_long$variable == "momentOfSurprise_1_DESCRIPTION", "momentOfSurprise_1",
                                    ifelse(description_long$variable == "momentOfSurprise_2_DESCRIPTION", "momentOfSurprise_2",
                                           ifelse(description_long$variable == "momentOfSurprise_3_DESCRIPTION", "momentOfSurprise_3",
                                                  ifelse(description_long$variable == "momentOfSurprise_4_DESCRIPTION", "momentOfSurprise_4",
                                                         ifelse(description_long$variable == "momentOfSurprise_5_DESCRIPTION", "momentOfSurprise_5",
                                                                ifelse(description_long$variable == "momentOfSurprise_6_DESCRIPTION", "momentOfSurprise_6",
                                                                       ifelse(description_long$variable == "momentOfSurprise_7_DESCRIPTION", "momentOfSurprise_7", 
                                                                              ifelse(description_long$variable == "ADDITIONAL.marker.for.moment.1.Description", "additionalMarker_momentOfSurprise_1",
                                                                                     ifelse(description_long$variable == "ADDITIONAL.marker.for.moment.2.Description", "additionalMarker_momentOfSurprise_2",
                                                                                            ifelse(description_long$variable == "cue", "cueImage", 
                                                                                                   NA))))))))))

marker_long <- merge(timing_long, description_long, by =c("stimID",  "vidFileName", "duration", "mainMomentOfSurprise", "variable") )

# recode factor levels of variable and sort data frame
marker_long$var <- factor(marker_long$variable, levels = c("cueImage", "momentOfSurprise_1", "additionalMarker_momentOfSurprise_1", "momentOfSurprise_2", "additionalMarker_momentOfSurprise_2", 
                                                           "momentOfSurprise_3", "momentOfSurprise_4", "momentOfSurprise_5", "momentOfSurprise_6", "momentOfSurprise_7"))
marker_long <- marker_long[order(marker_long$stimID, marker_long$var),] 

# rephrase variables
marker_long$Marker <- ifelse(marker_long$variable == "momentOfSurprise_1", "1. moment of suprise",
                             ifelse(marker_long$variable ==  "momentOfSurprise_2", "2. moment of suprise",
                                    ifelse(marker_long$variable == "momentOfSurprise_3", "3. moment of suprise",
                                           ifelse(marker_long$variable == "momentOfSurprise_4", "4. moment of suprise",
                                                  ifelse(marker_long$variable == "momentOfSurprise_5", "5. moment of suprise",
                                                         ifelse(marker_long$variable == "momentOfSurprise_6", "6. moment of suprise",
                                                                ifelse(marker_long$variable == "momentOfSurprise_7",  "7. moment of suprise",
                                                                       ifelse(marker_long$variable == "additionalMarker_momentOfSurprise_1", "additional marker for 1. moment of suprise",
                                                                              ifelse(marker_long$variable == "additionalMarker_momentOfSurprise_2", "additional marker for 2. moment of suprise",
                                                                                     ifelse(marker_long$variable == "cueImage", "Time stamp of cue image",
                                                                                            NA))))))))))
marker_long$Notes <- ifelse(marker_long$mainMomentOfSurprise == "moment of surprise 1", "Main moment of surprise is the first moment of surprise",
                            ifelse(marker_long$mainMomentOfSurprise == "moment of surprise 2", "Main moment of surprise is the second moment of surprise",
                                   ifelse(marker_long$mainMomentOfSurprise == "moment of surprise 3", "Main moment of surprise is the third moment of surprise",
                                          NA)))

# remove unnecessary rows
marker_long$subset <- ifelse(is.na(marker_long$timing) == F, 1, 0)
marker_long <- subset(marker_long, marker_long$subset == 1)

# remove unnecessary columns
marker_long <- marker_long[,c("stimID", "vidFileName", "duration", "Marker", "var", "timing", "description", "Notes")]

# overwrite unncessary cells
marker_long$stimID <- ifelse(marker_long$var == "cueImage", as.character(marker_long$stimID), NA)
marker_long$vidFileName <- ifelse(marker_long$var == "cueImage", as.character(marker_long$vidFileName), NA)
marker_long$duration <- ifelse(marker_long$var == "cueImage", as.character(marker_long$duration), NA)
marker_long$Notes <- ifelse(marker_long$var == "cueImage", as.character(marker_long$Notes), NA)

#rename columns
names(marker_long) <- c("Stimulus ID", "Video file name", "Video duration (without mock video)", 
                        "Marker", "Variable name in dataset", "Timing", "Description", "Notes")

# write file
xlsx::write.xlsx(marker_long, file=filename_tables, sheetName = "Online-only Table_2", append = T, row.names = F, showNA = F) # note: row.names contain variables

# create gt Table
gt_x2 <- gt(data = marker_long) %>% 
  tab_source_note(source_note = paste0(desc_x2)) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels(columns = everything())) 
# show gt Table  
gt_x2

# CREATE VARIABLE DICTIONARY FOR PAPER (i.e. Online-only Table 1)

exp_data <- read.csv(paste0(dataset_name, "_experimental_data.csv"))

Variable <- names(exp_data)

Explanation <- c(
  "subject ID",
  "BIDS identifier",
  "group: exp = experimental, cont = control",
  "number of trial order task",
  "task block",
  "acquisition within block",
  "time stamp (in secs) start of block",
  "time stamp (in secs) end of block",
  "half of the flip interval applied as timing correction (in secs) in PTB script",
  "intended jitter interval (in secs) after magic trick display",
  "intended jitter interval (in secs) after curiosity rating",
  "magic trick stimulus ID",
  "file name of magic trick video",
  "trial number in magic trick task",
  "time stamp (in secs) start of trial",
  "time stamp (in secs) end of trial",
  "duration of trial (in secs)",
  "duration of initial fixation at start of each block",
  "time stamp (in secs) of magic trick onset; collected before the video was opened",
  "time stamp (in secs) of magic trick offset; collected after the video was closed",
  "observed display duration (in secs) of magic trick",
  "duration of blank presentation (in secs) between end of magic trick and onset of fixation",
  "time stamp (in secs) of onset of fixation after magic trick display",
  "duration (in secs) of display of fixation after magic trick display",
  "time stamp (in secs) of onset of estimate rating",
  "duration (in secs) of display of estimate rating",
  "response time window for estimate rating",
  "response given in estimate rating",
  "time stamp (in secs) of response in estimate rating",
  "time stamp (in secs) of estimate rating being displayed in white ink",
  "response time for estimate rating",
  "1 if time stamp response estimate > response time window for estimate rating - 3 * timing correction; else 0; subject sum score in other_information.csv ('answer_tooSlow')",
  "time stamp (in secs) of onset of fixation after estimate rating",
  "duration (in secs) of display of fixation after estimate rating",
  "intended duration (in secs) for fixation after estimate rating",
  "time stamp (in secs) of onset of curiosity rating",
  "duration (in secs) of display of curiosity rating",
  "response time window for curiosity rating",
  "response given in curiosity rating",
  "time stamp (in secs) of response in curiosity rating",
  "time stamp (in secs) of curiosity rating being displayed in white ink",
  "response time for curiosity rating",
  "number that was highlighted in red at the beginning of the curiosity rating",
  "number of button presses to move the number to the left and right in the curiosity rating",
  "time stamp (in secs) of onset of fixation after curiosity rating",
  "duration (in secs) of display of fixation after curiosity rating",
  "1 if time stamp response curiosity > response time window for curiosity rating - 3 * timing correction; else 0; subject sum score in other_information.csv ('curiosity_tooSlow')",
  "time stamp (in secs) of offset of mock video",
  "time stamp (in secs) of cue image presentation",
  "time stamp (in secs) of first moment of surprise",
  "time stamp (in secs) of second moment of surprise",
  "time stamp (in secs) of third moment of surprise",
  "time stamp (in secs) of fourth moment of surprise",
  "time stamp (in secs) of fifth moment of surprise",
  "time stamp (in secs) of sixth moment of surprise",
  "time stamp (in secs) of seventh moment of surprise",
  "time stamp (in secs) of first additional marker for moment of surprise",
  "time stamp (in secs) of second additional marker for moment of surprise",
  "trial number in recall block of memory task",
  "response given in cued recall block of memory task",
  "dummy coding of cued recall performance according to strict criteria: 1 if recalled; else 0; subject sum score and percentage out of 36 trials in scores.csv ('cuedRecallStrict_abs and cuedRecallStrict_rel')",
  "dummy coding of cued recall performance according to lenient criteria: 1 if recalled; else 0 subject sum score and percentage out of 36 trials in scores.csv ('cuedRecallLenient_abs and cuedRecallLenient_rel')",
  "1 if cued recall response required further discussion during coding; else 0",
  "comments related to flagging",
  "trial number in recognition block of memory task",
  "response selected in recognition block of memory task",
  "response time for recognition response",
  "response given in confidence rating",
  "response time for response response",
  "dummy coding of recogntion (regardless of confidence): 1 if correct answer chosen; else 0; subject sum score and percentage out of 36 trials in scores.csv ('allConf_abs and allConf_rel",
  "1 if recognition = 1 & confidence > 3; else 0; subject sum score and percentage out of 36 trials in scores.csv ('highConf_abs and highConf_rel",
  "1 if cuedRecallStrict = 1 or recognitionConfLevel_4_5_6 = 1; else 0; subject sum score and percentage out of 36 trials in scores.csv ('rememberedStrictHigh_abs and rememberedStrictHigh_rel",
  "1 if cuedRecallLenient = 1 or recognitionConfLevel_4_5_6 = 1; else 0; subject sum score and percentage out of 36 trials in scores.csv ('rememberedLenientHigh_abs and rememberedLenientHigh_rel"
)

vardict <- data.frame(Variable, Explanation)

xlsx::write.xlsx(vardict, file=filename_tables, sheetName = "Online-only Table_3", append = T, row.names = F, showNA = F) # note: row.names contain variables

# create gt Table
gt_x3 <- gt(data = vardict) %>% 
  tab_source_note(source_note = paste0(desc_x3)) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels(columns = everything())) 
# show gt Table  
gt_x3

