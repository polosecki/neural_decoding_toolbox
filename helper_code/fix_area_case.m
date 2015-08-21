function area_out = fix_area_case(area)
%Simply ensures that the case is correct for finding overview file

if strcmpi(area, 'pitd') == 1
    area_out = 'PITd';
elseif strcmpi(area, 'lip') == 1
    area_out = 'LIP';
else
    error('Area must be LIP or PITd\n');
end