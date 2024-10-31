function camSaveFramesCb(obj,event, videoinput)
    global fileInfo

    [data, ts, metadata] = getdata(videoinput, videoinput.FramesAvailable);
    
    if ~isempty(data)
        fname=fullfile(fileInfo.pathname, fileInfo.filename);
        save(fname,"ts", "metadata", "data", "-V6");
        fprintf("File saved : %s\n\n", fname);
    else
        fprintf("camSaveFramesCb() - no data\n");
    end
end

