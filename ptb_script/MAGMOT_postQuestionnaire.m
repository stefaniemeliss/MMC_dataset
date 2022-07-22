totalQuestions = 0;
startQuestionnaire = GetSecs;
for q = 1:length(questionnaire) % loop over all questions in the questionnaire cell
    
    % general set ups %
    n = q;
    totalQuestions = totalQuestions + 1;
    theValue = randi(6);
    startValueQuestion = theValue;
    cols = [1,1,1,1,1,1,1]; % colour vector: when 1, numbers displayed in white
    cols(theValue) = 0;
    
    % display the question %
    Screen('TextSize', window, fontSizeBig);
    DrawFormattedText(window, questionnaire{q},...
        'center', screenYpixels * 0.4, white);
    
    % display answer scale %
    DrawFormattedText(window, '1', screenXpixels*0.125, screenYpixels * 0.6, [1, cols(1), cols(1)]); % index of theValue will have [1, 0, 0] as colour index
    DrawFormattedText(window, '2', screenXpixels*0.250, screenYpixels * 0.6, [1, cols(2), cols(2)]); % that prints the number in red rather than white
    DrawFormattedText(window, '3', screenXpixels*0.375, screenYpixels * 0.6, [1, cols(3), cols(3)]);
    DrawFormattedText(window, '4', screenXpixels*0.500, screenYpixels * 0.6, [1, cols(4), cols(4)]);
    DrawFormattedText(window, '5', screenXpixels*0.625, screenYpixels * 0.6, [1, cols(5), cols(5)]);
    DrawFormattedText(window, '6', screenXpixels*0.750, screenYpixels * 0.6, [1, cols(6), cols(6)]);
    DrawFormattedText(window, '7', screenXpixels*0.875, screenYpixels * 0.6, [1, cols(7), cols(7)]);
    
    abzisse = -0.04;
    
    Screen('TextSize', window, fontSizeSmall);
    DrawFormattedText(window, 'definitely\ndisagree',           screenXpixels*(abzisse + 0.125), screenYpixels * 0.8, white); % index of theValue will have [1, 0, 0] as colour index
    DrawFormattedText(window, ' somehow\ndisagree',             screenXpixels*(abzisse + 0.250), screenYpixels * 0.8, white); % that prints the number in red rather than white
    DrawFormattedText(window, 'slightly\ndisagree',             screenXpixels*(abzisse + 0.375), screenYpixels * 0.8, white);
    DrawFormattedText(window, 'neither\ndisagree\nnor agree',   screenXpixels*(abzisse + 0.500), screenYpixels * 0.8, white);
    DrawFormattedText(window, 'slightly\nagree',                screenXpixels*(abzisse + 0.625), screenYpixels * 0.8, white);
    DrawFormattedText(window, 'somehow\nagree',                 screenXpixels*(abzisse + 0.750), screenYpixels * 0.8, white);
    DrawFormattedText(window, 'definitely\nagree',              screenXpixels*(abzisse + 0.875), screenYpixels * 0.8, white);
    displayQuestionOnset = Screen('Flip', window);
    displayQuestionOnset = displayQuestionOnset -startQuestionnaire;
    
    % user interaction with answer scale %
    keyIsDown = 0;
    clicksQuestion = 0;
    conf = 0;
    KbQueueCreate(pptResponseDevice, keysOfInterestButtonbox);
    
    while ~conf %go through the loop as long as it takes for the confirmation button to be pressed
        while ~keyIsDown %wating for any key press
            KbQueueStart(pptResponseDevice); % Perform some other tasks while key events are being recorded
            [keyIsDown,secs, keyCode] = KbCheck(experimenterKeyboard); %checking computer keyboard
            if keyCode(quit) == 1 % if q is pressed, experiment aborts
                Screen('Flip', window);
                Priority(0);
                KbStrokeWait;
                sca;
                keyIsDown = 1;
            else
                keyIsDown = 0;
            end
            
            [pressed, firstPress]=KbQueueCheck(pptResponseDevice); % Collect keyboard events since KbQueueStart was invoked
            if pressed
                timestampQuestionnaireAnswer = GetSecs;
                if firstPress(KbName('b')) || firstPress(KbName('h'))
                    if theValue ~= 1
                        theValue = theValue - 1;
                        clicksQuestion = clicksQuestion + 1;
                    end
                    keyIsDown = 0;
                    KbQueueFlush(pptResponseDevice);
                elseif firstPress(KbName('y')) || firstPress(KbName('j'))
                    if theValue ~= 7
                        theValue = theValue + 1;
                        clicksQuestion = clicksQuestion + 1;
                    end
                    keyIsDown = 0;
                    KbQueueFlush(pptResponseDevice);
                elseif firstPress(KbName('r')) || firstPress(KbName('l')) %confirmation of response
                    keyIsDown = 1;
                    conf = 1;
                    responseQuestion = theValue;
                    timestampQuestionnaireAnswer = GetSecs;
                else % if any other button is pressed, set keyIsDown to 0 again
                    keyIsDown = 0;
                end
                
                Screen('TextSize', window, fontSizeBig);
                DrawFormattedText(window, questionnaire{n} ,...
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
                
                
                Screen('TextSize', window, fontSizeSmall);
                DrawFormattedText(window, 'definitely\ndisagree',           screenXpixels*(abzisse + 0.125), screenYpixels * 0.8, white); % index of theValue will have [1, 0, 0] as colour index
                DrawFormattedText(window, ' somehow\ndisagree',             screenXpixels*(abzisse + 0.250), screenYpixels * 0.8, white); % that prints the number in red rather than white
                DrawFormattedText(window, 'slightly\ndisagree',             screenXpixels*(abzisse + 0.375), screenYpixels * 0.8, white);
                DrawFormattedText(window, 'neither\ndisagree\nnor agree',   screenXpixels*(abzisse + 0.500), screenYpixels * 0.8, white);
                DrawFormattedText(window, 'slightly\nagree',                screenXpixels*(abzisse + 0.625), screenYpixels * 0.8, white);
                DrawFormattedText(window, 'somehow\nagree',                 screenXpixels*(abzisse + 0.750), screenYpixels * 0.8, white);
                DrawFormattedText(window, 'definitely\nagree',              screenXpixels*(abzisse + 0.875), screenYpixels * 0.8, white);
                Screen('Flip', window);
                %                 KbReleaseWait;
                
            end
        end
        
        keyIsDown = 0;
        
    KbQueueRelease(pptResponseDevice);
    
    timestampQuestion = GetSecs;
    timestampQuestion = timestampQuestion -startQuestionnaire;
    
    rtQuestion = timestampQuestion - displayQuestionOnset; %timing curiosity
    
end
    
    % Record the trial data into out data matrix %
    varsOfInterestTask = {subject,fMRI,group,motivation,orderNumber,block,triggerTaskBlockRaw,startBlock,endBlock,...
        stimID,trial,whichVid,tTrialStart,tTrialEnd,durationTrial,fixationInitialDuration,pre_stim_rest,...
        displayVidOnset,displayVidOffset,displayVidDuration,...
        fixationPostVidOnset,fixationPostVidDuration,jitterVideo(trial),...
        displayAnswerOnset,displayAnswerDuration,timeoutAnswer,responseAnswer,timestampAnswer,timestampAnswerWhite,rtAnswer,...
        fixationPostAnswerOnset,fixationPostAnswerDuration,betweenRatingFixation,...
        displayCuriosityOnset,displayCuriosityDuration,timeoutCuriosity,responseCuriosity,timestampCuriosity,timestampCuriosityWhite,rtCuriosity,startValueCuriosity,clicksCuriosity,...
        fixationPostCuriosityOnset,fixationPostCuriosityDuration,jitterRating(trial)};
    
    varsOfInterestQuest = {subject,fMRI,group,motivation,['q_trial_' num2str(totalQuestions)],questionnaire{totalQuestions},startValueQuestion,clicksQuestion,theValue,displayQuestionOnset,timestampQuestion,rtQuestion};
    
    respMatQuest(totalQuestions,:) = varsOfInterestQuest;

    
    % save respMatQuest to .mat file %
    filename = sprintf('%s_questionnaire.mat',fMRI);
    
    save(fullfile(SAVE_DIR,filename), 'respMatQuest')
    
end

% save data as .txt file
Quest = cell2table(respMatQuest,'VariableNames',varsOfInterestQuestName);

FileName=[fMRI '_questionnaire_' datestr(now, 'dd-mm-yyyy HH:MM') '.txt'];
writetable(Quest, fullfile(SAVE_DIR,FileName), 'Delimiter', 'tab')