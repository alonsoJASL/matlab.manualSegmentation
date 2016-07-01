function [dataExample,attributes]=readDatasetDetails(baseFileName)
%                   READ AND PARSE INPUT
%
% Parse input from folder, or have it chosen by the user with a GUI.
%
%           [dataExample,attributes]=readDatasetDetails(baseFileName)
%
% 
% INPUT:
%               baseFileName := (String) Full path to where the dataset or
%                              image is. Only one image from the dataset
%                              will be loaded into memory.
%
% OUTPUT:
%               dataExample := (matrix) First frame of the dataset for tests. 
%                attributes := (Struct) Structure with following fields:
%
%                   attributes.fileName := (string) full path to folder or 
%                              file.
%                   attributes.isDir := (boolean) True if folder, false if
%                              single image.
%                   attributes.Height := (int) Height (rows) of the image(s).
%                   attributes.Width := (int) Width (columns) of the
%                              image(s).
%                   attributes.Depth := (int) Either Z-axis or RGB values
%                              of image(s).
%                   attributes.isRGB := (boolean) true if image is RGB.
%                   attributes.numImages := (int) number of frames in
%                               dataset.
%
% Code part of the matlab.manualSegmentation git repository, licensed under
% the GNU General Public License v3. Found at: 
% 
%       <https://github.com/alonsoJASL/matlab.manualSegmentation.git> 
%

switch nargin
    case 0
        
        [folder] = uigetdir('*.*', ...
            'Select the folder that contains the file(s)');
        if folder ~=  0
            [dataExample,attributes] = readDatasetDetails(folder);
        else
            errorMessage = ...
                sprintf('Error: %s does not exist.',...
                folder);
            uiwait(warndlg(errorMessage));
            dataExample=[];attributes=[];
            return;
        end
    case 1
        if isdir(baseFileName)
            
            dirlist = dir(strcat(baseFileName,'*.tif'));
            filenames = {dirlist.name};
            
            N = length(filenames);
            
            if N>0
                II = imfinfo(strcat(baseFileName,'/', filenames{end}));
                
                if strcmp(II(1).ColorType,'truecolor')
                    dataExample = zeros(II(1).Height, II(1).Width, 3,1);
                    
                    dataExample(:,:,:) = imread(strcat(...
                        baseFileName,'/',filenames{1}));
                    attributes = struct('fileName', baseFileName,...
                        'isDir', true, ...
                        'Height', II(1).Height, ...
                        'Width',II(1).Width, 'Depth', size(II,1),...
                        'isRGB', true, 'numImages',N, ...
                        'names', filenames);
                else
                    dataExample = zeros(II(1).Height, II(1).Width, size(II,1));
                    
                    if isempty(findstr(filenames{1},'.txt'))
                        for j=1:size(II,1)
                            dataExample(:,:,j) = imread(strcat(...
                                baseFileName,'/',filenames{1}),j);
                        end
                    end
                    attributes = struct('fileName', baseFileName,...
                        'isDir', true, ...
                        'Height', II(1).Height, ...
                        'Width',II(1).Width, 'Depth', size(II,1),...
                        'isRGB', false,'numImages',N, ...
                        'names', filenames);
                end
                dataExample = double(dataExample)./max(double(dataExample(:)));
                
            else
                errorMessage = ...
                    sprintf('Error: %s\n does not contain files.',...
                    baseFileName);
                uiwait(warndlg(errorMessage));
                dataExample=[]; attributes=[];
            end
            
        else
            errorMessage = ...
                sprintf('Error: %s\n Not a folder.',...
                baseFileName);
            uiwait(warndlg(errorMessage));
            dataExample=[]; attributes=[];
        end
end
end
            
