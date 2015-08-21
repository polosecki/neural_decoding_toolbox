function [] = run_single_decoding_generalization_analysis(monkey, area, cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_labels, train_condition_in, ...
                                                            test_labels, test_condition_in, params, is_pop, is_rel)
                                                        
%params assumed to be struct containing the following:
bin_width = params.bin_width;
step_size = params.step_size;
num_cv_splits = params.num_cv_splits;
num_resample_runs = params.num_resample_runs;
test_only_at_train_times = params.test_only_at_train_times;
sample_sites_with_replacement = params.sample_sites_with_replacement;
restrict_features = params.restrict_features;
restrict_to_top = params.restrict_to_top;
num_features_to_use = params.num_features_to_use;
classifier_index = params.classifier_index;
is_special = params.is_special;
reshuffle = params.to_reshuffle;
if reshuffle; error('This routine should no longer be used for ceating null decodings'); end                                                        
start_dir = strrep(mfilename('fullpath'), mfilename(), '');

monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
align = fix_align_case(align);
ref = fix_ref_case(ref);

cell_str = sprintf('cell_%03.0f', cell_no);

cell_str = [area '_' cell_str];

if strcmpi(time_type, 'window')
    align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' lower(time_type) '_clean'];
else
    align_str = [ref '_' align '_' num2str(time_start) '_' lower(time_type) '_clean'];
end

%%   1.  Create strings listing where the toolbox and the tutoral data directories are and add the toolbox to Matlab's path

toolbox_directory_name = '/Freiwald/ppolosecki/lspace/plevy/ndt.1.0.2/';  % put name of path to the Neural Decoding Toolbox

if is_pop == 1
    raster_data_directory_name = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['Population_' area '_' ref], align_str);    
else
    raster_data_directory_name = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', cell_str, align_str); % put name of path to the raster data
end

% fprintf('Looking in %s\n', raster_data_directory_name);

addpath(toolbox_directory_name)
add_ndt_paths_and_init_rand_generator();

%%  1.5  Check that requested data exists.
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

%%  2.   Bin the data

save_prefix_name = ['Binned_' align_str];

binned_data_file_name = create_binned_data_from_raster_data(raster_data_directory_name, save_prefix_name, bin_width, step_size, is_pop, is_rel);
raster_data_directory_name
binned_data_file_name
%%  3.  Create a classifier and a feature proprocessor object

if classifier_index == 1
    the_classifier = libsvm_CL();
elseif classifier_index == 2
    the_classifier = max_correlation_coefficient_CL();
elseif classifier_index == 3
    the_classifier = poisson_naive_bayes_CL();
else
    error('Invalid classifier chosen. Refer to classifiers with index 1, 2 or 3');
end

%Ad hoc change: restrict to top only restricts the total number, not the
%"top" features
% if restrict_features == 1 && restrict_to_top == 1
%     the_feature_preprocessors{1} = select_or_exclude_top_k_features_FP();  
%     the_feature_preprocessors{1}.num_features_to_use = num_features_to_use;
% 
%     the_feature_preprocessors{2} = zscore_normalize_FP();
% else
%     the_feature_preprocessors{1} = zscore_normalize_FP();
% end
    the_feature_preprocessors{1} = zscore_normalize_FP();


%%  4a.  create labels for which exact stimuli (phi plus BRT) belong in the training set, and which stimuli belong in the test set
%These are now passed in!

%%  4b.  creata a generalization datasource that produces training data at the upper location, and test data at the lower location
 
binned_dir = fullfile(raster_data_directory_name, 'binned'); %'binned' always used to save, from create_binned_data... function

full_binned = fullfile(binned_dir, binned_data_file_name);

ds = generalization_DS(full_binned, labels_to_use, num_cv_splits, train_labels, test_labels);

ds.sample_sites_with_replacement = sample_sites_with_replacement;
ds.randomly_shuffle_labels_before_running = reshuffle;

load(full_binned);

%Grab time vector to save for later use
time_vector = binned_site_info.time_vector{1, 1};

specific_sites_train = get_decoder_labels_separated(decode_on, labels_to_use, train_condition_in);
specific_sites_test = get_decoder_labels_separated(decode_on, labels_to_use, test_condition_in);

specific_sites = cell(1, size(specific_sites_train, 2) + size(specific_sites_test, 2));

offset = size(specific_sites_train, 2);

for i = 1 : offset
    specific_sites{1, i} = specific_sites_train{1, i};
