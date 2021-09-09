%Function to read NGIMU session data
%@params sessioPath, the path to Session.xml
%@params constants, a structure with desired sampling rate .sFreq
%@returns a structure with data re-sampled to constants.sFreq sample rate
%raw and rotated with the NGIMU orientation vector
function collectedData = getNGIMUData(sessionPath,constants)

   
    
	if ~exist('OCTAVE_VERSION', 'builtin')
		%Parse java timetsamp from session.xml
		xmlStruct = parseXML([sessionPath '/Session.xml']); %Read the xml file into a struct
		dateString = xmlStruct.Children(2).Attributes(1).Value; %This field is always date in NGIMU session
	else
		%Read date based on text
		dateString = octaveGetDate([sessionPath '/Session.xml']);
    end

    %Read session data into memory
    sessionData = importSession(sessionPath);
		
    locale = javaObject('java.util.Locale','fi', 'FI');  %Use Finnish locale
    try
        sdf = javaObject('java.text.SimpleDateFormat','yyyy-MM-dd HH:mm:ss',locale); %Create simple date format
        tempDate = sdf.parse(dateString, javaObject('java.text.ParsePosition',0));   %Parse the dateString
        dateMs = tempDate.getTime();    %Get a java millisecond time stamp
    catch
        sdf = javaObject('java.text.SimpleDateFormat','yyyy-MM-dd HH.mm.ss',locale); %Create simple date format
        tempDate = sdf.parse(dateString, javaObject('java.text.ParsePosition',0));   %Parse the dateString
        dateMs = tempDate.getTime();    %Get a java millisecond time stamp
    end
            
    %Resample data
    [time, sessionData] = resampleSession(sessionData, 1/constants.sFreq);
    dNames = sessionData.('deviceNames');

    collectedData = struct();
    collectedData.dateMs = dateMs;
    collectedData.dateString = dateString;
    collectedData.time = time;
    collectedData.deviceNames = sessionData.('deviceNames');
%     keyboard;
    for d = 1:length(dNames)
        if isfield(sessionData.(dNames{d}),'sensors') && isfield(sessionData.(dNames{d}),'quaternion')
            aVector = sessionData.(dNames{d}).sensors.accelerometerVector;
            gVector = sessionData.(dNames{d}).sensors.gyroscopeVector;
            mVector =  sessionData.(dNames{d}).sensors.magnetometerVector;
            qVector = sessionData.(dNames{d}).quaternion.vector;    %Read quaternions from the file
            qVector = bsxfun(@times,qVector,1./sqrt(sum(qVector.^2,2)));        %Normalise quaternions just in case
    %         keyboard;
            %rotate accelerations with orientation quaternions
            accQuat = [zeros(size(aVector,1),1),aVector];
            rotatedAcc = quaternProd(quaternProd(quaternConj(qVector),[zeros(size(aVector,1),1),aVector]),qVector);
            rotatedAcc = rotatedAcc(:,2:4); %Drop the angle column from the quaternions
            %rotate gyrations with orientation quaternions
            rotatedGyro = quaternProd(quaternProd(quaternConj(qVector),[zeros(size(gVector,1),1),gVector]),qVector);
            rotatedGyro = rotatedGyro(:,2:4); %Drop the angle column from the quaternions
            %rotate magnetic fields with orientation quaternions
            rotatedMag = quaternProd(quaternProd(quaternConj(qVector),[zeros(size(mVector,1),1),mVector]),qVector);
            rotatedMag = rotatedMag(:,2:4); %Drop the angle column from the quaternions

            %Pop data into collectedData struct
            collectedData.(dNames{d}).aVector = aVector;
            collectedData.(dNames{d}).gVector = gVector;
            collectedData.(dNames{d}).mVector = mVector;
            collectedData.(dNames{d}).NGIMUAcc = rotatedAcc;
            collectedData.(dNames{d}).NGIMUGyro = rotatedGyro;
            collectedData.(dNames{d}).NGIMUMag = rotatedMag;
            collectedData.(dNames{d}).quat = qVector;
        end
        if isfield(sessionData.(dNames{d}),'analogue')
            collectedData.(dNames{d}).analogue = sessionData.(dNames{d}).analogue.vector;
        end
    end
end