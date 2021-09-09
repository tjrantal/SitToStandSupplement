%%Taken from mathworks help https://se.mathworks.com/help/matlab/ref/xmlread.html

function theStruct = parseXML(filename)
    % PARSEXML Convert XML file to a MATLAB structure.
    try
       tree = xmlread(filename);
    catch
       error('Failed to read XML file %s.',filename);
    end

    % Recurse over child nodes. This could run into problems 
    % with very deeply nested trees.
    try
		%disp('Start parsing child');
       theStruct = parseChildNodes(tree);
    catch
       error('Unable to parse XML file %s.',filename);
    end
