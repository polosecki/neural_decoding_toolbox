function [save_dir, params_save] = analyze_confusion(params)
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

start_cell = params.cell_start;
end_cell = params.cell_end;

%This block takes care of itself, for save name
if end_cell - start_cell == 0
    is_one_cell = 1;
else
    is_one_cell = 0;
end

if is_one_cell == 0
    sub_dir = 'Single_Cell_Analysis';
else
    sub_dir = 'Simple_Checks';
end

if ~exist(fullfile(root_dir, sub_dir), 'dir')
    mkdir(fullfile(root_dir, sub_dir));
end

save_dir = fullfile(root_dir, sub_dir);

%% 2. Everything else

monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
ref = fix_ref_case(ref);
align = fix_align_case(align);

params_save = [];
time_vector = [];

if with_resamples == 1
    
    count = 1;
    
    for cell_no = start_cell : end_cell
        [conf_matrix, decode_params] = get_confusion_matrix(monkey, area, ref, align, cell_no, time_start, time_window, time_type, train_condition, ...
                                                                decode_on, train_in, test_in, is_restricted, is_restricted_by_top, num_top_cells, with_resamples, is_special);
                           
        if isempty(conf_matrix) || isempty(decode_params)
            continue;
        end
        
        if ~isempty(decode_params) && isempty(params_save)
            params_save = decode_params;
        end
                                                            
        for class_index = 1 : classes
           [curr_mean, ~] = analyze_resample_confusion(conf_matrix, class_to_analyze, class_index, classes, analysis_type, is_special);
           all_means(count, class_index, :) = curr_mean;
        end
        
        count = count + 1;
        
        if isempty(time_vector)
            time_vector = decode_params.results.time_vector;
        end
        
    end
    
    valid_cells = count - 1;
    
    for class_index = 1 : classes
        means(class_index, :) = mean(all_means(:, class_index, :), 1);
        errors(class_index, :) = 2*std(all_means(:, class_index, :), 0, 1)/sqrt(valid_cells);
    end
    
else
    
    [means, errors, params_save, time_vector] = get_confusion_analysis(start_cell, end_cell, params, is_special);
    
end

[parts, ~] = strsplit(train_condition, '_');
train_condition_split = strjoin(parts, '\\_');

colors = hsv(classes); %get unique colors

% fprintf('Time vector: [%d X %d]\n', size(time_vector, 1), size(time_vector, 2));
% fprintf('Means vector: [%d X %d]\n', size(means(1, :), 1), size(means(1, :), 2));
% fprintf('Errors vector: [%d X %d]\n', size(errors(1, :), 1), size(errors(1, :), 2));

graph = figure();
hold on;
for i = 1 : classes
    plots(i) = shadedErrorBar(time_vector, means(i, :), errors(i, :), {'Color', colors(i, :)});
    plots_to_use(i) = plots(i).mainLine; %mainLine represents actual line, from shadedErrorBar code author
    test_labels = get_decoder_labels_plot(decode_on, train_condition, test_in, i);
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
legend('show')

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

if is_one_cell == 0
    save_dir = fullfile(save_dir, monkey, ref, title_save, dir_ending);
else
    save_dir = fullfile(save_dir, monkey, ref, [title_save '_cell_' num2str(start_cell)], dir_ending);
end

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

to_save = sprintf('%s_class_%d_%s', area, class_to_analyze, analysis_type);

saveas(graph, fullfile(save_dir, [to_save '.jpg']));

%Save as SVG
addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
plot2svg(fullfile(save_dir, [to_save '.svg']), graph);

close(graph);

close(graph);

% fprintf('Saving as %s\n', fullfile(save_dir, [to_save '.jpg']));

if ~exist(fullfile(save_dir, 'decode_params'), 'dir');
    mkdir(fullfile(save_dir, 'decode_params'));
end

save(fullfile(save_dir, 'decode_params', [to_save '_params.mat']), 'params_save');
        