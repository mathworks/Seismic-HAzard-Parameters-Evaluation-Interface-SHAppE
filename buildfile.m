function plan = buildfile()
%BUILDFILE SHAppE Toolbox build file.

% Copyright 2024-2025 The MathWorks, Inc.

% Define the build plan.
plan = buildplan( localfunctions() );

% Set the package task to run by default.
plan.DefaultTasks = "package";

% Add a test task to run the unit tests for the project. Generate and save
% a coverage report.
projectRoot = plan.RootFolder;
testFolder = fullfile( projectRoot, "tests" );
codeFolder = fullfile( projectRoot, "tbx", "shappe", "SHAppE_FrontEnd" );
plan("test") = matlab.buildtool.tasks.TestTask( testFolder, ...
    "Strict", true, ...
    "RunOnlyImpactedTests", true, ...
    "Description", "Assert that all tests across the project pass.", ...
    "SourceFiles", codeFolder, ...
    "TestResults", "reports/Results.html", ...
    "LoggingLevel", "Verbose", ...
    "OutputDetail", "Verbose" );
plan("test").addCodeCoverage( "reports/Coverage.html", ...
    "MetricLevel", "mcdc" );

% The test task depends on the check task.
plan("test").Dependencies = "check";

% The package task depends on the test task.
plan("package").Dependencies = "test";

end % buildfile

function checkTask( context )
% Check the source code and project for any issues.

% Set the project root as the folder in which to check for any static code
% issues.
projectRoot = context.Plan.RootFolder;
codeIssuesTask = matlab.buildtool.tasks.CodeIssuesTask( projectRoot, ...
    "IncludeSubfolders", true, ...
    "Configuration", "factory", ...
    "Description", ...
    "Assert that there are no code issues in the project.", ...
    "WarningThreshold", 11 );
codeIssuesTask.analyze( context )

% Update the project dependencies.
prj = currentProject();
prj.updateDependencies()

% Run the checks.
checkResults = table( prj.runChecks() );

% Log any failed checks.
passed = checkResults.Passed;
notPassed = ~passed;
if any( notPassed )
    disp( checkResults(notPassed, :) )
else
    fprintf( "** All project checks passed.\n\n" )
end % if

% Check that all checks have passed.
assert( all( passed ), "buildfile:ProjectIssue", ...
    "At least one project check has failed. " + ...
    "Resolve the failures shown above to continue." )

end % checkTask

function packageTask( context )
% Package the Chart Development Toolbox.

% Project root directory.
projectRoot = context.Plan.RootFolder;

% Package the .prj file into a .mlappinstall file.
% appPackagingProject = fullfile( projectRoot, "tbx", "shappe", "SHAppE_FrontEnd", "SHAppE.prj" );
% matlab.apputil.package( appPackagingProject )

% Toolbox short name.
toolboxShortName = "shappe";

% Import and tweak the toolbox metadata.
toolboxJSON = fullfile( projectRoot, toolboxShortName + ".json" );
meta = jsondecode( fileread( toolboxJSON ) );
meta.ToolboxMatlabPath = fullfile( projectRoot, meta.ToolboxMatlabPath );
meta.ToolboxFolder = fullfile( projectRoot, meta.ToolboxFolder );
meta.ToolboxImageFile = fullfile( projectRoot, meta.ToolboxImageFile );
versionString = feval( @(s) s(1).Version, ...
    ver( toolboxShortName ) ); %#ok<FVAL>
meta.ToolboxVersion = versionString;
meta.ToolboxGettingStartedGuide = fullfile( projectRoot, ...
    meta.ToolboxGettingStartedGuide );
mltbx = fullfile( projectRoot, ...
    meta.ToolboxName + " " + versionString + ".mltbx" );
meta.OutputFile = mltbx;

% Define the toolbox packaging options.
toolboxFolder = meta.ToolboxFolder;
toolboxID = meta.Identifier;
meta = rmfield( meta, ["Identifier", "ToolboxFolder"] );
opts = matlab.addons.toolbox.ToolboxOptions( ...
    toolboxFolder, toolboxID, meta );

% Package the toolbox.
matlab.addons.toolbox.packageToolbox( opts )
fprintf( 1, "[+] %s\n", opts.OutputFile )

% Add the license.
licenseText = fileread( fullfile( projectRoot, "LICENSE.txt" ) );
mlAddonSetLicense( char( opts.OutputFile ), ...
    struct( "type", 'BSD', "text", licenseText ) );

end % packageTask