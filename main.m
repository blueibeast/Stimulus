% Clear the workspace
close all;
clearvars;
sca;

%----------------------------------------------------------------------
%                       Ground Truth
%----------------------------------------------------------------------
filename = 'GroundTruth.xlsx';
truthTable = xlsread(filename);
problems = truthTable(:,1);
answers = truthTable(:,2);
complexity = truthTable(:,3); 

% Store ID and password
[login, blockName] = logindlg('Title','Mental Rotation');

% Setup PTB with some default values
PsychDefaultSetup(2);

% Set the screen number to the main monitor
screenNumber = 1;%max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2);

% Enable alpha blending
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
% Get the size of the on screen window
screenXpixels = windowRect(3);
screenYpixels = windowRect(4);
 
% Hide the cursor
HideCursor(screenNumber);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 30);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------

% Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames = round(isiTimeSecs / ifi);

% Stimulus displaying time in seconds and frames
TimeOutSecs = 5; %% Timing is off for Ball stimulus. Why?
TimeOutFrames = round(TimeOutSecs / ifi);

% Numer of frames to wait before re-drawing
waitframes = 1;

%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
%downKey = KbName('DownArrow');

%----------------------------------------------------------------------
%                      Experimental Image List
%----------------------------------------------------------------------

% Get the image files for the experiment
if strcmp( blockName, 'dash' );
    imageFolder = [cd '/Images/Dash_Wedge/'];
end
if strcmp( blockName, 'ball' );
    imageFolder = [cd '/Images/Ball_Stick/'];
end
if strcmp( blockName, 'mental' );
    imageFolder = [cd '/Images/Mental Rotation Stimuli/'];
end
imgList = dir(fullfile(imageFolder, '*.png'));
imgList = {imgList(:).name};
numImages = length(imgList);

% Check to see if the number of files is even. This needs to be the case.
isOdd = mod(numImages, 2);
if isOdd == 1
    error('*** Number of files has to be even to procede ***');
end
numTrials  = numImages / 2;
trialOrder = Shuffle(1:numTrials);
%numTrials = 10;

%----------------------------------------------------------------------
%                      Response Matrices
%----------------------------------------------------------------------

% Response time
responseTime = zeros(numTrials,1);

% Score
score = zeros(numTrials,1);

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

