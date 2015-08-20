function [newdatabin] = fixSegmentation(dataB, X, xatt, fixInterval)
%               FIX BINARY IMAGE SEGMENTATION
%
% Fix the segmentation done by freehandSegmentation, for missing segmented
% objects. It burns the already segmented images (in fixInterval). The 
% aditional segmentation done will be "added" to the new one with a bitor
% operator. 
%
% This function DOES NOT help you with segmentation already done (no 
% erasing already segmented objects).
% 
% Usage: 
%
%       (1) [newdatabin] = fixSegmentation(dataB, X, xatt, fixInterval)
%       (2) [newdatabin] = fixSegmentation(dataB, X, xatt)
%
% INPUT:
%          dataB := Current segmentation. 4D matrix with binary images.
%              X := Original Images. 
%           xatt := (Structure) image attributes. Normally from 
%           readParseInput function. Should contain:
%                       - Height  |
%                       - Width   |-> Dimensions of images
%                       - Depth   |
%                       - numImages -> number of images
%    fixInterval := (Optional) vector of indices of the images that should
%           be fixed. If missing, you can choose which image to fix, or to
%           fix them all.
% 
% OUPUT:
%     newdatabin := new segmented binary set of images.
%
% SEE ALSO: readParseInput , freehandSegmentation
% 

if nargin < 4 
    str = strcat('Enter the index of the image you want to fix',...
        ' [Default=[1:',num2str(xatt.numImages),']: ');
    fixInterval = input(str);
    if isempty(fixInterval)
        fixInterval = 1:xatt.numImages;
    elseif ischar(fixInterval)
        disp('Wrong input');
        newdatabin = [];
        return;
    end
else 
    fixInterval = sort(fixInterval);
end

newdatabin = dataB;

maxX = max(X(:));
Y = X(:,:,:,fixInterval)./2;
y = zeros(size(X(:,:,:,1)));

for i=1:length(fixInterval)
    for j=1:xatt.Depth
        
        y = Y(:,:,j,i);
        y(newdatabin(:,:,j,fixInterval(i)) > 0) = maxX;
        
        imagesc(y(:,:,j));
        jet2=jet;jet2(1,:)=0;colormap(jet2);
        axis on;
        
        str = strcat('Original Grayscale Image: ',num2str(fixInterval(i)), ...
            ' Layer: ', num2str(j));
        title(str , 'FontSize', 18);
        set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
        
        % Ask for the number of objects to be segmented.
        numCells = inputdlg('How many objects are we fixing?',...
            'Choose a number');
        numCells = str2num(numCells{1});
        
        if isempty(numCells)
            uiwait(msgbox('Incorrect input, not doing anything'));
            numCells = 0;
        end
        
        for k=1:numCells
            hFH = imfreehand();
            % Create a binary image ("mask") from the ROI object.
            %xy = hFH.getPosition;
            newdatabin(:,:,j,fixInterval(i)) = ...
                bitor(newdatabin(:,:,j,fixInterval(i)), hFH.createMask());
        end
        
        close all;
    end
end
        
        

        
    