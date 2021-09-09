%Function to read NGIMU session data
%@params sessioPath, the path to Session.xml
%@params constants, a structure with desired sampling rate .sFreq
%@returns a structure with data re-sampled to constants.sFreq sample rate
%Hack to get date from NGIMU Session.xml with Octave
function dateString = octaveGetDate(fileName)

	fh = fopen(fileName,'r');
	lineOfData = strtrim(fgetl(fh));
	while isempty(strfind(lower(lineOfData),lower('Date'))) && isempty(strfind(lower(lineOfData),lower('SessionInformation')))
		lineOfData = strtrim(fgetl(fh));
    end
    fclose(fh);
    %Split the row at spaces, not including spaces between double quotes
    [siSplits siMatches] = strsplit(lineOfData,'("[^"]*")|[^\s]','DelimiterType','RegularExpression');

    
    dateIndex = find(cellfun(@(x) ~isempty(strfind(lower(x),'date')),siMatches) ==1);
    tempSplit = strsplit(siMatches{dateIndex},'=');
    dateString = strrep(tempSplit{2},'"','');   %Eliminate double quotes
    
