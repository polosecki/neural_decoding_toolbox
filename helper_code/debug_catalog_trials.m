function [] = debug_catalog_trials(raster_labels)
%Tells how many trials of certain types exist in the data

phi_counts = zeros(1, 4);

for i = 1 : size(raster_labels.rel_phi, 2)
    switch raster_labels.rel_phi{1, i}
        case '0'
            phi_counts(1, 1) = phi_counts(1, 1) + 1;
        case '90'
            phi_counts(1, 2) = phi_counts(1, 2) + 1;
        case '180'
            phi_counts(1, 3) = phi_counts(1, 3) + 1;
        case '270'
            phi_counts(1, 4) = phi_counts(1, 4) + 1;
    end
end

fprintf('In relative frame (phi), there are:\n\t%d for 0 degrees\n\t%d for 90 degrees\n\t%d for 180 degrees\n\t%d for 270 degrees\n', ...
            phi_counts(1, 1), phi_counts(1, 2), phi_counts(1, 3), phi_counts(1, 4));
        
fprintf('%d total trials (above count is %d)\n', size(raster_labels.rel_phi, 2), sum(phi_counts, 2));

brt_counts = zeros(1, 4);

for i = 1 : size(raster_labels.rel_brt, 2)
    switch raster_labels.rel_brt{1, i}
        case '0'
            brt_counts(1, 1) = brt_counts(1, 1) + 1;
        case '90'
            brt_counts(1, 2) = brt_counts(1, 2) + 1;
        case '180'
            brt_counts(1, 3) = brt_counts(1, 3) + 1;
        case '270'
            brt_counts(1, 4) = brt_counts(1, 4) + 1;
    end
end

fprintf('\nIn relative frame (brt), there are:\n\t%d for 0 degrees\n\t%d for 90 degrees\n\t%d for 180 degrees\n\t%d for 270 degrees\n', ...
            brt_counts(1, 1), brt_counts(1, 2), brt_counts(1, 3), brt_counts(1, 4));
        
fprintf('%d total trials (above count is %d)\n', size(raster_labels.rel_brt, 2), sum(brt_counts, 2));

phi_brt_counts = zeros(1, 4);

for i = 1 : size(raster_labels.rel_phi_brt, 2)
    switch raster_labels.rel_phi_brt{1, i}
        case '0_0'
            phi_brt_counts(1, 1) = phi_brt_counts(1, 1) + 1;
        case '0_180'
            phi_brt_counts(1, 1) = phi_brt_counts(1, 1) + 1;
        case '180_0'
            phi_brt_counts(1, 2) = phi_brt_counts(1, 2) + 1; 
        case '180_180'
            phi_brt_counts(1, 2) = phi_brt_counts(1, 2) + 1;        
        case '0_90'
            phi_brt_counts(1, 3) = phi_brt_counts(1, 3) + 1;
        case '0_270'
            phi_brt_counts(1, 3) = phi_brt_counts(1, 3) + 1;
        case '180_90'
            phi_brt_counts(1, 4) = phi_brt_counts(1, 4) + 1;
        case '180_270'
            phi_brt_counts(1, 4) = phi_brt_counts(1, 4) + 1;
    end
end

fprintf('\nIn relative frame (phi & brt), there are:\n\t%d for phi = 0 & brt in RF\n\t%d for phi = 180 & brt in RF\n\t%d for phi = 0 & brt outside RF\n\t%d for phi = 180 & brt outside RF\n', ...
            phi_brt_counts(1, 1), phi_brt_counts(1, 2), phi_brt_counts(1, 3), phi_brt_counts(1, 4));
        
fprintf('%d total trials (above count is %d)\n', size(raster_labels.rel_phi_brt, 2), sum(phi_brt_counts, 2));

phi_brt_counts = zeros(1, 4);

for i = 1 : size(raster_labels.rel_phi_brt, 2)
    switch raster_labels.rel_phi_brt{1, i}
        case '90_0'
            phi_brt_counts(1, 1) = phi_brt_counts(1, 1) + 1;
        case '90_180'
            phi_brt_counts(1, 1) = phi_brt_counts(1, 1) + 1;
        case '270_0'
            phi_brt_counts(1, 2) = phi_brt_counts(1, 2) + 1;
        case '270_180'
            phi_brt_counts(1, 2) = phi_brt_counts(1, 2) + 1;        
        case '90_90'
            phi_brt_counts(1, 3) = phi_brt_counts(1, 3) + 1;
        case '90_270'
            phi_brt_counts(1, 3) = phi_brt_counts(1, 3) + 1;
        case '270_90'
            phi_brt_counts(1, 4) = phi_brt_counts(1, 4) + 1;
        case '270_270'
            phi_brt_counts(1, 4) = phi_brt_counts(1, 4) + 1;
    end
end

fprintf('\nIn relative frame (phi & brt), there are:\n\t%d for phi = 90 & brt in RF\n\t%d for phi = 270 & brt in RF\n\t%d for phi = 90 & brt outside RF\n\t%d for phi = 270 & brt outside RF\n', ...
            phi_brt_counts(1, 1), phi_brt_counts(1, 2), phi_brt_counts(1, 3), phi_brt_counts(1, 4));
        
fprintf('%d total trials (above count is %d)\n', size(raster_labels.rel_phi_brt, 2), sum(phi_brt_counts, 2));

    

