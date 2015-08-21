function [means, errors, resamples_by_time] = analyze_resample_confusion(conf_resample, class_to_analyze, class_to_get_fraction, num_classes, analysis_type, train_time)
%Given analysis type of [classes x classes] matrix where 
%   row represents stimulus guessed and 
%   column represents stimulus presented
%analysis_type = 'presented' or 'guessed'
%tells whether the index represents a row or column

if nargin() < 6 %then assume only care about train time = test time
    
end

dims = size(conf_resample);

if length(dims) == 4 %then we only saved for train time = test time
    
    time_bins = dims(3); %3rd dim is number of time bins
    
    means = zeros(1, time_bins);
    errors = zeros(1, time_bins);
    
    num_resamples = dims(4);
    
    resamples_by_time = num_resamples * ones(1, time_bins);
    
    for time = 1 : time_bins
        
        all_resamples = zeros(1, num_resamples);
        
        for resample = 1 : num_resamples
            
            slice = analyze_confusion_slice(conf_resample(:, :, time, resample), class_to_analyze, analysis_type, num_classes);

            all_resamples(resample) = slice(class_to_get_fraction);
            
            if isnan(slice(class_to_get_fraction))
                resamples_by_time(1, time) = resamples_by_time(1, time) - 1; %one fewer valid resample
                %                 error('Analysis of class %d at class %d at time %d, resample %d is NaN!', class_to_analyze, class_to_get_fraction, time, resample);
            end
            
        end
        
        means(1, time) = nanmean(all_resamples);
        errors(1, time) = nanstd(all_resamples);
        
        if isempty(means(1, time)) || isempty(errors(1, time)) %|| strcmpi(analysis_type, 'guessed')
            fprintf('%s time bin %d: (mean, error) = (%d, %d)\n', analysis_type, time, means(1, time), errors(1, time));
        end
        
    end
        
elseif length(dims) == 5
    
    time_bins = dims(4); %4rd dim is number of test time bins
    
    means = zeros(1, time_bins);
    errors = zeros(1, time_bins);
    
    num_resamples = dims(5);
    
    resamples_by_time = num_resamples * ones(1, time_bins);
    
    for time = 1 : time_bins
        
        all_resamples = zeros(1, num_resamples);
        
        for resample = 1 : num_resamples
            
            slice = analyze_confusion_slice(conf_resample(:, :, train_time, time, resample), class_to_analyze, analysis_type, num_classes);

            all_resamples(resample) = slice(class_to_get_fraction);
            
            if isnan(slice(class_to_get_fraction))
                resamples_by_time(1, time) = resamples_by_time(1, time) - 1; %one fewer valid resample
%                 error('Analysis of class %d at class %d at time %d, resample %d is NaN!', class_to_analyze, class_to_get_fraction, time, resample);
            end
            
        end
        
        means(1, time) = mean(all_resamples);
        errors(1, time) = std(all_resamples);
        
    end
        
else
    error('Confusion matrix with resamples separately has invalid number of dimensions (%d)!', length(dims));
end
    