function bicepData = ncreadBICEPtimeseries(bicepDatasetsMetadata,...
    bicepYearsVector,fileNameBicepDataProcessed,fullPathAreaStudyShapefile)

% NCREADBICEPTIMESERIES Read BICEP .nc files, extract data and save the
% data into a Matlab structured array for further processing.
%
%   INPUT:
%       bicepDatasetsMetadata      - structure that contains the name of the different folders where BICEP datasets have been downloaded
%       bicepYearsVector           - defines a common period for all datasets
%       fileNameBicepDataProcessed - name of the .mat file containing bicepData (ensures persistence of data for later use)
%       fullPathAreaStudyShapefile - path to shapefile with our area of study
%
%   OUTPUT:
%       bicepData              - Matlab strcuture with the data read from the BICEP .nc files 
%
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD
%   Anna.RufasBlanco@earth.ox.ac.uk
%
%   Version 1.0 - Completed 3 May 2024
%   Version 1.1 - Updated 6 Jan 2025: simplified terminology
%
% =========================================================================
%%
% -------------------------------------------------------------------------
% PROCESSING STEPS
% -------------------------------------------------------------------------

fprintf("\nReading BICEP time-series products...")

%% Presets

% Create a time vector using the chosen years
time = datetime.empty;
for year = bicepYearsVector(1):bicepYearsVector(end) % iterate through each year from start to end    
    for month = 1:12 % iterate through each month from 1 to 12
        time = [time; datetime(year, month, 1)];
    end
end

% Initialise structure array for output
bicepData = struct('ID', {}, 'varNames', {}, 'units', {}, 'dataset', {},...
    'lat', {}, 'lon', {}, 'time', {});

%% Extract data from BICEP datasets (monthly global arrays for 1998-2020)

for iDataset = 1:size(bicepDatasetsMetadata,1)
    
    datasetFolderName = bicepDatasetsMetadata{iDataset,1};
    datasetName = bicepDatasetsMetadata{iDataset,2};
    
    fullPathDatasetDir = fullfile('.','data','raw','BICEP_data',datasetFolderName);
    fprintf('\nReading data in folder %s',datasetFolderName)
    
    % Define dataset-specific parameters
    switch datasetFolderName
        
        case 'BICEP_POC_nc'
            oceanColourVars = {'POC'};
            oceanColourVarsUnits = {'mg C m-3'};
            latitudeVar = 'lat';
            longitudeVar = 'lon';
            % The POC product is a MLD-integrated product. The MLD used is not
            % provided with the POC product but the product information in 
            % Evers-King et al. (2017) says the MIMOC MLD product has been used.
        
        case 'BICEP_NPP_nc'
            oceanColourVars = {'pp'};
            oceanColourVarsUnits = {'mg C m-2 d-1'};
            latitudeVar = 'lat'; % this product also contains 'latitude' (apart from 'lat')
            longitudeVar = 'lon'; % this product also contains 'longitude' (apart from 'lon')

        case 'BICEP_Cphyto_nc'
            oceanColourVars = {'C_phyto','C_microphyto','C_nanophyto','C_picophyto','chl_a','mld'};
            oceanColourVarsUnits = {'mg C m-3','mg C m-3','mg C m-3','mg C m-3','mg chla m-3','m'};
            latitudeVar = 'latitude';
            longitudeVar = 'longitude';
            % The Cphyto product is a MLD-integrated product. The product information
            % (https://catalogue.ceda.ac.uk/uuid/6a6ccbb8ef2645308a60dc47e9b8b5fb) 
            % says that the MLD used is from Ifremer. 
    end
    
    % Process each year and month
    for iYear = 1:numel(bicepYearsVector)
        
        thisYear = bicepYearsVector(iYear);
        yearFolderPath = fullfile(fullPathDatasetDir, num2str(thisYear));
        fileNames = dir(fullfile(yearFolderPath,'*.nc'));

        % Iterate through each month of the current year
        for iMonth = 1:12
            
            filePath = fullfile(yearFolderPath, fileNames(iMonth).name);
            %S = ncinfo(filePath); % short summary

            % Read longitude and latitude
            lat = ncread(filePath,latitudeVar); % might be unsorted
            lon = ncread(filePath,longitudeVar); 
            
            % Adjust the coordinates (lat, lon) to define the area of 
            % study. The BICEP dataset is global and cannot be cropped 
            % before downloading. Therefore, we have to crop the global 
            % dataset to our area of interest after the download.
            [idxMinLat,idxMaxLat,idxMinLon,idxMaxLon,lat,lon] =...
                adjustAreaStudyCoordinates(lat,lon,fullPathAreaStudyShapefile);
            
            % Read data and permute lat and lon
            D = zeros(numel(lat),numel(lon),numel(oceanColourVars));
            for iVar = 1:numel(oceanColourVars)
                if issorted(lat)
                    Dtmp = ncread(filePath,oceanColourVars{iVar},...
                        [idxMinLon, idxMinLat, 1], [idxMaxLon-idxMinLon+1, idxMaxLat-idxMinLat+1, 1]);
                elseif ~issorted(lat)
                    Dtmp = ncread(filePath,oceanColourVars{iVar},...
                        [idxMinLon, idxMaxLat, 1], [idxMaxLon-idxMinLon+1, idxMinLat-idxMaxLat+1, 1]);
                end
                Dperm = permute(Dtmp,[2 1]); % swap lat and lon
                D(:,:,iVar) = Dperm;
                %figure(); pcolor(Dperm(:,:,7000)); caxis([0 1]); shading interp; colormap(jet); box on
            end
            
            % Sort lat and lon to have monotonically increasing values and 
            % apply the sorting to the data
            [latSort, idxLatSort] = sort(lat);
            [lonSort, idxLonSort] = sort(lon);
            Dsort = D(idxLatSort,idxLonSort,:); % lat x lon x vars

            % Initialise the output data array on the first iteration
            if (iYear == 1 && iMonth == 1)
                Dout = NaN(numel(latSort),numel(lonSort),12*numel(bicepYearsVector),numel(oceanColourVars));
            end
            
            % Store the sorted data in the output array at the calculated time index
            idxTime = (iYear - 1) * 12 + iMonth;
            Dout(:,:,idxTime,:) = Dsort;
            
            clear D Dtmp Dperm Dsort;
  
        end % iMonth
    end % iYear
    
    % Save information into output array
    bicepData(iDataset).ID       = char(datasetName);
    bicepData(iDataset).varNames = oceanColourVars;
    bicepData(iDataset).units    = oceanColourVarsUnits;
    bicepData(iDataset).dataset  = Dout;
    bicepData(iDataset).lat      = double(latSort);
    bicepData(iDataset).lon      = double(lonSort);
    bicepData(iDataset).time     = time;

end % iDataset

fprintf('\n... reading of surface ocean carbon products completed.')

%% Save

fprintf("\n... finished creating BICEP data structure, saving it...")
save(fullfile('.','data','processed',fileNameBicepDataProcessed),'bicepData','-v7.3')
fprintf("\n... saving completed.\n")
            
end % ncreadBICEPtimeseries
    