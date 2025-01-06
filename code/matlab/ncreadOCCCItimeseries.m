function occciData = ncreadOCCCItimeseries(occciDatasetsMetadata,...
    fileNameOccciDataProcessed,fullPathAreaStudyShapefile)

% NCREADCCCITIMESERIES Read OC-CCI .nc files, extract data and save the
% data into a Matlab structured array for further processing.
%
%   INPUT:
%       occciDatasetsMetadata      - structure that contains the name of the different OC-CCI datasets downloaded
%       fileNameOccciDataProcessed - name of the .mat file containing occciData  (ensures persistence of data for later use)
%       fullPathAreaStudyShapefile - path to shapefile with our area of study
%
%   OUTPUT:
%       occciData                  - Matlab table with the data read from the OC-CCI .nc files
%         
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD
%   Anna.RufasBlanco@earth.ox.ac.uk
%
%   Version 1.0 - Completed 28 April 2024   
%   Version 1.1 - Updated 6 Jan 2025: simplified terminology
%
% =========================================================================
%%
% -------------------------------------------------------------------------
% PROCESSING STEPS
% -------------------------------------------------------------------------

fprintf("\nReading OCI-CCI time-series products...")

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
for iCategory = 1:size(occciDatasetsMetadata,1)
    
    categoryName = occciDatasetsMetadata{iCategory,1};
    datasetNames = occciDatasetsMetadata{iCategory,2};
    
    fprintf("\nReading %s resolution datasets...\n", categoryName);
    
    % Process datasets and concatenate data
    occciData = processDatasets(occciData,occciVarName,datasetNames,...
        fullPathAreaStudyShapefile,iCategory,categoryName);
    
    fprintf("...%s resolution datasets processing completed.\n", categoryName);

end

%% Saving

save(fullfile('.','data','processed',fileNameOccciDataProcessed),'occciData','-v7.3')
fprintf("\n...finished reading OCI-CCI's time-series products.\n")

% =========================================================================
%%
% -------------------------------------------------------------------------
% LOCAL FUNCTIONS USED IN THIS SCRIPT
% -------------------------------------------------------------------------

% *************************************************************************

function occciData = processDatasets(occciData,occciVarName,datasetNames,...
    fullPathAreaStudyShapefile,iDatasetCategory,categoryName)

% Initialise arrays to hold data for concatenation
DfirstHalf  = []; % for datasets that have been split in time into two
DsecondHalf = []; % for datasets that have been split in time into two
Dcombined   = []; % combine first and second half
Dcategory   = []; % all datasets for that category

timeFirstHalf  = [];
timeSecondHalf = [];
timeCombined   = [];
timeCategory   = [];

varNamesCombined = {};
varUnitsCombined = {};

% Loop through datasets and read data
for iDataset = 1:length(datasetNames)
    
    fileName = datasetNames{iDataset};
    filePath = fullfile('.','data','raw','OCCCI_data','data_timeseries_areastudy_OCCCI_nc',fileName);
    
    fprintf('Reading data from dataset %s',fileName)

    [D,lat,lon,time,oceanColourVarNames,oceanColourVarUnits] =... 
        extractVariables(filePath,occciVarName,fullPathAreaStudyShapefile);

    % Determine whether to concatenate data along the third dimension
    if mod(iDataset,2) == 1 % odd datasets: store data as first half
        DfirstHalf = D;
        if (iDataset == 1) % initialise varnames and varunits on the first iteration
            timeFirstHalf = time;
            varNamesCombined = oceanColourVarNames;
            varUnitsCombined = oceanColourVarUnits;
        else
            varNamesCombined = [varNamesCombined; oceanColourVarNames]; 
            varUnitsCombined = [varUnitsCombined; oceanColourVarUnits];
        end   
    else % even datasets: concatenate with first half
        DsecondHalf = D;
        Dcombined = cat(3, DfirstHalf, DsecondHalf); % concatenate along the time dimension
        Dcategory = cat(4, Dcategory, Dcombined); % concatenate along the dataset dimension
        if (iDataset == 2)
            timeSecondHalf = time;
            timeCombined = cat(1, timeFirstHalf, timeSecondHalf);
            timeCategory = timeCombined;
        end
    end
            
end % iDataset

% Save processed data in the output structure
occciData = saveIntoStructureArray(occciData,iDatasetCategory,Dcategory,...
    varNamesCombined,varUnitsCombined,lat,lon,timeCategory,categoryName);

end % processDatasets

% *************************************************************************

function [Dadj,latAdj,lonAdj,timeCalendar,oceanColourVarNames,oceanColourVarUnits] =... 
    extractVariables(filePath,occciVarName,fullPathAreaStudyShapefile)

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
    %figure(); pcolor(Dperm(:,:,4000)); caxis([0 1]); shading interp; colormap(jet); box on
end

            
% Adjust the coordinates (lat, lon) to define the area of study. The OC-CCI 
% dataset is global and cannot be cropped before downloading. Therefore, 
% we have to crop the global dataset to our area of interest after the download.
[idxMinLat,idxMaxLat,idxMinLon,idxMaxLon,latAdj,lonAdj] =...
    adjustAreaStudyCoordinates(lat,lon,fullPathAreaStudyShapefile);
            
Dadj = D(idxMaxLat:idxMinLat,idxMinLon:idxMaxLon,:,:);
    
end % extractVariables

% *************************************************************************

function occciData = saveIntoStructureArray(occciData,iDatasetCategory,...
    Dcategory,Dvarnames,Dvarunits,lat,lon,timeCategory,categoryName)

    occciData(iDatasetCategory).ID       = categoryName;
    occciData(iDatasetCategory).varNames = Dvarnames;
    occciData(iDatasetCategory).units    = Dvarunits;
    occciData(iDatasetCategory).dataset  = Dcategory;
    occciData(iDatasetCategory).lat      = lat;
    occciData(iDatasetCategory).lon      = lon;
    occciData(iDatasetCategory).time     = timeCategory;

end % saveIntoStructureArray

% *************************************************************************

end % ncreadOCCCItimeseries