%%
cam = videoinput('gige', 1, 'Mono8');
src = cam.Source;
src.PacketSize = 9014;
src.PacketDelay = 112;  % used CalculatePacketDelay.m
 
cam.IgnoreDroppedFrames = 'on';  % this might not be desirable
%v.StopFcn = {@cbTest, v};
cam.FramesAcquiredFcn = {@cbTest, cam};
cam.FramesAcquiredFcnCount = 64;
cam.TriggerFcn = 'camTriggerOccurred';
cam.StartFcn = {@startCb, cam};
triggerconfig(cam, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
src.TriggerMode = 'on';
cam.TriggerRepeat = 0;


%% this works kinda
numTrials = 1;
trialDur = 3.8;  
dt = 6; % trialDur/1;    
frameRate = 16;
numFrames = ceil(trialDur * frameRate);
% s.ExposureMode = 'Timed';
% s.ExposureTimeRaw = 49000;
% Specify number of frames to acquire
%cam.TriggerRepeat = numTrials - 1;
cam.FramesPerTrigger = numFrames;
% s.TriggerNumFrames = v.FramesPerTrigger;
cam.FramesAcquiredFcnCount = numFrames;
%%%
clear data;
% Start continuous buffered acquisition and wait for acquisition to complete
%tic
%%
tic
start(cam);  % takes about 1.6-2.0 sec to complete
toc
%%

for trial = 1:numTrials
    fprintf('trigger now\n')

    fprintf('start wait\n')
    tic
    try 
        wait(cam, trialDur + dt, 'running')
    catch ME
        disp(ME.message)
        fprintf("\ntimeout")
        stop(cam)
    end
    toc
    fprintf('wait finished\n')
    fprintf('captured %d of %d frames\n', cam.FramesAcquired, numFrames);
    if(cam.FramesAcquired ~= numFrames)
        fprintf('dropped %d frames\n', cam.NumDroppedFrames)
    end
    [data, ts] = getdata(cam, cam.FramesAvailable);
    if ~isempty(data)
        imaqmontage(data)
    else
        fprintf("no data\n")
        stop(cam)
    end
end

%% save to mat file
tic
fname = 'testData1'
save(fname,"ts", "data")
toc
%% clear and reset
flushdata(cam);
imaqreset;
delete(cam);
clear;
close all;

