[X Y]=meshgrid(6:-1:1,1:6);

%%
figure;
temp=X+randn(6)/4;
pcolor(temp);
axis off
axes square
%%
figure;
temp2=Y+randn(6)/4;
pcolor(temp2);
axis off