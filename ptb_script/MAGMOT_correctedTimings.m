%----------------------------------------------------------------------
%                       Experimemtal setup
%----------------------------------------------------------------------

% check for operating system
os = computer; % determine the OS
if strcmp(os(1),'P') % check if PC or mac and change path accordingly
    cd('E:\Pilot Magictricks fMRI');
else
    cd(EXP_DIR);
end

% add path to be able to use the functions saved in EXP dir
addpath(EXP_DIR);

% get parameter input (optional)
prompt = {'subject ID (two digits)', 'fMRI ID', 'group (int, ext)', 'order number (1-25)', 'start block (set 2 or 3 if necessary)', 'number of blocks', 'start trial (1-12; adjust if necessary)'};
defaults = {'', 'MAGMOT_',  '', '', '1', '3', '1'};
answer = inputdlg(prompt, 'Experimental Setup Information', 1, defaults);
% now decode answer
[subject, fMRI, group, orderNumber, startBlock, totalBlocks, startTrial] = deal(answer{:});
orderNumber = str2num(orderNumber);
startBlock = str2num(startBlock); % block to start with
totalBlocks = str2num(totalBlocks); % number of blocks in total
startTrial = str2num(startTrial); % which trial to start with - in case MATLAB breaks at a certain number
motivation = group;
if strcmp(group, 'int')
    motivation = -1;
elseif strcmp(group, 'ext')
    motivation = 1;
else sca;
    disp('*** wrong input of group, start again ***');
    return
end

% get input for eye tracker
if eyetracking
%     if ~dummymode
        if ~IsOctave
            commandwindow;
        else
            more off;
        end
        
        % STEP 1
        % Added a dialog box to set your own EDF file name before opening
        % experiment graphics. Make sure the entered EDF file name is 1 to 8
        % characters in length and only numbers or letters are allowed.
        if IsOctave
            edfFile = 'DEMO';
        else
            prompt = {'Enter tracker EDF file name (1 to 8 letters or numbers)'};
            dlg_title = 'Create EDF file';
            num_lines= 1;
            def     = {'MAGMOT'};
            answer  = inputdlg(prompt,dlg_title,num_lines,def);
            %edfFile= 'DEMO.EDF'
            edfFile = answer{1};
            fprintf('EDFFile: %s\n', edfFile );
        end
%     end 
end

% read in trial order file and select the one corresponding to orderNumer
allTrialOrders = csvread('TrialOrders_best_maxRep-4.csv', 1, 0); % this creates an array with each trialOrder as a column
currentTrialOrder = allTrialOrders(:,orderNumber); % selects the column of allTrialOrders corresponding to orderNumber

% general inputs
betweenRatingFixation = 0.05;
timeoutCuriosity = 6-betweenRatingFixation;
timeoutAnswer = 6;
pre_stim_rest = 2;

if debug_extreme
    timeoutCuriosity = 3;
    timeoutAnswer = 3;
end

if debug
    timeoutCuriosity = 4;
    timeoutAnswer = 4;
end

%----------------------------------------------------------------------
%                       Screen setup
%----------------------------------------------------------------------

% Setup PTB with some default values
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Select the external screen if it is present, else revert to the native screen
screenNumber = max(screens);
% screenNumber = min(screens);

% Seed the random number generator.
rand('seed', sum(100 * clock));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

% define scaling factors
if debug_extreme
    scalingFactor = 0.5;
elseif debug
    scalingFactor = 0.75;
%     scalingFactor = 1;
else
    scalingFactor = 1;
end

% define screen size and font size
pixelsize = [0, 0, scalingFactor*1440, scalingFactor*900];

% Open the screen
Screen('Preference', 'SkipSyncTests', 1); %forgo syncTests
if debug || debug_extreme
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, pixelsize, 32, 2);
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, [], 32, 2);
end

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);
slack = Screen('GetFlipInterval', window)/2;

timingCorrection = slack;

% Set the text size and font
fontSizeBig = round(scalingFactor*50);
fontSizeSmall = round(scalingFactor*30);
Screen('TextSize', window, fontSizeBig);
Screen('TextFont', window, 'Courier');

% hide cursor
HideCursor();

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% set up language settings
feature('DefaultCharacterSet','ISO-8859-1');
Screen('Preference','TextEncodingLocale', 'en_US.ISO8859-1');


%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------

% Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames = round(isiTimeSecs / ifi); %isiTimeFrames roughly equals 1 sec

% Numer of frames to wait before re-drawing
waitframes = 1;

%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% define trigger device and pptResponseDevice
% Determine id for the trigger response
if secondKeyboard
    deviceString = 'Magic Keyboard';
else
    deviceString='932'; %scanner device: both button box and trigger; old button box: deviceString='fORP Interface';
end
computerString='Apple Internal Keyboard / Trackpad'; %scanner device: both button box and trigger; old button box: deviceString='fORP Interface';
[id,name] = GetKeyboardIndices;% get a list of all devices connected

triggerDevice=0;
for i=1:length(name)%for each possible device
    if strcmp(name{i},computerString)%compare the name to the name you want
        experimenterKeyboard=id(i);%grab the correct id, and exit loop
        if length(name) == 1
            triggerDevice = experimenterKeyboard;
        end
    elseif scanner
        if strcmp(name{i},deviceString)%compare the name to the name you want
            triggerDevice=id(i);%grab the correct id, and exit loop
            break;
        end
        %     elseif dryrunscanner
        %         if strcmp(name{i},deviceString)%compare the name to the name you want
        %             triggerDevice=id(i);%grab the correct id, and exit loop
        %             break;
        %         end
    elseif ~scanner && ~secondKeyboard
        triggerDevice = experimenterKeyboard;
        break
    end
