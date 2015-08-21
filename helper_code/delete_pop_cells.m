%deletes the artificial (i.e. shifted label) cells

% monkey = 'Quincy';
monkey = 'Michel';

%PITd stimulus-aligned
curr_name = sprintf('/Freiwald/ppolosecki/lspace/plevy/data/%s/attn/Population_PITd_stimulus/stimulus_onset_-500_2000_window_clean', monkey);
curr_dir = dir(curr_name);

for i = 1 : size(curr_dir)
    if strfind(curr_dir(i).name, 'shift')
        delete(fullfile(curr_name, curr_dir(i).name));
    end
end

%LIP stimulus-aligned
curr_name = sprintf('/Freiwald/ppolosecki/lspace/plevy/data/%s/attn/Population_LIP_stimulus/stimulus_onset_-500_2000_window_clean', monkey);
curr_dir = dir(curr_name);

for i = 1 : size(curr_dir)
    if strfind(curr_dir(i).name, 'shift')
        delete(fullfile(curr_name, curr_dir(i).name));
    end
end

%PITd saccade-aligned
curr_name = sprintf('/Freiwald/ppolosecki/lspace/plevy/data/%s/attn/Population_PITd_saccade/saccade_onset_-1500_1500_window_clean', monkey);
curr_dir = dir(curr_name);

for i = 1 : size(curr_dir)
    if strfind(curr_dir(i).name, 'shift')
        delete(fullfile(curr_name, curr_dir(i).name));
    end
end

%LIP saccade-aligned
curr_name = sprintf('/Freiwald/ppolosecki/lspace/plevy/data/%s/attn/Population_LIP_saccade/saccade_onset_-1500_1500_window_clean', monkey);
curr_dir = dir(curr_name);

for i = 1 : size(curr_dir)
    if strfind(curr_dir(i).name, 'shift')
        delete(fullfile(curr_name, curr_dir(i).name));
    end
end