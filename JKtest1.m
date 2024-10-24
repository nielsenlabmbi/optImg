%% connect camera
    cam = videoinput('gige', 1);
    
    if exist('cam')
        src = getselectedsource(cam);
        % stop(cam)
        
        % make sure Jumbo Frames are set to 9k in the GigE NIC adapter settings
        src.PacketSize = 9000;  

        %initialize without triggers and full field
        set(src, 'TriggerMode', 'Off');
        %triggerconfig(cam,'immediate','none','none');
        triggerconfig(cam,'manual','none','none');
        fullSize=cam.VideoResolution;
        cam.ROIPosition=[0 0 fullSize(1) fullSize(2)];
        
        % JK activate strobe1
        set(src, 'StdStrobe1Mode', 'EachFrame');

    end

    %%
    set(src, 'TriggerNumFrames', 80);

    %% 
    im = getdata(cam);
    %%
    if(exist('cam', 'var'))
        src = getselectedsource(cam);
        delete(cam);
        clear cam;
        clear src;

    end

    %% useful
    imaqreset
    %%
    imaqhelp