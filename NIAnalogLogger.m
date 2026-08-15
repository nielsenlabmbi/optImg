classdef NIAnalogLogger < handle
    %NIANALOGLOGGER  Command-driven analog data logger for NI USB-6008.
    %
    % Each call to start()/stop() runs one acquisition and saves it to
    % its own .mat file. No pause() is used -- data is accumulated in a
    % buffer via the daq object's ScansAvailableFcn callback, which fires
    % asynchronously as data streams in.
    %
    % USAGE:
    %   logger = NIAnalogLogger();   % set up device (uses defaults below)
    %   logger.setOutputDir("D:\data\session3");  
    %   logger.start();              % begin acquisition
    %   ...                          % do other things, acquisition runs in background
    %   logger.stop();               % end acquisition, saves e.g. acq_20260814_153012_441.mat
    %
    %   logger.start();              % run it again -> new .mat file
    %   logger.stop("myRun.mat");    % or supply your own filename
    %
    %   logger.delete();             % release the device when fully done
 
    properties
        devID   = "Dev1"           % change to match your device (see: daqlist)
        chNames = ["ai0","ai1"]    % analog channels to log
        fs      = 100              % Hz
    end
 
    properties (SetAccess = private)
        IsRunning = false
        outDir    = "."            % folder for saved .mat files -- use setOutputDir() to change
    end
 
    properties (Access = private)
        d               % daq object
        bufTime         % growing column vector of timestamps (s)
        bufData         % growing NxC matrix of samples
    end
 
    methods
        function obj = NIAnalogLogger(devID, chNames, fs, outDir)
            if nargin >= 1, obj.devID   = devID;   end
            if nargin >= 2, obj.chNames = chNames; end
            if nargin >= 3, obj.fs      = fs;      end
            if nargin >= 4, obj.setOutputDir(outDir); end
 
            obj.d = daq("ni");
            obj.d.Rate = obj.fs;
            for ch = obj.chNames
                addinput(obj.d, obj.devID, ch, "Voltage");
            end
            obj.d.ScansAvailableFcnCount = max(1, round(obj.fs/10)); % ~10 callbacks/sec
            obj.d.ScansAvailableFcn = @(src, evt) obj.onScansAvailable();
        end
 
        function start(obj)
            if obj.IsRunning
                warning("Logger acquisition already running -- ignoring start().");
                return
            end
            obj.bufTime = [];
            obj.bufData = [];
            start(obj.d, "continuous");
            obj.IsRunning = true;
            fprintf("Logger acquisition started.\n");
        end
 
        function stop(obj, filename)
            %STOP  End the current acquisition and save it to a .mat file.
            %
            %   logger.stop()              % auto-named: acq_<timestamp>.mat
            %   logger.stop("myRun.mat")   % explicit filename
            %   logger.stop("myRun")       % ".mat" extension added automatically
            if ~obj.IsRunning
                warning("No logger acquisition running -- ignoring stop().");
                return
            end
            stop(obj.d);
            obj.IsRunning = false;
 
            time = obj.bufTime;              %#ok<PROPLC>
            data = obj.bufData;               %#ok<PROPLC>
            channelNames = obj.chNames;       %#ok<PROPLC>
            sampleRate = obj.fs;              %#ok<PROPLC>
 
            if nargin < 2 || isempty(filename)
                fname = sprintf("acq_%s.mat", string(datetime("now","Format","yyyyMMdd_HHmmss_SSS")));
            else
                fname = string(filename);
                if ~endsWith(fname, ".mat", "IgnoreCase", true)
                    fname = fname + ".mat";
                end
            end
            fpath = fullfile(obj.outDir, fname);

            if isfile(fpath)
                warning("Logger file %s already exists -- it will be overwritten.", fpath);
            end

            save(fpath, "time", "data", "channelNames", "sampleRate");
 
            fprintf("Logger acquisition stopped. Saved %d samples to %s\n", numel(time), fpath);
        end
 
        function setOutputDir(obj, newDir)
            %SETOUTPUTDIR  Change the folder where .mat files are saved.
            %
            %   logger.setOutputDir("D:\data\session3")
            %
            % Creates the folder if it doesn't already exist. Errors if
            % the path is invalid or can't be created (e.g. bad drive
            % letter, no write permission).
            if obj.IsRunning
                warning("Changing output directory while an acquisition is running -- it will apply to the next stop().");
            end

            newDir = string(newDir);
            if ~isfolder(newDir)
                [ok, msg] = mkdir(newDir);
                if ~ok
                    error("Could not create output directory ""%s"": %s", newDir, msg);
                end
                fprintf("Created output directory: %s\n", newDir);
            end

            obj.outDir = newDir;
            fprintf("Logger output directory set to: %s\n", obj.outDir);
        end

        function delete(obj)
            if ~isempty(obj.d) && isvalid(obj.d) && obj.IsRunning
                stop(obj.d);
            end
        end
    end
 
    methods (Access = private)
        function onScansAvailable(obj)
            [data, timestamps] = read(obj.d, obj.d.ScansAvailableFcnCount, ...
                                       "OutputFormat", "Matrix");
            obj.bufTime = [obj.bufTime; seconds(timestamps)];
            obj.bufData = [obj.bufData; data];
        end
    end
end
