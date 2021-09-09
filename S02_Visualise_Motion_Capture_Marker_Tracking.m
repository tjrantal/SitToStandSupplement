fclose all;
close all;
clear all;
clc;


addpath('functions');



addpath('functions/dlt2D'); %2D DLT functions for scaling image coordinates to global


coordinatePath = 'data/video/';



participants = getFilesAndFolders(coordinatePath);
for p = {participants(3).name}

    %Calculate global coordinates + vector angle from vertical
    kneeCoords = readLog([coordinatePath p{1} '/' 'knee.txt'],'\t',0);
    thighCoords = readLog([coordinatePath p{1} '/' 'thigh.txt'],'\t',0);
    
    minMax = [max([kneeCoords.data(1,1) thighCoords.data(1,1)]) min([kneeCoords.data(end,1) thighCoords.data(end,1)])];
    knee = kneeCoords.data(kneeCoords.data(:,1) >=minMax(1) & kneeCoords.data(:,1) <=minMax(2),3:4);
    thigh = thighCoords.data(thighCoords.data(:,1) >=minMax(1) & thighCoords.data(:,1) <=minMax(2),3:4);
    vTime = thighCoords.data(thighCoords.data(:,1) >=minMax(1) & thighCoords.data(:,1) <=minMax(2),2);
    
    %videoFile
    vFile = dir([coordinatePath p{1} '/*.mp4']);
    vReader = VideoReader([coordinatePath p{1} '/' vFile(1).name]);
    height = vReader.Width;
    vReader.currentTime = vTime(1);
%     frame = vReader.readFrame();
    figure
    cnt = 0;
    while cnt < size(vTime,1)
        cnt = cnt+1;
        frame = vReader.readFrame();
        hold off;
        imshow(permute(flipdim(frame,1),[2 1 3]),[]);
        hold on;
        plot(thigh(cnt,1),thigh(cnt,2),'r*','MarkerSize',6);
        plot(knee(cnt,1),knee(cnt,2),'b*','MarkerSize',6);
        title(sprintf('Time %.2f s',vTime(cnt)));
        drawnow();
%         keyboard;
    end
    keyboard;
    vReader.delete();
end

