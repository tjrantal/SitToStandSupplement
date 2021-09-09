function peaks = getPeaks(signal,threshold,minPeakLength)
    if ~exist('minPeakLength','var')
        minPeakLength = 1;
    end
    if size(signal,1) > size(signal,2)
        signal = signal';
    end
    peaks = {}; %return empty if no peaks are found
    peakIndices = find(signal >= threshold);
    if isempty(peakIndices)
       
       return;
    end
    
    diffPI = diff(peakIndices);
    diffEnds = find(diffPI > 1);	%no min gap between peaks
    diffInits = [];
    if isempty(diffEnds)
        diffInits = peakIndices([1]);
        diffEnds = peakIndices([length(peakIndices)]);
    else
        diffInits = peakIndices([1, diffEnds+1]);
        diffEnds = peakIndices([diffEnds, length(peakIndices)]);
    end
    
%     figure
%     plot(signal,'k')
%     hold on;
%     plot(diffInits,signal(diffInits),'ro','linestyle','none');
%     plot(diffEnds,signal(diffEnds),'g*','linestyle','none');
% %     test = [diffInits; diffEnds]
%     
%     keyboard;
    %eliminate peaks that are shorter than minPeakLength
    for i = length(diffInits):-1:1
       if diffEnds(i)-diffInits(i)+1 < minPeakLength
          diffInits(i) = []; 
          diffEnds(i) = [];
       end
    end
    
    %Return empty struct if no peaks of sufficient length remain
	try
    	peaks = cellfun(@(x,y) x:y,num2cell(diffInits),num2cell(diffEnds),'uniformoutput',false);
%         test2 = [cellfun(@(x) x(1),peaks); cellfun(@(x) x(end),peaks)]
	 catch
	 end
end
