%Function to calculate global coordinates based on 2D DLT coefficients, and digitised camera image coordinates
%@param coeffs = 8 x 1 array of 2D DLT coordinate
%@param digitisedCoordinates = N x 2 matrix of digitised calibration object image coordinates
%@returns the global 2D coordinates
%Written by Timo Rantalainen 2018 tjrantal at gmail dot com. Licensed with the CC-BY https://creativecommons.org/licenses/by/4.0/
function coordinates = getGlobal2D(coeffs, digitisedCoordinates)
	%helper function to calculate the coordinates for a single digitised point
	function coords =  calcCoords(coeffsIn,coordIn)
		L1 = zeros(2,2);
		L2 = zeros(2,1);
		L1(1,1) = coordIn(1)*coeffsIn(7)-coeffsIn(1);
		L1(1,2) = coordIn(1)*coeffsIn(8)-coeffsIn(2);
		L1(2,1) = coordIn(2)*coeffsIn(7)-coeffsIn(4);
		L1(2,2) = coordIn(2)*coeffsIn(8)-coeffsIn(5);
		L2(1) = coeffsIn(3)-coordIn(1);
		L2(2) = coeffsIn(6)-coordIn(2);
		coords = L1\L2;	%Scale the coordinates		
	end
	
	coordinates = zeros(size(digitisedCoordinates,1),size(digitisedCoordinates,2));
	for i = 1:size(digitisedCoordinates,1)
		coordinates(i,:) = calcCoords(coeffs,digitisedCoordinates(i,:))';
	end
end