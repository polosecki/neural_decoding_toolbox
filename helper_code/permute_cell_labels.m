function [] = permute_cell_labels(monkey, area, cell_no, ref, align, time_start, time_window, time_type)
%Assumes that the given cell has already been "cleaned" for use by the
%decoder within the given time window; otherwise, quits

%% 1. Find correct file, error checks
cell_str = sprintf('cell_%03.0f', cell_no);

data_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', fix_monkey_case(monkey), 'attn', [fix_area_case(area) '_' cell_str]);

save_name = get_clean_data_name(ref, align, time_start, time_window, time_type);

orig_data_directory_name = fullfile(data_dir, save_name);

if ~exist(orig_data_directory_name, 'dir')
    warning('Desired directory (%s) does not exist! Create desired data before using this function', orig_data_directory_name);
    return;
end

orig_file_dir = dir([orig_data_directory_name '/*.mat']);

if isempty(orig_file_dir)
    warning('Desired file in directory (%s) does not exist! Create before using this function\n', orig_data_directory_name);
    return;
end

index = -1;

for i = 1 : size(orig_file_dir)
    if isempty(strfind(orig_file_dir(i).name, 'shift')) %Will be adding "shift" to name of artificially created cells
        index = i;
        break;
    end
end

if index == -1
    warning('No valid file found to permute for %s %s cell %d %s-align', monkey, area, cell_no, ref);
    return;
end

orig_file = orig_file_dir(i).name;

load(fullfile(orig_data_directory_name, orig_file));


%% 2. Make label circular permutation

orig_abs_phi = raster_labels.abs_phi;
orig_abs_brt = raster_labels.abs_brt;
orig_abs_phi_brt = cell(1, size(raster_labels.rel_phi_brt, 2));

orig_rf_phi = raster_site_info.RF_pos.phi;

for perm = 2 : 2 %1 creates RF at 90, 2 creates RF at 180, 3 creates RF at 270 w.r.t. original RF

    for i = 1 : size(raster_labels.rel_phi, 2) %rel_phi and abs_phi are same size
        raster_labels.abs_phi{1, i} = num2str(mod(str2double(orig_abs_phi{1, i}) + perm * 90, 360)); %shifting in multiples of 90

        raster_labels.abs_brt{1, i} = num2str(mod(str2double(orig_abs_brt{1, i}) + perm * 90, 360)); %shifting in multiples of 90

        raster_labels.abs_phi_brt{1, i} = [raster_labels.abs_phi{1, i} '_' raster_labels.abs_brt{1, i}];
    end
    
    raster_site_info.RF_pos.phi = mod(orig_rf_phi + perm * 90, 360); %shifting in multiples of 90
    
    perm_file = strrep(orig_file, '.mat', ['_shift_' num2str(perm*90), '.mat']);
    
    save(fullfile(orig_data_directory_name, perm_file), 'raster_data', 'raster_labels', 'raster_site_info');

end

end

