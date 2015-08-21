function decoder_labels = get_decoder_labels_separated(decode_on, labels_to_use, condition_in)
%Given desired decoding (phi or brt) and 
%labels to use (rel/abs phi/brt or phi and brt)
%generates the labels in required format for decoding toolbox
%Can be used for test OR train labels (depending on call from user)

values = {'0', '180', '270', '90'};

if strcmpi(decode_on, 'phi')
    if strcmpi(labels_to_use, 'rel_phi') || strcmpi(labels_to_use, 'abs_phi')
        for i = 1 : 4 %just to be explicit, make changes easier
            decoder_labels{i} = values{i};
        end
        
    elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
        if condition_in == 1
            decoder_labels{1} = [values{1} '_' values{1}];
            decoder_labels{2} = [values{1} '_' values{2}];
            decoder_labels{3} = [values{2} '_' values{1}];
            decoder_labels{4} = [values{2} '_' values{2}];
        else
            decoder_labels{1} = [values{1} '_' values{3}];
            decoder_labels{2} = [values{1} '_' values{4}];
            decoder_labels{3} = [values{2} '_' values{3}];
            decoder_labels{4} = [values{2} '_' values{4}];
        end
        
    else
        decoder_labels = {};
    end
    
else %brt
    if strcmpi(labels_to_use, 'rel_brt') || strcmpi(labels_to_use, 'abs_brt')
        for i = 1 : 4 %just to be explicit, make changes easier
            decoder_labels{i} = values{i};
        end
        
    elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
        if condition_in == 1
            decoder_labels{1} = [values{1} '_' values{1}];
            decoder_labels{2} = [values{2} '_' values{1}];
            decoder_labels{3} = [values{1} '_' values{2}];
            decoder_labels{4} = [values{2} '_' values{2}];
        else
            decoder_labels{1} = [values{3} '_' values{1}];
            decoder_labels{2} = [values{4} '_' values{1}];
            decoder_labels{3} = [values{3} '_' values{2}];
            decoder_labels{4} = [values{4} '_' values{2}];
        end
    
    else
        decoder_labels = {};
    end
end