function installRobotiqGripperToolbox(replaceExisting)
% INSTALLOPTITRACKTOOLBOX installs Robotiq Gripper Toolbox for MATLAB.
%   INSTALLOPTITRACKTOOLBOX installs Robotiq Gripper Toolbox into the following 
%   locations:
%                        Source: Destination
%     Robotiq GripperToolboxFunctions: matlabroot\toolbox\optitrack
%       Robotiq GripperToolboxSupport: matlabroot\toolbox\optitrack\Robotiq GripperToolboxSupport 
%
%   INSTALLOPTITRACKTOOLBOX(true) installs Robotiq Gripper Toolbox regardless of
%   whether a copy of the Robotiq Gripper toolbox exists in the MATLAB root.
%
%   INSTALLOPTITRACKTOOLBOX(false) installs Robotiq Gripper Toolbox only if no copy 
%   of the Robotiq Gripper toolbox exists in the MATLAB root.
%
%   M. Kutzer 17Feb2016, USNA

% Updates

% TODO - Allow users to create a local version if admin rights are not
% possible.


%% Assign tool/toolbox specific parameters
dirName = 'robotiq';

%% Check inputs
if nargin == 0
    replaceExisting = [];
end

%% Installation error solution(s)
adminSolution = sprintf(...
    ['Possible solution:\n',...
     '\t(1) Close current instance of MATLAB\n',...
     '\t(2) Open a new instance of MATLAB "as administrator"\n',...
     '\t\t(a) Locate MATLAB shortcut\n',...
     '\t\t(b) Right click\n',...
     '\t\t(c) Select "Run as administrator"\n']);

%% Check for toolbox directory
toolboxRoot  = fullfile(matlabroot,'toolbox',dirName);
isToolbox = exist(toolboxRoot,'file');
if isToolbox == 7
    % Apply replaceExisting argument
    if isempty(replaceExisting)
        choice = questdlg(sprintf(...
            ['MATLAB Root already contains the Robotiq Gripper Toolbox.\n',...
            'Would you like to replace the existing toolbox?']),...
            'Yes','No');
    elseif replaceExisting
        choice = 'Yes';
    else
        choice = 'No';
    end
    % Replace existing or cancel installation
    switch choice
        case 'Yes'
            % TODO - check if NatNet SDK components are running and close
            % them prior to removing directory
            rmpath(toolboxRoot);
            [isRemoved, msg, msgID] = rmdir(toolboxRoot,'s');
            if isRemoved
                fprintf('Previous version of Robotiq Gripper Toolbox removed successfully.\n');
            else
                fprintf('Failed to remove old Robotiq Gripper Toolbox folder:\n\t"%s"\n',toolboxRoot);
                fprintf(adminSolution);
                error(msgID,msg);
            end
        case 'No'
            fprintf('Robotiq Gripper Toolbox currently exists, installation cancelled.\n');
            return
        case 'Cancel'
            fprintf('Action cancelled.\n');
            return
        otherwise
            error('Unexpected response.');
    end
end

%% Create Scorbot Toolbox Path
[isDir,msg,msgID] = mkdir(toolboxRoot);
if isDir
    fprintf('Robotiq Gripper toolbox folder created successfully:\n\t"%s"\n',toolboxRoot);
else
    fprintf('Failed to create Robotiq Gripper Toolbox folder:\n\t"%s"\n',toolboxRoot);
    fprintf(adminSolution);
    error(msgID,msg);
end

%% Migrate toolbox folder contents
toolboxContent = 'RobotiqGripperToolboxFunctions';
if ~isdir(toolboxContent)
    error(sprintf(...
        ['Change your working directory to the location of "installRobotiqGripperToolbox.m".\n',...
         '\n',...
         'If this problem persists:\n',...
         '\t(1) Unzip your original download of "RobotiqGripperToolbox" into a new directory\n',...
         '\t(2) Open a new instance of MATLAB "as administrator"\n',...
         '\t\t(a) Locate MATLAB shortcut\n',...
         '\t\t(b) Right click\n',...
         '\t\t(c) Select "Run as administrator"\n',...
         '\t(3) Change your "working directory" to the location of "installRobotiqGripperToolbox.m"\n',...
         '\t(4) Enter "installRobotiqGripperToolbox" (without quotes) into the command window\n',...
         '\t(5) Press Enter.']));
