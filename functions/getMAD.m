%Calculate mean amplitude deviation for non-overlapping 5 s epochs
%as per Vaha-Ypya 2015 Physical therapy 68(10):1500-1504
%Allow for accelerometer sleep mode, return 0 mad, and nan for orientation
%Written by Timo Rantalainen 2021 tjrantal at gmail dot com
%Released into the public domain
function [mad, x, y, z madStamps] = getMAD(acc,tStamps,tStampEpoch)
    %make sure that acceleration is in Nx3 format
    if size(acc,2) > size(acc,1)
       acc = acc';   
    end
    madEpochLength = 5; %s
    %Go through the tStampEpoch in 5 s increments
    initStamps = tStamps(1):5:tStamps(end)-4;
    mad = zeros(length(initStamps),1);
    x = zeros(length(initStamps),1);
    y = zeros(length(initStamps),1);
    z = zeros(length(initStamps),1);
    madStamps = zeros(length(initStamps),1);
    ci = 0;
    for t = initStamps
        ci = ci+1;
        indices = find(tStamps>=t & tStamps <= (t+4));
        currentAcc = acc(indices,:);
        resultant = sqrt(sum(currentAcc.^2,2));
        madStamps(ci) = t;
        if isempty(indices)
           mad(ci) = 0;
           x(ci) = nan;
           y(ci) = nan;
           z(ci) = nan;
        else
            mad(ci)= mean(abs(resultant-mean(resultant)));  %Mean amplitude deviation of the epoch
            tempOrientation = mean(currentAcc,1);
            x(ci) = tempOrientation(1);
            y(ci) = tempOrientation(2);
            z(ci) = tempOrientation(3);
        end
    end
end