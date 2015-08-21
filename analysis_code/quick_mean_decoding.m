function [] = quick_mean_decoding(is_restricted, top_k_cells, is_population, monkey)
%Calculates mean decoding for all decoded conditions

clear area refs decode conditions;

root_dir = fullfile('/Freiwald/ppolosecki', 'lspace', 'plevy', 'data', monkey, 'attn');

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

conditions{1}{1}{1} = 'rel_phi';
conditions{1}{1}{2} = 'rel_phi_brt';

conditions{1}{2}{1} = 'rel_brt';
conditions{1}{2}{2} = 'rel_phi_brt';

conditions{2}{1}{1} = 'abs_phi';
conditions{2}{1}{2} = 'abs_phi_brt';

conditions{2}{2}{1} = 'abs_brt';
conditions{2}{2}{2} = 'abs_phi_brt';

labels_to_use = 'rel_phi_brt';

for area_index = 1 : 2
    
    for ref_index = 1 : 2
        
        if strcmpi(refs{ref_index}, 'stimulus')
            time_vector = [-500 : 100 : 1400];
        else
            time_vector = [-1500 : 100 : -100];
        end

        data = sprintf('Population_%s_%s', area{area_index}, refs{ref_index});
        
        data_dir = dir(fullfile(root_dir, data));

        if isempty(data_dir)
            fprintf('Looked unsuccessfully in %s\n', fullfile(root_dir, data));
            continue;
        end
        
        to_look = fullfile(fullfile(fullfile(root_dir, data), data_dir(3).name), 'results');
        
        closer = dir(to_look);
        
        for decode_index = 1 : 2

            decode_on = decode{decode_index};
            
            for train_in = 0 : 1

                for test_in = 0 : 1

                    count = 0;

                    clear dir_names; clear means; clear errors;

                    for i = 3 : size(closer, 1) %3 to skip '.' and '..'
                        if closer(i).isdir == 1
                            sub_dir_name = fullfile(to_look, closer(i).name);

                            if is_restricted == 0
                                if isempty(strfind(sub_dir_name, 'unrestricted'))
                                    continue;
                                end
                            else
                                if isempty(strfind(sub_dir_name, sprintf('%d', top_k_cells)))
                                    continue;
                                end
                            end
                                
                            sub_dir = dir(sub_dir_name);
                            count = count + 1;
                            dir_names{count} = closer(i).name;
                            file_to_load = [get_file_name_conditions(labels_to_use, decode_on, train_in, test_in) '.mat'];
                            for i = 1 : size(sub_dir, 1)
                                if strcmpi(file_to_load, sub_dir(i).name)
                                    load(fullfile(sub_dir_name, sub_dir(i).name));
                                    
%                                     fprintf('Looking at %s\n', sub_dir(i).name);
                                    
                                    if isempty(DECODING_RESULTS)
                                        warning('Empty decoding! File %s', file_to_load);
                                        continue;
                                    end
                                    
                                    means(:, count) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
                                    %PIP 9/14/2014
                                    errors(:, count) = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples;%2*DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples/sqrt(20);
                                    dir_names{count} = sprintf('%s (%d)', dir_names{count}, DECODING_RESULTS.CV_PARAMETERS.dimension_of_data_points);

                                    
                                end
                            end
                        end
                    end

                    colors = hsv(count); %get unique colors

                    %% 1. Graph
                    graph = figure();
                    hold on;

                    for i = 1 : size(means, 2)
                        plots(i) = shadedErrorBar(time_vector, means(:, i), errors(:, i), {'Color', colors(i, :)}, 1);
                        plots_to_use(i) = plots(i).mainLine; %mainLine represents actual line, from shadedErrorBar code author
                        labels{i} = strrep(dir_names{1, i}, '_', ' ');
                    end

                    ylim([0 1]);
                    line(xlim, [1/2 1/2], 'Color', 'k');

                    %indicate line of saccade or stimulus onset
                    line([0 0], ylim, 'Color', 'k', 'LineWidth', 2);

                    title_save = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in);
                    title_str = strrep(title_save, '_', ' ');

                    title(sprintf('Mean decoding for %s', title_str));
                    legend(plots_to_use(1, :), labels);
                    legend('show');

                    hold off;
                    
                    if is_restricted == 1
                        dir_ending = sprintf('restrict_top_%d', num_top_cells);
                    else
                        dir_ending = sprintf('unrestricted');
                    end

                    save_dir = fullfile(root_save, monkey, refs{ref_index}, title_save, dir_ending);

                    if ~exist(save_dir, 'dir')
                        mkdir(save_dir);
                    end

%                     fprintf('Saving in %s\n', save_dir);
                    
                    saveas(graph, fullfile(save_dir, sprintf('%s_mean_decoding.jpg', area{area_index})));
                    
                    close(graph);              
                               

                end

            end
            
        end
        
    end
    
end
