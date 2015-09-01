function [results]= make_GLM_and_contrasts_from_inst_firing(y,closest_surf_phi,surf_str)

%% Define variables
do_anovan=0;
RF_surf_index=find(unique([surf_str.phi])'==closest_surf_phi);

locations=circshift(unique([surf_str.phi])',-RF_surf_index+1);%RF_centered; for computation purposes
non_shifted_locations=unique([surf_str.phi])'; %For nomenclature purposes

locations=reshape(locations,2,2); %rows indicate physical conditions
non_shifted_locations=reshape(non_shifted_locations,2,2);
phys_surf=2*ismember([surf_str.phi]',locations(1,:))-1;
phys_targ=2*ismember([surf_str.brt]',locations(1,:))-1;

attend1=zeros(size(phys_targ)); attend1(ismember([surf_str.phi]',locations(1,1)))=1;
attend1(ismember([surf_str.phi]',locations(1,2)))=-1;

attend2=zeros(size(phys_targ)); attend2(ismember([surf_str.phi]',locations(2,1)))=1;
attend2(ismember([surf_str.phi]',locations(2,2)))=-1;

attend=[surf_str.phi];
saccade=[surf_str.brt]';

saccad1=zeros(size(phys_targ)); saccad1(ismember([surf_str.brt]',locations(1,1)))=1;
saccad1(ismember([surf_str.brt]',locations(1,2)))=-1;

saccad2=zeros(size(phys_targ)); saccad2(ismember([surf_str.brt]',locations(2,1)))=1;
saccad2(ismember([surf_str.brt]',locations(2,2)))=-1;

%% Run ANOVAN
if do_anovan
variable_names={'Surface Position','Target Position','Attention','Saccade'};
conds={phys_surf,phys_targ,attend,saccade};

% 'nested': A matrix M of 0's and 1's specifying the nesting relationships among the grouping variables. 
%M(i,j) is 1 if variable i is nested in variable j
nested_matrix=zeros(length(variable_names));
nested_matrix(3,1)=1; % var 3 (attention) is nested within var 1 (surf position)
nested_matrix(4,2)=1; % var 4 (Saccade) is nested within var 2 (Target Position)

%Statistical tests of all effects of interes are calculated below:
close all;
results.anovan.p=[];
for i=1:size(y,2)
    disp(['ANOVAN ' num2str(i)])
[p,table,stats,terms] = anovan(y(:,i),conds,'varnames',variable_names,'model','interaction','nested',nested_matrix);
%stats.coeffs give you effect sizes, stats.coeffnames give you what is what
close(1)
results.anovan.p=[results.anovan.p p];
results.anovan.table{1,i}=table;
results.anovan.stats{1,i}=stats;
results.anovan.stats{i}=stats;
results.anovan.terms{i}=terms;
end
end
%% RUN GLMs for effect sizes
%To obtain effect sizes am interested in:
%-Main effect of surface postion
%-Main effect of target postion
%-Main effect of saccade
%-Main effect of attention
%-Interaction attention / target
%-Interaction attention / saccade


%Special vaiables for main effects and firstv interaction (attention / target position)
for i=1:2
    for j=1:2
att1_targ{i,j}=ismember([surf_str.phi]',locations(1,i)) &  ismember([surf_str.brt]',locations(j,:));
att2_targ{i,j}=ismember([surf_str.phi]',locations(2,i)) &  ismember([surf_str.brt]',locations(j,:));
    end
end
%att1_targ{end}=[];
%att2_targ{end}=[];ra
%For main

temp1=att1_targ';
temp2=att2_targ';
X1=double([[temp1{:}] [temp2{:}] saccad1 saccad2]);

%i.e., [att1_11 att1_12 att1_21  att2_11 att2_12 att2_21 att2_22 sacc1 sacc2];
%phys surf = sum([temp1{:}],2) => sum([temp1{:}],2) - sum([temp2{:}],2) gives the effect of surface postion
%targ effect: [(att1_11 -att1_12 att1_21 -att1_22) (att2_11 -att2_12 att2_21 -att2_22)]
%atten1 effect: [(att1_11 att1_12 -att1_21 -att1_22)];
%atten2 effect: (att2_11 att2_12 -att2_21 -att2_22);
%atten1_taget_inter: [(att1_11 -att1_12 -att1_21 att1_22)]; 
%atten1_taget_inter: similar as above

contrast.matrix={[1 1 1 1 -1 -1 -1 -1 0 0]/4; %main effect of surface (possibly than this is better factoring atention out)
                 [1 -1 1 -1 1 -1 1 -1 0 0]/4; %main effect of target (would be good to have attention factore)
                 %[1 1 -1 -1 0  0 0  0 0 0]/2; %main effect of attnetion1
                 [1 0 -1 0 0  0 0  0 0 0]; % attention1 (w saccade targets in RF)
                 [0 1  0 -1 0  0 0  0 0 0]; % attention1 (w/no the saccade targets in RF)
                 [0 0  0 0  1 0 -1 0 0 0]; %attention2 (w saccade target in RF)
                 [0 0  0 0  0 1 0 -1 0 0]; %attention2 (w/no saccade target in RF) 
                 %[1 1 -1 -1 0  0 0  0 0 0;  %main effect of attnetion global
                 % 0 0  0 0  1 1 -1 -1 0 0]/2;
                 [1 -1 -1 1 0 0  0  0 0 0]/2;%att1/target interaction
                 [0  0 0  0 1 -1 1 -1 0 0]/2;%att2/target interaction
                 [0  0 0  0 0 0 1 1 0 0]/2; %baseline!! (i.e., nothing in RF)
                 };
             
contrast.name={'Surface(main)';
               'Target (main)';
               %'Main effect of Attn(Stim in RF)';
               'Attn(Surf in RF)(Targ in RF)';
               'Attn(Surf in RF)(Targ out RF)';
               'Attn(Surf out RF)(Targ in RF)';
               'Attn(Surf out RF)(Targ out RF)';
               %'Main effect of attention, global';
               'Attn(Surf in RF)/Targ inter';
               'Attn(Surf out RF)/Targ inter'
               'Baseline'};
 crazy_mat1=inv(X1'*X1);
 results.GLM1.ces_std=zeros(length(contrast.matrix),size(y,2));
 results.GLM1.ces_covar=cell(length(contrast.matrix),size(y,2));
 results.GLM1.F=zeros(length(contrast.matrix),size(y,2));
 results.GLM1.Fsig=zeros(length(contrast.matrix),size(y,2));
 results.GLM1.ces=zeros(length(contrast.matrix),size(y,2));
 results.GLM1.ces_vector=cell(length(contrast.matrix),size(y,2));
 results.GLM1.dof=zeros(length(contrast.matrix),size(y,2));
 for i=1:size(y,2)
     disp(['GLM1 ' num2str(i)])
     temp_y=y(:,i);
     if rank(X1(~isnan(temp_y),:))<rank(X1)
         continue
     end
     [beta, rvar, ~, ~] = fast_glmfit(temp_y(~isnan(temp_y)),X1(~isnan(temp_y),:));
     
     for c=1:length(contrast.matrix)
         [F, Fsig, ces, edof] = fast_fratio(beta,X1,rvar,contrast.matrix{c});
         ces_covar=rvar*contrast.matrix{c}*crazy_mat1*contrast.matrix{c}';
         ces_std=sqrt(mean(diag(ces_covar)))/sqrt(length(diag(ces_covar)));
         results.GLM1.ces_std(c,i)=ces_std;
         results.GLM1.ces_covar{c,i}=ces_covar;
         results.GLM1.F(c,i)=F;
         results.GLM1.Fsig(c,i)=Fsig;
         results.GLM1.ces(c,i)=mean(ces);
         results.GLM1.ces_vector{c,i}=ces;
         results.GLM1.dof(c,i)=edof;
     end
     
     
     results.GLM1.beta(:,i)=beta;
     results.GLM1.rvar(1,i)=rvar;
     
 end
 results.GLM1.X=X1;
 results.GLM1.contrast.name=contrast.name;
 results.GLM1.contrast.matrix=contrast.matrix;
 % Special variables for main effect of attn1 / saccade1 interaction

%i.e., [target att1_11 att1_12 att1_21 att2_22 att2 sacc2];

for i=1:2
    for j=1:2
att1_sacc1{i,j}=ismember([surf_str.phi]',locations(1,i)) &  ismember([surf_str.brt]',locations(1,j));
att1_sacc1{i,j}=ismember([surf_str.phi]',locations(1,i)) &  ismember([surf_str.brt]',locations(1,j));
    end
end
att1_bis=zeros(size(phys_surf)); %attention in RF, with no saccade targets in RF
att1_bis(ismember([surf_str.phi]',locations(1,1)) & ismember([surf_str.brt]',locations(2,:)))=1;
att1_bis(ismember([surf_str.phi]',locations(1,2)) & ismember([surf_str.brt]',locations(2,:)))=-1;
temp=att1_sacc1';


%TODO: an interaction that captures the interesting effect in LIP cell 11
%in Quincy

contrast2.matrix={2*[1 0 0 0  0  0 0 0 0 0]; %main effect of surface 
                  2*[0 1 0 0  0  0 0 0 0 0]; %main effect of target 
                  [0 0 1 1 -1 -1 0 0 0 0]/4 + ... %main effect of attnetion1
                  2*[0 0 0 0  0  0 1 0 0 0]/2;
                  2*[0 0 0 0  0  0 0 1 0 0];%main effect of attention2
                  [0 0 1 -1 1 -1 0 0 0 0]/2;%main effect of saccade1
                  2*[0 0 0  0 0  0 0 0 1 0];%main effect of saccade2
                  [0 0 1 -1 -1 1 0 0 0 0]/2; %attn1/sacc1 interaction
                  2*[0 0 0 0  0  0 1 0 0 0]; %Atten1 (no target in RF)
                  [0 0 1 1 -1 -1 0 0 0 0]/2 %Atten1 (target in RF)
                   };%test
             
contrast2.name={'Surface (main)';
               'Target (main)';
               'Attn(Surf in RF) (main)';
               'Attn(Surf out RF) (main)';
               'Saccade(targ in RF) (main)';
               'Saccade(targ out RF) (main)';
               'Attn(Surf in RF)/Sacc(Targ in RF) inter';
               'Attn(Surf in RF)(Targ out RF)'
               'Attn(Surf in RF)(Targ in RF)'};
           

 results.GLM2.ces_std=zeros(length(contrast2.matrix),size(y,2));
 results.GLM2.ces_covar=cell(length(contrast2.matrix),size(y,2));
 results.GLM2.F=zeros(length(contrast2.matrix),size(y,2));
 results.GLM2.Fsig=zeros(length(contrast2.matrix),size(y,2));
 results.GLM2.ces=zeros(length(contrast2.matrix),size(y,2));
 results.GLM2.ces_vector=cell(length(contrast2.matrix),size(y,2));
 results.GLM2.dof=zeros(length(contrast2.matrix),size(y,2));
 
 X2=[phys_surf phys_targ [temp{:}] att1_bis attend2 saccad2 ones(size(phys_targ))]; %
 crazy_mat2=inv(X2'*X2);
 for i=1:size(y,2)
     disp(['GLM2 ' num2str(i)])
     temp_y=y(:,i);
     if rank(X2(~isnan(temp_y),:))<rank(X2)
         continue
     end
     [beta2, rvar, ~, ~] = fast_glmfit(temp_y(~isnan(temp_y)),X2(~isnan(temp_y),:));
     
     for c=1:length(contrast2.matrix)
         [F, Fsig, ces, edof] = fast_fratio(beta2,X2,rvar,contrast2.matrix{c});
         ces_covar=rvar*contrast2.matrix{c}*crazy_mat2*contrast2.matrix{c}';
         ces_std=sqrt(mean(diag(ces_covar)))/sqrt(length(diag(ces_covar)));
         results.GLM2.ces_std(c,i)=ces_std;
         results.GLM2.ces_covar{c,i}=ces_covar;
         results.GLM2.F(c,i)=F;
         results.GLM2.Fsig(c,i)=Fsig;
         results.GLM2.ces(c,i)=mean(ces);
         results.GLM2.ces_vector{c,i}=ces;
         results.GLM2.dof(c,i)=edof;
     end
     
     results.GLM2.beta(:,i)=beta2;
     results.GLM2.rvar(1,i)=rvar;
     
 end
 results.GLM2.X=X2;
 results.GLM2.contrast.name=contrast2.name;
 results.GLM2.contrast.matrix=contrast2.matrix;
