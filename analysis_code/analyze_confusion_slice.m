function frac_values = analyze_confusion_slice(conf_mat, index, analysis_type, classes)
%Given analysis type of [classes x classes] matrix where 
%   row represents stimulus guessed and 
%   column represents stimulus presented
%analysis_type = 'presented' or 'guessed'
%tells whether the index represents a row or column

frac_values = zeros(1, classes);

if strcmpi(analysis_type, 'presented')
    total_trials = sum(conf_mat(:, index), 1);
    for i = 1 : classes
        frac_values(i) = conf_mat(i, index)/total_trials;
    end
elseif strcmpi(analysis_type, 'guessed')
    total_trials = sum(conf_mat(index, :), 2);
    for i = 1 : classes
        frac_values(i) = conf_mat(index, i)/total_trials;
    end    
else
    error('Choose "presented" or "guessed" for analysis_type (third) parameter\n');
end

% fprintf('***\n');
% conf_mat
% fprintf('\nyields:\n');
% fprintf('Class 1: %d ... Class 2: %d\n***\n', frac_values(1), frac_values(2));

end
