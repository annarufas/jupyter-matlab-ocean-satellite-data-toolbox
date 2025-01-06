function [idxMinLat,idxMaxLat,idxMinLon,idxMaxLon,latVector,lonVector] =... 
    adjustAreaStudyCoordinates(latVector,lonVector,fullPathAreaStudyShapefile)

% ADJUSTAREASTUDYCOORDINATES Adjust latitude and longitude vectors based on 
% the bounding box defined by a shapefile and return indices for the 
% closest matching values, along with the adjusted coordinate vectors.
%
%   INPUT:
%       latVector                  - latitude vector (degress north)
%       lonVector                  - longitude vector (degrees east)
%       fullPathAreaStudyShapefile - shapefile with our area of study
% 
%   OUTPUT:
%       idxMinLat              - index corresponding to min latitude in area of study
%       idxMaxLat              - index corresponding to max latitude in area of study
%       idxMinLon              - index corresponding to min longitude in area of study
%       idxMaxLon              - index corresponding to max longitude in area of study
%       latVector              - adjusted latitude vector (degress north)
%       lonVector              - adjusted longitude vector (degrees east)
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

%% Read bounding box from shapefile

areaStudy = m_shaperead(fullPathAreaStudyShapefile);

if ~isfield(areaStudy, 'MBRx') || ~isfield(areaStudy, 'MBRy')
    error('Shapefile does not contain bounding box fields "MBRx" and "MBRy".');
end

boundingBox.minLat = areaStudy.MBRy(1);
boundingBox.maxLat = areaStudy.MBRy(2);
boundingBox.minLon = areaStudy.MBRx(1);
boundingBox.maxLon = areaStudy.MBRx(2);

% fprintf('[INFO] Bounding box from shapefile: [%.2f %.2f] latitude, [%.2f %.2f] longitude.\n', ...
%     boundingBox.minLat, boundingBox.maxLat, boundingBox.minLon, boundingBox.maxLon);

%% Adjust latitude

[idxMinLat,idxMaxLat,latVector] = adjustCoordinate(latVector,boundingBox.minLat,boundingBox.maxLat);

%% Adjust longitude

[idxMinLon,idxMaxLon,lonVector] = adjustCoordinate(lonVector,boundingBox.minLon,boundingBox.maxLon);

%% Validate results

if isempty(latVector) || isempty(lonVector)
    error('[ERROR] No matching coordinates found for the area of study.');
end

% fprintf('[INFO] Adjusted coordinate indices: Latitude [%d:%d], Longitude [%d:%d]\n', ...
%     idxMinLat, idxMaxLat, idxMinLon, idxMaxLon);

end % adjustAreaStudyCoordinates 

% =========================================================================
%%
% -------------------------------------------------------------------------
% LOCAL FUNCTIONS USED IN THIS SCRIPT
% -------------------------------------------------------------------------

function [idxMin,idxMax,adjustedVector] = adjustCoordinate(coordVector,minValue,maxValue)
    
    % Find closest indices to the bounding box limits
    [~, idxMinCoord] = min(abs(coordVector - minValue));
    [~, idxMaxCoord] = min(abs(coordVector - maxValue));

    % Expand the ranges around the closest indices, which ensures a buffer 
    % around the area of study
    if issorted(coordVector)
        idxMin = max(idxMinCoord - 1, 1); 
        idxMax = min(idxMaxCoord + 1, numel(coordVector));
        adjustedVector = coordVector(idxMin:idxMax);
    else
        idxMin = min(idxMinCoord + 1, numel(coordVector)); 
        idxMax = max(idxMaxCoord - 1, 1);
        adjustedVector = coordVector(idxMax:idxMin); % note reversed indices
    end

    % Validate results
    if isempty(adjustedVector)
        warning('[WARNING] No valid coordinates found within the specified range.');
    end
    
end % adjustCoordinate
