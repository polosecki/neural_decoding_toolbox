function [grand_psth_matrix, trials_used] = make_grand_psth_matrix(grand_psth_indredients)
%Makes a matrix with individual trial PSTHs:
% Required fields are:
% fid
% tmap
% start_trig
% end_trig
% surf_str
%align %=1 for stim onset or 2 for saccade onset
%spks
%tres
%psthfilter

fid=grand_psth_indredients.fid;
tmap=grand_psth_indredients.tmap;
start_trig=grand_psth_indredients.start_trig;
end_trig=grand_psth_indredients.end_trig;
surf_str=grand_psth_indredients.surf_str;
spks=grand_psth_indredients.spks;
tres=grand_psth_indredients.tres;
psthfilter=grand_psth_indredients.psthfilter;
psthdec=grand_psth_indredients.psthdec;
align=grand_psth_indredients.align;

%Get time start and end (in nanoseconds) for each trial:
[time_start,time_end,inclidx] = find_ref_points_test(fid,tmap,start_trig,end_trig,surf_str);
%[time_start,time_end,inclidx] = find_ref_points(fid,tmap,start_trig,end_trig);

%Prevent future errors!
if find(time_start<0)
    disp('Hey, your time_start is less than zero!')
end

trials_with_good_markers=zeros(length(surf_str),1);
trials_with_good_markers(inclidx)=1;
ts_vect=nan(length(trials_with_good_markers),1);
te_vect=nan(length(trials_with_good_markers),1);
ts_vect(logical(trials_with_good_markers))=time_start;
te_vect(logical(trials_with_good_markers))=time_end;
durations=te_vect-ts_vect;
trials_used = strcmp({surf_str.out},'Success')' & strcmp({surf_str.type},'Normal')' & trials_with_good_markers;
%keyboard
%Use max(durations) to predefine the size of the nan matrix where psth will
%occur.
[~,trialID]=max(durations.*trials_used); %the max durations of the trials used

longest_psth = calc_psth(spks,ts_vect(trialID),te_vect(trialID),ts_vect(trialID),tres,psthfilter.Num,1,psthfilter.delay,psthdec);

grand_psth_matrix=nan(length(trials_used),length(longest_psth.data));

for trialID=1:length(trials_used)
    if trials_used(trialID)
        psth=calc_psth(spks,ts_vect(trialID),te_vect(trialID),ts_vect(trialID),tres,psthfilter.Num,1,psthfilter.delay,psthdec);
        if align==1
            grand_psth_matrix(trialID,1:length(psth.data))=psth.data;
        elseif align==2
            grand_psth_matrix(trialID,end-(length(psth.data)-1):end)=psth.data;
        else
            error('Alignment mode not supported')
        end
    end
end

