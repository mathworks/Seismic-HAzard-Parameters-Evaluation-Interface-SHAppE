% ImportSHAPE component class
% Branch test

classdef ImportSHAPE < shape.SHAPEComponent

    properties (Access = private)
        MainGrid matlab.ui.container.GridLayout
        ControlsPanel matlab.ui.container.Panel
        ControlsGrid matlab.ui.container.GridLayout

        FileNameDisplays (1, 4) matlab.ui.control.EditField
        BrowseButtons (1, 4) matlab.ui.control.Button
        ImportButton (1, 1) matlab.ui.control.Button
        ClearButton (1, 1) matlab.ui.control.Button
    end

    properties
        FileNames (2, 1) string
    end

    methods

        function obj = ImportSHAPE(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.ImportSHAPE
            end

            % Call superclass constructor
            obj@shape.SHAPEComponent(shapeData)

            % Setup method is called here

            % Set n-v pairs
            set(obj, namedArgs)

        end

    end % methods constructor

    methods (Access = protected)

        function setup(obj)

            % Main grid
            obj.MainGrid = uigridlayout(obj, [3, 1], ...
                "RowHeight", {"fit", "fit", "1x"});

            % Description
            uilabel(obj.MainGrid, "Text", "Select files to import");

            obj.ControlsPanel = uipanel(obj.MainGrid);
            obj.ControlsPanel.Layout.Row = 2;

            obj.ControlsGrid = uigridlayout(obj.ControlsPanel, [7, 3], ...
                "RowHeight", {"fit", "fit", "fit", "fit", "fit", "fit", "1x"}, ...
                "ColumnWidth", {"fit", "fit", "fit"});

            % File selector buttons
            labelText = ["Seismic data file name", ...
                "Production data file name (Optional)"];

            for k = 1:2

                % Create label
                uilabel(obj.ControlsGrid, "Text", labelText(k));

                % Create edit box
                obj.FileNameDisplays(k) = ...
                    uieditfield(obj.ControlsGrid, ...
                    "Editable", "off");

                % Create button
                obj.BrowseButtons(k) = ...
                    uibutton(obj.ControlsGrid, ...
                    "ButtonPushedFcn", @obj.onBrowseButtonPressed, ...
                    "UserData", k, ...
                    "Text", "Browse");

            end % for

            % Import button
            obj.ImportButton = uibutton(obj.ControlsGrid, ...
                "Text", "Import", ...
                "ButtonPushedFcn", @obj.onImportButtonPressed);

            % Clear button
            obj.ClearButton = uibutton(obj.ControlsGrid, ...
                "Text", "Clear", ...
                "ButtonPushedFcn", @obj.onClearButtonPressed);
            obj.ClearButton.Layout.Row = 3;
            obj.ClearButton.Layout.Column = 3;

        end

        function update(obj, ~, ~)

            % This method is run whenever a public property is changed

        end

    end % methods setup update

    methods

        function onBrowseButtonPressed(obj, source, ~)

            [file, path] = uigetfile(["*.xlsx"; "*.csv"]);

            % Refocus figure
            focus(ancestor(obj, "figure"))

            % If a file is selected
            if file ~= 0

                % Write file name property based on button pressed
                idx = source.UserData;
                obj.FileNames(idx) = fullfile(path, file);

                % Display selected file name
                obj.FileNameDisplays(idx).Value = file;

            end % if file ~= 0

        end % function onBrowseButtonPressed(obj, ~, ~)

        function onImportButtonPressed(obj, ~, ~)

            fileNamesExist = obj.FileNames ~= "";

            if all( fileNamesExist )

                % Import both files
                try
                    obj.ShapeData.importSeismicData(obj.FileNames(1));
                    obj.ShapeData.importProductionData(obj.FileNames(2));

                    uialert(ancestor(obj, "matlab.ui.Figure"), ...
                        "Files were imported successfully", ...
                        "Successful Import", ...
                        "Icon", "success")
                catch M
                    uialert(ancestor(obj, "matlab.ui.Figure"), ...
                        ["Check data file format.";...
                        "Error: " + M.message], ...
                        "Import failed")
                end

            elseif fileNamesExist(1)

                % Import sensimic data only
                try
                    obj.ShapeData.importSeismicData(obj.FileNames(1));

                    uialert(ancestor(obj, "matlab.ui.Figure"), ...
                        "Files were imported successfully", ...
                        "Successful Import", ...
                        "Icon", "success")
                catch M
                    uialert(ancestor(obj, "matlab.ui.Figure"), ...
                        ["Check data file format.";...
                        "Error: " + M.message], ...
                        "Import failed")
                end

            elseif fileNamesExist(2)

                % Ask for seismic file name if only production file given
                uialert(ancestor(obj, "matlab.ui.Figure"), ...
                    "Please specify the file name for the Seismic data", ...
                    "Seismic Data File Name Required")

            elseif ~all( fileNamesExist )

                % If no file names are given
                uialert(ancestor(obj, "matlab.ui.Figure"), ...
                    "Please specify the seismic data or both file names", ...
                    "File Names Required")

            end % if all( fileNamesExist )

        end % onImportButtonPressed

        function onClearButtonPressed(obj, ~, ~)

            % Write file name property based on button pressed
            obj.FileNames = ["", ""];

            % Display selected file name
            set(obj.FileNameDisplays, "Value", "");

        end

    end % callbacks

end % classdef