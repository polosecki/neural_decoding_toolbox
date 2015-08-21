clear area;

start_dir = strrep(mfilename('fullpath'), mfilename(), ''); %gets directory containing this file, regardless of curr_dir when called

% monkey = fix_monkey_case('quincy');
monkey = fix_monkey_case('michel');

% align = fix_align_case('start');
align = fix_align_case('onset');

area{1} = fix_area_case('lip');
area{2} = fix_area_case('pitd');

ref{1} = 'stimulus';
ref{2} = 'saccade';

for area_index = 1 : 2
    
    for ref_index = 1 : length(ref)
    
        ref = fix_ref_case(ref{ref_index});
        
        if strcmpi(ref{ref_index}, 'saccade')
            time_start = -1500;
            time_window = 1500;
            time_type = 'window';
        else
            time_start = -500;
            time_window = 2000;
            time_type = 'window';
        end
        
        if strcmpi(time_type, 'window')
            align_str = [ref '_' align '_' num2str(time_start) '_' num2str(time_window) '_' lower(time_type) '_clean'];
        else
            align_str = [ref '_' align '_' num2str(time_start) '_' lower(time_type) '_clean'];
        end

        pop_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', ['Population_' area{area_index} '_' ref], align_str);

        if ~exist(pop_dir, 'dir')
            mkdir(pop_dir);
        end

        for cell_no = 1 : 55

            cell_str = sprintf('cell_%03.0f', cell_no);

            base_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn', [area{area_index} '_' cell_str]);

            full_dir = fullfile(base_dir, align_str);

            if ~exist(full_dir, 'dir')
                warning('Directory containing results not found. Cleaning of neural data for %s %s %s %s-aligned cell %d likely not completed.', ...
                                                            monkey, area{area_index}, ref, align, cell_no);
                continue;
            end;

            result_dir = dir(full_dir);

            cd(full_dir);

            for i = 1 : size(result_dir)
                if ~isempty(strfind(result_dir(i).name, align_str))
                    if isempty(strfind(result_dir(i).name, 'shift')) %i.e. pseudo-population cell
                        copyfile(result_dir(i).name, fullfile(pop_dir, [cell_str '_' result_dir(i).name]));
                    else
                        movefile(result_dir(i).name, fullfile(pop_dir, [cell_str '_' result_dir(i).name])); %Don't want population cells in non-population folder
                    end
                end
            end

        end
    end
end