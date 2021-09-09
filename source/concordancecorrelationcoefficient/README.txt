Implementation of concordance correlation coefficient as described in wikipedia
	https://en.wikipedia.org/wiki/Concordance_correlation_coefficient
	
I have used this to synchronise two signals with non-similar amplitudes. Cross-correlation performs poorly when the signal amplitudes are not similar, and I've found concordance correlation to perform much better on such occasions.

Written by Timo Rantalainen 2013 - 2018 tjrantal at gmail dot com. Released to the public domain.


Build with gradle (cd into this folder from the command line, run 'gradle jar' [check compile.bat for furher help]). Usage sample from Matlab in test.m
