function [nasaData] = ncreadNASAtimeseries(dirNasaDataRaw,...
    filenameNasaDataProcessed)

% NCREADNASATIMESERIES Reads in the time-series data downloaded from
% NASA's OB.DAAC portal. 
%
%   INPUT:
%       dirNasaDataRaw            - directory containing the NASA .nc files
%       filenameNasaDataProcessed - .mat file containing nasaData
%
%   OUTPUT:
%       nasaData                  - Matlab table with the data read from the NASA .nc files
%          
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD
%   Anna.RufasBlanco@earth.ox.ac.uk
%
%   Version 1.0 - Completed 26 April 2024   
%
% =========================================================================
%%
% -------------------------------------------------------------------------
% PROCESSING STEPS
% -------------------------------------------------------------------------

fprintf("\nReading NASA's time-series products...")

%% Presets

% Naming conventions used by NASA
nasaVarNameLatitude = 'lat';
nasaVarNameLongitude = 'lon';
nasaVarNameTime = 'time_coverage_start';
nasaVarNameChla = 'chlor_a'; 

% Initialise structure array for output
nasaData = struct('ID', {}, 'varNames', {}, 'units', {}, 'dataset', {},... 
    'lat', {}, 'lon', {}, 'time', {});

%% Loop over sensor files

nSensors = size(dirNasaDataRaw, 1);

for iSensor = 1:nSensors
    
    sensorName = dirNasaDataRaw{iSensor, 1};
    fullPathSensorDir = fullfile('.','data','raw','NASA_data',sensorName);
    fprintf('\nReading data in folder %s',sensorName)
    
    % Get a list of all files in the folder
    fileNames = dir(fullfile(fullPathSensorDir, '*.nc'));
    nFiles = length(fileNames);
    
    % Extract common information to all files in folder: time, lat and lon
    fileChoice = 1; % 1st file
    filePathChoice = fileNames(fileChoice).name;
    S = ncinfo(filePathChoice); % short summary
    
    lat       = ncread(filePathChoice,nasaVarNameLatitude);
    lon       = ncread(filePathChoice,nasaVarNameLongitude);
    chlaUnits = ncreadatt(filePathChoice,nasaVarNameChla,'units');
    chlaIndex = find(strcmp({S.Variables.Name},nasaVarNameChla));
    iDimLat   = find(contains(string({S.Variables(chlaIndex).Dimensions.Name}),nasaVarNameLatitude,'IgnoreCase',true)); 
    iDimLon   = find(contains(string({S.Variables(chlaIndex).Dimensions.Name}),nasaVarNameLongitude,'IgnoreCase',true));
    iTime     = find(strcmp({S.Attributes.Name},nasaVarNameTime));
    [nRows,nCols] = size(ncread(filePathChoice,nasaVarNameChla));
    
    % Extract chla file by file and save the data into a standardised 
    % format, where 1st dim = lat, 2nd dim = lon. 
    Dtmp = zeros(nRows,nCols,nFiles);
    timeCalendar = string(zeros(nFiles, 1)); %NaT(nFiles,1); % create empty vector that will contain datetime values
    for iFile = 1:nFiles
        filePath = fileNames(iFile).name;
        Sfile = ncinfo(filePath); 
        timeCalendar(iFile) = Sfile.Attributes(iTime).Value; % get start time
        Dtmp(:,:,iFile) = ncread(filePath,nasaVarNameChla); % read chla
    end
    Dperm = permute(Dtmp,[iDimLat iDimLon 3]); % permute dimensions to the right sorting
    %figure(1); pcolor(Dperm(:,:,400)); caxis([0 1]); shading interp; colormap(jet); box on
    
    % Convert the string time vector to a datetime vector
    timeCalendar = datetime(timeCalendar, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    
    % Save information into output array
    nasaData(iSensor).ID = char(dirNasaDataRaw{iSensor, 2});
    nasaData(iSensor).varNames = 'CHL'; % name as in CMEMS products
    nasaData(iSensor).units = chlaUnits;
    nasaData(iSensor).dataset = Dperm;
    nasaData(iSensor).lat = lat;
    nasaData(iSensor).lon = lon;
    nasaData(iSensor).time = timeCalendar;

end % iSensor

%% Save

fprintf("\n... reading finished, saving array...")
save(fullfile('.','data','processed',filenameNasaDataProcessed),'nasaData','-v7.3')
fprintf("\n... saving completed.\n")

end % ncreadNASAtimeseries
