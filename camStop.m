function camStop(obj,event)
global fileInfo UDPport 

fprintf("camStop\n");
%let control know acquisition done (with exception of dummy trial)
if ~strcmp(fileInfo.trialno,'0')
    %disp('Sending update to control')
   % fwrite(UDPport.serialPortHandle,'doneData~');
end

end