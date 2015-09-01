function [RF_pos] = RF_map_analysis_fun(RF_args)


proc_dir=RF_args.proc_dir;
mat_logfile=RF_args.mat_logfile;
hdf_file=RF_args.hdf_file;
fig_dir=RF_args.fig_dir;
% %% USER EDITABLE BLOCK
% 
% proc_dir='/Freiwald/ppolosecki/lspace/quincy/130417Quincy/proc/';
% mat_logfile='Quincy_130417_0017.mat';
% hdf_file='130417_quincy_004_r.dh5';
% proc_dir='/Freiwald/ppolosecki/lspace/michel/130419Michel/proc/';
% mat_logfile='Michel_130419_0018.mat';
% hdf_file='130419_michel_010_r.dh5';
%mat_logfile='Michel_121129_0016.mat';
%hdf_file='121129_michel_005_r.dh5'; %File with a fix spot offset at 5deg,
%0 deg phi

%mat_logfile='Michel_121107_0039.mat'; %beautiful LIP receptive field
%hdf_file='121107_michel_009_r.dh5';

%mat_logfile='Michel_121107_0024.mat'; %nice LIP cell RF
%hdf_file='121107_michel_004_r.dh5';


cluster_used=RF_args.cluster;% Select the unit you want, unless you select use_mode_unit
use_mode_unit=false;
xx=0;%25;
pre_stim_time=-50-xx; %in ms (negative time is after stim)
post_stim_time=150+xx; %in ms

%400 450
spike_mode='count_spikes';%'psth';%'psth';%'count_spikes';%'count_spikes';%%'psth';%'count_spikes';%'count_spikes';%'count_spikes';%'psth';


% END OF USER EDITABLE BLOCK

load(fullfile(proc_dir,mat_logfile));
%Let's assume one electrode only:
tds=tds{1};tds.vskname
%% Get information about pictures presented:

object_used=find(~cellfun(@isempty,tds.pictures));
if length(object_used)>1; 
    error('It seems you used more than one object in your vsk file. Im dizzy'); 
end

