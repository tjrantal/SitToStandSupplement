

fclose all;
close all;
clear all;
clc;

javaaddpath('source/concordancecorrelationcoefficient/build/libs/concordancecorrelationcoefficient-1.0.jar');   %Synchronisation using concordance correlation coefficient https://github.com/tjrantal/concordancecorrelationcoefficient
addpath('functions');	%Utility functions
addpath('functions/ngimu_reader');	%Seb Madgwick's x-io NGIMU reader
addpath('functions/quaternion_library'); %Seb Madgwick's quaternion library
addpath('functions/dlt2D'); %2D DLT functions for scaling image coordinates to global
addpath('functions/posture');	%Posture calculation helper functions

dataPath = 'data/NGIMU/';
coordinatePath = 'data/video/';

plotDebugFigures = 0;   %1 to plot debugging figures

constants = struct();
constants.sFreq = 200;

constants.epochLength = 5;
constants.summaryEpochLength = 5;
constants.minLength = 30;   %This was 20 s in the paper but was extended to 30 s to get the correct reference orientation in this lab sample
constants.limits.chest = [0.035 0.6];
constants.limits.thigh = [0.035 2.0];



calibObjCoords = [0,0;0,0.74;0.59,0;0.59,0.74]; %2D calibration object laboratory coordinates

%Sort NGIMUs
serialWearLocationCorrespondence = readtable('serial_location_correspondence.txt','Delimiter','\t','ReadVariableNames',1);
interestingDevices = {'Thigh','Chest'};
interestingDeviceSerialindices = zeros(length(interestingDevices),1);
for i = 1:length(interestingDevices)
    interestingDeviceSerialindices(i) = find(cellfun(@(x) ~isempty(x), cellfun(@(x) strfind(x,interestingDevices{i}), {serialWearLocationCorrespondence.('WearLocation'){:}},'uniformoutput',0)) == 1,1,'first');
end
interestingDeviceSerial = lower({serialWearLocationCorrespondence.('Serial'){interestingDeviceSerialindices}});

[b,a] = butter(2,1/(constants.sFreq/2));    %1 Hz low-pass filter
[ifb,ifa] = butter(2,5/(constants.sFreq/2));    %5 Hz low-pass filter

