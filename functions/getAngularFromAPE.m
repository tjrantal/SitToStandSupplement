function [angularVelocity, standUpIndices] = getAngularFromAPE(data,midIndex,sRate)
    function x = makeColumn(x)
        if size(x,1) < size(x,2)
            x = x';
        end
    end
    
    function coeff = getCoeffs(x,y)
        x = makeColumn(x);
        y = makeColumn(y);
        A = [ones(length(x),1), x];
        coeff = A\y;
    end
    function f = getFit(x,coeff)
       x = makeColumn(x);
       f = coeff(1)+x.*coeff(2); 
    end
    function resid = getResidual(orig,fit)
        orig = makeColumn(orig);
        fit = makeColumn(fit);
       resid = sum((orig-fit).^2); 
    end

    baseLine = median(data(1:floor(1.5*sRate)));
    standUpStart = find(data(1:midIndex) > baseLine,1,'last');
    goodnessOfFit = [];
    lastPointError = [];
    for i = midIndex:length(data)
        xVals = [standUpStart:i]-standUpStart+1;
        currentEpoch = data(standUpStart:i);
        currentFit =getFit(xVals,getCoeffs(xVals,currentEpoch));
        goodnessOfFit(i-midIndex+1) = getResidual(currentEpoch,currentFit);
        goodnessPointError(i-midIndex+1) = (currentFit(end)-currentEpoch(end))^2;
        
    end
%     figure
%     plot(goodnessOfFit,'k');
%     hold on
%     plot(goodnessPointError,'r');
%   keyboard;
    
    fitEndIndex = find(goodnessPointError < 0.005,1,'last')+midIndex-1; 
    if isempty(fitEndIndex)
        standUpIndices = nan;
        angularVelocity = nan;
    else
        standUpIndices = standUpStart:fitEndIndex;
    %     figure
    %     plot(data,'k')
    %     hold on;
    %     plot(standUpStart:fitEndIndex,data(standUpStart:fitEndIndex),'r')
    %     keyboard;
        coeffs = getCoeffs([standUpIndices-standUpIndices(1)]/sRate,data(standUpIndices));
        angularVelocity = coeffs(2);
    end
end