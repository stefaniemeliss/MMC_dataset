Screen('TextSize', window, fontSizeSmall);
DrawFormattedText(window, 'This is how it is going to look like:', ... %curiosity scale
    'center', screenYpixels * 0.1, white);

Screen('TextSize', window, fontSizeBig);
DrawFormattedText(window, curiosityRating, ...
    'center', screenYpixels * 0.4, white); % display question and answers in white
DrawFormattedText(window, '1', screenXpixels*0.125, screenYpixels * 0.6, white);
DrawFormattedText(window, '2', screenXpixels*0.25, screenYpixels * 0.6, white);
DrawFormattedText(window, '3', screenXpixels*0.375, screenYpixels * 0.6, white);
DrawFormattedText(window, '4', screenXpixels*0.5, screenYpixels * 0.6, [1 0 0]);
DrawFormattedText(window, '5', screenXpixels*0.625, screenYpixels * 0.6, white);
DrawFormattedText(window, '6', screenXpixels*0.75, screenYpixels * 0.6, white);
DrawFormattedText(window, '7', screenXpixels*0.875, screenYpixels * 0.6, white);

DrawFormattedText(window, 'not at all', screenXpixels*(-0.04+0.125), screenYpixels * 0.8, white);
DrawFormattedText(window, 'very',       screenXpixels*(-0.04+0.875), screenYpixels * 0.8, white);

Screen('TextSize', window, fontSizeSmall);
DrawFormattedText(window, keyPress,...
    'center', screenYpixels*0.9, white);
Screen('Flip', window);