
% ======================================================================= %
%                                                                         %
% This script processes ocean satellite time-series data downloaded as    %
% NetCDF (.nc) files from four repositories, focusing on a specific study %
% area defined by a bounding box.                                         %
%                                                                         %
% The repositories used are:                                              %
%   - ESA Biological Pump and Carbon Exchange Processes (BICEP) project   %
%   - NASA Ocean Color website                                            %
%   - Copernicus Marine Service (CMEMS) Data Store                        %
%   - ESA Ocean Colour Climate Change Initiative (OC-CCI) project         %
%                                                                         %
% The study area is defined using a shapefile centered on a geological    %
% carbon storage (GCS) site called "Endurance", with a 50 km radius       %
% around the site. If you do not have a shapefile for your study area,    %
% you can use the provided function 'createAreaStudyShapefile.m' as a     %
% template. You will need to completely readapt Section 1 in this script  %
% to your needs.                                                          %
%                                                                         %
% The script has 5 sections:                                              %
%   Section 1 - Define the footprint of our area of study                 %
%   Section 2 - Read .nc files from BICEP and store data into a .mat file %
%   Section 3 - Read .nc files from NASA and store data into a .mat file  %
%   Section 4 - Read .nc files from CMEMS and store data into a .mat file %
%   Section 5 - Read .nc files from OCCCI and store data into a .mat file % 
%                                                                         %
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD                             %
%   Anna.RufasBlanco@earth.ox.ac.uk                                       %
%                                                                         %
%   Version 1.0 - Completed 6 Jan 2025                                    %
%                                                                         %
% ======================================================================= %

% Clear workspace, close figures, and add paths to plotting resources
close all; clear all; clc
addpath(genpath(fullfile('code','matlab')))
addpath(genpath(fullfile('data','raw'))); 
addpath(genpath(fullfile('resources','internal')));
addpath(genpath(fullfile('resources','external')));

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 1 - DEFINE THE FOOTPRINT OF OUR AREA OF STUDY
% -------------------------------------------------------------------------

% Set radius for the study area (extending XX km from central point)
radiusAreaStudy = 50; % km

% Define directories for storing output files
fullPathUkOffshoreGcsLicensesShapefile = fullfile('.','data','raw','coords_UKCS_Carbon_Storage_Licences_(ED50)/UKCS_Carbon_Storage_Licences_(ED50)');
fullPathGcsSiteShapefileDir   = fullfile('.','data','interim','coords_endurance');
fullPathAreaStudyShapefileDir = fullfile('.','data','interim','coords_boundarybox');

% Output shapefile names
shapefileNameGcsSite         = 'endurance_2023';
shapefileNameAreaStudy       = 'bbox_100km'; % bounding box = 2 x radiusAreaStudy
fileNameGcsSiteCentralCoords = 'endurance_centre.mat';

% Create shapefiles for the GCS site and the study area
createAreaStudyShapefile(radiusAreaStudy,...
                         fullPathUkOffshoreGcsLicensesShapefile,...
                         fullPathGcsSiteShapefileDir,...
                         fullPathAreaStudyShapefileDir,...
                         fileNameGcsSiteCentralCoords,...
                         shapefileNameGcsSite,...
                         shapefileNameAreaStudy)

% Specify the path to the newly created shapefile. This shapefile will be 
% used in subsequent functions to crop datasets (such as BICEP and OC-CCI) 
% that are downloaded in a global format to the defined area of study.
fullPathAreaStudyShapefile = fullfile(fullPathAreaStudyShapefileDir,shapefileNameAreaStudy);

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 2 - READ .NC FILES FROM BICEP AND STORE DATA INTO A .MAT FILE
% -------------------------------------------------------------------------

% Set the name for the processed BICEP data file
fileNameBicepDataProcessed = 'bicepBbox100km.mat'; % adjust name based on your bbox definition

% Check if .nc files have already been downloaded (using Jupyter Notebook)
fullPathBicepDirectory = fullfile('.','data','raw','BICEP_data');
containsNcFiles = checkForNcFiles(fullPathBicepDirectory);

