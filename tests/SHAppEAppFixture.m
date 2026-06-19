classdef SHAppEAppFixture < matlab.unittest.fixtures.Fixture
    %FIGUREFIXTURE Custom test fixture.

    % Copyright 2026 The MathWorks, Inc.

    properties ( SetAccess = protected )
        % Test figure.
        App (:, 1) shape.SHAPEApp {mustBeScalarOrEmpty}
    end % properties ( SetAccess = private )

    methods

        function fixture = SHAppEAppFixture()
            %FIGUREFIXTURE Launch SHAppE app
            % Add descriptions.
            fixture.SetupDescription = "Create a new SHAppE app.";
            fixture.TeardownDescription = "Delete the SHAppE app";

        end % constructor

        function setup( fixture )

            % Create a new figure.
            fixture.App = SHAppE_launcher;

            % Define the teardown action.
            fixture.addTeardown( @delete, fixture.App.Figure )

        end % setup

    end % methods

end % classdef