% Animation loop: we loop for the total number of trials
for trial = 1:numTrials

    % Cue to determine whether a response has been made
    respToBeMade = false;
    
    % Cue for the sound feeback
    correctness = 0;

    % If this is the first trial we present a start screen and wait for a
    % key-press
    if trial == 1
        line1 = 'Determine The Stereochemical Relationship Between Two Molecules.\n\n';
        line2 = 'For Each Question, Press The Rightkey For "Yes" And The Leftkey For "No".\n\n';
        line3 = 'Press Any Key To Begin';
        DrawFormattedText(window, [line1, line2, line3],...
            'center', 'center', black);
        Screen('Flip', window);
        KbStrokeWait;
    end
    
     if trial == 11
        line1 = 'This Is The End Of Practice Session.\n\n';
        line2 = 'Press Any Key To Begin The Actual Test.';
        DrawFormattedText(window, [line1, line2],...
            'center', 'center', black);
        Screen('Flip', window);
        KbStrokeWait;
    end

    % Flip again to sync us to the vertical retrace at the same time as
    % drawing our fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, white, [], 2);
    vbl = Screen('Flip', window);

    % Now we present the isi interval with fixation point minus one frame
    % because we presented the fixation point once already when getting a
    % time stamp
    for frame = 1:isiTimeFrames - 1

        % Draw the fixation point
        Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);

        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end

    % Now present the word in continuous loops until the person presses a
    % key to respond. We take a time stamp before and after to calculate
    % our reaction time. We could do this directly with the vbl time stamps,
    % but for the purposes of this introductory demo we will use GetSecs.
    %
    % The person should be asked to respond to either the written word or
    % the color the word is written in. They make thier response with the
    % three arrow key. They should press "Left" for "Red", "Down" for
    % "Green" and "Right" for "Blue".
    tStart = GetSecs;
    for frame = 1:TimeOutFrames - 1  %while respToBeMade == false

        % Define the file names for the two pictures
        imageNameA = [num2str( trialOrder(1,trial) ) 'a.png'];
        imageNameB = [num2str( trialOrder(1,trial) ) 'b.png'];
        
        % Now load the images
        [theImageA, mapA, alphaA] = imread([imageFolder imageNameA]);
        [theImageB, mapB, alphaB] = imread([imageFolder imageNameB]);

        % Make the images into textures
        %theImageA(:,:,4) = alphaA;    % Stack the alpha layer on top of image as a 4th layer
        %theImageB(:,:,4) = alphaB;    
        texA = Screen('MakeTexture', window, theImageA);
        texB = Screen('MakeTexture', window, theImageB);
        
        % Now fill the screen black
        Screen('FillRect', window, white);
        
        % Draw images to the screen
        [h1, w1, d1] = size(theImageA);    % Measure image size
        leftRect = [0 0 w1 h1];
        [h2, w2, d2] = size(theImageB);    % Measure image size
        rightRect = [0 0 w2 h2];
        %ratio = screenXpixels / ( w1 + w2 ) * 0.7;
        if strcmp( blockName, 'dash' );
            ratio = screenXpixels / ( 1183 + 1185 );
        else
            ratio = screenXpixels / ( 1322 + 1339 );
        end
        yPos = yCenter;
        xPos = linspace(0, screenXpixels, 5);
        Screen( 'DrawTexture', window, texA, [], CenterRectOnPointd( leftRect * ratio, xPos(2), yPos ), 0 );
        Screen( 'DrawTexture', window, texB, [], CenterRectOnPointd( rightRect * ratio, xPos(4), yPos ), 0 );

        % Check the keyboard. The person should press the
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            ShowCursor;
            sca;
            return
        elseif keyCode(leftKey)
            response = 0;
            respToBeMade = true;
            if response == answers( trialOrder(1,trial), 1 );
                score( trialOrder(1,trial), 1 ) = 1;
                correctness = 1;
            else
                score( trialOrder(1,trial), 1 ) = 0;
            end
            % Flip to the screen
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            break;
        elseif keyCode(rightKey)
            response = 1;
            respToBeMade = true;
            if response == answers( trialOrder(1,trial), 1 );
                score( trialOrder(1,trial), 1 ) = 1;
                correctness = 1;
            else
                score( trialOrder(1,trial), 1 ) = 0;
            end
            % Flip to the screen
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            break;
        end
        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    if respToBeMade == false
        score( trialOrder(1,trial), 1 ) = NaN;
        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    tEnd = GetSecs;
    rt = tEnd - tStart;
    responseTime( trialOrder(1,trial), 1 ) = rt;    % Score response time
    
    % SoundFeedback
    if correctness == 1
        soundFeedback(0.5,1);
    else
        soundFeedback(0.5,0);
    end
end

% End of experiment screen. We clear the screen once they have made their
% response
Screen('FillRect', window, grey);
DrawFormattedText(window, 'Experiment Finished \n\n Press Any Key To Exit',...
    'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
sca;

% Write recorded results to Excel file
fileName = 'testResults.xlsx';
sheet = str2double( login );
xlswrite( fileName, problems, sheet, 'A1' );
xlswrite( fileName, responseTime, sheet, 'B1' );
xlswrite( fileName, complexity, sheet, 'C1' );
xlswrite( fileName, score, sheet, 'D1' );

% Plot Results
subplot(1,2,1);
hold on;
for i = 1 : numTrials
    if score(i,1) == 1
        scatter(problems(i,1),responseTime(i,1), 'o', 'black');
    else
        scatter(problems(i,1),responseTime(i,1), 'x', 'red');
    end
    drawnow;
end
xlabel('Problem #');
ylabel('Response Time');
subplot(1,2,2);
hold on;
for i = 1 : numTrials
    if score(i,1) == 1
        scatter(problems(i,1),complexity(i,1), 'o', 'black');
    else
        scatter(problems(i,1),complexity(i,1), 'x', 'red');
    end
    drawnow;
end
xlabel('Problem #');
ylabel('Complexity');