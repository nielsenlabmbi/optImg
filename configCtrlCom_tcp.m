function configCtrlCom_tcp(ctrlIP)

%udp connection to control
global CtrlCom

CtrlCom=tcpclient(ctrlIP,40000);
configureTerminator(CtrlCom,126); %126 = ~
configureCallback(CtrlCom,'terminator',@camIsiCb);


disp('Control connected')