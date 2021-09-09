close all;
clear all;
clc;
javaaddpath('build/libs/concordancecorrelationcoefficient-1.0.jar');
t = 0:0.01:10;
testSig1 =  sin(t);
testSig2 =  cos(t);
figure
ah = [];
subplot(2,1,1)
plot(t,testSig1,'k');
hold on;
plot(t,testSig2,'r');
title('Original')
ah(1) = gca();
%Calculate lag, eliminate 20% data from both ends to enable sliding the signals with respect to each other
considerIndices = int32(0.2*length(testSig2)):int32(0.8*length(testSig2));
javaConc = javaObject('timo.jyu.ConcordanceCorrelationCoefficient',testSig1,testSig2(considerIndices));
[ignore mInd] = max(javaConc.coefficients);
synchOffs = double(mInd-considerIndices(1)+1);
subplot(2,1,2)
plot(t,testSig1,'k');
hold on;
plot(t+t(synchOffs),testSig2,'r');
title('Synchronised')
ah(2) = gca();
linkaxes(ah,'x');
