function [] = save_neural_data(monkey, area, cell_no, task, ref)
% Given an existing cell, this function writes a file for the matrix
% representing the neural activity of desired monkey cell at 'time' mSec
% w.r.t. the alignment
%
% Inputs:
%   monkey: name of monkey (ex. 'michel' or 'QUinCy') //not case sensitive
%   area: name of area (ex. 'lip' or 'pitd') //not case sensitive
%   cell_no: number of desired cell
%   task: name of task (ex. 'attention' or 'mgs') //not case sensitive   
%   alignment: either 'saccade' or 'stiMuluS' //not case sensitive
% Output:
%  none

start_dir = strrep(mfilename('fullpath'), mfilename(), ''); %gets directory containing this file, regardless of curr_dir when called
attn_dir = '/Freiwald/ppolosecki/lspace/plevy/helper_code/attention_code';

ref = fix_ref_case(ref);
monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
task = fix_task_case(task);

switch ref
    case 'stimulus'
        align = 1;
    case 'saccade'
        align = 2;
end

%Get information on cell
%cell_file_dir = '/Freiwald/ppolosecki/lspace/plevy/polo_code/cell_file_manager';
cell_file_dir = '/Freiwald/ppolosecki/lspace/polo_preliminary/cell_file_manager';


cell_info_file = fullfile(cell_file_dir, [area '_' monkey '.mat']);
cell_info = load(cell_info_file);
cell_str = cell_info.cell_str;

cell_results_file = fullfile(cell_file_dir, [area '_' monkey '_results.mat']);
% fprintf('Cell results: %s\n', fullfile(cell_file_dir, [area '_' monkey '_results.mat']));
cell_results = load(cell_results_file);
cell_results = cell_results.results_data;

if cell_no > size(cell_str, 2)
    warning('%s %s cell %d does not exist! (Only %d cells)\n', monkey, area, cell_no, size(cell_str, 2));
    return;
end

%Get trial data, found in tds (used in align = 1 & task = attention case)
base_dir = strcat('/Freiwald/ppolosecki/lspace/', lower(monkey)); %directory has lower case for monkey name

switch task
    case 'attention'
        %Check that there is a file to load
        if size(cell_str(cell_no).attention.mat) < 1
            warning('No file for %s %s attention cell %d. No save\n', monkey, area, cell_no);
            return;
        end
        load(fullfile(base_dir, cell_str(cell_no).dir, 'proc', cell_str(cell_no).attention.mat{end}));
    case 'MGS_file'
        error('You need to fix this code for the MGS case!!\n');
        %         load(fullfile(base_dir, cell_str(cell_no).dir, 'proc', cell_str(cell_no).MGS_file.mat{end}));
end

td = tds{1};
nocue = false;

% fprintf('About to load cell %d:\n%s\n', cell_no, fullfile(base_dir, cell_str(cell_no).dir, 'proc', ['cell_' sprintf('%03.0f', cell_no) '_single_trial_attn_PSTH.mat']));

if exist(fullfile(base_dir, cell_str(cell_no).dir, 'proc', ['cell_' sprintf('%03.0f', cell_no) '_single_trial_attn_PSTH.mat']), 'file') == 2
     data = load(fullfile(base_dir, cell_str(cell_no).dir, 'proc', ['cell_' sprintf('%03.0f', cell_no) '_single_trial_attn_PSTH.mat']));
else
    error('%s %s cell %d of monkey %s does not exist\n', area, task, cell_no, monkey);
end 

grand_psth = data.grand_psth;

grand_matrix = grand_psth.matrix{align};
raster_data = grand_matrix; %Must be called raster_data for NDT


cd(attn_dir);

ifname = fullfile(base_dir, cell_str(cell_no).dir, 'proc', cell_str(cell_no).attention.hdf{end});
fid = dhfun('open',ifname);
tmap = dh_get_trialmap_struct(fid);

[surf_str] = trial_info(tmap, tds);

if isempty(cell_str(cell_no).RF.hdf) || isempty(cell_results(cell_no).RF_pos)
    RF_pos.rho=8;
    RF_pos.phi=180; %assume couterlateral RF;
    warning('RF data is missing!!');
else
    RF_pos = cell_results(cell_no).RF_pos(1, 1); %Has rho, phi
end

