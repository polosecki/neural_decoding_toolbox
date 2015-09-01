function [results]=make_GLM_fun(cell_no,monkey,area,operation_mode)

%Inputs: cell_no: cell number in data base
%         monkey: monkey name
%         area: brain area
%         operation_mode: 'time_course' for full time analysis with plot
%                         'fixed_points' for just fixed set of time points (for histogram of population)

%cell_no=28;%PITd; %28;% LIP;

base_dir='/Freiwald/ppolosecki/lspace/';
if strcmp(monkey,'Michel') & strcmp(area,'LIP')
    base_dir='/Freiwald/ppolosecki/lspace/sara';
end
cell_file_dir='/Freiwald/ppolosecki/lspace/polo_preliminary/cell_file_manager';
%monkey='Quincy';
%area='LIP';%'IP';
cell_file=fullfile(cell_file_dir,[area '_' monkey '.mat']);
results_file=fullfile(cell_file_dir,[area '_' monkey '_results.mat']);

fixed_time_bins={[0.3 1.3 -0.8]; %stim-onset; mid-trial; pre-stim
                 [-0.3 -1]}; % 

%% Load basic files

load(cell_file);
load(results_file)
load(fullfile(base_dir,lower(monkey),cell_str(cell_no).dir,'proc',cell_str(cell_no).attention.mat{end}));
ifname=fullfile(base_dir,lower(monkey),cell_str(cell_no).dir,'proc',cell_str(cell_no).attention.hdf{end});

fid = dhfun('open',ifname);
tmap = dh_get_trialmap_struct(fid);
dhfun('close',fid);

[surf_str] = trial_info(tmap,tds);
surf_str_extra = heiko_log_surf_params(tds{1},false); % used to be called p in michael code

%---
%Sanity checks:
if any(strcmp({surf_str.out},'Success')'~=(tmap.oc==7))
    error('Tmap and surface info are not consistent')
end
test1=surf_str_extra.cuedsurfnames;
test2=[surf_str.name];
if ~all(strcmp(test1,test2))
    error('The surf_str surface info structures are not consistent')
end
%-----

if ~exist(fullfile(base_dir,lower(monkey),cell_str(cell_no).dir,'proc',['cell_' sprintf('%03.0f',cell_no) '_single_trial_attn_PSTH.mat']),'file');
    error('Run the first atention analysis code to create the PSTHs')
else
    load(fullfile(base_dir,lower(monkey),cell_str(cell_no).dir,'proc',['cell_' sprintf('%03.0f',cell_no) '_single_trial_attn_PSTH.mat']));
end


%% Run GLM and Tests:
%Commands of possible relevance:
%
%mvregress: multivariate general linear model
%manova1:multavariate analysis of variance
%fast_glmfit: fit glm model (FSFAST)
%fast_fratio: evaluate contrasts
%anovan: N-way anova


for mat_used=1:2
    
    tres = 1e9/30000; % Specified in nanoseconds, reciprocal of sample rate
    
    % Define time:
    t = 0:tres*grand_psth.psthdec/1e9:(size(grand_psth.matrix{mat_used},2)-1)*tres*grand_psth.psthdec/1e9;
    if mat_used==1
        %Center on surface onset(stmulus onset+pause_duration):
        t_zero=-grand_psth.start_trig(mat_used).offset+unique(surf_str_extra.pausedur(grand_psth.trials_used{mat_used}));
    elseif mat_used==2
        %Center on saccade onset:
        t_zero=t(end)-grand_psth.end_trig(mat_used).offset;
    end;
    t=t-t_zero;
    
    %trial_count=sum(~isnan(grand_psth.matrix{mat_used}),1);
    %times_used=trial_count>15;
    RF_surf=nan(length(results_data),1);
    RF_surf(~cellfun(@isempty,{results_data.closest_surf_phi}))=[results_data.closest_surf_phi]';
    
    switch operation_mode
        case 'time_course'
            tbins_center=t(3:3:end); %50ms bins
            tbins_semi_width=0.15; % i.e., width=2*semi_width
        case 'fixed_points'
            tbins_center=fixed_time_bins{mat_used};
            tbins_semi_width=0.25; %500 ms width
        otherwise
            error('Set a valid Operation Mode')
            
    end
    y=nan(size(grand_psth.matrix{mat_used},1),length(tbins_center));
    for i=1:length(tbins_center)
        y(:,i)=nanmean(grand_psth.matrix{mat_used}(:,abs(t-tbins_center(i))<=tbins_semi_width),2);
    end
    
    [temp]= make_GLM_and_contrasts_from_inst_firing(y,RF_surf(cell_no),surf_str);
    results{mat_used}=temp; clear temp;
    results{mat_used}.time=tbins_center;
    results{mat_used}.y=y;
end
%% Make plots
switch operation_mode
    case 'time_course'
        contrasts_plotted={logical([1 1 0 0 0 0 1 0 0]);
                           logical([0 0 0 0 1 0 1 1 0])};
        plot_GLM_contrasts(results,contrasts_plotted);
end


