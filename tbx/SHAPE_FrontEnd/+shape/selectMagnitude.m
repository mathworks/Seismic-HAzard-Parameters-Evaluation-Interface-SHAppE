% selectMagnitude component class

classdef selectMagnitude < shape.SHAPEComponent

    properties (Access=public) % Graphics
        MainGrid matlab.ui.container.GridLayout
        Axes matlab.graphics.axis.Axes
        Histogram matlab.graphics.chart.primitive.Histogram
        Xline matlab.graphics.chart.decoration.ConstantLine
        SelectedMagnitudeDropDown matlab.ui.control.DropDown
        MagLimitSpinner matlab.ui.control.Spinner
        ApplyButton matlab.ui.control.Button
        RestoreButton matlab.ui.control.Button
    end

    methods

        function obj = selectMagnitude(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.selectMagnitude
            end

            % Call superclass constructor
            obj@shape.SHAPEComponent(shapeData)

            % Setup method is called here

            % Run update method
            obj.update()

            % Set n-v pairs
            set(obj, namedArgs)

        end

    end % methods constructor

    methods (Access = protected)

        function setup(obj)

            % Initialise all graphics
            obj.MainGrid = uigridlayout(obj, [1, 2], ...
                "ColumnWidth", {"1x", 175});

            % Axes
            obj.Axes = axes(obj.MainGrid, ...
                "YScale", "log", ...
                "NextPlot", "add");
            ylabel(obj.Axes, "Log_{10}N")
            xlabel(obj.Axes, "Magnitude")
            grid(obj.Axes, "on")
            obj.Axes.Toolbar.Visible = "off";
            disableDefaultInteractivity(obj.Axes) % Stops panning

            % Control panel and grid
            ControlPanel = uipanel(obj.MainGrid);
            ControlGrid = uigridlayout(ControlPanel, [5, 2], ...
                "RowHeight", {"fit", "fit", "fit", "fit", "1x"});

            % Controls
            uilabel(ControlGrid, "Text", "Selected Unit", ...
                "HorizontalAlignment", "right");
            obj.SelectedMagnitudeDropDown = uidropdown(ControlGrid, ...
                "ValueChangedFcn", @obj.onSelectedMagnitudeChanged);
            uilabel(ControlGrid, "Text", "Minimum", ...
                "HorizontalAlignment", "right");
            obj.MagLimitSpinner = uispinner(ControlGrid, ...
                "ValueChangedFcn", @obj.onSpinnerChanged, ...
                "Step", 0.05);
            obj.ApplyButton = uibutton(ControlGrid, ...
                "Text", "Apply Filter", ...
                "ButtonPushedFcn", @obj.onApplyButtonPushed);
            obj.ApplyButton.Layout.Column = 1:2;
            obj.RestoreButton = uibutton(ControlGrid, ...
                "Text", "Restore Default Value", ...
                "ButtonPushedFcn", @obj.onUndoButtonPushed);
            obj.RestoreButton.Layout.Column = 1:2;

            % Histogram
            obj.Histogram = histogram(obj.Axes, NaN);

            % Xline
            obj.Xline = xline(obj.Axes, NaN, ...
                "Color", "Red", ...
                "LineWidth", 2);

        end

        function update(obj, ~, ~)

            % N.B. This method is run whenever a public property is changed

            if ~isempty(obj.ShapeData.SeismicData)

                % Set up drop down
                obj.SelectedMagnitudeDropDown.Items = obj.ShapeData.ValidMagnitudeMeasurements;
                obj.SelectedMagnitudeDropDown.ItemsData = obj.ShapeData.ValidMagnitudeMeasurements;

                % Set up data
                magnitudeData = obj.ShapeData.FilteredData.(obj.ShapeData.selectedMagnitudeMeasurement);
                obj.Histogram.Data = magnitudeData;

                if ~isempty(magnitudeData)
                    % Set up histogram edges
                    obj.Histogram.BinEdges = min(magnitudeData)-0.05:0.1:max(magnitudeData)+0.05;

                    % Set up spinner and xline
                    obj.MagLimitSpinner.Limits = [0, max(magnitudeData)]; %[min(magnitudeData), max(magnitudeData)];
                    obj.MagLimitSpinner.Value = obj.ShapeData.selectedMagnitudeMinimum; %obj.MagLimitSpinner.Limits(1) + diff(obj.MagLimitSpinner.Limits)/2;
                    obj.onSpinnerChanged()
                end

                % Enable controls
                set([obj.ApplyButton, obj.RestoreButton, obj.MagLimitSpinner],...
                    "Enable", "on")

            else

                % If no seismic data exists, disable controls
                set([obj.ApplyButton, obj.RestoreButton, obj.MagLimitSpinner],...
                    "Enable", "off")

            end

        end

    end % setup & update methods

    methods % callbacks

        function onSelectedMagnitudeChanged(obj, ~, ~)

            % Change magnitude unit filter property
            % Apply button not required for this to be applied its automatic
            magMeasurement = obj.SelectedMagnitudeDropDown.Value;
            obj.ShapeData.setDefaultFilter("selectedMagnitudeMinimum")
            obj.ShapeData.Filter("selectedMagnitudeMeasurement", magMeasurement)

        end

        function onSpinnerChanged(obj, ~, ~)

            obj.Xline.Value = obj.MagLimitSpinner.Value;

        end % onSpinnerChanged

        function onApplyButtonPushed(obj, ~, ~)

            % Grab values from controls
            magMin = obj.MagLimitSpinner.Value;

            % Set filter values
            obj.ShapeData.Filter("selectedMagnitudeMinimum", magMin)

        end % onApplyButtonPushed

        function onUndoButtonPushed(obj, ~, ~)

            obj.ShapeData.setDefaultFilter("selectedMagnitudeMinimum");

        end % onUndoButtonPushed

    end % callbacks

end % classdef