function camSaveFramesCb(obj,event, videoinput)
    global fileInfo UDPport 

    [data, ts, metadata] = getdata(videoinput, videoinput.FramesAvailable);
    
    if ~isempty(data)
        if fileInfo.trialno>0
            fname=fullfile(fileInfo.path, fileInfo.anim,...
                [fileInfo.anim '_u' fileInfo.unit '_' fileInfo.expt],...
                [fileInfo.anim '_u' fileInfo.unit '_' fileInfo.expt '_t' fileInfo.trialno]);
            save(fname,"ts", "metadata", "data", "-V6");
            fprintf("File saved : %s\n\n", fname);
        end
    else
        fprintf("camSaveFramesCb() - no data\n");
    end
end