end


if triggerDevice==0%%error checking
    error('No device by that name was detected')
    sca;
end


% if taking responses from the button box then participantResponses should be scanner device (same as triggerDevice),
% otherwise can be -1 to take responses from keyboard devices
if phantom
    pptResponseDevice = -1;
else
    pptResponseDevice = triggerDevice;
end

% % use whatever attached keyboard in debug mode
% if debug || debug_extreme
%     pptResponseDevice = -1;
%     triggerDevice = -1;
%     experimenterKeyboard = -1;
% end

% define keyboard names
escape = KbName('ESCAPE'); % used during video presentation
quit = KbName('q'); % used during instructions
experimenterKey = KbName('s');

keysOfInterestButtonbox=zeros(1,256);
if dryrunscanner
        keysOfInterestButtonbox(KbName({'r', 'g', 'b', 'y'}))=1;
elseif ~scanner || secondKeyboard
    keysOfInterestButtonbox(KbName({'h', 'j', 'k', 'l'}))=1; % I might have to change the response ratings accoringly!    
else
    keysOfInterestButtonbox(KbName({'r', 'g', 'b', 'y'}))=1;
end

keysOfInterestTrigger=zeros(1,256);
keysOfInterestTrigger(KbName({'t'}))=1;

keysOfInterestEyeTracking=zeros(1,256);
keysOfInterestEyeTracking(KbName({'Return', 'ESCAPE', 'c', 'd', 'v'}))=1;

%----------------------------------------------------------------------
%                       Define instructions
%----------------------------------------------------------------------

greeting1 = 'Hello and welcome!\n\nThank you very much\nfor participating in the experiment.';
greeting2 = 'Do you feel comfortable?\n\nIf you would like to, you can have\na little wiggle to make\nyourself even more comfortable.\n\nFor the scanning, it is very important\nthat you do not move your head.\n\nSo please try to find a position\nthat is as convenient as possible.';
headscout = 'We are going to run\na short localizer sequence. \n\nPlease keep your head as still as possible\nand continue reading.';
reminder = 'To remind you:\n\nPlease keep your head as still as possible\n\nand do not cross your legs or your arms.';
wait = 'Please wait.\n\nSomeone will talk to you shortly.';
resting = 'With the next sequence,\nwe are measuring your brain activity at rest.\n\nThe scan will last for approximately 10 min.\n You will see a white screen.\n\nPlease keep your eyes open\nand simply look at the white screen.\nYou are allowed to blink as usual.\n\nPlease try to NOT think about anything at all.';
question = 'Do you have any questions?\n\nPlease just ask.\n\n If not, please continue.';
restingStart = 'The screen will turn white shortly.\n\nPlease keep your eyes open\nand try not to think about anything.';
trigger = 'scanning is starting, waiting for trigger';
keyPress = '(press any key to continue)';
keyPressGreen = 'Plese press GREEN key (ring finger)\nto confirm that you read this statement.';
experimenterInput = 'EXPERIMENTER INPUT:\ncontinue or abort';
%-------
answerRating = 'How many people (out of 100)\nare able to correctly figure out the solution?';
curiosityRating = 'Please rate how CURIOUS\nyou were while watching the trick.';
%-------
task0 = 'Great,\nthe eye tracker calibration was successful!';
task1 = 'Do you feel okay?\n\nNext, we are  going to do\nthe actual experiment.\n\n Do you feel ready?\n\nWe will show you the instructions again.\n\n It is going to be the same task\nwe practised earlier.';
fieldmap = 'While you are reading the instructions,\nwe are running the fieldmap.\nSo please keep your head as still as possible.\n\nThere will be a screen asking you\nto wait so that someone can talk to you.\nPlease do so once you get there.';
task2 = 'In this experiment you will be presented\nwith a series of magic tricks.\n\nYour task is to carefully watch the videos\nand try to figure out what has happened.';
task4 = 'Afterwards, you are asked to give\nan estimate of how many people (out of 100)\nare able to correctly\nfigure out the solution to the trick.\n\nPossible answers are the following:\n\n0 - 10 people\n11 - 20 people\n21 - 30 people\n31 or more people';
task5 = 'In addition to that, we would like you\nto rate how curious you were while watching\nthe magic tricks on a scale \n\nfrom 1 (not curious at all) to 7 (very curious)';
task6 = 'For each of the answers,\nyou have 6 seconds. ';
taskExt1 = 'We ask you to answer the question\n"how many people are able to find\nthe solution?" and you can get\n';
taskExt2 = 'To remind you:\n\nWe ask you to answer the question\n"how many people are able to find\nthe solution?" and you can get\n';
taskExt0 = ' an additional 50% bonus payment on top\nof your payment for both tasks (GBP 30.00)\nif you answer all questions correctly.\nThat meanseach correct answer\nis worth an additional GBP 0.80';
% taskExt0 = ' an additional GBP 1.00 per correct answer.';
block1 = 'In total, you will see 36 magic tricks.\nThese will be presented in 3 blocks.\n\nThere will be two breaks in between\nso that you can rest and relax.\n\nPlease try not to move at all\nwhile you do the task.';
block2 = 'The experiment is ready to START.\n\nYou are asked to estimate\nhow many people are able to correctly find\nthe solution to the magic trick.';
taskStart = 'The fixation point will show up shortly.';
%-------
break1_1 = 'Thank you,\nthe first block of the task is finished.\n\nWELL DONE!';
break1_2 = 'Thank you,\nthe second block of the task is finished.\n\nWELL DONE!';
break2 = 'Take a break for as long as you need to.\n\nThe next part of the experiment\nwill start as soon as you are ready.\n\n The task is going to be\nthe same as in the previous block.';
if strcmp(group, 'ext') % extrinsic
    break3 = 'The experiment is ready to CONTINUE.\nYou are again asked to estimate\nhow many people are able to correctly\nfind the solution to the magic trick\nand you can get\n';    
