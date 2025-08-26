classdef ViewResults < shape.SHAPEComponent

    properties
        DisplayTable matlab.ui.control.Table
        MainGrid matlab.ui.container.GridLayout
        TabGroup matlab.ui.container.TabGroup
        TableTab matlab.ui.container.Tab
        ChartTab matlab.ui.container.Tab
        TiledLayout matlab.graphics.layout.TiledChartLayout
        Axis1 matlab.graphics.axis.Axes
        Axis2 matlab.graphics.axis.Axes
        Axis3 matlab.graphics.axis.Axes
        ScaleDropDown
    end

    properties
        AnalysisComplete (:, 1) event.listener {mustBeScalarOrEmpty}
        ResultsCleared (:, 1) event.listener {mustBeScalarOrEmpty}
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
                "ValueChangedFcn", @obj.ChangeAxisScale);

        end % setup

        function update(obj, ~, ~)

        end % update

    end % method setup update

    methods

        function onAnalysisComplete(obj, ~, ~)

            % Check we have data
            if ~isempty(obj.ShapeData.ResultsTable)

                % Update table
                obj.DisplayTable.Data = obj.ShapeData.ResultsTable;

                % redraw chart based on if windows overlap
                if obj.ShapeData.WindowsOverlap
                    obj.CreateChart_Overlap();
                else
                    obj.CreateChart_NoOverlap();
                end % if obj.ShapeData.WindowsOverlap

            end % if ~isempty(obj.ShapeData.ResultsTable)

        end % onAnalysisComplete(obj, ~, ~)

        function onResultsCleared(obj, ~, ~)

            % Clear table
            obj.DisplayTable.Data = obj.ShapeData.ResultsTable;

            % Clear chart
            obj.ChartSetup()

        end

        function CreateChart_Overlap(obj)

            % Set up tiled layout and annotations
            obj.ChartSetup()

            % Stop plot function changing axis properties
            hold([obj.Axis1, obj.Axis2, obj.Axis3], "on")

            % Tile 1
            yyaxis(obj.Axis1, "left")
            plot(obj.Axis1, obj.ShapeData.ResultsTable.TimeMid, ...
                obj.ShapeData.ResultsTable.MRP)

            % If CI values exist add to the plot
            if any(~ismissing(obj.ShapeData.ResultsTable.MRP_CI), "all")
                plot(obj.Axis1, obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.MRP_CI(:, 1), ...
                    obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.MRP_CI(:, 2), ...
                    "LineStyle", ":", "Marker","none")
            end

            if obj.ShapeData.HavePressureData
                yyaxis(obj.Axis1, "right")
                plot(obj.Axis1, obj.ShapeData.FilteredData.Time, ...
                    obj.ShapeData.FilteredData.Pressure)
            else
                obj.Axis1.YAxis(2).Visible = "off";
            end

            % Tile 2
            yyaxis(obj.Axis2, "left")
            plot(obj.Axis2, obj.ShapeData.ResultsTable.TimeMid, ...
                obj.ShapeData.ResultsTable.EP)

            % If CI values exist add to the plot
            if any(~ismissing(obj.ShapeData.ResultsTable.EP_CI), "all")
                plot(obj.Axis2, obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.EP_CI(:, 1), ...
                    obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.EP_CI(:, 2), ...
                    "LineStyle", ":", "Marker","none")
            end

            if obj.ShapeData.HavePressureData
                yyaxis(obj.Axis2, "right")
                plot(obj.Axis2, obj.ShapeData.FilteredData.Time, ...
                    obj.ShapeData.FilteredData.Pressure)
            else
                obj.Axis2.YAxis(2).Visible = "off";
            end

            % Tile 3
            yyaxis(obj.Axis3, "left")
            plot(obj.Axis3, obj.ShapeData.ResultsTable.TimeMid, ...
                obj.ShapeData.ResultsTable.EventsPerDay)

            yyaxis(obj.Axis3, "right")
            % If B values exist add to the plot
            if any(~ismissing(obj.ShapeData.ResultsTable.B_values), "all")
                plot(obj.Axis3, obj.ShapeData.ResultsTable.TimeMid, ...
                    obj.ShapeData.ResultsTable.B_values)

                % If CI values exist add to the plot
                if any(~ismissing(obj.ShapeData.ResultsTable.B_values_CI), "all")
                    plot(obj.Axis3, obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.B_values_CI(:, 1), ...
                        obj.ShapeData.ResultsTable.TimeMid, obj.ShapeData.ResultsTable.B_values_CI(:, 2), ...
                        "LineStyle", ":", "Marker","none")
                end

            else
                % If there are no b values, turn off the axis
                obj.Axis3.YAxis(2).Visible = "off";
            end

            hold([obj.Axis1, obj.Axis2, obj.Axis3], "off")

        end % CreateChart_Overlap(obj)

        function CreateChart_NoOverlap(obj)

            % Set up tiled layout and annotations
            obj.ChartSetup()

            % Save number of windows for for loops
            numWindows = obj.ShapeData.NumWindows;

            % Stop plot function changing axis properties and allow
            % multiple lines
            hold([obj.Axis1, obj.Axis2, obj.Axis3], "on")

            % Tile 1
            yyaxis(obj.Axis1, "left")
            for k = 1:numWindows
                x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                y = repmat(obj.ShapeData.ResultsTable.MRP(k), 1, 2);
                plot(obj.Axis1, x, y, "LineStyle", "-", "Marker","none")
            end

            % If CI values exist add to the plot
            if any(~ismissing(obj.ShapeData.ResultsTable.MRP_CI), "all")
                for k = 1:numWindows
                    x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                    y_lower = repmat(obj.ShapeData.ResultsTable.MRP_CI(k, 1), 1, 2);
                    y_upper = repmat(obj.ShapeData.ResultsTable.MRP_CI(k, 2), 1, 2);
                    plot(obj.Axis1, x, y_lower, x, y_upper, ...
                        "LineStyle", ":", "Marker","none")
                end
            end

            if obj.ShapeData.HavePressureData
                yyaxis(obj.Axis1, "right")
                plot(obj.Axis1, obj.ShapeData.FilteredData.Time, ...
                    obj.ShapeData.FilteredData.Pressure)
            else
                obj.Axis1.YAxis(2).Visible = "off";
            end

            % Tile 2
            yyaxis(obj.Axis2, "left")
            for k = 1:numWindows
                x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                y = repmat(obj.ShapeData.ResultsTable.EP(k), 1, 2);
                plot(obj.Axis2, x, y, "LineStyle", "-", "Marker","none")
            end

            % If CI values exist add to the plot
            if any(~ismissing(obj.ShapeData.ResultsTable.EP_CI), "all")
                for k = 1:numWindows
                    x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                    y_lower = repmat(obj.ShapeData.ResultsTable.EP_CI(k, 1), 1, 2);
                    y_upper = repmat(obj.ShapeData.ResultsTable.EP_CI(k, 2), 1, 2);
                    plot(obj.Axis2, x, y_lower, x, y_upper, ...
                        "LineStyle", ":", "Marker","none")
                end
            end

            if obj.ShapeData.HavePressureData
                yyaxis(obj.Axis2, "right")
                plot(obj.Axis2, obj.ShapeData.FilteredData.Time, ...
                    obj.ShapeData.FilteredData.Pressure)
            else
                obj.Axis2.YAxis(2).Visible = "off";
            end

            % Tile 3
            yyaxis(obj.Axis3, "left")
            for k = 1:numWindows
                x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                y = repmat(obj.ShapeData.ResultsTable.EventsPerDay(k), 1, 2);
                plot(obj.Axis3, x, y, "LineStyle", "-", "Marker","none")
            end

            yyaxis(obj.Axis3, "right")
            % If B values exist add to the plot
            if any(~ismissing(obj.ShapeData.ResultsTable.B_values), "all")
                for k = 1:numWindows
                    x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                    y = repmat(obj.ShapeData.ResultsTable.B_values(k), 1, 2);
                    plot(obj.Axis3, x, y, "LineStyle", "-", "Marker","none")
                end

                % If CI values exist add to the plot
                if any(~ismissing(obj.ShapeData.ResultsTable.B_values_CI), "all")
                    for k = 1:numWindows
                        x = obj.ShapeData.ResultsTable.TimeRange(k, :);
                        y_lower = repmat(obj.ShapeData.ResultsTable.B_values_CI(k, 1), 1, 2);
                        y_upper = repmat(obj.ShapeData.ResultsTable.B_values_CI(k, 2), 1, 2);
                        plot(obj.Axis3, x, y_lower, x, y_upper, ...
                            "LineStyle", ":", "Marker","none")
                    end
                end
            else
                % If there are no b values, turn off the axis
                obj.Axis3.YAxis(2).Visible = "off";
            end

            % Some global setting for all axes
            xt = unique( sort( obj.ShapeData.ResultsTable.TimeRange(:) ) );
            xt.Format = "dd/MM/uu";
            xticks([obj.Axis1, obj.Axis2, obj.Axis3], xt)
            xticklabels([obj.Axis1, obj.Axis2, obj.Axis3], string(xt))

            hold([obj.Axis1, obj.Axis2, obj.Axis3], "off")

        end % function CreateChart_NoOverlap(obj)

        function ChartSetup(obj)

            % Tiledlayout
            obj.TiledLayout = tiledlayout(obj.ChartTab, 3, 1);

            % Tile 1
            obj.Axis1 = nexttile(obj.TiledLayout);
            title(obj.Axis1, "Mean Return Period for M >= " + ...
                obj.ShapeData.TargetMagnitude)

            yyaxis(obj.Axis1, "left")
            ylabel(obj.Axis1, string(obj.ShapeData.SelectedTimeUnit))

            if obj.ShapeData.HavePressureData
                yyaxis(obj.Axis1, "right")
                ylabel(obj.Axis1, "Pressure")
            end

            % Tile 2
            obj.Axis2 = nexttile(obj.TiledLayout);
            title(obj.Axis2, "Exceedance Probability for M >= " + ...
                obj.ShapeData.TargetMagnitude + " within " + ...
                obj.ShapeData.TargetPeriodLength + " " + ...
                obj.ShapeData.SelectedTimeUnit + " period")

            yyaxis(obj.Axis2, "left")
            ylabel(obj.Axis2, "Probability")

            if obj.ShapeData.HavePressureData
                yyaxis(obj.Axis2, "right")
                ylabel(obj.Axis2, "Pressure")
            end

            % Tile 3
            obj.Axis3 = nexttile(obj.TiledLayout);
            title(obj.Axis3, "Activity Rate")

            yyaxis(obj.Axis3, "left")
            ylabel(obj.Axis3, "Events/day")

            yyaxis(obj.Axis3, "right")
            ylabel(obj.Axis3, "b-value")

            % Global setting for all axes
            axis([obj.Axis1, obj.Axis2, obj.Axis3], "padded")
            grid([obj.Axis1, obj.Axis2, obj.Axis3], "on")

            % Make sure axis of tile 1 matches the dropdown
            % obj.ChangeAxisScale() % this causes an error

        end

        function ChangeAxisScale(obj, ~, ~)

            obj.Axis1.YAxis(1).Scale = obj.ScaleDropDown.Value;

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

    end % methods

end % classdef