function [means, errors] = get_confusion_analysis_pop(conf_matrix, decode_params, classes, ...
                                    class_to_analyze, analysis_type, num_time_bins)

num_cells = 1; %Population, but kept this way to avoid changing code...

separate_matrices = NaN(classes, classes, num_time_bins, num_cells);

if size(conf_matrix, 1) ~= classes || size(conf_matrix, 2) ~= classes
    separate_matrices(:, :, :, 1) = [];
    warning('Confusion matrix found has incorrect number of decoding classes!');
    save_dir = [];
    return;
end

if isempty(decode_params)
    warning('No valid decoding parameters variable! No graph made.');
    return;
end

separate_matrices(:, :, :, 1) = conf_matrix;

valid_cells = size(separate_matrices, 4); %should be 1

% fprintf('%d valid cells for %s %s population analysis (should be 1)\n', valid_cells, monkey, area);

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
        %PIP 9/18/2019
        results(class, 2, time) = stddev;%2*stddev/sqrt(decode_params.results.num_resample_runs);
    end
end

means = squeeze(results(:, 1, :));
errors = squeeze(results(:, 2, :));

end

