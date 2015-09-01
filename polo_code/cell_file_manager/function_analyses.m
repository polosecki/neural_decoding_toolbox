clear all; close all;

cell_file_dir='/Freiwald/ppolosecki/lspace/plevy/polo_code/cell_file_manager';
monkey='Quincy';
area='PITd';
cell_file=fullfile(cell_file_dir,[area '_' monkey '.mat']);

fig_dir='/Freiwald/ppolosecki/lspace/plevy/figures';
base_dir='/Freiwald/ppolosecki/lspace/quincy'; %'/Freiwald/ppolosecki/lspace/sara/Michel';%'/Freiwald/ppolosecki/lspace/quincy';
close_figures=1;

write_results_data=1;
results_file=fullfile(cell_file_dir,[area '_' monkey '_results.mat']);
load_results_data=1;
i=29;

wd=pwd;
load(cell_file);
if load_results_data
    load(results_file)
end
%for i=52:length(cell_str)
     %% Make RF analysis:
    if ~isempty(cell_str(i).RF.hdf)
        RF_args.proc_dir=fullfile(base_dir,cell_str(i).dir,'proc');
        RF_args.mat_logfile=cell_str(i).RF.mat{end};
        RF_args.hdf_file=cell_str(i).RF.hdf{end};
        RF_args.cluster=cell_str(i).unit;
        RF_args.fig_dir=fig_dir;
        RF_args.cell_no=i;   
        
        cd('/Freiwald/ppolosecki/lspace/plevy/polo_code/RF_analysis');
        [RF_pos]=RF_map_analysis_fun(RF_args);
        if write_results_data
            results_data(i).RF_pos=RF_pos;
        end
        cd(wd);
    end
    %% Make attention analysis:
    if ~isempty(cell_str(i).attention.hdf)
        cd('/Freiwald/ppolosecki/lspace/plevy/polo_code/attention_analysis/');
        
        overwrite_grand_psth = 0; %Set to 1 if you want to save attention analysis
        
        if (~write_results_data & ~load_results_data) | isempty(cell_str(i).RF.hdf)
            RF_pos=[];
        else
            RF_pos=results_data(i).RF_pos;
        end
        
        [closest_surf_phi]=attention_analysis_func_pp(cell_file,i,base_dir,overwrite_grand_psth,fig_dir,RF_pos); %Edit here to change save loc. of PSTH matrix
        if write_results_data
            results_data(i).closest_surf_phi=closest_surf_phi;
        end
        cd(wd);
    end
    
    %% Make MGS analysis:
    if ~write_results_data & ~load_results_data
        closest_surf_phi=[];
    else
        closest_surf_phi=results_data(i).closest_surf_phi;
    end
    if ~isempty(cell_str(i).MGS_file.hdf)
        cd('/Freiwald/ppolosecki/lspace/plevy/polo_code/mgs_analysis/');
        overwrite_grand_psth=0;
        mgs_analysis_func_pp(cell_file,i,base_dir,overwrite_grand_psth,fig_dir,closest_surf_phi);
        cd(wd);
    end
    
    %% Make RMP analysis:
    if false
    if ~isempty(cell_str(i).rmp_task.hdf)
        cd('/Freiwald/ppolosecki/lspace/polo_preliminary/rmp_analysis/');
        overwrite_grand_psth=1;
        rmp_analysis_func_pp(cell_file,i,base_dir,overwrite_grand_psth,fig_dir);
        cd(wd);
    end
    end
    if close_figures
        close all;
    end
    if write_results_data
        save(results_file,'results_data')
    end
%end



