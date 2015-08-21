function [] = save_clean_data_batch(monkey, lip, pitd, cell_start, cell_end, ref, align, time_start, time_window)
%Cleans all the data given the specified parameters
%If only one parameter is given, it is assumed to be struct containing all
%needed parameters

if nargin() == 1
    params = monkey; %Just to make assignments below more clear
    
    monkey = params.monkey;
    lip = params.lip;
    pitd = params.pitd;
    cell_start = params.cell_start;
    cell_end = params.cell_end;
    ref = params.ref;
    align = params.align;
    time_start = params.time_start;
    time_window = params.time_window;
end
    
    
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