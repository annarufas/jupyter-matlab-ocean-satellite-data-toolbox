function [occciData] = ncreadTimeseriesOccciData(dirOccciDataRaw,...
    datasetNames,filenameOccciDataProcessed,pathAreaStudyShapefile)

% NCREADTIMESERIESOCCCIDATA Read OC-CCI .nc files, extract data and save the
% data into a Matlab structured array for further processing.
%
%   INPUT:
%       dirOccciDataRaw            - directory containing the CMEMS .nc files
%       datasetNames               - string that contains the name of the different OC-CCI datasets downloaded
%       filenameOccciDataProcessed - .mat file containing occciData
%       pathAreaStudyShapefile     - shapefile with our area of study
%
%   OUTPUT:
%       occciData                  - Matlab table with the data read from the OC-CCI .nc files
%          
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD
%   Anna.RufasBlanco@earth.ox.ac.uk
%
%   Version 1.0 - Completed 28 April 2024   
%
% =========================================================================
%%
% -------------------------------------------------------------------------
% PROCESSING STEPS
% -------------------------------------------------------------------------

fprintf("\nReading OCI-CCI's time-series products...")

%% Presets

% Naming conventions used by OC-CCI
occciVarName.Latitude = 'lat';
occciVarName.Longitude = 'lon';
occciVarName.Time = 'time';

% Initialise structure array for output
occciData = struct('ID', {}, 'varNames', {}, 'units', {}, 'dataset', {},...
    'lat', {}, 'lon', {}, 'time', {});

%% Loop over datasets

% Read data from each category
for iDatasetCategory = 1:size(datasetNames, 1)
    
    categoryName = datasetNames{iDatasetCategory, 1};
    thisCategoryDatasetNames = datasetNames{iDatasetCategory, 2};
    
    fprintf("\nReading %s resolution datasets...\n", categoryName);
    
    % Process datasets and concatenate data
    [occciData] = processDatasets(occciData,occciVarName,dirOccciDataRaw,...
        thisCategoryDatasetNames,pathAreaStudyShapefile,iDatasetCategory,categoryName);
    
    fprintf("...%s resolution datasets processing completed.\n", categoryName);

end

%% Saving

save(fullfile('.','data','processed',filenameOccciDataProcessed),'occciData','-v7.3')
fprintf("\n...finished reading OCI-CCI's time-series products.\n")

% =========================================================================
%%
% -------------------------------------------------------------------------
% LOCAL FUNCTIONS USED IN THIS SCRIPT
% -------------------------------------------------------------------------

% *************************************************************************

function [occciData] = processDatasets(occciData,occciVarName,dirOccciDataRaw,...
    thisCategoryDatasetNames,pathAreaStudyShapefile,iDatasetCategory,categoryName)

% Initialise arrays to hold data for concatenation
D_firstHalf = [];
D_secondHalf = [];
D_combined = [];
time_firstHalf = [];
time_secondHalf = [];
time_combined = [];
D_category = [];
time_category = [];

varnames_combined = {};
varunits_combined = {};

% Loop through datasets and read data
for iDataset = 1:length(thisCategoryDatasetNames)
    
    fileName = strcat(thisCategoryDatasetNames{iDataset});
    filePath = fullfile('.','data','raw','OCCCI_data',dirOccciDataRaw,fileName);
    
    fprintf('Reading data from dataset %s',fileName)

    [D,lat,lon,time,oceanColourVarNames,oceanColourVarUnits] =... 
        extractVariables(filePath,occciVarName,pathAreaStudyShapefile);

    % Determine whether to concatenate data along the third dimension
    if mod(iDataset,2) == 1 % odd datasets: store data as first half
        D_firstHalf = D;
        if (iDataset == 1) % initialise varnames and varunits on the first iteration
            time_firstHalf = time;
            varnames_combined = oceanColourVarNames;
            varunits_combined = oceanColourVarUnits;
        else
            varnames_combined = [varnames_combined; oceanColourVarNames]; 
            varunits_combined = [varunits_combined; oceanColourVarUnits];
        end   
    else % even datasets: concatenate with first half
        D_secondHalf = D;
        D_combined = cat(3, D_firstHalf, D_secondHalf); % concatenate along the time dimension
        D_category = cat(4, D_category, D_combined); % concatenate along the dataset dimension
        if (iDataset == 2)
            time_secondHalf = time;
            time_combined = cat(1, time_firstHalf, time_secondHalf);
            time_category = time_combined;
        end
    end
            
end % iDataset