else
    break3 = 'The experiment is ready to CONTINUE.\n\nYou are again asked to estimate\nhow many people are able to correctly\nfind the solution to the magic trick.';
end
%-------
calibrationInstruction = 'We will run the calibration\nof the eye tracker now.\n\nPlease follow the dot on the screen\nwith your eye.';
calibrationScreen = 'Press RETURN (on either simulus or host computer)\nto toggle camera image\n\nPress ESC to output/record\n\nPress C to calibrate\n\nPress V to validate';
calibrationCheck = 'First, we need to do the calibration again.\n\nAfterwards, the task starts!';
driftCorrection = 'Before the start of the next block,\nwe need to check the eye tracker calibration.\nThere will be a fixation target in the\ncentre of the screen. Please look at it.';
%-------
post1 = 'The task is done, GOOD JOB!\n\nThank you very much for completing it.';
quest1 = 'Thank you.\n\nWe are nearly done.';
quest2 = 'We will start the last scan now.\nThis is a structural image of your brain.\nThat means you do not have to do \nanything at all.\n\nIt will take approximately 6 minutes.';
quest3 = 'To prevent you from being too bored,\nwe have prepared a questionnaire.\n\nThis questionnaire is about\nyour opinion of the experiment.';
quest4 = 'Each question can be answered on a scale\nfrom 1 (definitely disagree) to 7 (definitely\nagree). Similar to the curiosity\nratings, you have to move the red number\nto the number reflecting your opinion.\n\nTo move it to the left,\nplease use your index finger (blue button).\n\nTo move it to the right,\nplease use your middle finger (yellow button).\n\nTo confirm your selection,\nplease use your pinkie (red button).';
t1Start = 'The structural scans\nand the questionnaire will start shortly';
endOfExperiment = 'The experiment is over now.\n\nMany thanks for your help!\n\nWe are waitimg for the scan to finish\nand will move you out of the scanner shortly.';
keyExit = '(press any key to EXIT)';
%-------
q1 = 'It was fun to do the experiment.';
q2 = 'It was boring to do the experiment.';
q3 = 'It was enjoyable to do the experiment.';
q4 = 'I was totally absorbed in the experiment.';
q5 = 'I lost track of time.';
q6 = 'I concentrated on the experiment.';
q7 = 'The task was interesting.';
q8 = 'I liked the experiment.';
q9 = 'I found working on the task interesting.';
q10 = 'The experiment bored me.';
q11 = 'I found the experiment fairly dull.';
q12 = 'I got bored.';
q13 = 'I put a lot of effort into this.';
q14 = 'I did not try very hard\nto do well at this activity.';
q15 = 'I tried very hard on this activity.';
q16 = 'It was important to me to do well at this task.';
q17 = 'I did not put much energy into this.';
q18 = 'I did not feel nervous at all while doing this.';
q19 = 'I felt very tense while doing this activity.';
q20 = 'I was very relaxed in doing this experiment.';
q21 = 'I was anxious while working on this task.';
q22 = 'I felt pressured while doing this task.';
q23 = 'I tried to find out how many people\nwill be able to find the solution.';
q24 = 'I was able to see the magic tricks properly.';


% define instruction lists for loop %
% instrListStart = {greeting1, greeting2, headscout, reminder, wait, resting, question, reminder};
instrListStart = {greeting1, greeting2, headscout, resting, question, reminder};
instrListEyetracking = {calibrationInstruction, calibrationScreen};

% here taskExtScreen is shown only for Ext group
instrListBlock1 = {wait, block1, block2, reminder}; % in between drift check eye tracker
if eyetracking
    instrListTask = {task0, task1, fieldmap, task2, task4, task5, task6};
    instrListBlock1 = {wait, block1, block2, calibrationCheck, reminder};
    instrListBlock2 = {break1_1, wait, break2, question, break3, calibrationCheck, reminder};
    instrListBlock3 = {break1_2, wait, break2, question, break3, calibrationCheck, reminder};
else
    instrListTask = {task1, fieldmap, task2, task4, task5, task6};
    instrListBlock1 = {wait, block1, block2, reminder};
    instrListBlock2 = {break1_1, wait, break2, question, break3,  reminder};
    instrListBlock3 = {break1_2, wait, break2, question, break3, reminder};
end
instrListPost = {post1, wait, resting, question, reminder};
instrListQuest = {quest1, quest2, quest3, quest4, question, reminder, t1Start};
instrListQuest = {quest1, quest2, reminder, quest3, quest4};
questionnaire = {q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, ...
    q15, q16, q17, q18, q19, q20, q21, q22, q23, q24};
questionnaire = questionnaire(randperm(length(questionnaire)));

%----------------------------------------------------------------------
%                     Conditions and trials
%----------------------------------------------------------------------

% setting up a folder for each participant
SAVE_DIR = fullfile(pwd, 'behavioural_data', subject);
mkdir(SAVE_DIR);

% clear stimuli folder of potential hidden files
vidLoc = fullfile(EXP_DIR,'magic tricks');
cd(vidLoc);
delete ._*

% create vid list
cd(EXP_DIR);
vidList = dir(fullfile('magic tricks','*.mp4')); % find .mp4 files in the 'vid' directory
vidList = {vidList.name}; % we just need the filenames, this is our trial list
sort(vidList); % sort vidList ascending