end
files = dir(toolboxContent);
wb = waitbar(0,'Copying Robotiq Gripper Toolbox toolbox contents...');
n = numel(files);
fprintf('Copying Robotiq Gripper Toolbox contents:\n');
for i = 1:n
    % source file location
    source = fullfile(toolboxContent,files(i).name);
    % destination location
    destination = toolboxRoot;
    if files(i).isdir
        switch files(i).name
            case '.'
                %Ignore
            case '..'
                %Ignore
            otherwise
                fprintf('\t%s...',files(i).name);
                nDestination = fullfile(destination,files(i).name);
                [isDir,msg,msgID] = mkdir(nDestination);
                if isDir
                    [isCopy,msg,msgID] = copyfile(source,nDestination,'f');
                    if isCopy
                        fprintf('[Complete]\n');
                    else
                        bin = msg == char(10);
                        msg(bin) = [];
                        bin = msg == char(13);
                        msg(bin) = [];
                        fprintf('[Failed: "%s"]\n',msg);
                    end
                else
                    bin = msg == char(10);
                    msg(bin) = [];
                    bin = msg == char(13);
                    msg(bin) = [];
                    fprintf('[Failed: "%s"]\n',msg);
                end
        end
    else
        fprintf('\t%s...',files(i).name);
        [isCopy,msg,msgID] = copyfile(source,destination,'f');
        
        if isCopy == 1
            fprintf('[Complete]\n');
        else
            bin = msg == char(10);
            msg(bin) = [];
            bin = msg == char(13);
            msg(bin) = [];
            fprintf('[Failed: "%s"]\n',msg);
        end
    end
    waitbar(i/n,wb);
end
set(wb,'Visible','off');

%% Save toolbox path
%addpath(genpath(toolboxRoot),'-end');
addpath(toolboxRoot,'-end');
savepath;

%% Rehash toolbox cache
fprintf('Rehashing Toolbox Cache...');
rehash TOOLBOXCACHE
fprintf('[Complete]\n');

end

function ToolboxUpdate(toolboxName)

%% Setup functions
ToolboxVer = str2func( sprintf('%sToolboxVer',toolboxName) );
installToolbox = str2func( sprintf('install%sToolbox',toolboxName) );

%% Check current version
try
    A = ToolboxVer;
catch ME
    A = [];
    fprintf('No previous version of %s detected.\n',toolboxName);
end

%% Setup temporary file directory
fprintf('Downloading the %s Toolbox...',toolboxName);
tmpFolder = sprintf('%sToolbox',toolboxName);
pname = fullfile(tempdir,tmpFolder);

%% Download and unzip toolbox (GitHub)
url = sprintf('https://github.com/kutzer/%sToolbox/archive/master.zip',toolboxName);
try
    fnames = unzip(url,pname);
    fprintf('SUCCESS\n');
    confirm = true;
catch
    confirm = false;
end

%% Check for successful download
if ~confirm
    error('InstallToolbox:FailedDownload','Failed to download updated version of %s Toolbox.',toolboxName);
end

%% Find base directory
install_pos = strfind(fnames, sprintf('install%sToolbox.m',toolboxName) );
sIdx = cell2mat( install_pos );
cIdx = ~cell2mat( cellfun(@isempty,install_pos,'UniformOutput',0) );

pname_star = fnames{cIdx}(1:sIdx-1);

%% Get current directory and temporarily change path
cpath = cd;
cd(pname_star);

%% Install ScorBot Toolbox
installToolbox(true);

%% Move back to current directory and remove temp file
cd(cpath);
[ok,msg] = rmdir(pname,'s');
if ~ok
    warning('Unable to remove temporary download folder. %s',msg);
end

%% Complete installation
fprintf('Installation complete.\n');

end