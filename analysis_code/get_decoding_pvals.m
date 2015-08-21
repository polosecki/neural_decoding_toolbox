function [p_values] = get_decoding_pvals(monkey, area, ref, align, arbitrary_cell_no, time_start, time_window, time_type, labels_to_use, decode_on, ...
    train_condition_in, test_condition_in, is_restricted, is_restricted_by_top, num_top_cells, is_pop, is_special,null_resamples,null_CVs)


p_values=[];




%start_dir = strrep(mfilename('fullpath'), mfilename(), '');

monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
ref = fix_ref_case(ref);
align = fix_align_case(align);

%labels_to_use = [labels_to_use '_results']; %to ensure that only exact (and not partial) file match is found
%For ex., this will avoid rel_phi yielding a file with rel_phi_brt

if strcmpi(time_type, 'window')
    align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' lower(time_type) '_clean'];
else
    align_str = [ref '_' align '_' num2str(time_start) '_' lower(time_type) '_clean'];
end

if is_pop == 1
    base_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['Population_' area '_' ref], align_str);
else
    cell_str = sprintf('cell_%03.0f', arbitrary_cell_no);
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

saved_subdir_name = get_file_name_conditions(labels_to_use, decode_on, train_condition_in, test_condition_in, is_special);
null_distribution_directory_name = fullfile(base_dir, 'results', ['NULL_' dir_ending],saved_subdir_name);
real_decoding_results_file_name= fullfile(base_dir, 'results', dir_ending, [saved_subdir_name '.mat']);

if ~exist(null_distribution_directory_name, 'dir')
    warning('Directory (%s) containing results not found. Null decoding for %s %s %s %s-aligned  likely not completed.', null_distribution_directory_name, monkey, area, ref, align);

    return;
end;

if ~is_pop
    warning('Single cell decoding doesn''s support p-value calculation')
    p_values=[];
    return
end

pval_obj = pvalue_object(real_decoding_results_file_name, [null_distribution_directory_name '/']);

pval_obj.null_distribution_file_prefix_name=['CVs_' num2str(null_CVs) '_resamples_' num2str(null_resamples) '_'];
pval_obj.real_decoding_results_lower_than_null_distribution=0; % 0:Positive tailed test, 1:Negative tailed test, 2Two-tailed test
pval_obj.collapse_all_times_when_estimating_pvals=1; % Self-descriptive option! :-)

[p_values, ~, ~] = pval_obj.create_pvalues_from_nulldist_files;
%[p_values null_distributions PVALUE_PARAMS] = pval_obj.create_pvalues_from_nulldist_files;
clear pval_obj











