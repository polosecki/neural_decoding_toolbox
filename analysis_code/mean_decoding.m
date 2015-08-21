function [] = mean_decoding(labels_to_use, is_restricted, is_restricted_by_top, top_k_cells, is_population, monkey, is_special)
%Calculates mean decoding for all decoded conditions

%ASSUMPTIONS:
%   Analyzing a time 'window' (rather than one slice of time)
%   Only care about the binary classifications (label has phi_brt)
%   Only care about relative coordinates (so label is rel_phi_brt)

clear area refs decode conditions;

root_save = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'figures');

if is_population == 1
    root_save = fullfile(root_save, 'Population_Analysis');
else
    root_save = fullfile(root_save, 'Single_Cell_Analysis');
end

area{1} = 'LIP';
area{2} = 'PITd';

refs{1} = 'stimulus';
refs{2} = 'saccade';

decode{1} = 'phi';
decode{2} = 'brt';

for area_index = 1 : 2
    
    for ref_index = 1 : 2
        
        if strcmpi(refs{ref_index}, 'stimulus')
            time_vector = [-500 : 100 : 1400];
            time_start = -500;
            time_window = 2000;
        else
            time_vector = [-1500 : 100 : -100];
            time_start = -1500;
            time_window = 1500;
        end

        for decode_index = 1 : 2

            decode_on = decode{decode_index};
            
            for train_in = 0 : 1

                for test_in = 0 : 1
		                                        
                    clear means errors all_means std_dev;
                    
                    count = 1;
                    
                    if is_population == 1

                        arbitrary_cell = 1; %Doesn't matter for population

                        [decoding, params] = get_decoding_results(monkey, area{area_index}, refs{ref_index}, 'onset', arbitrary_cell, ...
                                                   time_start, time_window, 'window', labels_to_use, decode_on, train_in, test_in, ...
                                                   is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special);

                        DECODING_RESULTS = decoding.DECODING_RESULTS;
                        
                        if isempty(DECODING_RESULTS)
                            continue;
                        end
                                               
                        means(:, count) = diag(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results);
                        %PIP 9/18/2014
                        errors(:, count) = diag(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples);%2*diag(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples)/sqrt(params.results.num_resample_runs);
                       
                    else
                        
                        for cell_no = 1 : 55
                            
                            decoding = get_decoding_results(monkey, area{area_index}, refs{ref_index}, 'onset', cell_no, ...
                                           time_start, time_window, 'window', labels_to_use, decode_on, train_in, test_in, ...
                                           is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special);
                                       
                            if isempty(decoding)
                                continue;
                            end
                                       
                            DECODING_RESULTS = decoding.DECODING_RESULTS;
                                       
                            if isempty(DECODING_RESULTS)
                                continue;
                            end
                            
                            all_means(:, count) = diag(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results);                            
                            count = count + 1;
                        end
                        
                        count = 1;
                        means(:, count) = mean(all_means, 2);
                        std_dev = std(all_means, 0, 2)';
                        %PIP 9/18/2014
                        errors(:, count) = std_dev;%2*std_dev/sqrt(size(all_means, 2));
                                               
                    end
                    
                    colors = hsv(count); %get unique colors

                    %% 1. Graph
                    graph = figure();
                    hold on;

                    for i = 1 : size(means, 2)
                        plots(i) = shadedErrorBar(time_vector, means(:, i), errors(:, i), {'Color', colors(i, :)}, 1);
                        plots_to_use(i) = plots(i).mainLine; %mainLine represents actual line, from shadedErrorBar code author
                        labels{i} = 'mean decoding';
                    end

                    ylim([0 1]);
                    line(xlim, [1/2 1/2], 'Color', 'k');

                    %indicate line of saccade or stimulus onset
                    line([0 0], ylim, 'Color', 'k', 'LineWidth', 2);

                    title_save = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in, is_special);
                                       
                    title_str = strrep(title_save, '_', ' ');
                    title_str = strrep(title_str, 'Decode ', '');

                    title(sprintf('Mean decoding for %s', title_str));
                    legend(plots_to_use(1, :), labels, 'Location', 'SouthWest');
                    legend('show');

                    hold off;
                    
                    if is_restricted == 1
                        if is_restricted_by_top == 1
                            dir_ending = sprintf('restrict_top_%d', num_top_cells);
                        else
                            dir_ending = sprintf('restricted_equal');
                        end
                    else
                        dir_ending = sprintf('unrestricted');
                    end

                    save_dir = fullfile(root_save, monkey, refs{ref_index}, title_save, dir_ending);

                    if ~exist(save_dir, 'dir')
                        mkdir(save_dir);
                    end

                    saveas(graph, fullfile(save_dir, sprintf('%s_mean_decoding.png', area{area_index})));
                    
                    %Save as SVG
                    addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
                    plot2svg(fullfile(save_dir, sprintf('%s_mean_decoding.svg', area{area_index})), graph);
                    
                    close(graph);              
                               
                end
            end
        end
    end
end
