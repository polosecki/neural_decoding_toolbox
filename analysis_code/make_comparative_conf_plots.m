function [] = make_comparative_conf_plots(monkey, labels_to_use, is_restricted, is_restricted_by_top, num_top_cells, is_population, ref, decode_on, train_in, test_in, analysis_type, with_resamples, is_special,p_val_params)
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
classes = 2;

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
        
        [conf_matrix, decode_params] = get_confusion_matrix_population(monkey, area{area_index}, ref, align, time_start, time_window, time_type, labels_to_use, decode_on, ...
            train_in, test_in, is_restricted, is_restricted_by_top, num_top_cells, with_resamples, is_special);
        
        if isempty(conf_matrix) || isempty(decode_params)
            return;
        end
        
        if with_resamples == 1
            
            for class_index = 1 : classes
                
                [curr_mean, curr_error, num_resamples] = analyze_resample_confusion(conf_matrix, class_index, class_index, classes, analysis_type);
                
                means(area_index, class_index, :) = curr_mean;
                %PIP 9/18/2014
                errors(area_index, class_index, :) = curr_error;%2*curr_error ./ sqrt(num_resamples);
                
                %                 if num_resamples ~= decode_params.results.num_resample_runs
                %                     error('Number of resamples (%d) in decoding parameter file not equal to number of resamples in matrix (%d)', ...
                %                         decode_params.results.num_resample_runs, num_resamples);
                %                 end
                
            end
            
        else
            
            for class_index = 1 : classes
                
                [curr_means, curr_errors] = get_confusion_analysis_pop(conf_matrix, decode_params, classes, class_index, ...
                    analysis_type, length(time_vector));
                
                means(area_index, class_index, :) = curr_means(class_index, :);
                errors(area_index, class_index, :) = curr_errors(class_index, :);
                
            end
            
        end
        if p_val_params.use_p_vals
            [p_vals]=get_decoding_pvals(monkey, area{area_index}, ref, align, 1, time_start, time_window, time_type, labels_to_use, ...
                decode_on, train_in, test_in, is_restricted, is_restricted_by_top, num_top_cells, is_population, is_special,p_val_params.null_resamples,p_val_params.null_CVs);
            p_values{area_index}=p_vals;
        else
            p_values{area_index}=[];
        end
    else
        
        if with_resamples == 1
            
            count = 1;
            
            for cell_no = start_cell : end_cell
                [conf_matrix, decode_params] = get_confusion_matrix(monkey, area{area_index}, ref, align, cell_no, time_start, time_window, time_type, labels_to_use, ...
                    decode_on, train_in, test_in, is_restricted, is_restricted_by_top, num_top_cells, with_resamples, is_special);
                
                if isempty(conf_matrix) || isempty(decode_params)
                    continue;
                end
                
                for class_index = 1 : classes
                    [curr_mean, ~] = analyze_resample_confusion(conf_matrix, class_index, class_index, classes, analysis_type);
                    all_means(count, class_index, :) = curr_mean;
                end
                
                count = count + 1;
                
            end
            
            valid_cells = count - 1;
            
            for class_index = 1 : classes
                means(area_index, class_index, :) = mean(all_means(:, class_index, :), 1);
                %PIP 9/18/2014:
                errors(area_index, class_index, :) = std(all_means(:, class_index, :), 0, 1);%2*std(all_means(:, class_index, :), 0, 1)/sqrt(valid_cells);
            end
            
        else
            
            params.num_classes = classes;
            params.analysis_type = analysis_type;
            params.labels_to_use = labels_to_use;
            params.decode_on = decode_on;
            params.monkey = monkey;
            params.area = area{area_index};
            params.ref = ref;
            params.align = align;
            params.time_start = time_start;
            params.time_window = time_window;
            
            params.train_in = train_in;
            params.test_in = test_in;
            
            params.is_restricted = is_restricted;
            params.is_restricted_by_top = is_restricted_by_top;
            params.num_top_cells = num_top_cells;
            
            params.with_resamples = with_resamples;
            
            for class_index = 1 : classes
                
                params.analyze_class = class_index;
                
                [curr_means, curr_errors, ~, time_vector] = get_confusion_analysis(start_cell, end_cell, params);
                
                means(area_index, class_index, :) = curr_means(class_index, :);
                errors(area_index, class_index, :) = curr_errors(class_index, :);
                
            end
            
        end
        
    end
