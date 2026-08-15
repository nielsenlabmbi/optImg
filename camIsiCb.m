function camIsiCb(src,~)

global cam camProp  CtrlCom fileInfo NIlogger;

if src.NumBytesAvailable>0
    %test once whether logger is available so we don't need to add it to
    %all functions below (conditions only met if there is a valid
    %logger, which should only be the case when selected)
    if exist('NIlogger', 'var') == 1 && isa(NIlogger, 'NIAnalogLogger') && isvalid(NIlogger)
        useLogger=1;
    else
        useLogger=0;
    end

    %parse string
    inString=readline(src);
    inString=char(inString);
    disp(['Message received from ctrl: ' inString]);
    
    msg=strtrim(strsplit(inString,';'));
    
    switch msg{1}
                
        case 'F' %filename - 3 strings after F with animal, unit, experiment
            fileInfo.anim=msg{2};
            fileInfo.unit=msg{3};
            fileInfo.expt=msg{4};

            %make directory
            makeDataDir(fileInfo);

            %also set logger directory
            if useLogger
                loggerBase=fullfile(fileInfo.path,fileInfo.anim,[fileInfo.anim '_u' fileInfo.unit '_' fileInfo.expt]);
                NIlogger.setOutputDir(loggerBase);
            end
       
        case 'D' % trial duration in seconds
            dur = str2double(msg{2});
            numFrames=ceil(camProp.frameRate*dur);

            fprintf("Trial duration: %0.2f seconds.  numFrames = %d\n", dur, numFrames)
            
            cam.FramesPerTrigger = numFrames;
            cam.FramesAcquiredFcnCount = numFrames;
            src = getselectedsource(cam);
            src.TriggerNumFrames = cam.FramesPerTrigger;
           

        case 'T' %get camera ready for acquisition (per trial, starts with hardware trigger)
           
            fileInfo.trialno=msg{2};
            %start camera
            start(cam);
            disp(['Trial ' fileInfo.trialno ' start (waiting for trigger)']);
            
            %start data logger 
            if useLogger
                NIlogger.start();
            end
            
        case 'S' %stop camera - this always gets executed, independent of whether the camera finishes
            % because it has reached the correct frame number (otherwise we
            % get hung up on dropped frame)
            disp('Acquisition stopped');
            camSaveFrames; %this applies in the case of dropped frames
            stop(cam);
            
            %stop logger
            if useLogger
                NIlogger.stop([fileInfo.anim '_u' fileInfo.unit '_' fileInfo.expt '_t' fileInfo.trialno '_log']);
            end

            %pause(2);
            disp('Sending update to control')
            write(CtrlCom,'doneData');

        case 'I' %dummy first trial to avoid dropped frame issue
            fileInfo.trialno='0';
            disp('Dummy trial - starting');
            start(cam)
            disp('Dummy trial - waiting for trigger');
            pause(5);
            %need to explicitly stop in case of dropped frames
            stop(cam);
            %flush data
            disp(cam.FramesAvailable)
            data = getdata(cam, cam.FramesAvailable);
            disp('Sending update to control')
            write(CtrlCom,'doneData');
    end
 
    %if ~strcmp(msg{1},'T') && ~strcmp(msg{1},'I')
        %fwrite(UDPport.serialPortHandle,'a~');
    %end
       
end