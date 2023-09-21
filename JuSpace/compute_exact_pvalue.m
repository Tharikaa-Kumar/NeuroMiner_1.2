function [p_exact,dist_rand] = compute_exact_pvalue(D1,D2,data_PET,res,Nperm,options,T1)
% function [p_exact,dist_rand] = compute_exact_pvalue(D1,D2,data_PET,res,Nperm,options,T1)
% the functions allow to compute exact p-values based on the output from
% the compute_DomainGauges function, see help for this function for the
% input parameters
% options: a numeric array, i.e. [1 1]
% first index indicates the computing option
    % option(1) = 1 --> es between
    % option(1) = 2 --> es within
    % option(1) = 3 --> mean list 1
    % option(1) = 4 --> list 1 each
    % option(1) = 5 --> ind z-score list 1 to list 2
    % option(1) = 6 --> pair-wise difference list 1 to list 2
    % options(1) = 7 --> leave one out from list 1
    % opt_comp = 8 --> list 1 each compares against null distribution of
    % correlation coefficients
% second index indicates the analysis option
    % option(2) = 1 --> % Spearman correlation
    % option(2) = 2 --> % Pearson correlation
    % option(2) = 3 --> % multiple linear regresion
% IMPORTANTLY: exact p-value is only supported for options(1) = 1,2,5 and 6
% and options(2) = 1 and 2 settings

N = size(D1,1);
N2 = size(D2,1);
N1_g1 = round(N.*N./(N+N2));
N1_g2 = N-N1_g1;
N2_g1 = round(N2.*N./(N+N2));
N2_g2 = N2-N2_g1;

% if options(4)==1 % adjust for structural correlation
%     path_T1 = fullfile(fileparts(which('spm')),'tpm','TPM.nii,1');
%     T1 =  mean_time_course({path_T1},atlas, atlas_vals); 
% end


v = [ones(floor(N./2),1); 2.*ones(floor(N./2)+1,1)];
for i = 1:Nperm
    
    ord_i2 = randperm(N2)';
    D1_i = zeros(size(D1));
    D2_i = zeros(size(D2));
%     i_r = randi(2,size(D1,1),1); 
    switch options(1) %orthogonal permutations
        case {2,6}
            ord_i = randperm(N)'; %orthogonal permutations
            i_r = v(ord_i); %orthogonal permutations
            D1_i(i_r==1,:) = D1(i_r==1,:);
            D1_i(i_r==2,:) = D2(i_r==2,:);
            D2_i(i_r==2,:) = D1(i_r==2,:);
            D2_i(i_r==1,:) = D2(i_r==1,:);
        case {1,5}
            ord_i1 = randperm(N)';
            ord_i2 = randperm(N2)';
            D1_i(1:N1_g1,:) = D1(ord_i1(1:N1_g1),:);
            D1_i(N1_g1+1:end,:) = D2(ord_i2(1:N1_g2),:);
            l1 = length(ord_i1(N1_g1+1:end));
            D2_i(1:l1,:) = D1(ord_i1(N1_g1+1:end),:);
            D2_i(l1+1:end,:) = D2(ord_i2(N1_g2+1:end),:);
    end
    

switch options(1)
   case 1 % Cohen's d between groups
        m_D1 = mean(D1_i);
        std_D1 = std(D1_i);
        m_D2 = mean(D2_i);
        std_D2 = std(D2_i);
        data = (m_D1-m_D2)./sqrt((std_D1.^2+std_D2.^2)./2);
    case 2 % Cohen's d within group change
        delta_d = D1_i-D2_i;
        data = mean(delta_d)./std(delta_d);
    case 3 % mean list 1
        if size(D1_i,1)==1
            data = D1_i;
        else
            data = mean(D1_i);
        end
    case 4 % list 1 with PET data
        data = D1_i;
    case 5 % compute z-score list 1 relative to list 2
        m_D2 = mean(D2_i);
        std_D2 = std(D2_i);
        data = (D1_i - repmat(m_D2,size(D1_i,1),1))./repmat(std_D2,size(D1_i,1),1);
    case 6 % pair-wise differences list 1 - list 2
        data = D1_i - D2_i;
    case 7 
        for i = 1:size(D1_i,1)
            data_i = D1_i(i,:);
            data_z = D1_i([1:i-1 i+1:end],:);
            data(i,:) = (data_i-mean(data_z))./std(data_z);
        end   
    case 8
        data = D1_i;
end
    
switch options(2)
    case 1
% if options(2)==1
        if options(4)==1
            data_ij = removenan_my([data',data_PET',T1']);
            [r_es] = partialcorr(data_ij(:,1:size(data',2)),data_ij(:,size(data',2)+1:size(data',2)+size(data_PET',2)),data_ij(:,size(data',2)+size(data_PET',2)+1:end),'type','Spearman');   
        else
            data_ij = removenan_my([data',data_PET']);
            [r_es] = corr(data_ij(:,1:size(data',2)),data_ij(:,size(data',2)+1:size(data',2)+size(data_PET',2)),'type','Spearman');   
        end
    case 2
% elseif options(2)==2
        if options(4)==1
            data_ij = removenan_my([data',data_PET',T1']);
            [r_es] = partialcorr(data_ij(:,1:size(data',2)),data_ij(:,size(data',2)+1:size(data',2)+size(data_PET',2)),data_ij(:,size(data',2)+size(data_PET',2)+1:end),'type','Pearson');
        else
            data_ij = removenan_my([data',data_PET']);
            [r_es] = corr(data_ij(:,1:size(data',2)),data_ij(:,size(data',2)+1:size(data',2)+size(data_PET',2)),'type','Pearson');
        end
    case 3
        if options(4)==1
            data_ij = removenan_my([data',data_PET',T1']);
        else
            data_ij = removenan_my([data',data_PET']);
        end
        x = data_ij(:,1:size(data',2));
        Y = data_ij(:,size(data',2)+1:end);
        Y = [ones(length(x),1) Y];
        r_es = [Y\x]';
% else
%     disp('Exact p-value permutation is not supported for this option');
%     break;
% end
end

if options(2) ~= 3
    rr = fishers_r_to_z(r_es);
else
    if options(4)==1
        rr = r_es(:,2:end-1);
    else
        rr = r_es(:,2:end);
    end
end

switch options(1) % computes correlations
    case {1,2}
        r_all(i,:) = rr;
    case {5,6}
        r_all(i,:) = mean(rr);
end

end

p_exact = (sum(abs(r_all)>=abs(res))+1)./(length(r_all)+1);
dist_rand = r_all;