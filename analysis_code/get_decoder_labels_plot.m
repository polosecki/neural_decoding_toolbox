function test_labels = get_decoder_labels_plot(decode_on, labels_to_use, condition_in, class, is_special)
%Given desired decoding (phi or brt) and 
%labels to use (rel/abs phi/brt or phi and brt)
%generates the labels in required format for decoding toolbox
%Can be used for test OR train labels (depending on call from user)

values = {'0', '180', '270', '90'};

if nargin() < 5
    is_special = 0;
end

if is_special == 1
    
    if strcmpi(decode_on, 'phi')
        if strcmpi(labels_to_use, 'rel_phi') || strcmpi(labels_to_use, 'abs_phi')

            error('"Special" decoding not compatible with just phi label');

        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = sprintf('s = %s, t = %s', values{1}, values{1});
                decoder_labels{2} = sprintf('s = %s, t = %s', values{2}, values{1});
            else
                decoder_labels{1} = sprintf('s = %s, t = %s', values{1}, values{2});
                decoder_labels{2} = sprintf('s = %s t = %s', values{2}, values{2});
            end

        else
            decoder_labels = {};
        end

    else %brt
        if strcmpi(labels_to_use, 'rel_brt') || strcmpi(labels_to_use, 'abs_brt')

            error('"Special" decoding not compatible with just phi label');

        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = sprintf('s = %s, t = %s', values{1}, values{1});
                decoder_labels{2} = sprintf('s = %s, t = %s', values{1}, values{2});
            else
                decoder_labels{1} = sprintf('s = %s, t = %s', values{2}, values{1});
                decoder_labels{2} = sprintf('s = %s, t = %s', values{2}, values{2});
            end

        else
            decoder_labels = {};
        end
    end
    
else

    if strcmpi(decode_on, 'phi')
        if strcmpi(labels_to_use, 'rel_phi') || strcmpi(labels_to_use, 'abs_phi')
            for i = 1 : 4 %just to be explicit, make changes easier
                decoder_labels{i} = sprintf('s = %s', values{i});
            end

        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = sprintf('s = %s, t = %s & s = %s, t = %s', values{1}, values{1}, values{1}, values{2});
                decoder_labels{2} = sprintf('s = %s, t = %s & s = %s, t = %s', values{2}, values{1}, values{2}, values{2});
            else
                decoder_labels{1} = sprintf('s = %s, t = %s & s = %s, t = %s', values{1}, values{3}, values{1}, values{4});
                decoder_labels{2} = sprintf('s = %s t = %s & s = %s, t = %s', values{2}, values{3}, values{2}, values{4});
            end

        else
            decoder_labels = {};
        end

    else %brt
        if strcmpi(labels_to_use, 'rel_brt') || strcmpi(labels_to_use, 'abs_brt')
            for i = 1 : 4 %just to be explicit, make changes easier
                decoder_labels{i} = sprintf('t = %s', values{i});
            end

        elseif strcmpi(labels_to_use, 'rel_phi_brt') || strcmpi(labels_to_use, 'abs_phi_brt')
            if condition_in == 1
                decoder_labels{1} = sprintf('s = %s, t = %s & s = %s, t = %s', values{1}, values{1}, values{2}, values{1});
                decoder_labels{2} = sprintf('s = %s, t = %s & s = %s, t = %s', values{1}, values{2}, values{2}, values{2});
            else
                decoder_labels{1} = sprintf('s = %s, t = %s & s = %s, t = %s', values{3}, values{1}, values{4}, values{1});
                decoder_labels{2} = sprintf('s = %s, t = %s & s = %s, t = %s', values{3}, values{2}, values{4}, values{2});
            end

        else
            decoder_labels = {};
        end
    end
    
end

test_labels = decoder_labels{class};

