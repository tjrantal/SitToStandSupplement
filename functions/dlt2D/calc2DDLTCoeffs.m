%Function to calculate 2D direct linear transformation coefficients (DLT)
%@param calibObjectGlobalCoordinates = N x 2 matrix of calibration object global coordinates
%@param digitisedCoordinates = N x 2 matrix of digitised calibration object image coordinates
%@returns the 8 2D DLT coordinates
%Written by Timo Rantalainen 2018 tjrantal at gmail dot com. Licensed with the CC-BY https://creativecommons.org/licenses/by/4.0/
function coeffs = calc2DDLTCoeffs(calibObjectGlobalCoordinates, digitisedCoordinates)
	B = zeros(2*size(calibObjectGlobalCoordinates,1),8); %Matrix for solving DLT-parameters
	C = zeros(2*size(digitisedCoordinates,1),1); %Digitized calibrationObject coordinates
	cnt = 0;
	%Re-order the digitised coordinates into an array x1,y1,x2,y2, etc. Could've used reshape...
	for i =1:size(digitisedCoordinates,1)
		for j = 1:size(digitisedCoordinates,2)
			cnt = cnt+1;
			C(cnt) = digitisedCoordinates(i,j);
			
		end
    end

    %Create the matrix used to solve the coefficient
	for i = 1:size(calibObjectGlobalCoordinates,1)
		B(2*i-1,1)			= calibObjectGlobalCoordinates(i,1); 
		B(2*i-1,2)			= calibObjectGlobalCoordinates(i,2); 
		B(2*i-1,3)  		= 1;
		B(2*i-1,7)		 	=-calibObjectGlobalCoordinates(i,1)*digitisedCoordinates(i,1);
		B(2*i-1,8)			=-calibObjectGlobalCoordinates(i,2)*digitisedCoordinates(i,1);
		B(2*i,4)		= calibObjectGlobalCoordinates(i,1);
		B(2*i,5)		= calibObjectGlobalCoordinates(i,2);
		B(2*i,6)		= 1;
		B(2*i,7)		=-calibObjectGlobalCoordinates(i,1)*digitisedCoordinates(i,2);
		B(2*i,8)		=-calibObjectGlobalCoordinates(i,2)*digitisedCoordinates(i,2);
	end
	
	coeffs = B\C;	%Solve the DLT coefficients
end