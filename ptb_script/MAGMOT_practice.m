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

% get parameter input (optional)
prompt = {'subject ID (two digits)', 'fMRI ID', 'group (int, ext)'};
defaults = {'', 'MAGMOT_',  ''};
answer = inputdlg(prompt, 'Experimental Setup Information', 1, defaults);
% now decode answer
[subject, fMRI, group] = deal(answer{:});
start = 1; % block to start with
totalBlocks = 1; % number of blocks in total
startTrial = 1; % which trial to start with - in case MATLAB breaks at a certain number
motivation = group;
if strcmp(group, 'int')
    motivation = -1;
elseif strcmp(group, 'ext')
    motivation = 1;
else sca;
    disp('*** wrong input of group, start again ***');
    return
end

% % get parameter input (optional)
% prompt = {'subject ID (two digits)', 'fMRI ID', 'group (int, ext)', 'order number (1-25)', 'start (set 2 or 3 if necessary)', 'number of blocks', 'start trial (1-12; adjust if necessary)'};
% defaults = {'pilot7', 'MAGMOT_pilot7',  'int', '1', '1', '3', '1'};
% answer = inputdlg(prompt, 'Experimental Setup Information', 1, defaults);
% % now decode answer
% [subject, fMRI, group, orderNumber, startBlock, totalBlocks, startTrial] = deal(answer{:});
% orderNumber = str2num(orderNumber);
% startBlock = str2num(startBlock); % block to start with
% totalBlocks = str2num(totalBlocks); % number of blocks in total
% startTrial = str2num(startTrial); % which trial to start with - in case MATLAB breaks at a certain number
% motivation = group;
% if strcmp(group, 'int')
%     motivation = -1;
% elseif strcmp(group, 'ext')
%     motivation = 1;
% else sca;
%     disp('*** wrong input of group, start again ***');
%     return
% end

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
            def     = {'MAGMOTp7'};
            answer  = inputdlg(prompt,dlg_title,num_lines,def);
            %edfFile= 'DEMO.EDF'
            edfFile = answer{1};
            fprintf('EDFFile: %s\n', edfFile );
        end
%     end 
end

% % read in trial order file and select the one corresponding to orderNumer
% allTrialOrders = csvread('TrialOrders_best_maxRep-4.csv', 1, 0); % this creates an array with each trialOrder as a column
% currentTrialOrder = allTrialOrders(:,orderNumber); % selects the column of allTrialOrders corresponding to orderNumber
% 
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
    timeoutCuriosity = 3;
    timeoutAnswer = 3;
end

triggerDevice = -1;
pptResponseDevice = -1;

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

% read in trial order file and select the one corresponding to orderNumer
orderNumber = 1;
% allTrialOrders = csvread('TrialOrders_best_maxRep-4.csv', 1, 0); % this creates an array with each trialOrder as a column
% currentTrialOrder = allTrialOrders(:,orderNumber); % selects the column of allTrialOrders corresponding to orderNumber


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
deviceString='932'; %scanner device: both button box and trigger; old button box: deviceString='fORP Interface';
% deviceString='Magic Keyboard'; %scanner device: both button box and trigger; old button box: deviceString='fORP Interface';
computerString='Apple Internal Keyboard / Trackpad'; %scanner device: both button box and trigger; old button box: deviceString='fORP Interface';
[id,name] = GetKeyboardIndices;% get a list of all devices connected

triggerDevice=0;
for i=1:length(name)%for each possible device
    if strcmp(name{i},computerString)%compare the name to the name you want
        experimenterKeyboard=id(i);%grab the correct id, and exit loop
    end
    if scanner
        if strcmp(name{i},deviceString)%compare the name to the name you want
            triggerDevice=id(i);%grab the correct id, and exit loop
            break;
        end
    elseif dryrunscanner
        if strcmp(name{i},deviceString)%compare the name to the name you want
            triggerDevice=id(i);%grab the correct id, and exit loop
            break;
        end
    else
        triggerDevice = -1;
        break
    end
end


% if taking responses from the button box then participantResponses should be scanner device (same as triggerDevice),
% otherwise can be -1 to take responses from keyboard devices
if phantom
    pptResponseDevice = -1;
else
    pptResponseDevice = triggerDevice;
end

% define keyboard names
escape = KbName('ESCAPE'); % used during video presentation
quit = KbName('q'); % used during instructions
experimenterKey = KbName('s');
repeat = KbName('w'); 

keysOfInterestButtonbox=zeros(1,256);
if dryrunscanner
    keysOfInterestButtonbox(KbName({'r', 'g', 'b', 'y'}))=1;
elseif ~scanner
    keysOfInterestButtonbox(KbName({'h', 'j', 'k', 'l'}))=1; % I might have to change the response ratings accoringly!
else
    keysOfInterestButtonbox(KbName({'r', 'g', 'b', 'y'}))=1;
end

keysOfInterestTrigger=zeros(1,256);
keysOfInterestTrigger(KbName({'t'}))=1;

keysOfInterestEyeTracking=zeros(1,256);
keysOfInterestEyeTracking(KbName({'Return', 'ESCAPE', 'c', 'd', 'v'}))=1;

