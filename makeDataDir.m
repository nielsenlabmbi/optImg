function makeDataDir(fileInfo)
%generate file structure for isidata

baseName=fullfile(fileInfo.path,fileInfo.anim);

%check for animal folder
if ~isfolder(baseName)
    mkdir(baseName);
end

%check for experiment specific folder
fullName=fullfile(baseName,[fileInfo.anim '_u' fileInfo.unit '_' fileInfo.expt]);
if ~isfolder(fullName)
    mkdir(fullName);
end

