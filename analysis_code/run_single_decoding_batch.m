function [] = run_single_decoding_batch(params)
%Runs all the decoding analysis given the specified parameters
%params is assumed to be struct containing all needed parameters

monkey = params.monkey;
lip = params.lip;
pitd = params.pitd;
cell_start = params.cell_start;
cell_end = params.cell_end;
ref = params.ref;
align = params.align;
time_start = params.time_start;
time_window = params.time_window;
generalization = params.generalization;
decode_on = params.decode_on;
labels_to_use = params.labels_to_use;
is_rel = params.is_rel;

if generalization == 1
    train_labels = params.train_labels;
    test_labels = params.test_labels;
    train_condition_in = params.train_condition_in;
    test_condition_in = params.test_condition_in;
end

decode_params = params.decode_params;

if time_window == 0
    time_type = 'slice';
else
    time_type = 'window';
end

is_pop = params.is_pop;

%If we're running LIP and PITd and we want to restrict the number of cells
%used, then we find which area has the fewest number of cells and limit to
%that number of cells in both areas
if lip == 1 && pitd == 1 && is_pop == 1
    if decode_params.restrict_features == 1 && decode_params.restrict_to_top == 0
        
        arbitrary_cell_no = 1; %doesn't matter! just keeping function call happy
        
        valid_lip = determine_num_valid_sites(monkey, 'lip', arbitrary_cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_condition_in, ...
                                                            test_condition_in, decode_params, is_pop, is_rel);
                                                        
        valid_pitd = determine_num_valid_sites(monkey, 'pitd', arbitrary_cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_condition_in, ...
                                                            test_condition_in, decode_params, is_pop, is_rel);
        
%         fprintf('%d valid LIP, %d valid PITd\n', valid_lip, valid_pitd);
        num_to_use = min(valid_lip, valid_pitd);
        
        if is_rel == 0
            if mod(num_to_use, 2) ~= 0
                warning('Number of cells to use (%d) should be even!', num_to_use);
            end
            num_to_use = floor(num_to_use/2);
        end
        
        decode_params.num_features_to_use = num_to_use;
        
    end
end

if generalization ~= 1
    str_one = 'Analysis without specificying the train and test labels has not been used in quite some time';
    str_two = ' so it is possible that the decoding will put results in different from normal folders. Other problems may also arise - Paul';
    %warning([str_one str_two]);
    error([str_one str_two]);
end
    
if is_pop == 1
    
    arbitrary_cell_no = 1; %This value doesn't matter! Just used to keep the called function happy.
    
    if lip == 1
        if generalization == 1
            if decode_params.to_reshuffle
                
                run_single_decoding_generalization_reshuffles(monkey, 'lip', arbitrary_cell_no, ref, align, time_start, time_window, time_type, ...
                    decode_on, labels_to_use, train_labels, train_condition_in, ...
                    test_labels, test_condition_in, decode_params, is_pop, is_rel);
                
            else
                run_single_decoding_generalization_analysis(monkey, 'lip', arbitrary_cell_no, ref, align, time_start, time_window, time_type, ...
                    decode_on, labels_to_use, train_labels, train_condition_in, ...
                    test_labels, test_condition_in, decode_params, is_pop, is_rel);
                
            end
        else
            run_single_decoding_analysis(monkey, 'lip', arbitrary_cell_no, ref, align, time_start, time_window, time_type, decode_on, labels_to_use, decode_params, is_pop, is_rel);
        end
        fprintf('\n***Decoded %s LIP %s %s aligned-cell population***\n\n', monkey, ref, align);
    end
    if pitd == 1
        if generalization == 1
                        if decode_params.to_reshuffle

            run_single_decoding_generalization_reshuffles(monkey, 'pitd', arbitrary_cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_labels, train_condition_in, ...
                                                            test_labels, test_condition_in, decode_params, is_pop, is_rel);
                        else
                            run_single_decoding_generalization_analysis(monkey, 'pitd', arbitrary_cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_labels, train_condition_in, ...
                                                            test_labels, test_condition_in, decode_params, is_pop, is_rel);
                        end
                        
        else
            run_single_decoding_analysis(monkey, 'pitd', arbitrary_cell_no, ref, align, time_start, time_window, time_type, decode_on, labels_to_use, decode_params, is_pop, is_rel);
        end
        fprintf('\n***Decoded %s PITd %s %s aligned-cell population***\n\n', monkey, ref, align);
    end
    
else
    if decode_params.to_reshuffle
        error('Null distributions not supported for single cells, too time consuming and cumbersome')
    end
    for cell_no = cell_start : cell_end
        if lip == 1
            if generalization == 1
                run_single_decoding_generalization_analysis(monkey, 'lip', cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_labels, train_condition_in, ...
                                                            test_labels, test_condition_in, decode_params, is_pop, is_rel);
                                                            
            else
                run_single_decoding_analysis(monkey, 'lip', cell_no, ref, align, time_start, time_window, time_type, decode_on, labels_to_use, decode_params, is_pop, is_rel);
            end
            fprintf('\n***Decoded %s LIP %s %s aligned-cell %d***\n\n', monkey, ref, align, cell_no);
        end
        if pitd == 1
            if generalization == 1
                run_single_decoding_generalization_analysis(monkey, 'pitd', cell_no, ref, align, time_start, time_window, time_type, ...
                                                            decode_on, labels_to_use, train_labels, train_condition_in, ...
                                                            test_labels, test_condition_in, decode_params, is_pop, is_rel);
            else
                run_single_decoding_analysis(monkey, 'pitd', cell_no, ref, align, time_start, time_window, time_type, decode_on, labels_to_use, decode_params, is_pop, is_rel);
            end
            fprintf('\n***Decoded %s PITd %s %s aligned-cell %d***\n\n', monkey, ref, align, cell_no);
        end
    end
end

end