% button1 = KbName('h'); %blue
% button2 = KbName('j'); %yellow
% button3 = KbName('k'); %green
% button4 = KbName('l'); %red

%----------------------------------------------------------------------
%                       Define instructions
%----------------------------------------------------------------------

greeting = 'Hello and welcome!\n\nThank you very much\nfor participating in the experiment.';
question = 'Do you have any questions?\n\nPlease just ask.';
trigger = 'scanning is starting, waiting for trigger';
keyPress = '(press any key to continue)';
experimenterInput = 'EXPERIMENTER INPUT:\n\ncontinue (s)\nabort (q)\nrepeat (w)';
%-------
answerRating = 'How many people (out of 100)\nare able to correctly figure out the solution?';
curiosityRating = 'Please rate how CURIOUS\nyou were while watching the trick.';
%-------
task1 = 'We are  going to practice\nthe actual task.\n\n Do you feel ready?\n\nWe will show you the instructions.';
task2 = 'In this experiment you will be presented\nwith a series of magic tricks.\nThe videos are without audio.\n\nYour task is to carefully watch the videos\nand try to figure out what has happened.';
task3 = 'Before the start of each magic trick\nyou will see a fixation point.';
task4 = 'Afterwards, you are asked to give\nan estimate of how many people (out of 100)\nare able to correctly\nfigure out the solution to the trick.\n\nPossible answers are the following:\n\n0 - 10 people\n11 - 20 people\n21 - 30 people\n31 or more people';
task5 = 'In addition to that, we would like you\nto rate how curious you were while watching\nthe magic tricks on a scale \n\nfrom 1 (not curious at all) to 7 (very curious)';
% taskExt = 'If you are able to answer the question\n"how many people are able to find\nthe solution?" correctly, you can get\nan additional GBP 1.00 per right answer.';
task6 = 'For each of the answers,\nyou have 6 seconds. ';
task7 = 'To select the estimate you think\nis correct, you have to press\nthe corresponding button on the button box.\n\nYour INDEX finger is lies on the blue button\ncorresponding to the answer "0 to 10 people".\nYour MIDDLE finger is on the yellow button\ncorresponding to "11 to 20 people".\nYour RING finger lies on the green button\ncorresponding to "21 to 30 people"\nand your PINKIE lies on the red button\ncorresponding to "31 and more people".';
task8 = 'For the curiosity rating, you have\nto move the red number \nto the number representing your curiosity.\n\nTo move it to the left,\nplease use your index finger (blue button).\n\nTo move it to the right,\nplease use your middle finger (yellow button).\n\nTo confirm your selection,\nplease use your pinkie (red button).';
task9 = 'You will see both the answer and\nthe rating screen to remind you\nhow it looks like.\n\nAfter you have indicated your answer and\nyour rating, the coloured ink will turn white\nand you simply wait for the task to continue.';
block1 = 'You will see two magictricks\nduring the practice.\n\nIn the actual experiment,\nthere will be 36 magic tricks.';
block2 = 'The practice starts NOW.\n\nYou are asked to estimate\nhow many people are able to correctly find\nthe solution to the magic trick.';
taskStart = 'The fixation point will show up shortly.';
%-------
endOfExperiment = 'The practice is over now.\n\nDo you have any questions?';
keyExit = '(press any key to EXIT)';
%-------
instrListTask = {greeting, task1, task2, task3, task4, task5, task6, task7, task8, task9};

% % show the instructions screens for the respective group %
% if strcmp(group, 'int') % intrinsic
%     instrListTask = {greeting, task1, task2, task3, task4, task5, task6, task7, task8};
% elseif strcmp(group, 'ext') % extrinsic
%     instrListTask = {greeting, task1, task2, task3, task4, task5, taskExt, task6, task7, task8};
% else
%     sca;
%     disp('*** wrong input of group, start again ***');
%     return
% end

instrListBlock1 = {question, block1, block2};

%----------------------------------------------------------------------
%                     Conditions and trials
%----------------------------------------------------------------------

% setting up a folder for each participant
SAVE_DIR = fullfile(pwd, 'behavioural_data', subject);
mkdir(SAVE_DIR);

% clear stimuli folder of potential hidden files
vidLoc= fullfile(EXP_DIR,'magic tricks', 'practice');
cd(vidLoc);
delete ._*

cd(EXP_DIR);
vidList = dir(fullfile(vidLoc, '*.mp4')); % find .mp4 files in the 'vid' directory
vidList = {vidList.name}; % we just need the filenames, this is our trial list

numTrials = length(vidList);

trialList = numTrials/totalBlocks; % n in block
trialListBlock = trialList;

% jittering
jitterVideo = [4 8];
jitterRating = [6 4];

% trial order
currentTrialOrder = [1 2];


%----------------------------------------------------------------------
%                     Make response matrixes
%----------------------------------------------------------------------

%----------------------------------------------------------------------
%                     Make response matrixes
%----------------------------------------------------------------------

