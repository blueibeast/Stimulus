function  soundFeedback( durationSecs, correct )

%---------------
% Sound Setup
%---------------

% Initialize Sounddriver
InitializePsychSound(1);

% Number of channels and Frequency of the sound
nrchannels = 2;
freq = 24000;

% How many times to we wish to play the sound
repetitions = 1;

% Length of the beep
beepLengthSecs = durationSecs;

% Start immediately (0 = immediately)
startCue = 0;

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
pahandle = PsychPortAudio('Open', [], 1, 1, freq, nrchannels);

% Set the volume to half for this demo
PsychPortAudio('Volume', pahandle, 0.5);

% Make a beep which we will play back to the user
if correct == 1
    myBeep = MakeBeep(600, beepLengthSecs, freq);
else
    myBeep = MakeBeep(300, beepLengthSecs, freq);
end

% Fill the audio playback buffer with the audio data, doubled for stereo
% presentation
PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);

% Start audio playback
PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
pause( durationSecs );

% Stop playback
PsychPortAudio('Stop', pahandle);

% Close the audio device
PsychPortAudio('Close', pahandle);

end