function fieldName = formatFieldName(originalText)

    % Remove trailing parentheses
    splitOriginalText = strsplit(originalText, '(');
    formattedOriginalString = splitOriginalText{1};

    % Remove non-alphanumeric characters
    formattedOriginalString(~ismember(formattedOriginalString, ['0':'9', 'A':'Z', 'a':'z'])) = ' ';

    % Create lower camel case string
    words = lower(strsplit(formattedOriginalString, ' '));
    fieldName = words{1};
    for wordIndex = 2:length(words)
        if length(words{wordIndex}) == 0
            continue;
        end
        words{wordIndex}(1) = upper(words{wordIndex}(1));
        fieldName = [fieldName words{wordIndex}];
    end
end