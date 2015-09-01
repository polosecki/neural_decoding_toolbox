clear all

%PITd
%April 11 2013

cell_file_dir='/Freiwald/ppolosecki/lspace/polo_preliminary/cell_file_manager';
load(fullfile(cell_file_dir,'PITd_data.mat'));
{PITd_cell.dir};


cell_no=7;
base_dir='/Freiwald/ppolosecki/lspace/quincy';
load(fullfile(base_dir,PITd_cell(cell_no).dir,'proc',PITd_cell(cell_no).attention.mat{1}));
ifname=fullfile(base_dir,PITd_cell(cell_no).dir,'proc',PITd_cell(cell_no).attention.hdf{1});


bid = 1; % Channel number (1 for Blackrock recordings in Freiwald lab)
tres = 1e9/30000; % Specified in nanoseconds, reciprocal of sample rate
clussel =PITd_cell(cell_no).unit; % Cluster number(s)
make_grand_psth=1;




psthfilter.type = 'Gauss';
psthfilter.fs        = round(1e9/tres); %Sampling frequency (Hz)
psthfilter.sigma_ms  = 25; %Specified in milliseconds
psthfilter.length_ms = 100;   %Specified in milliseconds, truncation length, usually 4x more than sigma
psthdec = 100;

% ------------ END OF USER-EDITABLE BLOCK -----------------
clear dhfun
% Design the filter
psthfilter = design_psth_filter(psthfilter);

fid = dhfun('open',ifname);
tmap = dh_get_trialmap_struct(fid);
%%
trls = [tds{1}.trials]; %holds all the basic trial parameters
%this gets you the name, number, rho and phi for the target surface of
%every trial
%[surf_str] = surface_info_withcatch(tmap,tds);
[surf_str] = trial_info(tmap,tds);
surface_numbers = [surf_str.numb];

%This is Michael Code (partially redundant):----

td = tds{1};
nocue = false;
surf_str_extra = heiko_log_surf_params(td,nocue); % used to be called p in michael code
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




% Get time start and end (in NANOSECONDS) for each trial
[time_start,time_end,inclidx] = find_ref_points(fid,tmap,start_trig,end_trig);



nspk = double(dhfun('GETNUMBERSPIKES',fid,bid)); %the numbers of spikes (total)
 tstamps = dhfun('READSPIKEINDEX',fid,bid,1,nspk); %times that every spike occured
    
[spike_clus] = dhfun('READSPIKECLUSTER',fid,bid,1,nspk); %tells you cluster information
 spks = tstamps(spike_clus == clussel);

trials_with_good_markers=zeros(length(surf_str),1);
trials_with_good_markers(inclidx)=1; 
ts_vect=nan(length(surf_str),1);
te_vect=nan(length(surf_str),1);
ts_vect(logical(trials_with_good_markers))=time_start;
te_vect(logical(trials_with_good_markers))=time_end;
durations=te_vect-ts_vect;
trials_used = strcmp({surf_str.out},'Success')' & strcmp({surf_str.type},'Normal')' & trials_with_good_markers;

%Use max(durations) to predefine the size of the nan matrix where psth will
%occur.

[m,Idxm]=max(durations.*trials_used); %the max durations of the trials used

trialID=Idxm;


longest_psth = calc_psth(spks,ts_vect(trialID),te_vect(trialID),ts_vect(trialID),tres,psthfilter.Num,1,psthfilter.delay,psthdec); 
 
%Make alignment to desired trigger automatic!!!!!!!



