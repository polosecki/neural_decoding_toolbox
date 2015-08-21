function [decoding_results, params] = get_decoding_results(monkey, area, ref, align, cell_no, time_start, time_window, time_type, labels_to_use, decode_on, ...
                                                        train_condition_in, test_condition_in, is_restricted, is_restricted_by_top, num_top_cells, is_pop, is_special)

decoding_results = [];
params = [];

start_dir = strrep(mfilename('fullpath'), mfilename(), '');

monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
ref = fix_ref_case(ref);
align = fix_align_case(align);

labels_to_use = [labels_to_use '_results']; %to ensure that only exact (and not partial) file match is found
%For ex., this will avoid rel_phi yielding a file with rel_phi_brt

if strcmpi(time_type, 'window')
	align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' lower(time_type) '_clean'];
else
	align_str = [ref '_' align '_' num2str(time_start) '_' lower(time_type) '_clean'];
end

if is_pop == 1
    base_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['Population_' area '_' ref], align_str);
else
    cell_str = sprintf('cell_%03.0f', cell_no);
    base_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', [area '_' cell_str], align_str);
end

if is_restricted == 1
    if is_restricted_by_top == 1
        dir_ending = sprintf('restrict_top_%d', num_top_cells);
    else
        dir_ending = 'restricted_equal';
    end
else
    dir_ending = sprintf('unrestricted');
end

full_dir = fullfile(base_dir, 'results', dir_ending);

if ~exist(full_dir, 'dir')
% 	warning('Directory (%s) containing results not found. Cell decoding for %s %s %s %s-aligned cell %d likely not completed.', full_dir, monkey, area, ref, align, cell_no);
	return;
end;

result_dir = dir(fullfile(full_dir, '*.mat'));

if size(result_dir) < 3 %therefore no result files
%     warning('Cell decoding for %s %s %s %s-aligned cell %d likely not completed.', monkey, area, ref, align, cell_no);
    return;
end

saved_file_name = get_file_name_conditions(labels_to_use, decode_on, train_condition_in, test_condition_in, is_special);

to_load = -1;
to_copy = -1;

%Load the proper file
for i = 1 : size(result_dir)
    %Results
    if ~isempty(strfind(result_dir(i).name, saved_file_name)) && isempty(strfind(result_dir(i).name, 'params'))
        to_load = i;
    end
    %Variable containing decoding parameters
    if ~isempty(strfind(result_dir(i).name, saved_file_name)) && ~isempty(strfind(result_dir(i).name, 'params'))
        to_copy = i;
    end
end
    
if to_load == -1
    warning('Desired cell (%s %s %s %s-aligned cell population) and training condition (%s) not found\n', monkey, area, ref, align, labels_to_use);
    return;
end
    
if to_copy == -1
    warning('Desired cell (%s %s %s %s-aligned cell population) and training condition (%s) has no parameter-detailing variable\n', monkey, area, ref, align, labels_to_use);
    params = [];
    return;
else
    params = load(fullfile(full_dir, result_dir(to_copy).name));
    if isempty(params.results)
        fprintf('Cell %d: failed load of params\n', cell_no);
    end
end

% fprintf('Loading %s\n', fullfile(full_dir, result_dir(to_load).name));

decoding_results = load(fullfile(full_dir, result_dir(to_load).name));

end

