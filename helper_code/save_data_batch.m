function [] = save_data_batch(monkey, lip, pitd, stim, sacc, cell_start, cell_end)
%Saves data from hd5 files
%If one argument, it is assumed that a struct has been used
%containing all the needed information

if nargin() == 1
    params = monkey; %just to make following assignments less confusing
    
    monkey = params.monkey;
    lip = params.lip;
    pitd = params.pitd;
    stim = params.stim;
    sacc = params.sacc;
    cell_start = params.cell_start;
    cell_end = params.cell_end; 
end

% quincy_bad_pitd = [8 19 22 23 32 33 42 43 44 45 46 52];
% quincy_bad_lip = [2 12 13 14 17 26];
% 
% michel_bad_pitd = [6 10 11 12 16 19 32 38 40 48];
% michel_bad_lip = [1 2 4 5 21 31 32 33];

quincy_bad_pitd = bad_files('Quincy','PITd');
quincy_bad_lip = bad_files('Quincy','LIP');

michel_bad_pitd = bad_files('Michel','PITd');
michel_bad_lip = bad_files('Michel','LIP');

output = 1; %or 0 for no printing

good_cell = 1;

for i = cell_start : cell_end
    if lip == 1
        if strcmpi(monkey, 'quincy')
            if ~isempty(intersect(quincy_bad_lip, i))
                warning('%s LIP cell %d is bad. Skipping the save\n', monkey, i);
                good_cell = 0;
            else
                good_cell = 1;
            end
        end
        
        if strcmpi(monkey, 'michel')
            if ~isempty(intersect(michel_bad_lip, i))
                warning('%s LIP cell %d is bad. Skipping the save\n', monkey, i);
                good_cell = 0;
            else
                good_cell = 1;
            end
        end
        
        if stim == 1 && good_cell == 1
            save_neural_data(monkey, 'lip', i, 'attention', 'stimulus');
            if output == 1
                fprintf('Saved %s LIP stimulus-aligned cell %d\n', monkey, i);
            end
        end
        
        if sacc == 1 && good_cell == 1
            save_neural_data(monkey, 'lip', i, 'attention', 'saccade');
            if output == 1
                fprintf('Saved %s LIP saccade-aligned cell %d\n', monkey, i);
            end
        end
    end
        
    if pitd == 1
        if strcmpi(monkey, 'quincy')
            if ~isempty(intersect(quincy_bad_pitd, i))
                warning('%s PITd cell %d is bad. Skipping the save\n', monkey, i);
                good_cell = 0;
            else
                good_cell = 1;
            end
        end
        
        if strcmpi(monkey, 'michel')
            if ~isempty(intersect(michel_bad_pitd, i))
               warning('%s PITd cell %d is bad. Skipping the save\n', monkey, i);
               good_cell = 0;
            else
                good_cell = 1;
            end
        end
               
        if stim == 1 && good_cell == 1
            save_neural_data(monkey, 'pitd', i, 'attention', 'stimulus');
            if output == 1
                fprintf('Saved %s PITd stimulus-aligned cell %d\n', monkey, i);
            end
        end
        if sacc == 1 && good_cell == 1
            save_neural_data(monkey, 'pitd', i, 'attention', 'saccade');
            if output == 1
                fprintf('Saved %s PITd saccade-aligned cell %d\n', monkey, i);
            end
        end
    end
end
    