%Setting values here will let you control which steps below will be run
clear all;

to_save = 0; % make raster data from the grand_psth matrices, uncleaned
to_clean = 0;
to_populate = 0;

%Slowest part!!
to_decode = 0; %Independent from special_decode
to_special_decode = 0; %Independent from decode; decoding with both surface and saccade targets in RF, separated by cognitive condition
to_null_decode = 1; %Independent from decode, runs special as well

%To plot confusion matrix analysis
to_plot_confusion = 0;
to_plot_special_confusion = 0; %above must be 1 for this to run

%To plot mean decodings
to_plot_mean = 0;
to_plot_mean_special = 0; %above must be 1 for this to run

%To plot LIP vs. PITd comparisons for confusion matrices AND mean decodings
%Also plots cross-time training matrices
to_compare = 0; %THE ONE FOR MAKING THE USEFUL PLOTS
to_compare_special = 0; %above must be 1 for this to run

%CURRENTLY ABANDONED: To compute significance of mean decoding results accross areas
to_compute_sig = 0; %
to_compute_sig_special = 0; %above must be 1 for this to run

%Shouldn't change unless really certain it must be done
start_dir = strrep(mfilename('fullpath'), mfilename(), ''); %gets directory containing this file, regardless of curr_dir when called
analysis_dir = '/Freiwald/ppolosecki/lspace/plevy/analysis_code/';
helper_dir = '/Freiwald/ppolosecki/lspace/plevy/helper_code/';

%%

addpath(genpath('/Freiwald/ppolosecki/lspace/plevy/ndt.1.0.2'))
addpath(genpath('/Freiwald/ppolosecki/lspace/plevy/polo_code/cell_file_manager'))
addpath(genpath('/Freiwald/ppolosecki/lspace/plevy/polo_code/attention_analysis'))
addpath(genpath(analysis_dir))
addpath(genpath(helper_dir))

%% 1. For getting and saving data (uncleaned)

if to_save == 1

    %Choose monkey
    params.data.monkey = 'quincy';
%     params.data.monkey = 'michel';

    %Choose areas to save (1 for yes, 0 for no)
    params.data.lip = 1;
    params.data.pitd = 1;

    %Choose alignments to save (1 for yes, 0 for no)
    params.data.stim = 1;
    params.data.sacc = 1;

    %Range of cells
    %Invalid/out of range/"bad" cells ignored
    params.data.cell_start = 1;
    params.data.cell_end = 55;

    save_data_batch(params.data);

end

%% 2. For cleaning neural data to use with toolbox (remove NaNs)

%Choose monkey
params.clean.monkey = fix_monkey_case('quincy');
% params.clean.monkey = fix_monkey_case('michel');

refs{1} = 'stimulus';
refs{2} = 'saccade';

for ref_index = 2 : length(refs)

    if to_clean == 1

        %Choose areas to clean (1 for yes, 0 for no)
        params.clean.lip = 1;
        params.clean.pitd = 1;

        %Range of cells
        %Invalid/out of range/"bad" cells ignored
        params.clean.cell_start = 1;
        params.clean.cell_end = 55;

        %Choose reference point and alignment

        params.clean.ref = fix_ref_case(refs{ref_index});

        params.clean.align = fix_align_case('onset');

        %These values should be left untouched unless a change is desired
        if strcmpi(params.clean.ref, 'stimulus')
            params.clean.time_start = -500; %w.r.t. align
            params.clean.time_window = 2000; %after time_start
        elseif strcmpi(params.clean.ref, 'saccade')
            params.clean.time_start = -800;%-1500; %w.r.t. align
            params.clean.time_window = 800;%1500; %after time_start
        else
            error('Must choose valid reference point for data alignment');
        end

        save_clean_data_batch(params.clean);

    end

end

%% 2.5 Create population

if to_populate == 1

     monkey = fix_monkey_case('quincy');
%    monkey = fix_monkey_case('michel');
    
    prepare_for_populating(monkey);
    permute_cell_labels_func(monkey);
    create_population_folder_func(monkey);

end

%% 3. Run decoding analysis

%Choose monkey
 params.decode.monkey = fix_monkey_case('quincy');
%params.decode.monkey = fix_monkey_case('michel');
%params.decode.monkey = 'both_monkeys';

params.decode.decode_params.bin_width = 30; %30 = 100mS
params.decode.decode_params.step_size = 30; %30 = 100mS
params.decode.decode_params.num_cv_splits = 6;
params.decode.decode_params.num_resample_runs = 200;
params.decode.decode_params.test_only_at_train_times = 0;

params.decode.decode_params.restrict_features = 1;
params.decode.decode_params.restrict_to_top = 1;
params.decode.decode_params.num_features_to_use = 20;

params.decode.decode_params.to_reshuffle = 0; %Reshuffles the labels for NULL distribution

params.decode.decode_params.classifier_index = 1;
%Index 1 is SVM
%Index 2 is Max_correlation_coefficient
%Index 3 is Naive Bayes

%***Loop controls (OK to edit)***

%0 is for single-cell analysis, 1 for population
pop_start = 1;
pop_end = 1;

%1 is for stimulus/surface alignment, 2 is for saccade alignment
ref_start = 2;
ref_end = 2;

%1 is for decoding phi, 2 for brt
decode_start = 1;
decode_end = 2;

