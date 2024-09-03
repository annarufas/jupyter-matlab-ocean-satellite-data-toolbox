
%% Information common to all data sets

fullpathOutputDir = '/Users/Anna/Documents/Academic/Projects/Agile/Agile_datasets/Copernicus/';

% Copernicus Marine username and password 
USERNAME = "arufasblanco";
PASSWORD = "hembef-pypdav-1suSry";

% Define the region of interest and the time range
lon_range = [0 2];
lat_range = [54 55];

% Datasets

server = 'my'; % or "nrt"

datasetID =  {'c3s_obs-oc_glo_bgc-plankton_my_l3-multi-4km_P1D',...     % Global, OC-CCI
              'cmems_obs-oc_glo_bgc-optics_my_l3-multi-4km_P1D',...     % Global, Copernicus-GlobColour
              'cmems_obs-oc_glo_bgc-plankton_my_l3-multi-4km_P1D',...   % " "
              'cmems_obs-oc_glo_bgc-transp_my_l3-multi-4km_P1D',...     % " "
              'cmems_obs-oc_atl_bgc-optics_my_l3-multi-1km_P1D',...     % Regional
              'cmems_obs-oc_atl_bgc-plankton_my_l3-olci-300m_P1D',...   % " "
              'cmems_obs-oc_atl_bgc-plankton_my_l3-multi-1km_P1D',...   % " "
              'cmems_obs-oc_atl_bgc-transp_my_l3-multi-1km_P1D',...     % " "
              'cmems_mod_nws_bgc-chl_my_7km-3D_P1D-m',...               % Numerical model reanalysis
              'cmems_mod_nws_bgc-kd_my_7km-3D_P1D-m',...                % " "
              'cmems_mod_nws_bgc-pft_my_7km-3D-diato_P1D-m',...         % " "
              'cmems_mod_nws_bgc-pft_my_7km-3D-dino_P1D-m',...          % " "
              'cmems_mod_nws_bgc-pft_my_7km-3D-nano_P1D-m',...          % " "
              'cmems_mod_nws_bgc-pft_my_7km-3D-pico_P1D-m',...          % " "
              'cmems_mod_nws_bgc-phyc_my_7km-3D_P1D-m',...              % " "
              'cmems_mod_nws_bgc-pp_my_7km-3D_P1D-m',...                % " "
              'cmems_mod_nws_bgc-no3_my_7km-3D_P1D-m',...               % " "
              'cmems_mod_nws_bgc-o2_my_7km-3D_P1D-m',...                % " "
              'cmems_mod_nws_bgc-po4_my_7km-3D_P1D-m',...               % " "   
              'cmems_mod_nws_bgc-ph_my_7km-3D_P1D-m',...                % " "
              'cmems_mod_nws_bgc-spco2_my_7km-2D_P1D-m'};               % " "              

outputID = {'obs_glob_occci_plk',...
            'obs_glob_copernicus_opt',...
            'obs_glob_copernicus_plk',...
            'obs_glob_copernicus_trns',...
            'obs_reg_opt',...
            'obs_reg_plk_olci',...
            'obs_reg_plk_multi',...
            'obs_reg_trns',...
            'mod_nws_chl',...
            'mod_nws_kd',...
            'mod_nws_diat',...
            'mod_nws_dino',...
            'mod_nws_nano',...
            'mod_nws_pico',...
            'mod_nws_phy',...
            'mod_nws_npp',...
            'mod_nws_no3',...
            'mod_nws_o2',...
            'mod_nws_po4',...
            'mod_nws_ph',...
            'mod_nws_pco2'}; 

outputTag = {'dataset_name','variables','units','dataset','lat','lon','time','depth'};

%% Read data products

for iDataset = 1:length(outputID)

    filename = strcat(outputID{iDataset},'.nc');
