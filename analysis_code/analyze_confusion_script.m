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

%% 1. Change these variables
classes = 2;

class_to_analyze = 1;
analysis_type = 'presented';
% analysis_type = 'guessed';

% train_condition = 'rel_brt';
train_condition = 'rel_phi_brt';
% train_condition = 'rel_phi';

decode_on = 'phi';
% decode_on = 'brt';

monkey = 'quincy';
% monkey = 'michel';

area = 'lip';
% area = 'pitd';

ref = 'stimulus';
% ref = 'saccade';

align = 'onset';
time_start = -500;
time_window = 2000;
time_type = 'window';

start_cell = 29;
max_cells = 29; %monkey_area_cells(monkey, area);

%This block takes care of itself, for save name
if max_cells - start_cell == 0
    is_one_cell = 1;
else
    is_one_cell = 0;
end

sub_dir = 'Simple_Checks';

if ~exist(fullfile(root_dir, sub_dir), 'dir')
    mkdir(fullfile(root_dir, sub_dir));
end

save_dir = fullfile(root_dir, sub_dir);

%% 2. Everything else
start_dir = strrep(mfilename('fullpath'), mfilename(), '');

cd('../helper_code/');
monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
ref = fix_ref_case(ref);
align = fix_align_case(align);
cd(start_dir);

num_cells = max_cells - start_cell + 1;

bin_length = 100; %Currently 100 mS
num_bins = time_window/bin_length;

seperate_matrices = NaN(classes, classes, num_bins, num_cells);
index_to_add = 1;

for cell_no = start_cell : max_cells
	conf_matrix = get_confusion_matrix(monkey, area, ref, align, cell_no, time_start, time_window, time_type, train_condition, decode_on);
    
    if isempty(conf_matrix)
        seperate_matrices(:, :, :, index_to_add) = [];
        continue;
    end
    
    if size(conf_matrix, 1) ~= classes || size(conf_matrix, 2) ~= classes
        seperate_matrices(:, :, :, index_to_add) = [];
        continue;
    end
    
    seperate_matrices(:, :, :, index_to_add) = conf_matrix;
    index_to_add = index_to_add + 1;
end

valid_cells = size(seperate_matrices, 4);

fprintf('%d valid cells for %s %s analysis\n', valid_cells, monkey, area);

combined_results = NaN(classes, valid_cells, num_bins);

for time = 1 : num_bins
    for cell_no = 1 : valid_cells
        frac_results = analyze_confusion_slice(seperate_matrices(:, :, time, cell_no), class_to_analyze, analysis_type, classes);
        for class = 1 : size(frac_results, 2)
            combined_results(class, cell_no, time) = frac_results(1, class);
        end
    end
end

results = NaN(classes, 2, num_bins); %One column for mean, one for std err

for time = 1 : num_bins
    for class = 1 : classes
        results(class, 1, time) = mean(combined_results(class, :, time));
        stddev = std(combined_results(class, :, time));
        results(class, 2, time) = stddev/sqrt(valid_cells - 1);
    end
end

means = squeeze(results(:, 1, :));
sem = squeeze(results(:, 2, :));

[parts, ~] = strsplit(train_condition, '_');
train_condition_split = strjoin(parts, '\\_');

% figure();
% bar(means);
% line(xlim, [1/classes 1/classes], 'Color', 'k');
% title([monkey '\_' area '\_' 'class\_' num2str(class_to_analyze) '\_' train_condition_split '\_' analysis_type]);        

colors = hsv(classes); %get unique colors

% labels = cell(1, classes);

graph = figure();
hold on;
for i = 1 : classes
    x = 1 : size(means, 2);
    plots(i) = shadedErrorBar(x, means(i, :), sem(i, :), {'Color', colors(i, :)});
    plots_to_use(i) = plots(i).mainLine; %mainLine represents actual line, from shadedErrorBar code author
    labels{i} = sprintf('class %d', i);
end

line(xlim, [1/classes 1/classes], 'Color', 'k');
title([monkey '\_' area '\_' 'class\_' num2str(class_to_analyze) '\_' train_condition_split '\_' analysis_type]);
legend(plots_to_use(1, :), labels);
legend('show');

hold off;

save_dir = fullfile(save_dir, ['decode_' decode_on '_' ref '_onset_by_' train_condition]);

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

if is_one_cell == 0
    to_save = [monkey '_' area '_class' num2str(class_to_analyze) '_' analysis_type '.jpg'];
else
    to_save = [monkey '_' area '_class' num2str(class_to_analyze) '_' analysis_type '_cell_' num2str(start_cell) '.jpg'];
end

saveas(graph, fullfile(save_dir, to_save));

fprintf('Saving as %s\n', fullfile(save_dir, to_save));
        