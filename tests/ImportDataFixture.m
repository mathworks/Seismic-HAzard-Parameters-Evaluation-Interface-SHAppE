classdef ImportDataFixture < SHAppEAppFixture
    %FIGUREFIXTURE Custom test fixture.

    % Copyright 2026 The MathWorks, Inc.

    methods

        function fixture = ImportDataFixture()
            %FIGUREFIXTURE Launch SHAppE app
            % Add descriptions.
            fixture.SetupDescription = "";
            fixture.TeardownDescription = "";

        end % constructor

        function setup( fixture )

            % Create a new figure.
            setup@SHAppEAppFixture(fixture)

            % Import data            
            s = which("Vietnam_Seismic_Data.xlsx");
            p = which("Vietnam_Production_Data.xlsx");
            fixture.App.ShapeData.importSeismicData(s, [1, 2, 3, 5, 4])
            fixture.App.ShapeData.importProductionData(p, 1)

        end % setup

    end % methods

end % classdef