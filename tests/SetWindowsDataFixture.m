classdef SetWindowsDataFixture < SHAppEAppFixture
    %FIGUREFIXTURE Custom test fixture.

    % Copyright 2026 The MathWorks, Inc.

    methods

        function fixture = SetWindowsDataFixture()
            %FIGUREFIXTURE Launch SHAppE app
            % Add descriptions.
            fixture.SetupDescription = "";
            fixture.TeardownDescription = "";

        end % constructor

        function setup( fixture )

            % Create a new figure.
            setup@ImportDataFixture(fixture)

            % Set up windows data
            

        end % setup

    end % methods

end % classdef