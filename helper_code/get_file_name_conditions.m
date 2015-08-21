function file_name = get_file_name_conditions(labels_to_use, decode_on, train_condition_in, test_condition_in, is_special)
%Gives name for file given current naming conventions

if nargin() < 5
    is_special = 0;
end

if isempty(strfind(labels_to_use, 'rel'))
    rel_or_abs = 'abs';
else
    rel_or_abs = 'rel';
end

if train_condition_in == 1
    train_in = '_in_';
else
    train_in = '_out_';
end

if test_condition_in == 1
    test_in = '_in_';
else
    test_in = '_out_';
end

if strcmpi(decode_on, 'phi')
    not_decode = 'brt';
else
    not_decode = 'phi';
end
    
% save the results and file detailing code parameters
if test_condition_in == -1 && train_condition_in == -1
    file_name = ['Decode_' decode_on '_' rel_or_abs '_tr_all_' decode_on '_te_all_' decode_on];
else
    file_name = ['Decode_' decode_on '_' rel_or_abs '_tr_' not_decode train_in 'te_' not_decode test_in];
end

if is_special == 1

    if train_condition_in == 1
        tr_value = sprintf('_%d_', 0);
    else
        tr_value = sprintf('_%d_', 180);
    end
    
    file_name = strrep(file_name, train_in, tr_value);
    
    if test_condition_in == 1
        te_value = sprintf('_%d_', 0);
    else
        te_value = sprintf('_%d_', 180);
    end
    
    file_name = strrep(file_name, test_in, te_value);
end


end

