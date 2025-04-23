function launcher

% CHeck thrid party SHAPE Functions are on the path
% https://epos-apps.grid.cyfronet.pl/tcs-ah/sera-applications.git
checkSHAPEFunctions

shapeData = shape.ShapeData;
shape.SHAPEApp(shapeData);

end

function checkSHAPEFunctions

% Request location of installed additional software
installedLocation = SHAppE.getInstallationLocation("SHAPE toolbox");

% Add to MATLAB path
addpath( genpath(installedLocation) )

% Ientify locations of the dist_GRT function
% There are typically three, one for each version of SHAPE)
locations = string( which("dist_GRT.m","-all") );

% Locate the version 2b location
idx = contains(locations, "SHAPE_ver2b.0");

% Check functions exist and check correct version exist
if isempty(locations) || ~any(idx)

    warning("ver2b.0 SHAPE Functions could not be located on MATLAB path - Data analysis will fail")

else

    % If the only functions on the path are the version 2 ones skip
    if isscalar(idx) && idx

    else

        % Truncate once to containing folder
        functionsToUse = fileparts( locations(idx) );

        % In case multiple copies of ver2b exist
        functionsToUse = functionsToUse(1);

        % Truncate four times to get to folder that contains all versions
        root = fileparts(fileparts(fileparts(fileparts(functionsToUse))));

        % Remove root folder and subfolders from path
        rmpath( genpath( root)  )

        % Re-add only the required folder
        addpath(functionsToUse(1))

    end

end

end