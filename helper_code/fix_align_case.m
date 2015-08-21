function align_out = fix_align_case(align)
%Simply ensures that the case is correct for finding data file

if strcmpi(align, 'onset') == 1
    align_out = 'onset';
elseif strcmpi(align, 'start') == 1
    align_out = 'start';
else
    error('Invalid alignment type\nMust be start or onset\n');
end