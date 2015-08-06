% Script file:
% Idea taken from:
% http://www.mathworks.com/matlabcentral/...
%           answers/32601-manual-segmentation-of-image
%
% Reworked by Jose Alonso Solis Lemus.
%
% Demo to have the user freehand draw an irregular shape over
% a gray scale image, have it extract only that part to a new image,
% and to calculate the mean intensity value of the image within that shape.
% Also calculates the perimeter, centroid, and center of mass 
% (weighted centroid).
% 

clear all
close all
imtool close all;
clc

fontSize = 16;

% Read a file
[dataIn, att] = readParseInput();

% Right now, we're only choosing the first image
grayImage = dataIn(:,:,:,1);

% is it really gray?
if att.Depth_RGB >3 
    % If the image is 3D, we're segmenting the MEAN only. 
    % This feature will be changed in future versions.
    grayImage = mean(grayImage,3);
elseif att.Depth_RGB == 3
    grayImage = rgb2gray(grayImage);
end

imagesc(grayImage);
axis on;
title('Original Grayscale Image', 'FontSize', fontSize);
set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.

% Ask for the number of objects to be segmented.
numCells = inputdlg('How many objects are we segmenting?');
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

for i=1:numCells
    hFH = imfreehand();
    % Create a binary image ("mask") from the ROI object.
    binaryImage = hFH.createMask();
    xy = hFH.getPosition;
    %
    binaryImageSum = bitor(binaryImageSum,binaryImage);
end

labeledImage = bwlabeln(binaryImageSum);
imagesc(labeledImage);

