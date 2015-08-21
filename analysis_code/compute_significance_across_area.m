function significance = compute_significance_across_area(monkey, ref, labels_to_use, decode_on, train_in, test_in, is_special, desired_p)
%Computes p value of difference between LIP and PITd at all time points
%Assumes #cells are equal in PITd and LIP and that #resamples are equal

%assumptions
arbitrary_cell = 1;
time_type = 'window';
align = 'onset';
is_restricted = 1;
is_restricted_by_top = 0;
top_k_cells = 10; %arbitrary in case of not restricting by top
is_population = 1;

if strcmpi(ref, 'stimulus')
    time_vector = [-500 : 100 : 1400];
    time_start = -500;
    time_window = 2000;
else
    time_vector = [-1500 : 100 : -100];
    time_start = -1500;
    time_window = 1500;
end


[LIP_results, ~] = get_decoding_results(monkey, 'LIP', ref, align, arbitrary_cell, time_start, time_window, time_type, labels_to_use, ...
                                decode_on, train_in, test_in, is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special);

[PITd_results, ~] = get_decoding_results(monkey, 'PITd', ref, align, arbitrary_cell, time_start, time_window, time_type, labels_to_use, ...
    decode_on, train_in, test_in, is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special);

%decoding value comes as [num_resample_runs x num_CV_splits x num_training_times x num_test_times]
%we collapse over all CV splits and care only about same train/test time

LIP_decodings = LIP_results.DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
PITd_decodings = PITd_results.DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;

l_train_times = size(LIP_decodings, 3);
p_train_times = size(PITd_decodings, 3);

l_test_times = size(LIP_decodings, 4);
p_test_times = size(PITd_decodings, 4);

is_p_square = 0;
is_l_square = 0;

if l_test_times ~= 1 
    if l_test_times ~= l_train_times
        error('Check decoding parameters for LIP; uneven or non-column/row matrix');
    else
        is_l_square = 1;
    end
end

if p_test_times ~= 1 
    if p_test_times ~= p_train_times
        error('Check decoding parameters for PITd; uneven or non-column/row matrix');
    else
        is_p_square = 1;
    end
end

if l_train_times ~= p_train_times
    error('LIP and PITd decodings should have equal number of time bins decoded');
end

num_times = l_train_times;

p_value = zeros(1, num_times);

for time = 1 : num_times
   
    %Get decoding values
    if is_l_square == 1
        lip_slice = LIP_decodings(:, :, time, time);
    else
        lip_slice = LIP_decodings(:, :, time, 1);
    end
    
    if is_p_square == 1
        pitd_slice = PITd_decodings(:, :, time, time);
    else
        pitd_slice = PITd_decodings(:, :, time, 1);
    end
    
    %Collapse over all_cv
    l_collapsed = mean(lip_slice, 2);
    p_collapsed = mean(pitd_slice, 2);
    
%     fprintf('Time %d of %d\n', time, num_times);
    
    curr_distr = compute_all_resample_pairs(l_collapsed, p_collapsed);
    
%     p_value(1, time) = binomi
    
%     fprintf('Time %d: Current delta mean %d\n', time, curr_delta);
    
%     significance = mean(curr_distr < 0);
      
    %     fprintf('At time %d, value is %d percentile\n', time, round(significance * 100) / 1000 * 1000);
    
%     p_value(1, time) = 2 * min(significance, 1 - significance);
      
    

end

graph = figure();

plot(time_vector, p_value);
ylim([0 1]);
line(xlim, [desired_p desired_p], 'Color', 'k');
line([0 0], ylim, 'Color', 'k');

root_dir = '/Freiwald/ppolosecki/lspace/plevy/figures/comparative';

title_save = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in, is_special);
title_str = strrep(title_save, '_', ' ');
title_str = strrep(title_str, 'Decode ', '');

title(sprintf('P value for LIP - PITd for %s', title_str));

if is_restricted == 1
    if is_restricted_by_top == 1
        dir_ending = sprintf('restrict_top_%d', num_top_cells);
    else
        dir_ending = sprintf('restricted_equal');
    end
else
    dir_ending = sprintf('unrestricted');
end

if is_population == 1
    save_dir = fullfile(root_dir, monkey, ref, 'population', title_save, dir_ending);
else
    save_dir = fullfile(root_dir, monkey, ref, 'single_cell', title_save, dir_ending);
end

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

saveas(graph, fullfile(save_dir, sprintf('LIP_PITd_sig.jpg')));

fprintf('Saving as %s\n', fullfile(save_dir, sprintf('LIP_PITd_sig.jpg')));

%Save as SVG
addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
plot2svg(fullfile(save_dir, sprintf('LIP_PITd_sig.svg')), graph);

close(graph);

end

