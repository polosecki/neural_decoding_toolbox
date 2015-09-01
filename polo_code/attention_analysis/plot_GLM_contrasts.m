function [linehandles]=plot_GLM_contrasts(results,contrasts_plotted)
%INPUTS:
%   results: results structure as provided by make_GLM_and_contrasts_from_inst_firing
%   contrasts_plotted: 2-by-1 cell with logical vectors indicating the contrasts to be plotted from

show_legends=1;
f=figure;
set(f,'Position',get(0,'ScreenSize'));
lims_used=zeros(2);
colors_used=distinguishable_colors(sum(contrasts_plotted{1}+sum(contrasts_plotted{2})));
%colors_used=distinguishable_colors(6);
%colors_used=colors_used([1 2 6 4 3 5],:);
for mat_used=1:2
    subplot(1,2,mat_used); hold on
    if mat_used==1
        xlim([-1.5 2])
    elseif mat_used==2
        xlim([-2 0.5])
    else
        error('what mat??')
    end
    
    
    y_matrix=[results{mat_used}.GLM1.ces(contrasts_plotted{1},:);results{mat_used}.GLM2.ces(contrasts_plotted{2},:)];
    y__std_matrix=[results{mat_used}.GLM1.ces_std(contrasts_plotted{1},:);results{mat_used}.GLM2.ces_std(contrasts_plotted{2},:)];
    [temp]= shadowcaster_ver3PP(results{mat_used}.time',y_matrix', 2*y__std_matrix', [],colors_used);
    if mat_used==1
        linehandles=temp;
    end
    clear temp;
    lims_used(mat_used,:)=ylim;
end

for mat_used=1:2
    subplot(1,2,mat_used)
    ylim([min(lims_used(:,1)) max(lims_used(:,2))]);
    line(xlim,[0 0],'Color','black','LineStyle','-')
    line([0 0],ylim,'Color','black','LineStyle','--')
    xlabel ('Time from trigger event(s)')
    if mat_used==1
        ylabel('Effect Size (Hz)')
        line([-1 -1],ylim,'Color',[.3 .3 .3],'LineStyle',':');
        if show_legends
        lg=legend(linehandles,{results{1}.GLM1.contrast.name{contrasts_plotted{1}} results{1}.GLM2.contrast.name{contrasts_plotted{2}}});
        set(lg,'Location','SouthWest');
        set(lg,'Box','off')
        %         set(lg,'units','pixels');
        %         lp=get(lg,'outerposition');
        %         set(lg,'outerposition',[lp(1:2),50,lp(4)]);
        end
    end
end
