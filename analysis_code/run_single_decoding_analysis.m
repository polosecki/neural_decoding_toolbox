function [] = run_single_decoding_analysis(monkey, area, cell_no, ref, align, time_start, time_window, time_type, ...
                                                decode_on, labels_to_use, params, is_pop)
%params assumed to be struct containing the following:
bin_width = params.bin_width;
step_size = params.step_size;
num_cv_splits = params.num_cv_splits;
num_resample_runs = params.num_resample_runs;

% start_dir = strrep(mfilename('fullpath'), mfilename(), '');

% cd('../helper_code/');
monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
ref = fix_ref_case(ref);
align = fix_align_case(align);
% cd(start_dir);

cell_str = sprintf('cell_%03.0f', cell_no);

cell_str = [area '_' cell_str];

if strcmpi(time_type, 'window')
    align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' lower(time_type) '_clean'];
else
    align_str = [ref '_' align '_' num2str(time_start) '_' lower(time_type) '_clean'];
end
    
%%  1.  Create strings listing where the toolbox and the tutoral data directories are

toolbox_directory_name = '/Freiwald/ppolosecki/lspace/plevy/ndt.1.0.2/';  % put name of path to the Neural Decoding Toolbox

if is_pop == 1
    raster_data_directory_name = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['Population_' area '_' ref], align_str);    
else
    raster_data_directory_name = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', cell_str, align_str); % put name of path to the raster data
end
    
% fprintf('Looking in %s\n', raster_data_directory_name);


%%  2.  Check that requested data exists
if ~exist(raster_data_directory_name, 'dir')
    warning('Directory (%s) does not exist!\nAnalysis not conducted\n', raster_data_directory_name);
    return;
end

if is_pop == 0
    if ~exist(fullfile(raster_data_directory_name, [align_str '.mat']), 'file')
        warning('File (%s) does not exist!\nAnalysis not conducted\n', fullfile(raster_data_directory_name, [align_str '.mat']));
        return;
    end
end

%%  3.  Add the toolbox to Matlab's path       

addpath(toolbox_directory_name) 
add_ndt_paths_and_init_rand_generator



%%  4.  Bin the data

save_prefix_name = ['Binned_' align_str];

binned_data_file_name = create_binned_data_from_raster_data(raster_data_directory_name, save_prefix_name, bin_width, step_size, is_pop, is_rel);
 
% fprintf('Full binned file: %s\n', binned_data_file_name);

%%  5.  Calculate how many times each stimulus has been shown to each neuron

binned_dir = fullfile(raster_data_directory_name, 'binned'); %'binned' always used to save, from create_binned_data... function

full_binned = fullfile(binned_dir, binned_data_file_name);

load(full_binned);  % load the binned data

%%  Begin the decoding analysis  %%




%%  6.  Create a datasource object


% create the basic datasource object
ds = basic_DS(full_binned, labels_to_use,  num_cv_splits);

specific_sites_train = get_train_labels_separated(decode_on, labels_to_use);
specific_sites_test = get_test_labels_separated(decode_on, labels_to_use);

specific_sites = cell(1, size(specific_sites_train, 2) + size(specific_sites_test, 2));

for i = 1 : size(specific_sites_train)
    specific_sites{1, i} = specific_sites_train{1, i};
end
for i = 1 : size(specific_sites_test)
    specific_sites{1, i + size(specific_sites_train)} = specific_sites_test{1, i};
end

min_k = num_cv_splits * num_resample_runs;

ds.sites_to_use = find_sites_with_k_label_repetitions(eval(['binned_labels.' labels_to_use]), min_k, specific_sites);

valid_sites_found = length(ds.sites_to_use);

% other useful options:

% if using the Poison Naive Bayes classifier, load the data as spike counts by setting the load_data_as_spike_counts flag to 1
%ds = basic_DS(binned_data_file_name, specific_binned_labels_names,  num_cv_splits, 1);

