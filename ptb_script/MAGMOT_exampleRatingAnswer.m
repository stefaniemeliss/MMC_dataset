Screen('TextSize', window, fontSizeSmall);
DrawFormattedText(window, 'This is how it is going to look like:', ... % answer scale
    'center', screenYpixels * 0.1, white);

Screen('TextSize', window, fontSizeBig);
abzisse = -0.04;

DrawFormattedText(window, answerRating, ...
    'center', screenYpixels * 0.25, white); % display question and answer options colour coded
DrawFormattedText(window, '0 to 10',    screenXpixels*(abzisse + 0.2), screenYpixels * 0.6, [0 0 1]); % blue
DrawFormattedText(window, '11 to 20',   screenXpixels*(abzisse + 0.4), screenYpixels * 0.6, [1 1 0]); % yellow
DrawFormattedText(window, '21 to 30',   screenXpixels*(abzisse + 0.6), screenYpixels * 0.6, [0 1 0]); % green
DrawFormattedText(window, '31 or more', screenXpixels*(abzisse + 0.8), screenYpixels * 0.6, [1 0 0]); %red

Screen('TextSize', window, fontSizeSmall); % display which finger lies on which button
DrawFormattedText(window, '(index finger)',     screenXpixels*(abzisse + 0.2), screenYpixels * 0.7, white);
DrawFormattedText(window, '(middle finger)',    screenXpixels*(abzisse + 0.4), screenYpixels * 0.7, white);
DrawFormattedText(window, '(ring finger)',      screenXpixels*(abzisse + 0.6), screenYpixels * 0.7, white);
DrawFormattedText(window, '(pinkie)',           screenXpixels*(abzisse + 0.8), screenYpixels * 0.7, white);

DrawFormattedText(window, keyPress,...
    'center', screenYpixels*0.9, white);
Screen('Flip', window);