%1 is for decoding on labels just phi OR brt, 2 is for decoding on phi AND
%brt (binary classification)
cond_start = 2;
cond_end = 2;

%1 is for relative coordinates, 2 is for absolute coordinates
rel_start = 1;
rel_end = 2;

%For train/test conditions (1 is IN, 0 is OUT); Should have 0 to 1
train_start = 0;
train_end = 1;
test_start = 0;
test_end = 1;

%Calculation takes care of itself
num_conditions = (pop_end - pop_start + 1) * (ref_end - ref_start + 1) * (decode_end - decode_start + 1) ...
            * (cond_end - cond_start + 1) * (rel_end - rel_start + 1) ...
            * (train_end - train_start + 1) * (test_end - test_start + 1);

%***Values to be accessed with parameters/indices (don't edit unless really confident!)***
refs{1} = 'stimulus';
refs{2} = 'saccade';

decode{1} = 'phi';
decode{2} = 'brt';

conditions{1}{1}{1} = 'rel_phi';
conditions{1}{1}{2} = 'rel_phi_brt';

conditions{1}{2}{1} = 'rel_brt';
conditions{1}{2}{2} = 'rel_phi_brt';

conditions{2}{1}{1} = 'abs_phi';
conditions{2}{1}{2} = 'abs_phi_brt';

conditions{2}{2}{1} = 'abs_brt';
conditions{2}{2}{2} = 'abs_phi_brt';

%The work
 
if to_decode == 1

    %Not 'special' decoding
    params.decode.decode_params.is_special = 0;
    
    decoded = 0;
    
    for is_pop = pop_start : pop_end
    
        if is_pop == 1
            params.decode.decode_params.sample_sites_with_replacement = 1;
        else
            params.decode.decode_params.sample_sites_with_replacement = 0;
        end
        
        params.decode.is_pop = is_pop;

        %Choose areas to decode (1 for yes, 0 for no)
        params.decode.lip = 1;
        params.decode.pitd = 1;

        %Range of cells
        %Invalid/out of range/"bad" cells ignored
        %Ignored if population (is_pop == 1)
        params.decode.cell_start = 1;
        params.decode.cell_end = 55;

        %Is generalization analysis or "normal" analysis?
        %No control of labels with "normal" analysis
        params.decode.generalization = 1;

        for ref_index = ref_start : ref_end

            %Choose reference point and alignment

            params.decode.ref = fix_ref_case(refs{ref_index});

            params.decode.align = fix_align_case('onset');

            %These values should be left untouched unless a change is desired
            if strcmpi(params.decode.ref, 'stimulus')
                params.decode.time_start = -500; %w.r.t. align
                params.decode.time_window = 2000; %after time_start
            else
%                 params.decode.time_start = -1500; %w.r.t. align
%                 params.decode.time_window = 1500; %after time_start
                params.decode.time_start = -800; %w.r.t. align
                params.decode.time_window = 800; %after time_start
            end

            for decode_index = decode_start : decode_end

                for cond_index = cond_start : cond_end

                    for rel_index = rel_start : rel_end

                        params.decode.decode_on = decode{decode_index}; %'phi'; %either phi or brt
                        params.decode.labels_to_use = conditions{rel_index}{decode_index}{cond_index}; %'rel_phi'; %for ex., rel_phi_brt, abs_brt
                        
                        if rel_index == 1
                            params.decode.is_rel = 1;
                        else
                            params.decode.is_rel = 0;
                            
                            if is_pop == 1
                                %params.decode.decode_params.num_features_to_use = params.decode.decode_params.num_features_to_use * 2; 
                                %to account for permuations
                            end

                        end

                        if params.decode.generalization == 1
                            %get_decoder_labels function must be adjusted if change desired

                            if ~isempty(strfind(params.decode.labels_to_use, 'phi_brt'))

                                for train_in = train_start : train_end

                                    params.decode.train_condition_in = train_in;
                                    params.decode.train_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, train_in);

                                    for test_in = test_start : test_end

                                        params.decode.test_condition_in = test_in;   
                                        params.decode.test_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, test_in);

                                        if isempty(params.decode.train_labels) || isempty(params.decode.test_labels)
                                            warning('Decoding on %s using labels %s currently invalid\nYou may need to change decode/labels or edit get_train/test_labels functions\n', ...
                                                        params.decode.decode_on, params.decode.labels_to_use);
                                            return;
                                        end

                                        run_single_decoding_batch(params.decode);
                                        decoded = decoded + 1;
                                        fprintf('Finished %d of %d decodings\n', decoded, num_conditions);
                                    end
                                end

                            else

                                params.decode.train_condition_in = -1; %To indicate irrelevant to the next f'n
                                params.decode.train_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, params.decode.train_condition_in);                    

                                params.decode.test_condition_in = -1; %To indicate irrelevant to the next f'n
                                params.decode.test_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, params.decode.test_condition_in);

                                if isempty(params.decode.train_labels) || isempty(params.decode.test_labels)
                                    warning('Decoding on %s using labels %s currently invalid\nYou may need to change decode/labels or edit get_train/test_labels functions\n', ...
                                                params.decode.decode_on, params.decode.labels_to_use);
                                    return;
                                end

                                run_single_decoding_batch(params.decode);
                                decoded = decoded + 1;
                                fprintf('Finished %d of %d decodings\n', decoded, num_conditions);

                            end

                        else
                            run_single_decoding_batch(params.decode);
                            decoded = decoded + 1;
                            fprintf('Finished %d of %d decodings\n', decoded, num_conditions);
                        end
                    end

                end

            end

        end
        
    end
    
