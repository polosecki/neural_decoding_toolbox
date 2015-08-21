function [] = make_comparative_decode_plots(monkey, labels_to_use, is_restricted, is_restricted_by_top, top_k_cells, is_population, ref, decode_on, train_in, test_in, is_special,p_val_params)
%For given conditions, makes plot comparing the binary classification
%success in PITd vs. LIP

%% 0. Get desired values to plot

area{1} = 'LIP';
area{2} = 'PITd';

%Assume the following
start_cell = 1; %If needed for single-cell analysis
end_cell = 55;
time_type = 'window';
align = 'onset';

if strcmpi(ref, 'stimulus')
    time_vector = [-500 : 100 : 1400];
    time_start = -500;
    time_window = 2000;
else
    time_vector = [-800 : 100 : -100];
    time_start = -800;
    time_window = 800;
end

for area_index = 1 : 2
    
    if is_population == 1

        arbitrary_cell = 1; %Just to keep below function happy

        [decode_results, decode_params] = get_decoding_results(monkey, area{area_index}, ref, align, arbitrary_cell, time_start, time_window, time_type, labels_to_use, ...
                                        decode_on, train_in, test_in, is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special);

        if isempty(decode_results) || isempty(decode_params) || isempty(decode_results.DECODING_RESULTS)
            warning('No valid confusion matrix found!');
            return;
        end
        

        
        time_vector = decode_params.results.time_vector;
        num_time_bins = size(time_vector, 2);
        
        mean_results = decode_results.DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
        
        if size(mean_results, 1) == size(mean_results, 2) %then this is square matrix, with cross-time train/test
            means(area_index, :) = diag(mean_results);
        else %assume just test and train at same times, so already 1-D
            means(area_index, :) = mean_results;
        end
        
        std_results = decode_results.DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples;

        if size(std_results, 1) == size(std_results, 2) %then this is square matrix, with cross-time train/test
            errors(area_index, :) = diag(std_results); %2*diag(std_results)/sqrt(decode_params.results.num_resample_runs);
        else %assume just test and train at same times, so already 1-D
            errors(area_index, :) = std_results; %2*std_results/sqrt(decode_params.results.num_resample_runs);
        end
        
        if p_val_params.use_p_vals
            [p_vals]=get_decoding_pvals(monkey, area{area_index}, ref, align, arbitrary_cell, time_start, time_window, time_type, labels_to_use, ...
                decode_on, train_in, test_in, is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special,p_val_params.null_resamples,p_val_params.null_CVs);
            p_values{area_index}=p_vals;
        else
            p_values{area_index}=[];
        end
        

    else

        clear separate_means;
        index_to_add = 1;

        for cell_no = start_cell : end_cell
        
            [decode_results, decode_params] = get_decoding_results(monkey, area{area_index}, ref, align, cell_no, time_start, time_window, time_type, labels_to_use, ...
                                        decode_on, train_in, test_in, is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special);

            if isempty(decode_results) || isempty(decode_params) || isempty(decode_results.DECODING_RESULTS)
%                 separate_means(area_index, index_to_add, :) = [];
                continue;
            end
            
            mean_results = decode_results.DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;

            if size(mean_results, 1) == size(mean_results, 2) %then this is square matrix, with cross-time train/test
                separate_means(index_to_add, :) = diag(mean_results);
            else %assume just test and train at same times, so already 1-D
                separate_means(index_to_add, :) = mean_results;
            end
            
            index_to_add = index_to_add + 1;
        end

        num_valid_cells = size(separate_means, 2);
        
        means(area_index, :) = mean(separate_means, 1);
        errors(area_index, :) = std(separate_means, 0, 1);%2*std(separate_means, 0, 1)/sqrt(num_valid_cells);

    end
        
end

%% 1. Graph
root_dir = '/Freiwald/ppolosecki/lspace/plevy/figures/comparative';

if ~exist(root_dir, 'dir')
    mkdir(root_dir);
end

colors(1, :) = [0 0 128]/255; %navy/dark blue
colors(2, :) = [255 0 0]/255; %(darker) red

