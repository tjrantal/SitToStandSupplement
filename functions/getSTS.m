%Function to detect and quantify sit-to-stand transitions
%Requires continuous sampling
function [standUps angularVelocities stsStamps stsIndices] = getSTS(stamps,angle,resultant, sFreq)
    twoSFreq = floor(2*sFreq);
    movingVar = movvar(resultant,[twoSFreq 0]);
    rectPosture = zeros(size(angle,1),size(angle,2));
    rectPosture(angle<pi/4) = 1; %
%     figure,plot(rectPosture),set(gca,'ylim',[-0.1 1.1]), hold on; 
    medFiltLength = floor(23*sFreq/100);
    if mod(medFiltLength,2) == 0    %Cannot allow an even median filter length
        medFiltLength = medFiltLength+1;
    end
    rectPosture = medfilt1(rectPosture,medFiltLength);
%     plot(rectPosture,'r');
    movingRectMean = conv(rectPosture,ones(1,twoSFreq)./twoSFreq,'same');
    tempBuffer = buffer(angle,twoSFreq,twoSFreq-1,'nodelay');
    minFAPE = zeros(size(angle,1),size(angle,2)).*nan;
    tempMin = min(tempBuffer,[],1);
    minFAPE(length(minFAPE)-length(tempMin)+1:end-(twoSFreq-1)) = tempMin(twoSFreq:end);

    lagDuration = floor(2.5*sFreq);
    maxExplore = length(rectPosture)-lagDuration;
    
%     keyboard;
    standUps = find(rectPosture(lagDuration+1:end-1) - rectPosture(lagDuration+2:end) <= -1+10*eps ...
            & movingRectMean(1:end-lagDuration-1)  < 0.5 ...
            & movingVar(1:end-lagDuration-1) < 0.02 ...
            & angle(lagDuration-floor(0.5*sFreq)+1:end-floor(0.5*sFreq)-1) > 65/180*pi... 
            & minFAPE(lagDuration+1:end-1) <= 35/180*pi);
    standUps = standUps+lagDuration;		
    
%     figure,plot(fAPE,'k'); hold on, plot(standUps,fAPE(standUps),'r*','linestyle','none')
    
    [angularVelocities, localIndices] = cellfun(@(x) getAngularFromAPE(angle(x+[-lagDuration:floor(1*sFreq)]),lagDuration,sFreq),num2cell(standUps),'uni',0);
    toKeep =  cellfun(@(x) ~isnan(x),angularVelocities,'uni',1);
    angularVelocities = angularVelocities(toKeep);
    localIndices = localIndices(toKeep);
    standUps = standUps(toKeep);
    stsIndices = cellfun(@(x,y) x+y-lagDuration,num2cell(standUps),localIndices,'uni',0);
    stsStamps = cellfun(@(x) stamps(round(mean(x))),stsIndices);
    
end