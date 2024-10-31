function camPldapsCb(obj, event)

global cam UDPport fileInfo trialCounter meta;

try
    n = get(UDPport,'NumBytesAvailable');
    %disp("camPladaps callback()") ;

    if n > 0
        % inString = fread(UDPport,n);
        inString = readline(UDPport);
        %inString = char(inString');
    else
        disp("JK 2384 return")
        return
    end
    
    %inString = inString(1:end-1);  %Get rid of the terminator
    msg=strtrim(strsplit(inString,';'));
    %disp(['received: ' msg{1}])
    
    switch msg{1}
        
        case 'P' %preview
            camPreview;
            
        case 'F' %filename
            fileInfo.filename=strtrim(msg{2});
            % JK The data are saved in camSaveFramesCb().
           
        case 'G' %get camera ready for acquisition (starts with hardware trigger)
            start(cam);
            disp(['Trial ' num2str(trialCounter) ' start (waiting for trigger)']);
           
        case 'T' % trial duration in seconds
            frameRate = 16.29;
            dur = str2double(msg{2});
            numFrames = ceil(dur * frameRate);
            fprintf("Trial duration: %0.2f seconds.  numFrames = %d\n", dur, numFrames)
            cam.FramesPerTrigger = numFrames;
            cam.FramesAcquiredFcnCount = numFrames;
            
        case 'S' %stop camera
            disp('Acquisition stopped');
            stop(cam);
            camSaveData;
          
        % case 'E' %close files, clean up - including deleting the camera obj.  
        %     disp('Protocol end.  Closing files and camera.');
        %     %save metadata
        %     fname=fullfile(fileInfo.pathname,[fileInfo.filename '_meta.mat']);
        %     save(fname, 'meta');
        % 
        %     %close movie file
        %     % close(fileInfo.writerObj);
        % 
        %     %close and clean up.  This deletes the camera without updating
        %     %the GUI so use with caution.  
        %     camClose;
    end
 
    if ~strcmp(msg{1},'G')
        fwrite(UDPport,'a~');
    end
   
catch ME
    disp(ME.message);
    
end