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
            % Create fixture for app with data
            importFixture = testCase.applyFixture(ImportDataFixture);
            testCase.AppWithData = importFixture.App;

            % Choose the filter tab & depth tab
            testCase.choose(testCase.AppWithData.FilterTab)
            testCase.choose(testCase.AppWithData.EpicentralTab)

            % Extract select magnitude component
            epiComp = testCase.AppWithData.SelectEpicentalComponent;

            % Set roi points using method included for testing as cannot
            % test interactively
            roiPoints = [15.3951 108.0655
                15.3073	108.0672
                15.3016	108.1814
                15.3883	108.1838];
            epiComp.DrawPolyForTest(roiPoints)

            % Apply
            testCase.press(epiComp.ApplyButton)

            % Check
            roiP = [testCase.AppWithData.FilterOptionsTable.Data.Value{2}];
            verifyEqual(testCase, roiP, roiPoints, "abstol", 1e-6)
        end

        function testTimeFilter(testCase)
            % Create fixture for app with data
            importFixture = testCase.applyFixture(ImportDataFixture);
            testCase.AppWithData = importFixture.App;

            % Choose the filter tab & depth tab
            testCase.choose(testCase.AppWithData.FilterTab)
            testCase.choose(testCase.AppWithData.TimeCropTab)

            % Extract select magnitude component
            timeComp = testCase.AppWithData.SelectTimeComponent;

            % Select time range interactively
            timeRange = [datetime(2014, 1, 1), datetime(2016, 1, 1)];
            timeRangeNum = ruler2num(timeRange, timeComp.Axes.XAxis);
            testCase.hover(timeComp.Axes, [timeRangeNum(1), 3000])
            testCase.press(timeComp.Axes, [timeRangeNum(1), 3000])
            testCase.hover(timeComp.Axes, [timeRangeNum(2), 3000])
            testCase.press(timeComp.Axes, [timeRangeNum(2), 3000])

            % Apply
            testCase.press(timeComp.ApplyButton)

            % Check
            timeRng = [testCase.AppWithData.FilterOptionsTable.Data.Value{5:6}];
            testCase.verifyLessThanOrEqual( ...
                abs(timeRng - timeRange), days(3)); % I believe some error is introduced when using ruler2num hence this option
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