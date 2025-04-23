% selectDepthRange component class

classdef selectDepthRange < shape.SHAPEComponent

    properties  (Access=private) % Graphics
        MainGrid matlab.ui.container.GridLayout
        HistAxes matlab.graphics.axis.Axes
        ScatterAxes matlab.graphics.axis.Axes
        ControlPanel matlab.ui.container.Panel
        ControlGrid matlab.ui.container.GridLayout
        BinsSpinner matlab.ui.control.Spinner
        MinDepthSpinner matlab.ui.control.Spinner
        MaxDepthSpinner matlab.ui.control.Spinner
        ApplyButton matlab.ui.control.Button
        RestoreButton matlab.ui.control.Button
    end

    properties (Access=private)
        Histogram matlab.graphics.chart.primitive.Histogram
        Scatter matlab.graphics.chart.primitive.Scatter
        MinHistLine matlab.graphics.chart.decoration.ConstantLine
        MaxHistLine matlab.graphics.chart.decoration.ConstantLine
        MinScatterLine matlab.graphics.chart.decoration.ConstantLine
        MaxScatterLine matlab.graphics.chart.decoration.ConstantLine
    end

    methods

        function obj = selectDepthRange(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.selectDepthRange
            end

            % Call superclass constructor
            obj@shape.SHAPEComponent(shapeData)

            % Setup method is called here

            % Run update method
            obj.update()

            % Set n-v pairs
            set(obj, namedArgs)

        end % obj = selectDepthRange(shapeData)

    end % Constructor

    methods (Access = protected)

        function setup(obj)

            % Create graphics
            obj.MainGrid = uigridlayout(obj, [1, 3], ...
                "ColumnWidth", {'1x', '1x', 175});

            obj.HistAxes = axes(obj.MainGrid);
            obj.ScatterAxes = axes(obj.MainGrid);

            obj.ControlPanel = uipanel(obj.MainGrid);

            obj.ControlGrid = uigridlayout(obj.ControlPanel, [5, 2], ...
                "RowHeight", {"fit", "fit", "fit", "fit", "fit", "1x"});

            % Set up spinners
            uilabel(obj.ControlGrid, "Text", "Bins", "HorizontalAlignment", "right");
            obj.BinsSpinner = uispinner(obj.ControlGrid, "Limits", [5, 30], ...
                "Step", 1, "ValueChangedFcn", @obj.onBinsSpinnerPressed, ...
                "Value", 15);

            uilabel(obj.ControlGrid, "Text", "Min Depth", "HorizontalAlignment", "right");
            obj.MinDepthSpinner = uispinner(obj.ControlGrid, ...
                "Step", 0.1, "ValueChangedFcn", @obj.onMinDepthSpinnerPressed);

            uilabel(obj.ControlGrid, "Text", "Max Depth", "HorizontalAlignment", "right");
            obj.MaxDepthSpinner = uispinner(obj.ControlGrid, ...
                "Step", 0.1, "ValueChangedFcn", @obj.onMaxDepthSpinnerPressed);

            % Buttons
            obj.ApplyButton = uibutton(obj.ControlGrid, ...
                "Text", "Apply Filter", ...
                "ButtonPushedFcn", @obj.onApplyButtonPushed);
            obj.ApplyButton.Layout.Column = 1:2;
            obj.RestoreButton = uibutton(obj.ControlGrid, ...
                "Text", "Restore Default Value", ...
                "ButtonPushedFcn", @obj.onUndoButtonPushed);
            obj.RestoreButton.Layout.Column = 1:2;

            % Initialise histogram and scatter
            obj.Histogram = histogram(obj.HistAxes, NaN);
            obj.Scatter = scatter(obj.ScatterAxes, NaN, NaN);
            obj.ScatterAxes.YDir = "reverse";
            grid(obj.ScatterAxes, "on")

            % Initialise x and y lines
            obj.MinHistLine = xline(obj.HistAxes, NaN);
            obj.MaxHistLine = xline(obj.HistAxes, NaN);
            obj.MinScatterLine = yline(obj.ScatterAxes, NaN);
            obj.MaxScatterLine = yline(obj.ScatterAxes, NaN);

        end % setup

        function update(obj, ~, ~)

            if ~isempty(obj.ShapeData.SeismicData)

                depthBounds = obj.ShapeData.selectedDepthRange;

                % set Spinners
                obj.MinDepthSpinner.Limits = obj.ShapeData.TotalDepthRange;
                obj.MaxDepthSpinner.Limits = obj.ShapeData.TotalDepthRange;
                obj.MinDepthSpinner.Value = depthBounds(1);
                obj.MaxDepthSpinner.Value = depthBounds(2);

                % set Histogram
                obj.Histogram.Data = obj.ShapeData.FilteredData.Depth;
                obj.Histogram.NumBins = obj.BinsSpinner.Value;

                % set Scatter plot
                set(obj.Scatter, "XData", 1:height(obj.ShapeData.FilteredData),...
                    "YData", obj.ShapeData.FilteredData.Depth)

                % set X and Y lines
                obj.MinHistLine.Value = depthBounds(1);
                obj.MaxHistLine.Value = depthBounds(2);
                obj.MinScatterLine.Value = depthBounds(1);
                obj.MaxScatterLine.Value = depthBounds(2);

                % Enable controls
                set([obj.BinsSpinner, ...
                    obj.MaxDepthSpinner, ...
                    obj.MinDepthSpinner, ...
                    obj.ApplyButton, ...
                    obj.RestoreButton], ...
                    "Enable", "on")

            else

                % If no seismic data exists, disable controls
                set([obj.BinsSpinner, ...
                    obj.MaxDepthSpinner, ...
                    obj.MinDepthSpinner, ...
                    obj.ApplyButton, ...
                    obj.RestoreButton], ...
                    "Enable", "off")

            end

        end % update

    end % setup and update methods

    methods % Callbacks

        function onBinsSpinnerPressed(obj, ~, ~)
            obj.Histogram.NumBins = obj.BinsSpinner.Value;
        end

        function onMinDepthSpinnerPressed(obj, ~, ~)
            obj.MinHistLine.Value = obj.MinDepthSpinner.Value;
            obj.MinScatterLine.Value = obj.MinDepthSpinner.Value;
        end

        function onMaxDepthSpinnerPressed(obj, ~, ~)
            obj.MaxHistLine.Value = obj.MaxDepthSpinner.Value;
            obj.MaxScatterLine.Value = obj.MaxDepthSpinner.Value;
        end

        function onApplyButtonPushed(obj, ~, ~)

            value = [obj.MinDepthSpinner.Value, obj.MaxDepthSpinner.Value];
            obj.ShapeData.Filter("selectedDepthRange", value)

        end % onApplyButtonPushed

        function onUndoButtonPushed(obj, ~, ~)

            obj.ShapeData.setDefaultFilter("selectedDepthRange");

        end % onUndoButtonPushed

        function movingCurser(~, ~)

            xPos = num2ruler( ax.CurrentPoint(1, 1), ax.XAxis );

            if xPos >= d(1) && xPos <= d(end)
                xl.Value = xPos;
                xl.Label = string(xl.Value);

                % set label position
                if xPos <= midDate
                    xl.LabelHorizontalAlignment = "right";
                else
                    xl.LabelHorizontalAlignment = "left";
                end

                % Calculate marker y position
                yPos = interp1(d, y, xPos, "linear");

                % Set marker position
                set(marker, "XData", xPos, "YData", yPos)

            end

        end % function movingCurser(~, ~)

    end % Methods callbacks

end % classdef