monkey = 'quincy';
[lip, pitd] = deal(1, 1);

ref = 'stimulus';
% ref = 'saccade';

align = 'onset';

time_start = -500;
time_window = 2000;
time_type = 'window';

cell_start = 1;
max_cells = 55;

for cell_no = cell_start : max_cells
    if lip == 1
        run_single_decoding_generalization_analysis(monkey, 'lip', cell_no, ref, align, time_start, time_window, time_type);
%         run_single_decoding_analysis(monkey, 'lip', cell_no, ref, align, time_start, time_window, time_type);
        fprintf('\n***Decoded %s LIP %s %s aligned-cell %d***\n\n', monkey, ref, align, cell_no);
    end
    if pitd == 1
%         run_single_decoding_analysis(monkey, 'pitd', cell_no, ref, align, time_start, time_window, time_type);
        run_single_decoding_generalization_analysis(monkey, 'pitd', cell_no, ref, align, time_start, time_window, time_type);
        fprintf('\n***Decoded %s PITd %s %s aligned-cell %d***\n\n', monkey, ref, align, cell_no);
    end
end