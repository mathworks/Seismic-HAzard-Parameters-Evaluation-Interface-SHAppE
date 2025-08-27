classdef (Abstract) SHAPEComponent < matlab.ui.componentcontainer.ComponentContainer

    properties (GetAccess = protected)
        ShapeData (:, 1) shape.ShapeData {mustBeScalarOrEmpty}
    end

    % Listeners
    properties (Access = protected)
        SeismicDataListener (:, 1) event.listener {mustBeScalarOrEmpty}
        ProductionDataListener (:, 1) event.listener {mustBeScalarOrEmpty}
        SHAPEFiltersChanged (:, 1) event.listener {mustBeScalarOrEmpty}
        DataAnalysisComplete (:, 1) event.listener {mustBeScalarOrEmpty}
    end

    methods
        function obj = SHAPEComponent(shapeData)
            
            arguments
                shapeData (1, 1) shape.ShapeData
            end

            % Call the superclass constructor with specified properties
            obj@matlab.ui.componentcontainer.ComponentContainer(...
                "Units", "normalized", "Position", [0, 0, 1, 1], ...
                "Parent", [])

            % Assign shapeData
            obj.ShapeData = shapeData;

            % Initialise listeners
            obj.SeismicDataListener = ...
                listener(obj.ShapeData, "SeismicDataImported", @obj.update);
            obj.ProductionDataListener = ...
                listener(obj.ShapeData, "ProductionDataImported", @obj.update);
            obj.SHAPEFiltersChanged = ...
                listener(obj.ShapeData, "FilterChanged", @obj.update);
            obj.DataAnalysisComplete = ...
                listener(obj.ShapeData, "AnalysisComplete", @obj.update);

        end
    end
end