function camSaveFramesCb(obj,event, videoinput)
    global fileInfo

    [data, ts] = getdata(videoinput, videoinput.FramesAvailable);
    
    if ~isempty(data)
        fname=fullfile(fileInfo.pathname, fileInfo.filename);
        save(fname,"ts", "data", "-V6");
        fprintf("file saved : %s\n\n", fname);
    else
        fprintf("camSaveFramesCb() - no data\n");
    end
end

