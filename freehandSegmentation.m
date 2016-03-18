function [dataBin, binAtt] = freehandSegmentation(dataIn, imAtt, colours)
%           FREEHAND SEGMENTATION FUNCTION
% Do manual segmentation on images to obtain ground truth data.
% 
% usage:
%
%            [dataBin] = freehandSegmentation(dataIn)
%            [dataBin] = freehandSegmentation(dataIn, imAtt)
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
global KEY_IS_PRESSED;
KEY_IS_PRESSED = 0;

if nargin == 1
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
                    imAtt.Width = size(dataIn,2);
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
        otherwise
            disp('Error. Wrong dimensions of input data.');
            dataBin = [];
            return;
    end
end

if nargin == 3 
    cmap = colours;
else
    % Default 
    cmap=jet;
    cmap(1,:)=0;
end
    

% deal with Warinings.
set(0,'recursionlimit',750);

numImages = imAtt.numImages;
if numImages > 3
    str = strcat('How many images do you want to segment? [Default=',...
        num2str(numImages),']: ');
    a = input(str);
    
    if ~isempty(a)
        numImages = a;
    end
end

dataBin = zeros(imAtt.Height, imAtt.Width, imAtt.Depth, numImages);
binaryImageSum = zeros(size(dataIn(:,:,1,1)));

overlappingDataset = 0;

for i=1:numImages
    for j=1:imAtt.Depth
        grayImage = dataIn(:,:,j,i);
        
        imagesc(grayImage);
        colormap(cmap);
        axis on;
        
        str = strcat('Original Grayscale Image: ',num2str(i), ...
            ' Layer: ', num2str(j));
        title(str , 'FontSize', 18);
        set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
        set(gcf, 'KeyPressFcn', @myKeyPressFcn); % Get key press for ending.
        
        numCells = 0;

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
                           numCells = numCells+1;
                        else
                            % We have to break up the image into different
                            % cell layers                           
                            binaryImageSum = bwlabeln(binaryImageSum);
                            binaryImageSum = ...
                                changeGroundTruthLabels(binaryImageSum);
                            [binaryImageSum] = ...
                                changeOverlapRepresentation(binaryImageSum);
                            binaryImageSum(:,:,end+1) = newCell;
                            numCells = numCells+1;
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
                numCells = numCells+1;
            else
                % do nothing.
                binaryImageSum = bitor(binaryImageSum,newCell);
                numCells = numCells+1;
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

if nargout > 1 
    binAtt = imAtt;
    binAtt.numCells = numCells;
end

end

function myKeyPressFcn(hObject, event)
    global KEY_IS_PRESSED
    KEY_IS_PRESSED  = 1;
    message = ['Key pressed, segment your last cell or'...
        '\nclick on any of the already segmented cells.'];
    uiwait(msgbox(message));
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

        

    