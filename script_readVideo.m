% script file: read video
%

clc
% OS X
fname = '/Volumes/DATA/ARTEMIAE/10min.mov';
outname = '/Volumes/DATA/ARTEMIAE/ARTIMAGES/';

V = VideoReader(fname);

i=1;

while hasFrame(V);
    if i < 10
        outstr = 't000';
    elseif i >= 10 && i < 100
        outstr = 't00';
    elseif i >= 100 && i < 1000
        outstr = 't0';
    else
        outstr = 't';
    end
    
    vid = readFrame(V); 
    imwrite(vid,strcat(outname,outstr,num2str(i),'.tif'));
    i=i+1;
end

