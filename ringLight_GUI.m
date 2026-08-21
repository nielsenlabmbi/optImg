% ringLight_GUI.m
% JK 23 July 2026
%
% Simple GUI to control the microscope-mounted NeoPixel ring.
%
% Requires:
%   - MATLAB R2019b or later (uses serialport and uifigure)
%   - Arduino running aiNeopixels.ino
%     (/home/justin/jkcode/arduino/ringLight/ringLight.ino)
%
% Usage:
%   >> ringLight_GUI
%
% Close the Arduino Serial Monitor before launching — only one app may
% hold the serial port at a time.
%
% Serial protocol (115200 baud, LF-terminated lines sent to Arduino):
%   W128,R64,G32,B0   set ring color (White, Red, Green, Blue; each 0-255)
%   OFF               turn ring off

function ringLight_GUI

    % --- Find Arduino serial port (OS-specific device name pattern) ---
    if ismac
        searchStr = "cu.usb";
    elseif ispc
        searchStr = "COM";
    else
        searchStr = "ACM";   % Linux
    end

    ports = serialportlist;
    portStr = "";
    for k = 1:numel(ports)
        if contains(ports(k), searchStr)
            portStr = ports(k);
            break;
        end
    end
    if portStr == ""
        error("No Arduino serial port found.");
    end

    % JK
    disp("JK manually set to COM4");
    portStr = "COM4";

    % Baud rate must match Serial.begin() in aiNeopixels.ino
    baud = 115200;
    s = serialport(portStr, baud);
    configureTerminator(s, "LF");

    % Opening the port toggles DTR and resets the Arduino; wait for boot
    pause(2.5);
    flush(s);
    while s.NumBytesAvailable > 0
        line = readline(s);
        fprintf("Arduino: %s", line);
    end

    % --- Build GUI ---
    fig = uifigure("Name", "RingLight Control", "Position", [100 100 420 360]);
    % Set CloseRequestFcn after fig exists; pass src (not fig) into callback
    fig.CloseRequestFcn = @(src, ~) closeGUI(s, src);

    labels = ["White", "Red", "Green", "Blue"];
    sliders = gobjects(1, 4);
    valueLabels = gobjects(1, 4);

    for i = 1:4
        y = 300 - (i - 1) * 70;
        uilabel(fig, "Text", labels(i), "Position", [20 y 60 22], 'FontSize', 20);
        % Create value label before slider so ValueChangedFcn gets a real handle
        valueLabels(i) = uilabel(fig, "Text", "0", "Position", [360 y 40 22], 'FontSize', 18);
        sliders(i) = uislider(fig, "Limits", [0 255], "Value", 0, ...
            "Position", [90 y+5 250 3], ...
            "ValueChangedFcn", @(src, ~) updateValueLabel(src, valueLabels(i)));
    end

    % On sends current slider values; Off sends OFF command to Arduino
    uibutton(fig, "Text", "On", "Position", [80 15 100 36], ...
        "ButtonPushedFcn", @(~,~) sendColor(s, sliders));
    uibutton(fig, "Text", "Off", "Position", [220 15 100 36], ...
        "ButtonPushedFcn", @(~,~) writeline(s, "OFF"));

    fprintf("Connected to %s at %d baud\n", portStr, baud);
end

% Update numeric readout next to a slider when it moves
function updateValueLabel(slider, lbl)
    lbl.Text = sprintf("%d", round(slider.Value));
end

% Send W,R,G,B command built from slider positions
function sendColor(s, sliders)
    w = round(sliders(1).Value);
    r = round(sliders(2).Value);
    g = round(sliders(3).Value);
    b = round(sliders(4).Value);
    cmd = sprintf("W%d,R%d,G%d,B%d", w, r, g, b);
    writeline(s, cmd);
end

% Clean shutdown: ring off, release serial port, close figure
function closeGUI(s, fig)
    fig.CloseRequestFcn = '';   % prevent re-entry during cleanup
    try
        writeline(s, "OFF");
    catch
    end
    delete(s);
    delete(fig);
end