%Making Single-trial PSTHs for finer analysis.
if make_grand_psth
    if ~exist(fullfile(base_dir,PITd_cell(cell_no).dir,'proc',['cell_' sprintf('%03.g',cell_no) '_single_trial_attn_PSTH.mat']),'file')
        grand_psth.to_stim_onset.data=nan(length(trials_used),length(longest_psth.data));
        grand_psth.to_saccade_onset.data=nan(length(trials_used),length(longest_psth.data));
        
        grand_psth.to_stim_onset.start_trig.type ='Marker';%;%'TrialStart'
        grand_psth.to_stim_onset.start_trig.name ='Stimulus_onset';%'Fixation_out';%'TrialStart';%'Stimulus_onset';
        grand_psth.to_stim_onset.start_trig.offset = -1.5+unique(surf_str_extra.pausedur(trials_used)); %
        grand_psth.to_stim_onset.end_trig.type ='Marker';%'TrialEnd'; 
        grand_psth.to_stim_onset.end_trig.name ='Fixation_out';%; %'Stimulus_onset';%'TrialEnd';
        grand_psth.to_stim_onset.end_trig.offset =-.5;
        
        grand_psth.to_saccade_onset.start_trig.type ='Marker';%;%';
        grand_psth.to_saccade_onset.start_trig.name ='Fixation_out';%'Fixation_out';%'TrialStart';%;%
        grand_psth.to_saccade_onset.start_trig.offset = -2; %-.05%1.0%-.25%-.05; %usually a negative value
        grand_psth.to_saccade_onset.end_trig.type ='Marker';%'TrialEnd'; %'Marker'%%
        grand_psth.to_saccade_onset.end_trig.name ='Fixation_out';%; %'Stimulus_onset';%'Fixation_out'%'Stimulus_onset'%'Fixation_out'%'TrialEnd'; %'Fixation_out'%'TrialEnd';
        grand_psth.to_saccade_onset.end_trig.offset =.5;%1.8;% 4.0%.05;%3.0
        
        
        for trialID=1:length(trials_used)
            if trials_used(trialID)
                psth=calc_psth(spks,ts_vect(trialID),te_vect(trialID),ts_vect(trialID),tres,psthfilter.Num,1,psthfilter.delay,psthdec);
                grand_psth.to_stim_onset.data(trialID,1:length(psth.data))=psth.data;

                
                [ts1,te1,crap] = find_ref_points(fid,tmap(trialID),start_trig,end_trig);
                psth=calc_psth(spks,ts1,ts2,ts1,tres,psthfilter.Num,1,psthfilter.delay,psthdec);
                grand_psth.to_saccade_onset.data(trialID,end-(length(psth.data)-1):end)=psth.data;                              
            end
        end
        grand_psth.start_trig=start_trig;
        grand_psth.end_trig=end_trig;
        grand_psth.psthfilter=psthfilter;
        grand_psth.psthdec=psthdec;
        grand_psth.cell_no=cell_no;
        save(fullfile(base_dir,PITd_cell(cell_no).dir,'proc',['cell_' sprintf('%03.g',cell_no) '_single_trial_attn_PSTH.mat']),'grand_psth')  
    else
        load(fullfile(base_dir,PITd_cell(cell_no).dir,'proc',['cell_' sprintf('%03.g',cell_no) '_single_trial_attn_PSTH.mat']),'grand_psth')  
    end
end

conditions_plotted=allcomb(unique([surf_str.phi]),unique([surf_str.brt]));

j=1;
make_sem=0;
this_plot_cond=nan(length(ts_vect),size(conditions_plotted,2));
for k=1:size(conditions_plotted,2)
this_plot_cond(:,k)= [surf_str.phi]==conditions_plotted(j,k);
end
this_plot_trials=logical(trials_used.*prod(this_plot_cond,2));
psth=calc_psth(spks,ts_vect(this_plot_trials),te_vect(this_plot_trials),ts_vect(this_plot_trials),tres,psthfilter.Num,1,psthfilter.delay,psthdec);

t = 0:tres*psthdec/1e9:(length(psth.data)-1)*tres*psthdec/1e9; %time in seconds
legendlist = ['test']
color2 = [1 0 0];

if make_sem
psth_se=dh_calc_psth_stderr(fid,bid,ts_vect(this_plot_trials),te_vect(this_plot_trials),clussel,tres,psthfilter.Num,psthfilter.Den,psthfilter.delay,psthdec);
[maxvalue minvalue]= shadowcaster_ver3(t', psth.data', 2*psth_se.stderr', legendlist,color2)
hold on
else
psth_plot(psth,tres*psthdec,[],color2,[1 0 0],[],bid,clussel,'Spikes per second');
%psth_plot(psth,tres,dopts,gcolor,contrib_color,ax,elec,clust,ylab)
end
line([(0-(start_trig.offset)) (0-start_trig.offset)], ylim, 'Color', 'k', 'LineStyle', '--')
%%TO DO: make all the plots And also, make the tuning curves. 




dhfun('close',fid);


