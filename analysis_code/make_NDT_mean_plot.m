function [] = make_NDT_mean_plot(monkey, area, labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, ...
                                    train_in, test_in, is_special, cell_no, use_fewer_NULL)
%Assume the following
time_type = 'window';
align = 'onset';

if strcmpi(ref, 'stimulus')
    time_vector = [-500 : 100 : 1400];
    time_start = -500;
    time_window = 2000;
else
    time_vector = [-1500 : 100 : -100];
    time_start = -1500;
    time_window = 1500;
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

null_ending = ['NULL_' dir_ending];

full_dir = fullfile(base_dir, 'results', dir_ending);
null_dir = fullfile(base_dir, 'results', null_ending);

if ~exist(full_dir, 'dir') || ~exist(null_dir, 'dir')
% 	warning('Directory (%s) containing results not found. Cell decoding for %s %s %s %s-aligned cell %d likely not completed.', full_dir, monkey, area, ref, align, cell_no);
	return;
end;

result_dir = dir(fullfile(full_dir, '*.mat'));

if size(result_dir) < 3 %therefore no result files
%     warning('Cell decoding for %s %s %s %s-aligned cell %d likely not completed.', monkey, area, ref, align, cell_no);
    return;
end

saved_file_name = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in, is_special);

% fprintf('Looking for p-value analysis of %s\n', fullfile(full_dir, saved_file_name));

ndt_plot = plot_standard_results_object({fullfile(full_dir, saved_file_name)});
ndt_plot.title = strrep(saved_file_name, '_', ' ');
ndt_plot.plot_time_intervals = time_vector;
ndt_plot.significant_event_times = 0;
ndt_plot.p_values = {fullfile(null_dir, saved_file_name)};
ndt_plot.p_value_alpha_level = 0.05;
ndt_plot.use_fewer_NULL = use_fewer_NULL;
% ndt_plot.the_axis = [time_vector 0 100];
ndt_plot.add_pvalue_latency_to_legends_alignment = 0;
ndt_plot.errorbar_stdev_multiplication_factor = 2;
the_figure = ndt_plot.plot_results();

% fprintf('\nDone with plot!\n\n');

if isempty(the_figure)
%     warning('Empty figure :(');
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

saveas(the_figure, fullfile(save_dir, sprintf('%s_mean_decoding.jpg', area)));

close(the_figure);

% fprintf('Saving as %s\n', fullfile(save_dir, sprintf('%s_mean_decoding.jpg', area)));
    
end

