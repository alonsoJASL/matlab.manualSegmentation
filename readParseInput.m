function [dataIn,attributes]=readParseInput(baseFileName)
%                   READ AND PARSE INPUT
%
% Parse input from folder, or have it chosen by the user with a GUI.
% INPUT:
%               baseFileName := (String) Full path to where the dataset or
%                              image is. If folder, then the entire dataset
%                               is loaded into memory, otherwise just the
%                               file referenced is read.
%
% OUTPUT:
%                    dataIn := (matrix) 4D matrix of size: Height, Width,
%                               Depth and numFrames. Attributes of image
%                               (or dataset) are stored in attributes
%                               structure.
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
        button = questdlg('What are we going to be dealing with?',...
            'Select Input Type','Multiple Files','Single File',...
            'Cancel','Cancel');
        if strcmp(button(1),'C')
            % no data to read, exit
            dataIn=[];attributes=[];
            return;
        else
            switch button
                case 'Multiple Files'
                    [folder] = uigetdir('*.*', ...
                        'Select the folder that contains the file(s)');
                    if folder ~=  0
                        [dataIn,attributes] = readParseInput(folder);
                    else
                        errorMessage = ...
                            sprintf('Error: %s does not exist.',...
                            folder);
                        uiwait(warndlg(errorMessage));
                        dataIn=[];attributes=[];
                        return;
                    end
                case 'Single File'
                    [baseFileName,folder] = uigetfile('*.*',...
                        'Select the folder that contains the file.');
                    fullFileName = fullfile(folder, baseFileName);
                    % Check if file exists.
                    if ~exist(fullFileName, 'file')
                        errorMessage = ...
                            sprintf('Error: %s does not exist.',...
                            fullFileName);
                        uiwait(warndlg(errorMessage));
                        dataIn=[]; attributes=[];
                        return;
                    end
                    
                    [dataIn, attributes] = readParseInput(fullFileName);
            end
        end
        
    case 1
        if isdir(baseFileName)
            
            dirlist = dir(strcat(baseFileName,'*.tif'));
            filenames = {dirlist.name};
            
            N = length(filenames);
            
            if N>0
                II = imfinfo(strcat(baseFileName,'/', filenames{end}));
                
                if strcmp(II(1).ColorType,'truecolor')
                    dataIn = zeros(II(1).Height, II(1).Width, 3,N);
                    for i=1:N
                        dataIn(:,:,:,i) = imread(strcat(...
                            baseFileName,'/',filenames{i}));
                    end
                    attributes = struct('fileName', baseFileName,...
                        'isDir', true, ...
                        'Height', II(1).Height, ...
                        'Width',II(1).Width, 'Depth', size(II,1),...
                        'isRGB', true, 'numImages',N);
                else
                    dataIn = zeros(II(1).Height, II(1).Width, size(II,1),N);
                    
                    for i=1:N
                        if isempty(findstr(filenames{i},'.txt'))
                            for j=1:size(II,1)
                                dataIn(:,:,j,i) = imread(strcat(...
                                    baseFileName,'/',filenames{i}),j);
                            end
                        end
                    end
                    attributes = struct('fileName', baseFileName,...
                        'isDir', true, ...
                        'Height', II(1).Height, ...
                        'Width',II(1).Width, 'Depth', size(II,1),...
                        'isRGB', false,'numImages',N);
                end
                dataIn = double(dataIn)./max(double(dataIn(:)));
                
            else
                errorMessage = ...
                    sprintf('Error: %s\n does not contain files.',...
                    baseFileName);
                uiwait(warndlg(errorMessage));
                dataIn=[]; attributes=[];
            end
            
        else
            if ~exist(baseFileName, 'file')
                % File doesn't exist -- didn't find it there.
                errorMessage = ...
                    sprintf('Error: %s\n does not exist.',...
                    baseFileName);
                uiwait(warndlg(errorMessage));
                dataIn=[]; attributes=[];
                return;
            end
            
            try
                II = imfinfo(baseFileName);
                
                % We check if the image is read as an RGB.
                if strcmp(II(1).ColorType,'truecolor')
                    if size(II,1) > 1
                        dataIn = zeros(II(1).Height, II(1).Width, ...
                            3, size(II,1));
                        for j=1:size(II,1)
                            dataIn(:,:,:,j) = imread(baseFileName,j);
                        end
                    else
                        dataIn = imread(baseFileName);
                    end
                else
                    dataIn = zeros(II(1).Height, II(1).Width, size(II,1));
                    for j=1:size(II,1)
                        dataIn(:,:,j) = imread(baseFileName,j);
                    end
                end
                dataIn = double(dataIn)./max(double(dataIn(:)));
                
                if strcmp(II(1).ColorType,'truecolor')
                    attributes = struct('fileName', baseFileName,...
                        'isDir', false, ...
                        'Height', II(1).Height, ...
                        'Width',II(1).Width, 'Depth', 3,...
                        'isRGB', true, ...
                        'numImages',size(II,1));
                else
                    attributes = struct('fileName', baseFileName,...
                        'isDir', false, ...
                        'Height', II(1).Height, ...
                        'Width',II(1).Width, 'Depth', size(II,1),...
                        'isRGB', false, 'numImages',1);
                end
            catch e
                if contains(e.identifier, 'whatFormat')
                    currData = load(baseFileName);
                    fn = fieldnames(currData);
                    % specific case for (dataG, dataL) pairs
                    if length(fn)>1 && sum(contains(fn, 'data'))>0
                        try
                            r = currData.dataR;
                            g = currData.dataG;
                        catch e
                            r = currdata.dataL;
                            g = currData.dataG;
                        end
                        dataIn = cat(3, r,g,zeros(size(r)));
                        
                    else
                        dataIn = currData.(fn{1});
                        
                    end
                    attributes.fileName = baseFileName;
                    attributes.isDir = false;
                    attributes.Height = size(dataIn, 1);
                    attributes.Width = size(dataIn, 2);
                    attributes.Depth = size(dataIn, 3);
                    attributes.isRGB = size(dataIn,3) == 3;
                    attributes.numImages = 1;
                    
                else
                    fprintf('%s: ERROR, could not read file.\n', mfilename);
                end
                
            end
            
        end
end