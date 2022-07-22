% KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);        
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
        keyIsDown = 1;   % if any press is recorded, move on to next screen
    end
end

KbQueueRelease(pptResponseDevice); %ADDED!