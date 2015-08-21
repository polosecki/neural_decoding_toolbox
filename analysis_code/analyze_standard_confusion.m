function [means, errors] = analyze_standard_confusion(conf_resample, class_to_analyze, num_classes, analysis_type, train_time)
%Given analysis type of [classes x classes] matrix where 
%   row represents stimulus guessed and 
%   column represents stimulus presented
%analysis_type = 'presented' or 'guessed'
%tells whether the index represents a row or column

if nargin() < 5 %then assume only care about train time = test time
    
end

dims = size(conf_resample);

if length(dims) == 4 %then we only saved for train time = test time
    
    time_bins = dims(3); %3rd dim is number of time bins
    
    means = zeros(1, time_bins);
    errors = zeros(1, time_bins);
    
    for time = 1 : time_bins
        
        all_resamples = zeros(1, dims(4));
        
        for resample = 1 : dims(4) %4th dim is number of resamples
            
            slice = analyze_confusion_slice(conf_resample(:, :, time, resample), class_to_analyze, analysis_type, num_classes);

            all_resamples(resample) = slice(class_to_analyze);
            
        end
        
        means(1, time) = mean(all_resamples);
        errors(1, time) = std(all_resamples);
        
    end
        
elseif length(dims) == 5
    
    time_bins = dims(4); %4rd dim is number of test time bins
    
    means = zeros(1, time_bins);
    errors = zeros(1, time_bins);
    
    for time = 1 : time_bins
        
        all_resamples = zeros(1, dims(4));
        
        for resample = 1 : dims(5) %5th dim is number of resamples
            
            slice = analyze_confusion_slice(conf_resample(:, :, train_time, time, resample), class_to_analyze, analysis_type, num_classes);

            all_resamples(resample) = slice(class_to_analyze);
            
        end
        
        means(1, time) = mean(all_resamples);
        errors(1, time) = std(all_resamples);
        
    end
        
else
    error('Confusion matrix with resamples separately has invalid number of dimensions (%d)!', length(dims));
end
    