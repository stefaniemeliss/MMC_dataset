% STEP 3
% Provide Eyelink with details about the graphics environment
% and perform some initializations. The information is returned
% in a structure that also contains useful defaults
% and control codes (e.g. tracker state bit and Eyelink key values).
el=EyelinkInitDefaults(window);
% fprintf('DEBUG: ran line el=EyelinkInitDefaults(window);\n');

% STEP 4
% Initialization of the connection with the Eyelink Gazetracker.
% exit program if this fails.
if ~EyelinkInit(dummymode)
    fprintf('Eyelink Init aborted.\n');
    cleanup;  % cleanup function
    return;
end

% the following code is used to check the version of the eye tracker
% and version of the host software
sw_version = 0;

[v vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

% open file to record data to
i = Eyelink('Openfile', edfFile);
if i~=0
    fprintf('Cannot create EDF file ''%s'' ', edffilename);
    Eyelink( 'Shutdown');
    Screen('CloseAll');
    return;
end

Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox MAGMOT''');

% STEP 5
% SET UP TRACKER CONFIGURATION
% Setting the proper recording resolution, proper calibration type,
% as well as the data file content;
Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, screenXpixels-1, screenYpixels-1);
Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, screenXpixels-1, screenYpixels-1);
% set calibration type.
Eyelink('command', 'calibration_type = HV9');
Eyelink('command', 'generate_default_targets = YES'); % added after unsuccuessful tracking

% fprintf('DEBUG: ran line Eyelink(command, calibration_type = HV9);;\n');

% set parser (conservative saccade thresholds)

% set EDF file contents using the file_sample_data and
% file-event_filter commands
% set link data thtough link_sample_data and link_event_filter
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');

% check the software version
% add "HTARGET" to record possible target data for EyeLink Remote
if sw_version >=4
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
else
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
end

% allow to use the big button on the eyelink gamepad to accept the
% calibration/drift correction target
% Eyelink('command', 'button_function 5 "accept_target_fixation"');


% make sure we're still connected.
if Eyelink('IsConnected')~=1 && dummymode == 0
    fprintf('not connected, clean up\n');
    Eyelink( 'Shutdown');
    Screen('CloseAll');
    return;
end

% STEP 6
% Calibrate the eye tracker
% setup the proper calibration foreground and background colors
el.backgroundcolour = [0 0 0]; % black
el.calibrationtargetcolour = [1 1 1]; % white
% fprintf('DEBUG: ran lines to change target colour and background\n');


% parameters are in frequency, volume, and duration
% set the second value in each line to 0 to turn off the sound
el.cal_target_beep=[600 0.5 0.05];
el.drift_correction_target_beep=[600 0.5 0.05];
el.calibration_failed_beep=[400 0.5 0.25];
el.calibration_success_beep=[800 0.5 0.25];
el.drift_correction_failed_beep=[400 0.5 0.25];
el.drift_correction_success_beep=[800 0.5 0.25];
% you must call this function to apply the changes from above
EyelinkUpdateDefaults(el);
% fprintf('DEBUG: ran line EyelinkUpdateDefaults(el);\n');


% show participant instructions for eye tracker calibration
Screen('TextSize', window, fontSizeBig);
DrawFormattedText(window,calibrationInstruction,...
    'center', 'center', white);

Screen('TextSize', window, fontSizeSmall);
DrawFormattedText(window, keyPress,... %press anx key to continue
    'center', screenYpixels*0.9, white);
Screen('Flip', window);

KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);

MAGMOT_waitForAnyKeyPress;

% show experimenter instructions for eye tracker calibration
Screen('TextSize', window, fontSizeSmall);
DrawFormattedText(window,calibrationScreen,...
    screenXpixels*0.1, 'center', white);
Screen('Flip', window);

% fprintf('DEBUG: before KbQueue\n');

KbQueueCreate(experimenterKeyboard, keysOfInterestEyeTracking);

% fprintf('DEBUG: after KbQueue\n');

keyIsDown = 0;


while ~keyIsDown %wating for any key press
    KbQueueStart(experimenterKeyboard); % Perform some other tasks while key events are being recorded
    
    [keyIsDown,secs, keyCode] = KbCheck(experimenterKeyboard); %checking computer keyboard
    if keyCode(quit) == 1 % if q is pressed, experiment aborts
        Screen('Flip', window);
        Priority(0);
        KbStrokeWait;
        sca;
    else
        keyIsDown = 0;
    end
    
    [pressed, firstPress]=KbQueueCheck(experimenterKeyboard); % Collect keyboard events since KbQueueStart was invoked
    if pressed
        keyIsDown = 1;   % if any press is recorded, move on to next screen
    end
end

KbQueueRelease(experimenterKeyboard); %ADDED!

% fprintf('DEBUG: after MAGMOT_waitForAnyKeyPress\n');



 % I think this is where the calibration appears
EyelinkDoTrackerSetup(el);
fprintf('ran line EyelinkDoTrackerSetup(el);\n');