end

%% 1. Graph
root_dir = '/Freiwald/ppolosecki/lspace/plevy/figures/comparative';

if ~exist(root_dir, 'dir')
    mkdir(root_dir);
end

colors(1, :) =  [115   140   204]/255;%[173 216 230]/255; %light blue
colors(2, :) = [0 0 128]/255; %navy/dark blue
colors(3, :) = [240 128 128]/255; %light red
colors(4, :) = [255 0 0]/255; %(darker) red

graph = figure();

hold on;

count = 1;

% fprintf('Time vector: [%d X %d]\n', size(time_vector, 1), size(time_vector, 2));
% fprintf('Means vector: [%d X %d]\n', size(means(area_index, class_index, :), 1), size(means(area_index, class_index, :), 2));
% fprintf('Errors vector: [%d X %d]\n', size(errors(area_index, class_index, :), 1), size(errors(area_index, class_index, :), 2));
t_step=mode(diff(time_vector));
plotted_time=(time_vector+t_step)/1000;
for area_index = 1 : 2
    for class_index = 1 : 2
        plots(count) = shadedErrorBar(plotted_time, 100*means(area_index, class_index, :), 100*errors(area_index, class_index, :), {'Color', colors(count, :),'LineWidth', 2,'Marker','.','MarkerSize',20}, 1);
        plots_to_use(count) = plots(count).mainLine; %mainLine represents actual line, from shadedErrorBar code author
        labels{count} = sprintf('%s class %d', area{area_index}, class_index);
        count = count + 1;
    end
end

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
            line([plotted_time(i)-time_semiwidth plotted_time(i)+time_semiwidth],[pvals_offset(area_index) pvals_offset(area_index)], 'Color', colors(2*area_index,:),'LineWidth', 1)
        end
    end
end
end


for_powerpoint=1;
if ~for_powerpoint
    prev_xlim=xlim;
    lg=legend(plots_to_use(1, :), labels, 'Location','SouthWest');
    set(lg,'Box','off')
    %set(graph,'Position',get(0,'ScreenSize'));
    legend('show');
    xlim(prev_xlim)
end
if plotted_time(end)>0.05
xlim([plotted_time(1) plotted_time(end)])
xlabel('Time from stimulus onset (s)','FontSize',15)
else
xlim([plotted_time(1) 0.02])
xlabel('Time from saccade onset (s)','FontSize',15)
end




set(gca,'FontSize',15)
ylim([0 100]);
set(gca,'ytick',[0 25 50 75 100])

line(xlim, [50 50], 'Color', 'k');

%indicate line of saccade or stimulus onset
line([0 0], ylim, 'Color', 'k', 'LineStyle', '--');

title_save = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in, is_special);
title_str = strrep(title_save, '_', ' ');
title_str = strrep(title_str, 'Decode ', '');
%if ~for_powerpoint
    title(sprintf('Mean decoding for %s %s', title_str,monkey));
%end

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

if is_population == 1
    save_dir = fullfile(root_dir, monkey, ref, 'population', title_save, dir_ending);
else
    save_dir = fullfile(root_dir, monkey, ref, 'single_cell', title_save, dir_ending);
end

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% fprintf('Saving in %s\n', save_dir);

saveas(graph, fullfile(save_dir, sprintf('conf_analysis_%s.png', analysis_type)));


%Save as SVG
addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
plot2svg(fullfile(save_dir, sprintf('conf_analysis_%s.svg', analysis_type)), graph);

close(graph);

end

