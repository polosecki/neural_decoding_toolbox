cell_start = 1;
cell_end = 55;

monkey = 'quincy'; 
% monkey = 'michel'

[lip, pitd] = deal(1, 1);
[stim, sacc] = deal(1, 1);

quincy_bad_pitd = [8 19 22 23 32 33 42 43 44 45 46 52];
quincy_bad_lip = [2 12 13 14 17 26];

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
    