participants = getFilesAndFolders(dataPath);
for p = {participants(:).name}
    ngimu = getNGIMUData([dataPath p{1}],constants);	%Reads the MIMU signals, and interpolates to a constant sample rate (to account for lost packets, sampling rate differences between devices etc)
    aThigh = ngimu.(['ngimu' lower(interestingDeviceSerial{1})]).aVector;   %Sensor accelerations
    
    %Remove nan values from the accelerations
    keepSamples = ~isnan(aThigh(:,1)) & ~isnan(aThigh(:,2)) & ~isnan(aThigh(:,3));
    aThigh = aThigh(keepSamples,:);
    ngimu.time = ngimu.time(keepSamples);
    %Calculate thigh angle based on video-based marker trajectories
    tempCalib = readLog([coordinatePath p{1} '/' 'calib.txt'],'\t',0);  %2D calibration object digitised coordinates
    dltCoeffs = calc2DDLTCoeffs(calibObjCoords,tempCalib.data(:,3:4));  %2D direct-linear-transformation coefficients

    %Calculate global coordinates + vector angle from vertical
    kneeCoords = readLog([coordinatePath p{1} '/' 'knee.txt'],'\t',0);  %Digitised knee marker coordinates
    thighCoords = readLog([coordinatePath p{1} '/' 'thigh.txt'],'\t',0);    %Digitised thigh marker coordinates

    %DEBUGGING
    if plotDebugFigures 
        figure
        plot(kneeCoords.data(:,3),kneeCoords.data(:,4),'k')
        hold on;
        plot(thighCoords.data(:,3),thighCoords.data(:,4),'r')
    end
    
    %Figure out time stamp intersection betwen the thigh and the knee
    %markers
    minMax = [max([kneeCoords.data(1,1) thighCoords.data(1,1)]) min([kneeCoords.data(end,1) thighCoords.data(end,1)])];
    gknee = getGlobal2D(dltCoeffs,kneeCoords.data(kneeCoords.data(:,1) >=minMax(1) & kneeCoords.data(:,1) <=minMax(2),3:4));
    gthigh = getGlobal2D(dltCoeffs,thighCoords.data(thighCoords.data(:,1) >=minMax(1) & thighCoords.data(:,1) <=minMax(2),3:4));
    gTime = thighCoords.data(thighCoords.data(:,1) >=minMax(1) & thighCoords.data(:,1) <=minMax(2),2);
    gTime = gTime-gTime(1);
    vsRate = 1/mean(diff(gTime));   %Virtual sample rate
    %Thigh segment posture angle calculation. 
    thighVector = gthigh-gknee;
    thighNorm = thighVector./vecnorm(thighVector,2,2);
    thighAngle = acos(dot(thighNorm,repmat([0,1],size(thighNorm,1),1),2));  %Angle between global vertical and the thigh
    [vfb,vfa] = butter(2,5/(vsRate/2)); 
    fva = filtfilt(vfb,vfa,thighAngle); %Low-pass filter motion capture-based orientation angle to match accelerometer-based analysis
    %DEBUGGING
    if plotDebugFigures 
        figure,plot(thighAngle)
    end
    
    %APE calculation, figure out reference posture as done in daily
    %recordings
    temp = struct();
    [temp.mad, temp.x, temp.y, temp.z] = getMAD(aThigh,ngimu.time,5);   %Calculate 5 s non-overlapping mean amplitude deviation, and mean X, Y, and Z accelerations
    ref = getReferencePosture(temp,constants.limits.('thigh'),constants);
    
    %Calculate angle between reference orientation (ref), and instantaneous
    %acceleration. Accelerations are 4th order 1 Hz zerolag filtered to
    %minimise the effects of movement into the instantaneous orientation
    %estimate
    raw = struct();
    raw.x = filtfilt(b,a,aThigh(:,1));
    raw.y = filtfilt(b,a,aThigh(:,2));
    raw.z = filtfilt(b,a,aThigh(:,3));
    imuAngle = getPostureAngle(raw,ref);    %Calculate instantaneous accelerometer orientation angle    
    fia = filtfilt(ifb,ifa,imuAngle);   %Low-pass filter accelerometer-based orintation angle 
    
    %Create synchronisation signal
    syncInstants = ngimu.time(1):(1/vsRate):ngimu.time(end);
    syncAngle = interp1(ngimu.time,fia,syncInstants);
    synchOffs = synchroniseRecords(syncAngle,fva);
    
    %Daily sit-to-stand transition detection algorithm (can only detect the
    %first sit-to-stand of a bout of continuous sit-to-stands
    aResultant = sqrt(sum(aThigh.^2,2));
    fAPE = fia(1:2:end);   %subsample to 100 Hz sample rate to correspond to the accelerometer used in daily records
    res = aResultant(1:2:end);   %subsample to 100 Hz sample rate to correspond to the accelerometer used in daily records
    fAPEStamps = ngimu.time(1:2:end);   %subsample to 100 Hz sample rate to correspond to the accelerometer used in daily records
    [stsIndices, stsAngularVelocities,  ~, fitIndices] = getSTS(ngimu.time,fia,aResultant,constants.sFreq);
    figure
    plot(ngimu.time,fia,'k');
    hold on;
    plot(ngimu.time(stsIndices),fia(stsIndices),'k*','linestyle','none');
    cellfun(@(x) plot(ngimu.time(x),fia(x),'k','linewidth',3),fitIndices);
    cellfun(@(x,y,z) text(x,y,sprintf('%.1f',z/pi*180)),num2cell(ngimu.time(stsIndices)),num2cell(ones(length(stsIndices),1).*max(fia(stsIndices))+0.1),stsAngularVelocities);
    
    %TEST STS from MOCAP
    meanThighVector = (gthigh+gknee)./2;
    thighVelocity = (meanThighVector(2:end,:)-meanThighVector(1:end-1,:)).*vsRate;
    thighVelocity = [filtfilt(vfb,vfa,thighVelocity(:,1)), filtfilt(vfb,vfa,thighVelocity(:,2))]; %Low-pass velocities to prevent differentiation noise form propagating
    thighAcceleration = (thighVelocity(2:end,:)-thighVelocity(1:end-1,:)).*vsRate;
    thighGs = thighAcceleration./9.81;
    thighGs(:,2) = thighGs(:,2) +1;
    thighRes = sqrt(sum(thighGs.^2,2));
    thighRes = [0; 0; thighRes];
    mocapStamps = ([1:length(fva)]-1)./vsRate+syncInstants(synchOffs);
    [mocapStsIndices, mocapStsAngularVelocities, ~ ,mocapFitIndices] = getSTS(mocapStamps,fva,thighRes,vsRate);
    plot(mocapStamps,fva,'b');
    hold on;
    plot(mocapStamps(mocapStsIndices),fva(mocapStsIndices),'b*','linestyle','none');
    cellfun(@(x) plot(mocapStamps(x),fva(x),'b','linewidth',3),mocapFitIndices);
    
    cellfun(@(x,y,z) text(x,y,sprintf('%.1f',z/pi*180)),num2cell(mocapStamps(mocapStsIndices)'),num2cell(ones(length(mocapStsIndices),1).*min(fva(mocapStsIndices))-0.1),mocapStsAngularVelocities);
    title(sprintf('%s 2D motion capture thigh angle (blue) vs. thigh IMU APE (black)',p{1}));
%     keyboard;

end

