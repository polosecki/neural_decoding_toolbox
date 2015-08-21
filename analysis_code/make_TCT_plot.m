function [] = make_TCT_plot(monkey, area, labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, is_special, cell_no)
%Assume the following
time_type = 'window';
align = 'onset';

if strcmpi(ref, 'stimulus')
    time_vector = [-500 : 100 : 1400];
    time_start = -500;
    time_window = 2000;
else
    time_vector = [-1500 : 100 : -100];
    time_start = -800;%-1500;
    time_window = 800;%1500;
end

monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
ref = fix_ref_case(ref);
align = fix_align_case(align);

labels_to_use = [labels_to_use '_results']; %to ensure that only exact (and not partial) file match is found
%For ex., this will avoid rel_phi yielding a file with rel_phi_brt

align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' lower(time_type) '_clean'];

if is_pop == 1
    base_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['Population_' area '_' ref], align_str);
elseif nargin() > 11
    cell_str = sprintf('cell_%03.0f', cell_no);
    base_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', [area '_' cell_str], align_str);
else
    error('If not population, must specify a cell number as last input argument');
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

saved_file_name = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in, is_special);

tct_matrix = plot_standard_results_TCT_object(fullfile(full_dir, saved_file_name));
tct_matrix.decoding_result_type_name = strrep(saved_file_name, '_', ' ');
tct_matrix.plot_time_intervals = time_vector;
tct_matrix.display_TCT_movie = 0;
tct_matrix.color_result_range = [0 100];
tct_matrix.significant_event_times = 0;
[~, the_figure] = tct_matrix.plot_results();

if isempty(the_figure)
    return;
end

root_dir = '/Freiwald/ppolosecki/lspace/plevy/figures/comparative';

if is_pop == 1
    save_dir = fullfile(root_dir, monkey, ref, 'population', saved_file_name, dir_ending);
else
    save_dir = fullfile(root_dir, monkey, ref, 'single_cell', saved_file_name, dir_ending);
end

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

if is_pop == 1
    full_save = fullfile(save_dir, sprintf('%s_tct.jpg', area));
else
    full_save = fullfile(save_dir, sprintf('cell_%d_%s_tct.jpg', cell_no, area));
end

saveas(the_figure, full_save);
    
%Save as SVG
% addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
% plot2svg(strrep(full_save, '.jpg', '.svg'), the_figure);

saveas(the_figure, strrep(full_save, '.jpg', '.eps'), 'epsc');

close(the_figure);

% fprintf('Saving as %s\n', fullfile(save_dir, sprintf('%s_tct.jpg', area)));
    
end

