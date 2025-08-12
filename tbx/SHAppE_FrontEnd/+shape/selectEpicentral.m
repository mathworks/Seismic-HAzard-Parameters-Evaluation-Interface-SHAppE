% selectEpicentral component class

classdef selectEpicentral < shape.SHAPEComponent

    properties (Access=private) % Graphics
        MainGrid matlab.ui.container.GridLayout
        GeoAxes matlab.graphics.axis.GeographicAxes
        GeoScatter matlab.graphics.chart.primitive.Scatter
        DrawROIButton matlab.ui.control.Button
        ROI images.roi.Polygon
        ApplyButton matlab.ui.control.Button
        ClearButton matlab.ui.control.Button
    end

    properties
        Basemap = "topographic"
    end

    properties (Constant, Access=private)
        NotSelectedColour = [1, 0, 0]
        SelectedColour = [0, 1, 0];
    end

    properties (Access=private) % Data Related
        L event.listener
    end

    methods

        function obj = selectEpicentral(shapeData, namedArgs)

            arguments
                shapeData (1, 1) shape.ShapeData
                namedArgs.?shape.selectEpicentral
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

            % Create graphics
            obj.MainGrid = uigridlayout(obj, [1, 2], ...
                "ColumnWidth", {"1x", 175});

            obj.GeoAxes = geoaxes(obj.MainGrid);
            % obj.GeoAxes.Basemap = obj.Basemap;
            ControlPanel = uipanel(obj.MainGrid);
            ControlGrid = uigridlayout(ControlPanel, [5, 1], ...
                "RowHeight", {"fit", "fit", "fit", "fit", "1x"});

            obj.DrawROIButton = uibutton(ControlGrid, ...
                "Text", "Draw New ROI", ...
                "ButtonPushedFcn", @obj.DrawPoly);

            % Create data graphics
            obj.GeoScatter = geoscatter(obj.GeoAxes, ...
                NaN, NaN, "filled");
            obj.GeoScatter.SizeData = 12;

            % Create polygon ROI
            obj.InitilaizeROI;

            % Create buttons
            obj.ApplyButton = uibutton(ControlGrid, ...
                "Text", "Apply Filter", ...
                "ButtonPushedFcn", @obj.onApplyButtonPushed);
            obj.ClearButton = uibutton(ControlGrid, ...
                "Text", "Restore Default Value", ...
                "ButtonPushedFcn", @obj.onClearButtonPushed);

        end

        function update(obj, ~, ~)

            if ~isempty(obj.ShapeData.SeismicData)

                % Set up data points
                colourData = repmat(obj.NotSelectedColour, ...
                    length(obj.ShapeData.FilteredData.Latitude), 1);

                set(obj.GeoScatter, "LongitudeData", obj.ShapeData.FilteredData.Longitude,...
                    "LatitudeData", obj.ShapeData.FilteredData.Latitude, "CData", colourData)
                set([obj.DrawROIButton, ...
                    obj.ClearButton], "Enable", "on")

                if ~isempty(obj.ROI.Position)
                    obj.ApplyButton.Enable = "on";
                else
                    obj.ApplyButton.Enable = "off";
                end

            else

                set([obj.DrawROIButton, ...
                    obj.ApplyButton, ...
                    obj.ClearButton], "Enable", "off")

            end

        end
    end % methods (Access = protected)

    methods (Access=private)

        function onPolyMoved(obj, ~, ~)

            % reset epicentral property
            if ~isempty(obj.ShapeData.selectedEpicentralValues)
                obj.ShapeData.setDefaultFilter("selectedEpicentralValues")
            end

            % Check a valid ROI has been drawn
            if ~isempty(obj.ROI.Position) && ~isempty(obj.ShapeData.FilteredData)

                % See what has been selected
                idx = inROI(obj.ROI, ...
                    obj.ShapeData.FilteredData.Latitude, ...
                    obj.ShapeData.FilteredData.Longitude);

                % Measure how many points were selected
                numSelectedPoints = sum(idx);
                numNotSelectedPoints = length(idx) - numSelectedPoints;

                % Change colour of selected points
                obj.GeoScatter.CData(idx, :) = repmat(obj.SelectedColour, numSelectedPoints, 1);

                % Change colour of not selected points
                obj.GeoScatter.CData(~idx, :) = repmat(obj.NotSelectedColour, numNotSelectedPoints, 1);

            end % if ~isempty(obj.ROI.Position)

        end % onPolyMoved

        function DrawPoly(obj, ~, ~)

            % Call this to reset
            obj.onPolyMoved

            % Reset colours
            obj.GeoScatter.CData = obj.NotSelectedColour;

            % Draw new ROI
            draw(obj.ROI)

            obj.ApplyButton.Enable = "on";

        end % DrawPoly

    end % Poly methods

    methods % callbacks

        function onApplyButtonPushed(obj, ~, ~)

            % Check a valid ROI exists and we have at least three points
            if ~isempty(obj.ROI.Position) && height(obj.ROI.Position) >= 3

                % Grab axis limits before setting
                latLims = obj.GeoAxes.LatitudeLimits;
                lonLims = obj.GeoAxes.LongitudeLimits;

                % Set property using filter methodserial
                obj.ShapeData.Filter("selectedEpicentralValues", obj.ROI.Position)

                % Set colour
                obj.GeoScatter.CData = obj.SelectedColour;

                % Set axis limits
                geolimits(obj.GeoAxes, latLims, lonLims)

                % Toggle apply button
                obj.ApplyButton.Enable = "off";

            end % if ~isempty(obj.ROI.Position)

        end % onApplyButtonPushed

        function onClearButtonPushed(obj, ~, ~)

            obj.InitilaizeROI();

            obj.ShapeData.setDefaultFilter("selectedEpicentralValues");

            % Set axis mode back to auto
            geolimits(obj.GeoAxes, "auto")

            % Reinitialise ROI
            % obj.ROI.Position = [];

            % obj.InitilaizeROI()
            obj.onPolyMoved()

        end % onClearButtonPushed

    end

    methods (Access=private)

        function InitilaizeROI(obj)

            % Delete ROI is one exists
            if ~isempty(obj.ROI)
                delete(obj.ROI)
            end

            obj.ROI = images.roi.Polygon(obj.GeoAxes, "Deletable", false);

            % Create polygon listeners
            listenerNames = ["ROIMoved", "MovingROI", ...
                "DrawingFinished", "DeletingROI", "VertexDeleted"];
            for k = 1:5
                l(k) = listener(obj.ROI, listenerNames(k), @obj.onPolyMoved); %#ok<AGROW>
            end
            obj.L = l;

        end

    end

end % classdef