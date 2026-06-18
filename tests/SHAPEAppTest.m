classdef SHAPEAppTest < matlab.uitest.TestCase

    properties
        DataFilePath = fullfile(fileparts(cd), "tbx", "data")
        SeismicFileName = "Vietnam_Seismic_Data.xlsx"
        ProductionFileName = "Vietnam_Production_Data.xlsx"
        App (:, 1) shape.SHAPEApp {mustBeScalarOrEmpty}
        AppWithData (:, 1) shape.SHAPEApp {mustBeScalarOrEmpty}
        AppWithDataAndWindows (:, 1) shape.SHAPEApp {mustBeScalarOrEmpty}
    end

    methods(TestClassSetup)
        function checkFile(testCase)
            import matlab.unittest.constraints.IsFile
            testCase.assertThat(...
                fullfile(testCase.DataFilePath, testCase.SeismicFileName), IsFile)
            testCase.assertThat(...
                fullfile(testCase.DataFilePath, testCase.ProductionFileName), IsFile)
        end

        function applySHAppEfixtures(testCase)
            

            % % Create fixture for app with data
            % importFixture = testCase.applyFixture(ImportDataFixture);
            % testCase.AppWithData = importFixture.App;
            % 
            % % Create fixture for app with data and windows defined
            % windowsFixture = testCase.applyFixture(ImportDataFixture);
            % testCase.AppWithDataAndWindows = windowsFixture.App;
        end
    end

    methods (Test) % Importing
        function testImport(testCase)

            % Create fixture for fresh app
            fixture = testCase.applyFixture(SHAppEAppFixture);
            testCase.App = fixture.App;

            % Extract input component
            ImportComp = testCase.App.ImportTab.Children;

            % Select seismic data file
            ImportComp.updateFileNames(1, ...
                testCase.DataFilePath, testCase.SeismicFileName)

            % Set spinners
            varColIdx = [1, 2, 3, 5, 4];
            for k = 1:5
                testCase.type(ImportComp.VarColumnIdxSpinners(k), varColIdx(k))
            end

            % Select production data file
            ImportComp.updateFileNames(2, ...
                testCase.DataFilePath, testCase.ProductionFileName)

            % Press import button
            testCase.press(ImportComp.ImportButton)

            % Dismiss dialog box
            dismissDialog(testCase, "uialert", testCase.App.Figure)

            % Check data exists in the display table
            load comparisonData ImportedSeisAndProdData
            verifyEqual(testCase, ...
                ImportedSeisAndProdData, ImportComp.ImportedDisplayTable.Data, "abstol", 1e-6)
        end    
    end % methods Importing

    methods (Test) % Filtering
        function testMagnitudeFilter(testCase)
            % Create fixture for app with data
            importFixture = testCase.applyFixture(ImportDataFixture);
            testCase.AppWithData = importFixture.App;

            % Choose the filter tab
            testCase.choose(testCase.AppWithData.FilterTab)

            % Extract select magnitude component
            magComp = testCase.AppWithData.SelectMagnitudeComponent;

            % Increment minimum value
            testCase.type(magComp.MagLimitSpinner, 0.45)

            % Apply value
            testCase.press(magComp.ApplyButton)

            % Verify model is updated
            verifyEqual(testCase, ...
                testCase.AppWithData.ShapeData.selectedMagnitudeMinimum, ...
                0.45, "abstol", 1e-6)

            % Check display table is also correct
            minDisplayedMag = testCase.AppWithData.FilterOptionsTable.Data.Value{1};
            verifyEqual(testCase, minDisplayedMag, 0.45, "abstol", 1e-6)
        end

        function testDepthFilter(testCase)
            % Create fixture for app with data
            importFixture = testCase.applyFixture(ImportDataFixture);
            testCase.AppWithData = importFixture.App;

            % Choose the filter tab & depth tab
            testCase.choose(testCase.AppWithData.FilterTab)
            testCase.choose(testCase.AppWithData.DepthTab)

            % Extract select magnitude component
            depthComp = testCase.AppWithData.SelectDepthRangeComponent;

            % Change bins (small test whilst we are here)
            testCase.type(depthComp.BinsSpinner, 5);

            % Change min & max depth
            testCase.type(depthComp.MinDepthSpinner, 1.5);
            testCase.type(depthComp.MaxDepthSpinner, 4.5);

            % Apply
            testCase.press(depthComp.ApplyButton);

            % Check 
            MinMaxVals = [testCase.AppWithData.FilterOptionsTable.Data.Value{3:4}];
            verifyEqual(testCase, MinMaxVals, [1.5, 4.5], "abstol", 1e-6)
        end

        function testEpicentralFilter(testCase)

        end

        function testTimeFilter(testCase)

        end
    end % methods filtering
        
    methods (Test) % Setting Windows
        function testSettingWindows_Time(testCase)

        end

        function testSettingWindows_Events(testCase)

        end

        function testSettingWindows_File(testCase)

        end

        function testSettingWindows_Graphical(testCase)

        end
    end % methods setting windows

end % classdef