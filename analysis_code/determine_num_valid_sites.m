function num_valid_sites = determine_num_valid_sites(monkey, area, cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_condition_in, ...
                                                            test_condition_in, params, is_pop, is_rel)
                                                        
%params assumed to be struct containing the following:
bin_width = params.bin_width;
step_size = params.step_size;
num_cv_splits = params.num_cv_splits;
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

%%  4b.  creata a generalization datasource that produces training data at the upper location, and test data at the lower location
 
binned_dir = fullfile(raster_data_directory_name, 'binned'); %'binned' always used to save, from create_binned_data... function

full_binned = fullfile(binned_dir, binned_data_file_name);

load(full_binned);

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

valid_sites = find_sites_with_k_label_repetitions(eval(['binned_labels.' labels_to_use]), min_k, specific_sites);

num_valid_sites = length(valid_sites);

