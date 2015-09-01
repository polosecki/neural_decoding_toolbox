clear all; close all;
null_distribution_directory_name='/Freiwald/ppolosecki/lspace/plevy/data/Quincy/attn/Population_PITd_stimulus/stimulus_onset_-500_2000_window_clean/results/NULL_restricted_equal/Decode_phi_rel_tr_brt_out_te_brt_out_/'
results_dir='/Freiwald/ppolosecki/lspace/plevy/data/Quincy/attn/Population_PITd_stimulus/stimulus_onset_-500_2000_window_clean/results/restricted_equal';
results_file='Decode_phi_rel_tr_brt_out_te_brt_out_.mat';


addpath(genpath('/Freiwald/ppolosecki/lspace/plevy/ndt.1.0.2'))

real_decoding_results_file_name=fullfile(results_dir,results_file);
pval_obj = pvalue_object(real_decoding_results_file_name, null_distribution_directory_name);

pval_obj.null_distribution_file_prefix_name='CVs_6_resamples_20_';
pval_obj.real_decoding_results_lower_than_null_distribution=0;
pval_obj.collapse_all_times_when_estimating_pvals=0;

[p_values null_distributions PVALUE_PARAMS] = pval_obj.create_pvalues_from_nulldist_files;

load(real_decoding_results_file_name)
a=(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS);
a=a.mean_decoding_results;
figure; hold all
plot(diag(a))
plot(p_values)