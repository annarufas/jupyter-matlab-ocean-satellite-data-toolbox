function createAreaStudyShapefile(RADIUS_AREA_STUDY,pathUkOffshoreGcsLicensesShapefile,...
    pathGcsSiteShapefileDir,pathAreaStudyShapefileDir,filenameGcsSiteCentralCoords,...
    shapefileGcsSite,shapefileAreaStudy)

% CREATEAREASTUDYSHAPEFILE Create the monitoring footprint for this study.
%
%   INPUT: 
%       RADIUS_AREA_STUDY                  - radius in km
%       pathUkOffshoreGcsLicensesShapefile - shapefile with NSTA's UKCS offshore licensed sites
%       pathGcsSiteShapefileDir            - directory to store our GCS site shapefile
%       pathAreaStudyShapefileDir          - directory to store our area of study shapefile
%
%   OUTPUT: 
%       filenameGcsSiteCentralCoords - .mat file with our GCS site central coordinates
%       shapefileGcsSite             - shapefile with our GCS site coordinates
%       shapefileAreaStudy           - shapefile with our area of study coordinates
%          
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD
%   Anna.RufasBlanco@earth.ox.ac.uk
%
%   Version 1.0 - Completed 19 April 2024   
%
% =========================================================================
%%
% -------------------------------------------------------------------------
% PROCESSING STEPS
% -------------------------------------------------------------------------

%% Create a shapefile for the Endurance and calculate central coordinates

if ~exist(fullfile(pathGcsSiteShapefileDir,shapefileGcsSite),'file')
    
    fprintf('\nCreating Endurance shapefile...')
    
    idxEndurance = 1; % change accordingly if not using Endurance (Endurance is the first site in the shapefile pathUkOffshoreGcsLicensesCoords)

    % Read UK Continental Shelf Carbon Storage sites
    ukcsGcsSites = m_shaperead(pathUkOffshoreGcsLicensesShapefile); % lat/lon coordinates

    % Extract coordinates for our GCS site and create a shapefile
    gcsSiteLon = ukcsGcsSites.ncst{idxEndurance}(:,1);  
    gcsSiteLat = ukcsGcsSites.ncst{idxEndurance}(:,2);
    gcsSite.Geometry = 'Polygon';
    gcsSite.X = gcsSiteLon; 
    gcsSite.Y = gcsSiteLat;  
    gcsSite.Name = 'Rectangle'; 
    shapewrite(gcsSite,fullfile(pathGcsSiteShapefileDir,shapefileGcsSite,'.shp'))

    % Extract central coordinates for our GCS site
    pgon = polyshape(gcsSiteLon,gcsSiteLat);
    [gcsSiteLonCentre,gcsSiteLatCentre] = centroid(pgon);
    save(fullfile(pathGcsSiteShapefileDir,filenameGcsSiteCentralCoords),...
        'gcsSiteLonCentre','gcsSiteLatCentre')
    
    fprintf('...done.\n')
    
end

%% Create a shapefile for the area of study
   
% Create a boundary box region expanding radiusAreaStudy km to the north 
% and south and radiusAreaStudy km to the east and west of the GCS site. 
% This function creates a shapefile with the lat/lon coordinates 
% corrresponding to the RADIUS_AREA_STUDY km expansion centred around the 
% GCS site.

if ~exist(fullfile(pathAreaStudyShapefileDir,shapefileAreaStudy),'file')
    
    fprintf('Creating area of study shapefile...')

    load(fullfile(pathGcsSiteShapefileDir,filenameGcsSiteCentralCoords),...
        'gcsSiteLonCentre','gcsSiteLatCentre')
   
    ydistDeg_initguess = 2; % how many km are 2ºN?
    xdistDeg_initguess = 2; % how many km are 2ºE?
    distStepDeg = 0.001; % step distance in degrees

    % The following uses an iteration method to approximate the distance to 
    % RADIUS_AREA_STUDY

    % First, minimise xdistDeg
    [arclen,~] = distance([gcsSiteLatCentre, gcsSiteLonCentre],... 
        [gcsSiteLatCentre, gcsSiteLonCentre+xdistDeg_initguess]);
    xdistDeg = xdistDeg_initguess;
    distkm = deg2km(arclen);
    while (distkm > RADIUS_AREA_STUDY)
        xdistDeg = xdistDeg - distStepDeg;
        [arclen,~] = distance([gcsSiteLatCentre, gcsSiteLonCentre],... 
            [gcsSiteLatCentre, gcsSiteLonCentre+xdistDeg]);
        distkm = deg2km(arclen);
        if (distkm <= RADIUS_AREA_STUDY)
            break
        end
    end

    fprintf('\nThe best minimised distance in the x direction is %5.3f km, which corresponds to %5.3fºE.',distkm,xdistDeg)

    % Second, minimise ydistDeg
    [arclen,~] = distance([gcsSiteLatCentre, gcsSiteLonCentre],... 
        [gcsSiteLatCentre+ydistDeg_initguess, gcsSiteLonCentre]);
    ydistDeg = ydistDeg_initguess;
    distkm = deg2km(arclen);
    while (distkm > RADIUS_AREA_STUDY)
        ydistDeg = ydistDeg - distStepDeg;
        [arclen,~] = distance([gcsSiteLatCentre, gcsSiteLonCentre],... 
            [gcsSiteLatCentre+ydistDeg, gcsSiteLonCentre]);
        distkm = deg2km(arclen);
        if (distkm <= RADIUS_AREA_STUDY)
            break
        end
    end

    fprintf('\nThe best minimised distance in the y direction is %5.3f km, which corresponds to %5.3fºN.',distkm,ydistDeg)

    bboxlat = zeros(5,1);
    bboxlon = zeros(5,1);

    bboxlat(1) = gcsSiteLatCentre - ydistDeg;
    bboxlon(1) = gcsSiteLonCentre - xdistDeg;
    bboxlat(2) = gcsSiteLatCentre + ydistDeg;
    bboxlon(2) = bboxlon(1);
    bboxlat(3) = bboxlat(2);
    bboxlon(3) = gcsSiteLonCentre + xdistDeg;
    bboxlat(4) = bboxlat(1);
    bboxlon(4) = bboxlon(3);
    bboxlat(5) = bboxlat(1);
    bboxlon(5) = bboxlon(1);

    bbox.Geometry = 'Polygon';
    bbox.X = bboxlon; 
    bbox.Y = bboxlat;  
    bbox.Name = 'Rectangle'; 
    shapewrite(bbox,fullfile(pathAreaStudyShapefileDir,strcat(shapefileAreaStudy,'.shp')))

    fprintf('\n...done.\n')

end

end