varsOfInterestAllName = {'subject' 'fMRI' 'group' 'motivation' 'orderNumber' 'block' 'triggerTaskBlockRaw' 'startBlock' 'endBlock' 'stimID' ...
    'trial' 'whichVid' 'tTrialStart' 'tTrialEnd' 'durationTrial' 'fixationInitialDuration' 'pre_stim_rest'... 
    'displayVidOnset' 'displayVidOffset' 'displayVidDuration'... 
    'fixationPostVidOnset' 'fixationPostVidDuration' 'jitterVideo_trial' 'displayAnswerOnset' 'displayAnswerDuration' 'timeoutAnswer' 'responseAnswer' 'timestampAnswer' 'timestampAnswerWhite' 'rtAnswer' ...
    'fixationPostAnswerOnset' 'fixationPostAnswerDuration' 'betweenRatingFixation' 'displayCuriosityOnset' 'displayCuriosityDuration' 'timeoutCuriosity' 'responseCuriosity' 'timestampCuriosity' 'timestampCuriosityWhite' 'rtCuriosity'... 
    'startValueCuriosity' 'clicksCuriosity' 'fixationPostCuriosityOnset' 'fixationPostCuriosityDuration' 'jitterRating_trial' };

% use this information to create 
respMatTask = cell(numTrials, size(varsOfInterestAllName,2));

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

totalTrials = startTrial - 1;


% % % start of the loop for each block % % %

for block = start:totalBlocks
    
    startTrialBlock = startTrial + (block-1)*trialList;
    trialListBlock = startTrialBlock + trialList - 1;
    
    % --------------- display instructions   --------------- %
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
    
    % ---------------  example ratings   --------------- %
    MAGMOT_exampleRatingAnswer
    
    KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
    
    MAGMOT_waitForAnyKeyPress
    
    KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
    
    MAGMOT_exampleRatingCuriosity
    
    KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
    
    MAGMOT_waitForAnyKeyPress
    
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
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    % % %  magic trick presentation + task + curiosity rating   % % %
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    
    % show waiting for scanner text
    Screen('TextSize', window, fontSizeBig);
    DrawFormattedText(window, taskStart ,...
        'center', 'center', white);
    Screen('TextSize', window, fontSizeSmall);
    DrawFormattedText(window, trigger, 'center', screenYpixels*0.9, white);
    Screen('Flip', window);
        
    WaitSecs(2);
    triggerTaskBlockRaw = GetSecs;
    
    % display fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
    vbl = Screen('Flip', window);
    for frame = 1:(pre_stim_rest*isiTimeFrames) - 1 % pre_stim_rest = 2 seconds, time to wait before the first magic trick of the block is displayed
        Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
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
        
%         % create an object containing the marker information for each magic trick
%         for j = 1:numTricks
%             if strcmp(string(timingListAllNamed{j,nameTricksColumn}), string(stimID)) == true % find the correct row
%                 rowWithDataforThisTrick = j;
%                 timingsForThisTrick = timingListAllNamed(rowWithDataforThisTrick,1:numEvents); % get the timings associated with the current trick
%                 [ranks_ordered, idx] = sort(cell2mat(timingsForThisTrick), 'ascend'); % get index for timings in ascending order
%                 timingsForThisTrickOrdered = timingsForThisTrick(idx); % order the timings in ascending order
%                 eventsOrdered = events(idx); % order events in ascending order
%                 combinedInfoForThisTrickOrdered = [eventsOrdered; timingsForThisTrickOrdered]; % combine both in one object
%                 combinedInfoForThisTrickOrdered{3,numEvents} = []; % create a third row for this object to add actual display timings in there later
%             end
%         end
        
        
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
                Eyelink('Command', 'clear_screen 0')
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
        varsOfInterestAll = {subject,fMRI,group,motivation,orderNumber,block,triggerTaskBlockRaw,startBlock,endBlock,...
            stimID,trial,whichVid,tTrialStart,tTrialEnd,durationTrial,fixationInitialDuration,pre_stim_rest,...
            displayVidOnset,displayVidOffset,displayVidDuration,...
            fixationPostVidOnset,fixationPostVidDuration,jitterVideo(trial),...
            displayAnswerOnset,displayAnswerDuration,timeoutAnswer,responseAnswer,timestampAnswer,timestampAnswerWhite,rtAnswer,...
            fixationPostAnswerOnset,fixationPostAnswerDuration,betweenRatingFixation,...
            displayCuriosityOnset,displayCuriosityDuration,timeoutCuriosity,responseCuriosity,timestampCuriosity,timestampCuriosityWhite,rtCuriosity,startValueCuriosity,clicksCuriosity,...
            fixationPostCuriosityOnset,fixationPostCuriosityDuration,jitterRating(trial)};
        
%         marker =  combinedInfoForThisTrickOrdered(3,:);
%         
%         varsOfInterestAll = [varsOfInterestTask, marker];
        
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
    

    
end

%----------------------------------------------------------------------
%                       save data from workspace
%----------------------------------------------------------------------

datetimestamp = datestr(now, 'dd-mm-yyyy_HH:MM');

filename = sprintf('practice_%s_workspace_%s.mat',fMRI, datetimestamp);
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
KbQueueStart;
KbQueueWait; % Wait until the 't' key signal is sent
sca;