end

%% 3.5 Run specific/special decodings

%Choose monkey
%params.decode.monkey = fix_monkey_case('quincy');
%params.decode.monkey = fix_monkey_case('michel');
params.decode.monkey = fix_monkey_case('both_monkeys');

params.decode.decode_params.bin_width = 30; %30 = 100mS
params.decode.decode_params.step_size = 30; %30 = 100mS
params.decode.decode_params.num_cv_splits = 3;
params.decode.decode_params.num_resample_runs = 200;
params.decode.decode_params.test_only_at_train_times = 0;

params.decode.decode_params.restrict_features = 1;
params.decode.decode_params.restrict_to_top = 0;
params.decode.decode_params.num_features_to_use = 20;

params.decode.decode_params.to_reshuffle = 0;

params.decode.decode_params.classifier_index = 1;
%Index 1 is SVM
%Index 2 is Max_correlation_coefficient
%Index 3 is Naive Bayes

%***Loop controls (OK to edit)***

%0 is for single-cell analysis, 1 for population
pop_start = 1;
pop_end = 1;

%1 is for stimulus/surface alignment, 2 is for saccade alignment
ref_start = 1;
ref_end = 2;

%1 is for decoding phi, 2 for brt
decode_start = 1;
decode_end = 2;

%1 is for decoding on labels just phi OR brt, 2 is for decoding on phi AND brt
cond_start = 2;
cond_end = 2;

%1 is for relative coordinates, 2 is for absolute coordinates
rel_start = 1;
rel_end = 2;

%For train/test conditions (1 is IN = 0 deg, 0 is OUT = 180 deg); Should have 0 to 1
%Here, we always decode whether the variable-to-decode is 0 or 180
%the non-decoded variable is either always IN or always OUT
train_start = 0;
train_end = 1;
test_start = 0;
test_end = 1;

%Calculation takes care of itself
num_conditions = (pop_end - pop_start + 1) * (ref_end - ref_start + 1) * (decode_end - decode_start + 1) ...
            * (cond_end - cond_start + 1) * (rel_end - rel_start + 1) ...
            * (train_end - train_start + 1) * (test_end - test_start + 1);

%***Values to be accessed with parameters/indices (don't edit unless really confident!)***
refs{1} = 'stimulus';
refs{2} = 'saccade';

decode{1} = 'phi';
decode{2} = 'brt';

conditions{1}{1}{1} = 'rel_phi';
conditions{1}{1}{2} = 'rel_phi_brt';

conditions{1}{2}{1} = 'rel_brt';
conditions{1}{2}{2} = 'rel_phi_brt';

conditions{2}{1}{1} = 'abs_phi';
conditions{2}{1}{2} = 'abs_phi_brt';

conditions{2}{2}{1} = 'abs_brt';
conditions{2}{2}{2} = 'abs_phi_brt';

%The work
if to_special_decode == 1

    params.decode.decode_params.is_special = to_special_decode;
    
    decoded = 0;
    
    for is_pop = pop_start : pop_end
    
        params.decode.is_pop = is_pop;

        if is_pop == 1
            params.decode.decode_params.sample_sites_with_replacement = 1;
        else
            params.decode.decode_params.sample_sites_with_replacement = 0;
        end
        
        %Choose areas to decode (1 for yes, 0 for no)
        params.decode.lip = 1;
        params.decode.pitd = 1;

        %Range of cells
        %Invalid/out of range/"bad" cells ignored
        %Ignored if population (is_pop == 1)
        params.decode.cell_start = 1;
        params.decode.cell_end = 55;

        %Is generalization analysis or "normal" analysis?
        %No control of labels with "normal" analysis
        params.decode.generalization = 1;

        for ref_index = ref_start : ref_end

            %Choose reference point and alignment

            params.decode.ref = fix_ref_case(refs{ref_index});

            params.decode.align = fix_align_case('onset');

            %These values should be left untouched unless a change is desired
            if strcmpi(params.decode.ref, 'stimulus')
                params.decode.time_start = -500; %w.r.t. align
                params.decode.time_window = 2000; %after time_start
            else
                params.decode.time_start = -1500; %w.r.t. align
                params.decode.time_window = 1500; %after time_start
            end

            for decode_index = decode_start : decode_end

                for cond_index = cond_start : cond_end

                    for rel_index = rel_start : rel_end

                        params.decode.decode_on = decode{decode_index}; %'phi'; %either phi or brt
                        params.decode.labels_to_use = conditions{rel_index}{decode_index}{cond_index}; %'rel_phi'; %for ex., rel_phi_brt, abs_brt
                        
                        if rel_index == 1
                            params.decode.is_rel = 1;
                        else
                            params.decode.is_rel = 0;
                            
                            if is_pop == 1
                                %params.decode.decode_params.num_features_to_use = params.decode.decode_params.num_features_to_use * 2; 
                                %to account for permuations
                            end

                        end

                        if params.decode.generalization == 1
                            %get_decoder_labels function must be adjusted if change desired

                            if ~isempty(strfind(params.decode.labels_to_use, 'phi_brt'))

                                for train_in = train_start : train_end

                                    for test_in = test_start : test_end
                                    
                                        params.decode.train_condition_in = train_in;
                                        params.decode.train_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, train_in, to_special_decode);


                                        params.decode.test_condition_in = test_in;   
                                        params.decode.test_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, test_in, to_special_decode);

                                        if isempty(params.decode.train_labels) || isempty(params.decode.test_labels)
                                            warning('Decoding on %s using labels %s currently invalid\nYou may need to change decode/labels or edit get_train/test_labels functions\n', ...
                                                        params.decode.decode_on, params.decode.labels_to_use);
                                            return;
                                        end

                                        run_single_decoding_batch(params.decode);
                                        decoded = decoded + 1;
                                        fprintf('Finished %d of %d decodings\n', decoded, num_conditions);
                                        
                                    end
                                        
                                end

                            else
                               warning('Do not use label of just phi OR just brt with special decoding!');
                            end

                        else
                            run_single_decoding_batch(params.decode);
                            decoded = decoded + 1;
                            fprintf('Finished %d of %d decodings\n', decoded, num_conditions);
                        end
                    end

                end

            end

        end
        
    end
    