if containsNcFiles
    % Define BICEP datasets metadata (should match "OUTPUT_DIRECTORY_LIST"
    % from the Jupyter Notebook 'downloadBICEPtimeseries.ipynb')
    bicepDatasetsMetadata = {...
        % {raw data subdirectory name, category name}
        'BICEP_POC_nc',                {'bicep_poc_4km'};
        'BICEP_NPP_nc',                {'bicep_npp_9km'};
        'BICEP_Cphyto_nc',             {'bicep_cphyto_9km'};
    };

    % Define the common years for all datasets (adjust depending on release version)
    bicepYearsVector = 1998:2020; 

    % Read the BICEP .nc files and store them into a .mat file and in the
    % workspace
    bicepData = ncreadBICEPtimeseries(bicepDatasetsMetadata,...
                                      bicepYearsVector,...
                                      fileNameBicepDataProcessed,...
                                      fullPathAreaStudyShapefile);

end

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 3 - READ .NC FILES FROM NASA AND STORE DATA INTO A .MAT FILE
% -------------------------------------------------------------------------

% Set the name for the processed NASA data file
fileNameNasaDataProcessed = 'nasaBbox100km.mat'; % adjust name based on your bbox definition

% Check if .nc files have already been downloaded (using Jupyter Notebook)
fullPathNasaDirectory = fullfile('.','data','raw','NASA_data');
containsNcFiles = checkForNcFiles(fullPathNasaDirectory);

if containsNcFiles
    % Define NASA datasets metadata (should match "DATA_SUBDIRS"
    % from the Jupyter Notebook 'downloadNASAtimeseries.ipynb')
    nasaDatasetsMetadata = {...
        % {raw data subdirectory name,                  category name}
        'data_timeseries_areastudy_NASA_aquamodis_nc',  {'aquamodis_4km'};
        'data_timeseries_areastudy_NASA_meris_nc',      {'meris_4km'};
        'data_timeseries_areastudy_NASA_viirssnpp_nc',  {'viirssnpp_4km'};
        'data_timeseries_areastudy_NASA_viirsjpss1_nc', {'viirsjpss1_4km'};
    };

    % Read the NASA .nc files and store them into a .mat file and in the
    % workspace
    nasaData = ncreadNASAtimeseries(nasaDatasetsMetadata,...
                                    fileNameNasaDataProcessed);
    
end

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 4 - READ .NC FILES FROM CMEMS AND STORE DATA INTO A .MAT FILE
% -------------------------------------------------------------------------

% Set the name for the processed CMEMS data file
fileNameCmemsDataProcessed = 'cmemsBbox100km.mat'; % adjust name based on your bbox definition

% Check if .nc files have already been downloaded (using Jupyter Notebook)
fullPathCmemsDirectory = fullfile('.','data','raw','CMEMS_data');
containsNcFiles = checkForNcFiles(fullPathCmemsDirectory);

if containsNcFiles
    % Define CMEMS datasets metadata (should match "LIST_DATASET_IDS"
    % from the Jupyter Notebook 'downloadCMEMStimeseries.ipynb')   
    cmemsDatasetsMetadata = {...
        'obs_satell_glob_cmems_olci_4km_plk.nc',...
        'obs_satell_glob_cmems_olci_4km_trns.nc',...
        'obs_satell_reg_cmems_multi_1km_plk.nc',...
        'obs_satell_reg_cmems_multi_1km_opt.nc',...
        'obs_satell_reg_cmems_multi_1km_trns.nc',...
        'obs_satell_reg_cmems_olci_300m_plk.nc',...
        'mod_bgc_reg_chl.nc',...
        'mod_bgc_reg_diat.nc',...
        'mod_bgc_reg_dino.nc',...
        'mod_bgc_reg_nano.nc',...
        'mod_bgc_reg_pico.nc',...
        'mod_bgc_reg_phy.nc',...
        'mod_bgc_reg_npp.nc',...
        'mod_bgc_reg_kd.nc',...
        'mod_bgc_reg_no3.nc',...
        'mod_bgc_reg_po4.nc',...
        'mod_bgc_reg_o2.nc',...
        'mod_bgc_reg_ph.nc',...
        'mod_bgc_reg_pco2.nc',...
        'mod_phy_reg_mld.nc',...
        'mod_phy_reg_sal.nc',...
        'mod_phy_reg_temp.nc',...
        'mod_phy_reg_ssh.nc',...
        'mod_phy_reg_velo.nc'...
    };

    % Read the CMEMS .nc files and store them into a .mat file and in the
    % workspace
    cmemsData = ncreadCMEMStimeseries(cmemsDatasetsMetadata,...
                                      fileNameCmemsDataProcessed);
    
