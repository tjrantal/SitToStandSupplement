function [time, resampledSessionData] = resampleSession(sessionData, newSamplePeriod)

    % Copy original structure
    resampledSessionData = sessionData;

    % Determine end time
    endTime = -Inf;
    for deviceIndex = 1:sessionData.numberOfDevices
        deviceName = sessionData.deviceNames{deviceIndex};
        csvFileNames = fieldnames(sessionData.(deviceName));
        for csvFileIndex = 1:length(csvFileNames)
            maxTime = max(sessionData.(deviceName).(csvFileNames{csvFileIndex}).time);
            if maxTime > endTime
%                 disp(sprintf('maxTime updated %s %s %d',deviceName,csvFileNames{csvFileIndex},maxTime))
                endTime = maxTime;
            end
        end
    end
    endTime = ceil(endTime);

    % Create resampled time vector
    time = [0:newSamplePeriod:endTime]';

    % Loop through each device
    for deviceIndex = 1:sessionData.numberOfDevices
        deviceName = sessionData.deviceNames{deviceIndex};

        % Loop through each CSV file
        csvFileNames = fieldnames(sessionData.(deviceName));
        for csvFileIndex = 1:length(csvFileNames)
            csvFileName = csvFileNames{csvFileIndex};

            % Overwrite time
            resampledSessionData.(deviceName).(csvFileName).time = time;

            % Interpolate quaternion CSV file
            if strcmp(csvFileName, 'quaternion')
                resampledSessionData.(deviceName).(csvFileName).vector = interpolateQuaternion(sessionData.(deviceName).(csvFileName).time, ...
                                                                                               sessionData.(deviceName).(csvFileName).vector, ...
                                                                                               time);
                resampledSessionData.(deviceName).quaternion.w = resampledSessionData.(deviceName).quaternion.vector(:,1);
                resampledSessionData.(deviceName).quaternion.x = resampledSessionData.(deviceName).quaternion.vector(:,2);
                resampledSessionData.(deviceName).quaternion.y = resampledSessionData.(deviceName).quaternion.vector(:,3);
                resampledSessionData.(deviceName).quaternion.z = resampledSessionData.(deviceName).quaternion.vector(:,4);
                continue;
            end

            % Skip rotation matrix CSV file
            if strcmp(csvFileName, 'matrix')
                sessionData.(deviceName) = rmfield(sessionData.(deviceName), csvFileName); % remove field
                warning('Rotation matrix cannot be resampled.  This field has been removed from the data structure.');
                continue;
            end

            % Loop through each CSV column
            csvColumnNames = fieldnames(sessionData.(deviceName).(csvFileName));
            for csvColumnIndex = 1:length(csvColumnNames)
                csvColumnName = csvColumnNames{csvColumnIndex};

                % Skip time column
                if strcmp(csvColumnName, 'time')
                    continue;
                end
                
                %Modified by Timo Rantalainen tjrantal at gmail dot com
                %2017/11/02
                %Check that we do not have duplicate time-stamps, use the
                %first sample for a given time-stamp
                sampledTime = sessionData.(deviceName).(csvFileName).time;
                sampledData = sessionData.(deviceName).(csvFileName).(csvColumnName);
                [sampledTime, indices] = unique(sampledTime);
                sampledData = sampledData(indices,:);
                if length(indices) > 2
                    % Interpolate data column
                    resampledSessionData.(deviceName).(csvFileName).(csvColumnName) = interp1(sampledTime, ...
                                                                                          sampledData, ...
                                                                                          time);
                end
            end
        end
    end
end

function interpolatedQuaternion = interpolateQuaternion(orginalTime, orginalQuaternion, newTime)

    % Linear interpolation, TODO: use slerp, https://en.wikipedia.org/wiki/Slerp
    interpolatedQuaternion = interp1(orginalTime, orginalQuaternion, newTime);

    % Normalise quaternion
    numberOfRows = size(interpolatedQuaternion, 1);
    for rowIndex = 1:numberOfRows
        interpolatedQuaternion(rowIndex,:) = interpolatedQuaternion(rowIndex,:) * (1 / norm(interpolatedQuaternion(rowIndex,:)));
    end
end

