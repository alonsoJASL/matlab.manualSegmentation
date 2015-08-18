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

close all
imtool close all;
clc

fontSize = 16;

% Read a file
[dataIn, att] = readParseInput();

disp('Dataset attributes:');
disp(att);
%
numImages = att.numImages;
if numImages > 3
    str = strcat('How many images do you want to segment? [Default=',...
        num2str(numImages),']: ');
    a = input(str);
    
    if ~isempty(a)
        numImages = a;
    end
end

% output file
dataBin = zeros(att.Height, att.Width, att.Depth_RGB, numImages);
binaryImageSum = zeros(size(dataIn(:,:,1,1)));

% deal with Warinings.
set(0,'recursionlimit',750);

for i=1:numImages
    for j=1:att.Depth_RGB
        grayImage = dataIn(:,:,j,i);

        imagesc(grayImage);
        colormap gray
        jet2=jet;jet2(1,:)=0;colormap(jet2); 
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
        if i==1 && j==1
            message = sprintf(['Left click and hold to begin drawing.' ...
                '\nSimply lift the mouse button to finish']);
            uiwait(msgbox(message));
        end
        
        for k=1:numCells
            hFH = imfreehand();
             % Create a binary image ("mask") from the ROI object.
             %xy = hFH.getPosition;
             binaryImageSum = bitor(binaryImageSum,hFH.createMask());
        end  
        dataBin(:,:,j,i) = binaryImageSum;
        close all;
    end
end

dataL = bwlabeln(dataBin);
writeOutput(dataL, att);

