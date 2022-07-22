% Clear the workspace
close all;
clearvars;
sca;

debug = false; % needed

debug_extreme = false; % needed

eyetracking = false;

scanner = false;

dryrunscanner = false;

practice = true;

version = 'version_fin_withEyetracking';

try
    EXP_DIR = ['/Users/steffimeliss/Dropbox/Reading/PhD/Magictricks/fmri_study/' version '/'];
    cd(EXP_DIR)
catch
    EXP_DIR = ['/Users/stefaniemeliss/Dropbox/Reading/PhD/Magictricks/fmri_study/' version '/'];
    cd(EXP_DIR)
end


% then type: MAGMOT_practice