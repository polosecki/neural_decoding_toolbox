function [means, errors, params_save, time_vector] = get_confusion_analysis(start_cell, end_cell, params)
                                
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

if time_window == 0
    time_type = 'slice';
else
    time_type = 'window';
end

train_in = params.train_in;
test_in = params.test_in;

is_restricted = params.is_restricted;
is_restricted_by_top = params.is_restricted_by_top;
num_top_cells = params.num_top_cells;

with_resamples = params.with_resamples;
                                
is_special = params.is_special;

num_cells = end_cell - start_cell + 1;

separate_matrices = [];
index_to_add = 1;

params_save = [];
time_vector = [];

for cell_no = start_cell : end_cell
    [conf_matrix, decode_params] = get_confusion_matrix(monkey, area, ref, align, cell_no, time_start, time_window, time_type, train_condition, ...
                                                        decode_on, train_in, test_in, is_restricted, is_restricted_by_top, num_top_cells, with_resamples, is_special);


    if ~isempty(decode_params) && isempty(params_save)
        params_save = decode_params;
    end

    %While decode_params will change each time, the relevant portion
    %(time_vector) will be consistent across cells

    if isempty(separate_matrices) %hasn't been created yet
        time_vector = decode_params.results.time_vector;
        num_time_bins = size(time_vector, 2);
        separate_matrices = NaN(classes, classes, num_time_bins, num_cells);
    end

    if isempty(conf_matrix) || isempty(decode_params)
        separate_matrices(:, :, :, index_to_add) = [];
        continue;
    end

    if size(conf_matrix, 1) ~= classes || size(conf_matrix, 2) ~= classes
        separate_matrices(:, :, :, index_to_add) = [];
        continue;
    end

    separate_matrices(:, :, :, index_to_add) = conf_matrix;
    index_to_add = index_to_add + 1;
end

valid_cells = size(separate_matrices, 4);

combined_results = NaN(classes, valid_cells, num_time_bins);

for time = 1 : num_time_bins
    for cell_no = 1 : valid_cells
        frac_results = analyze_confusion_slice(separate_matrices(:, :, time, cell_no), class_to_analyze, analysis_type, classes);
        for class = 1 : size(frac_results, 2)
            combined_results(class, cell_no, time) = frac_results(1, class);
        end
    end
end

results = NaN(classes, 2, num_time_bins); %One column for mean, one for std err

for time = 1 : num_time_bins
    for class = 1 : classes
        results(class, 1, time) = mean(combined_results(class, :, time));
        stddev = std(combined_results(class, :, time));
        results(class, 2, time) = 2*stddev/sqrt(valid_cells);
    end
end

means = squeeze(results(:, 1, :));
errors = squeeze(results(:, 2, :));

end