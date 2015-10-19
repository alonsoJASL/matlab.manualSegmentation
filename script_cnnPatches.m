% script: CNN Patches 
% Take an annotated image and create the training
% images for the CNN.
%

clc;

fname = '/media/jsolisl/DATA/ISBI_CELLTRACKING/2013/TRAINING/';
dirnames{1} = 'C2DL-MSC/';
dirnames{2} = 'N2DH-GOWT1/';
dirnames{3} = 'N2DH-SIM/';
dirnames{4} = 'N2DL-HeLa/';

for k=1:length(dirnames)
    fprintf('\n DATASET: %s', dirnames{k});
    imnames = dir(strcat(fname,dirnames{k},'01/*.tif'));
    imnames = {imnames.name};
    
    imannotated = dir(strcat(fname,dirnames{k},'01_SegGroundTruth/*.tif'));
    imannotated = {imannotated.name};
    
    for j=1:length(imnames)
        disp(imnames{j});
        name = strcat(fname,dirnames{k},'01/',imnames{j});
        namegt = strcat(fname,dirnames{k},'01_SegGroundTruth/',imannotated{j});
        
        A = imread(name);
        Ay = imread(namegt);
        
        %
        [cells, gtCells] = getTrainingImages(A, Ay);
        [height, width, numIm] = size(cells);
        
        for i=1:numIm
            [patches, gt] = generatePatches(cells(:,:,i),gtCells(:,:,i));
            outDir = strcat(fname, 'CNNTRAINING/', dirnames{k});
            if isempty(dir(outDir))
                mkdir(outDir);
            end
            if i < 10
                saveStr = strcat('01_',imnames{j}(1:end-4),'_0', num2str(i));
            else
                saveStr = strcat('01_',imnames{j}(1:end-4), '_',num2str(i));
            end
            
            save(strcat(outDir,saveStr),'patches','gt');
        end
    end
end