% define number of trials in total and per block
numTrials = length(vidList);

if debug
    numTrials = 6; %debug
elseif debug_extreme
    numTrials = 3; %debug
end

trialList = numTrials/totalBlocks; % n in block
trialListBlock = trialList;

% jittering
filenameVideo = fullfile(EXP_DIR, 'videoJitter.tsv');
fileID = fopen(filenameVideo);
J = textscan(fileID, '%f');
fclose(fileID);
jitterVideo = J{1,1}';

filenameRating = fullfile(EXP_DIR, 'ratingJitter.tsv');
fileID = fopen(filenameRating);
J = textscan(fileID, '%f');
fclose(fileID);
jitterRating = J{1,1}';

% post questionnaire
numQuestions = length(questionnaire);

% information to send marker: which events are important
eventListName = fullfile(EXP_DIR, 'whichTimings.tsv');
fileID = fopen(eventListName);
eventList = textscan(fileID, '%s %s %s %s %s %s %s %s %s %s %s');
fclose(fileID);
eventList = eventList{1,1}'; 

% information to send marker: what are the timestamps for each event?
timingsName = fullfile(EXP_DIR, 'allTimingsCell.tsv'); 
fileID = fopen(timingsName);
timingList = textscan(fileID, '%s %f %f %f %f %f %f %f %f %f %f %f');
fclose(fileID);
vidListTransposed = timingList{1,1};
timingListMat = cell2mat(timingList(2:size(timingList,2)));
timingListCell = num2cell(timingListMat);
timingListAll = [timingListCell, vidListTransposed];
timingListAllNamed = [timingListAll;eventList]; %timingListAllNamed{row, column}

% dynamically define number of tricks and events from the cell array created
numTricks = size(timingListAllNamed,1)-1;
nameTricksColumn = size(timingListAllNamed,2);
numEvents = size(timingListAllNamed,2)-1;
nameEventsRow = size(timingListAllNamed,1);
tricks = timingListAllNamed(1:numTricks,nameTricksColumn); % this refers to the column with the names of the magic tricks in it
events = timingListAllNamed(nameEventsRow,1:numEvents); % this refers to the row with the names of the events in it

%----------------------------------------------------------------------
%                     Make response matrixes
%----------------------------------------------------------------------

varsOfInterestTaskName = {'subject' 'fMRI' 'group' 'motivation' 'orderNumber' 'block' 'triggerTaskBlockRaw' 'startBlock' 'endBlock' 'stimID' ...
    'trial' 'whichVid' 'tTrialStart' 'tTrialEnd' 'durationTrial' 'fixationInitialDuration' 'pre_stim_rest'... 
    'displayVidOnset' 'displayVidOffset' 'displayVidDuration'... 
    'fixationPostVidOnset' 'fixationPostVidDuration' 'jitterVideo_trial' 'displayAnswerOnset' 'displayAnswerDuration' 'timeoutAnswer' 'responseAnswer' 'timestampAnswer' 'timestampAnswerWhite' 'rtAnswer' ...
    'fixationPostAnswerOnset' 'fixationPostAnswerDuration' 'betweenRatingFixation' 'displayCuriosityOnset' 'displayCuriosityDuration' 'timeoutCuriosity' 'responseCuriosity' 'timestampCuriosity' 'timestampCuriosityWhite' 'rtCuriosity'... 
    'startValueCuriosity' 'clicksCuriosity' 'fixationPostCuriosityOnset' 'fixationPostCuriosityDuration' 'jitterRating_trial' };

varsOfInterestAllName = [varsOfInterestTaskName, events]; % combines elements of event list with varsOfInterestTask

varsOfInterestQuestName = {'subject' 'fMRI' 'group' 'motivation' 'question' 'text' 'startValueQuestion' 'clicksQuestion' 'answerQuestion' 'questionOnset' 'questionOffset' 'rtAnswer'};

% use this information to create 
respMatTask = cell(numTrials, size(varsOfInterestAllName,2));
respMatQuest = cell(numQuestions, size(varsOfInterestQuestName,2));

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

if initialEyetrackerTest
    if eyetracking
        MAGMOT_EyeLinkInit
        fprintf('DEBUG: back to main script, after MAGMOT_EyeLinkInit\n');
    end
    
    Screen('TextSize', window, fontSizeBig);
    DrawFormattedText(window, 'Experimenter: press Q'    ,...
        'center', 'center', white);
    Screen('Flip', window);
    
    keyIsDown = 0;
    while ~keyIsDown %wating for any key press
        [keyIsDown,secs, keyCode] = KbCheck(experimenterKeyboard); %checking computer keyboard
        if keyCode(quit) == 1 % if q is pressed, experiment aborts
            Screen('Flip', window);
            Priority(0);
            KbStrokeWait;
            sca;
        else
            keyIsDown = 0;
        end
    end
end


totalTrials = startTrial - 1;

% % % start of the loop for each block % % %

