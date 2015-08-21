function type_out = fix_task_case(type)
%Simply ensures that the case is correct for finding data file

if strcmpi(type, 'attention') == 1
    type_out = 'attention';
elseif strcmpi(type, 'mgs') == 1
    type_out = 'MGS_file';
else
    error('Task must be mgs or attention\n');
end