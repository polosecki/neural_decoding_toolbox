function [conf_matrix, params] = get_confusion_matrix_population(monkey, area, ref, align, time_start, time_window, time_type, labels_to_use, decode_on, ...
                                                    train_condition_in, test_condition_in, is_restricted, is_restricted_by_top, num_top_cells, with_resamples, is_special)

conf_matrix = [];

is_pop = 1;

arbitrary_cell = 1; %Not important for getting population results

[decoding_results, params] = get_decoding_results(monkey, area, ref, align, arbitrary_cell, time_start, time_window, time_type, labels_to_use, decode_on, ...
                                                        train_condition_in, test_condition_in, is_restricted, is_restricted_by_top, num_top_cells, is_pop, is_special);
if isempty(decoding_results) || isempty(params)
    return;
end
                                                    
DECODING_RESULTS = decoding_results.DECODING_RESULTS;
                                                    
if isempty(DECODING_RESULTS)
    warning('Valid cell decoding for %s %s %s %s-aligned cell population not completed with train/test in %d/%d.', ...
                        monkey, area, ref, align, train_condition_in, test_condition_in);
    return;
end
    
if with_resamples == 1
    names = fieldnames(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.confusion_matrix_results);

    found = 0;
    for i = 1 : length(names)
        if strcmpi(names(i), 'all_resamples')
            found = 1;
        end
    end
    
    if found == 1
        conf_matrix = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.confusion_matrix_results.all_resamples;
    else
        error('Expected results with resamples but that decoding not run yet!');
    end
else
    conf_matrix = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.confusion_matrix_results.confusion_matrix;
end
