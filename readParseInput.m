function [dataIn,attributes]=readParseInput(baseFileName)
%                   READ AND PARSE INPUT
%
% Parse input from filder, or have it chosen by the user with a GUI.
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
            dirlist = dir(baseFileName);
            filenames = {dirlist.name};
            filenames(1:2) = []; % Remove '.' and '..' from the list.
            
            if strcmp(filenames{1},'.DS_Store')
                filenames(1) = [];
            end
            
            N = length(filenames);
            
            if N>0
                II = imfinfo(strcat(baseFileName,'/', filenames{end-1}));
                
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
        end
        
end
end