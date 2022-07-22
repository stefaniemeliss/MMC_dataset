Screen('TextSize', window, fontSizeBig);
DrawFormattedText(window, experimenterInput,...
    'center', 'center', white);
Screen('Flip', window);

keyIsDown = 0;
while ~keyIsDown
    
    [keyIsDown, secs, keyCode] = KbCheck(experimenterKeyboard); %all devices
    
    if keyCode(experimenterKey) == 1 % when pressed, continue with instructions
        Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
        vbl = Screen('Flip', window);
        for frame = 1:isiTimeFrames - 1
            Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        end
        keyIsDown=1;
    elseif keyCode(quit) == 1 % when quit pressed, abort mission
        Screen('Flip', window);
        Priority(0)
        KbStrokeWait;
        sca;
        fprintf('REMEBER TO SAVE ALL DATA INCLUDING EYE TRACKING\n');

    else % continue to display experimenter screen
        keyIsDown = 0;
    end
end