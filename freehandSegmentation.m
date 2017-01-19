function [dataBin, binAtt] = freehandSegmentation(dataIn, imAtt, colours)
%           FREEHAND SEGMENTATION FUNCTION
% Do manual segmentation on images to obtain ground truth data.
%
% usage:
%
%            [dataBin] = freehandSegmentation(dataIn);
%            [dataBin] = freehandSegmentation(dataIn, imAtt);
%    [dataBin, binAtt] = freehandSegmentation([], imAtt);
%
% INPUT:
%           dataIn := matrix (2, 3 or 4D) that contains the images.
%                   The size of said matrices can be:
%                       - [Heigh, Width, 1, 1] for 2D
%                       - [Height, Width, 1, numImages] for multiple 2D
%                       - [Height, Width, Depth] for single 3D
%                       - [Height, Width, Depth, numImages] for multiple 3D
%                     Notice how dataIn should always be a 4D matrix,
%                     unless you include an attributes structure in your
%                     input parameters.
%            imAtt := structure that specifies image attributes. Should
%                     contain:
%                       - fileName -> path to folder or filename.
%                       - Height  |
%                       - Width   |-> Dimensions of images
%                       - Depth   |
%                       - numImages -> number of images
%
% OUTPUT:
%           dataBin := binary image that resulted from the segmentation of
%                   the images. It is such that:
%               size(dataBin) = [Height, Width, Depth, numImages];
%
global KEY_IS_PRESSED WHICH_KEY;
KEY_IS_PRESSED = 0;
WHICH_KEY = [];
% Default colour map
cmap=jet;
cmap(1,:)=0;

switch nargin
    case 1
        if isempty(dataIn)
            % Working with full dataset one image at the time.
            disp('Error. No input image or attributes specified.');
            help freehandSegmentation ;
            dataBin = [];
            return;
        else
            switch ndims(dataIn)
                case 2
                    [imAtt.Height, imAtt.Width] = size(dataIn);
                    imAtt.Depth = 1;
                    imAtt.numImages = 1;
                case 3
                    button = questdlg('What are we going to be dealing with?',...
                        'Select Input Type','Multiple 2D images','Single 3D image',...
                        'Cancel','Cancel');
                    switch button
                        case 'Multiple 2D images'
                            imAtt.Height = size(dataIn,1);
                            imAtt.Widtoutputfolfderh = size(dataIn,2);
                            imAtt.Depth = 1;
                            imAtt.numImages = size(dataIn,3);
                            dataIn = reshape(dataIn, imAtt.Height, imAtt.Width,...
                                1, imAtt.numImages);
                        case 'Single 3D image'
                            [imAtt.Height, imAtt.Width, imAtt.Depth] = size(dataIn);
                            imAtt.numImages = 1;
                        otherwise
                            disp('You canceled the operations');
                            dataBin = [];
                    end
                case 4
                    [imAtt.Height, imAtt.Width, imAtt.Depth, imAtt.numImages] = ...
                        size(dataIn);
                    button = questdlg('Are these multiple RGB images??',...
                        'Select Input Type','Multiple RGBs!',...
                        'No, just a single 3D',...
                        'Cancel','Cancel');
                    switch button
                        case 'Multiple RGBs!'
                            imAtt.numImages = size(dataIn,4);
                            imAtt.isRGB = 1;
                        case 'No, just a single 3D'
                            imAtt.isRGB = 0;
                        otherwise
                            disp('You canceled the operations');
                            dataBin = [];
                            return;
                    end
                otherwise
                    disp('Error. Wrong dimensions of input data.');
                    dataBin = [];
                    return;
            end
        end
    case 2
        % Get full dataset details.
        if isempty(dataIn)
            [~,imAtt] = readDatasetDetails(imAtt(1).fileName);
        end
    case 3
        % Get full dataset details.
        [~,imAtt] = readDatasetDetails(imAtt(1).fileName);
        cmap = colours;
    otherwise
        % Working with full dataset one image at the time.
        disp('Error. Wrong input arguments.');
        help freehandSegmentation ;
        dataBin = [];
        return;
end

