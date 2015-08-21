function [save_dir, decode_params] = analyze_confusion_population(params)
%For given monkey and area, determines mean and stderr of
%	for class i presented
%		fraction of guesses for each class
%	for class i guessed
%		fraction of presented from each class
%
%Given analysis type of [class x class] matrix where 
%   row represents stimulus guessed and 
%   column represents stimulus presented
%analysis_type = 'presented' or 'guessed'
%tells whether the index represents a row or column

root_dir = '/Freiwald/ppolosecki/lspace/plevy/figures';

%% 1. Set up parameters
classes = params.num_classes;

class_to_analyze = params.analyze_class;
analysis_type = params.analysis_type;

train_condition = params.labels_to_use;

decode_on = params.decode_on;

monkey = params.monkey;

area = params.area;

ref = params.ref;

align = params.align;
time_start = params.time_start;
time_window = params.time_window;

train_in = params.train_in;
test_in = params.test_in;

is_restricted = params.is_restricted;
is_restricted_by_top = params.is_restricted_by_top;
num_top_cells = params.num_top_cells;

with_resamples = params.with_resamples;

is_special = params.is_special;

if time_window == 0
    time_type = 'slice';
else
    time_type = 'window';
end

sub_dir = 'Population_Analysis';

if ~exist(fullfile(root_dir, sub_dir), 'dir')
    mkdir(fullfile(root_dir, sub_dir));
end

save_dir = fullfile(root_dir, sub_dir);

%% 2. Everything else

monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
ref = fix_ref_case(ref);
align = fix_align_case(align);

[conf_matrix, decode_params] = get_confusion_matrix_population(monkey, area, ref, align, time_start, time_window, time_type, train_condition, decode_on, ...
                                    train_in, test_in, is_restricted, is_restricted_by_top, num_top_cells, with_resamples, is_special);   

if isempty(conf_matrix) || isempty(decode_params)
    warning('No valid confusion matrix found!');
    save_dir = [];
    return;
end

time_vector = decode_params.results.time_vector;

num_time_bins = size(time_vector, 2);

if with_resamples == 1
    
    for class_index = 1 : classes
        
        [curr_mean, curr_error, num_resamples] = analyze_resample_confusion(conf_matrix, class_to_analyze, class_index, classes, analysis_type);
        
%         fprintf('Resamples is [%d X %d]\n', size(num_resamples, 1), size(num_resamples, 2));
        
        means(class_index, :) = curr_mean;
        %PIP 9/18/2014
        errors(class_index, :) = curr_error;%2*curr_error ./ sqrt(num_resamples);
        
%         if num_resamples ~= decode_params.results.num_resample_runs
%             error('Number of resamples (%d) in decoding parameter file not equal to number of resamples in matrix (%d)', ...
%                         decode_params.results.num_resample_runs, num_resamples);
%         end
        
    end
    
else

    [means, errors] = get_confusion_analysis_pop(conf_matrix, decode_params, classes, class_to_analyze, ...
                            analysis_type, num_time_bins);
    
end

colors = hsv(classes); %get unique colors

graph = figure();
hold on;

for i = 1 : classes
    plots(i) = shadedErrorBar(time_vector, means(i, :), errors(i, :), {'Color', colors(i, :)});
    plots_to_use(i) = plots(i).mainLine; %mainLine represents actual line, from shadedErrorBar code author
    test_labels = get_decoder_labels_plot(decode_on, train_condition, test_in, i, is_special);
    labels{i} = strrep(test_labels, '_', ' ');
end


ylim([0 1]);
line(xlim, [1/classes 1/classes], 'Color', 'k');

%indicate line of saccade or stimulus onset
if strcmpi(ref, 'stimulus')
    line([0 0], ylim, 'Color', 'k', 'LineWidth', 2);
else
    line([0 0], ylim, 'Color', 'k', 'LineWidth', 2);
end

title_save = get_file_name_conditions(train_condition, decode_on, train_in, test_in, is_special);

title_str = strrep(title_save, '_', ' ');

title(sprintf('%s class %d %s', title_str, class_to_analyze, analysis_type));
legend(plots_to_use(1, :), labels, 'Location', 'SouthWest');
legend('show');

hold off;

if is_restricted == 1
    if is_restricted_by_top == 1
        dir_ending = sprintf('restrict_top_%d', num_top_cells);
    else
        dir_ending = sprintf('restricted_equal');
    end
else
    dir_ending = sprintf('unrestricted');
end

save_dir = fullfile(save_dir, monkey, ref, title_save, dir_ending);

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

to_save = sprintf('%s_class_%d_%s', area, class_to_analyze, analysis_type);

saveas(graph, fullfile(save_dir, [to_save '.jpg']));

%Save as SVG
addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
plot2svg(fullfile(save_dir, [to_save '.svg']), graph);

close(graph);

% fprintf('Saving plot as %s\n', fullfile(save_dir, [to_save '.jpg']));

if ~exist(fullfile(save_dir, 'decode_params'), 'dir');
    mkdir(fullfile(save_dir, 'decode_params'));
end

save(fullfile(save_dir, 'decode_params', [to_save '_params.mat']), 'decode_params');


