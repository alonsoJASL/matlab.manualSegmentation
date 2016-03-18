function [Xout] = changeGroundTruthLabels(Xin, changeWhich)
%   CHANGE GROUND TRUTH LABELS
% Changes the labels on Xin to the labels specified in the string 
% changeWhich. The program assumes that the first label that appears in the
% unique(Xin) corresponds to the background, and therefore is not changed.
% Defaults to 'primes' as the new labelling scheme.

if nargin < 2
    whichlabels = 'primes';
else
    whichlabels = lower(changeWhich);
end

labels = unique(Xin);
labels(1) = [];

Xout = Xin;

switch whichlabels
    case {'primes', 'prime'}
        newLabels = getPrimes(length(labels));
    case {'standard', 'normal'}
        newLabels = 1:length(labels);
    otherwise
        disp('ERROR. Not a valid option for changing the labels.');
        disp('Available options: primes, standard');
        Xout = Xin;
end

for i=1:length(labels)
    Xout(Xin==labels(i)) = newLabels(i);
end