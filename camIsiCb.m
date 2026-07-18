function camIsiCb(obj, event)

global cam  UDPport fileInfo;

try
    n = get(UDPport.serialPortHandle,'BytesAvailable');

    if n > 0
        inString = fread(UDPport.serialPortHandle,n);
        inString = char(inString');
    else
        return
    end
    
    inString = inString(1:end-1);  %Get rid of the terminator
    disp(['Message received from ctrl: ' inString]);
    
    msg=strtrim(strsplit(inString,';'));
    
    switch msg{1}
                
        case 'F' %filename - 3 strings after F with animal, unit, experiment
            fileInfo.anim=msg{2};
            fileInfo.unit=msg{3};
            fileInfo.expt=msg{4};

            %make directory
            makeDataDir(fileInfo);
       
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
            
        case 'S' %stop camera
            disp('Acquisition stopped');
            camSaveFrames;
            stop(cam);
            
            %pause(2);
            %disp('Sending update to control')
            %fwrite(UDPport.serialPortHandle,'doneData~');

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
            fwrite(UDPport.serialPortHandle,'doneData~');
    end
 
    if ~strcmp(msg{1},'T') && ~strcmp(msg{1},'I')
        %fwrite(UDPport.serialPortHandle,'a~');
    end
   
catch ME
    disp(ME.message);
    
end