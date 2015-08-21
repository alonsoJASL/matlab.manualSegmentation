function [dataBin] = freehandSegmentation(dataIn, imAtt)
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

for i=1:numImages
    for j=1:imAtt.Depth
        grayImage = dataIn(:,:,j,i);
        
        imagesc(grayImage);
        colormap gray
        jet2=jet;jet2(1,:)=0;colormap(jet2);
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

        %for k=1:numCells
         while ~KEY_IS_PRESSED               
            hFH = imfreehand();
            % Create a binary image ("mask") from the ROI object.
            %xy = hFH.getPosition;
            binaryImageSum = bitor(binaryImageSum,hFH.createMask());
            numCells = numCells+1;
        end
        dataBin(:,:,j,i) = binaryImageSum;
        
        % reset binaryImage
        binaryImageSum = zeros(size(dataIn(:,:,1,1)));
        KEY_IS_PRESSED = 0;
        close all;
    end
end
end

function myKeyPressFcn(hObject, event)
    global KEY_IS_PRESSED
    KEY_IS_PRESSED  = 1;
    message = ['Key pressed, segment your last cell or'...
        '\nclick on any of the already segmented cells.'];
    uiwait(msgbox(message));
end


        

    