end

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 5 - READ .NC FILES FROM OC-CCI AND STORE DATA INTO A .MAT FILE
% -------------------------------------------------------------------------

% Set the name for the processed OC-CCI data file
fileNameOccciDataProcessed = 'occciBbox100km.mat'; % adjust name based on your bbox definition

% Check if .nc files have already been downloaded (using Jupyter Notebook)
fullPathOcciDirectory = fullfile('.','data','raw','OCCCI_data');
containsNcFiles = checkForNcFiles(fullPathOcciDirectory);

if containsNcFiles
    % Define OC-CCI datasets metadata (should match "OUTPUT_FILENAME_LIST"
    % from the Jupyter Notebook 'downloadOCCCItimeseries.ipynb') 
    occciDatasetsMetadata = {... 
        % {category name, datasets in the category}
        'occci_1km_1day', {'occci_1km_1day_chl_9710.nc',...
                           'occci_1km_1day_chl_1024.nc',...
                           'occci_1km_1day_waterclass_01to03_9710.nc',...
                           'occci_1km_1day_waterclass_01to03_1024.nc',...
                           'occci_1km_1day_waterclass_04to06_9710.nc',...
                           'occci_1km_1day_waterclass_04to06_1024.nc',...
                           'occci_1km_1day_waterclass_07to09_9710.nc',...
                           'occci_1km_1day_waterclass_07to09_1024.nc',...
                           'occci_1km_1day_waterclass_10to12_9710.nc',...
                           'occci_1km_1day_waterclass_10to12_1024.nc',...
                           'occci_1km_1day_waterclass_13to14_9710.nc',...
                           'occci_1km_1day_waterclass_13to14_1024.nc'};
        'occci_4km_1day', {'occci_4km_1day_chl_9710.nc',...
                           'occci_4km_1day_chl_1024.nc'};
        'occci_4km_5day', {'occci_4km_5day_chl_9710.nc',...
                           'occci_4km_5day_chl_1024.nc'};
        'occci_4km_8day', {'occci_4km_8day_chl_9710.nc',...
                           'occci_4km_8day_chl_1024.nc'};
    };

    % Read the OC-CCI .nc files and store them into a .mat file and in the
    % workspace
    occciData = ncreadOCCCItimeseries(occciDatasetsMetadata,...
                                      fileNameOccciDataProcessed,...
                                      fullPathAreaStudyShapefile);
                                  
end

% =========================================================================
%%
% -------------------------------------------------------------------------
% LOCAL FUNCTIONS USED IN THIS SCRIPT
% -------------------------------------------------------------------------

function containsNcFiles = checkForNcFiles(directoryPath)

    % Initialize the result as false (no .nc files found)
    containsNcFiles = false;

    % Get a list of all files and folders in the directory
    files = dir(directoryPath);
    
    % Remove the '.' and '..' entries
    files = files(~ismember({files.name}, {'.', '..'}));

    % Loop through each entry in the directory
    for i = 1:length(files)
        
        fullPath = fullfile(directoryPath, files(i).name);
        
        if files(i).isdir
            % If the entry is a directory, recursively check it
            if checkForNcFiles(fullPath)
                containsNcFiles = true;
                return;  % Stop searching once a .nc file is found
            end
        else
            % If the entry is a file, check if it has a .nc extension
            [~, ~, ext] = fileparts(fullPath);
            if strcmpi(ext, '.nc')
                containsNcFiles = true;
                return;  % Stop searching once a .nc file is found
            end
        end
    end
end