for block = startBlock:totalBlocks
    
    startTrialBlock = startTrial + (block-1)*trialList;
    trialListBlock = startTrialBlock + trialList - 1;
    %     trialListBlock = startBlock*trialList;
    
    
    % displaying instructions depending on block %
    % ---------------  BLOCK 1   --------------- %
    % first general MRI instructions, followed by resting state,  then instructions for task
    
    if block == 1
        
        if preLearningRest
            %---------------welcome & instruction scout + rs fmri   --------------- %
            for instr = 1:length(instrListStart) %inqqstr how to behave while scanning
                Screen('TextSize', window, fontSizeBig);
                DrawFormattedText(window, instrListStart{instr}    ,...
                    'center', 'center', white);
                
                Screen('TextSize', window, fontSizeSmall); %press anx key to continue
                DrawFormattedText(window, keyPress,...
                    'center', screenYpixels*0.9, white);
                Screen('Flip', window);
                
                KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
                
                MAGMOT_waitForAnyKeyPress
            end
            
            
            % ---------------  pre learning resting state   --------------- %
            MAGMOT_restingstate
        end
        
        % ---------------  initial eye tracking calibration   --------------- %
        if eyetracking
            MAGMOT_EyeLinkInit
            fprintf('DEBUG: back to main script, after MAGMOT_EyeLinkInit\n');
        end
        
        
        % ---------------  instructions task block 1   --------------- %
        for instr = 1:length(instrListTask) %how to do the task
            Screen('TextSize', window, fontSizeBig);
            DrawFormattedText(window, instrListTask{instr},...
                'center', 'center', white);
            
            Screen('TextSize', window, fontSizeSmall);
            DrawFormattedText(window, keyPress,... %press anx key to continue
                'center', screenYpixels*0.9, white);
            Screen('Flip', window);
            
            % Create the KbQueue
            KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
            
            MAGMOT_waitForAnyKeyPress;
        end
        
        
        % ------------- show screen for reward to exp group ------------ %
        if strcmp(group, 'ext') % extrinsic
            Screen('TextSize', window, fontSizeBig);
            DrawFormattedText(window, taskExt1,...
                'center', screenYpixels*0.2, white);
            DrawFormattedText(window, taskExt0,...
                'center', screenYpixels*0.4, [0 1 0]); % in GREEN
            DrawFormattedText(window, keyPressGreen,... %press GREEN key to continue
                'center', screenYpixels*0.8, white);
            Screen('Flip', window);
            
            KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
            
            MAGMOT_waitForGreenKeyPress
            
        end
        
        % ---------------  last instructions for task   --------------- %
        for instr = 1:length(instrListBlock1)
            Screen('TextSize', window, fontSizeBig);
            DrawFormattedText(window, instrListBlock1{instr}    ,...
                'center', 'center', white);
            
            Screen('TextSize', window, fontSizeSmall);
            DrawFormattedText(window, keyPress,... % press any key
                'center', screenYpixels*0.9, white);
            Screen('Flip', window);
            
            KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
            
            MAGMOT_waitForAnyKeyPress
            
        end
        
        
        % displaying instructions depending on block %
        % ---------------  BLOCK 2   --------------- %
        % instructions for the second block to begin %
        
    elseif block == 2
        
        % ---------------  instructions task block 2   --------------- %
        for instr = 1:length(instrListBlock2)
            
            if strcmp(instrListBlock2{instr}, break3) && strcmp(group, 'ext')
                Screen('TextSize', window, fontSizeBig);
                DrawFormattedText(window, instrListBlock2{instr},...
                    'center', screenYpixels*0.2, white);
                
                DrawFormattedText(window, taskExt0,... % ' an additional GBP 1.00 per correct answer.'
                    'center', screenYpixels*0.5, [0 1 0]); %GREEN
                DrawFormattedText(window, keyPressGreen,... %press GREEN key to continue
                    'center', screenYpixels*0.8, white);
                Screen('Flip', window);
                
                KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
                
                MAGMOT_waitForGreenKeyPress
            else
                Screen('TextSize', window, fontSizeBig);
                DrawFormattedText(window, instrListBlock2{instr},...
                    'center', 'center', white);
                
                Screen('TextSize', window, fontSizeSmall);
                DrawFormattedText(window, keyPress,... %press any key
                    'center', screenYpixels*0.9, white);
                Screen('Flip', window);
                
                KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
                
                MAGMOT_waitForAnyKeyPress
            end
        end
        
        
        % displaying instructions depending on block %
        % ---------------  BLOCK 3   --------------- %
        % instructions for the third block to begin  %
        
    elseif block == 3
        
        for instr = 1:length(instrListBlock3)
            if strcmp(instrListBlock3{instr}, break3) && strcmp(group, 'ext')
                Screen('TextSize', window, fontSizeBig);
                DrawFormattedText(window, instrListBlock3{instr},...
                    'center', screenYpixels*0.2, white);
                
                DrawFormattedText(window, taskExt0,... % ' an additional GBP 1.00 per correct answer.'
                    'center', screenYpixels*0.5, [0 1 0]); %GREEN
                DrawFormattedText(window, keyPressGreen,... %press GREEN key to continue
                    'center', screenYpixels*0.8, white);
                Screen('Flip', window);
                
                KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
                
                MAGMOT_waitForGreenKeyPress
            else
                Screen('TextSize', window, fontSizeBig);
                DrawFormattedText(window, instrListBlock3{instr},...
                    'center', 'center', white);
                
                Screen('TextSize', window, fontSizeSmall);
                DrawFormattedText(window, keyPress,... %press any key
                    'center', screenYpixels*0.9, white);
                Screen('Flip', window);
                
                KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
                
                MAGMOT_waitForAnyKeyPress
            end
        end
    else
        sca;
        disp('*** wrong input, start again ***');
        return
    end
    
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    % % %  magic trick presentation + task + curiosity rating   % % %
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    
    
    % Do calibration / drift check at beginning of the block
    if eyetracking
        % make sure we're still connected.
        if Eyelink('IsConnected')~=1 && dummymode == 0
            fprintf('not connected, clean up\n');
            Eyelink( 'Shutdown');
            Screen('CloseAll');
            return;
        end
        % drift correction
        EyelinkDoDriftCorrection(el);
    end
    
    % 
    
    % show waiting for scanner text
    Screen('TextSize', window, fontSizeBig);
    DrawFormattedText(window, taskStart ,...
        'center', 'center', white);
    Screen('TextSize', window, fontSizeSmall);
    DrawFormattedText(window, trigger, 'center', screenYpixels*0.9, white);
    waitingForScannerTaskBlock = Screen('Flip', window);
    
    % prepare inital white fixation
    Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
    
    % waiting for scanner signal to start task fmri
    % as soon as trigger is received, flip white fixation
    if scanner
        KbQueueCreate(triggerDevice, keysOfInterestTrigger);	% First queue: scannerSignal
        KbQueueStart(triggerDevice);
        KbQueueWait(triggerDevice); % Wait until the 't' key signal is sent
        triggerTaskBlockRaw = Screen('Flip', window); % flip screen to show white fixation
        %         WaitSecs(1); % to make sure that we reach our pre_stim_rest
        KbQueueRelease(triggerDevice);
        
    else
        nextSec = GetSecs+2;
        triggerTaskBlockRaw = Screen('Flip', window, ceil(nextSec)); % flip screen to show white fixation
    end
    
    % ---------------  start of the loop for each trial   --------------- %
    
    for trial = startTrialBlock:trialListBlock
        
        % general setups %
        tTrialStart = GetSecs;
        totalTrials = totalTrials + 1; 
        whichVid = currentTrialOrder(trial); % this gives the correct index for which video to select corresponding to currentTrialOrder
        stimID = vidList(whichVid); % using whichVid as index, we select the corresponding magic trick and encode it as stimID
        moviename = char(fullfile(vidLoc, stimID));
        vidfile = char(stimID);
        fprintf('Trial %d/%d, magic trick %s\n', trial, length(vidList), vidfile);
        
        % create an object containing the marker information for each magic trick
        for j = 1:numTricks
            if strcmp(string(timingListAllNamed{j,nameTricksColumn}), string(stimID)) == true % find the correct row
                rowWithDataforThisTrick = j;
                timingsForThisTrick = timingListAllNamed(rowWithDataforThisTrick,1:numEvents); % get the timings associated with the current trick
                


   
                % idea: replace the NaNs with -Inf: a(isnan(a)) = Inf;
                z = cellfun(@replace_nan, timingsForThisTrick, repmat( {Inf}, size(timingsForThisTrick,1), size(timingsForThisTrick,2)) , 'UniformOutput', 0);
                
                % then sort timingsForThisTrick in ascending order
                [ranks_ordered, idx] = sort(cell2mat(timingsForThisTrick), 'ascend'); % get index for timings in ascending order
                [ranks_ordered2, idx2] = sort(cell2mat(z), 'ascend'); % get index for timings in ascending order
                % then replace the Inf with NaNs again: a(isinf(a)) = NaN
                for ll = 1:length(z)
                    if z{ll}== Inf
                        z{ll} = NaN;
                    end
                end
                
                
                timingsForThisTrickOrdered = timingsForThisTrick(idx); % order the timings in ascending order
                timingsForThisTrickOrdered2 = timingsForThisTrick(idx2); % order the timings in ascending order
                eventsOrdered = events(idx); % order events in ascending order
                eventsOrdered2 = events(idx2); % order events in ascending order
                combinedInfoForThisTrickOrdered = [eventsOrdered; timingsForThisTrickOrdered]; % combine both in one object
                combinedInfoForThisTrickOrdered2 = [eventsOrdered2; timingsForThisTrickOrdered2]; % combine both in one object
