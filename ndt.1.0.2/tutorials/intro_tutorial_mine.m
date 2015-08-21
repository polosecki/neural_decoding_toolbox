clear

%Be sure to update the variables below
%Make sure that the directory and data file exist 
%(must use save_neural_data and then save_clean_neural_window)

monkey = 'Quincy';
% monkey = 'Michel';

area = 'PITd';
% area = 'LIP';

cell_no = 29;
cell_str = sprintf('cell_%03.0f', cell_no);

ref = 'stimulus';
% ref = 'saccade';

align = 'onset';
% align = 'start';

time_start = 500;
time_window = 1000;

time_type = 'window';
% time_type = 'slice';

cell_str = [area '_' cell_str];
if strcmpi(time_type, 'window')
    align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' time_type '_clean'];
else
    align_str = [ref '_' align '_' num2str(time_start) '_' time_type '_clean'];
end
    
%%  1.  Create strings listing where the toolbox and the tutoral data directories are

toolbox_directory_name = '/Freiwald/ppolosecki/lspace/plevy/ndt.1.0.2/';  % put name of path to the Neural Decoding Toolbox
raster_data_directory_name = fullfile('Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', cell_str, align_str); % put name of path to the raster data

fprintf('Looking in %s\n', raster_data_directory_name);


%%  2.  Plot a rasters and a PSTH for one neuron that is in raster-format

file_name = 'stimulus_onset_500_1000_window_clean.mat';

%load the raster-format data for one neuron 
load(fullfile(raster_data_directory_name, file_name)) 

% plot the rasters
subplot(1, 2, 1); 
imagesc(~raster_data); 
colormap gray; 
line([0 0], get(gca, 'YLim'), 'color', [1 0 0]);  % put a line at the time when the stimulus was shown
title('Rasters'); 
ylabel('Trials')
xlabel('Time (ms)')

% plot the PSTH
subplot(1, 2, 2); 
bar(sum(raster_data));
line([0 0], get(gca, 'YLim'), 'color', [1 0 0]);  % put a line at the time when the stimulus was shown
title('Peristimulus time histogram (PSTH)') 
ylabel('Number of spikes')
xlabel('Time (ms)')
axis([0 1000 get(gca, 'YLim')])

set(gcf, 'position', [200   400   900   350])



%%  3.  Add the toolbox to Matlab's path       

addpath(toolbox_directory_name) 
add_ndt_paths_and_init_rand_generator



%%  4.  Bin the data

save_prefix_name = 'Binned_stimulus_onset_500_1000_window_clean';
bin_width = 30; %Given our time res, this corresponds to 100mS
step_size = 30; %Given our time res, this corresponds to 100mS 

binned_data_file_name = create_binned_data_from_raster_data(raster_data_directory_name, save_prefix_name, bin_width, step_size);
 
fprintf('Full binned file: %s\n', binned_data_file_name);

%%  5.  Calculate how many times each stimulus has been shown to each neuron

binned_dir = fullfile(raster_data_directory_name, 'binned'); %'binned' always used to save, from create_binned_data... function

full_binned = fullfile(binned_dir, binned_data_file_name);

load(full_binned);  % load the binned data

for i = 0 : 10 %60 from original
    inds_of_sites_with_at_least_k_repeats = find_sites_with_k_label_repetitions(binned_labels.rel_phi, i);
    num_sites_with_k_repeats(i + 1) = length(inds_of_sites_with_at_least_k_repeats);
end





%%  Begin the decoding analysis  %%




%%  6.  Create a datasource object

% we will use object identity labels to decode which object was shown (disregarding the position of the object)
% specific_binned_labels_names = 'rel_phi';
specific_binned_labels_names = 'abs_phi';

% use 20 cross-validation splits (which means that 19 examples of each object are used for training and 1 example of each object is used for testing)
num_cv_splits = 20; 

% create the basic datasource object
ds = basic_DS(full_binned, specific_binned_labels_names,  num_cv_splits);



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

the_cross_validator.num_resample_runs = 10;  % usually more than 2 resample runs are used to get more accurate results, but to save time we are using a small number here


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

% save the results
save_file_name = 'Binned_stimulus_onset_500_1000_window_clean_abs_results';

save_file_name = fullfile(results_dir, save_file_name);

save(save_file_name, '-v7.3', 'DECODING_RESULTS'); 

% if logged the code that was run using a log_code_object, save the code
%LOGGED_CODE = log_code_obj.return_logged_code_structure;
%save(save_file_name, '-v7.3', 'DECODING_RESULTS', 'LOGGED_CODE'); 



%%  12.  Plot the basic results


% which results should be plotted (only have one result to plot here)
result_names{1} = save_file_name;

% create an object to plot the results
plot_obj = plot_standard_results_object(result_names);

% put a line at the time when the stimulus was shown
plot_obj.significant_event_times = 0;   


% optional argument, can plot different types of results
%plot_obj.result_type_to_plot = 2;  % for example, setting this to 2 plots the normalized rank results


plot_obj.plot_results;   % actually plot the results





%%  13.  Plot the TCT matrix

plot_obj = plot_standard_results_TCT_object(save_file_name);

plot_obj.significant_event_times = 0;   % the time when the stimulus was shown


% optional parameters when displaying the TCT movie
%plot_obj.movie_time_period_titles.title_start_times = [-500 0];
%plot_obj.movie_time_period_titles.title_names = {'Fixation Period', 'Stimulus Period'}

plot_obj.plot_results;  % plot the TCT matrix and a movie showing if information is coded by a dynamic population code


