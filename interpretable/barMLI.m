function [f, ax] = barMLI(casenum, MLIcont, feats, refdata, uiaxes)

if exist('uiaxes','var') 
    ax = uiaxes; 
    f=0;
else 
    ax = gca;
    f=figure;
    f.Position = [100 100 750 750];
end

hold(ax,'on'); 
nF = numel(feats);
y = MLIcont.Y_mapped(casenum,:);
y_ciu = MLIcont.Y_mapped_ciu(casenum,:);
y_cil = MLIcont.Y_mapped_cil(casenum,:);
[~,idx] = sort(y);
idx2 = abs(y_ciu) > abs(y);
if any(idx2)
    y2 = y;
    y2(~idx2) = nan;
    y(idx2) = nan;
end

bar(ax, y(idx),'FaceColor',rgb('DodgerBlue'),'EdgeColor',rgb("SlateGrey"));
errorbar(ax,1:nF, y(idx), y_ciu(idx), y_cil(idx), 'LineStyle','none', 'Color', 'k'); 
if any(idx2)
    bar(ax,y2(idx), 'FaceColor',rgb('LightGrey'),'EdgeColor',rgb("Grey")); 
    errorbar(ax,1:nF, y2(idx), y_ciu(idx), y_cil(idx), 'LineStyle','none', 'Color', rgb("Grey")); 
end
%ax=gca; 
ax.XTick=1:numel(feats); 
if any(idx2)
    featsI = strcat('\color{gray}',feats(idx2));
    feats(idx2) = featsI;
end
feats = regexprep(feats,'_', '\\_');
ax.XTickLabel=feats(idx);
ax.YAxis.Label.String = 'Percentage change of prediction [ % maximum range ]';
ax.YAxis.Label.FontWeight = 'bold'; 
ax.YAxis.Label.FontSize = 12; 
ax.XAxis.Label.String = 'Features'; 
ax.Box="on";

if exist('refdata','var') && ~isempty(refdata)
    ax.Position(4) = .50;
    pos = ax.Position;
    pos([2 4]) = [0.75 0.2];
    ax2 = axes('Position', pos);
    centiles = nk_ComputePercentiles(refdata,refdata(casenum,:),'inverse');
    bar(ax2,centiles(idx),'FaceColor',rgb('SlateGray'),'EdgeColor',rgb("Black"));
    ax2.YAxis.Label.String = 'Percentile rank [%]';
    ax2.YAxis.Label.FontWeight = 'bold'; 
    ax2.YAxis.Label.FontSize = 12; 
    ax2.XTick=1:numel(feats); 
    ax2.XLim=[-0.2 numel(feats)+1.2];
    ax2.XTickLabel=[];
    ax2.Title.String = sprintf('Predictive profile of subject #%g', casenum);
    ax2.Title.FontWeight = 'bold';
    ax2.Title.FontSize = 14;
else
    if ~exist('uiaxes','var')
        ax.Title.String = sprintf('Predictive profile of subject #%g', casenum);
    end
    ax.Title.FontWeight = 'bold';
    ax.Title.FontSize = 14;
end
