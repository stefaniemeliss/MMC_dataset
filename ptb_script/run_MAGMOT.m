qq% Clear the workspace
close all;
clearvars;

% set wd
version = 'version_fin_withEyetracking';

try
    EXP_DIR = ['/Users/steffimeliss/Dropbox/Reading/PhD/Magic tricks/fmri_study/' version '/'];
    cd(EXP_DIR)
catch
    EXP_DIR = ['/Users/stefaniemeliss/Dropbox/Reading/PhD/Magic tricks/fmri_study/' version '/'];
    cd(EXP_DIR)
end


% get parameter input (optillllklllllklonal)
prompt = {'scanner', 'initial eye tracker calibration', 'do eye tracking', 'debug'};
defaults = {'1', '',  '1', '0'};
title = 'Input: 1 (true) or 0 (false)';
dims = [1 50];
answer = inputdlg(prompt,title,dims,defaults);
% now decode answer
[scanner, initialEyetrackerTest, eyetracking, debug] = deal(answer{:});
scanner = logical(str2double(scanner));
initialEyetrackerTest = logical(str2double(initialEyetrackerTest));
eyetracking = logical(str2double(eyetracking));
debug = logical(str2double(debug));

% ADDITIONAL parameters, most likely not to be changed
dummymode = 0; % can be 0 or; for eye tracking

practice = false;

dryrunscanner = false; % participant is in the scanner using the button box, but there is no trigger as the scan is not running
phantom = false; % scanner is running, but without a participant in it
secondKeyboard = false; % a second keyBoard is attached that is not button box

debug_extreme = false;

% specify which bits of the protocol should be run
preLearningRest = false;
postLearningRest = true;
postDoPostQuestionnaire = true;


% then type: MAGMOT_correctedTimings

MAGMOT_correctedTimings