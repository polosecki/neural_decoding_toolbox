%Makes structure for each cell saying:

%unit number, files for each task

%%Figures the cell index - DO NOT EDIT
clear all; clc; close all
monkey='Michel';
area='PITd';
mat_file=[area '_' monkey '.mat'];
if exist(mat_file,'file')
    load(mat_file);
    i=length(cell_str)+1;
else
    i=1;
end
%% USER EDITABLE BLOCK
cell_str(i).unit=3;
cell_str(i).dir='140522Michel';
cell_str(i).MGS_file.hdf={'140522_michel_004_r.dh5'};
cell_str(i).RF.hdf={'140522_michel_005_r.dh5'};
cell_str(i).attention.hdf={'140522_michel_006_r.dh5'};
cell_str(i).rmp_task.hdf={};
cell_str(i).rmp_visual_control.hdf={};


basedir='/Freiwald/ppolosecki/lspace/michel';

cell_str(i).monkey=monkey;
cell_str(i).area=area;
file_types={'RF','MGS_file','rmp_task','rmp_visual_control','attention'};

%% Find the matlab file associatted with each hdf file
for j=1:length(file_types)
    if isfield(cell_str(i),file_types{j})
        hdf_files=eval(['cell_str(i).' file_types{j} '.hdf']);
        mat_files={};
        for k=1:length(hdf_files)
            LineNo = findstringline(fullfile(basedir,cell_str(i).dir,'proc','filelist_match_hdf.txt'),hdf_files{k});
            mat_text = textread(fullfile(basedir,cell_str(i).dir,'proc','filelist_match_mat.txt'),'%s','delimiter','\n');
            [pathstr, name, ext] = fileparts(mat_text{LineNo});
            mat_files{k}=[name ext];
        end
        eval(['cell_str(i).' file_types{j} '.mat=mat_files;']);
    end
end
%% SAVE THE RESULT

if i>1 && isequal(cell_str(i),cell_str(i-1))
    error('You are adding the same cell twice!!!');
end

if exist(mat_file,'file')
movefile(mat_file, [area '_' monkey '_' datestr(now,'yymmdd_HHMMSS') '.mat']);
end
save(mat_file,'cell_str');