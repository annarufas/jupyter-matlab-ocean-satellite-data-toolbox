function [cmemsData] = ncreadTimeseriesCmemsData(dirCmemsDataRaw,datasetNames,...
    filenameCmemsDataProcessed)

% NCREADTIMESERIESCMEMSDATA Read CMEMS .nc files, extract data and save the
% data into a Matlab structured array for further processing.
%
%   INPUT:
%       dirCmemsDataRaw            - directory containing the CMEMS .nc files
%       datasetNames               - string that contains the name of the different CMEMS datasets
%       filenameCmemsDataProcessed - .mat file containing cmemsData
%
%   OUTPUT:
%       cmemsData                  - Matlab table with the data read from the CMEMS .nc files
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

fprintf("\nReading CMEMS's time-series products...")
  
%% Presets

% Naming conventions used by CMEMS
cmemsVarNameLatitude = 'lat';
cmemsVarNameLongitude = 'lon';
cmemsVarNameTime = 'time';
cmemsVarNameDepth = 'depth'; 

% Initialise structure array for output
cmemsData = struct('ID', {}, 'varNames', {}, 'units', {}, 'dataset', {},... 
    'lat', {}, 'lon', {}, 'time', {}, 'depth', {});

% Upon inspection of some properties of the data (Hovmoller diagrams), we 
% will discard the first five years (1993-1997) as their values look 
% anomalously high and start in 1998
startDate = datetime(1998,1,1);

%% Loop over files

