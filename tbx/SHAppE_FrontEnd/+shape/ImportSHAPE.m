% ImportSHAPE component class

classdef ImportSHAPE < shape.SHAPEComponent

    properties (Access = private)
        MainGrid matlab.ui.container.GridLayout
        ControlsPanel matlab.ui.container.Panel
        ControlsGrid matlab.ui.container.GridLayout

        FileNameDisplays (1, 4) matlab.ui.control.EditField
        BrowseButtons (1, 4) matlab.ui.control.Button
        VarColumnIdxSpinners (1, 6) matlab.ui.control.Spinner  
        ImportButton (1, 1) matlab.ui.control.Button
        ClearButton (1, 1) matlab.ui.control.Button

        ImportedDisplayTable matlab.ui.control.Table
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
            obj.MainGrid = uigridlayout(obj, [1, 2], ...
                "RowHeight", {"fit", "fit"}, ...
                "ColumnWidth", {"fit", "1x"});

            % Getting started panel
            startPanel = uipanel(obj.MainGrid, ...
                "Title", "Getting Started");
            startPanel.Layout.Row = 1;
            startPanel.Layout.Column = 1;

            % Getting started grid
            startGrid = uigridlayout(startPanel, [1, 2], ...
                "RowHeight", {"fit", "fit"}, ...
                "ColumnWidth", {"fit", "fit"});

            % Getting started buttons
            uibutton(startGrid, ...
                "text", "Open Documentation", ...
                "ButtonPushedFcn", @obj.onDocButtonPushed);
            uibutton(startGrid, ...
                "text", "Move Examples files to PWD", ...
                "ButtonPushedFcn", @obj.onCopyExampleFilesButtonPushed);

            % Import files panel
            obj.ControlsPanel = uipanel(obj.MainGrid, ...
                "Title", "Select files to import");
            obj.ControlsPanel.Layout.Row = 2;
            obj.ControlsPanel.Layout.Column = 1;

            obj.ControlsGrid = uigridlayout(obj.ControlsPanel, [12, 3], ...
                "RowHeight", {"fit", "fit", "fit", "fit", "fit", "fit", ...
                "fit", 25, "fit", "fit", "fit", 25, "fit"}, ...
                "ColumnWidth", {"fit", "fit", "fit"});

            % Seismic label
            uilabel(obj.ControlsGrid, "Text", "Seismic data file name");

            % Seismic edit box
            obj.FileNameDisplays(1) = ...
                uieditfield(obj.ControlsGrid, ...
                "Editable", "off");

            % Seismic browse button
            obj.BrowseButtons(1) = ...
                uibutton(obj.ControlsGrid, ...
                "ButtonPushedFcn", @obj.onBrowseButtonPressed, ...
                "UserData", 1, ...
                "Text", "Browse");

            % Required variable labels
            reqVarBlurb = uilabel(obj.ControlsGrid, ...
                "Text", "Specify column number in your file for each variable");
            reqVarBlurb.Layout.Column = [1, 3];
            RequiredVariables = ["Time", "Latitude", "Longitude", "Magnitude", "Depth"];
            for k = 1:length(RequiredVariables)
                uilabel(obj.ControlsGrid, "Text", RequiredVariables(k));
                obj.VarColumnIdxSpinners(k) = uispinner(obj.ControlsGrid, ...
                    "RoundFractionalValues","on", ...
                    "Limits", [1, inf]);
                obj.VarColumnIdxSpinners(k).Layout.Column = [2, 3];
            end

            % Production label
            prodLbl = uilabel(obj.ControlsGrid, ...
                "Text", "Production data file name (Optional)");
            prodLbl.Layout.Row = 9;

            % Production edit box
            obj.FileNameDisplays(2) = ...
                uieditfield(obj.ControlsGrid, ...
                "Editable", "off");

            % Production browse button
            obj.BrowseButtons(2) = ...
                uibutton(obj.ControlsGrid, ...
                "ButtonPushedFcn", @obj.onBrowseButtonPressed, ...
                "UserData", 2, ...
                "Text", "Browse");

            % Required variable labels
            reqVarBlurb = uilabel(obj.ControlsGrid, ...
                "Text", "Specify column number in your file for the Time variable");
            reqVarBlurb.Layout.Column = [1, 3];
            uilabel(obj.ControlsGrid, "Text", "Time");
            obj.VarColumnIdxSpinners(6) = uispinner(obj.ControlsGrid, ...
                    "RoundFractionalValues","on", ...
                    "Limits", [1, inf]);
            obj.VarColumnIdxSpinners(6).Layout.Column = [2, 3];

            % Import button
            obj.ImportButton = uibutton(obj.ControlsGrid, ...
                "Text", "Import", ...
                "ButtonPushedFcn", @obj.onImportButtonPressed);
            obj.ImportButton.Layout.Row = 13;

            % Clear button
            obj.ClearButton = uibutton(obj.ControlsGrid, ...
                "Text", "Clear", ...
                "ButtonPushedFcn", @obj.onClearButtonPressed);
            obj.ClearButton.Layout.Column = 3;

            % Imported data panel
            importedPanel = uipanel(obj.MainGrid, ...
                "Title", "Data Preview");
            importedPanel.Layout.Row = [1, 2];
            importedPanel.Layout.Column = 2;

            % Imported data grid
            importedGrid = uigridlayout(importedPanel, [1, 1]);

            % Imported data display table
            obj.ImportedDisplayTable = uitable(importedGrid);

            % make everything in imported panel invisible
            set(importedPanel.Children, "Visible", "on")

        end

        function update(obj, ~, ~)

            % This method is run whenever a public property is changed

        end

    end % methods setup update

    methods

        function onDocButtonPushed(obj, ~, ~)
            try
                path = which("GettingStartedWithSHAppE.mlx");
                edit(path)
            catch M
                uialert(ancestor(obj, "matlab.ui.Figure"), ...
                    ["Unable to open documentation";...
                    "Error: " + M.message], ...
                    "Open failed")
            end
        end

        function onCopyExampleFilesButtonPushed(obj, ~, ~)
            try
                % Add SHAppE data files to the working directory
                copyfile(which("Vietnam_Seismic_Data.xlsx"), pwd)
                copyfile(which("Vietnam_Production_Data.xlsx"), pwd)
                copyfile(which("Example_Windows.xlsx"), pwd)

                uialert(ancestor(obj, "matlab.ui.Figure"), ...
                    "Example files copied to working directory successfully", ...
                    "Example Files Copied", ...
                    "Icon", "success")
            catch M
                uialert(ancestor(obj, "matlab.ui.Figure"), ...
                    ["Unable to copy example files";...
                    "Error: " + M.message], ...
                    "Copy failed")
            end
        end

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

                % Collate required variable column numbers
                SeismicDataColumnNumbers = [obj.VarColumnIdxSpinners(1:5).Value];
                ProductionDataColumnNumbers = obj.VarColumnIdxSpinners(6).Value;

                % Import both files
                try
                    obj.ShapeData.importSeismicData(obj.FileNames(1), SeismicDataColumnNumbers);
                    obj.ShapeData.importProductionData(obj.FileNames(2), ProductionDataColumnNumbers);

                    % Display preview of imported data
                    obj.ImportedDisplayTable.Data = ...
                    timetable2table( obj.ShapeData.FilteredData(1:20, :) );

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

                % Collate required variable column numbers
                SeismicDataColumnNumbers = [obj.VarColumnIdxSpinners(1:5).Value];

                % Import sensimic data only
                try
                    obj.ShapeData.importSeismicData(obj.FileNames(1), SeismicDataColumnNumbers);

                    % Display preview of imported data
                    obj.ImportedDisplayTable.Data = ...
                    timetable2table( obj.ShapeData.FilteredData(1:20, :) );

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