%                 combinedInfoForThisTrickOrdered{3,numEvents} = []; % create a third row for this object to add actual display timings in there later
            end
        end
        
        
        % do eye tracking related operations
        if eyetracking
            if ~dummymode
                % Sending a 'TRIALID' message to mark the start of a trial in Data Viewer
                Eyelink('Message', 'TRIALID %d', trial);
                % This supplies the title at the bottom of the eyetracker display
                Eyelink('command', 'record_status_message "TRIAL %d/%d  %s"', trial, length(vidList), vidfile);
                % Before recording, we place reference graphics on the host display
                % Must be offline to draw to EyeLink screen
                Eyelink('Command', 'set_idle_mode');
                % clear tracker display and draw box at center
                Eyelink('Command', 'clear_screen 0');
%                 Eyelink('command', 'draw_box %d %d %d %d 15', round(screenXpixels/2-50), round(screenYpixels/2-50), round(screenXpixels/2+50), round(screenYpixels/2+50));
                Eyelink('command', 'draw_box %d %d %d %d 15', round(screenXpixels/2-1280/2), round(screenYpixels/2-720/2), round(screenXpixels/2+1280/2), round(screenYpixels/2+720/2));
                
                % start recording
                Eyelink('StartRecording');
                Eyelink('Message', 'startOfTrial %d %s', trial ,vidfile);
