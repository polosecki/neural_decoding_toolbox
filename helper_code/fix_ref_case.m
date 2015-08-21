function align_out = fix_ref_case(ref)
%Simply ensures that the case is correct for finding data file

if strcmpi(ref, 'stimulus') == 1
    align_out = 'stimulus';
elseif strcmpi(ref, 'saccade') == 1
    align_out = 'saccade';
else
    error('Invalid alignment type\nMust be stimulus or saccade\n');
end