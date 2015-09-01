function LineNo = findstringline(y,str)
% LineNo = findstringline(y,str)
% Inputs:
% y is the file name of the text file
% str is the target string
% Outputs:
% LineNo is a row with the line numbers where the str appears on file y

fid = fopen(y);                 % Open file y

LineNo = [];                    % Create empty array for line numbers
line = 0;                       % Initialize line counter

while 1
    line = line + 1;            % Increment line number counter
    linestr = fgetl(fid);       % Get the string of each line
    
    
    if ~ischar(linestr)         % If end of file
        break                   % break loop
    end
    
    k = strfind(linestr,str);   % Determine if string str is present in that line
    
    if ~isempty(k)              % If string is present
        LineNo = [LineNo line]; % record line number
    end       
end

if isempty(LineNo)              % If no entries in LineNo array
    disp(['SORRY, STRING ' str ' NOT FOUND IN FILE ' y]);   % then str was never found in file y
end

fclose(fid)                     % Close out file