% Save processed data in the output structure
[occciData] = saveIntoStructureArray(occciData,iDatasetCategory,D_category,...
    varnames_combined,varunits_combined,lat,lon,time_category,categoryName);

end % processDatasets

% *************************************************************************

function [Dadj,latAdj,lonAdj,timeCalendar,oceanColourVarNames,oceanColourVarUnits] =... 
    extractVariables(filePath,occciVarName,pathAreaStudyShapefile)

% List variable names and units
S = ncinfo(filePath); % short summary

nVars = length(S.Variables);
varName = cell(nVars,1);
varUnit = cell(nVars,1);
for iVar = 1:nVars
    varName{iVar} = S.Variables(iVar).Name;
    iUnit = contains({S.Variables(iVar).Attributes.Name},'units','IgnoreCase',true);
    if (sum(iUnit) > 0) % check that the field 'units' exists before reading it (some variables, like 'flags', don't have units)
        varUnit{iVar} = ncreadatt(filePath,varName{iVar},'units');
    end
end

% Get idx of dimensional variable names (different files use different
% variable names (e.g., some files use 'lat', others use 'latitude'))
iLat = find(contains(string(varName),occciVarName.Latitude,'IgnoreCase',true));
iLon = find(contains(string(varName),occciVarName.Longitude,'IgnoreCase',true));
iTime = find(contains(string(varName),occciVarName.Time,'IgnoreCase',true));

% Read longitude, latitude and time
lat = ncread(filePath,varName{iLat});
lon = ncread(filePath,varName{iLon});
time = ncread(filePath,varName{iTime});

% Transform the numeric representation of time into calendar datetime 
% format
timeUnits = varUnit{iTime}; %ncreadatt(fileurl,'time','units');
timeCalendar = datetime(1970,1,1,'Format','dd-MMM-yyyy') + caldays(time);

% Get idx of non-structural variables (i.e., ocean colour information)
isVarOceanColour = zeros(nVars,1);
for i = 1:nVars
    if (i == iLat || i == iLon || i == iTime)
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
        iDimLat = find(contains(string({S.Variables(i).Dimensions.Name}),occciVarName.Latitude,'IgnoreCase',true)); 
        iDimLon = find(contains(string({S.Variables(i).Dimensions.Name}),occciVarName.Longitude,'IgnoreCase',true)); 
        iDimTime = find(contains(string({S.Variables(i).Dimensions.Name}),occciVarName.Time,'IgnoreCase',true)); 
        break
    end
end

startIndices = [1           1           1]; 
dimCounts    = [length(lat) length(lon) length(time)]; 
orderIndices = [iDimLat     iDimLon     iDimTime];

% Sort start and counts according to dimensional arrangement in the
% original dataset
[~,sortedIndices] = sort(orderIndices);
start = startIndices(sortedIndices); % start indices ordered
count = dimCounts(sortedIndices); % dimensional information ordered

% Read data and save it in a standardized format:
% 1st dimension: latitude
% 2nd dimension: longitude
% 3rd dimension: time
% The ordering follows the 'dimCounts' array specification.
sizeDataset = [dimCounts,nOceanColourVars];
D = zeros(sizeDataset,'single'); % use single-precision to reduce storage space
for i = 1:nOceanColourVars
    Dtmp = ncread(filePath,oceanColourVarNames{i},start,count);
    Dperm = permute(Dtmp,[iDimLat iDimLon iDimTime]);
    D(:,:,:,i) = Dperm;
    %figure(1); pcolor(Dperm(:,:,4000)); caxis([0 1]); shading interp; colormap(jet); box on
end

 % Adjust coordinates for the area of study
[idxMinLat,idxMaxLat,idxMinLon,idxMaxLon,latAdj,lonAdj] =...
    adjustAreaStudyCoordinates(lat,lon,pathAreaStudyShapefile);
            
Dadj = D(idxMaxLat:idxMinLat,idxMinLon:idxMaxLon,:,:);
    
end % extractVariables

% *************************************************************************

function [occciData] = saveIntoStructureArray(occciData,iDatasetCategory,...
    D_category,D_varnames,D_varunits,lat,lon,time_category,categoryName)

    occciData(iDatasetCategory).ID = categoryName;
    occciData(iDatasetCategory).varNames = D_varnames;
    occciData(iDatasetCategory).units = D_varunits;
    occciData(iDatasetCategory).dataset = D_category;
    occciData(iDatasetCategory).lat = lat;
    occciData(iDatasetCategory).lon = lon;
    occciData(iDatasetCategory).time = time_category;

end % saveIntoStructureArray

% *************************************************************************

end % ncreadTimeseriesOccciData