% can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
%ds.num_times_to_repeat_each_label_per_cv_split = 2;

 % optionally can specify particular sites to use
%ds.sites_to_use = find_sites_with_k_label_repetitions(the_labels_to_use, num_cv_splits);  

% can do the decoding on a subset of labels
%ds.label_names_to_use =  {'kiwi', 'flower', 'guitar', 'hand'};


%%   7.  Create a feature preprocessor object

% create a feature preprocess that z-score normalizes each feature
the_feature_preprocessors{1} = zscore_normalize_FP;  


% other useful options:   

% can include a feature-selection features preprocessor to only use the top k most selective neurons
% fp = select_or_exclude_top_k_features_FP;
% fp.num_features_to_use = 25;   % use only the 25 most selective neurons as determined by a univariate one-way ANOVA
% the_feature_preprocessors{2} = fp;




%%  8.  Create a classifier object 

% select a classifier
the_classifier = max_correlation_coefficient_CL;


% other useful options:   

% use a poisson naive bayes classifier (note: the data needs to be loaded as spike counts to use this classifier)
%the_classifier = poisson_naive_bayes_CL;  

% use a support vector machine (see the documentation for all the optional parameters for this classifier)
%the_classifier = libsvm_CL;


%%  9.  create the cross-validator 


the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);  

the_cross_validator.num_resample_runs = num_resample_runs;

% other useful options:   

% can greatly speed up the run-time of the analysis by not creating a full TCT matrix (i.e., only trainging and testing the classifier on the same time bin)
% the_cross_validator.test_only_at_training_times = 1;  




%%  10.  Run the decoding analysis   

% if calling the code from a script, one can log the code so that one can recreate the results 
%log_code_obj = log_code_object;
%log_code_obj.log_current_file; 


% run the decoding analysis 
DECODING_RESULTS = the_cross_validator.run_cv_decoding; 



%%  11.  Save the results

if ~exist(fullfile(raster_data_directory_name, 'results'), 'dir')
    mkdir(fullfile(raster_data_directory_name, 'results'));
end

results_dir = fullfile(raster_data_directory_name, 'results');

results.time = datestr(clock());
results.monkey = monkey;
results.area = area;
results.ref = ref;
results.align = align;
results.time_type = time_type;
results.time_start = time_start;
results.time_window = time_window;
results.decode_on = decode_on;
results.labels_to_use = labels_to_use;
results.bin_width = bin_width;
results.step_size = step_size;
results.num_cv_splits = num_cv_splits;
results.num_resample_runs = num_resample_runs;
results.valid_sites_found = valid_sites_found;

% save the results and file detailing code parameters
save_file_name = get_file_name_conditions(labels_to_use, decode_on, -1, -1); %-1 for not generalization analysis

save_file_name = fullfile(results_dir, save_file_name);

save(save_file_name, '-v7.3', 'DECODING_RESULTS'); 

save([save_file_name '_params.mat'], 'results');

cd(results_dir);

file_ID = fopen([save_file_name '_params.txt'], 'w');

if isempty(file_ID)
    warning('File not opened properly to save parameters\n');
    return;
end

fprintf(file_ID, 'Analysis completed: %s\nMonkey: %s\nArea: %s\n', datestr(clock()), monkey, area);
fprintf(file_ID, 'Aligned on: %s-%s\n', ref, align);
fprintf(file_ID, 'Time %s beginning at %d with width %d\n', time_type, time_start, time_window);
fprintf(file_ID, 'Looking to decode %s from %s labels\n', decode_on, labels_to_use);

fprintf(file_ID, 'Decoding parameters (basic analysis):\n\tBin Width: %d\n\tStep size: %d\n\tNum_CV_splits: %d\n\tNum_resample_runs: %d\n', ...
                        bin_width, step_size, num_cv_splits, num_resample_runs);

if is_pop == 1
    fprintf(fileID, '%d valid cells in the population\n', valid_sites_found);
end
                    
fclose(file_ID);

cd(start_dir);

