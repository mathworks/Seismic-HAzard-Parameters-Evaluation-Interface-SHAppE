% ShapeData Model class file

classdef ShapeData < handle

    properties (SetAccess = private)
        SeismicDataFileName (1, 1) string
        ProductionDataFileName (1, 1) string
        SeismicData = table(double.empty( 0, 1 ), double.empty( 0, 1 ), 'VariableNames', ["Latitude", "Longitude"])
    end

    properties ( SetObservable )
        selectedDateRange (1, 2) datetime = [NaT, NaT]          % lower and upper time range
        selectedEpicentralValues (:, 2) {mustBeNumeric, mustBeFinite, mustBePositive} % latitude and longitude values for each point of the epicentral ROI
        selectedDepthRange (1, 2) {mustBeNumeric} = [NaN, NaN]  % lower and upper depth limits
        % selectedMagnitudeMeasurement (1, 1) string ...          % Selected magnitude measurement
        %     = shape.ShapeData.ValidMagnitudeMeasurements(1)
        selectedMagnitudeMinimum (1, 1) {mustBeNumeric} = NaN   % Magnitude lower limit
        WindowDates (:, 2) datetime = datetime.empty( 0, 2 )
        WindowMethodInfo struct
    end % properties

    properties ( Dependent, SetAccess = private )
        FilteredData
        NumFilteredDataPoints (1, 1) {mustBeNumeric}
        MidDate (1, 1) datetime
        TotalDepthRange (1, 2) {mustBeNumeric}
        MaxMagnitudeSeismicData (1, 1) {mustBeNumeric}
        AppliedFiltersTable table
        NumWindows (1, 1) {mustBeNumeric}
        WindowsOverlap (1, 1) logical
        AppliedProcessingParametersTable table
        HavePressureData (1, 1) logical
    end % properties ( Dependent, SetAccess = private )

    properties ( Constant )
        % ValidMagnitudeMeasurements = ["ML", "Mw"]
    end % properties ( Constant )

    % Processing properties
    properties
        Method (1, 1) string {mustBeMember(Method, ["GR", "NP"])} = "GR"
        Truncated (1, 1) logical = false

        EstimateMMax (1, 1) logical = false
        M_Max {mustBeNumeric, mustBeScalarOrEmpty}
        M_Max_estimated {mustBeNumeric, mustBeScalarOrEmpty}
        NumTrials {mustBeNumeric, mustBeScalarOrEmpty} = 100 % Only for truncated methods, Number of trials to be estimated. [] no bias to be estimated

        TargetPeriodLength (1, 1) {mustBeNumeric} = 1
        SelectedTimeUnit (1, 1) string {mustBeMember(SelectedTimeUnit, ["Day", "Month", "Year"])} = "Day"
        TargetMagnitude (1, 1) {mustBeNumeric}

        NumBootStapItr (1, 1) {mustBeNumeric} = 100

    end

    % Result properties
    properties
        ResultsTable table
        ExportFilePath string {mustBeScalarOrEmpty} = string.empty(0, 0)
    end

    events
        SeismicDataImported
        ProductionDataImported
        FilterChanged
        WindowsSet
        AnalysisComplete
        ResultsCleared
    end

    methods % Constructor

        function obj = ShapeData(seismicDataFileName, requiredSvarsIdx, productionDataFileName, requiredPvarsIdx)

            switch nargin

                % Two inputs provided
                case 4

                    % Validation
                    validateattributes(seismicDataFileName, "string", {"size", [1, 1]})
                    validateattributes(productionDataFileName, "string", {"size", [1, 1]})

                    % Import seismic data
                    obj.importSeismicData(seismicDataFileName, requiredSvarsIdx)

                    % Import production data
                    obj.importProductionData(productionDataFileName, requiredPvarsIdx)

                    % One input provided
                case 2

                    % Validation
                    validateattributes(seismicDataFileName, "string", {"size", [1, 1]})

                    % Import seismic data
                    obj.importSeismicData(seismicDataFileName, requiredSvarsIdx)

                    % No or not enough inputs required
                otherwise

            end % switch nargin

        end % function obj = ShapeData

    end

    methods % Public methods

        function importSeismicData(obj, seismicDataFileName, requiredVarsColumn)

            % requiredVarsColumn is provided by the user and is the column number
            % for each of the required variables below in the supplied file
            % ["Time", "Latitude", "Longitude", "Magnitude", "Depth"];

            arguments
                obj (1, 1) shape.ShapeData
                seismicDataFileName (1, 1) string {mustBeFile}
                requiredVarsColumn (1, 5) {mustBeNumeric, mustBePositive, mustBeInteger, mustBeFinite, mustBeNonzero}
            end

            % Import data
            obj.SeismicData = obj.importSeismicDataFile(seismicDataFileName, requiredVarsColumn);

            % Set date range
            [minSDate, MaxSDate] = bounds(obj.SeismicData.Time);
            obj.selectedDateRange = [minSDate, MaxSDate];

            % Set epicentral values
            % obj.selectedEpicentralValues = true(height(obj.SeismicData), 1);

            % Set depth range
            [ll, ul] = bounds(obj.SeismicData.Depth);
            obj.selectedDepthRange = [ll, ul];

            % Set magnitude minimum
            obj.selectedMagnitudeMinimum = ...
                min(obj.SeismicData.Magnitude);

            % Set Max magnitude default for processing
            obj.M_Max = obj.MaxMagnitudeSeismicData;
            obj.TargetMagnitude = obj.MaxMagnitudeSeismicData;

            % Set (save) file path
            [~, name, ext] = fileparts(seismicDataFileName);
            obj.SeismicDataFileName = name + ext;

            % run event
            notify(obj, "SeismicDataImported")

        end

        function importProductionData(obj, productionDataFileName, requiredVarsColumn)

            % requiredVarsColumn is provided by the user and is the column number
            % for each of the required variables below in the supplied file
            % ["Time"];

            arguments
                obj (1, 1) shape.ShapeData
                productionDataFileName (1, 1) string {mustBeFile}
                requiredVarsColumn (1, 1) {mustBeNumeric, mustBePositive, mustBeInteger, mustBeFinite, mustBeNonzero}
            end

            % Ensure seismicData exists before importing production data
            if ~isempty(obj.SeismicData)

                % Import production data
                ProductionData = obj.importProductionDataFile(productionDataFileName, requiredVarsColumn);

                % Merge both datasets

                % Combine the s and p data. Use timedata from first table (s) and
                % interpolate values in p to match using a linear method. Any values of p
                % outside the range of p are filled with NaNs
                obj.SeismicData = synchronize(obj.SeismicData, ...
                    ProductionData, ...
                    "first", "linear", "EndValues", NaN);

                % Set (save) file path
                [~, name, ext] = fileparts(productionDataFileName);
                obj.ProductionDataFileName = name + ext;

                % run event
                notify(obj, "ProductionDataImported")

            else

                error("No seismic data exists: Import seismic data before production data")

            end

        end % function importProductionData

        function Filter(obj, name, value)

            obj.(name) = value;
            notify(obj, "FilterChanged")

        end

        function setDefaultFilter(obj, name)

            switch name

                case "selectedDateRange"

                    % Set date range
                    [minSDate, MaxSDate] = bounds(obj.SeismicData.Time);
                    obj.selectedDateRange = [minSDate, MaxSDate];

                    notify(obj, "FilterChanged")

                case "selectedEpicentralValues"

                    % Set epicentral values
                    obj.selectedEpicentralValues = double.empty(0, 2);

                    notify(obj, "FilterChanged")

                case "selectedDepthRange"

                    % Set depth range
                    [ll, ul] = bounds(obj.SeismicData.Depth);
                    obj.selectedDepthRange = [ll, ul];

                    notify(obj, "FilterChanged")

                case "selectedMagnitudeMinimum"

                    % Set magnitude minimum
                    obj.selectedMagnitudeMinimum = ...
                        min(obj.SeismicData.Magnitude);

                    notify(obj, "FilterChanged")

                % case "selectedMagnitudeMeasurement"
                % 
                %     % Set magnitude minimum
                %     obj.selectedMagnitudeMeasurement = ...
                %         obj.ValidMagnitudeMeasurements(1);
                % 
                %     notify(obj, "FilterChanged")

            end % switch

        end % setDefaultFilter

        function idx = createFilterLogical(obj)

            % Time: Create logical for selected date range
            t =  obj.SeismicData.(obj.SeismicData.Properties.DimensionNames{1});
            idx = isbetween(t, ...
                obj.selectedDateRange(1), obj.selectedDateRange(2));

            % Epicentral: Create logical for selected long and lat
            if ~isempty(obj.selectedEpicentralValues)
                inROI = inpolygon(obj.SeismicData.Longitude, obj.SeismicData.Latitude, ...
                    obj.selectedEpicentralValues(:, 2), obj.selectedEpicentralValues(:, 1));
                idx = idx & inROI;
            end

            % Depth: Create logical for selected depth range
            idx = idx ...
                & obj.SeismicData.Depth >= obj.selectedDepthRange(1) ...
                & obj.SeismicData.Depth <= obj.selectedDepthRange(2);

            % Magnitude: Create logical for selected
            idx = idx ...
                & obj.SeismicData.Magnitude ...
                >= obj.selectedMagnitudeMinimum;

        end % function idx = createFilterLogical(obj)

        function setWindows(obj, windowDates, methodInfo)

            % Set chosen method
            obj.WindowMethodInfo = methodInfo;

            % Set property
            obj.WindowDates = windowDates;

        end

        function runAnalysis(obj)

            warning('off', 'all');

            % Calculate number of windows
            numWindows = obj.NumWindows;

            % Preallocation of results data
            obj.ResultsTable = table.empty(numWindows, 0);
            DistTables = cell(numWindows, 1);
            B_values = NaN(numWindows, 1);
            B_values_CI = NaN(numWindows, 2);
            Lamb_values = NaN(numWindows, 1);
            numWdwEvents = NaN(numWindows, 1);
            % wdwRange = NaT(numWindows, 2);
            EP = NaN(numWindows, 1);
            EP_CI = NaN(numWindows, 2);
            MRP = NaN(numWindows, 1);
            MRP_CI = NaN(numWindows, 2);

            % Calculate which windows are of valid size
            numEventsThresholds = [15, 7, 50, 50]; % [GR_T, GR_U, NP_T, NP_U]

            if obj.Truncated

                if obj.EstimateMMax
                    % Estimate the value

                    % Filter the seismic data based on set minimum
                    % magnitude value
                    idx = obj.SeismicData.Magnitude >= ...
                        obj.selectedMagnitudeMinimum;
                    seismicFiltered = obj.SeismicData(idx, :);
                    Ctime = datenum(seismicFiltered.Time);
                    Cmag = seismicFiltered.Magnitude;

                    switch obj.Method
                        case "GR"
                            [~,~,~,~,~,~,Mmax,~,BIAS,~] = TruncGR_O(Ctime,Cmag,0,obj.selectedMagnitudeMinimum,[],obj.NumTrials);
                            Mmax = Mmax+BIAS;
                            obj.M_Max_estimated = Mmax;
                        case "NP"
                            [~,~,~,~,~,~,~,~,~,Mmax,~,BIAS,~] = Nonpar_tr_O(Ctime,Cmag,0,obj.selectedMagnitudeMinimum,[],obj.NumTrials);
                            Mmax = Mmax+BIAS;
                            obj.M_Max_estimated = Mmax;
                    end % switch obj.Method

                else
                    Mmax = obj.M_Max;
                end % if obj.EstimateMMax

            else % is unbounded

                Mmax = obj.MaxMagnitudeSeismicData;

            end % if obj.Truncated

            % Run setup and distribution functions
            switch obj.Method

                case "GR"

                    if obj.Truncated

                        for k = 1:numWindows

                            % Extract window data
                            trIdx = timerange(obj.WindowDates(k, 1), obj.WindowDates(k, 2), "closed");
                            wdwData = obj.FilteredData(trIdx, :);
                            numWdwEvents(k) = height(wdwData);

                            % Before calculation ensure we have enough events
                            % in the window
                            if (numWdwEvents(k) > 0) && (numWdwEvents(k) >= numEventsThresholds(1))

                                % Setup
                                t = datenum(wdwData.Time);
                                M = wdwData.Magnitude;
                                iop = double( replace(obj.SelectedTimeUnit, ["Day", "Month", "Year"], ["0", "1", "2"]) );
                                Mmin = obj.selectedMagnitudeMinimum;

                                Nsynth = obj.NumTrials;
                                [b, ~, lamb, ~, ~, eps, ~, ~, ~, ~] = ...
                                    TruncGR_O_CI(t,M,iop,Mmin,Mmax,Nsynth);

                                % Distribution function
                                Md = obj.selectedMagnitudeMinimum; % starting magnitude for distribution functions calculations
                                Mu = Mmax + eps; % ending magnitude for distribution functions calculations
                                dM = eps; % magnitude step for distribution functions calculations
                                Mmin = obj.selectedMagnitudeMinimum; %   Mmin - lower bound of the distribution
                                funct = @(mags_vec) TruncGR_O_CI(t,mags_vec,iop,Mmin,Mmax,[]);
                                bCI = bootci(obj.NumBootStapItr,{funct,M},'alpha',0.05);

                                [m, PDF_GRT, CDF_GRT] = ...
                                    dist_GRT_CI(Md, Mu, dM, Mmin, eps, b, Mmax+eps, bCI);

                                % Store results
                                DistTables{k} = table(m, CDF_GRT, PDF_GRT, ...
                                    'VariableNames', ["Magnitude", "CDF", "PDF"]);
                                B_values(k) = b;
                                B_values_CI(k, :) = bCI;
                                Lamb_values(k) = lamb;

                            end % if numWdwEvents(k) >= numEventsThresholds(1)

                        end % for k = 1:numWindows

                    else % Unbounded (~Truncated)

                        for k = 1:numWindows

                            % Extract window data
                            trIdx = timerange(obj.WindowDates(k, 1), obj.WindowDates(k, 2), "closed");
                            wdwData = obj.FilteredData(trIdx, :);
                            numWdwEvents(k) = height(wdwData);

                            % Before calculation ensure we have enough events
                            % in the window
                            if (numWdwEvents(k) > 0) && (numWdwEvents(k) >= numEventsThresholds(2))

                                % Setup
                                t = datenum(wdwData.Time);
                                M = wdwData.Magnitude;
                                iop = double( replace(obj.SelectedTimeUnit, ["Day", "Month", "Year"], ["0", "1", "2"]) );
                                Mmin = obj.selectedMagnitudeMinimum;
                                [~,lamb, ~, ~, eps, b, bCI] = UnlimitGR(t, M, iop, Mmin, obj.NumBootStapItr);

                                % Distribution Function
                                [m, PDF_GRU, CDF_GRU] = dist_GRU_CI(Mmin,Mmax+eps,eps,Mmin,eps,b,bCI);

                                % Store Results
                                DistTables{k} = table(m, CDF_GRU, PDF_GRU, ...
                                    'VariableNames', ["Magnitude", "CDF", "PDF"]);
                                B_values(k) = b;
                                B_values_CI(k, :) = bCI;
                                Lamb_values(k) = lamb;

                            end % if numWdwEvents(k) >= numEventsThresholds(2)

                        end % for k = 1:numWindows

                    end % if

                case "NP"

                    if obj.Truncated

                        for k = 1:numWindows

                            % Extract window data
                            trIdx = timerange(obj.WindowDates(k, 1), obj.WindowDates(k, 2), "closed");
                            wdwData = obj.FilteredData(trIdx, :);
                            numWdwEvents(k) = height(wdwData);

                            % Before calculation ensure we have enough events
                            % in the window
                            if (numWdwEvents(k) > 0) && (numWdwEvents(k) >= numEventsThresholds(3))

                                % Setup
                                t = datenum(wdwData.Time); %#ok<*DATNM>
                                M = wdwData.Magnitude;
                                iop = double( replace(obj.SelectedTimeUnit, ["Day", "Month", "Year"], ["0", "1", "2"]) );
                                Mmin = obj.selectedMagnitudeMinimum;
                                Nsynth = obj.NumTrials;
                                [~,lamb,~,~,eps,~,h,xx,ambd,~,~,~,~] = ...
                                    Nonpar_tr_O(t, M, iop, Mmin, Mmax, Nsynth);

                                % Distribution Function
                                [m, PDF_NPT, CDF_NPT] = dist_NPT(Mmin, Mmax+eps, eps, Mmin, eps, h, xx, ambd, Mmax);                                                       %K29JAN2020 - magnitude PDF/CDF
                                data = [xx, ambd'];funct = @(data)dist_NPT_CI(Mmin, Mmax+eps, eps, Mmin, eps, h, data, Mmax);
                                [CDF_CI] = bootci(obj.NumBootStapItr, {funct,data}, 'alpha', 0.05)';

                                % Store results
                                DistTables{k} = table(m, [CDF_NPT, CDF_CI], PDF_NPT, ...
                                    'VariableNames', ["Magnitude", "CDF", "PDF"]);
                                Lamb_values(k) = lamb;

                            end % if numWdwEvents(k) >= numEventsThresholds(3)

                        end % for k = 1:numWindows

                    else % unbounded

                        for k = 1:numWindows

                            % Extract window data
                            trIdx = timerange(obj.WindowDates(k, 1), obj.WindowDates(k, 2), "closed");
                            wdwData = obj.FilteredData(trIdx, :);
                            numWdwEvents(k) = height(wdwData);

                            % Before calculation ensure we have enough events
                            % in the window
                            if (numWdwEvents(k) > 0) && (numWdwEvents(k) >= numEventsThresholds(4))

                                % Setup
                                t = datenum(wdwData.Time);
                                M = wdwData.Magnitude;
                                iop = double( replace(obj.SelectedTimeUnit, ["Day", "Month", "Year"], ["0", "1", "2"]) );
                                Mmin = obj.selectedMagnitudeMinimum;
                                % Nsynth = obj.NumTrials;
                                [~, lamb, ~, ~, eps, ~, h, xx, ambd] = Nonpar_O(t, M, iop, Mmin);

                                % Distribution Function
                                [m, PDF_NPU, CDF_NPU] = dist_NPU(Mmin,Mmax+eps,eps,Mmin,eps,h,xx,ambd);

                                data=[xx, ambd'];
                                funct = @(data)dist_NPU_CI(Mmin,Mmax+eps,eps,Mmin,eps,h,data);
                                CDF_CI = bootci(obj.NumBootStapItr,{funct,data},'alpha',0.05)';

                                % Store Results
                                DistTables{k} = table(m, [CDF_NPU, CDF_CI], PDF_NPU, ...
                                    'VariableNames', ["Magnitude", "CDF", "PDF"]);
                                Lamb_values(k) = lamb;

                            end % if numWdwEvents(k) >= numEventsThresholds(4)

                        end % for k = 1:numWindows

                    end % if

            end % switch obj.Method

            % Store results in results table
            obj.ResultsTable.WindowNumber = (1 : height( obj.WindowDates ))';
            obj.ResultsTable.TimeRange = obj.WindowDates;
            obj.ResultsTable.TimeMid = obj.ResultsTable.TimeRange(:, 1) + diff(obj.ResultsTable.TimeRange, [], 2)/2;
            obj.ResultsTable.NumEvents = numWdwEvents;
            obj.ResultsTable.EventsPerDay = obj.ResultsTable.NumEvents ./ days( diff(obj.ResultsTable.TimeRange, [], 2) );
            obj.ResultsTable.DistTables = DistTables;
            obj.ResultsTable.B_values = B_values;
            obj.ResultsTable.B_values_CI = B_values_CI;
            obj.ResultsTable.Lamb_values = Lamb_values;

            % Using distribution results calculate Exceedance probability (EP)
            % and Mean Return Period (MRP) for each window
            for k = 1:numWindows

                % If is valid window
                if ~isempty(DistTables{k})

                    [~, ind] = min( abs( DistTables{k}.Magnitude - obj.TargetMagnitude ) );
                    targetDist = DistTables{k}(ind, :);

                    % Exceedance probability
                    EP(k) = 1-exp(-Lamb_values(k) * obj.TargetPeriodLength .* (1-targetDist.CDF(1)));
                    EP_CI(k, :) = fliplr( 1-exp(-Lamb_values(k) * obj.TargetPeriodLength .* (1-targetDist.CDF(2:3))) );

                    % Mean Return Period
                    MRP(k) = 1/Lamb_values(k)./(1-targetDist.CDF(1));
                    MRP_CI(k, :) = 1/Lamb_values(k)./(1-targetDist.CDF(2:3));

                end % ~isempty(DistTables{k})

            end % for k = 1:numWindows

            % Store results in results table
            obj.ResultsTable.EP = EP;
            obj.ResultsTable.EP_CI = EP_CI;
            obj.ResultsTable.MRP = MRP;
            obj.ResultsTable.MRP_CI = MRP_CI;

            % Fire event notification
            notify(obj, "AnalysisComplete")

            warning('on', 'all');

        end % function runAnalysis(obj)

        function ExportData(obj)

            % Only generate file if a path has been specified
            if ~isempty(obj.ExportFilePath)

                % Write meta data
                metaTable = table(datetime("now"), 'VariableNames', "Analysis Date");
                writetable(metaTable, obj.ExportFilePath, "Sheet", "Meta Data")

                % Write file info
                fileTable = table(obj.SeismicDataFileName, ...
                    obj.ProductionDataFileName, ...
                    'VariableNames', ["SeismicDataFilename", "ProductionDataFilename"]);
                writetable(fileTable, obj.ExportFilePath, "Sheet", "Files")

                % Write Input (Seismic + Production) data
                writetimetable(obj.SeismicData, obj.ExportFilePath, "Sheet", "Input Data")

                % Write Filtered data
                writetimetable(obj.FilteredData, obj.ExportFilePath, "Sheet", "Filtered Data")

                % Write filters table (take a copy and modify epicentral)
                fTable = obj.AppliedFiltersTable;
                idx = fTable.("Filter Name") == "Epicentral";
                fTable.Value{idx} = join(join(string(fTable.Value{idx}), ", "), "; ");
                writetable(fTable, obj.ExportFilePath, "Sheet", "Filters")

                % Write windows data table
                windowsTable = table(obj.WindowDates(:, 1), ...
                    obj.WindowDates(:, 2), ...
                    'VariableNames', ["Start", "End"]);
                writetable(windowsTable, obj.ExportFilePath, "Sheet", "Windows")

                % Write window selection method info
                methodInfo = struct2table(obj.WindowMethodInfo);
                writetable(methodInfo, obj.ExportFilePath, "Sheet", "Window Method Info")

                % Write Processing parameters
                writetable(obj.AppliedProcessingParametersTable, obj.ExportFilePath, "Sheet", "Processing Parameters");

                % Write results table
                writetable(obj.ResultsTable, obj.ExportFilePath, "Sheet", "Results")

            end

        end

        function ClearResults(obj)

            obj.ResultsTable = table.empty(0, 0);

            obj.ExportFilePath = string.empty(0, 0);

            notify(obj, "ResultsCleared")

        end

    end % Public methods

    methods % Get methods

        function value = get.FilteredData(obj)

            if ~isempty(obj.SeismicData)

                % Create filter logical based on filter properties
                idx = createFilterLogical(obj);

                % Filter table
                value = obj.SeismicData(idx, :);

                % Magnitude Measurement: Display only chosen magnitude in
                % filtered table
                % varIdx = obj.selectedMagnitudeMeasurement ...
                %     ~= obj.ValidMagnitudeMeasurements;
                % value = removevars(value, obj.ValidMagnitudeMeasurements(varIdx));

                % Add a cumulative number of events variable to the table
                value.CumEvents = (1:height(value))';

            else

                value = obj.SeismicData;

            end

        end % value = get.FilteredData(obj)

        function value = get.TotalDepthRange(obj)

            if ~isempty(obj.SeismicData)
                [Min, Max] = bounds(obj.SeismicData.Depth);
                value = [Min, Max];
            end

        end

        function value = get.NumFilteredDataPoints(obj)

            value = height(obj.FilteredData);

        end

        function value = get.MidDate(obj)

            if ~isempty(obj.FilteredData)

                % Extract timestamp variable name
                timeStampVarName = string( obj.FilteredData.Properties.DimensionNames(1) );

                dates = obj.FilteredData.(timeStampVarName);

                value = dates(1) + (dates(end) - dates(1))/2;

            else

                value = datetime.empty(0, 1);

            end

        end % function value = get.MidDate(obj)

        function value = get.MaxMagnitudeSeismicData(obj)

            if ~isempty(obj.SeismicData)
                value = max( obj.SeismicData.Magnitude );
            else
                value = [];
            end

        end % function value = get.MaxMagnitudeFilteredData(obj)

        function value = get.AppliedFiltersTable(obj)
            % This returns a summary table of all the current filter values

            FilterNames = ["Minimum Magnitude", "Epicentral", ...
                "Min Depth", "Max Depth", ...
                "Start Time", "End Time"]';

            FilterValues = {obj.selectedMagnitudeMinimum, obj.selectedEpicentralValues, ...
                obj.selectedDepthRange(1), obj.selectedDepthRange(2), ...
                obj.selectedDateRange(1), obj.selectedDateRange(2)}';

            value = table(FilterNames, FilterValues, ...
                'variableNames', ["Filter Name", "Value"]);

        end % get.AppliedFiltersTable(obj)

        function value = get.AppliedProcessingParametersTable(obj)

            ParamNames = ["Method", "Truncated", ...
                "Extimate", "MaxMagnitude", "NumberOfTrials", ...
                "TargetPeriodLength", "TimeUnit", "TargetMagnitude", ...
                "BootStrapInterations"]';

            % Change some values based on processing parameter logicals
            if obj.Truncated
                if obj.EstimateMMax
                    mm = obj.M_Max_estimated + " (estimated)";
                    nt = obj.NumTrials;
                else
                    mm = obj.M_Max;
                    nt = NaN;
                end
                estmm = obj.EstimateMMax;
            else
                estmm = NaN;
                mm = NaN;
                nt = NaN;
            end


            ParamValues = {obj.Method, obj.Truncated, ...
                estmm, mm, nt, ...
                obj.TargetPeriodLength, obj.SelectedTimeUnit, obj.TargetMagnitude, ...
                obj.NumBootStapItr}';

            value = table(ParamNames, ParamValues, ...
                'variableNames', ["Parameter Name", "Value"]);

        end

        function value = get.NumWindows(obj)

            value = height(obj.WindowDates);

        end % get.NumWindows(obj)

        function value = get.WindowsOverlap(obj)

            d = obj.WindowDates';
            value = any( diff( d(:) ) < 0 );

        end % get.WindowsOverlap(obj)

        function value = get.HavePressureData(obj)

            value = any( obj.FilteredData.Properties.VariableNames == "Pressure" );

        end

    end % methods Get

    methods % set methods

        function set.WindowDates(obj, value)

            % Check dates for each window are sequential
            isSequential = all( diff(value, [], 2) > 0);

            % Re-order windows so they are sequential based on first window
            % date
            value = sortrows(value, 1);

            % Set property
            if isSequential
                obj.WindowDates = value;

                % Fire event
                notify(obj, "WindowsSet")
            else
                warning("Window dates not set - dates are not sequential")
            end

        end % set.WindowDates(obj, value)

        % function set.selectedMagnitudeMeasurement(obj, value)
        % 
        %     obj.selectedMagnitudeMeasurement = validatestring(value, obj.ValidMagnitudeMeasurements);
        % 
        % end % set.selectedMagnitudeMeasurement(obj, value)

        function set.selectedDateRange(obj, value)

            % Ensure dates are sequential
            value = sort(value);

            % Set property
            obj.selectedDateRange = value;

        end

        function set.selectedEpicentralValues(obj, value)

            % Check we have at least three epicentral points or it is empty
            numPoints = height(value);
            if numPoints >= 3
                obj.selectedEpicentralValues = value;
            elseif numPoints == 0
                obj.selectedEpicentralValues = value;
            else
                error("selectedEpicentralValues must be empty or height >=3")
            end

        end

    end % set methods

    methods (Static, Access = private) % Static

        function data = importSeismicDataFile(fileName, requiredVarsColumn)

            % requiredVarsColumn is provided by the user and is the column number
            % for each of the required variables below in the supplied file

            % Define the required variables
            RequiredVariables = ["Time", "Latitude", "Longitude", "Magnitude", "Depth"];

            % Import as a table
            data = readtable(fileName);

            % Remove everything except the required columns
            data = data(:, requiredVarsColumn);

            % Set column names
            data.Properties.VariableNames = RequiredVariables;

            % Convert to a timetable using the supplied column index
            data = table2timetable(data, "RowTimes", requiredVarsColumn(1));

            % Remove duplications in the data (measurements with same time)
            [~, idx] = unique(data.(RequiredVariables(1)));
            data = data(idx, :);

        end % function data = importData(fileName, fieldsFileName)

        function data = importProductionDataFile(fileName, requiredVarsColumn)

            % requiredVarsColumn is provided by the user and is the column number
            % for time (the only required variable) in the supplied file

            % Define the required variables
            RequiredVariables = "Time";

            % Import as a table
            data = readtable(fileName);

            % Set column name for the time variables
            data.Properties.VariableNames(requiredVarsColumn(1)) = RequiredVariables;

            % Convert to a timetable using the supplied column index
            data = table2timetable(data, "RowTimes", requiredVarsColumn(1));

            % Remove duplications in the data (measurements with same time)
            [~, idx] = unique(data.(RequiredVariables(1)));
            data = data(idx, :);

        end % function data = importData(fileName, fieldsFileName)

    end % methods (Static, Access = private) % Static

end % classdef