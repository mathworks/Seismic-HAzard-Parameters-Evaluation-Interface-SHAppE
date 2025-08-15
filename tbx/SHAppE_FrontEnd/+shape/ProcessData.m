% ProcessData component class

classdef ProcessData < shape.SHAPEComponent

    properties

        MainGrid matlab.ui.container.GridLayout
        MethodDropDown matlab.ui.control.DropDown
        TruncatedCheckBox matlab.ui.control.CheckBox
        EstimateMaxMagCheckBox matlab.ui.control.CheckBox
        MaxMagPanel matlab.ui.container.Panel
        MaxMagLabel matlab.ui.control.Label
        MaxMagSpinner matlab.ui.control.Spinner               
        NumTrialsLabel matlab.ui.control.Label
        NumTrialsSpinner matlab.ui.control.Spinner
        TargetPeriodLengthSpinner matlab.ui.control.Spinner
        TimeUnitDropDown matlab.ui.control.DropDown
        TargetMagnitudeSpinner matlab.ui.control.Spinner
        BootStrapItrSpinner matlab.ui.control.Spinner
        RunAnalysisButton matlab.ui.control.Button

    end

    methods

        function obj = ProcessData(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.ProcessData
            end

            % Call superclass constructor
            obj@shape.SHAPEComponent(shapeData)

            % Setup method is called here

            % Set up data
            if ~isempty(obj.ShapeData.MaxMagnitudeSeismicData)
                obj.MaxMagSpinner.Value = obj.ShapeData.MaxMagnitudeSeismicData;
                obj.MaxMagSpinner.Limits = [obj.ShapeData.MaxMagnitudeSeismicData, inf];
            end

            % Set n-v pairs
            set(obj, namedArgs)

        end

    end % methods constructor

    methods (Access = protected)

        function setup(obj)

            % Main grid
            obj.MainGrid = uigridlayout(obj, [2, 2], ...
                "ColumnWidth", {300, "1x"}, ...
                "RowHeight", {"fit", "1x"});

            % Description
            description = uilabel(obj.MainGrid, "Text", "Select data analysis options");
            description.Layout.Column = [1, 2];

            SubGrid = uigridlayout(obj.MainGrid, [5, 1], ...                
                "RowHeight", {"fit", "fit", "fit", "fit", "fit"});

            % Method
            methodPanel = uipanel(SubGrid, "Title", "Method");
            methodGrid = uigridlayout(methodPanel, [2, 2], ...
                "RowHeight", ["fit", "fit"]);
            uilabel(methodGrid, "Text", "Method");
            obj.MethodDropDown = uidropdown(methodGrid, "Items", ["GR", "NP"], ...
                "ValueChangedFcn", @obj.onMethodChanged);
            obj.TruncatedCheckBox = uicheckbox(methodGrid, "Text", "Truncated", ...
                "ValueChangedFcn", @obj.onTruncatedChanged);

            % Max Magnitude
            obj.MaxMagPanel = uipanel(SubGrid, "Title", "Max Magnitude", ...
                "Enable", "off");
            maxMagGrid = uigridlayout(obj.MaxMagPanel, [3, 2], ...
                "RowHeight", ["fit", "fit", "fit"]);
            obj.EstimateMaxMagCheckBox = uicheckbox(maxMagGrid, "Text", "Estimate", ...
                "ValueChangedFcn", @obj.onEstimateChanged);
            uilabel(maxMagGrid, "Text", ""); % Just to skip a grid space
            obj.MaxMagLabel = uilabel(maxMagGrid, "Text", "Max Magnitude");
            obj.MaxMagSpinner = uispinner(maxMagGrid, "Step", 0.1, ...
                "ValueChangedFcn", @obj.onMaxMagChanged);
            obj.NumTrialsLabel = uilabel(maxMagGrid, "Text", "Number of Trials", ...
                "Enable", "off");
            obj.NumTrialsSpinner = uispinner(maxMagGrid, "Limits", [1, inf], ...
                "RoundFractionalValues", "on", ...
                "Enable", "off", ...
                "ValueChangedFcn", @obj.onNumTrialsChanged);

            % Processing Parameters
            ppPanel = uipanel(SubGrid, "Title", "Processing Parameters");
            ppGrid = uigridlayout(ppPanel, [3, 2], ...
                "RowHeight", ["fit", "fit", "fit"]);
            uilabel(ppGrid, "Text", "Target Period Length");
            obj.TargetPeriodLengthSpinner = uispinner(ppGrid, "Limits", [1, inf], ...
                "ValueChangedFcn", @obj.onTargetPeriodLengthChanged);
            uilabel(ppGrid, "Text", "Time Unit");
            obj.TimeUnitDropDown = uidropdown(ppGrid, "Items", ["Day", "Month", "Year"], ...
                "ValueChangedFcn", @obj.onTimeUnitChanged);
            uilabel(ppGrid, "Text", "Target Magnitude");
            obj.TargetMagnitudeSpinner = uispinner(ppGrid, "Step", 0.1, ...
                "ValueChangedFcn", @obj.onTargetMagChanged);
            
            % Confidence Interval Calculation
            cicPanel = uipanel(SubGrid, "Title", "Confidence Interval Calculation");
            cicGrid = uigridlayout(cicPanel, [1, 2], ...
                "RowHeight", "fit");
            uilabel(cicGrid, "Text", "Bootstrap Iterations");
            obj.BootStrapItrSpinner = uispinner(cicGrid, "Limits", [1, inf], ...
                "RoundFractionalValues", "on", ...
                "ValueChangedFcn", @obj.onBootStrIntChanged);

            % Run Analysis
            obj.RunAnalysisButton = uibutton(SubGrid, "push",...
                "Text", "Run Analysis", ...
                "Enable", "off", ...
                "ButtonPushedFcn", @obj.onRunAnalysisButtonPushed);

        end % function setup(obj)

        function update(obj, ~, ~)

            % This method is run whenever a public property is changed

            if ~isempty(obj.ShapeData.SeismicData)
                
                % Set control defaults when you initially load data
                obj.MethodDropDown.Value = obj.ShapeData.Method;
                obj.TruncatedCheckBox.Value = obj.ShapeData.Truncated;
                obj.EstimateMaxMagCheckBox.Value = obj.ShapeData.EstimateMMax;
                obj.MaxMagSpinner.Value = obj.ShapeData.M_Max;
                obj.NumTrialsSpinner.Value = obj.ShapeData.NumTrials;
                obj.TargetPeriodLengthSpinner.Value = obj.ShapeData.TargetPeriodLength;
                obj.TimeUnitDropDown.Value = obj.ShapeData.SelectedTimeUnit;
                obj.TargetMagnitudeSpinner.Value = obj.ShapeData.TargetMagnitude;
                obj.BootStrapItrSpinner.Value = obj.ShapeData.NumBootStapItr;

                % Turn on run analysis button
                obj.RunAnalysisButton.Enable = "on";

            else

                % Turn off run analysis button
                obj.RunAnalysisButton.Enable = "off";

            end

        end

    end % method setup update

    methods % Callbacks

        function onMethodChanged(obj ,~, ~)
            obj.ShapeData.Method = obj.MethodDropDown.Value;
        end

        function onTruncatedChanged(obj, ~, ~)

            obj.ShapeData.Truncated = obj.TruncatedCheckBox.Value;

            checked = obj.TruncatedCheckBox.Value;

            if checked
                obj.MaxMagPanel.Enable = "on";
            else
                obj.MaxMagPanel.Enable = "off";
            end

        end % function onTruncatedChanged(obj, ~, ~)

        function onEstimateChanged(obj, ~, ~)

            obj.ShapeData.EstimateMMax = obj.EstimateMaxMagCheckBox.Value;

            checked = obj.EstimateMaxMagCheckBox.Value;

            if checked
                obj.MaxMagSpinner.Enable = "off";
                obj.MaxMagLabel.Enable = "off";
                obj.NumTrialsSpinner.Enable = "on";
                obj.NumTrialsLabel.Enable = "on";
            else
                obj.MaxMagSpinner.Enable = "on";
                obj.MaxMagLabel.Enable = "on";
                obj.NumTrialsSpinner.Enable = "off";
                obj.NumTrialsLabel.Enable = "off";
            end

        end

        function onMaxMagChanged(obj, ~, ~)
            obj.ShapeData.M_Max = obj.MaxMagSpinner.Value;
        end

        function onNumTrialsChanged(obj, ~, ~)
            obj.ShapeData.NumTrials = obj.NumTrialsSpinner.Value;
        end

        function onTargetPeriodLengthChanged(obj, ~, ~)
            obj.ShapeData.TargetPeriodLength = obj.TargetPeriodLengthSpinner.Value;
        end

        function onTimeUnitChanged(obj, ~, ~)
            obj.ShapeData.SelectedTimeUnit = obj.TimeUnitDropDown.Value;
        end

        function onTargetMagChanged(obj, ~, ~)
            obj.ShapeData.TargetMagnitude = obj.TargetMagnitudeSpinner.Value;
        end

        function onBootStrIntChanged(obj, ~, ~)
            obj.ShapeData.NumBootStapItr = obj.BootStrapItrSpinner.Value;
        end

        function onRunAnalysisButtonPushed(obj, ~, ~)

            d = uiprogressdlg(obj.Parent.Parent.Parent, ...
                "Message", "Processing", ...
                "Indeterminate", "on");
            try
                obj.ShapeData.runAnalysis();
            catch M
                uialert(obj.Parent.Parent.Parent, ...
                    M.message, "Analysis Failed")                
            end

            close(d)

        end

    end % methods % Callbacks

end % classdef