pics=tds.pictures{object_used};
pic_pos=cell2mat([tds.pictures{object_used}.jump]'); % [X Y] position of the pictures in pixels.

%zz below seems to contain info for each image, however there are 2 columns
%of info for each image, how do I know which one applies to them?
%zz={tds.doc_data{2}.OBJECTPARAMS_BCONT};
object_params=[tds.doc_data{object_used}.OBJECTPARAMS_BCONT];
object_name='..\..\Stimuli\BMPs\dot_mapping.txt';
object_params=object_params(strcmp([object_params.imagelistName],object_name));

rho_used=unique(cellfun(@str2num,[object_params.stimPosRho])); 
phi_used=unique(cellfun(@str2num,[object_params.stimPosPhi])); 
if length(rho_used)*length(phi_used)~=1;
    error('Stimulus has moved during recording, or something like that')
end

center_deg_stim=[rho_used*cos(phi_used) rho_used*sin(phi_used)];
%Fix spot position is in tds.doc_data{2}.FIXSPOTPARAMS_MARIA
pics_start_time=[pics.start]'; %Picture start times, in ms
good_pics=(([pics.end]-[pics.start])==mode([pics.end]-[pics.start]))'; %vector that tells you what pics you were presented for a good ammount of time;
%plot(pic_pos(good_pics,1),pic_pos(good_pics,2), '.')

%% Get information about behavior (fixation periods) anf filter out unfixated pics:
fix_in_indexes=strcmp(tds.trignames,'Fixation_in')';
fix_out_indexes=strcmp(tds.trignames,'Fixation_out')';
times_fix_in=tds.trigtimes(fix_in_indexes)'; %Fixation times in ms
times_fix_out=tds.trigtimes(fix_out_indexes)';
times_fix_in=times_fix_in(1:length(times_fix_out)); % For simplicity, I will trash out things happennign after last fix out;


%Remove pictures not fixated from good_pix
for i=1:length(pics_start_time)
    %[relevant_fix_time]=max(times_fix_in(times_fix_in<pics_start_time(i)));
    a=find(-diff(times_fix_in<pics_start_time(i)));
    if ~((pics_start_time(i)>times_fix_in(a)+50) & (pics_start_time(i)<times_fix_out(a)-300))
        good_pics(i)=0;
    end
end
plot(pic_pos(good_pics,1),pic_pos(good_pics,2), '.');

good_pics=(good_pics & ~[tds.pictures{2}.frameslost]'); %Remove pictures with lost frames from analysis

positions_used=unique(pic_pos(good_pics,:),'rows');



%% Get spike time stamps:
fid = dhfun('open',fullfile(proc_dir,hdf_file));

%Times in the hdf file are in NANOSECONDS
%[TIMES] = dhfun('getmarker',fid,'Fixation_out'); % Gives you the time of
%fix out in the hdf files

spike_channel=1;
total_spikes=dhfun('getnumberspikes',fid,spike_channel);
spike_times=dhfun('readspikeindex', fid, spike_channel, 1, total_spikes);
spike_clusters=dhfun('readspikecluster', fid, spike_channel, 1, total_spikes);
spike_times=spike_times'; spike_clusters=spike_clusters';

%Choose spikes from the desired cluster:
%cluster_used=mode(spike_clusters);
if cluster_used>0
    spikes_used= (spike_clusters==cluster_used);
else
    spikes_used=logical(ones(size(spike_clusters))); %Use negative number to work with all spikes
end

%% Calculate psth for each position

%Define PSTH parameters:
tres = double(dhfun('getspikesampleperiod',fid,spike_channel)); %1e9/30000; % Specified in nanoseconds, reciprocal of sample rate

psthfilter.type = 'Gauss';
psthfilter.fs        = round(1e9/tres); %Sampling frequency (Hz)
psthfilter.sigma_ms  = 20; %Specified in milliseconds
psthfilter.length_ms = 80;   %Specified in milliseconds, truncation length, usually 4x more than sigma
psthdec=100;
% Design the filter
psthfilter = design_psth_filter(psthfilter);

firing_rate=zeros(length(positions_used),1);
for i=1:length(positions_used)
    presentation_indexes=find((pic_pos(:,1)==positions_used(i,1)) & (pic_pos(:,2)==positions_used(i,2)) & good_pics);
    if isempty(presentation_indexes)
        error('you are trying to calculate firing rate for a position that was not succesfully presented');
    end
    ts=(pics_start_time(presentation_indexes)-pre_stim_time)*10^6; %time start of the psth
    te=(pics_start_time(presentation_indexes)+post_stim_time)*10^6;  %end time of psth, nanos
    test(i)=isempty(ts);
    switch spike_mode
        case 'psth'
            psth = calc_psth(spike_times(spikes_used),ts,te,pics_start_time(presentation_indexes)*10^6,tres,psthfilter.Num,1,psthfilter.delay,psthdec);
            %[psth] = calc_psth(tstamps,ts,te,ta,tres,Num,Den,fdelay,dec);
            z(i)=psth;
            firing_rate(i)=mean(psth.data);
        case 'count_spikes'
            nspikes=get_evoked_spikes(spike_times(spikes_used),ts,te);
            firing_rate(i)=(mean(nspikes)/mean(te-ts))*10^9;
    end
end
unique(test)

%% Rescale postion of stimuli so that they are in degrees and centered correctly too

%convert positions_used to degrees:
%calculate screen diagonal length in pixels for pixel/degree conversion
screenD_pix = sqrt((tds.display_mode.width)^2 + (tds.display_mode.height)^2);
screenD_cm = tds.monitor.diagonal_size;
screen_eye_distance = tds.monitor.distance; %57cm is default
diagonal_angular_amplitude=(180/pi)*atan(screenD_cm/screen_eye_distance);
pix2deg_coef = diagonal_angular_amplitude / screenD_pix;

positions_used=pix2deg_coef*positions_used+repmat(center_deg_stim,size(positions_used,1),1);
plot(positions_used(:,1),positions_used(:,2),'.')

%% Interpolate and plot RF
%xi = linspace(min(positions_used(1,:)),max(positions_used(1,:)),20);
%yi = linspace(min(positions_used(2,:)),max(positions_used(2,:)),20);
gridsize =mean(diff((unique(positions_used(:,1)))));
figure
int_factor=2.2857;
smooth_map.MAKE=1; % set to 1 to apply smoothing
smooth_map.fhwm_ker=2; % full width at half maximum for kernel;
smooth_map.ker_halfsize=3; % half-width of the kernel matrix;


[xi,yi,zi]=display_map(positions_used(:,1),positions_used(:,2),firing_rate,0,200,int_factor*gridsize,'pcolor',1,smooth_map);
[rho,phi]=calculate_RF_center(xi,yi,zi); % position of center of mass, thesholded at mean value
hold on
plot(rho*cos(phi*pi/180),rho*sin(phi*pi/180),'kO')
RF_pos.rho=rho;
RF_pos.phi=phi;

%xtick_vector=linspace(1,size(zi,2),10);
%xt_label_vector=linspace(min(xi(:)),max(xi(:)),7);
%ytick_vector=linspace(1,size(zi,1),10);
%yt_label_vector=linspace(min(yi(:)),max(yi(:)),10);
%set(gca,'xtick',xt_label_vector); %note axes x and y are flipped here, this seems to beha ve normally
%set(gca,'xtickLabel',xt_label_vector);
%set(gca,'ytick',ytick_vector); %note axes x and y are flipped here, this seems to beha ve normally
%set(gca,'ytickLabel',yt_label_vector);

%display_map(x,y, zp, applylog, resi, sgaus, plotmode, multip)
%hold on
%colormap('gray')
if ~isempty(fig_dir)
addpath(fullfile('.','plot2svg'))
        filename=['cell_' sprintf('%03.0f',RF_args.cell_no) '_RF'];
        %saveas(f,fullfile(figure_dir,[filename '.eps']));
        plot2svg(fullfile(fig_dir,[filename '.svg']),gcf);
        saveas(gcf,fullfile(fig_dir,[filename '.fig']));
        saveas(gcf,fullfile(fig_dir,[filename '.eps']));
end
