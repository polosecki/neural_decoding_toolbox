function [] = mean_decoding_all_together(labels_to_use, is_restricted, is_restricted_by_top, top_k_cells, is_population, monkey, is_special,p_val_params)
%Calculates mean decoding for all decoded conditions

%ASSUMPTIONS:
%   Analyzing a time 'window' (rather than one slice of time)
%   Only care about the binary classifications (label has phi_brt)
%   Only care about relative coordinates (so label is rel_phi_brt)

save_file=true;
align = 'onset';
time_type = 'window';

color_source=distinguishable_colors(5);
colors_used=[(color_source(3,:)+[1 1 1])/2;
    color_source(3,:)*.65;
    (color_source(5,:)+[1 1 1])/2;
    color_source(5,:)*.75];

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
    
    for ref_index = 2 : 2
        
        if strcmpi(refs{ref_index}, 'stimulus')
            time_vector = [-500 : 100 : 1400];
            time_start = -500;
            time_window = 2000;
        else
            time_vector = [-800 : 100 : -100];
            time_start = -800;
            time_window = 800;
        end
        graph = figure();
        hold on;
        for decode_index = 1 : 2
            
            decode_on = decode{decode_index};
            
            
            for train_in = 0 : 1;
                
                %for test_in = 0 : 1
                test_in = train_in;
                
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
                if p_val_params.use_p_vals
                    [p_vals]=get_decoding_pvals(monkey, area{area_index}, refs{ref_index}, align, arbitrary_cell, time_start, time_window, time_type, labels_to_use, ...
                        decode_on, train_in, test_in, is_restricted, is_restricted_by_top, top_k_cells, is_population, is_special,p_val_params.null_resamples,p_val_params.null_CVs);
                    p_values=p_vals;
                else
                    p_values=[];
                end
                %colors = hsv(count); %get unique colors
                
                %% 1. Graph
                
                t_step=mode(diff(time_vector));
                plotted_time=(time_vector+t_step)/1000; %centered on cente rof time slice
                for i = 1 : size(means, 2)
                    m=100*means(:, i);
                    c_used=(2*decode_index)-1+train_in;
                    %                     plots(i) = shadedErrorBar(time_vector, means(:, i), errors(:, i), {'Color', colors(i, :)}, 1);
                    %                     plots_to_use(i) = plots(i).mainLine; %mainLine represents actual line, from shadedErrorBar code author
                    plots_to_use{c_used}=plot(plotted_time, m,'color',colors_used(c_used,:),'LineWidth', 2,'MarkerSize',20); % ,'Marker','.'
                    labels{i} = 'mean decoding';
                    face_color={[1 1 1],colors_used(c_used,:)};
                    if p_val_params.use_p_vals && ~isempty(p_values)
                        mult_compare_method=p_val_params.mult_compare_method;
                        p_threshold=p_val_params.p_threshold;%.01;
                        switch mult_compare_method
                            case 'none'
                                h=p_values<p_threshold;
                            case 'bonferroni'
                                h=p_values<(p_threshold/(length(p_values)));
                            case 'fdr'
                                tested_pvals=horzcat(p_values);
                                [h_tested, crit_p]=fdr_bky(abs(tested_pvals),p_threshold);% Benjamini & Hochberg/Yekutieli method
                                %[h_tested, crit_p, ~]=fdr_bh(abs(tested_pvals),p_threshold);
                                h=h_tested((1:length(tested_pvals)/2)+(area_index-1)*length(tested_pvals)/2);
                            case 'holm-bonferroni'
                                tested_pvals=horzcat(p_values{:});
                                adjustedPVals = frmrHolmBonferoni(tested_pvals);
                                h_tested=adjustedPVals<p_threshold;
                                h=h_tested((1:length(tested_pvals)/2)+(area_index-1)*length(tested_pvals)/2);
                        end
                    else
                        h=false(size(m));
                    end
                    for j=1:length(m)
                        plot(plotted_time(j),m(j),'Marker','o','color',colors_used(c_used,:),'MarkerFaceColor',face_color{h(j)+1},'MarkerSize',15);
                    end
                end
                
                
                
            end
            
            
        end
        ylim([0 100]);
        
        if plotted_time(end)>0.05
            xlim([plotted_time(1) plotted_time(end)])
            xlabel('Time from stimulus onset (s)','FontSize',15)
        else
            xlim([plotted_time(1) 0.02])
            xlabel('Time from saccade onset (s)','FontSize',15)
            
        end
        %indicate line of saccade or stimulus onset
        line([0 0], ylim, 'Color', 'k', 'LineStyle', '--');
        
        line(xlim, [50 50], 'Color', 'k');
        ylabel('Decoding accuracy (%)','FontSize',15)
        
        set(gca,'FontSize',15)
        ylim([0 100]);
        set(gca,'ytick',[0 25 50 75 100])
        
        
        title_str = area{area_index};
        
        title(sprintf('Mean decoding for %s', title_str));
        %legend(plots_to_use(1, :), labels, 'Location', 'SouthWest');
        %legend('show');
        drawnow
        pause(2)
%         disp('Press a key')
%         waitforbuttonpress
        if is_restricted == 1
            if is_restricted_by_top == 1
                dir_ending = sprintf('restrict_top_%d', top_k_cells);
            else
                dir_ending = sprintf('restricted_equal');
            end
        else
            dir_ending = sprintf('unrestricted');
        end
        %                title_save = get_file_name_conditions(labels_to_use, decode_on, train_in, test_in, is_special);
        
        title_save='for_paper_collapsed';
        save_dir = fullfile(root_save, monkey, refs{ref_index}, title_save, dir_ending);
        
        if ~exist(save_dir, 'dir')
            mkdir(save_dir);
        end
        if save_file
            v=version('-release');
            if str2num(v(1:end-1))>=2015
                saveas(graph, fullfile(save_dir, sprintf('%s_mean_decoding.svg', area{area_index})));
            else
                %Save as SVG
                addpath('/Freiwald/ppolosecki/lspace/polo_preliminary/attention_analysis/plot2svg');
                plot2svg(fullfile(save_dir, sprintf('%s_mean_decoding.svg', area{area_index})), graph);
            end
        end
        close(graph);
    end
end