function writeOutput(dataOut, outAttributes, options)
%               WRITE OUTPUT
% Write the output of the manual segmentation into tiff files. 
%

if nargin < 3
    options.outname = 'man';
    options.rangeW = 1:outAttributes.numImages;1
end

if length(options.rangeW)<outAttributes.numImages
    disp('Range must be of lenght = attributes.numImages, i.e: ');
    disp(outAttributes.numImages);
    return;
end

% get folder
if outAttributes.isDir == false
    a = strsplit(outAttributes.fileName,'/');
    folderName = strcat(outAttributes.fileName(1:end-length(a{end})-1),...
        '_GTruth/');
elseif exist(outAttributes.outName)
    folderName = outAttributes.outName;
else
    folderName = strcat(outAttributes.fileName,'_GTruth/');
end

if isempty(dir(folderName))
    mkdir(folderName);
end

for i=1:outAttributes.numImages
    
    if i < 11
        tiffstr = strcat(folderName, options.outname, ...
            '00',num2str(i-1),'.tif');
    elseif i<101
        tiffstr = strcat(folderName, options.outname , ...
            '0', num2str(i-1),'.tif');
    else
        tiffstr = strcat(folderName, options.outname , ...
            num2str(i-1),'.tif');
    end
    
    %tiffstr = strcat(folderName, options.outname ,num2str(i),'.tif');
    if outAttributes.isRGB == false
        for j=1:outAttributes.Depth
%            try 
                ui16image = uint16(dataOut(:,:,j,i));
%             catch e
%                 disp('oops');
%             end
            if j==1
                %imwrite(ui16image(:,:,j),tiffstr);
                imwrite(ui16image,tiffstr);
            else
                %imwrite(ui16image(:,:,j),tiffstr,...
                imwrite(ui16image,tiffstr,...
                    'WriteMode','append');
            end
            
        end
    else
        ui16image = uint16(dataOut(:,:,:,i));
        imwrite(ui16image,tiffstr);
    end
end