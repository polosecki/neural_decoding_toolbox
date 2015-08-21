function [] = check_analysis_validity(analysis, decoder)
%Given paramters from the analysis and the decoder, checks to make sure the
%proper data was grabbed and analyzed

if ~strcmpi(analysis.monkey, decoder.monkey)
    error('Intended monkey analyzed not same as decoded monkey!');
end

if ~strcmpi(analysis.area, decoder.area)
    error('Intended area analyzed not same as decoded area!');
end

if ~strcmpi(analysis.ref, decoder.ref)
    error('Intended time reference analyzed not same as decoded time reference!');
end

if ~strcmpi(analysis.align, decoder.align)
    error('Intended alignment in analysis not same as decoded alignment!');
end

if analysis.time_start ~= decoder.time_start
    error('Intended start time analyzed not same as decoded start time !');
end

if ~strcmpi(analysis.labels_to_use, decoder.labels_to_use)
    error('Intended labels to decode on not same in analysis and decoding!');
end

if ~strcmpi(analysis.decode_on, decoder.decode_on)
    error('Intended condition (phi/brt) to decode not same in analysis and decoding!');
end

if analysis.train_in ~= decoder.train_condition_in
    error('Intended train condition (in/out) not same in analysis and decoding!');
end

if analysis.test_in ~= decoder.test_condition_in
    error('Intended test condition (in/out) not same in analysis and decoding!');
end


