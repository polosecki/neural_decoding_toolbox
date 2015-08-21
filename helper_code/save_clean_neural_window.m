function [] = save_clean_neural_window(full_path, current_file, reference, time_start, time_window)
%Given neural data, cleans all trials containing NaNs within the desired window.
%reference will be either 'onset' or 'start'
%   In onset case, the time start is relative to the onset 
        %(either stimulus or saccade depending on the data)
%   In start case, the time start is relative to the matrix beginning
%If not given, time_start will be zero
%If not given, time_window will be s.t. all data from time_start until end
%is kept
%   If a time slice is wanted (ex. just the data at t = 150 ms) then the
%   time window should be 0

if nargin() < 3
    error('Be sure to provide full path to data, name of data file and reference point\n');
end

if nargin() < 4
    time_start = 0;
end

if nargin() < 5
    time_window = -1; %To indicate that all time should be be kept
end

start_dir = strrep(mfilename('fullpath'), mfilename(), ''); %gets directory containing this file, regardless of curr_dir when called
attn_dir = '/Freiwald/ppolosecki/lspace/plevy/helper_code/attention_code';

%Find brain area used
dir_parts = strsplit(full_path, '/');

%NOTE: This indices are based on the fixed file-writing of save_neural_data
%function. If that changes, so must this!

%Get monkey and area of file
%[monkey_index, area_index] = deal(6, 8);
[monkey_index, area_index] = deal(7, 9);


if strcmpi(dir_parts{1, area_index}(1), 'p')
    area = 'PITd';
elseif strcmpi(dir_parts{1, area_index}(1), 'l')
    area = 'LIP';
else
    error('Invalid area name in file.');
end

if strcmpi(dir_parts{1, monkey_index}(1), 'q')
    monkey = 'Quincy';
elseif strcmpi(dir_parts{1, monkey_index}(1), 'm')
    monkey = 'Michel';
else
    error('Invalid area name in file.');
end

%Load cell directory information and experiment data
base_dir = strcat('/Freiwald/ppolosecki/lspace/', lower(monkey)); %directory has lower case for monkey name

name_parts = strsplit(dir_parts{1, area_index}, '_');

cell_no = str2double(name_parts{1, end});

%cell_file_dir = '/Freiwald/ppolosecki/lspace/plevy/polo_code/cell_file_manager';
cell_file_dir = '/Freiwald/ppolosecki/lspace/polo_preliminary/cell_file_manager';

cell_info_file = fullfile(cell_file_dir, [area '_' monkey '.mat']);
cell_info = load(cell_info_file);
cell_str = cell_info.cell_str;

if exist(fullfile(full_path, current_file), 'file')
    load(fullfile(full_path, current_file));
else
    warning('Desired data file (%s) does not exist. Create with "save_neural_data" before using this function.', fullfile(full_path, current_file));
    return;
end

if size(cell_str(cell_no).attention.mat) < 1
    warning('No file for %s %s attention cell %d. No save\n', monkey, area, cell_no);
    return;
end
load(fullfile(base_dir, cell_str(cell_no).dir, 'proc', cell_str(cell_no).attention.mat{end}));

fprintf('%s %s cell %d:\n', monkey, area, cell_no);

%Work out time alignment
psth = nanmean(raster_data(:, :));
psth_std = nanstd(raster_data(:, :));
contrib = sum(~isnan(raster_data(:, :)));
use_idx = contrib > 1;
psth_sem = psth_std;
psth_sem(use_idx) = psth_std(use_idx)./sqrt(contrib(use_idx));

tres = 1e9/30000; % Specified in nanoseconds, reciprocal of sample rate
psthdec = 100; % Given in Pablo's attention_analysis_function_pp.m

t = 0:tres*psthdec/1e9:(length(psth)-1)*tres*psthdec/1e9; %time in seconds

if strcmpi(reference, 'onset')
    switch raster_site_info.align
        case 'stimulus' %index is 1, from Pablo's code
            %Center on surface onset (stimulus onset + pause_duration):
            cd(attn_dir);
            td = tds{1};
            nocue = false;
            surf_str_extra = heiko_log_surf_params(td, nocue);
            cd(start_dir); %Simply go back from attn_dir
            %Line below finds the one pause value common in used trials
            t_zero = -raster_site_info.start_trig_stim + unique(surf_str_extra.pausedur(raster_site_info.trials_used_stim));
        case 'saccade' %index is 2, from Pablo's code
            %Center on saccade onset:
            t_zero = t(end) - raster_site_info.end_trig_sacc;
    end
elseif strcmpi(reference, 'start')
    t_zero = 0;
else
    error('Invalid reference point. Must be ''start'' or ''onset''\n');
end

t = round((t - t_zero) * 1e3); %Multiply t vector to convert to mS

fprintf('Trial is %d mS or %d sec\n', t(1, size(t, 2)) - t_zero, (t(1, size(t, 2)) - t_zero)/1e3);

start_index = find(t == time_start);

if isempty(start_index)
    error('Start time not in trial');
end

if time_window < 0 %all data
    end_index = size(t, 2); %t is row vector
    time_window = t(1, end_index) - time_start;
elseif time_window == 0 %time slice
    end_index = start_index;
else
    end_index = find(t == time_start + time_window);
end

t_clean = t(start_index : end_index);

fprintf('Indices %d to %d\n', start_index, end_index);

%Check to make sure a valid end_index was found. 
%If not, we default to end of array
if isempty(end_index)
    end_index = size(t, 1);
end

raster_data = raster_data(:, start_index : end_index);

%Now, find all trials with NaN and eliminate from data
[x, ~] = find(isnan(raster_data));
x = unique(x)'; %To make row vector

fprintf('%d trials, %d with NaN\n', size(raster_data, 1), size(x, 2));

raster_data(x, :) = [];

% fprintf('Now, raster_data is [%d X %d]\n', size(raster_data, 1), size(raster_data, 2));

raster_labels.rel_phi(:, x) = [];
raster_labels.abs_phi(:, x) = [];

raster_labels.rel_brt(:, x) = [];
raster_labels.abs_brt(:, x) = [];

raster_labels.rel_phi_brt(:, x) = [];
raster_labels.abs_phi_brt(:, x) = [];

raster_site_info.trials_used_stim(x, :) = [];
raster_site_info.trials_used_sacc(x, :) = [];

raster_site_info.time_vector = t_clean;

if start_index == end_index
    time_type = 'slice';
else
    time_type = 'window';
end
% raster_site_info.align
% raster_site_info
save_name = get_clean_data_name(raster_site_info.align, reference, time_start, time_window, time_type);

sub_dir = save_name;

if ~exist(fullfile(full_path, sub_dir), 'dir')
    mkdir(fullfile(full_path, sub_dir));
end

fprintf('Saving as %s\n\n', save_name);

save(fullfile(full_path, sub_dir, save_name), 'raster_data', 'raster_labels', 'raster_site_info');

end
