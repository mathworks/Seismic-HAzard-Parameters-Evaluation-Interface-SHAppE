function SHAppE_launcher

% Check for IP and Stats toolboxes
if checkToolboxes

    % Check third party SHAPE Functions are on the path
    % https://epos-apps.grid.cyfronet.pl/tcs-ah/sera-applications.git
    checkSHAPEFunctions

    % Create instance of model and launch app
    shapeData = shape.ShapeData;
    shape.SHAPEApp(shapeData);

else

    warning("SHAppE cannot launch. Required MATLAB toolboxes (Image Processing Toolbox, Statistics and Machine Learning Toolbox) are not installed.")

end

end

function checkSHAPEFunctions

try
    % Request location of installed additional software
    installedLocation = SHAppE.getInstallationLocation("SHAPE toolbox");

    % Add this to MATLAB path
    addpath( genpath(installedLocation) )
catch
end

% Identify locations of the dist_GRT function
% There are typically three, one for each version of SHAPE)
locations = string( which("dist_GRT.m","-all") );

% Locate the version 2b location
idx = contains(locations, "SHAPE_ver2b.0");

% Check functions exist and check correct version exists
if isempty(locations) || ~any(idx)

    warning("ver2b.0 SHAPE Functions could not be located on MATLAB path - Data analysis will fail")

else

    % If the only functions on the path are the version 2b ones skip
    if isscalar(idx) && idx

    else

        % Truncate once to containing folder
        functionsToUse = fileparts( locations(idx) );

        % In case multiple copies of ver2b exist
        functionsToUse = functionsToUse(1);

        % Remove root folder and subfolders from MATLAB path
        try
            rmpath( genpath(installedLocation) )
        catch
        end

        % Re-add only the required folder
        addpath(functionsToUse)

    end % if isscalar(idx) && idx

end % if isempty(locations) || ~any(idx)

end % checkSHAPEFunctions

function  isInstalled = checkToolboxes

isInstalled = license("test", "Image_Toolbox") && ...
    license("test", "statistics_Toolbox");

end % checkToolboxes