%     fileurl = strcat('https://',USERNAME,':',PASSWORD,'@',server,'.cmems-du.eu/thredds/dodsC/',outputID(iDataset));
    disp(filename)

    % List variable names and units
    S = ncinfo(filename); % short summary
    nVars = length(S.Variables);
    varName = cell(nVars,1);
    varUnit = cell(nVars,1);
    for iVar = 1:nVars
        varName{iVar} = S.Variables(iVar).Name;
        iUnit = contains({S.Variables(iVar).Attributes.Name},'units','IgnoreCase',true);
        if (sum(iUnit) > 0) % check that the field 'units' exists before reading it (some variables, like 'flags' don't have units)
            varUnit{iVar} = ncreadatt(filename,varName{iVar},'units');
        end
    end

    % Get idx of dimensional variable names (different files use different
    % variable names (e.g., some files use 'lat', others use 'latitude'))
    iLat = find(contains(string(varName),'lat','IgnoreCase',true));
    iLon = find(contains(string(varName),'lon','IgnoreCase',true));
    iTime = find(contains(string(varName),'time','IgnoreCase',true));
    iDepth = find(contains(string(varName),'depth','IgnoreCase',true));

    % Read longitude, latitude, time and depth (if exists)
    lat = ncread(filename,varName{iLat});
    lon = ncread(filename,varName{iLon});
    time = ncread(filename,varName{iTime}); 
    if ~isempty(iDepth)
        depth = ncread(filename,varName{iDepth}); 
    end

%     % Find the indices of the longitude and latitude values within the desired range
%     lon_indices = find(lon >= lon_range(1) & lon <= lon_range(end));
%     lat_indices = find(lat >= lat_range(1) & lat <= lat_range(end));
    
    % Transform time into a more conventional format
    % I have checked the epochtype options in the files I want to download
    time_units = varUnit{iTime}; %ncreadatt(fileurl,'time','units');
    time_units_num = extract(time_units,digitsPattern);

    if strcmp(time_units,'days since 0000-01-01') 
        epochtype = 'datenum';
    elseif strcmp(time_units,'days since 1900-01-01')
        epochtype = 'excel';
    elseif strcmp(time_units,'days since 1904-01-01')
        epochtype = 'excel1904';     
    elseif strcmp(time_units,'seconds since 1970-01-01') || strcmp(time_units,'seconds since 1970-01-01 00:00:00')
        epochtype = 'posixtime';   
    else
        error('Invalid time unit.');
    end

    time_formatted = datetime(time(:),'ConvertFrom',epochtype,'Epoch',... 
        [time_units_num{1} '-' time_units_num{2} '-' time_units_num{3}]);

    % Get idx of non-structural variables (i.e., ocean colour information)
    isVarColour = zeros(nVars,1);
    for i = 1:nVars
        if (i == iLat | i == iLon | i == iTime | i == iDepth)
            isVarColour(i) = 0;
        else
            isVarColour(i) = 1;
        end
    end
    nColourVars = sum(isVarColour == 1);
    colourVarNames = varName(isVarColour == 1);
    colourVarUnits = varUnit(isVarColour == 1);
    
    % Create 'start' and 'count' arguments for the ncread function. For
    % that, we need to find the arrangement of the dimensional variables in 
    % the ocean colour variables
    for i = 1:nVars
        if (isVarColour(i) == 1)
            iDimLat = find(contains(string({S.Variables(i).Dimensions.Name}),'lat','IgnoreCase',true)); 
            iDimLon = find(contains(string({S.Variables(i).Dimensions.Name}),'lon','IgnoreCase',true)); 
            iDimTime = find(contains(string({S.Variables(i).Dimensions.Name}),'time','IgnoreCase',true)); 
            iDimDepth = find(contains(string({S.Variables(i).Dimensions.Name}),'depth','IgnoreCase',true));
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
    [~,idx] = sort(orderIndices);
    start = startIndices(idx); % start indices ordered
    count = dimCounts(idx); % dimensional information ordered
    
    % Read data and save it in a standardised format, where 1st dim = lat,
    % 2nd dim = lon, 3rd dim = time, 4th dim = depth (just as 'dimCounts'
    % indicates)
    sizeDataset = [dimCounts,nColourVars];
    D = zeros(sizeDataset);
    if ~isempty(iDepth)
        for i = 1:nColourVars
            Dtmp = ncread(filename,colourVarNames{i},start,count);
            Dperm = permute(Dtmp,[iDimLat iDimLon iDimTime iDimDepth]);
            D(:,:,:,:,i) = Dperm;
            %figure(1); pcolor(Dperm(:,:,7000)); caxis([0 1]); shading interp; colormap(jet); box on
        end 
    elseif isempty(iDepth)
        for i = 1:nColourVars
            Dtmp = ncread(filename,colourVarNames{i},start,count);
            Dperm = permute(Dtmp,[iDimLat iDimLon iDimTime]);
            D(:,:,:,i) = Dperm;
            %figure(1); pcolor(Dperm(:,:,7000)); caxis([0 1]); shading interp; colormap(jet); box on
        end
    end

    % Get spatiotemporal variables
    D_lat = lat;
    D_lon = lon;
    D_time = time_formatted;
    if ~isempty(iDepth)
        D_depth = depth;
    else
        D_depth = 0;
    end
    
    % Save information into ocean colour (OC) output array
    % OC is a structure array
    coreName = outputID{iDataset};
    for iTag = 1:length(outputTag)
        sufix = outputTag{iTag};
        if (iTag == 1)
            OC(iDataset).(sprintf('%s',sufix)) = sprintf('%s',coreName);
        elseif (iTag == 2)
            OC(iDataset).(sprintf('%s',sufix)) = colourVarNames;
        elseif (iTag == 3)
            OC(iDataset).(sprintf('%s',sufix)) = colourVarUnits;
        elseif (iTag == 4)
            OC(iDataset).(sprintf('%s',sufix)) = D;
        elseif (iTag == 5)
            OC(iDataset).(sprintf('%s',sufix)) = D_lat;
        elseif (iTag == 6)
            OC(iDataset).(sprintf('%s',sufix)) = D_lon;
        elseif (iTag == 7)
            OC(iDataset).(sprintf('%s',sufix)) = D_time;
        elseif (iTag == 8)
            OC(iDataset).(sprintf('%s',sufix)) = D_depth;
        end    
    end
   
end % iDataset

save(strcat(fullpathOutputDir,'OC.mat'),'OC','-v7.3')

%% Dataset information

% Long story short: we have a large number of oceanographic products, 
% from numerical models and satellite and insitu observations, from the
% past (generally since 1993-01-01) to the present. The models also provide 
% forecast data for 5 to 10 days.
% Depending on the type of products and their data structure, there are 
% different services to access them. All products are available via FTP, 
% the majority of them are now available via MOTU and OPeNDAP (which allows 
% easy subset of the data, when possible, i.e. when the data structure 
% is grid-based). ERDDAP is a specific service that allows to subset 
% INSITU products.
% Both are available through OPeNDAP and MOTU. For these products, you can 
% follow the steps in our articles without any particular problem, just as 
% you did before.

% Using OPENDAP, ERDAP, MOTU: https://help.marine.copernicus.eu/en/articles/4469993-how-to-download-copernicus-marine-products
% Using MATLAB: https://help.marine.copernicus.eu/en/articles/6380431-how-to-access-and-subset-a-dataset-via-opendap-in-matlab
%
% Abbreviations
% obs: observations (satellite observations)
% oc: ocean colour
% bgc: biogeophysical
% nrt: near real time
% l3: level 3 (daily gridded products) 
% l4: level 4 (monthly averaged or gap filled) 
% hr: high resolution
% P1D: daily products
% P1M: monthly products

% Datasets of interest

% Observations, MY, L3, daily
% -------------------------------------------------------------------------
%
% Global (4 km resolution), since 1997
%
%   Ocean Colour Climate Change Initiative (OC-CCI)
%       https://data.marine.copernicus.eu/product/OCEANCOLOUR_GLO_BGC_L3_MY_009_107/description
%       Product ID: OCEANCOLOUR_GLO_BGC_L3_MY_009_107
%       Dataset ID: c3s_obs-oc_glo_bgc-plankton_my_l3-multi-4km_P1D 
%       Variables:  Mass concentration of chlorophyll a in sea water (CHL)
%                   Mass concentration of microphytoplankton expressed as chlorophyll in sea water (CHL)
%                   Mass concentration of nanophytoplankton expressed as chlorophyll in sea water (CHL)
%                   Mass concentration of picophytoplankton expressed as chlorophyll in sea water (CHL)
%
%   Copernicus-GlobColour
%       https://data.marine.copernicus.eu/product/OCEANCOLOUR_GLO_BGC_L3_MY_009_103/description
%       Product ID: OCEANCOLOUR_GLO_BGC_L3_MY_009_103
%       Dataset ID: (1) cmems_obs-oc_glo_bgc-optics_my_l3-multi-4km_P1D 
%                   (2) cmems_obs-oc_glo_bgc-plankton_my_l3-multi-4km_P1D
%                   (3) cmems_obs-oc_glo_bgc-transp_my_l3-multi-4km_P1D 
%       Variables: Volume backwards scattering coefficient of radiative flux in sea water due to particles BBP [m-1] – 1
%                  Volume absorption coefficient of radiative flux in seawater due to dissolved organic matter and non algal particles CDM [m-1] – 1
%                  Chlorophyll-a (CHL) - 2
%                  Phytoplankton Functional types and sizes (PFT) - 2
%                  Volume attenuation coefficient of downwelling radiative flux in sea water KD490 [m-1] - 3
%                  Mass concentration of suspended matter in sea water - 3
%                  Secchi depth of sea water ZSD [m] - 3  
%
% Regional, ATL (1 km resolution – 300 m with olci), since 1997
%       https://data.marine.copernicus.eu/product/OCEANCOLOUR_ATL_BGC_L3_MY_009_113/description
%       Product ID: OCEANCOLOUR_ATL_BGC_L3_MY_009_113
%       Dataset ID: (1) cmems_obs-oc_atl_bgc-optics_my_l3-multi-1km_P1D
%                   (2) cmems_obs-oc_atl_bgc-plankton_my_l3-olci-300m_P1D
%                   (3) cmems_obs-oc_atl_bgc-plankton_my_l3-multi-1km_P1D
%                   (4) cmems_obs-oc_atl_bgc-transp_my_l3-multi-1km_P1D
%       Variables: Volume backwards scattering coefficient of radiative flux in sea water due to particles BBP [m-1] – 1
%                  Volume absorption coefficient of radiative flux in seawater due to dissolved organic matter and non algal particles CDM [m-1] – 1
%                  Mass concentration of chlorophyll a in sea water CHL [mg/m3] – 2,3
%                  Volume attenuation coefficient of downwelling radiative flux in sea water KD490 [m-1] – 4
%                  Mass concentration of suspended matter in sea water SPM [g/m3] – 4
%                  Secchi depth of sea water ZSD [m] – 4
%
% Numerical model reanalysis (biogeochemistry), since 1993
% -------------------------------------------------------------------------
%
% Atlantic-European North West Shelf
%       Reanalysis vs analysis, here: https://marine.copernicus.eu/explainers/glossary)
%       User guide: https://catalogue.marine.copernicus.eu/documents/PUM/CMEMS-NWS-PUM-004-009-011.pdf
%       https://data.marine.copernicus.eu/product/NWSHELF_MULTIYEAR_BGC_004_011/description
%       Product ID: NWSHELF_MULTIYEAR_BGC_004_011
%       Dataset ID: (1) cmems_mod_nws_bgc-chl_my_7km-3D_P1D-m 
%                   (2) cmems_mod_nws_bgc-no3_my_7km-3D_P1D-m
%                   (3) cmems_mod_nws_bgc-o2_my_7km-3D_P1D-m 
%                   (4) cmems_mod_nws_bgc-pft_my_7km-3D-diato_P1D-m
%                   (5) cmems_mod_nws_bgc-pft_my_7km-3D-dino_P1D-m 
%                   (6) cmems_mod_nws_bgc-pft_my_7km-3D-nano_P1D-m
%                   (7) cmems_mod_nws_bgc-pft_my_7km-3D-pico_P1D-m
%                   (8) cmems_mod_nws_bgc-phyc_my_7km-3D_P1D-m
%                   (9) cmems_mod_nws_bgc-po4_my_7km-3D_P1D-m
%                   (10) cmems_mod_nws_bgc-pp_my_7km-3D_P1D-m
%                   (11) cmems_mod_nws_bgc-ph_my_7km-3D_P1D-m
%                   (12) cmems_mod_nws_bgc-spco2_my_7km-2D_P1D-m
%                   (13) cmems_mod_nws_bgc-kd_my_7km-3D_P1D-m
%       Variables: Mass concentration of chlorophyll a in sea water (CHL) - 1
%                  Volume beam attenuation coefficient of radiative flux in sea water attn [m-1] - 2
%                  Mass concentration of diatoms expressed as chlorophyll in sea water (CHL) - 3
%                  Mass concentration of dinoflagellates expressed as chlorophyll in sea water (CHL) - 4
%                  Mass concentration of nanoplankton expressed as chlorophyll in sea water (CHL) - 5
%                  Mass concentration of picophytoplankton expressed as chlorophyll in sea water (CHL) - 6
%                  Mole concentration of phytoplankton expressed as carbon in sea water (PHYC) - 7
%                  Net primary production of biomass expressed as carbon per unit volume in sea water (PP) - 8
%                  Mole concentration of nitrate in sea water (NO3) - 9
%                  Mole concentration of dissolved molecular oxygen in seawater (O2) - 10
%                  Mole concentration of phosphate in sea water (PO4) - 11
%                  Sea water ph reported on total scale (pH) - 12
%                  Surface partial pressure of carbon dioxide in sea water (spCO2) - 13                 

%% % %% 4) get coastline (using ’gshhs’ function)
%  lonRange = [nanmin(lonData(:)),nanmax(lonData(:))];
%  latRange = [nanmin(latData(:)),nanmax(latData(:))];
%  Outline
% % extract coastline and land mask for region Function overview
% Oxygen example
%     % of interest from GSHHG data
%     mch_coast = gshhs(’gshhs_h.b’, latRange, lonRange);
%     mch_river = ...
%        gshhs(’wdb_rivers_h.b’, latRange, lonRange);
%     save(coastFile, ’mch_coast’, ’mch_river’, ’-v7.3’);
% else
%     load(coastFile); % use existing file
% end


%%
% Determination of Spring Bloom Onset Date
% In Alvera-Azcárate (2021), threshold method following (Brody et al., 2013)
% (1) Determination of the median for every year and the date on which [chl] 
% first reaches a value 5% above this median is chosen as the date the spring bloom starts
% (2) A 30-day Gaussian filtered time series is used to avoid short-term 
% variations influencing in the calculation of the spring bloom timing.

% Comparison with in situ chl observations (HPLC)
% Differences between in situ and satellite CHL observations were quantified 
% based on direct match ups within the in situ data archive. Considering all 
% available data, the uncertainty is estimated with the Mean Absolute Difference (MAD) 
% resulting in a value of 1.89 μg/l, which corresponds to a Mean Absolute Percentage Difference (MAPD) of 45.26%. 
% The satellite products tend to overestimate CHL values when CHL is less than 1μg/l resulting in a slope of 0.64 and a relative high scatter (r2 = 0.60) around the 1:1 line for higher CHL values.
