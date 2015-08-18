function writeOutput(dataOut, outAttributes, rangeW)
%               WRITE OUTPUT
% Write the output of the manual segmentation into tiff files. 
%

if nargin < 3
    rangeW = 1:outAttributes.numImages;
end

if length(rangeW)<outAttributes.numImages
    disp('Range must be of lenght = attributes.numImages, i.e: ');
    disp(outAttributes.numImages);
    return;
end

% get folder
if outAttributes.isDir == false
    a = strsplit(outAttributes.fileName,'/');
    folderName = strcat(outAttributes.fileName(1:end-length(a{end})-1),...
        '_GTruth/');
else 
    folderName = strcat(outAttributes.fileName,'_GTruth/');
end

mkdir(folderName);

for i=1:outAttributes.numImages
    tiffstr = strcat(folderName, 'man',num2str(i),'.tif');
    
    for j=1:outAttributes.Depth_RGB
        ui16image = uint16(dataOut(:,:,j,i));
        if i==1
            imwrite(ui16image(:,:,j),tiffstr);
        else
            imwrite(ui16image(:,:,j),tiffstr,...
                'WriteMode','append');
        end
    end
end