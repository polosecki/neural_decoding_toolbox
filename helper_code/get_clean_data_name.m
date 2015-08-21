function file_name = get_clean_data_name(reference, align, time_start, time_window, time_type)
%Given naming conventions, gives name for clean data file

if nargin() < 5
    %If no time type, assume that time is window, not slice
    time_type = 'window';
end

switch align
    case 'start'
        if strcmpi(time_type, 'slice')
            file_name = [reference '_start_' num2str(time_start) '_slice_clean'];
        else
            file_name = [reference '_start_' num2str(time_start) '_' num2str(time_window) '_window_clean'];
        end
    case 'onset'
        if strcmpi(time_type, 'slice')
            file_name = [reference '_onset_' num2str(time_start) '_slice_clean'];
        else
            file_name = [reference '_onset_' num2str(time_start) '_' num2str(time_window) '_window_clean'];
        end
end
% switch reference
%     case 'start'
%         if strcmpi(time_type, 'slice')
%             file_name = [align '_start_' num2str(time_start) '_slice_clean'];
%         else
%             file_name = [align '_start_' num2str(time_start) '_' num2str(time_window) '_window_clean'];
%         end
%     case 'onset'
%         if strcmpi(time_type, 'slice')
%             file_name = [align '_onset_' num2str(time_start) '_slice_clean'];
%         else
%             file_name = [align '_onset_' num2str(time_start) '_' num2str(time_window) '_window_clean'];
%         end
% end

end

