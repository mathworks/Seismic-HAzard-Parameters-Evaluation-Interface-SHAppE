classdef tShapeData < matlab.unittest.TestCase

    methods (Test)

        function tCreateBlank(testCase)
            % Setup - create a blank instance of ShapeData
            S = shape.ShapeData();

            % Query
            data = S.FilteredData;

            % Check
            verifySize(testCase, data, [0, 2])
        end

        function tCreateSeismic(testCase)
            % Setup - create a blank instance of ShapeData
            path = string( which("Vietnam_Seismic_Data.xlsx") );
            SvarIdx = [1, 2, 3, 5, 4];
            S = shape.ShapeData(path, SvarIdx);
        end

        function tCreateSeismicAndProduction(testCase)
            % Setup - create a blank instance of ShapeData
            Spath = string( which("Vietnam_Seismic_Data.xlsx") );
            Ppath = string( which("Vietnam_Production_Data.xlsx") );
            SvarIdx = [1, 2, 3, 5, 4];
            PvarIdx = 1;
            S = shape.ShapeData(Spath, SvarIdx, Ppath, PvarIdx);
        end

        function tFilterWithNonSequentialTimeRange(testCase)
            % This test checks that ShapeData can handle non-sequential
            % dates in the selectedDateRange correctly

            % Setup
            Spath = string( which("Vietnam_Seismic_Data.xlsx") );
            Ppath = string( which("Vietnam_Production_Data.xlsx") );
            SvarIdx = [1, 2, 3, 5, 4];
            PvarIdx = 1;
            S = shape.ShapeData(Spath, SvarIdx, Ppath, PvarIdx);
            S.selectedDateRange = [datetime(2017, 10, 1), datetime(2017, 1, 1)];
            
            % Query
            data = S.FilteredData;

            % Check
            verifySize(testCase, data, [220, 7])
        end

        function tFilterWithNaTTimeRange(testCase)
            % This test checks that ShapeData can handle non-sequential
            % dates in the selectedDateRange correctly

            % Setup
            Spath = string( which("Vietnam_Seismic_Data.xlsx") );
            Ppath = string( which("Vietnam_Production_Data.xlsx") );
            SvarIdx = [1, 2, 3, 5, 4];
            PvarIdx = 1;
            S = shape.ShapeData(Spath, SvarIdx, Ppath, PvarIdx);
            S.selectedDateRange = [NaT, NaT];

            % Query
            data = S.FilteredData;

            % Check filtering with NaT returns nothing
            verifyEmpty(testCase, data)
        end

        function tSelectEpicetralValues(testCase)

            % Setup
            Spath = string( which("Vietnam_Seismic_Data.xlsx") );
            Ppath = string( which("Vietnam_Production_Data.xlsx") );
            SvarIdx = [1, 2, 3, 5, 4];
            PvarIdx = 1;
            S = shape.ShapeData(Spath, SvarIdx, Ppath, PvarIdx);

            latLong = [15.4311  108.0537;
                15.3437  108.0106;
                15.1989  108.0892;
                15.3069  108.2606;
                15.4611  108.1651];

            % METHOD 1
            % Query
            S.selectedEpicentralValues = latLong;
            data = S.FilteredData;

            % Check
            verifySize(testCase, data, [6587, 7])

        end

        % function tNegativeMagnitudeValues(testCase)
        %     % Setup - create a blank instance of ShapeData
        %     Spath = string( which("Seismic_Test.xlsx") );
        %     SvarIdx = [1, 2, 3, 4, 5];
        %     S = shape.ShapeData(Spath, SvarIdx);
        % end

    end

end