% Script file:
% Original demo with more features at:
% http://www.mathworks.com/matlabcentral/...
%           answers/32601-manual-segmentation-of-image
%
% Reworked by Jose Alonso Solis Lemus.
%
% Demo to have the user freehand draw an irregular shape over
% a gray scale image.
% 

clear all
close all
imtool close all;
clc

fontSize = 16;

% Read a file
[dataIn, att] = readParseInput();

disp('Dataset attributes:');
disp(att);

numImages = att.numImages;
if numImages > 3
    str = strcat('There are ', num2str(numImages), ...
        'how many do you want to segment? [Default=92]: ');
    a = input(str);
    
    if ~isempty(a)
        numImages = a;
    end
end

% output file
dataBin = zeros(att.Height, att.Width, att.Depth_RGB, numImages);

% deal with Warinings.
set(0,'recursionlimit',750);

for i=1:numImages
    for j=1:att.Depth_RGB
        grayImage = dataIn(:,:,j,i);

        imagesc(grayImage);
        axis on;
        
        str = strcat('Original Grayscale Image: ',num2str(i), ...
            ' Layer: ', num2str(j));
        title(str , 'FontSize', fontSize);
        set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
        
        % Ask for the number of objects to be segmented.
        numCells = inputdlg('How many objects are we segmenting?',...
            'Choose a number');
        numCells = str2num(numCells{1});
        
        if isempty(numCells)
            uiwait(msgbox('Incorrect input, using numCells=1'));
            numCells = 1;
        end
        
        %
        message = sprintf(['Left click and hold to begin drawing.' ...
            '\nSimply lift the mouse button to finish']);
        uiwait(msgbox(message));
        binaryImage = zeros(size(grayImage));
        binaryImage = binaryImage > 5;
        binaryImageSum = binaryImage;
        
        for k=1:numCells
            hFH = imfreehand();
            % Create a binary image ("mask") from the ROI object.
            binaryImage = hFH.createMask();
            xy = hFH.getPosition;
            %
            binaryImageSum = bitor(binaryImageSum,binaryImage);
        end
        
        dataBin(:,:,j,i) = binaryImageSum;
    end
end

dataL = bwlabeln(dataBin);