graph = figure();
hold on;

count = 1;

t_step=mode(diff(time_vector));
plotted_time=(time_vector+t_step)/1000; %centered on cente rof time slice
for area_index = 1 : 2
    plots(count) = shadedErrorBar(plotted_time, 100*means(area_index, :), 100*errors(area_index, :), {'Color', colors(count, :),'LineWidth', 2,'Marker','.','MarkerSize',20}, 1);
    plots_to_use(count) = plots(count).mainLine; %mainLine represents actual line, from shadedErrorBar code author
    labels{count} = sprintf('%s', area{area_index});
    count = count + 1;
end

set(gca,'FontSize',15)
ylim([0 100]);
set(gca,'ytick',[0 25 50 75 100])


%indicate line of saccade or stimulus onset
line([0 0], ylim, 'Color', 'k', 'LineStyle', '--');

title_save = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in, is_special);
title_str = strrep(title_save, '_', ' ');
title_str = strrep(title_str, 'Decode ', '');

title(sprintf('Mean decoding for %s %s', title_str,monkey));
%lg=legend(plots_to_use(1, :), labels, 'Location', 'SouthWest');
%set(lg,'Box','off')
%legend('show');


ylabel('Decoding accuracy (%)','FontSize',15)

pvals_offset=[7.5 5];
for area_index=1:2
if p_val_params.use_p_vals && ~isempty(p_values{area_index})
    mult_compare_method=p_val_params.mult_compare_method;
    p_threshold=p_val_params.p_threshold;%.01;
            switch mult_compare_method
                case 'none'
                    h=p_values{area_index}<p_threshold;
                case 'bonferroni'
                    h=p_values{area_index}<(p_threshold/sum(cellfun(@length,p_values)));
                case 'fdr'                    
                    tested_pvals=horzcat(p_values{:});
                    [h_tested, crit_p]=fdr_bky(abs(tested_pvals),p_threshold);% Benjamini & Hochberg/Yekutieli method
                    %[h_tested, crit_p, ~]=fdr_bh(abs(tested_pvals),p_threshold);
                    h=h_tested((1:length(tested_pvals)/2)+(area_index-1)*length(tested_pvals)/2);
                case 'holm-bonferroni'                  
                    tested_pvals=horzcat(p_values{:});
                    adjustedPVals = frmrHolmBonferoni(tested_pvals);
                    h_tested=adjustedPVals<p_threshold;
                    h=h_tested((1:length(tested_pvals)/2)+(area_index-1)*length(tested_pvals)/2);
            end
    for i=1:length(p_values{area_index})
        time_semiwidth=mode(diff(plotted_time))/2;
        if h(i) %p_values{area_index}(i)<p_threshold
            line([plotted_time(i)-time_semiwidth plotted_time(i)+time_semiwidth],[pvals_offset(area_index) pvals_offset(area_index)], 'Color', colors(area_index,:),'LineWidth', 1)
        end
    end
end
end

if plotted_time(end)>0.05
xlim([plotted_time(1) plotted_time(end)])
xlabel('Time from stimulus onset (s)','FontSize',15)
else
xlim([plotted_time(1) 0.02])
xlabel('Time from saccade onset (s)','FontSize',15)

end
line(xlim, [50 50], 'Color', 'k');
%keyboard

hold off;

if is_restricted == 1
    if is_restricted_by_top == 1
        dir_ending = sprintf('restrict_top_%d', top_k_cells);
    else
        dir_ending = sprintf('restricted_equal');
    end
else
    dir_ending = sprintf('unrestricted');
end

if is_population == 1
    save_dir = fullfile(root_dir, monkey, ref, 'population', title_save, dir_ending);
else
    save_dir = fullfile(root_dir, monkey, ref, 'single_cell', title_save, dir_ending);
end

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end


saveas(graph, fullfile(save_dir, 'mean_decoding_analysis.png'));

%Save as SVG
addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
plot2svg(fullfile(save_dir, 'mean_decoding_analysis.svg'), graph);

close(graph);

end
