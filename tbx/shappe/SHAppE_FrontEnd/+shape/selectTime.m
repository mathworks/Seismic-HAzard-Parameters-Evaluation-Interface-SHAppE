% selectTime component class

classdef selectTime < shape.SHAPEComponent

    properties (Access=private) % Graphics
        MainGrid matlab.ui.container.GridLayout
        Axes matlab.graphics.axis.Axes
        ChartData matlab.graphics.chart.primitive.Line
        Xline matlab.graphics.chart.decoration.ConstantLine
        Marker matlab.graphics.primitive.Line
        XlineClicked matlab.graphics.chart.decoration.ConstantLine
        ApplyButton matlab.ui.control.Button
        RestoreButton matlab.ui.control.Button
        SelectedRegion matlab.graphics.chart.decoration.ConstantRegion
        StartDateBound matlab.ui.control.DatePicker
        EndDateBound matlab.ui.control.DatePicker
    end % properties Graphics

    properties (Access=private)
        clickCount = 0
        SelectedDateRange = [NaT, NaT]
    end

    methods % Constructor
        function obj = selectTime(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.selectTime
            end

            % Call superclass constructor
            obj@shape.SHAPEComponent(shapeData)

            % Setup method is called here

            % Run update method
            obj.update()

            % Set n-v pairs
            set(obj, namedArgs)

        end
    end % Constructor

    methods (Access = protected)

        function setup(obj)

            % Initialise all graphics
            obj.MainGrid = uigridlayout(obj, [1, 2], ...
                "ColumnWidth", {"1x", 175});

            % Axes
            obj.Axes = axes(obj.MainGrid, ...
                "NextPlot", "add");
            ylabel(obj.Axes, "Cumulative number of events")
            grid(obj.Axes, "on")

            % Control panel and grid
            ControlPanel = uipanel(obj.MainGrid);
            ControlGrid = uigridlayout(ControlPanel, [5, 2], ...
                "RowHeight", {"fit", "fit", "fit", "fit", "1x"}, ...
                "ColumnWidth", {"fit", "1x"});

            % Date pickers
            uilabel(ControlGrid, "Text", "Start");
            obj.StartDateBound = uidatepicker(ControlGrid, ...
                "ValueChangedFcn", @obj.onDateSelected);
            uilabel(ControlGrid, "Text", "End");
            obj.EndDateBound = uidatepicker(ControlGrid, ...
                "ValueChangedFcn", @obj.onDateSelected);

            % Buttons
            obj.ApplyButton = uibutton(ControlGrid, ...
                "Text", "Apply Filter", ...
                "ButtonPushedFcn", @obj.onApplyButtonPushed);
            obj.ApplyButton.Layout.Column = 1:2;
            obj.RestoreButton = uibutton(ControlGrid, ...
                "Text", "Restore Default Value", ...
                "ButtonPushedFcn", @obj.onRestoreButtonPushed);
            obj.RestoreButton.Layout.Column = 1:2;

            % Create plot and then axes clicked callback
            % Important for the callback to be set after plot
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

            obj.SelectedRegion = xregion(obj.Axes, NaT, NaT, ...
                "PickableParts","none", ...
                "FaceColor", [0.4, 0.9, 0.1]);

        end

        function update(obj, ~, ~)
            % This runs whenever a filter is changed

            if ~isempty(obj.ShapeData.SeismicData)

                % Extract timestamp variable name
                timeStampVarName = string( obj.ShapeData.FilteredData.Properties.DimensionNames(1) );

                % Update data shown on chart
                set(obj.ChartData, "XData", obj.ShapeData.FilteredData.(timeStampVarName),...
                    "YData", obj.ShapeData.FilteredData.CumEvents)

                % Set chart title
                obj.Axes.Title.String = "Events: " + obj.ShapeData.NumFilteredDataPoints + ...
                    "/" + obj.ShapeData.NumSeismicDataPoints;

                % Enable controls
                set([obj.RestoreButton, ...
                    obj.StartDateBound, ...
                    obj.EndDateBound], "Enable", "on")

            else

                % Disable controls
                set([obj.ApplyButton, ...
                    obj.RestoreButton, ...
                    obj.StartDateBound, ...
                    obj.EndDateBound], "Enable", "off")

            end

        end

    end

    methods (Access = public) % Public callbacks

        function movingCurser(obj, ~, ~)

            % Only run if there is SHAPE data and filtered data
            if ~isempty(obj.ShapeData.SeismicData) && ~isempty(obj.ShapeData.FilteredData)

                % Get curser position in axes units
                xPos = num2ruler( obj.Axes.CurrentPoint(1, 1), obj.Axes.XAxis );
                yPos = num2ruler( obj.Axes.CurrentPoint(1, 2), obj.Axes.YAxis );

                % Check curser is inside axes
                InsideAxes = xPos >= obj.Axes.XLim(1) && ...
                    xPos <= obj.Axes.XLim(2) && ...
                    yPos >= obj.Axes.YLim(1) && ...
                    yPos <= obj.Axes.YLim(2);

                if InsideAxes

                    % Check curser is over data
                    % Extract timestamp variable name
                    timeStampVarName = string( obj.ShapeData.FilteredData.Properties.DimensionNames(1) );

                    overData = isbetween(xPos, ...
                        obj.ShapeData.FilteredData.(timeStampVarName)(1), ...
                        obj.ShapeData.FilteredData.(timeStampVarName)(end));

                    if overData

                        % Turn moving line and marker on
                        obj.Marker.Visible = "on";
                        obj.Xline.Visible = "on";

                        obj.Xline.Value = xPos;
                        obj.Xline.Label = string(obj.Xline.Value);

                        % set label position
                        if xPos <= obj.ShapeData.MidDate
                            obj.Xline.LabelHorizontalAlignment = "right";
                        else
                            obj.Xline.LabelHorizontalAlignment = "left";
                        end

                        % Calculate marker y position
                        yPos = interp1(obj.ShapeData.FilteredData.(timeStampVarName),...
                            obj.ShapeData.FilteredData.CumEvents, xPos, "linear");

                        % Set marker position
                        set(obj.Marker, "XData", xPos, "YData", yPos)

                    end

                else
                    % Turn moving line and marker off
                    obj.Marker.Visible = "off";
                    obj.Xline.Visible = "off";
                end

            end

        end % function movingCurser(~, ~)

    end % Private callbacks

    methods (Access = private)

        function mouseClicked(obj, ~, ~)

            % Grab x position
            xClicked = num2ruler( obj.Axes.CurrentPoint(1, 1), obj.Axes.XAxis );

            % Increment clickcount
            obj.clickCount = obj.clickCount + 1;

            % If it's the first click
            if obj.clickCount == 1

                % Enable vertical line
                obj.XlineClicked.Value = xClicked;
                obj.XlineClicked.Visible = "on";

                % Set date pickers
                obj.StartDateBound.Value = xClicked;
                obj.EndDateBound.Value = NaT;

                % Set daterange property
                obj.onDateSelected()

            end

            % If it's the second click
            if obj.clickCount == 2

                % Disable vertical line
                obj.XlineClicked.Visible = "off";

                % Set end date picker
                obj.EndDateBound.Value = xClicked;

                % Set daterange property
                obj.onDateSelected()

                % Reset clickcount
                obj.clickCount = 0;

            end

        end % function mouseClicked(~, ~)

        function onDateSelected(obj, ~, ~)

            % Set selected date range (after sorting)
            dateRangeSorted = sort([obj.StartDateBound.Value, obj.EndDateBound.Value]);
            obj.SelectedDateRange = dateRangeSorted;

            % If both fields are set
            if ~any(ismissing(obj.SelectedDateRange))

                % Show selected region graphically
                obj.SelectedRegion.Value = obj.SelectedDateRange;

                % Enable apply button
                obj.ApplyButton.Enable = "on";
            end

        end

        function onApplyButtonPushed(obj, ~, ~)

            value = obj.SelectedDateRange;

            % Stop any NaTs being passed to ShapeData
            if ~any(ismissing(value))
                obj.ShapeData.Filter("selectedDateRange", value)
            end

        end % onApplyButtonPushed

        function onRestoreButtonPushed(obj, ~, ~)

            % reset date range to default
            obj.ShapeData.setDefaultFilter("selectedDateRange");

            % Clear date pickers
            obj.StartDateBound.Value = NaT;
            obj.EndDateBound.Value = NaT;

            % Clear selected region (graphical)
            obj.SelectedRegion.Value = [NaT, NaT];

            % Clear selected date range
            obj.SelectedDateRange = [NaT, NaT];

            % Disable apply button
            obj.ApplyButton.Enable = "off";

        end % onUndoButtonPushed

    end % Private callbacks

end % classdef






