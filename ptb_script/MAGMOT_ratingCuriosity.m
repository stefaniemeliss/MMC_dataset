% displayCuriosityOnset = GetSecs;
% if eyetracking
%     Eyelink('Message', 'displayCuriosityOnset');
% end
theValue = randi(7); %set value to random number between 1 and 7 --> starting point for our rating (highlighted)
startValueCuriosity = theValue;

DrawFormattedText(window, curiosityRating, ... % display rating scale
    'center', screenYpixels * 0.4, white);

cols = [1,1,1,1,1,1,1];  % colour vector: when 1, numbers displayed in white
cols(theValue) = 0;  % changes colour vector so that it puts a 0 at the index of theValue

DrawFormattedText(window, '1', screenXpixels*0.125, screenYpixels * 0.6, [1, cols(1), cols(1)]); % index of theValue will have [1, 0, 0] as colour index
DrawFormattedText(window, '2', screenXpixels*0.25, screenYpixels * 0.6, [1, cols(2), cols(2)]); % that prints the number in red rather than white
DrawFormattedText(window, '3', screenXpixels*0.375, screenYpixels * 0.6, [1, cols(3), cols(3)]);
DrawFormattedText(window, '4', screenXpixels*0.5, screenYpixels * 0.6, [1, cols(4), cols(4)]);
DrawFormattedText(window, '5', screenXpixels*0.625, screenYpixels * 0.6, [1, cols(5), cols(5)]);
DrawFormattedText(window, '6', screenXpixels*0.75, screenYpixels * 0.6, [1, cols(6), cols(6)]);
DrawFormattedText(window, '7', screenXpixels*0.875, screenYpixels * 0.6, [1, cols(7), cols(7)]);

DrawFormattedText(window, 'not at all', screenXpixels*(-0.04+0.125), screenYpixels * 0.8, white);
DrawFormattedText(window, 'very',       screenXpixels*(-0.04+0.875), screenYpixels * 0.8, white);

displayCuriosityOnset = Screen('Flip', window, fixationPostAnswerOnset + betweenRatingFixation - timingCorrection);
if eyetracking
    Eyelink('Message', 'displayCuriosityOnset');
end

KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);

keyIsDown = 0; % user interaction with rating scale
clicksCuriosity = 0;
conf = 0;

while ~conf %go through the loop as long as it takes for the confirmation button to be pressed
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
            timestampCuriosity = GetSecs;
            if eyetracking
                Eyelink('Message', 'timestampCuriosity');
            end

            if firstPress(KbName('b')) || firstPress(KbName('h'))
                if theValue ~= 1
                    theValue = theValue - 1;
                    clicksCuriosity = clicksCuriosity + 1;
                end
                keyIsDown = 0;
                KbQueueFlush(pptResponseDevice);
            elseif firstPress(KbName('y')) || firstPress(KbName('j'))
                if theValue ~= 7
                    theValue = theValue + 1;
                    clicksCuriosity = clicksCuriosity + 1;
                end
                keyIsDown = 0;
                KbQueueFlush(pptResponseDevice);
            elseif firstPress(KbName('r')) || firstPress(KbName('l')) %confirmation of response
                keyIsDown = 1;
                conf = 1;
                responseCuriosity = theValue;
                timestampCuriosity = GetSecs;
            else % if any other button is pressed, set keyIsDown to 0 again
                keyIsDown = 0;
            end
            
            DrawFormattedText(window, curiosityRating, ...
                'center', screenYpixels * 0.4, white);
            
            cols = [1,1,1,1,1,1,1];
            cols(theValue) = 0;
            % draw the updated rating highlighting another number
            DrawFormattedText(window, '1', screenXpixels*0.125, screenYpixels * 0.6, [1, cols(1), cols(1)]);
            DrawFormattedText(window, '2', screenXpixels*0.25, screenYpixels * 0.6, [1, cols(2), cols(2)]);
            DrawFormattedText(window, '3', screenXpixels*0.375, screenYpixels * 0.6, [1, cols(3), cols(3)]);
            DrawFormattedText(window, '4', screenXpixels*0.5, screenYpixels * 0.6, [1, cols(4), cols(4)]);
            DrawFormattedText(window, '5', screenXpixels*0.625, screenYpixels * 0.6, [1, cols(5), cols(5)]);
            DrawFormattedText(window, '6', screenXpixels*0.75, screenYpixels * 0.6, [1, cols(6), cols(6)]);
            DrawFormattedText(window, '7', screenXpixels*0.875, screenYpixels * 0.6, [1, cols(7), cols(7)]);
            
            DrawFormattedText(window, 'not at all', screenXpixels*(-0.04+0.125), screenYpixels * 0.8, white);
            DrawFormattedText(window, 'very',       screenXpixels*(-0.04+0.875), screenYpixels * 0.8, white);
            Screen('Flip', window);
            
        end
        
        % this limits the maximum response window to the pre defined time out and progresses even if no answer has been given
        if GetSecs > displayCuriosityOnset + timeoutCuriosity - 3*timingCorrection
            keyIsDown = 1;
            conf = 1;
            responseCuriosity = theValue;
            timestampCuriosity = GetSecs;
        end
    end
    

end

% display numbers in white
DrawFormattedText(window, curiosityRating, ... % display rating scale
    'center', screenYpixels * 0.4, white);
DrawFormattedText(window, '1', screenXpixels*0.125, screenYpixels * 0.6, white);
DrawFormattedText(window, '2', screenXpixels*0.25, screenYpixels * 0.6, white);
DrawFormattedText(window, '3', screenXpixels*0.375, screenYpixels * 0.6, white);
DrawFormattedText(window, '4', screenXpixels*0.5, screenYpixels * 0.6, white);
DrawFormattedText(window, '5', screenXpixels*0.625, screenYpixels * 0.6, white);
DrawFormattedText(window, '6', screenXpixels*0.75, screenYpixels * 0.6, white);
DrawFormattedText(window, '7', screenXpixels*0.875, screenYpixels * 0.6, white);
DrawFormattedText(window, 'not at all', screenXpixels*(-0.04+0.125), screenYpixels * 0.8, white);
DrawFormattedText(window, 'very',       screenXpixels*(-0.04+0.875), screenYpixels * 0.8, white);
timestampCuriosityWhite = Screen('Flip', window);
if eyetracking
    Eyelink('Message', 'timestampCuriosityWhite');
end

KbQueueRelease(pptResponseDevice);