% deal with Warinings.
set(0,'recursionlimit',750);

numImages = imAtt(1).numImages;
defOverlapping = 0; % to test overlapping at the end of the code.
if numImages > 5
    str = strcat('How many (random) images do you want to segment? [Default=',...
        num2str(numImages),']: ');
    a = input(str);
    
    if ~isempty(a)
        if length(a)>1
            numImages = length(a);
            randomIndex = sort(a);
            imAtt = imAtt(randomIndex);
            disp('Segmenting the following images:');
            disp({imAtt.names});
        else
            numImages = a;
            randomIndex = sort(randi(imAtt(1).numImages,a,1));
            imAtt = imAtt(randomIndex);
            disp('Segmenting the following images:');
            disp({imAtt.names});
        end
    end
end

bigDataset = isempty(dataIn);

if bigDataset == true
    dataBin = zeros(imAtt(1).Height, imAtt(1).Width, imAtt(1).Depth, 1);
    binaryImageSum = zeros(imAtt(1).Height, imAtt(1).Width);
    
    overlappingDataset = 0;
    
    outputfolder = strcat(imAtt(1).fileName(1:end-1), '_GT/');
    outputfolderAtt = strcat(outputfolder(1:end-1),'_mat_Ha/');
    
    if ~isdir(outputfolder)
        mkdir(outputfolder)
    end
    if ~isdir(outputfolderAtt)
        mkdir(outputfolderAtt);
    end
    
    if imAtt(1).isRGB == true
        numCells = zeros(3,numImages);
    else
        numCells = zeros(imAtt(1).Depth, numImages);
    end
    
    for i=1:numImages
        [dataIn, auxAtt] = readParseInput(strcat(imAtt(1).fileName,...
            imAtt(i).names));
        outputname = strcat(imAtt(i).names(1:end-4),'.mat');
        
        for j=1:auxAtt.Depth
            grayImage = dataIn(:,:,j);
            
            if imAtt(1).isRGB == 0
                imagesc(grayImage);
                colormap(cmap);
                axis on;
            else
                imshow(dataIn);
                axis on;
            end
            
            str = strcat('Original Grayscale Image: ',num2str(i), ...
                ' Layer: ', num2str(j));
            title(str , 'FontSize', 18);
            set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
            set(gcf, 'KeyPressFcn', @myKeyPressFcn); % Get key press for ending.
            
            
            
            if i==1 && j==1
                message = sprintf(['Left click and hold to begin drawing.' ...
                    '\nSimply press any key before you do the last cell.']);
                uiwait(msgbox(message));
            end
            
            %for k=1:5 % ONLY FOR DEBUGGING CODE
            while ~KEY_IS_PRESSED
                
                hFH = imfreehand();
                % Create a binary image ("mask") from the ROI object.
                %xy = hFH.getPosition;
                newCell = hFH.createMask();
                
                if overlappingDataset == 0
                    testOverlapping = bitand(binaryImageSum, newCell);
                else
                    aux = changeOverlapRepresentation(binaryImageSum);
                    aux = aux>0;
                    testOverlapping = bitand(aux, newCell);
                end
                
                if sum(testOverlapping(:)) > 0
                    % A wild overlapping cell just appeared!
                    defOverlapping = true;
                    if overlappingDataset == 0
                        str = strcat('Overlapping of cells detected.', ...
                            ' How should we deal with it?');
                        button = questdlg(str, 'Select Input Type',...
                            'Yes, this is an overlapping dataset.',...
                            'Oopsie! Must have done something wrong',...
                            'Cancel','Cancel');
                    else
                        button = 'yes';
                    end
                    
                    switch button
                        case {'Yes, this is an overlapping dataset.', 'yes'}
                            % deal with it!
                            overlappingDataset = 1;
                            if size(binaryImageSum,3) > 1
                                % We've already done the breaking up of the
                                % cells into layers.
                                lastLabel = unique(binaryImageSum);
                                lastLabel = lastLabel(end);
                                newCell = newCell.*getPrimes(lastLabel,1);
                                binaryImageSum(:,:,end+1) = newCell;
                                numCells(j,i) = numCells(j,i)+1;
                            else
                                % We have to break up the image into different
                                % cell layers
                                binaryImageSum = bwlabeln(binaryImageSum);
                                binaryImageSum = ...
                                    changeGroundTruthLabels(binaryImageSum);
                                [binaryImageSum] = ...
                                    changeOverlapRepresentation(binaryImageSum);
                                binaryImageSum(:,:,end+1) = newCell;
                                numCells(j,i) = numCells(j,i)+1;
                            end
                        otherwise
                            overlappingDataset = 0;
                            newCell = zeros(hFH.createMask());
                    end
                elseif overlappingDataset == 1
                    % keep stacking the layers of cells!
                    lastLabel = unique(binaryImageSum);
                    lastLabel = lastLabel(end);
                    newCell = newCell.*getPrimes(lastLabel,1);
                    binaryImageSum(:,:,end+1) = newCell;
                    numCells(j,i) = numCells(j,i)+1;
                else
                    % do nothing.
                    binaryImageSum = bitor(binaryImageSum,newCell);
                    numCells(j,i) = numCells(j,i)+1;
                end
            end
            
            if overlappingDataset == 1
                dataBin(:,:,j) = changeOverlapRepresentation(binaryImageSum);
                save(strcat(outputfolder,outputname),'dataBin');
            else
                dataBin(:,:,j) = binaryImageSum;
                save(strcat(outputfolder,outputname),'dataBin');
            end
            
            
            % reset binaryImage and everything else!
            binaryImageSum = zeros(size(dataIn(:,:,1,1)));
            clear newCell;
            overlappingDataset = 0;
            KEY_IS_PRESSED = 0;
            close all;
        end
    end
    
