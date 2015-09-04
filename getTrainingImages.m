function [cellStructure] = getTrainingImages(dataIn, dataBin)
%                   GET TRAINING IMAGES
% This function takes a binary image of lots of manually segmented images 
% and builds patches that can later be used for training on segmentation 
% techniques. 
%
% Usage: [cellStructure] = getTrainingImages(X, dataBin, xatt)
%
% INPUT:
%            dataIn := single image. 
%           databin := single binary image.
% OUTPUT:
%
%    cellStructure := image patches.
%

dataL = bwlabeln(dataBin);
labels = unique(dataL);

labels(1) = [];

[n, m] = size(dataL);
L = length(labels);
patches = zeros(n, m, L);
patch = zeros(n,m);

Wi = zeros(1,L);
He = zeros(1,L);

for i=1:L
    
    structBoundaries = bwboundaries(dataL==i);
    xy = structBoundaries{1};
    x = xy(:,2);
    y = xy(:,1);
    
    leftColumn = min(x);
    rightColumn = max(x);
    topLine = min(y);
    bottomLine = max(y);
    
    Wi(i) = rightColumn - leftColumn + 1;
    He(i) = bottomLine - topLine + 1;
    
    croppedImage = imcrop(dataIn, ...
             [leftColumn, topLine, Wi(i), He(i)]);
    patch(1:He(i)+1, 1:Wi(i)+1) = croppedImage;
    patches(:,:,i) = patch;
    patch(patch~=0) = 0;
end
maxWidth = max(Wi)+1;
maxHeight = max(He)+1;

cellStructure = zeros(maxHeight,maxWidth,L);
for i=1:L
    cellStructure(1:He(i)+1,1:Wi(i)+1,i) = ...
        patches(1:He(i)+1,1:Wi(i)+1, i);
end