end

%% 3.75 Run decoding for NULL distribution

%Choose monkey
params.decode.monkey = fix_monkey_case('quincy');
%params.decode.monkey = fix_monkey_case('both_monkeys');
%params.decode.monkey = fix_monkey_case('michel');
is_special_null_decode= false;% true;%
params.decode.decode_params.bin_width = 30; %30 = 100mS
params.decode.decode_params.step_size = 30; %30 = 100mS
if ~is_special_null_decode
    params.decode.decode_params.num_cv_splits = 6;%3;%6;
else
    params.decode.decode_params.num_cv_splits = 3;%6;
end
params.decode.decode_params.num_resample_runs = 50;%200;
params.decode.decode_params.test_only_at_train_times = 1;
params.decode.decode_params.sample_sites_with_replacement = 1;

params.decode.decode_params.restrict_features = 1;
params.decode.decode_params.restrict_to_top = 1;
params.decode.decode_params.num_features_to_use = 20;
params.decode.decode_params.to_reshuffle = 1;
params.decode.decode_params.num_reshuffles = 300;
params.decode.decode_params.delete_old_reshuffles = 0; %WARNING: setting this to 1 will destroy lots of files

params.decode.decode_params.classifier_index = 1;
%Index 1 is SVM
%Index 2 is Max_correlation_coefficient
%Index 3 is Naive Bayes

%***Loop controls (OK to edit)***

%0 is for single-cell analysis, 1 for population
pop_start = 1;
pop_end = 1;

%1 is for stimulus/surface alignment, 2 is for saccade alignment
ref_start = 2;%1;
ref_end = 2;

%1 is for decoding phi, 2 for brt
decode_start = 1;
decode_end = 2;%2;

%1 is for decoding on labels just phi OR brt, 2 is for decoding on phi AND brt
cond_start = 2;
cond_end = 2;

%1 is for relative coordinates, 2 is for absolute coordinates
rel_start = 1;
rel_end = 2;

%For train/test conditions (1 is IN, 0 is OUT); Should have 0 to 1
train_start = 0;
train_end = 1;
test_start = 0;
test_end = 1;

%Calculation takes care of itself
num_conditions = (pop_end - pop_start + 1) * (ref_end - ref_start + 1) * (decode_end - decode_start + 1) ...
            * (cond_end - cond_start + 1) * (rel_end - rel_start + 1) ...
            * (train_end - train_start + 1) * (test_end - test_start + 1);

