function [rho,phi]=calculate_RF_center(xi,yi,zi)

%zi(zi<mean(zi(:)))=0;
zi=(zi-mean(zi(:)))/std(zi(:)); % convert to z-score
CC=bwconncomp(zi>0); %parse thresholded z-score into components
[nrows, ~] = cellfun(@size, CC.PixelIdxList);
[~,biggest_comp]=max(nrows); %pick largest component
temp=zeros(size(zi));
temp(CC.PixelIdxList{biggest_comp})=zi(CC.PixelIdxList{biggest_comp});
zi=temp; clear temp;
total_weight=sum(sum(zi));
xc=sum(sum(xi.*zi))/total_weight; % calculate center of mass of largest component
yc=sum(sum(yi.*zi))/total_weight;

phi=atan2(yc,xc)*180/pi;

if phi<0;
    phi=phi+360;
end

rho=sqrt(xc^2+yc^2);