end

for i = 1 : size(specific_sites_test, 2)
    specific_sites{1, i + offset} = specific_sites_test{1, i};
end

min_k = num_cv_splits;

ds.sites_to_use = find_sites_with_k_label_repetitions(eval(['binned_labels.' labels_to_use]), min_k, specific_sites);

if restrict_features == 1
    ds.num_resample_sites = num_features_to_use;
end

valid_sites_found = length(ds.sites_to_use);

% fprintf('Found %d valid sites, %d of which will be randomly (re)sampled\n', valid_sites_found, ds.num_resample_sites);

%%  4c. run a cross-validation decoding analysis that uses the generalization datasource we created to 
%         train a classifier with data from the upper location and test the classifier with data from the lower location

the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);
the_cross_validator.num_resample_runs = num_resample_runs;
the_cross_validator.test_only_at_training_times = test_only_at_train_times;

DECODING_RESULTS = the_cross_validator.run_cv_decoding();

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
results.train_labels = train_labels;
results.train_condition_in = train_condition_in;
results.test_labels = test_labels;
results.test_condition_in = test_condition_in;
results.bin_width = bin_width;
results.step_size = step_size;
results.num_cv_splits = num_cv_splits;
results.num_resample_runs = num_resample_runs;
results.valid_sites_found = valid_sites_found;
results.time_vector = time_vector;
results.classifier = class(the_classifier);
results.sample_sites_with_replacement = sample_sites_with_replacement;

save_file_name = get_file_name_conditions(labels_to_use, decode_on, train_condition_in, test_condition_in, is_special);
save_file_name
if restrict_features == 1
    if restrict_to_top == 1
        if reshuffle == 1
            results_dir = fullfile(results_dir, sprintf('NULL_restrict_top_%d', num_features_to_use), save_file_name);
        else
            results_dir = fullfile(results_dir, sprintf('restrict_top_%d', num_features_to_use));
        end
    else
        if reshuffle == 1
            results_dir = fullfile(results_dir, sprintf('NULL_restricted_equal'), save_file_name);
        else
            results_dir = fullfile(results_dir, sprintf('restricted_equal'));
        end
    end
else
    if reshuffle == 1
        results_dir = fullfile(results_dir, sprintf('NULL_unrestricted'), save_file_name);
    else
        results_dir = fullfile(results_dir, sprintf('unrestricted'));
    end
end

if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

save_file_name = fullfile(results_dir, save_file_name);

save(save_file_name, '-v7.3', 'DECODING_RESULTS'); 

save([save_file_name '_params.mat'], 'results');

cd(results_dir);

fileID = fopen([save_file_name '_params.txt'], 'w');

if isempty(fileID)
    warning('File not opened properly to save parameters\n');
    return;
end

fprintf(fileID, 'Analysis completed: %s\nMonkey: %s\nArea: %s\n', datestr(clock()), monkey, area);
fprintf(fileID, 'Aligned on: %s-%s\n', ref, align);
fprintf(fileID, 'Time %s beginning at %d with width %d\n', time_type, time_start, time_window);
fprintf(fileID, 'Looking to decode %s from %s labels\n', decode_on, labels_to_use);
fprintf(fileID, 'Was this a "special" decoding? %d\n', is_special);
fprintf(fileID, 'Was this for a NULL distribution? %d\n', reshuffle);
fprintf(fileID, 'Train and test labels:\n');

for i = 1 : size(train_labels, 2)
    fprintf(fileID, '\tTrain label %d: %s\n', i, strjoin(train_labels{1, i}));
end
for i = 1 : size(test_labels, 2)
    fprintf(fileID, '\tTest label %d: %s\n', i, strjoin(test_labels{1, i}));
end

fprintf(fileID, 'Decoding parameters (generalization analysis):\n\tBin Width: %d\n\tStep size: %d\n\tNum_CV_splits: %d\n\tNum_resample_runs: %d\n', ...
            bin_width, step_size, num_cv_splits, num_resample_runs);

if is_pop == 1
    fprintf(fileID, '%d valid cells in the population\n', valid_sites_found);
    if restrict_features == 1
        fprintf(fileID, 'Restricted to %d cells\n', num_features_to_use);
    end
end
        
fprintf(fileID, 'Classifier used: %s\n', results.classifier);
fprintf(fileID, 'Sampling with replacement? %d\n', sample_sites_with_replacement);

fclose(fileID);

cd(start_dir);