%***Values to be accessed with parameters/indices (don't edit unless really confident!)***
refs{1} = 'stimulus';
refs{2} = 'saccade';

decode{1} = 'phi';
decode{2} = 'brt';

conditions{1}{1}{1} = 'rel_phi';
conditions{1}{1}{2} = 'rel_phi_brt';

conditions{1}{2}{1} = 'rel_brt';
conditions{1}{2}{2} = 'rel_phi_brt';

conditions{2}{1}{1} = 'abs_phi';
conditions{2}{1}{2} = 'abs_phi_brt';

conditions{2}{2}{1} = 'abs_brt';
conditions{2}{2}{2} = 'abs_phi_brt';

%The work
 
if to_null_decode == 1

    %Not 'special' decoding
    params.decode.decode_params.is_special = 0;
    
    decoded = 0;
    
    for is_pop = pop_start : pop_end
    
        params.decode.is_pop = is_pop;

        %Choose areas to decode (1 for yes, 0 for no)
        params.decode.lip = 1;
        params.decode.pitd = 1;

        %Range of cells
        %Invalid/out of range/"bad" cells ignored
        %Ignored if population (is_pop == 1)
        params.decode.cell_start = 1;
        params.decode.cell_end = 55;

        %Is generalization analysis or "normal" analysis?
        %No control of labels with "normal" analysis
        params.decode.generalization = 1;

        for ref_index = ref_start : ref_end

            %Choose reference point and alignment

            params.decode.ref = fix_ref_case(refs{ref_index});

            params.decode.align = fix_align_case('onset');

            %These values should be left untouched unless a change is desired
            if strcmpi(params.decode.ref, 'stimulus')
                params.decode.time_start = -500; %w.r.t. align
                params.decode.time_window = 2000; %after time_start
            else
                %params.decode.time_start = -1500; %w.r.t. align
                %params.decode.time_window = 1500; %after time_start
                params.decode.time_start = -800; %w.r.t. align
                params.decode.time_window = 800; %after time_start
            end

            for decode_index = decode_start : decode_end

                for cond_index = cond_start : cond_end

                    for rel_index = rel_start : rel_end

                        params.decode.decode_on = decode{decode_index}; %'phi'; %either phi or brt
                        params.decode.labels_to_use = conditions{rel_index}{decode_index}{cond_index}; %'rel_phi'; %for ex., rel_phi_brt, abs_brt
                        
                        if rel_index == 1
                            params.decode.is_rel = 1;
                        else
                            params.decode.is_rel = 0;
                            
                            if is_pop == 1
                                %params.decode.decode_params.num_features_to_use = params.decode.decode_params.num_features_to_use * 2; 
                                %to account for permuations
                            end

                        end

                        if params.decode.generalization == 1
                            %get_decoder_labels function must be adjusted if change desired

                            if ~isempty(strfind(params.decode.labels_to_use, 'phi_brt'))

                                for train_in = train_start : train_end

                                    params.decode.train_condition_in = train_in;
                                    params.decode.train_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, train_in);

                                    for test_in = test_start : test_end

                                        params.decode.test_condition_in = test_in;   
                                        params.decode.test_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, test_in);

                                        if isempty(params.decode.train_labels) || isempty(params.decode.test_labels)
                                            warning('Decoding on %s using labels %s currently invalid\nYou may need to change decode/labels or edit get_train/test_labels functions\n', ...
                                                        params.decode.decode_on, params.decode.labels_to_use);
                                            return;
                                        end
                                        if ~is_special_null_decode
                                        run_single_decoding_batch(params.decode);
                                        end
                                        decoded = decoded + 1;
                                        
                                        %Now generate NULL distributions
                                        if is_special_null_decode
                                        special_decode = 1;
                                        params.decode.decode_params.is_special = special_decode;

                                        params.decode.train_condition_in = train_in;
                                        params.decode.train_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, train_in, special_decode);


                                        params.decode.test_condition_in = test_in;   
                                        params.decode.test_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, test_in, special_decode);
                                        
                                        if isempty(params.decode.train_labels) || isempty(params.decode.test_labels)
                                            warning('Decoding on %s using labels %s currently invalid\nYou may need to change decode/labels or edit get_train/test_labels functions\n', ...
                                                        params.decode.decode_on, params.decode.labels_to_use);
                                            return;
                                        end
                                        run_single_decoding_batch(params.decode);
                                                                                    
                                        params.decode.decode_params.is_special = 0;
                                        end % if false ends here
                                        disp('hello!!!!')
                                        fprintf('Finished %d of %d decodings\n', decoded, num_conditions);
                                    end
                                end

                            else

                                params.decode.train_condition_in = -1; %To indicate irrelevant to the next f'n
                                params.decode.train_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, params.decode.train_condition_in);                    

                                params.decode.test_condition_in = -1; %To indicate irrelevant to the next f'n
                                params.decode.test_labels = get_decoder_labels(params.decode.decode_on, params.decode.labels_to_use, params.decode.test_condition_in);

                                if isempty(params.decode.train_labels) || isempty(params.decode.test_labels)
                                    warning('Decoding on %s using labels %s currently invalid\nYou may need to change decode/labels or edit get_train/test_labels functions\n', ...
                                                params.decode.decode_on, params.decode.labels_to_use);
                                    return;
                                end

                                run_single_decoding_batch(params.decode);
                                decoded = decoded + 1;
                                fprintf('Finished %d of %d decodings\n', decoded, num_conditions);

                            end

                        else
                            run_single_decoding_batch(params.decode);
                            decoded = decoded + 1;
                            fprintf('Finished %d of %d decodings\n', decoded, num_conditions);
                        end
                    end

                end

            end

        end
        
    end
    
end

%% 4. Plot confusion matrix analysis

clear monkey area refs decode conditions analysis_type;

% monkey_index = 1; %quincy
monkey_index = 2; %michel

with_resamples = 1;

is_pop = 1;

%Only relevant for population
is_restricted = 1;
is_restricted_by_top = 0; %only relevant if is_restricted is 1
num_top_cells = 20; %only relevant if both of the above are 1

%***Loop controls (OK to edit)***

% %0 is for single-cell analysis, 1 for population
% pop_start = 1;
% pop_end = 1;

%1 is for stimulus/surface alignment, 2 is for saccade alignment
ref_start = 1;
ref_end = 2;

%1 is for decoding phi, 2 for brt
decode_start = 1;
decode_end = 2;

%1 is for decoding on just phi OR brt, 2 is for decoding on phi AND brt
%1 is 4 way classification; 2 is binary classification
cond_start = 2;
cond_end = 2;

%1 is for relative coordinates, 2 is for absolute coordinates
rel_start = 1;
rel_end = 2;

%For train/test conditions (1 is IN, 0 is OUT); Should have 0 to 1
train_start = 0;
train_end = 1;
test_start = 0;
test_end = 1;

