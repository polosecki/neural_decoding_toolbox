function [xi,yi,zi] = display_map(x,y, zp, applylog, resi, sgaus, plotmode, multip,smooth_map)
%sgaus = 2.2857*0.002;
normalize = 0;

if applylog
    zpl = log(zp); % Attention! This log is done to avoid negative values
                   % for the interpolated power!
    zpl(isinf(zpl))=-1;               
                   
else
    zpl = zp;
end


lambdas = RBFcoef(zpl, [x y]', sgaus);

exl = 0.0005; % Extrapolate mm to the left
exr = 0.0005; % Extrapolate mm to the left
exu = 0.0005; % Extrapolate mm to the left
exd = 0.0005; % Extrapolate mm to the left

axmi = min(x) - exl;
axma = max(x) + exr;
aymi = min(y) - exu;
ayma = max(y) + exd;
axd = (axma-axmi)/(resi-1);
ayd = (ayma-aymi)/(resi-1);

[xi,yi] = meshgrid(axmi:axd:axma,aymi:ayd:ayma);
zi = reshape( ...
	RBFipol(lambdas, [x y]', [xi(:) yi(:)]', sgaus, normalize), ...
	size(xi));

if applylog
    zi = exp(zi); % Attention! This exp is to restore the zp logarithmization!
end

% Apply an optional multiplier to the interpolated data
zi = zi * multip;

if smooth_map.MAKE
    x_ax=mean(xi,1);
    y_ax=mean(yi,2);
    dx=mean(diff(x_ax));    
    
    ker_halfsize=5; %in degress;
    sigma_ker=smooth_map.fhwm_ker/(2*sqrt(2*log(2)));
    
    x=(-smooth_map.ker_halfsize):dx:(smooth_map.ker_halfsize);y=x;
    [X,Y]=meshgrid(x,y);
    ker=exp(-(X.^2+Y.^2)/(2*sigma_ker^2));ker=ker./sum(ker(:));
    zi=conv2(zi,ker,'same');
end

if strcmp(plotmode,'contourf')
    contourf(xi,yi,zi,50);
elseif strcmp(plotmode,'pcolor')  
    h = pcolor(xi,yi,zi);
    %h = pcolor(xi,yi,zi_smooth);
    set(h,'LineStyle','none');
end
% hold on;
% plot(x,y,'wo');
% hold off;
axmult = 1;
tdx = 0.001*0.25;
tdy = 0.001*0.25;
%for i=1:length(ch)
%    text(x(i)*axmult+tdx,y(i)*axmult+tdy,num2str(ch(i)));
%end

%axis off;
set(gca, 'PlotBoxAspectRatio', [axd ayd 1])
colorbar
