function launcher

% CHeck SSH Function are on the path,
% If so, trim them down to just the function in:
% sera-applications/SHAPE_Package/SHAPE_ver2b.0/SSH
% are on the path

% Repo for reference
% https://epos-apps.grid.cyfronet.pl/tcs-ah/sera-applications.git

shapeData = shape.ShapeData;
shape.SHAPEApp(shapeData);

end