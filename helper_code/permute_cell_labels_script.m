clearvars area ref;

% monkey = 'quincy'; 
monkey = 'michel';

area{1} = 'lip';
area{2} = 'pitd';

ref{1} = 'stimulus';
ref{2} = 'saccade';

align = 'onset';

cell_start = 1;
cell_end = 55;

for area_index = 1 : 2
    
    area_name = area{area_index};
    
    for cell_no = cell_start : cell_end
        
        for ref_index = 1 : length(ref)
            
            ref_name = ref{ref_index};
            
            if strcmpi(ref_name, 'stimulus')
                time_start = -500;
                time_window = 2000;
                time_type = 'window';
            else
                time_start = -1500;
                time_window = 1500;
                time_type = 'window';
            end
            
            permute_cell_labels(monkey, area_name, cell_no, ref_name, align, time_start, time_window, time_type);
            
        end
        
    end
    
end