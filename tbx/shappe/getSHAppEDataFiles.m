% Function to copy SHAppE example data to working directory and open
function getSHAppEDataFiles

% Copy
try
    % Add SHAppE data files to the working directory
    copyfile(which("Vietnam_Seismic_Data.xlsx"), pwd)
    copyfile(which("Vietnam_Production_Data.xlsx"), pwd)
    copyfile(which("Example_Windows.xlsx"), pwd)
catch
    warning("Unable to copy SHAppE data files")
end

% Open
try
    % Open the example files
    winopen("Vietnam_Seismic_Data.xlsx")
    winopen("Vietnam_Production_Data.xlsx")
    winopen("Example_Windows.xlsx")
catch
    warning("Unable to open SHAppE data files")
end

end