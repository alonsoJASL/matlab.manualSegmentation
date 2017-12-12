function [imNames] = loadimages(dirname, dataset, returnwhich)
% Pull one (random or the first) or all the images from a dataset.
% works better with loadnames.m
% 
% USAGE: 
%           [imNames] = loadimages(dirname, dataset, returnwhich)
% 
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


allFiles = dir(fullfile(dirname, dataset));
allFiles(1:2) = [];

if nargin < 3
    returnwhich = 'random';
elseif ischar(returnwhich) 
    returnwhich = lower(returnwhich);
else
    % it's an index!
    indx = returnwhich;
    returnwhich = 'index';
end

switch returnwhich
    case 'all'
        imNames = {allFiles.name};
    case 'random'
        index = randi(length(allFiles));
        imNames = allFiles(index).name;
    case 'one'
        imNames = allFiles(1).name;
    case 'index'
        imNames = allFiles(indx).name;
    case 'last'
        imNames = allFiles(end).name;
    otherwise 
        disp('Wrong option. Use: all, random, one, or specify the index (number).');
        disp('Returning all');
        imNames = {allFiles.name};
end




    

