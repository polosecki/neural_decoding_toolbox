%Be sure that the file to clean exists (use save_neural_data)
cell_start = 1;
cell_end = 55;

monkey = 'Quincy'; 
% monkey = 'Michel'

[lip, pitd] = deal(1, 1);

% ref = 'stimulus';
ref = 'saccade';

align = 'onset';
% align = 'start';

time_start = -500; %w.r.t. align
time_window = 2000; %after time_start

time_type = 'window';
% time_type = 'slice';

% '/Freiwald/ppolosecki/lspace/plevy/data/Quincy/attn/PITd_cell_001', 'stimulus_full'

for cell_no = cell_start : cell_end
    cell_str = sprintf('cell_%03.0f', cell_no);
    if lip == 1
        data_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['LIP_' cell_str]);
        to_clean = [ref '_full.mat'];
        save_clean_neural_window(data_dir, to_clean, align, time_start, time_window);
    end
    if pitd == 1
        data_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['PITd_' cell_str]);
        to_clean = [ref '_full.mat'];
        save_clean_neural_window(data_dir, to_clean, align, time_start, time_window);
    end
end