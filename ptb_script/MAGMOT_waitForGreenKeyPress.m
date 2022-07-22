% wait for the green key to be pressed and only continue if green has been pressed
keyIsDown = 0;
while ~keyIsDown
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
        if firstPress(KbName('g')) || firstPress(KbName('k'))
            responseAnswer = '21 to 30'; % Handle press of button 3
            keyIsDown = 1;
        else
            keyIsDown = 0;
        end
    end
end

KbQueueRelease(pptResponseDevice);
