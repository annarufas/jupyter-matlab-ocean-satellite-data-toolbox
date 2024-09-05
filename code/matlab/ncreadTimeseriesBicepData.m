function [bicepData] = ncreadTimeseriesBicepData(datasetNames,...
    yearsVector,pathAreaStudyShapefile)

% NCREADTIMESERIESBICEPDATA Read BICEP .nc files, extract data and save the
% data into a Matlab structured array for further processing.
%
%   INPUT:
%       datasetNames           - string containing the names of the BICEP datasets
%       yearsVector            - defines a common period for all datasets
%       pathAreaStudyShapefile - shapefile with our area of study
%
%   OUTPUT:
%       bicepData              - Matlab strcuture with the data read from the BICEP .nc files 
%
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD
%   Anna.RufasBlanco@earth.ox.ac.uk
%
%   Version 1.0 - Completed 3 May 2024   
%
% =========================================================================
%%
% -------------------------------------------------------------------------
% PROCESSING STEPS
% -------------------------------------------------------------------------

fprintf("\nReading BICEP's time-series products...")

%% Presets

% Create a time vector
time = datetime.empty;
% Iterate through each year from start to end
for year = yearsVector(1):yearsVector(end)
    % Iterate through each month from 1 to 12
    for month = 1:12
        time = [time; datetime(year, month, 1)];
    end
end

% Initialise structure array for output
bicepData = struct('ID', {}, 'varNames', {}, 'units', {}, 'dataset', {},...
    'lat', {}, 'lon', {}, 'time', {});

%% Extract data from BICEP datasets (monthly global arrays for 1998-2020)

for iDataset = 1:size(datasetNames, 1)
    
    datasetName = datasetNames{iDataset, 1};
    fullPathDatasetDir = fullfile('.','data','raw','BICEP_data',datasetName);
    fprintf('\nReading data in folder %s',datasetName)
    
    % Define dataset-specific parameters
    switch datasetName
        
        % The POC product is a MLD-integrated product. BICEP does not
        % provide the MLD product used but the product information in 
        % Evers-King et al. (2017) says it is the MIMOC MLD product has 
        % been used for it.
        case 'BICEP_POC_nc'
            oceanColourVars = {'POC'};
            oceanColourVarsUnits = {'mg C m-3'};
            latitudeVar = 'lat';
            longitudeVar = 'lon';
        
        case 'BICEP_NPP_nc'
            oceanColourVars = {'pp'};
            oceanColourVarsUnits = {'mg C m-2 d-1'};
            latitudeVar = 'lat'; % this product also contains 'latitude'
            longitudeVar = 'lon'; % this product also contains 'longitude'
        
        % The Cphyto product comes with a MLD. The product information says
        % (https://catalogue.ceda.ac.uk/uuid/6a6ccbb8ef2645308a60dc47e9b8b5fb) 
        % the MLD is from Ifremer. It is a MLD-integrated product.  
        case 'BICEP_Cphyto_nc'
            oceanColourVars = {'C_phyto','C_microphyto','C_nanophyto','C_picophyto','chl_a','mld'};
            oceanColourVarsUnits = {'mg C m-3','mg C m-3','mg C m-3','mg C m-3','mg chla m-3','m'};
            latitudeVar = 'latitude';
            longitudeVar = 'longitude';
    end
    
    % Process each year and month
    for iYear = 1:numel(yearsVector)
        
        thisYear = yearsVector(iYear);
        yearFolderPath = fullfile(fullPathDatasetDir, num2str(thisYear));
        fileNames = dir(fullfile(yearFolderPath,'*.nc'));
        nFiles = length(fileNames);

        % Iterate through each month of the current year
        for iMonth = 1:12
            
            filePath = fullfile(yearFolderPath, fileNames(iMonth).name);
            %S = ncinfo(filePath); % short summary

            % Read longitude and latitude
            % Note: latitude might be unsorted
            lat = ncread(filePath,latitudeVar);
            lon = ncread(filePath,longitudeVar); 
            
            % Adjust coordinates for the area of study
            [idxMinLat,idxMaxLat,idxMinLon,idxMaxLon,lat,lon] =...
                adjustAreaStudyCoordinates(lat,lon,pathAreaStudyShapefile);
            
            % Read data and permute lat and lon
            D = zeros(numel(lat),numel(lon),numel(oceanColourVars));
            for iVar = 1:numel(oceanColourVars)
                % Read the data for the current variable from the .nc file.
                % Adjust read indices based on whether latitude is sorted 
                % or not.
                % Notice that Dtmp expects 3-D data, but the third dimension
                % is just one value, so ends up being a 2-D array.
                if (issorted(lat))
                    Dtmp = ncread(filePath,oceanColourVars{iVar},...
                        [idxMinLon, idxMinLat, 1], [idxMaxLon-idxMinLon+1, idxMaxLat-idxMinLat+1, 1]);
                elseif (~issorted(lat))
                    Dtmp = ncread(filePath,oceanColourVars{iVar},...
                        [idxMinLon, idxMaxLat, 1], [idxMaxLon-idxMinLon+1, idxMinLat-idxMaxLat+1, 1]);
                end
                Dperm = permute(Dtmp,[2 1]); % swap lat and lon
                D(:,:,iVar) = Dperm;
                %figure(1); pcolor(Dperm(:,:,7000)); caxis([0 1]); shading interp; colormap(jet); box on
            end
            
            % Sort lat and lon to have monotonically increasing values and 
            % apply the sorting to the data
            [lat_sort, sortLatIdx] = sort(lat);
            [lon_sort, sortLonIdx] = sort(lon);
            D_sort = D(sortLatIdx,sortLonIdx,:); % lat x lon x vars

            % Initialise the output data array on the first iteration
            if (iYear == 1 && iMonth == 1)
                D_out = NaN(numel(lat_sort),numel(lon_sort),12*numel(yearsVector),numel(oceanColourVars));
            end
            
            % Store the sorted data in the output array at the calculated time index
            idxTime = (iYear - 1) * 12 + iMonth;
            D_out(:,:,idxTime,:) = D_sort(:,:,:);
  
        end % iMonth
 
    end % iYear
    
    % Save information into output array
    bicepData(iDataset).ID = char(datasetNames{iDataset,2});
    bicepData(iDataset).varNames = oceanColourVars;
    bicepData(iDataset).units = oceanColourVarsUnits;
    bicepData(iDataset).dataset = D_out;
    bicepData(iDataset).lat = double(lat_sort);
    bicepData(iDataset).lon = double(lon_sort);
    bicepData(iDataset).time = time;

end % iDataset

fprintf('\n... reading of surface ocean carbon products completed.')
            
end % ncreadTimeseriesBicepData
    