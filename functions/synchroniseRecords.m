function synchOffs = synchroniseRecords(record1,record2)
	considerIndices = int32(0.2*length(record2)):int32(0.8*length(record2));
	javaConc = javaObject('timo.jyu.ConcordanceCorrelationCoefficient',record1,record2(considerIndices));
	[ignore mInd] = max(javaConc.coefficients);
	synchOffs = double(mInd-considerIndices(1)+1);
	%indices = ([1:length(hrvData)]-1)+synchOffs;               
end