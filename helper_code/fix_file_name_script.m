clear;

start_dir = pwd();

cd('../helper_code/');
monkey = fix_monkey_case('quincy');
area = fix_area_case('lip');
ref = fix_ref_case('stimulus');
align = fix_align_case('onset');
cd(start_dir);

time_start = -500;
time_window = 2000;
time_type = 'window';

for cell_no = 1 : 55

    cell_str = sprintf('cell_%03.0f', cell_no);

    if strcmpi(time_type, 'window')
        align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' lower(time_type) '_clean'];
    else
        align_str = [ref '_' align '_' num2str(time_start) '_' lower(time_type) '_clean'];
    end

    base_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', [area '_' cell_str]);

    full_dir = fullfile(base_dir, align_str, 'results');

    if ~exist(full_dir, 'dir')
        warning('Directory containing results not found. Cell decoding for %s %s %s %s-aligned cell %d likely not completed.', monkey, area, ref, align, cell_no);
        continue;
    end;

    result_dir = dir(full_dir);

    cd(full_dir);
    
    for i = 1 : size(result_dir)
        if strfind(result_dir(i).name, 'Binned')
            movefile(result_dir(i).name, 'Binned_phi_on_rel_phi_brt_results.mat');
        end
    end
end