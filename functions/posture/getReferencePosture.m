function [ref, indices] = getReferencePosture(data,limits,constants)
    minMatchLength = constants.minLength/constants.epochLength;
	convKern = ones(1,minMatchLength)./(minMatchLength);
    thresh = double(data.mad >= limits(1) & data.mad <= limits(2));
    convolved = conv(thresh,convKern,'valid');
    candidates = getPeaks(convolved,1-eps);
    if isempty(candidates)
       ref = [];
       return;
    end
    indices = cellfun(@(x) x(1):x(end)+minMatchLength-1,candidates,'uniformoutput',false);
    Xs = cellfun(@(x) mean(data.x(x)),candidates);
    Ys = cellfun(@(x) mean(data.y(x)),candidates);
    Zs = cellfun(@(x) mean(data.z(x)),candidates);
    ref = [median(Xs), median(Ys), median(Zs)];
    ref = ref./norm(ref);
    
    %Debugging
    if 0
        candInd = cellfun(@(x) x(1):x(end)+minMatchLength-1,candidates,'uniformoutput',false);
        fh = figure('position',[0 50 1600 800]);
        subplot(2,1,1)
        hold on;
        plot(data.mad)
        cellfun(@(x) plot(x,data.mad(x)),candInd);
        ah(1) = gca();
        subplot(2,1,2)
        hold on;
        plot(data.x,'r');
        plot(data.y,'g');
        plot(data.z,'b');
        cellfun(@(x) plot(x,data.x(x)),candInd);
        cellfun(@(x) plot(x,data.y(x)),candInd);
        cellfun(@(x) plot(x,data.z(x)),candInd);
        ah(2) = gca();
        linkaxes(ah,'x');
    end
end