for iDataset = 1:length(datasetNames)

    fileName = strcat(datasetNames{iDataset},'.nc');
    filePath = fullfile('.','data','raw','CMEMS_data',dirCmemsDataRaw,fileName);
    
    fprintf('\nReading %s',fileName)

    % List variable names and units
    S = ncinfo(filePath); % short summary
    nVars = length(S.Variables);
    varName = cell(nVars,1);
    varUnit = cell(nVars,1);
    for iVar = 1:nVars
        varName{iVar} = S.Variables(iVar).Name;
        iUnit = contains({S.Variables(iVar).Attributes.Name},'units','IgnoreCase',true);
        if (sum(iUnit) > 0) % check that the field 'units' exists before reading it (some variables, like 'flags' don't have units)
            varUnit{iVar} = ncreadatt(filePath,varName{iVar},'units');
        end
    end

    % Get idx of dimensional variable names (different files use different
    % variable names (e.g., some files use 'lat', others use 'latitude'))
    iLat = find(contains(string(varName),cmemsVarNameLatitude,'IgnoreCase',true));
    iLon = find(contains(string(varName),cmemsVarNameLongitude,'IgnoreCase',true));
    iTime = find(contains(string(varName),cmemsVarNameTime,'IgnoreCase',true));
    iDepth = find(contains(string(varName),cmemsVarNameDepth,'IgnoreCase',true));

    % Read longitude, latitude, time and depth (if exists)
    lat = ncread(filePath,varName{iLat});
    lon = ncread(filePath,varName{iLon});
    time = ncread(filePath,varName{iTime}); 
    if ~isempty(iDepth)
        depth = ncread(filePath,varName{iDepth}); 
    end

    % Transform time into a more conventional format
    % I have checked the epochtype options in the files I want to download
    timeUnits = varUnit{iTime}; %ncreadatt(fileurl,'time','units');
    timeUnitsNum = extract(timeUnits,digitsPattern);

    if strcmp(timeUnits,'days since 0000-01-01') 
        epochtype = 'datenum';
    elseif strcmp(timeUnits,'days since 1900-01-01')
        epochtype = 'excel';
    elseif strcmp(timeUnits,'days since 1904-01-01')
        epochtype = 'excel1904';     
    elseif strcmp(timeUnits,'seconds since 1970-01-01') || strcmp(timeUnits,'seconds since 1970-01-01 00:00:00')
        epochtype = 'posixtime';   
    else
        error('Invalid time unit.');
    end

    timeCalendar = datetime(time(:),'ConvertFrom',epochtype,'Epoch',... 
        [timeUnitsNum{1} '-' timeUnitsNum{2} '-' timeUnitsNum{3}]);
    
    % Get idx of non-structural variables (i.e., ocean colour information)
    isVarOceanColour = zeros(nVars,1);
    for i = 1:nVars
        if (i == iLat | i == iLon | i == iTime | i == iDepth)
            isVarOceanColour(i) = 0;
        else
            isVarOceanColour(i) = 1;
        end
    end
    nOceanColourVars = sum(isVarOceanColour == 1);
    oceanColourVarNames = varName(isVarOceanColour == 1);
    oceanColourVarUnits = varUnit(isVarOceanColour == 1);
    
    % Create 'start' and 'count' arguments for the ncread function. For
    % that, we need to find the arrangement of the dimensional variables in 
    % the ocean colour variables
    for i = 1:nVars
        if (isVarOceanColour(i) == 1)
            iDimLat = find(contains(string({S.Variables(i).Dimensions.Name}),cmemsVarNameLatitude,'IgnoreCase',true)); 
            iDimLon = find(contains(string({S.Variables(i).Dimensions.Name}),cmemsVarNameLongitude,'IgnoreCase',true)); 
            iDimTime = find(contains(string({S.Variables(i).Dimensions.Name}),cmemsVarNameTime,'IgnoreCase',true)); 
            iDimDepth = find(contains(string({S.Variables(i).Dimensions.Name}),cmemsVarNameDepth,'IgnoreCase',true));
            break
        end
    end
    
    if ~isempty(iDepth)
        startIndices = [1           1           1            1]; 
        dimCounts    = [length(lat) length(lon) length(time) length(depth)]; 
        orderIndices = [iDimLat     iDimLon     iDimTime     iDimDepth];
    else
        startIndices = [1           1           1]; 
        dimCounts    = [length(lat) length(lon) length(time)]; 
        orderIndices = [iDimLat     iDimLon     iDimTime];
    end
    
    % Sort start and counts according to dimensional arrangement in the
    % original dataset
    [~,sortedIndices] = sort(orderIndices);
    start = startIndices(sortedIndices); % start indices ordered
    count = dimCounts(sortedIndices); % dimensional information ordered
    
    % Read data and save it in a standardized format:
    % 1st dimension: latitude
    % 2nd dimension: longitude
    % 3rd dimension: time
    % 4th dimension: depth
    % The ordering follows the 'dimCounts' array specification.
    sizeDataset = [dimCounts,nOceanColourVars];
    D = zeros(sizeDataset,'single'); % use single-precision to reduce storage space 
    if ~isempty(iDepth)
        for i = 1:nOceanColourVars
            Dtmp = ncread(filePath,oceanColourVarNames{i},start,count);
            Dperm = permute(Dtmp,[iDimLat iDimLon iDimTime iDimDepth]);
            D(:,:,:,:,i) = Dperm;
            %figure(1); pcolor(Dperm(:,:,7000)); caxis([0 1]); shading interp; colormap(jet); box on
        end 
    elseif isempty(iDepth)
        for i = 1:nOceanColourVars
            Dtmp = ncread(filePath,oceanColourVarNames{i},start,count);
            Dperm = permute(Dtmp,[iDimLat iDimLon iDimTime]);
            D(:,:,:,i) = Dperm;
            %figure(1); pcolor(Dperm(:,:,7000)); caxis([0 1]); shading interp; colormap(jet); box on
        end
    end

    if isempty(iDepth)
        depth = 0;
    end
    
    % If the dataset is one of the reanalysis products, skip first five years, 1993-1997
    [~, closestIdxStartDate] = min(abs(timeCalendar - startDate));

    % Save information into output array
    cmemsData(iDataset).ID = datasetNames{iDataset};
    cmemsData(iDataset).varNames = oceanColourVarNames;
    cmemsData(iDataset).units = oceanColourVarUnits;
    if contains(fileName, 'mod_')
        if ~isempty(iDepth)
            cmemsData(iDataset).dataset = D(:,:,closestIdxStartDate:end,:,:);
        elseif isempty(iDepth)
            cmemsData(iDataset).dataset = D(:,:,closestIdxStartDate:end,:);
        end
    else
        cmemsData(iDataset).dataset = D;
    end
    cmemsData(iDataset).lat = lat;
    cmemsData(iDataset).lon = lon;
    if contains(fileName, 'mod_')
        cmemsData(iDataset).time = timeCalendar(closestIdxStartDate:end);
    else
        cmemsData(iDataset).time = timeCalendar;
    end
    cmemsData(iDataset).depth = depth;   
   
end % iDataset

%% Save

fprintf("\n... reading finished, saving array...")
save(fullfile('.','data','processed',filenameCmemsDataProcessed),'cmemsData','-v7.3')
fprintf("... saving completed.\n")

end % ncreadTimeseriesCmemsData
