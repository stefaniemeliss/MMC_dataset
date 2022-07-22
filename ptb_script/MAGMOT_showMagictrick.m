% draw blank screen
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);

% waiting for trigger to start video presentation  with TR %
if scanner
    KbQueueCreate(triggerDevice, keysOfInterestTrigger);	% First queue: scannerSignal
    KbQueueStart(triggerDevice);
    KbQueueWait(triggerDevice); % Wait until the 't' key signal is sent
    
    % show white fixation until trigger was sent, then flip to black fixation
    displayVidOnset = Screen('Flip', window);
    
    KbQueueRelease(triggerDevice);
else
    % if not waiting for a trigger, display white fixation for 2000ms, then flip to black fixation
    displayVidOnset = Screen('Flip', window, triggerTaskBlockRaw + pre_stim_rest - timingCorrection);
end

if eyetracking
    if ~dummymode
        Eyelink('Message', 'displayVidOnset');
    end
end

% magic trick presentation %
vid = Screen('OpenMovie', window, moviename);
Screen('PlayMovie', vid, 1);
tex = 0;
msgsentAll = false;

if practice
    msgsentAll = true;
end

msgIndex = 1; % keeps track of which message needs to be sent to the eyetracker next

while tex ~= -1
    
    if ~msgsentAll
        currentTimeStamp = combinedInfoForThisTrickOrdered{2,msgIndex};
        
        if isnan(currentTimeStamp)
            combinedInfoForThisTrickOrdered{3,msgIndex} = NaN;
            msgIndex = msgIndex+1;
        elseif GetSecs - displayVidOnset > currentTimeStamp
            
            if eyetracking && ~dummymode
                Eyelink('Message', '%s', combinedInfoForThisTrickOrdered{1,msgIndex} );
            end
            combinedInfoForThisTrickOrdered{3,msgIndex} = GetSecs; % get timestamp of actual display
            combinedInfoForThisTrickOrdered{3,msgIndex} = combinedInfoForThisTrickOrdered{3,msgIndex} - triggerTaskBlockRaw; % calculating timing relative to task block onset
            
            msgIndex = msgIndex+1;
        end
    end
    
    if ~practice && msgIndex > numEvents
        msgsentAll = true;
        
        % create object with the actual presentation times
        presentedTimingsForThisTrickOrdered = combinedInfoForThisTrickOrdered(3,:); 
        % reorder combinedInfoForThisTrickOrdered (or its parts) back to initial sequence of events
        [ranks_reordered, idx_revised] = sort(idx, 'ascend'); % get index for idx in ascending order
        timingsForThisTrickReordered = timingsForThisTrickOrdered(idx_revised); % order the timings back to how they were
        eventsReordered = eventsOrdered(idx_revised); % order events back to how they were
        presentedTimingsForThisTrickReordered = presentedTimingsForThisTrickOrdered(idx_revised); % order presentation timing back to how they were
        combinedInfoForThisTrickReordered = [eventsReordered; timingsForThisTrickReordered; presentedTimingsForThisTrickReordered]; % combine all three in one object

    end
    
    [tex pts] = Screen('GetMovieImage', window, vid);
    if(tex>0)
        Screen('DrawTexture', window, tex);
        Screen('Close', tex)
        stimonset = Screen('Flip', window);
    end
    [keyIsDown, secs, keyCode] = KbCheck(experimenterKeyboard);
    if keyCode(escape)==1
        Screen('PlayMovie', vid, 0);
        Screen('CloseMovie', vid);
        sca;
        disp('*** Experiment terminated ***');
        return
    end
end
Screen('CloseMovie', vid);

displayVidOffset = GetSecs;
if eyetracking
    if ~dummymode
        Eyelink('Message', 'displayVidOffset');
    end
end
displayVidDuration = displayVidOffset - displayVidOnset;