%                 Eyelink('Message', 'startOfTrial %s',vidfile);
                Eyelink('Message', 'startOfTrial %d',trial);
            end
        end
        
        % check recording only at the beginning of the block
        if trial == startTrialBlock
            if eyetracking
                if ~dummymode
                    % Check recording status, stop display if error
                    error=Eyelink('CheckRecording');
                    if(error~=0)
                        break;
                    end
                end
            end
        end
        
        % waiting for trigger to start video presentation  with TR and  magic trick presentation %
        MAGMOT_showMagictrick
        
        % after video has finished, wait for the next TR and show white fixation
        Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2); % prepare white fixation
        
        if scanner
            KbQueueCreate(pptResponseDevice, keysOfInterestTrigger);	% First queue: scannerSignal
            KbQueueStart(triggerDevice);
            KbQueueWait(triggerDevice); % Wait until the 't' key signal is sent
            fixationPostVidOnset = Screen('Flip', window); % shows white fixation after trigger
            KbQueueRelease;
        else
            if mod(ceil(displayVidDuration),2) == 0
                fixationPostVidOnset = Screen('Flip', window, displayVidOnset  + ceil(displayVidDuration) - timingCorrection); % shows white fixation again
            else
                fixationPostVidOnset = Screen('Flip', window, displayVidOnset  + 1 + ceil(displayVidDuration) - timingCorrection); % shows white fixation again          
            end
        end
        
        if eyetracking
            if ~dummymode
                Eyelink('Message', 'fixationPostVidOnset');
            end
        end
        
        
        % Answer rating %
        MAGMOT_ratingAnswer
        
        % Fixation point before curiosity rating  presented for 2000ms (betweenRatingFixation) %
        Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
        fixationPostAnswerOnset = Screen('Flip', window, displayAnswerOnset + timeoutAnswer - timingCorrection);
        if eyetracking
            if ~dummymode
                Eyelink('Message', 'fixationPostAnswerOnset');
            end
        end
        
        
        
        % Curiousity rating %
        MAGMOT_ratingCuriosity
        
        % prepare the last fixation
        Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
        % show last fixation after curiosity rating as achieved its timeout %
        fixationPostCuriosityOnset = Screen('Flip', window, displayCuriosityOnset + timeoutCuriosity - timingCorrection);
        if eyetracking
            if ~dummymode
                Eyelink('Message', 'fixationPostCuriosityOnset');
            end
        end
        
        
        % prepare blank screen
        Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
        % flip screen after fixation has been displayed for length of jitterRating(trial)
        tTrialEnd = Screen('Flip', window, fixationPostCuriosityOnset + jitterRating(trial) - timingCorrection);
        if eyetracking
            if ~dummymode
                Eyelink('Message', 'endOfTrial %d %s', trial ,vidfile);
            end
        end
        
        % get timings for trial duration %
        endBlock = NaN;
        durationBlock = NaN;
        if trial == trialListBlock
            endBlock = GetSecs;
            durationBlock = endBlock - triggerTaskBlockRaw;
            if eyetracking
                if ~dummymode
                    Eyelink('Message', 'endOfBlock %d', block);
                end
            end
        end
        
        if eyetracking
            if ~dummymode
                Eyelink('StopRecording');
            end
        end
        
        fixationInitialDuration = NaN;
        if totalTrials == 1
            fixationInitialDuration = displayVidOnset - triggerTaskBlockRaw;
        end
        
        % calculating all timings relative to task block onset
        tTrialStart = tTrialStart - triggerTaskBlockRaw; 
        tTrialEnd = tTrialEnd  - triggerTaskBlockRaw;
        
        displayVidOnset = displayVidOnset - triggerTaskBlockRaw;
        displayVidOffset = displayVidOffset - triggerTaskBlockRaw;
        
        fixationPostVidOnset = fixationPostVidOnset - triggerTaskBlockRaw;
        
        displayAnswerOnset = displayAnswerOnset - triggerTaskBlockRaw;
        timestampAnswer = timestampAnswer  - triggerTaskBlockRaw;
        timestampAnswerWhite = timestampAnswerWhite  - triggerTaskBlockRaw;
        
        fixationPostAnswerOnset = fixationPostAnswerOnset - triggerTaskBlockRaw;
        
        displayCuriosityOnset = displayCuriosityOnset - triggerTaskBlockRaw;
        timestampCuriosity = timestampCuriosity - triggerTaskBlockRaw;
        timestampCuriosityWhite = timestampCuriosityWhite - triggerTaskBlockRaw;
        
        fixationPostCuriosityOnset = fixationPostCuriosityOnset - triggerTaskBlockRaw;
        
        startBlock = triggerTaskBlockRaw - triggerTaskBlockRaw;
        endBlock = endBlock - triggerTaskBlockRaw;
                
        % calculating all durations
        durationTrial = tTrialEnd - tTrialStart;
        
        displayVidDuration = displayVidOffset - displayVidOnset; % timing video presentation
        
        fixationPostVidDuration = displayAnswerOnset - fixationPostVidOnset;
        displayAnswerDuration = fixationPostAnswerOnset - displayAnswerOnset;
        fixationPostAnswerDuration = displayCuriosityOnset - fixationPostAnswerOnset;
        displayCuriosityDuration = fixationPostCuriosityOnset - displayCuriosityOnset;
        fixationPostCuriosityDuration = tTrialEnd - fixationPostCuriosityOnset;
        
        % calculating reaction times
        rtAnswer = timestampAnswer - displayAnswerOnset; % timing answer
        rtCuriosity = timestampCuriosity - displayCuriosityOnset; %timing curiosity
        
        
        % Record the trial data into out data matrix %
        varsOfInterestTask = {subject,fMRI,group,motivation,orderNumber,block,triggerTaskBlockRaw,startBlock,endBlock,...
            stimID,trial,whichVid,tTrialStart,tTrialEnd,durationTrial,fixationInitialDuration,pre_stim_rest,...
            displayVidOnset,displayVidOffset,displayVidDuration,...
            fixationPostVidOnset,fixationPostVidDuration,jitterVideo(trial),...
            displayAnswerOnset,displayAnswerDuration,timeoutAnswer,responseAnswer,timestampAnswer,timestampAnswerWhite,rtAnswer,...
            fixationPostAnswerOnset,fixationPostAnswerDuration,betweenRatingFixation,...
            displayCuriosityOnset,displayCuriosityDuration,timeoutCuriosity,responseCuriosity,timestampCuriosity,timestampCuriosityWhite,rtCuriosity,startValueCuriosity,clicksCuriosity,...
            fixationPostCuriosityOnset,fixationPostCuriosityDuration,jitterRating(trial)};
        
        marker =  combinedInfoForThisTrickOrdered(3,:); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NOTE: THIS NEEDS TO BE REPLACED AFTER PILOT %%%%%%%%%%%%%%%%%