else
    dataBin = zeros(imAtt.Height, imAtt.Width, imAtt.Depth, numImages);
    binaryImageSum = zeros(imAtt.Height, imAtt.Width);
    
    overlappingDataset = 0;
    numCells = zeros(imAtt.Depth,numImages);
    
    for i=1:numImages
        for j=1:imAtt.Depth
            grayImage = dataIn(:,:,j,i);
            
            if imAtt.isRGB == 0
                imagesc(grayImage);
                colormap(cmap);
                axis on;
            elseif imAtt.numImages > 1
                imshow(dataIn(:,:,:,i));
                axis on;
            else
                imshow(dataIn);
                axis on;
            end
            
            str = strcat('Original Grayscale Image: ',num2str(i), ...
                ' Layer: ', num2str(j));
            title(str , 'FontSize', 18);
            set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
            set(gcf, 'KeyPressFcn', @myKeyPressFcn); % Get key press for ending.
            
            if i==1 && j==1
                message = sprintf(['Left click and hold to begin drawing.' ...
                    '\nSimply press any key before you do the last cell.']);
                uiwait(msgbox(message));
            end
            
            %for k=1:10 % ONLY FOR DEBUGGING CODE
            while ~KEY_IS_PRESSED
                hFH = imfreehand();
                % Create a binary image ("mask") from the ROI object.
                %xy = hFH.getPosition;
                newCell = hFH.createMask();
                
                if overlappingDataset == 0
                    testOverlapping = bitand(binaryImageSum, newCell);
                else
                    aux = changeOverlapRepresentation(binaryImageSum);
                    aux = aux>0;
                    testOverlapping = bitand(aux, newCell);
                end
                
                if sum(testOverlapping(:)) > 0
                    % A wild overlapping cell just appeared!
                    defOverlapping = true;
                    if overlappingDataset == 0
                        str = strcat('Overlapping of cells detected.', ...
                            ' How should we deal with it?');
                        button = questdlg(str, 'Select Input Type',...
                            'Yes, this is an overlapping dataset.',...
                            'Oopsie! Must have done something wrong',...
                            'Cancel','Cancel');
                    else
                        button = 'yes';
                    end
                    
                    switch button
                        case {'Yes, this is an overlapping dataset.', 'yes'}
                            % deal with it!
                            overlappingDataset = 1;
                            if size(binaryImageSum,3) > 1
                                % We've already done the breaking up of the
                                % cells into layers.
                                lastLabel = unique(binaryImageSum);
                                lastLabel = lastLabel(end);
                                newCell = newCell.*getPrimes(lastLabel,1);
                                binaryImageSum(:,:,end+1) = newCell;
                                numCells(j,i) = numCells(j,i)+1;
                            else
                                % We have to break up the image into different
                                % cell layers
                                binaryImageSum = bwlabeln(binaryImageSum);
                                binaryImageSum = ...
                                    changeGroundTruthLabels(binaryImageSum);
                                [binaryImageSum] = ...
                                    changeOverlapRepresentation(binaryImageSum);
                                binaryImageSum(:,:,end+1) = newCell;
                                numCells(j,i) = numCells(j,i)+1;
                            end
                        otherwise
                            overlappingDataset = 0;
                            newCell = zeros(hFH.createMask());
                    end
                elseif overlappingDataset == 1
                    % keep stacking the layers of cells!
                    lastLabel = unique(binaryImageSum);
                    lastLabel = lastLabel(end);
                    newCell = newCell.*getPrimes(lastLabel,1);
                    binaryImageSum(:,:,end+1) = newCell;
                    numCells(j,i) = numCells(j,i)+1;
                else
                    % do nothing.
                    binaryImageSum = bitor(binaryImageSum,newCell);
                    numCells(j,i) = numCells(j,i)+1;
                end
            end
            
            if overlappingDataset == 1
                dataBin(:,:,j,i) = changeOverlapRepresentation(binaryImageSum);
            else
                dataBin(:,:,j,i) = binaryImageSum;
            end
            
            % reset binaryImage and everything else!
            binaryImageSum = zeros(size(dataIn(:,:,1,1)));
            clear newCell;
            overlappingDataset = 0;
            KEY_IS_PRESSED = 0;
            close all;
        end
    end
