function camSaveFrames
    global fileInfo cam 

    if cam.FramesAvailable>0
        [data, ts, metadata] = getdata(cam, cam.FramesAvailable);

        fname=fullfile(fileInfo.path, fileInfo.anim,...
            [fileInfo.anim '_u' fileInfo.unit '_' fileInfo.expt],...
            [fileInfo.anim '_u' fileInfo.unit '_' fileInfo.expt '_t' fileInfo.trialno]);
        save(fname,"ts", "metadata", "data", "-V6");
        fprintf("File saved (short) : %s\n\n", fname);
    else
        %fprintf("camSaveFrames() - no data\n");
    end
end

