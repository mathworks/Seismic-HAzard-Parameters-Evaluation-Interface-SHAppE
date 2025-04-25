classdef SHAPEApp < handle

    properties (GetAccess = protected)
        ShapeData (:, 1) shape.ShapeData {mustBeScalarOrEmpty}
    end

    % Structure
    properties (Access = protected)
        Figure matlab.ui.Figure
        MainTabGroup matlab.ui.container.TabGroup
        ImportTab matlab.ui.container.Tab
        FilterTab matlab.ui.container.Tab
        WindowSelectionTab matlab.ui.container.Tab
        ProcessingTab matlab.ui.container.Tab
        ViewResultsTab matlab.ui.container.Tab
        FilterTabGrid matlab.ui.container.GridLayout
        FilterTabGroup  matlab.ui.container.TabGroup
        FilterOptionsTable matlab.ui.control.Table
        MagnitudeTab matlab.ui.container.Tab
        EpicentralTab matlab.ui.container.Tab
        DepthTab matlab.ui.container.Tab
        TimeCropTab matlab.ui.container.Tab
    end

    % Components
    properties (Access = protected)
        ImportDataComponent shape.ImportSHAPE
        SelectMagnitudeComponent shape.selectMagnitude
        SelectEpicentalComponent shape.selectEpicentral
        SelectDepthRangeComponent shape.selectDepthRange
        SelectTimeComponent shape.selectTime
        SelectDateRegionsComponent shape.selectWindows
        ProcessComponent shape.ProcessData
        ResultsComponent shape.ViewResults
    end

    % Listeners
    properties (Access = protected)
        SeismicDataImported (:, 1) event.listener {mustBeScalarOrEmpty}
        FiltersChanged (:, 1) event.listener {mustBeScalarOrEmpty}
        WindowsSet (:, 1) event.listener {mustBeScalarOrEmpty}
        AnalysisComplete (:, 1) event.listener {mustBeScalarOrEmpty}
    end

    methods % Constructor

        function obj = SHAPEApp(shapeData)

            arguments
                shapeData (1, 1) shape.ShapeData
            end

            obj.ShapeData = shapeData;

            % Build structure
            obj.Figure = uifigure("Units", "normalized", ...
                "Position", [0.2, 0.2, 0.6, 0.6], ...
                "AutoResizeChildren", "off", ...
                "WindowButtonMotionFcn", @obj.MouseHoverCallback, ...
                "Name", "SHAppE");

            obj.MainTabGroup = uitabgroup(obj.Figure, "Units","normalized", ...
                "Position", [0, 0, 1, 1], ...
                "SelectionChangedFcn", @obj.onMainTabChanged);
            obj.ImportTab = uitab(obj.MainTabGroup,"Title","Import", ...
                "UserData", "On");
            obj.FilterTab = uitab(obj.MainTabGroup,"Title","Filter", ...
                "UserData", "Off", "ForegroundColor", [0.8, 0.8, 0.8]);
            obj.WindowSelectionTab = uitab(obj.MainTabGroup,"Title","Window Selection", ...
                "UserData", "Off", "ForegroundColor", [0.8, 0.8, 0.8]);
            obj.ProcessingTab = uitab(obj.MainTabGroup,"Title","Process Data", ...
                "UserData", "Off", "ForegroundColor", [0.8, 0.8, 0.8]);
            obj.ViewResultsTab = uitab(obj.MainTabGroup,"Title","View Results", ...
                "UserData", "Off", "ForegroundColor", [0.8, 0.8, 0.8]);

            % Filtering tab
            obj.FilterTabGrid = uigridlayout(obj.FilterTab, [2, 2], ...
                "ColumnWidth", {"1x", 300}, ...
                "RowHeight", {"fit", "1x"});

            % Description
            uilabel(obj.FilterTabGrid, "Text", "Filter Data using options below");

            % Filtering tabs
            obj.FilterTabGroup = uitabgroup(obj.FilterTabGrid, ...
                "Units","normalized");
            obj.FilterTabGroup.Layout.Row = 2;
            obj.FilterTabGroup.Layout.Column = 1;
            drawnow % This is here to make sure uitabgroup is created correctly
                    % so that when it is populated later we can see the graphics

            % Filter options table
            obj.FilterOptionsTable = uitable(obj.FilterTabGrid, ...
                "Data", obj.ShapeData.AppliedFiltersTable);
            obj.FilterOptionsTable.Layout.Row = [1, 2];
            obj.FilterOptionsTable.Layout.Column = 2;
                % "Data", table(1, 1, 'VariableNames', ["Filter Name", "Value"]));
            
            obj.MagnitudeTab = uitab(obj.FilterTabGroup,"Title","Magnitude");
            obj.EpicentralTab = uitab(obj.FilterTabGroup,"Title","Epicentral");
            obj.DepthTab = uitab(obj.FilterTabGroup,"Title","Depth");
            obj.TimeCropTab = uitab(obj.FilterTabGroup,"Title","Time");


            % Create each component

            % Importing
            obj.ImportDataComponent = shape.ImportSHAPE(shapeData, "Parent", obj.ImportTab);

            % Filtering
            obj.SelectMagnitudeComponent = shape.selectMagnitude(shapeData, "Parent", obj.MagnitudeTab);            
            obj.SelectEpicentalComponent = shape.selectEpicentral(shapeData, "Parent", obj.EpicentralTab);
            obj.SelectDepthRangeComponent = shape.selectDepthRange(shapeData, "Parent", obj.DepthTab);
            obj.SelectTimeComponent = shape.selectTime(shapeData, "Parent", obj.TimeCropTab);

            % Date selection
            obj.SelectDateRegionsComponent = shape.selectWindows(shapeData, "Parent", obj.WindowSelectionTab);

            % Processing
            obj.ProcessComponent = shape.ProcessData(shapeData, "Parent", obj.ProcessingTab);

            % Results
            obj.ResultsComponent = shape.ViewResults(shapeData, "Parent", obj.ViewResultsTab);

            % Initialise listeners
            obj.SeismicDataImported = ...
                listener(obj.ShapeData, "SeismicDataImported", @obj.onSeismicDataImported);
            obj.FiltersChanged = ...
                listener(obj.ShapeData, "FilterChanged", @obj.onFiltersChanged);
            obj.WindowsSet = ...
                listener(obj.ShapeData, "WindowsSet", @obj.onWindowsSet);
            obj.AnalysisComplete = ...
                listener(obj.ShapeData, "AnalysisComplete", @obj.onAnalysisComplete);

        end % Constructor method

    end % methods constructor

    methods % callbacks

        function onSeismicDataImported(obj, ~, ~)

            obj.onFiltersChanged();

            % "Turn on" filter and set windows tabs
            obj.FilterTab.UserData = "On";
            obj.FilterTab.ForegroundColor = "k";
            obj.WindowSelectionTab.UserData = "On"; % Having to do it like this as tabs dont have a visible or enabled property - see ontabchanged callback
            obj.WindowSelectionTab.ForegroundColor = "k";

            % Move to results tab
            obj.MainTabGroup.SelectedTab = obj.FilterTab;

        end % onSeismicDataImported

        function onFiltersChanged(obj, ~, ~)
            % Update filters table
            obj.FilterOptionsTable.Data = obj.ShapeData.AppliedFiltersTable;
            
        end % onFiltersChanged

        function onWindowsSet(obj, ~, ~)
            % "Turn on" processing tab
            obj.ProcessingTab.UserData = "On";
            obj.ProcessingTab.ForegroundColor = "k";

        end % onWindowsSet

        function onAnalysisComplete(obj, ~, ~)

            % "Turn on" results tab
            obj.ViewResultsTab.UserData = "On";
            obj.ViewResultsTab.ForegroundColor = "k";

            % Move to results tab
            obj.MainTabGroup.SelectedTab = obj.ViewResultsTab;

        end % onAnalysisComplete      

        function onMainTabChanged(obj, ~, e)
            
            % Check is selected tab is "On" (Enabled)
            if e.NewValue.UserData ~= "On"
                % Go back to previous tab
                obj.MainTabGroup.SelectedTab = e.OldValue;
            end

            % Wipe results if going from results tab backwards
            if e.OldValue == obj.ViewResultsTab

                % Set current tab back to results (for athetics)
                obj.MainTabGroup.SelectedTab = obj.ViewResultsTab;

                % Ask user if they want to proceed to their selection and
                % clear results
                selection = uiconfirm(obj.Figure, ...
                    "This action will clear results data. Do you want to proceed?",...
                    "Warning", "Icon", "warning");

                if selection == "OK"

                        % Clear results data in model (this triggers a
                        % results tab listener)
                        obj.ShapeData.ClearResults()

                        % 'Disable' results tab
                        set(obj.ViewResultsTab, ...
                            "UserData", "Off", ...
                            "ForegroundColor", [0.8, 0.8, 0.8])

                        % Switch to selected tab
                        obj.MainTabGroup.SelectedTab = e.NewValue;

                end % if selection == "OK"

            end % if e.OldValue == obj.ViewResultsTab

            % Check we have filtered data if moving from filter tab
            if e.OldValue == obj.FilterTab && e.NewValue ~= obj.ImportTab
                if isempty(obj.ShapeData.FilteredData)
                    uialert(obj.Figure, ...
                        "No data after filtering", ...
                        "Data Error", ...
                        "Icon", "error")

                    % Switch to filtered tab
                    obj.MainTabGroup.SelectedTab = obj.FilterTab;
                end
            end

        end % onMainTabChanged

        function MouseHoverCallback(obj, ~, ~)

            if (obj.MainTabGroup.SelectedTab.Title == "Window Selection")
                obj.SelectDateRegionsComponent.movingCurser()
            elseif  ((obj.MainTabGroup.SelectedTab.Title == "Filter") && ...
                    (obj.FilterTabGroup.SelectedTab.Title == "Time"))
                obj.SelectTimeComponent.movingCurser;
            end

        end

    end % callback methods

end % classdef