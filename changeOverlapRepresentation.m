function [newGT, newAtt] = changeOverlapRepresentation(groundTruth,att)
%                CHANGE OVERLAP REPRESENTATION
%
% Changes the representation of overlapped ground truth images from having
% them being represented as layers (so 2D images become 3D...) or
% labelling the objects with prime numbers so that image size isn't
% changed. This program only accepts a single image to work with.
%
% Usage:
%
%        [newGT, newAtt] = changeOverlapRepresentation(gt,att)
%        [newGT, newAtt] = changeOverlapRepresentation(gt)
%
% INPUT:
%                   gt := original 2D image.
%                  att := Structure of attributes of the image
%                         MUST include:
%                           - att.Depth := number of 3D slices of thew
%                                          image
%                           - att.overlap := boolean (always true, given
%                                           the context)
%                           - att.overlaptype := either 'primes' or
%                             'levels'.
%                           - att.overlaplevels
%
% OUTPUT:
%               newGT := New segmented image in the alternate form of
%                        representation.
%              newAtt := Attributes of the image altered to fit the new
%                        representation.
%
% Some conventions: ground truth has always 0 for background pixels and
% natural numbers for labels.
%

if nargin < 2
    sizeGT = size(groundTruth);
    att.Height = sizeGT(1);
    att.Width = sizeGT(2);
    att.Depth = size(groundTruth, 3);

    att.overlap = true;
    if att.Depth > 1
        att.overlaptype = 'levels';
        att.overlapindx = [];
        att.ovelaplabels = [];
    else
        att.overlaptype  = 'primes';
        labelsGT = unique(groundTruth);
        overlapindx = find(~isprime(labelsGT));
        overlapindx(1) = [];

        att.overlapindx = overlapindx;
        overlaplabels = labelsGT(overlapindx);
        att.overlaplabels = overlaplabels;
    end
    att.overlaplevels = att.Depth;
else % two arguments sent: gt image and attributes structure.
    try
        att.overlaptype = lower(att.overlaptype);
    catch e
        disp('ERROR. Set the attributes struct right!');
        newGT = [];
        newAtt = [];
        return;
    end
end

switch att.overlaptype
    case {'primes','prime'}
        % From prime-based to layered ground truth.
        labelsOnImage = unique(groundTruth);
        labelsOnImage(1) = [];
        indxNotPrime = find(~isprime(labelsOnImage));

        actualLabels = [];
        for i=1:length(labelsOnImage)
            actualLabels = [actualLabels factor(labelsOnImage(i))];
        end
        actualLabels = unique(actualLabels);

        outputLayers = zeros(att.Height, att.Width, length(actualLabels));

        for i=1:length(labelsOnImage)
            if isprime(labelsOnImage(i))
                indx = find(actualLabels==labelsOnImage(i));
                outputLayers(:,:,indx) = groundTruth==actualLabels(indx);
                outputLayers(:,:,indx) = ...
                    outputLayers(:,:,indx).*actualLabels(indx);
            else
                compoundLabel = labelsOnImage(i);
                factorisedLabel = factor(compoundLabel);
                for j=1:length(factorisedLabel)
                    indx = find(actualLabels==factorisedLabel(j));
                    outputLayers(:,:,indx) = outputLayers(:,:,indx) + ...
                        (groundTruth==labelsOnImage(i)).*factorisedLabel(j);
                end
            end
        end

        newGT = outputLayers;

        if nargout>1
            newAtt = att;
            newAtt.Depth = size(newGT,3);
            newAtt.overlaplevels = size(newGT,3);
            newAtt.overlaptype = 'levels';
            newAtt.overlapindx = [];
            newAtt.labels = actualLabels;

        end

    case {'levels', 'level'}
        % From layered ground truth to prime-based ground truth.
        groundTruth = -1.*groundTruth;
        groundTruth(groundTruth==0) = 1;

        newLabels = primes(1000);
        labels = unique(groundTruth);
        newLabels = [newLabels(1:length(labels))];
        newLabels(end) = 1;
        newLabels = newLabels';

        for indx=1:length(labels)
            groundTruth(groundTruth==labels(indx)) = newLabels(indx);
        end

        newGT = prod(groundTruth,3);
        newGT(newGT==1) = 0;
        newLabels(end) = [];

        if nargout > 1
            labelsGT = unique(newGT);

            newAtt = att;
            newAtt.Depth = size(newGT,3);
            newAtt.overlaplevels = 1;
            newAtt.overlaptype = 'primes';
            newAtt.overlapindx = find(~isprime(labelsGT));

            newAtt.labels = newLabels;

            newAtt.overlapindx(1) = [];

            newAtt.overplaplabels = labelsGT(newAtt.overlapindx);
        end


    otherwise
        disp('ERROR. Found atributes.overlaptype, but options do not match.');
        disp('Try again. Available options are: "LEVELS" or "PRIMES".');
        newGT = [];
        newAtt = [];
        return;
end
