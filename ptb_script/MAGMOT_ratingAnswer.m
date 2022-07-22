% displayAnswerOnset = GetSecs;
% if eyetracking
%     Eyelink('Message', 'displayAnswerOnset');
% end
% displayAnswerOnset = displayAnswerOnset - triggerTaskBlock;

abzisse = -0.04;

DrawFormattedText(window, answerRating, ...
    'center', screenYpixels * 0.25, white); % display question and answer options colour coded
DrawFormattedText(window, '0 to 10',    screenXpixels*(abzisse + 0.20), screenYpixels * 0.6, [0 0 1]); % blue
DrawFormattedText(window, '11 to 20',   screenXpixels*(abzisse + 0.40), screenYpixels * 0.6, [1 1 0]); % yellow
DrawFormattedText(window, '21 to 30',   screenXpixels*(abzisse + 0.60), screenYpixels * 0.6, [0 1 0]); % green
DrawFormattedText(window, '31 or more', screenXpixels*(abzisse + 0.80), screenYpixels * 0.6, [1 0 0]); %red

displayAnswerOnset = Screen('Flip', window, fixationPostVidOnset + jitterVideo(trial) - timingCorrection);
if eyetracking
    Eyelink('Message', 'displayAnswerOnset');
end

KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);

keyIsDown = 0;
while ~keyIsDown %wating for any key press
    KbQueueStart(pptResponseDevice); % Perform some other tasks while key events are being recorded
    
    [keyIsDown,secs, keyCode] = KbCheck(experimenterKeyboard); %checking computer keyboard
    if keyCode(quit) == 1 % if q is pressed, experiment aborts
        Screen('Flip', window);
        Priority(0);
        KbStrokeWait;
        sca;
    else
        keyIsDown = 0;
    end
    
    [pressed, firstPress]=KbQueueCheck(pptResponseDevice); % Collect keyboard events since KbQueueStart was invoked
    if pressed
        timestampAnswer = GetSecs;
        if eyetracking
            Eyelink('Message', 'timestampAnswer');
        end

        if firstPress(KbName('b')) || firstPress(KbName('h'))
            responseAnswer = '0 to 10'; % Handle press of button 1
            keyIsDown = 1;
        elseif firstPress(KbName('y')) || firstPress(KbName('j'))
            responseAnswer = '11 to 20'; % Handle press of button 2
            keyIsDown = 1;
        elseif firstPress(KbName('g')) || firstPress(KbName('k'))
            responseAnswer = '21 to 30'; % Handle press of button 3
            keyIsDown = 1;
        elseif firstPress(KbName('r')) || firstPress(KbName('l'))
            responseAnswer = '31 or more'; % Handle press of button 4
            keyIsDown = 1;
        end
    end
    
    % this limits the maximum response window to the pre defined time out and progresses even if no answer has been given
    if GetSecs > displayAnswerOnset + timeoutAnswer - 3*timingCorrection
        timestampAnswer = GetSecs;
        keyIsDown = 1;
        responseAnswer = NaN;
    end
end

DrawFormattedText(window, answerRating, ...
    'center', screenYpixels * 0.25, white); % display question and answer options all in white until 6 seconds have passed
DrawFormattedText(window, '0 to 10',    screenXpixels*(abzisse + 0.2), screenYpixels * 0.6, [1 1 1]); 
DrawFormattedText(window, '11 to 20',   screenXpixels*(abzisse + 0.4), screenYpixels * 0.6, [1 1 1]); 
DrawFormattedText(window, '21 to 30',   screenXpixels*(abzisse + 0.6), screenYpixels * 0.6, [1 1 1]); 
DrawFormattedText(window, '31 or more', screenXpixels*(abzisse + 0.8), screenYpixels * 0.6, [1 1 1]); 

timestampAnswerWhite = Screen('Flip', window);

if eyetracking
    Eyelink('Message', 'timestampAnswerWhite');
end


KbQueueRelease(pptResponseDevice);

