function decoder_labels = get_decoder_labels(decode_on, labels_to_use, condition_in, is_special)
%Given desired decoding (phi or brt) and 
%labels to use (rel/abs phi/brt or phi and brt)
%generates the labels in required format for decoding toolbox
%Can be used for test OR train labels (depending on call from user)
%condition_in specifies, if we're decoding PHI, for ex., whether the
%BRT/saccade targets should be in or outside of the RF
%
%If is_special == 1, if we're decoding PHI, we keep BRT at just 0 or 180
%                    if we're decoding BRT, we keep PHI at just 0 or 180
%where condition_in then acts to specify if BRT/PHI is IN (0) or OUT (180)

values = {'0', '180', '270', '90'};

if nargin() < 4
    is_special = 0;
end

if is_special == 1
    
    if strcmpi(decode_on, 'phi')
        if strcmpi(labels_to_use, 'rel_phi') || strcmpi(labels_to_use, 'abs_phi')
            
            error('"Special" decoding not compatible with just phi label');
            
        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = {[values{1} '_' values{1}]};
                decoder_labels{2} = {[values{2} '_' values{1}]};
            else
                decoder_labels{1} = {[values{1} '_' values{2}]};
                decoder_labels{2} = {[values{2} '_' values{2}]};
            end

        else
            decoder_labels = {};
        end

    else %brt
        if strcmpi(labels_to_use, 'rel_brt') || strcmpi(labels_to_use, 'abs_brt')

            error('"Special" decoding not compatible with just phi label');

        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = {[values{1} '_' values{1}]};
                decoder_labels{2} = {[values{1} '_' values{2}]};
            else
                decoder_labels{1} = {[values{2} '_' values{1}]};
                decoder_labels{2} = {[values{2} '_' values{2}]};
            end

        else
            decoder_labels = {};
        end
    end
    
else
    
    if strcmpi(decode_on, 'phi')
        if strcmpi(labels_to_use, 'rel_phi') || strcmpi(labels_to_use, 'abs_phi')
            for i = 1 : 4 %just to be explicit, make changes easier
                decoder_labels{i} = {values{i}};
            end

        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = {[values{1} '_' values{1}], [values{1} '_' values{2}]};
                decoder_labels{2} = {[values{2} '_' values{1}], [values{2} '_' values{2}]};
            else
                decoder_labels{1} = {[values{1} '_' values{3}], [values{1} '_' values{4}]};
                decoder_labels{2} = {[values{2} '_' values{3}], [values{2} '_' values{4}]};
            end

        else
            decoder_labels = {};
        end

    else %brt
        if strcmpi(labels_to_use, 'rel_brt') || strcmpi(labels_to_use, 'abs_brt')
            for i = 1 : 4 %just to be explicit, make changes easier
                decoder_labels{i} = {values{i}};
            end

        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = {[values{1} '_' values{1}], [values{2} '_' values{1}]};
                decoder_labels{2} = {[values{1} '_' values{2}], [values{2} '_' values{2}]};
            else
                decoder_labels{1} = {[values{3} '_' values{1}], [values{4} '_' values{1}]};
                decoder_labels{2} = {[values{3} '_' values{2}], [values{4} '_' values{2}]};
            end

        else
            decoder_labels = {};
        end
    end
    
end
