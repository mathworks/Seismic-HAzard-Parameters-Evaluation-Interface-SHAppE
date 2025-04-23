% selectWindows component class

classdef selectWindows < shape.SHAPEComponent

    properties (Access=public) % Graphics
        MainGrid matlab.ui.container.GridLayout
        TabGroup matlab.ui.container.TabGroup
        Axes matlab.graphics.axis.Axes
        TablePanel matlab.ui.container.Panel
        DisplayTable matlab.ui.control.Table
        ChartData
        Xline matlab.graphics.chart.decoration.ConstantLine
        Marker matlab.graphics.primitive.Line
        XlineClicked matlab.graphics.chart.decoration.ConstantLine
        FileDisplayLabel matlab.ui.control.EditField
        TimeTab matlab.ui.container.Tab
        TimeGrid matlab.ui.container.GridLayout
        EventsTab matlab.ui.container.Tab
        EventsGrid matlab.ui.container.GridLayout
        FileTab matlab.ui.container.Tab
        FileGrid matlab.ui.container.GridLayout
        GraphicalTab matlab.ui.container.Tab
        YAxisDataDropDown matlab.ui.control.DropDown
        YAxisDataLabel
        TimeWindowSize
        TimeStepSize
        EventsWindowSize
        EventsStepSize
        SetWindowsButton matlab.ui.control.Button
        WindowsTable matlab.ui.control.Table
    end % properties Graphics

    properties (Constant, Access=private)
        HighlightColours = lines(7)
        WindowOptions = ["Time", "Events", "File", "Graphical"]
    end

    properties (Access=private) % Listeners
        ShapeDataWindowsChanged
    end

    properties (Access=private) % Data Related
        MidDate
        WindowFileName
    end % properties Data related

    properties (Access=private) % Internal variables
        ClickCount = 0
        RegionDates = [NaT, NaT]
    end % properties Interval variables

    properties (SetAccess=private) % Table of selected dates
        SelectedDatesTable = ...
            table('Size', [0, 2], ...
            'VariableTypes', ["datetime", "datetime"], ...
            'VariableNames', ["Start", "End"]);
    end % properties Dates Table

    methods % Constructor
        function obj = selectWindows(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.selectWindows
            end

            % Call superclass constructor
            obj@shape.SHAPEComponent(shapeData)

            % Setup method is called here by matlab.ui.componentcontainer.ComponentContainer

            % Listeners
            obj.ShapeDataWindowsChanged = ...
                listener(obj.ShapeData, "WindowDates", "PostSet", @obj.onWindowsSet);

            % Run update method
            obj.update()

            % Set n-v pairs
            set(obj, namedArgs)

        end
    end % Constructor

    methods (Access = protected)

        function setup(obj)

            % Main grid
            obj.MainGrid = uigridlayout(obj, [3, 2], ...
                "RowHeight", ["fit", "1x", "fit"], ...
                "ColumnWidth", ["2x", "1x"]);

            % Description
            uilabel(obj.MainGrid, "Text", "Define windows using one of the methods below.");

            % Tab Group
            obj.TabGroup = uitabgroup(obj.MainGrid);
            obj.TabGroup.Layout.Row = 2;
            obj.TabGroup.Layout.Column = 1;

            % Time control panel
            obj.TimeTab = uitab(obj.TabGroup, "Title", "Time");
            obj.TimeGrid = uigridlayout(obj.TimeTab, ...
                "ColumnWidth", [100, 300], "RowHeight", ["fit", "fit"]);
            obj.TimeWindowSize = uispinner(obj.TimeGrid, ...
                "Limits", [1, inf], ...
                "Value", 1, "Step", 1, "ValueChangedFcn", @obj.buttonEnabler);
            uilabel(obj.TimeGrid, "Text", "Window Size (Days)");
            obj.TimeStepSize = uispinner(obj.TimeGrid, ...
                "Limits", [1, inf], ...
                "Value", 1, "Step", 1, "ValueChangedFcn", @obj.buttonEnabler);
            uilabel(obj.TimeGrid, "Text", "Step Size (Days)");

            % Events control panel
            obj.EventsTab = uitab(obj.TabGroup, "Title", "Events");
            obj.EventsGrid = uigridlayout(obj.EventsTab, ...
                "ColumnWidth", [100, 300], "RowHeight", ["fit", "fit"]);
            obj.EventsWindowSize = uispinner(obj.EventsGrid, ...
                "Limits", [1, inf], ...
                "Value", 1, "Step", 1, "ValueChangedFcn", @obj.buttonEnabler);
            uilabel(obj.EventsGrid, "Text", "Window Size (Number of Events)");
            obj.EventsStepSize = uispinner(obj.EventsGrid, ...
                "Limits", [1, inf], ...
                "Value", 1, "Step", 1, "ValueChangedFcn", @obj.buttonEnabler);
            uilabel(obj.EventsGrid, "Text", "Step Size (Number of Events)");

            % File control panel
            obj.FileTab = uitab(obj.TabGroup, "Title", "File");
            obj.FileGrid = uigridlayout(obj.FileTab, [1, 2], ...
                "ColumnWidth", [300, 80], "RowHeight", "fit");
            obj.FileDisplayLabel = uieditfield(obj.FileGrid, "Editable", "off");
            uibutton(obj.FileGrid, "Text", "Browse", ...
                "ButtonPushedFcn", @obj.onBrowseButtonPressed);

            % Graphical - Axes and Table
            obj.GraphicalTab = uitab(obj.TabGroup, "Title", "Graphical");
            mainGraphicalGrid = uigridlayout(obj.GraphicalTab, ...
                "ColumnWidth", {"1x", 250}, "RowHeight", {400, "fit"});
            obj.Axes = axes(mainGraphicalGrid);
            obj.DisplayTable = uitable(mainGraphicalGrid);

            % Graphical - Buttons
            graphicalButtonGrid = uigridlayout(mainGraphicalGrid, [1, 5], ...
                "RowHeight", "fit", "ColumnWidth", {120, 100, 100, 100, "1x"});
            graphicalButtonGrid.Layout.Column = [1, 2];
            obj.YAxisDataLabel = uilabel(graphicalButtonGrid, "Text", "Chosen Y Axis Data");
            obj.YAxisDataDropDown = uidropdown(graphicalButtonGrid, ...
                "ValueChangedFcn", @obj.onYAxisDropDownChanged, ...
                "Items", string.empty(0, 1));
            uibutton(graphicalButtonGrid, "Text", "Clear All", ...
                "ButtonPushedFcn", @obj.clearAllRegions);
            uibutton(graphicalButtonGrid, "Text", "Clear Last", ...
                "ButtonPushedFcn", @obj.clearLastRegion);

            % Create plot and then axes clicked callback
            % (Important for the callback to be set after plot)
            obj.ChartData = plot(obj.Axes, NaT, NaN, "PickableParts","none");

            % Adjust axes (after plot function for safety)
            obj.Axes.ButtonDownFcn = @obj.mouseClicked;
            obj.Axes.Toolbar.Visible = "off";

            % Graphics for moving curser
            curserColor = [0.5, 0.5, 0.5];
            obj.Xline = xline(obj.Axes, nan, "LabelOrientation", "horizontal", ...
                "PickableParts","none", ...
                "Color", curserColor, ...
                "alpha", 1);

            obj.Marker = line(obj.Axes, NaN, NaN, "LineStyle", "none", ...
                "Marker", "o", ...
                "MarkerFaceColor", curserColor, ...
                "MarkerEdgeColor", curserColor);

            % Graphics for clicking
            obj.XlineClicked = xline(obj.Axes, NaN, ...
                "PickableParts","none", ...
                "Visible","off", ...
                "Color", curserColor, ...
                "alpha", 1);

            % Set windows button
            buttonGrid = uigridlayout(obj.MainGrid, [1, 8]);
            buttonGrid.Layout.Row = 3;
            buttonGrid.Layout.Column = 1;
            obj.SetWindowsButton = uibutton(buttonGrid, ...
                "Text", "Set Windows", ...
                "ButtonPushedFcn", @obj.onSetWindowsButtonPushed, ...
                "Enable", "off");

            % Windows table
            obj.WindowsTable = uitable(obj.MainGrid);
            obj.WindowsTable.Layout.Row = [1, 3];
            obj.WindowsTable.Layout.Column = 2;

        end

        function update(obj, ~, ~)

            if ~isempty(obj.ShapeData.FilteredData)
                % If there is valid shapeData

                % Add drop down items
                obj.YAxisDataDropDown.Items = ...
                    obj.ShapeData.FilteredData.Properties.VariableNames;

                % Run drop down callback
                obj.onYAxisDropDownChanged()

                % Update table
                obj.DisplayTable.Data = obj.SelectedDatesTable;

                % Unhide tabgroup
                obj.TabGroup.Visible = "on";

                % Turn on button
                obj.SetWindowsButton.Enable = "on";
            else

                % Hide tabgroup
                obj.TabGroup.Visible = "off";

                % Disable button
                obj.SetWindowsButton.Enable = "off";

            end % if

        end % Update

    end

    methods (Access = public) % Public callbacks

        function movingCurser(obj, ~, ~)

            % Identify selected tab
            [~, isOpenName] = obj.isSelected();

            % Only run if there is SHAPE data and the graphical panel is
            % open
            if ~isempty(obj.ShapeData.SeismicData) && ...
                    ~isempty(isOpenName) && ...
                    isOpenName == "Graphical"

                % Get curser position in axes units
                xPos = num2ruler( obj.Axes.CurrentPoint(1, 1), obj.Axes.XAxis );
                yPos = num2ruler( obj.Axes.CurrentPoint(1, 2), obj.Axes.YAxis );

                % Check is curser is inside axes
                InsideAxes = xPos >= obj.Axes.XLim(1) && ...
                    xPos <= obj.Axes.XLim(2) && ...
                    yPos >= obj.Axes.YLim(1) && ...
                    yPos <= obj.Axes.YLim(2);

                if InsideAxes
                    obj.Xline.Value = xPos;
                    obj.Xline.Label = string(obj.Xline.Value);

                    % set label position
                    if xPos <= obj.ShapeData.MidDate
                        obj.Xline.LabelHorizontalAlignment = "right";
                    else
                        obj.Xline.LabelHorizontalAlignment = "left";
                    end

                    % Extract timestamp variable name
                    timeStampVarName = string( obj.ShapeData.FilteredData.Properties.DimensionNames(1) );

                    % Calculate marker y position
                    selectedVariable = obj.YAxisDataDropDown.Value;
                    YData = obj.ShapeData.FilteredData.(selectedVariable);
                    yPos = interp1(obj.ShapeData.FilteredData.(timeStampVarName), YData, xPos, "linear");

                    % Set marker position
                    set(obj.Marker, "XData", xPos, "YData", yPos)

                end

            end

        end % function movingCurser(~, ~)

    end % Private callbacks

    methods (Access = private) % Private callbacks

        function onWindowsSet(obj, ~, ~)

            obj.SetWindowsButton.Enable = "off";

            % Update table
            Table = table(obj.ShapeData.WindowDates(:, 1), obj.ShapeData.WindowDates(:, 2), ...
                'VariableNames', ["Start", "End"]);
            obj.WindowsTable.Data = Table;

        end

        function onSetWindowsButtonPushed(obj, ~, ~)

            % Identify selected tab
            [isOpenIdx, isOpenName] = obj.isSelected();

            if nnz(isOpenIdx)==1 && ~isempty(obj.ShapeData)

                switch isOpenName
                    case obj.WindowOptions(1)
                        obj.setWindowsTime()

                    case obj.WindowOptions(2)
                        obj.setWindowsEvents()

                    case obj.WindowOptions(3)
                        obj.setWindowsFile()

                    case obj.WindowOptions(4)
                        obj.setWindowsGraphical()

                end % switch

            end % if ~isempty(obj.ShapeData)

        end % function onSetWindowsButtonPushed

        function onYAxisDropDownChanged(obj, ~, ~)

            if ~isempty(obj.ShapeData.SeismicData)

                % Extract ydata from the table based on drop down
                selectedVariable = obj.YAxisDataDropDown.Value;
                YData = obj.ShapeData.FilteredData.(selectedVariable);

                % Extract timestamp variable name
                timeStampVarName = string( obj.ShapeData.FilteredData.Properties.DimensionNames(1) );

                % Set data on chart
                set(obj.ChartData, "XData", obj.ShapeData.FilteredData.(timeStampVarName), "YData", YData)

                % Set axis limits
                obj.Axes.XLim = [min(obj.ShapeData.FilteredData.(timeStampVarName)), max(obj.ShapeData.FilteredData.(timeStampVarName))];
                obj.Axes.YLim = [min(YData), max(YData)];

            end

        end

        function onBrowseButtonPressed(obj, ~, ~)

            [file, path] = uigetfile("*.xlsx");

            % Refocus figure
            focus(ancestor(obj, "figure"))

            % If a file is selected
            if file ~= 0

                obj.buttonEnabler()

                % Save full file name
                obj.WindowFileName = fullfile(path, file);

                % Display selected file name
                obj.FileDisplayLabel.Value = file;

            end % if file ~= 0

        end % function onBrowseButtonPressed(obj, ~, ~)

        function mouseClicked(obj, ~, ~)

            % Grab x position
            xClicked = num2ruler( obj.Axes.CurrentPoint(1, 1), obj.Axes.XAxis );

            % Increment clickcount
            obj.ClickCount = obj.ClickCount + 1;

            % If clickcount is odd
            if mod(obj.ClickCount, 2)
                % Create vertical line
                obj.XlineClicked.Value = xClicked;
                obj.XlineClicked.Visible = "on";

                % Save date
                obj.RegionDates(1) = xClicked;
            else

                obj.XlineClicked.Visible = "off";

                % Create region graphics
                regionNum = height(obj.SelectedDatesTable) + 1;
                colorNum = regionNum - (floor((regionNum-1)/height(obj.HighlightColours)) * height(obj.HighlightColours)); % this wraps the value around to number of colors
                highlightColour = obj.HighlightColours(colorNum, :);

                xregion(obj.Axes, obj.XlineClicked.Value, xClicked, ...
                    "PickableParts","none", ...
                    "FaceColor", highlightColour)

                % Save date
                obj.RegionDates(2) = xClicked;
                obj.RegionDates = sort(obj.RegionDates);

                % Add to table
                obj.SelectedDatesTable{end+1, :} = obj.RegionDates;

                % Clear regionDates
                obj.RegionDates = [NaT, NaT];

                % Update display table
                obj.DisplayTable.Data = obj.SelectedDatesTable;

                % Increase transparency of highlight color
                hsv = rgb2hsv( reshape(highlightColour, 1, 1, 3) );
                hsv(2) = max(hsv(2) * 0.6, 0);
                hsv(3) = min(hsv(3) * 2, 1);
                highlightColourTransparent = hsv2rgb(hsv);

                % Add style
                s = uistyle("BackgroundColor", highlightColourTransparent);
                addStyle(obj.DisplayTable, s, "Row", ...
                    height(obj.DisplayTable.Data))

            end

        end % function mouseClicked(~, ~)

        function clearAllRegions(obj, ~, ~)

            % Delete region graphics
            delete( findobj(obj.Axes.Children, "Type", "ConstantRegion") )

            % Clear saved regions
            obj.SelectedDatesTable(:, :) = [];

            % Update display table
            obj.DisplayTable.Data = obj.SelectedDatesTable;

        end

        function clearLastRegion(obj, ~, ~)

            % Delete last region graphic
            allRegions = findobj(obj.Axes.Children, "Type", "ConstantRegion");
            if ~isempty(allRegions)
                delete(allRegions(1))

                % Clear saved regions
                obj.SelectedDatesTable(end, :) = [];

                % Update display table
                obj.DisplayTable.Data = obj.SelectedDatesTable;
            end

        end % clearLastRegion(obj, ~, ~)

        function buttonEnabler(obj, ~, ~)
            set(obj.SetWindowsButton, "Enable", "on");
        end

    end

    methods (Access = private) % Private functions

        function [idx, selectedName] = isSelected(obj)
            % Function to identify selected tab

            allNames = get(obj.TabGroup.Children, "Title");
            selectedName = obj.TabGroup.SelectedTab.Title;

            idx = string(allNames) == selectedName;

        end

        function setWindowsTime(obj)

            % Set windows size and step size as durations
            windowSize = days(obj.TimeWindowSize.Value);
            stepsize = days(obj.TimeStepSize.Value);

            % Calculate the number of windows we will have based on values entered
            timestamps = obj.ShapeData.FilteredData.Time;
            TotalDuration = timestamps(end) - timestamps(1);
            dt = mod(TotalDuration-windowSize, stepsize);
            numWindows = floor( ((TotalDuration - windowSize - dt) / stepsize) + 1 );

            % Create windows in terms of dates
            windowStartDates = ...
                (timestamps(1) : stepsize : timestamps(1)+(stepsize*numWindows-1))';
            windowEndDates = windowStartDates + windowSize;
            windowDates = [windowStartDates, windowEndDates];

            % Create method info structure
            methodInfo.Method = "Time";
            methodInfo.windowSize = windowSize;
            methodInfo.stepsize = stepsize;

            % Set windows
            obj.ShapeData.setWindows(windowDates, methodInfo)

        end

        function setWindowsEvents(obj)

            % Set windows size and step size as number of events (rows in our table)
            windowSize = obj.EventsWindowSize.Value;
            stepsize = obj.EventsStepSize.Value;

            numEvents = height(obj.ShapeData.FilteredData);

            startIdx = ( 1:stepsize:numEvents )';
            endIdx = ( (1 + windowSize):stepsize:numEvents )';
            startIdx = startIdx(1:length(endIdx));
            idx = [startIdx, endIdx];

            timeStamps = obj.ShapeData.FilteredData.Time;

            % Create method info structure
            methodInfo.Method = "Events";
            methodInfo.windowSize = windowSize;
            methodInfo.stepsize = stepsize;

            % Set windows
            obj.ShapeData.setWindows(timeStamps(idx), methodInfo)

        end

        function setWindowsGraphical(obj)

            if ~isempty(obj.SelectedDatesTable)

                % Extract from the table
                windowDates = [obj.SelectedDatesTable{:, 1}, obj.SelectedDatesTable{:, 2}];

                % Create method info structure
                methodInfo.Method = "Graphical";

                % Set windows
                obj.ShapeData.setWindows(windowDates, methodInfo)

            else

                uialert(ancestor(obj, "matlab.ui.Figure"), ...
                    "Please select window dates", ...
                    "Unable to set windows", ...
                    "Icon", "warning")

            end

        end % setWindowsGraphical(obj)

        function setWindowsFile(obj)

            if ~isempty(obj.FileDisplayLabel.Value)

                try

                    % Old method for .txt file
                    % windowDates = readmatrix(obj.WindowFileName);
                    % windowDates = datetime(windowDates, "ConvertFrom", "datenum");

                    % Import dates from excel file
                    windowDates = readtable(obj.WindowFileName);
                    windowDates = windowDates{:, :};

                    % Create method info structure
                    methodInfo.Method = "File";
                    methodInfo.fileName = obj.WindowFileName;

                    % Set windows
                    obj.ShapeData.setWindows(windowDates, methodInfo)

                catch M

                    uialert(ancestor(obj, "matlab.ui.Figure"), ...
                        "Cannot read dates from specified file", ...
                        "Unable to set windows", ...
                        "Icon", "warning")

                end % try

            else

                uialert(ancestor(obj, "matlab.ui.Figure"), ...
                    "Please select a file", ...
                    "Unable to set windows", ...
                    "Icon", "warning")

            end % ~isempty(obj.FileDisplayLabel.Value)

        end % setWindowsFile(obj)

    end % methods

end % classdef