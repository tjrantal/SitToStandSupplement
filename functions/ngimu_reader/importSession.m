function sessionData = importSession(sessionDirectory)

    % List directories and files in session directory
    directoryList = dir(sessionDirectory);

    % Error if session directory does not exist
    if isempty(directoryList)
        error('Session directory is empty or does not exist.');
    end

    % Error if Session.xml not present
    invalid = true;
    for directoryIndex = 1:length(directoryList)
        if strcmp('Session.xml', directoryList(directoryIndex).name)
            invalid = false;
        end
    end
    if invalid
        error('Invalid session directory (Session.xml not found).');
    end

    % Loop through each device directory
    for directoryIndex = 1:length(directoryList)

        % Skip the first 2 results which are always '.' and '..'
        if directoryIndex < 3
            continue;
        end

        % Skip if not directory
        if ~directoryList(directoryIndex).isdir
            continue;
        end

        % List files in device directory
        directoryPath = [sessionDirectory '/' directoryList(directoryIndex).name '/'];
        fileList = dir(directoryPath);

        % Add each CSV file to data structure
        deviceName = formatFieldName(directoryList(directoryIndex).name);
        for fileIndex = 1:length(fileList)
            filePath = [directoryPath fileList(fileIndex).name];

            % Skip if not CSV file
            [path, name, extension] = fileparts(filePath);
            if ~strcmp('.csv', extension)
                continue;
            end

            % Read CSV headings
            fileID = fopen(filePath);
            csvHeadings = strsplit(fgets(fileID), ',');
            fclose(fileID);

            % Read CSV file
            fileName = formatFieldName(name);
            csvData = dlmread(filePath, ',', 1, 0);

            % Remove repeated samples
            csvData = unique(csvData, 'rows');

            % Add each column to data structure
            for headingIndex = 1:length(csvHeadings)
                heading = formatFieldName(csvHeadings{headingIndex});
                sessionData.(deviceName).(fileName).(heading) = csvData(:,headingIndex);
            end
        end
    end

    % Add device names to data structure
    deviceNames = fieldnames(sessionData);
    sessionData.deviceNames = deviceNames;
    numberOfDevices = length(deviceNames);
    sessionData.numberOfDevices = numberOfDevices;

    % Add specific vector/matrix fields as combined CSV columns
    for deviceIndex = 1:sessionData.numberOfDevices
        deviceName = sessionData.deviceNames{deviceIndex};
        if isfield(sessionData.(deviceName), 'analogue')
            sessionData.(deviceName).analogue.vector = [sessionData.(deviceName).analogue.channel1, ...
                                                        sessionData.(deviceName).analogue.channel2, ...
                                                        sessionData.(deviceName).analogue.channel3, ...
                                                        sessionData.(deviceName).analogue.channel4, ...
                                                        sessionData.(deviceName).analogue.channel5, ...
                                                        sessionData.(deviceName).analogue.channel6, ...
                                                        sessionData.(deviceName).analogue.channel7, ...
                                                        sessionData.(deviceName).analogue.channel8];
        end
        if isfield(sessionData.(deviceName), 'earth')
            sessionData.(deviceName).earth.vector = [sessionData.(deviceName).earth.x, ...
                                                     sessionData.(deviceName).earth.y, ...
                                                     sessionData.(deviceName).earth.z];
        end
        if isfield(sessionData.(deviceName), 'euler')
            sessionData.(deviceName).euler.vector = [sessionData.(deviceName).euler.roll, ...
                                                     sessionData.(deviceName).euler.pitch, ...
                                                     sessionData.(deviceName).euler.yaw];
        end
        if isfield(sessionData.(deviceName), 'linear')
            sessionData.(deviceName).linear.vector = [sessionData.(deviceName).linear.x, ...
                                                      sessionData.(deviceName).linear.y, ...
                                                      sessionData.(deviceName).linear.z];
        end
        if isfield(sessionData.(deviceName), 'matrix')
            sessionData.(deviceName).matrix.matrix = zeros(3,3,length(sessionData.(deviceName).matrix.time));
            sessionData.(deviceName).matrix.matrix(1,1,:) = sessionData.(deviceName).matrix.xx;
            sessionData.(deviceName).matrix.matrix(2,1,:) = sessionData.(deviceName).matrix.xy;
            sessionData.(deviceName).matrix.matrix(3,1,:) = sessionData.(deviceName).matrix.xz;
            sessionData.(deviceName).matrix.matrix(1,2,:) = sessionData.(deviceName).matrix.yx;
            sessionData.(deviceName).matrix.matrix(2,2,:) = sessionData.(deviceName).matrix.yy;
            sessionData.(deviceName).matrix.matrix(3,2,:) = sessionData.(deviceName).matrix.yz;
            sessionData.(deviceName).matrix.matrix(1,3,:) = sessionData.(deviceName).matrix.zx;
            sessionData.(deviceName).matrix.matrix(2,3,:) = sessionData.(deviceName).matrix.zy;
            sessionData.(deviceName).matrix.matrix(3,3,:) = sessionData.(deviceName).matrix.zz;
        end
        if isfield(sessionData.(deviceName), 'quaternion')
            sessionData.(deviceName).quaternion.vector = [sessionData.(deviceName).quaternion.w, ...
                                                          sessionData.(deviceName).quaternion.x, ...
                                                          sessionData.(deviceName).quaternion.y, ...
                                                          sessionData.(deviceName).quaternion.z];
        end
        if isfield(sessionData.(deviceName), 'sensors')
            sessionData.(deviceName).sensors.gyroscopeVector = [sessionData.(deviceName).sensors.gyroscopeX, ...
                                                                sessionData.(deviceName).sensors.gyroscopeY, ...
                                                                sessionData.(deviceName).sensors.gyroscopeZ];
            sessionData.(deviceName).sensors.accelerometerVector = [sessionData.(deviceName).sensors.accelerometerX, ...
                                                                    sessionData.(deviceName).sensors.accelerometerY, ...
                                                                    sessionData.(deviceName).sensors.accelerometerZ];
            sessionData.(deviceName).sensors.magnetometerVector = [sessionData.(deviceName).sensors.magnetometerX, ...
                                                                   sessionData.(deviceName).sensors.magnetometerY, ...
                                                                   sessionData.(deviceName).sensors.magnetometerZ];
        end
    end
end


