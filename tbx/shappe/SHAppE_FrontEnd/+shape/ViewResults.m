classdef ViewResults < shape.SHAPEComponent

    properties
        DisplayTable matlab.ui.control.Table
        MainGrid matlab.ui.container.GridLayout
        TabGroup matlab.ui.container.TabGroup
        TableTab matlab.ui.container.Tab
        ChartTab matlab.ui.container.Tab
        TiledLayout matlab.graphics.layout.TiledChartLayout
        Axes (3, 2) matlab.graphics.axis.Axes
        Axis3 matlab.graphics.axis.Axes
        ScaleDropDown matlab.ui.control.DropDown
    end

    properties
        AnalysisComplete (:, 1) event.listener {mustBeScalarOrEmpty}
        ResultsCleared (:, 1) event.listener {mustBeScalarOrEmpty}
    end

    properties (Constant)
        leftAxisColour = "k";
        rightAxisColour = "b";
    end

    methods

        function obj = ViewResults(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.ViewResults
            end

            % Call superclass constructor
            obj@shape.SHAPEComponent(shapeData)

            % Setup method is called here

            % Set n-v pairs
            set(obj, namedArgs)

            % Initialise listeners
            obj.AnalysisComplete = ...
                listener(obj.ShapeData, ...
                "AnalysisComplete", @obj.onAnalysisComplete);

            obj.ResultsCleared = ...
                listener(obj.ShapeData, ...
                "ResultsCleared", @obj.onResultsCleared);

        end % Constructor

    end % methods constructor

    methods (Access = protected)

        function setup(obj)

            % Main grid
            obj.MainGrid = uigridlayout(obj, [3, 1], ...
                "RowHeight", ["fit", "1x", "fit"]);

            % Description
            uilabel(obj.MainGrid, "Text", "Select Results Format");

            % Tab Group
            obj.TabGroup = uitabgroup(obj.MainGrid);

            % Chart View Tab
            obj.ChartTab = uitab(obj.TabGroup, "Title", "Chart");

            % Table View Tab
            obj.TableTab = uitab(obj.TabGroup, "Title", "Table");
            g = uigridlayout(obj.TableTab, [2, 1]);
            obj.DisplayTable = uitable(g);

            % Save and export buttons
            buttonGrid = uigridlayout(obj.MainGrid, [1, 5], "ColumnWidth", repmat("fit", 1, 5));
            uibutton(buttonGrid, "Text", "Save as .mat", ...
                "Enable", "off", "Visible", "off");
            uibutton(buttonGrid, "Text", "Export to Excel", ...
                "ButtonPushedFcn", @obj.ExportResultsTable);

            % Linear / Log dropdown menu
            obj.ScaleDropDown = uidropdown(buttonGrid, ...
                "Items", ["linear", "log"], ...
                "ValueChangedFcn", @obj.ChangeAxisScale, ...
                "Value", "log");

            % Set up tiled layout and annotations
            obj.InitialiseCharts()

        end % setup

        function update(~, ~, ~)

        end % update

    end % method setup update

    methods

        function onAnalysisComplete(obj, ~, ~)

            % Check we have data
            if ~isempty(obj.ShapeData.ResultsTable)

                % Update table
                obj.DisplayTable.Data = obj.ShapeData.ResultsTable;

                % redraw chart based on number of windows and if they overlap
                % if (obj.ShapeData.NumWindows < 50) && ~obj.ShapeData.WindowsOverlap
                %     obj.CreateChart_NoOverlap();
                % else
                %     obj.CreateChart_Overlap();
                % end
                obj.CreateChart()

            end % if ~isempty(obj.ShapeData.ResultsTable)

        end % onAnalysisComplete(obj, ~, ~)

        function onResultsCleared(obj, ~, ~)

            % Clear table
            obj.DisplayTable.Data = obj.ShapeData.ResultsTable;

            % Clear chart
            obj.InitialiseCharts()

        end

        function CreateChart(obj)

            % redraw chart based on number of windows and if they overlap
            if (obj.ShapeData.NumWindows < 50) && ~obj.ShapeData.WindowsOverlap
                chartType = "noOverlap";
            else
                chartType = "Overlap";
            end

            % Set dynamic annotations
            obj.setupCharts()

            % Save number of windows for for loops
            numWindows = obj.ShapeData.NumWindows;

            % Stop plot function changing axis properties
            hold(obj.Axes, "on")

            % Tile 1 - Left - Axes(1, 1)
            switch chartType
                case "Overlap"
                    plot(obj.Axes(1, 1), obj.ShapeData.ResultsTable.TimeMid, ...
                        obj.ShapeData.ResultsTable.MRP, ...
                        "Color", obj.leftAxisColour)

                    % If CI values exist add to the plot
                    if any(~ismissing(obj.ShapeData.ResultsTable.MRP_CI), "all")
                        plot(obj.Axes(1, 1), obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.MRP_CI(:, 1), ...
                            obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.MRP_CI(:, 2), ...
                            "LineStyle", ":", "Marker","none", "Color", obj.leftAxisColour)
                    end
                case "noOverlap"
                    for k = 1:numWindows
                        x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                        y = repmat(obj.ShapeData.ResultsTable.MRP(k), 1, 2);
                        plot(obj.Axes(1, 1), x, y, "LineStyle", "-", ...
                            "Marker","none", ...
                            "Color", obj.leftAxisColour)
                    end

                    % If CI values exist add to the plot
                    if any(~ismissing(obj.ShapeData.ResultsTable.MRP_CI), "all")
                        for k = 1:numWindows
                            x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                            y_lower = repmat(obj.ShapeData.ResultsTable.MRP_CI(k, 1), 1, 2);
                            y_upper = repmat(obj.ShapeData.ResultsTable.MRP_CI(k, 2), 1, 2);
                            plot(obj.Axes(1, 1), x, y_lower, x, y_upper, ...
                                "LineStyle", ":", "Marker","none", ...
                                "Color", obj.leftAxisColour)
                        end
                    end
            end % switch

            % Tile 1 - Right - Axes(1, 2)
            if obj.ShapeData.HavePressureData
                plot(obj.Axes(1, 2), obj.ShapeData.FilteredData.Time, ...
                    obj.ShapeData.FilteredData.Pressure, ...
                    "color", obj.rightAxisColour)
            else
                obj.Axes(1, 2).Visible = "off";
            end

            % Tile 2 - Left - Axes(2, 1)
            switch chartType
                case "Overlap"
                    plot(obj.Axes(2, 1), obj.ShapeData.ResultsTable.TimeMid, ...
                        obj.ShapeData.ResultsTable.EP, ...
                        "Color", obj.leftAxisColour)

                    % If CI values exist add to the plot
                    if any(~ismissing(obj.ShapeData.ResultsTable.EP_CI), "all")
                        plot(obj.Axes(2, 1), obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.EP_CI(:, 1), ...
                            obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.EP_CI(:, 2), ...
                            "LineStyle", ":", "Marker","none", "Color", obj.leftAxisColour)
                    end
                case "noOverlap"
                    for k = 1:numWindows
                        x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                        y = repmat(obj.ShapeData.ResultsTable.EP(k), 1, 2);
                        plot(obj.Axes(2, 1), x, y, "LineStyle", "-", "Marker","none", ...
                            "Color", obj.leftAxisColour)
                    end

                    % If CI values exist add to the plot
                    if any(~ismissing(obj.ShapeData.ResultsTable.EP_CI), "all")
                        for k = 1:numWindows
                            x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                            y_lower = repmat(obj.ShapeData.ResultsTable.EP_CI(k, 1), 1, 2);
                            y_upper = repmat(obj.ShapeData.ResultsTable.EP_CI(k, 2), 1, 2);
                            plot(obj.Axes(2, 1), x, y_lower, x, y_upper, ...
                                "LineStyle", ":", "Marker","none", ...
                                "Color", obj.leftAxisColour)
                        end
                    end
            end % switch

            % Tile 2 - Right - Axes(2, 2)
            if obj.ShapeData.HavePressureData
                plot(obj.Axes(2, 2), obj.ShapeData.FilteredData.Time, ...
                    obj.ShapeData.FilteredData.Pressure, ...
                    "color", obj.rightAxisColour)
            else
                obj.Axes(2, 2).Visible = "off";
            end

            % Tile 3

            % Check if b values exist
            bValsExist = any(~ismissing(obj.ShapeData.ResultsTable.B_values), "all");

            % If B values exist add 'B values' to Left axis - Axes(3, 1),
            % and 'events per day' to right axis - Axes(3, 2)
            if bValsExist

                switch chartType
                    case "Overlap"

                        % Add b-values to left
                        ylabel(obj.Axes(3, 1), "b-value")
                        plot(obj.Axes(3, 1), obj.ShapeData.ResultsTable.TimeMid, ...
                            obj.ShapeData.ResultsTable.B_values, ...
                            "color", obj.leftAxisColour)

                        % Also add CI values to left axis if they exist
                        if any(~ismissing(obj.ShapeData.ResultsTable.B_values_CI), "all")
                            plot(obj.Axes(3, 1), obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.B_values_CI(:, 1), ...
                                obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.B_values_CI(:, 2), ...
                                "LineStyle", ":", "Marker","none", "color", obj.leftAxisColour)
                        end

                        % Add 'events per day' to right axis - Axes(3, 2)
                        ylabel(obj.Axes(3, 2), "Events/day")
                        plot(obj.Axes(3, 2), obj.ShapeData.ResultsTable.TimeMid, ...
                            obj.ShapeData.ResultsTable.EventsPerDay, "color", obj.rightAxisColour)

                    case "noOverlap"

                        % Add b-values to left
                        ylabel(obj.Axes(3, 1), "b-value")
                        for k = 1:numWindows
                            x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                            y = repmat(obj.ShapeData.ResultsTable.B_values(k), 1, 2);
                            plot(obj.Axes(3, 1), x, y, "LineStyle", "-", "Marker","none", ...
                                "Color", obj.leftAxisColour)
                        end

                        % Also add CI values to left axis if they exist
                        if any(~ismissing(obj.ShapeData.ResultsTable.B_values_CI), "all")
                            for k = 1:numWindows
                                x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                                y_lower = repmat(obj.ShapeData.ResultsTable.B_values_CI(k, 1), 1, 2);
                                y_upper = repmat(obj.ShapeData.ResultsTable.B_values_CI(k, 2), 1, 2);
                                plot(obj.Axes(3, 1), x, y_lower, x, y_upper, ...
                                    "LineStyle", ":", "Marker","none", ...
                                    "Color", obj.leftAxisColour)
                            end
                        end

                        % Add 'events per day' to right axis - Axes(3, 2)
                        ylabel(obj.Axes(3, 2), "Events/day")
                        for k = 1:numWindows
                            x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                            y = repmat(obj.ShapeData.ResultsTable.EventsPerDay(k), 1, 2);
                            plot(obj.Axes(3, 2), x, y, "LineStyle", "-", "Marker","none", ...
                                "Color", obj.rightAxisColour)
                        end

                end % switch

            else % If B values don't exist, add 'events per day' to left axis - Axes(3, 1), and hide right axis

                switch chartType
                    case "Overlap"
                        % Plot events per day
                        ylabel(obj.Axes(3, 1), "Events/day")
                        plot(obj.Axes(3, 1), obj.ShapeData.ResultsTable.TimeMid, ...
                            obj.ShapeData.ResultsTable.EventsPerDay, "color", obj.rightAxisColour)

                    case "noOverlap"

                        % Add 'events per day' to left axis - Axes(3, 1)
                        ylabel(obj.Axes(3, 1), "Events/day")
                        for k = 1:numWindows
                            x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                            y = repmat(obj.ShapeData.ResultsTable.EventsPerDay(k), 1, 2);
                            plot(obj.Axes(3, 1), x, y, "LineStyle", "-", "Marker","none", ...
                                "color", obj.leftAxisColour)
                        end

                end % switch

                % Hide right axis
                obj.Axes(3, 2).Visible = "off";

            end % if - else b-values

            if chartType == "noOverlap"

                    % Axes settings
                    xt = unique( sort( obj.ShapeData.ResultsTable.TimeRange(:) ) );
                    xt.Format = "dd/MM/uu";
                    set(obj.Axes(:, 1), "xtick", xt)
                    xticklabels(obj.Axes(:, 1), string(xt))                    
                    set(obj.Axes(:, 1), "XTickLabelRotation", 45)

            end % if chartType == "noOverlap"

            set(obj.Axes(:, 2), "xtick", []) % This is required as xticks get turned back on when you plot with a datetime on the x
            set(obj.Axes(:, 1), "XGrid", "on")
            hold(obj.Axes, "off")

            % Set tile 1 left y axis scale to match drop down
            obj.ChangeAxisScale()

        end % createChart

        function InitialiseCharts(obj)

            % Tiledlayout
            obj.TiledLayout = tiledlayout(obj.ChartTab, 3, 1);

            % Tile 1
            obj.Axes(1, :) = obj.createDoubleAxes(obj.TiledLayout, 1);

            % Tile 2
            obj.Axes(2, :) = obj.createDoubleAxes(obj.TiledLayout, 2);

            % Tile 3
            obj.Axes(3, :) = obj.createDoubleAxes(obj.TiledLayout, 3);

        end

        function setupCharts(obj)

            % Tile 1
            title(obj.Axes(1, 1), "Mean Return Period for M >= " + ...
                obj.ShapeData.TargetMagnitude)

            ylabel(obj.Axes(1, 1), string(obj.ShapeData.SelectedTimeUnit))

            if obj.ShapeData.HavePressureData
                ylabel(obj.Axes(1, 2), "Pressure")
            end

            % Tile 2
            title(obj.Axes(2, 1), "Exceedance Probability for M >= " + ...
                obj.ShapeData.TargetMagnitude + " within " + ...
                obj.ShapeData.TargetPeriodLength + " " + ...
                obj.ShapeData.SelectedTimeUnit + " period")

            ylabel(obj.Axes(2, 1), "Probability")

            if obj.ShapeData.HavePressureData
                ylabel(obj.Axes(2, 2), "Pressure")
            end

            % Tile 3
            title(obj.Axes(3, 1), "Activity Rate")

        end

        function ChangeAxisScale(obj, ~, ~)

            obj.Axes(1, 1).YAxis.Scale = obj.ScaleDropDown.Value;

        end

        function ExportResultsTable(obj, ~, ~)

            % Ask user for fileName
            [FileName, Location] = uiputfile("SeismologyResults.xlsx");

            % Refocus figure
            focus(ancestor(obj, "figure"))

            % If user hasn't pushed cancel
            if FileName ~= 0

                % Create full path
                obj.ShapeData.ExportFilePath = fullfile(Location, FileName);

                % Export everything
                obj.ShapeData.ExportData()

            end

        end

        function Axes = createDoubleAxes(obj, tLayout, tileNum)

            % Create axes as array
            Axes = axes("Parent", tLayout);
            Axes(2) = axes("Parent", tLayout);

            % Place both axes in same tile
            Axes(1).Layout.Tile = tileNum;
            Axes(2).Layout.Tile = tileNum;

            % Set right axis properties
            set(Axes(2), ...
                "YAxisLocation", "right", ...
                "Color", "none", ...
                "Box", "off");

            % Hide duplicate x-ticks on the top axes if you don"t want them
            Axes(2).XTick = [];

            % Set right y axis colour
            Axes(2).YAxis.Color = obj.rightAxisColour;

            % Link the x-axes so panning/zooming is shared
            linkaxes(Axes, "x");

            % Create placeholder graphics for data
            % data = line(NaN, NaN, "Parent", ax(1));
            % data(2) = line(NaN, NaN, "Parent", ax(2));

        end % function [ax, data] = createDoubleAxes(tLayout, tileNum)

    end % methods (Abstract)

end % classdef