%***Values to be accessed with parameters/indices (don't edit unless really confident!)***
monkey{1} = 'Quincy';
monkey{2} = 'Michel';

area{1} = 'lip';
area{2} = 'pitd';

refs{1} = 'stimulus';
refs{2} = 'saccade';

decode{1} = 'phi';
decode{2} = 'brt';

conditions{1}{1}{1} = 'rel_phi';
conditions{1}{1}{2} = 'rel_phi_brt';

conditions{1}{2}{1} = 'rel_brt';
conditions{1}{2}{2} = 'rel_phi_brt';

conditions{2}{1}{1} = 'abs_phi';
conditions{2}{1}{2} = 'abs_phi_brt';

conditions{2}{2}{1} = 'abs_brt';
conditions{2}{2}{2} = 'abs_phi_brt';

analysis_type{1} = 'guessed';
analysis_type{2} = 'presented';

if to_plot_confusion == 1
    
    params.analysis.is_special = to_plot_special_confusion;
    
    if is_pop == 1
        
        %% 1. Is population
            
        %Choose monkey
        params.analysis.monkey = fix_monkey_case(monkey{monkey_index});

        params.analysis.is_restricted = is_restricted;
        params.analysis.is_restricted_by_top = is_restricted_by_top;
        params.analysis.num_top_cells = num_top_cells;
        
        params.analysis.with_resamples = with_resamples;
        
        params.analysis.is_special = to_plot_special_confusion;
        
        for area_index = 1 : 2
        
            %Choose area to analyze
            params.analysis.area = area{area_index};

            %Choose reference point and alignment
            
            for ref_index = ref_start : ref_end            

                params.analysis.ref = fix_ref_case(refs{ref_index});

                params.analysis.align = fix_align_case('onset');

                %These values should be left untouched unless a change is desired
                if strcmpi(params.analysis.ref, 'stimulus')
                    params.analysis.time_start = -500; %w.r.t. align
                    params.analysis.time_window = 2000; %after time_start
                else
                    params.analysis.time_start = -1500; %w.r.t. align
                    params.analysis.time_window = 1500; %after time_start
                end

                for decode_index = decode_start : decode_end

                    params.analysis.decode_on = decode{decode_index};  %'phi'; %either phi or brt
                    
                    for cond_index = cond_start : cond_end

                        for rel_index = rel_start : rel_end
                        
                            if cond_index == 1
                                params.analysis.num_classes = 4;
                            else
                                params.analysis.num_classes = 2;
                            end
                            
                            params.analysis.labels_to_use = conditions{rel_index}{decode_index}{cond_index}; %'rel_phi'; %for ex., rel_phi_brt, abs_brt

                            if cond_index == 1 %so just PHI or just BRT...
                            
                                if params.analysis.is_special == 1;
                                    error('"Special" decoding not valid with labels of just phi or just brt');
                                end
                                
                                params.analysis.train_in = -1;                                
                                params.analysis.test_in = -1;
                                
                                for analyze = 1 : params.analysis.num_classes
                                    params.analysis.analyze_class = analyze;
                                    for type = 1 : 2 %For guessed and presented
                                        params.analysis.analysis_type = analysis_type{type};

                                        cd(analysis_dir);
                                        [figure_dir, decode_params] = analyze_confusion_population(params.analysis); %figure_dir will be the same for all calls within a given run
                                        cd(start_dir);
                                    end
                                end

                                if isempty(figure_dir)
                                    warning('Unsuccessful analysis due to no valid decoding!');
                                    return;
                                end

                                %Write decoding paramters in figure_dir
                                cd(figure_dir);
                                write_analysis_parameters(decode_params.results, decode_params.results.valid_sites_found);
                                check_analysis_validity(params.analysis, decode_params.results);
                                cd(start_dir);
                                
                            else
                                              
                                if params.analysis.is_special == 1
                                    
                                    for train_in = train_start : train_end

                                        for test_in = test_start : test_end
                                        
                                            params.analysis.train_in = train_in;
                                            params.analysis.test_in = test_in;

                                            for analyze = 1 : params.analysis.num_classes
                                                params.analysis.analyze_class = analyze;
                                                for type = 1 : 2 %presented and guessed
                                                    params.analysis.analysis_type = analysis_type{type};

                                                    cd(analysis_dir);
                                                    [figure_dir, decode_params] = analyze_confusion_population(params.analysis); 
                                                    %figure_dir will be the same for all calls within a given run
                                                    cd(start_dir);
                                                end
                                            end

                                            if isempty(figure_dir)
                                                warning('Unsuccessful analysis due to no valid decoding!');
                                                continue;
                                            end

                                            %Write decoding paramters in figure_dir
                                            cd(figure_dir);
                                            write_analysis_parameters(decode_params.results, decode_params.results.valid_sites_found);
                                            check_analysis_validity(params.analysis, decode_params.results);
                                            cd(start_dir);
                                            
                                        end
                                        
                                    end

                                else
                                
                                    for train_in = train_start : train_end

                                        params.analysis.train_in = train_in;                                

                                        for test_in = test_start : test_end

                                            params.analysis.test_in = test_in;

                                            for analyze = 1 : params.analysis.num_classes
                                                params.analysis.analyze_class = analyze;
                                                for type = 1 : 2 %presented and guessed
                                                    params.analysis.analysis_type = analysis_type{type};

                                                    cd(analysis_dir);
                                                    [figure_dir, decode_params] = analyze_confusion_population(params.analysis); 
                                                    %figure_dir will be the same for all calls within a given run
                                                    cd(start_dir);
                                                end
                                            end

                                            if isempty(figure_dir)
                                                warning('Unsuccessful analysis due to no valid decoding!');
                                                return;
                                            end

                                            %Write decoding paramters in figure_dir
                                            cd(figure_dir);
                                            write_analysis_parameters(decode_params.results, decode_params.results.valid_sites_found);
                                            check_analysis_validity(params.analysis, decode_params.results);
                                            cd(start_dir);

                                        end

                                    end
                                    
                                end
                                
                            end
                        end
                    end
                end

            end
        
        end
        
    else
    
        %% 2. Not population
        
        params.analysis.monkey = fix_monkey_case(monkey{monkey_index});
        
        params.analysis.is_restricted = is_restricted;
        params.analysis.is_restricted_by_top = is_restricted_by_top;
        params.analysis.num_top_cells = num_top_cells;
        
        params.analysis.with_resamples = with_resamples;
        
        %Range of cells
        %Invalid/out of range/"bad" cells ignored
        params.analysis.cell_start = 1;
        params.analysis.cell_end = 55;
        
        for area_index = 1 : 2
        
            %Choose area to analyze
            params.analysis.area = area{area_index}; %'lip';

            for ref_index = ref_start : ref_end
                
                %Choose reference point and alignment
                params.analysis.ref = fix_ref_case(refs{ref_index});
                params.analysis.align = fix_align_case('onset');

                %These values should be left untouched unless a change is desired
                if strcmpi(params.analysis.ref, 'stimulus')
                    params.analysis.time_start = -500; %w.r.t. align
                    params.analysis.time_window = 2000; %after time_start
                else
                    params.analysis.time_start = -1500; %w.r.t. align
                    params.analysis.time_window = 1500; %after time_start
                end

                for cond_index = cond_start : cond_end
                    
                    for decode_index = decode_start : decode_end
                
                        params.analysis.decode_on = decode{decode_index};
                        
                        for rel_index = rel_start : rel_end
                        
                            if cond_index == 1
                                params.analysis.num_classes = 4;
                            else
                                params.analysis.num_classes = 2;
                            end

                            params.analysis.labels_to_use = conditions{rel_index}{decode_index}{cond_index}; %'rel_phi'; %for ex., rel_phi_brt, abs_brt

                            if cond_index == 1 %so just PHI or just BRT...
                            
                                if params.analysis_is_special == 1
                                    error('Special decoding not compatible with label of just phi or just brt');
                                end
                                
                                params.analysis.train_in = -1;                                
                                params.analysis.test_in = -1;
                                
                                for analyze = 1 : params.analysis.num_classes
                                    params.analysis.analyze_class = analyze;
                                    for type = 1 : 2
                                        params.analysis.analysis_type = analysis_type{type}; %'guessed';

                                        cd(analysis_dir);
                                        [figure_dir, decode_params] = analyze_confusion(params.analysis); %figure_dir will be the same for all calls within a given run
                                        
                                        if ~isempty(decode_params)
                                            decode_params_save = decode_params; %to avoid replacing a valid copy with an empty one
                                        end
                                        
                                        cd(start_dir);
                                    end
                                end

                                if isempty(figure_dir)
                                    warning('Unsuccessful analysis due to no valid decoding!');
                                    return;
                                end
                                
                                %Write decoding paramters in figure_dir
                                cd(figure_dir);
                                write_analysis_parameters(decode_params_save.results);
                                check_analysis_validity(params.analysis, decode_params_save.results);
                                cd(start_dir);
                                
                            else
                                           
                                if params.analysis.is_special == 1
                                    
                                    for non_decode_in = non_decode_in_start : non_decode_in_end

                                        params.analysis.train_in = non_decode_in;
                                        params.analysis.test_in = non_decode_in;
                                        
                                        for analyze = 1 : params.analysis.num_classes
                                            params.analysis.analyze_class = analyze;
                                            for type = 1 : 2 %presented and guessed
                                                params.analysis.analysis_type = analysis_type{type};

%                                                 cd(analysis_dir);
                                                [figure_dir, decode_params] = analyze_confusion(params.analysis); 
                                                %figure_dir will be the same for all calls within a given run
%                                                 cd(start_dir);
                                            end
                                        end

                                        if isempty(figure_dir)
                                            warning('Unsuccessful analysis due to no valid decoding!');
                                            return;
                                        end

                                        %Write decoding paramters in figure_dir
                                        cd(figure_dir);
                                        write_analysis_parameters(decode_params.results);
                                        check_analysis_validity(params.analysis, decode_params.results);
                                        cd(start_dir);
                                        
                                    end
                                    
                                else
                                
                                    for train_in = train_start : train_end

                                        params.analysis.train_in = train_in;                                

                                        for test_in = test_start : test_end

                                            params.analysis.test_in = test_in;

                                            for analyze = 1 : params.analysis.num_classes
                                                params.analysis.analyze_class = analyze;
                                                for type = 1 : 2
                                                    params.analysis.analysis_type = analysis_type{type}; %'guessed';

%                                                     cd(analysis_dir);
                                                    [figure_dir, decode_params] = analyze_confusion(params.analysis); %figure_dir will be the same for all calls within a given run
%                                                     cd(start_dir);
                                                end
                                            end

                                            if isempty(figure_dir)
                                                warning('Unsuccessful analysis due to no valid decoding!');
                                                return;
                                            end

                                            %Write decoding paramters in figure_dir
                                            cd(figure_dir);
                                            write_analysis_parameters(decode_params.results);
                                            check_analysis_validity(params.analysis, decode_params.results);
                                            cd(start_dir);

                                        end

                                    end
                                    
                                end
                                
                            end
                        
                        end
                        
                    end
                    
                end
                
            end
            
        end
    end
    
   
end

%% 5. Plot mean decoding analysis (mean decoding results)

if to_plot_mean == 1

%    monkey = 'Quincy';
     monkey = 'Michel';
    
    is_pop = 1;

    is_restricted = 1;
    is_restricted_by_top = 0;
    num_top_cells = 20;

    %1 is for relative coordinates, 2 is for absolute coordinates
    rel_start = 1;
    rel_end = 2;
    

    for rel_index = rel_start : rel_end
        
        if rel_index == 1
            labels_to_use = 'rel_phi_brt';
        else
            labels_to_use = 'abs_phi_brt';
        end
            
        %Only works for 'rel_phi_brt' or 'abs_phi_brt' conditions and alignment on 'onset'
        mean_decoding(labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, monkey, to_plot_mean_special);
        
    end
end

%% 6. Plot comparative analysis (LIP vs. PITd for confusion matrix + mean decoding results)
%This also plots cross-time training matrices and, if NULL distributions
%have been computed, mean decoding results with significance indicated

if to_compare == 1
    
    monkey = 'Quincy';
%   monkey = 'Michel';
%    monkey = 'both_monkeys';
    
    is_pop = 1;
    is_restricted = 1;
    is_restricted_by_top = 1;
    num_top_cells = 20;

    with_resamples = 1;

    p_val_params.use_p_vals=1; %1:Enable display of significance in comparative plots
    p_val_params.null_resamples=50; %Resamples in the null decodings
    p_val_params.p_threshold=0.05;
    p_val_params.mult_compare_method='fdr';
    if ~to_compare_special
    p_val_params.null_CVs=6; %Cross-validation splits in the null decodings
    else
    p_val_params.null_CVs=3;
    end    
    
    %1 is for relative coordinates, 2 is for absolute coordinates
    rel_start = 1;
    rel_end = 2;
       
    clear refs decode;
    
    refs{1} = 'stimulus';
    refs{2} = 'saccade';

    decode{1} = 'phi';
    decode{2} = 'brt';
    
    analysis{1} = 'guessed';
    analysis{2} = 'presented';

    for rel_index = rel_start : rel_end

        if rel_index == 1
            labels_to_use = 'rel_phi_brt';
        else
            labels_to_use = 'abs_phi_brt';
        end
            
        for ref_index = 2 : 2 %%%CHANGE!!!

            ref = refs{ref_index};

            for decode_index = 1 : 2

                decode_on = decode{decode_index};

                for train_in = 0 : 1

                    for test_in = 0 : 1

                        make_comparative_decode_plots(monkey, labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special,p_val_params);

                        if is_pop == 1
                            make_TCT_plot(monkey, 'LIP', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special);
                            make_TCT_plot(monkey, 'PITd', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special);
                        else
                            for cell_no = 1 : 55
                                make_TCT_plot(monkey, 'LIP', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special, cell_no);
                                make_TCT_plot(monkey, 'PITd', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special, cell_no);
                            end
                        end

                        %make_NDT_mean_plot requires existing NULL
                        %distributions for each train/test condition
    %                     if is_pop == 1
    %                         make_NDT_mean_plot(monkey, 'LIP', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special, use_fewer_NULL);
    %                         make_NDT_mean_plot(monkey, 'PITd', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special, use_fewer_NULL);
    %                     else
    %                         for cell_no = 1 : 55
    %                             make_NDT_mean_plot(monkey, 'LIP', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special, cell_no, use_fewer_NULL);
    %                             make_NDT_mean_plot(monkey, 'PITd', labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, to_compare_special, cell_no, use_fewer_NULL);
    %                         end
    %                     end


                        for analysis_index = 1 : 2

                            analysis_type = analysis{analysis_index};

                            make_comparative_conf_plots(monkey, labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_pop, ref, decode_on, train_in, test_in, analysis_type, with_resamples, to_compare_special,p_val_params);
                            
                        end                
                    end                
                end            
            end        
        end
    end
end

%% 7. Compute statistical values

if to_compute_sig == 1
    
%    monkey = 'Quincy';
     monkey = 'Michel';
    
    labels_to_use = 'rel_phi_brt';
    % labels_to_use = 'abs_phi_brt';

    significance_threshold = 0.05;

    clear refs decode;
    
    refs{1} = 'stimulus';
    refs{2} = 'saccade';

    decode{1} = 'phi';
    decode{2} = 'brt';
        
    for ref_index = 1 : 2
        
        ref = refs{ref_index};
        
        for decode_index = 1 : 2
            
            decode_on = decode{decode_index};
    
            for train_in = 0 : 1
                
                for test_in = 0 : 1
                    
                    if to_compute_sig_special == 1
                        if train_in ~= test_in
                            continue;
                        end
                    end
                    
                    compute_significance_across_area(monkey, refs{ref_index}, labels_to_use, decode{decode_index}, train_in, test_in, ...
                                           to_compute_sig_special, significance_threshold); 

                end                
            end            
        end        
    end
end