end

if nargout > 1
    binAtt = imAtt(1);
    binAtt.names = [];
    binAtt.numCells = numCells;
    if defOverlapping == 1
        binAtt.overlap = true;
        binAtt.overlaptype = 'primes';
        
        labelsGT = unique(dataBin);
        overlapindx = find(~isprime(labelsGT));
        overlapindx(1) = [];
        
        binAtt.overlapindx = overlapindx;
        overlaplabels = labelsGT(overlapindx);
        binAtt.overlaplabels = overlaplabels;
    end
    if bigDataset == true
        binAtt.outputfolder = outputfolder;
        binAtt.handles = outputfolderAtt;
        if ~isempty(a)
            binAtt.names = randomIndex;
        end
    end
    if exist('outputfolderAtt')
        save(strcat(outputfolderAtt,'handles.mat'), 'binAtt');
    end
end

end

function myKeyPressFcn(hObject, event)
global KEY_IS_PRESSED WHICH_KEY;

% message = ['Key pressed, segment your last cell or'...
%     '\nclick on any of the already segmented cells.'];
% uiwait(msgbox(message));

button = questdlg('Key pressed, please indicate what to do:',...
    'Select next action:','Undo...','Clear all (start over)',...
    'Finished','Finished');
switch button
    case 'Undo'
        WHICH_KEY = 'u';
        KEY_IS_PRESSED  = 0;
    case 'Clear all (start over)'
        WHICH_KEY = 'c';
        KEY_IS_PRESSED  = 0;
    case 'Finished'
        WHICH_KEY = 'f';
        KEY_IS_PRESSED  = 1;
    otherwise
        disp('You canceled the operations');
        KEY_IS_PRESSED  = 0;
        WHICH_KEY = 'n'; % do 'n'othing
end

end

function [n] = getPrimes(N,nextPrime)
if nargin < 2
    nextPrime = false;
end

N=fix(N);

if nextPrime == 0
    idx = 10;
    x=primes(idx*N);
    
    while length(x)<N
        idx = idx*2;
        x=primes(idx*N);
    end
    
    if length(x)==N
        n=x;
    else
        indx = 1:N;
        n=x(indx);
    end
    
elseif N==1
    n = 2;
else
    x = primes(10000); % unlikely to need more..
    indx = find(x<=N);
    n = x(indx(end)+1);
    
end
end



