function [] = write_analysis_parameters(params, num_valid_cells)
%After running confusion matrix analysis, this function will write a text
%file detailing the decoding/analysis parameters

%Get parameters
monkey = params.monkey;
area = params.area;
ref = params.ref;
time_start = params.time_start;
time_window = params.time_window;
labels_to_use = params.labels_to_use;
decode_on = params.decode_on;
train_in = params.train_condition_in;
test_in = params.test_condition_in;
classifier = params.classifier;
num_resamples = params.num_resample_runs;

%Write decoding paramters in figure_dir

fileID = fopen(['parameters_' area '.txt'], 'w');

if isempty(fileID)
    warning('File not opened properly to save parameters\n');
    return;
end

fprintf(fileID, 'Analysis completed: %s\nMonkey: %s\nArea: %s\n', datestr(clock()), monkey, area);
fprintf(fileID, 'Classifier used: %s\n', classifier);
fprintf(fileID, 'Number of reamples: %d\n', num_resamples); 
fprintf(fileID, 'Aligned on: %s-%s\n', ref, 'onset');
fprintf(fileID, 'Time window beginning at %d with width %d\n', time_start, time_window);
fprintf(fileID, 'Looking to decode %s from %s labels\n', decode_on, labels_to_use);

train_labels = get_decoder_labels(decode_on, labels_to_use, train_in);
test_labels = get_decoder_labels(decode_on, labels_to_use, test_in);

for i = 1 : size(train_labels, 2)
    fprintf(fileID, '\tTrain label %d: %s\n', i, strjoin(train_labels{1, i}));
end
for i = 1 : size(test_labels, 2)
    fprintf(fileID, '\tTest label %d: %s\n', i, strjoin(test_labels{1, i}));
end

if nargin() > 1
    fprintf(fileID, '%d valid cells in the population\n', num_valid_cells);
end

fclose(fileID);


end

