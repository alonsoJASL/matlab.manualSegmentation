function [imNames] = loadimages(dirname, dataset, returnwhich)
% Pull one (random or the first) or all the images from a dataset.
% works better with loadnames.m
% This is useful for functions like readParseInput from the MANUAL
% SEGMENTATION package. 
%
% SEE ALSO loadnames, readParseInput
%
% Code part of the matlab.manualSegmentation git repository, licensed under
% the GNU General Public License v3. Found at: 
% 
%       <https://github.com/alonsoJASL/matlab.manualSegmentation.git> 
%
%


allFiles = dir(strcat(dirname, dataset));
allFiles(1:2) = [];

if nargin < 3
    returnwhich = 'random';
else 
    returnwhich = lower(returnwhich);
end

switch returnwhich
    case 'all'
        imNames = {allFiles.name};
    case 'random'
        index = randi(length(allFiles));
        imNames = allFiles(index).name;
    case 'one'
        imNames = allFiles(1).name;
    otherwise 
        disp('Wrong option. Use: all, random, or one.');
        disp('Returning all');
        imNames = {allFiles.name};
end




    

