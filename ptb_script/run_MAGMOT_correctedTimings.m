% Clear the workspace
close all;
clearvars;

% get parameter input (optional)
prompt = {'scanner', 'initial eye tracker calibration', 'do eye tracking', 'practice', 'debug'};
defaults = {'true', '',  'true', 'true', 'false'};
title = 'Input: 1 (true) or 0 (false)';
dims = [1 50];
answer = inputdlg(prompt,title,dims,defaults);
% now decode answer
[scanner, initialEyetrackerTest, eyetracking, practice, debug] = deal(answer{:});

% ADDITIONAL parameters, most likely not to be changed
dummymode = 0; % can be 0 or; for eye tracking

dryrunscanner = false; % participant is in the scanner using the button box, but there is no trigger as the scan is not running
phantom = false; % scanner is running, but without a participant in it
secondKeyboard = false; % a second keyBoard is attached that is not button box

debug_extreme = false;

% specify which bits of the protocol should be run
preLearningRest = true;
postLearningRest = true;
postDoPostQuestionnaire = true;

version = 'version_fin_withEyetracking';

try
    EXP_DIR = ['/Users/steffimeliss/Dropbox/Reading/PhD/Magictricks/fmri_study/' version '/'];
    cd(EXP_DIR)
catch
    EXP_DIR = ['/Users/stefaniemeliss/Dropbox/Reading/PhD/Magictricks/fmri_study/' version '/'];
    cd(EXP_DIR)
end

% then type: MAGMOT_correctedTimings