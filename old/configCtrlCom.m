function configCtrlCom(ctrlIP)

%udp connection to control
global CtrlCom

%udp connection to acquisition control
CtrlCom=instrfindall('RemoteHost',ctrlIP);
if length(CtrlCom)>0
    fclose(CtrlCom);
    delete(CtrlCom);
    clear CtrlCom;
end

CtrlCom.serialPortHandle = udp(ctrlIP,'RemotePort',9004,'LocalPort',8005);

set(CtrlCom.serialPortHandle, 'InputBufferSize', 1024)
set(CtrlCom.serialPortHandle, 'OutputBufferSize', 1024)
set(CtrlCom.serialPortHandle, 'Datagramterminatemode','off')

%Establish udp port event callback criterion
CtrlCom.serialPortHandle.BytesAvailableFcnMode = 'Terminator';
CtrlCom.serialPortHandle.Terminator = '~';

fopen(CtrlCom.serialPortHandle);
stat=get(CtrlCom.serialPortHandle, 'Status');

if ~strcmp(stat, 'open')
    disp([' Trouble opening connection to acq computer; cannot proceed']);
    CtrlCom.serialPortHandle=[];
    return;
end

CtrlCom.serialPortHandle.bytesavailablefcn=@camIsiCb;
disp('Control connected')