%         marker =  combinedInfoForThisTrickReordered(3,:);
        
        varsOfInterestAll = [varsOfInterestTask, marker];
        
        respMatTask(totalTrials,:) = varsOfInterestAll;

        initialTiming = ceil(GetSecs);
        
        % save respMat to .mat file %
        cd(SAVE_DIR)
        filename = sprintf('%s_task_run%s.mat',fMRI, num2str(block));
        save(filename, 'respMatTask');
        
        cd(EXP_DIR)
    end
    
    if eyetracking
        if ~dummymode
            Eyelink('StopRecording');
        end
    end
    
    if block == totalBlocks
        
        if postLearningRest
            % ---------------  post learning rest instructions   --------------- %
            for instr = 1:length(instrListPost)
                Screen('TextSize', window, fontSizeBig);
                DrawFormattedText(window, instrListPost{instr}    ,...
                    'center', 'center', white);
                
                Screen('TextSize', window, fontSizeSmall);
                DrawFormattedText(window, keyPress,...
                    'center', screenYpixels*0.9, white);
                Screen('Flip', window);
                
                KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
                
                MAGMOT_waitForAnyKeyPress
                
            end
            
            
            % ---------------  post learning resting state   --------------- %
            MAGMOT_restingstate
            
        end
        
    end
    
    % % % % % % % % % % % % % % % % % % % % % % %
    % % % %  END OF TASK - SAVE RESPMAT   % % % %
    % % % % % % % % % % % % % % % % % % % % % % %
    
    cd(SAVE_DIR)
    
    datetimestamp = datestr(now, 'dd-mm-yyyy_HH:MM');
    
    filename = sprintf('%s_workspace_run%s_%s.mat',fMRI, num2str(block), datetimestamp);
    save(fullfile(SAVE_DIR, filename));
    
    cd(EXP_DIR)
    
%     % ------------------- experimenter screen --------------------%
%     MAGMOT_experimenterScreen
    
end


%----------------------------------------------------------------------
%                       save data from task and resting state blocks
%----------------------------------------------------------------------

SAVE_DIR_eye = fullfile(EXP_DIR, 'eyetracking_data');

cd(SAVE_DIR_eye)
% save eye tracking data
if eyetracking
    if ~dummymode
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.5);
        Eyelink('CloseFile');
        % download data file
        try
            fprintf('Receiving data file ''%s''\n', edfFile );
            status=Eyelink('ReceiveFile');
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            if 2==exist(edfFile, 'file') % comment out if necessary
                fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
            end
        catch
            fprintf('Problem receiving data file ''%s''\n', edfFile );
        end
        % close the eye tracker and window
        Eyelink('ShutDown');
    end
end

% save data as .txt file 
Task = cell2table(respMatTask,'VariableNames',varsOfInterestAllName);

FileName=[fMRI '_task_' datestr(now, 'dd-mm-yyyy_HH:MM') '.txt'];
writetable(Task, fullfile(SAVE_DIR,FileName), 'Delimiter', 'tab');

FileName=[fMRI '_task_' datestr(now, 'dd-mm-yyyy_HH:MM') '.csv'];
writetable(Task, fullfile(SAVE_DIR,FileName), 'Delimiter', ',');


%----------------------------------------------------------------------
%                       questionnaire and MPRAGE
%----------------------------------------------------------------------
if postDoPostQuestionnaire
    cd(EXP_DIR);
    
    % ---------------  instructions t1 and questionnaire  --------------- %
    for instr = 1:length(instrListQuest)
        Screen('TextSize', window, fontSizeBig);
        DrawFormattedText(window, instrListQuest{instr}    ,...
            'center', 'center', white);
        
        Screen('TextSize', window, fontSizeSmall);
        DrawFormattedText(window, keyPress,...
            'center', screenYpixels*0.9, white);
        Screen('Flip', window);
        
        KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
        
        MAGMOT_waitForAnyKeyPress
        
    end
    
    
    % ---------------  questionnaire  --------------- %
    MAGMOT_postQuestionnaire
    
    %----------------------------------------------------------------------
    %                       save workspace and end experiment
    %----------------------------------------------------------------------
    
    datetimestamp = datestr(now, 'dd-mm-yyyy_HH:MM');
    
    filename = sprintf('%s_workspace_%s.mat',fMRI, datetimestamp);
    save(fullfile(SAVE_DIR,filename));
    
    
    % End of experiment screen. We clear the screen once they have made their
    % response
    Screen('TextSize', window, fontSizeBig);
    DrawFormattedText(window, endOfExperiment,...
        'center', 'center', white);
    Screen('TextSize', window, fontSizeSmall);
    DrawFormattedText(window, keyExit,...
        'center', screenYpixels*0.9, white);
    Screen('Flip', window);
    
    KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
    KbQueueStart(pptResponseDevice);
    KbQueueWait(pptResponseDevice); % Wait until the 't' key signal is sent
    KbQueueRelease(pptResponseDevice);
    sca;
    
else
    sca;
end


