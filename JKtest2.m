%%
v = videoinput('gige', 1, 'Mono8');
s = v.Source;
triggerconfig(v, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
s.TriggerMode = 'on';
v.TriggerRepeat = 0;
s.PacketSize = 9014;
s.PacketDelay = 112;  % used CalculatePacketDelay.m
% 
v.IgnoreDroppedFrames = 'on';
v.StopFcn = 'cbTest';
v.TriggerFcn = 'camTriggerOccurred';

%% this works kinda
numTrials = 2;
trialDur = 4.0;  
dt = 6; % trialDur/1;    
frameRate = 16;
numFrames = ceil(trialDur * frameRate);
% s.ExposureMode = 'Timed';
% s.ExposureTimeRaw = 49000;
% Specify number of frames to acquire
v.TriggerRepeat = numTrials - 1;
v.FramesPerTrigger = numFrames;
s.TriggerNumFrames = v.FramesPerTrigger;
%%%
clear data;
% Start continuous buffered acquisition and wait for acquisition to complete
tic
start(v);  % takes about 1.6-2.0 sec to complete
toc

for trial = 1:numTrials
    fprintf('trigger now\n')

    fprintf('start wait\n')
    tic
    try 
        %wait(v, trialDur + dt, "logging")
        wait(v, trialDur + dt, 'running')
    catch ME
        disp(ME.message)
        fprintf("\ntimeout")
        stop(v)
    end
    toc
    fprintf('wait finished\n')
    if(v.FramesAcquired ~= numFrames)
        fprintf('dropped %d frames\n', v.NumDroppedFrames)
    end
    [data, ts] = getdata(v, v.FramesAvailable);
    if ~isempty(data)
        imaqmontage(data)
    else
        fprintf("no data\n")
        stop(v)
    end
end

%%
flushdata(v);
imaqreset;
delete(v);
clear;
close all;

