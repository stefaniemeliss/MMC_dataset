Screen('TextSize', window, fontSizeBig);
DrawFormattedText(window, restingStart ,...
    'center', 'center', white);
Screen('TextSize', window, fontSizeSmall);
DrawFormattedText(window, trigger, 'center', screenYpixels*0.9, white);

Screen('Flip', window);

% waiting for scanner signal to start resting state fmri
if scanner
    KbQueueCreate(triggerDevice, keysOfInterestTrigger);	% First queue: scannerSignal
    KbQueueStart(triggerDevice);
    KbQueueWait(triggerDevice); % Wait until the 't' key signal is sent
    KbQueueRelease(triggerDevice);

else
    WaitSecs(2);
end


% then display white rectagle
baseRect = [0 0 screenXpixels*0.9 screenYpixels*0.9];
centeredRect = CenterRectOnPointd(baseRect, xCenter, yCenter);
rectColor = [1 1 1];
Screen('FillRect', window, rectColor, centeredRect);
Screen('Flip', window);
KbReleaseWait;

% present white screen until experimenter pushes button
keyIsDown = 0;
while ~keyIsDown %waiting for experimenterKey or quit to be pressed
    Screen('FillRect', window, rectColor, centeredRect);
    Screen('Flip', window);
    [keyIsDown, secs, keyCode] = KbCheck(experimenterKeyboard); % checking computer keyboard
    
    if keyCode(experimenterKey) == 1 % when triggered, show black screen
        %             if find(keyCode) == KbName(experimenterKey) % when triggered, show blank screen
        
        keyIsDown=1;
        
        KbReleaseWait;
        
        % ------------------- experimenter screen --------------------%
        MAGMOT_experimenterScreen
        
%         % Display text: please wait, someone will talk to you
%         Screen('TextSize', window, fontSizeBig);
%         DrawFormattedText(window, wait,...
%             'center', 'center', white);
%         
%         Screen('TextSize', window, fontSizeSmall); %press anx key to continue
%         DrawFormattedText(window, keyPress,...
%             'center', screenYpixels*0.9, white);
%         Screen('Flip', window);
%         
%         KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
%         
%         MAGMOT_waitForAnyKeyPress

        
    elseif keyCode(quit) == 1 % when quit pressed, abort mission
        Screen('Flip', window);
        Priority(0)
        KbStrokeWait;
        sca;
        keyIsDown = 0;
    else
        keyIsDown = 0;
    end
end