surf_x = mode([surf_str.rho])'.*cos(unique([surf_str.phi])'*pi/180); %Euclidian position of surfaces
surf_y = mode([surf_str.rho])'.*sin(unique([surf_str.phi])'*pi/180);
surf_pos = [surf_x surf_y]; 
RF_pos_vect = [RF_pos.rho*cos(RF_pos.phi*pi/180) RF_pos.rho*sin(RF_pos.phi*pi/180)]; %Euclidian position of RF center
temp = surf_pos - repmat(RF_pos_vect,size(surf_pos,1),1);
surf_RF_dist = sqrt(diag(temp*temp',0));
[~, min_index] = min(surf_RF_dist); 

closest_surf_phi = unique([surf_str.phi]);
closest_surf_phi = closest_surf_phi(min_index);

%Make phi be {0, 90, 180, 270} (i.e. not {...} + 45}
if mod(closest_surf_phi, 90) == 45
    for i = 1 : size(surf_str, 2)
        surf_str(1, i).phi = surf_str(1, i).phi - 45;
        surf_str(1, i).brt = surf_str(1, i).brt - 45;
    end
    closest_surf_phi = closest_surf_phi - 45; %To make rel_phi still valid
end

%Converting to cell for consistency with toolbox (NDT)
%Must be called raster_labels for NDT

%NDT requires the labels as strings, so we do the following
raster_labels.rel_phi = num2cell(mod([surf_str(1, :).phi] - closest_surf_phi, 360));
raster_labels.abs_phi = num2cell([surf_str(1, :).phi]);

raster_labels.rel_brt = num2cell(mod([surf_str(1, :).brt] - closest_surf_phi, 360));
raster_labels.abs_brt = num2cell([surf_str(1, :).brt]);

rel_phi = cell2mat(raster_labels.rel_phi);
abs_phi = cell2mat(raster_labels.abs_phi);

rel_brt = cell2mat(raster_labels.rel_brt);
abs_brt = cell2mat(raster_labels.abs_brt);

for i = 1 : size(raster_labels.rel_phi, 2) %rel_phi and abs_phi are same size
    raster_labels.rel_phi{1, i} = num2str(rel_phi(1, i));
    raster_labels.abs_phi{1, i} = num2str(abs_phi(1, i));
    
    raster_labels.rel_brt{1, i} = num2str(rel_brt(1, i));
    raster_labels.abs_brt{1, i} = num2str(abs_brt(1, i));
    
    raster_labels.rel_phi_brt{1, i} = [num2str(rel_phi(1, i)) '_' num2str(rel_brt(1, i))];
    raster_labels.abs_phi_brt{1, i} = [num2str(abs_phi(1, i)) '_' num2str(abs_brt(1, i))];
end

raster_site_info.RF_pos = RF_pos;
raster_site_info.align = ref;

raster_site_info.start_trig_stim = grand_psth.start_trig(1).offset;
raster_site_info.end_trig_stim = grand_psth.end_trig(1).offset;

raster_site_info.start_trig_sacc = grand_psth.start_trig(2).offset;
raster_site_info.end_trig_sacc = grand_psth.end_trig(2).offset;

raster_site_info.trials_used_stim = grand_psth.trials_used{1, 1};
raster_site_info.trials_used_sacc = grand_psth.trials_used{1, 2};

%%Navigate to correct directory
cd('/Freiwald/ppolosecki/lspace/plevy/data');

if ~exist(fullfile(monkey), 'dir')
    mkdir(fullfile(monkey));
end

cd(fullfile(monkey));

if strcmpi(task, 'attention') == 1
    
	if ~exist(fullfile('attn'), 'dir')
    	mkdir(fullfile('attn'));
    end
        
    cd(fullfile('attn'));

elseif strcmpi(task, 'MGS_file') == 1
    
     if ~exist(fullfile('mgs'), 'dir')
        mkdir(fullfile('mgs'));
     end
        
     cd(fullfile('mgs'));
end

desired_dir = fullfile([area '_' sprintf('cell_%03.0f', cell_no)]);

if ~exist(fullfile(desired_dir), 'dir')
    mkdir(fullfile(desired_dir));
end

cd(desired_dir);

save([ref '_full'], 'raster_data', 'raster_labels', 'raster_site_info');

cd(start_dir);