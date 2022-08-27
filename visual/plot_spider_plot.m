function [pl, ps] = plot_spider_plot(tROI, options, ax)
y = height(tROI);
% colors = [rgb('Purple'); rgb('Red'); rgb('MediumSeaGreen'); rgb('DarkGreen')];
% Lg1 = 'bvFTD classifier';
% Lg2 = 'Schizophrenia classifier';
% Lg3 = 'MCI/Early AD classifier';
% Lg4 = 'Established AD classifier';
% Lg = {Lg1, Lg2, Lg3, Lg4};
%
% Tr1 = 0;
% Tr2 = 0.8;
% Tr3 = 0.8;
% Tr4 = 0.8;
% Tr = [Tr1 Tr2 Tr3 Tr4];
%
% figure;

tROI.Properties.RowNames = tROI.AnatomicalRegion;
axes(ax); cla
P = table2array(tROI(:,options.tROI_columns))';
if ~isempty(options.spider.max) && isfinite(options.spider.max)
    axmax = options.spider.max;
else
    axmax = max(P(:))+range(P(:))*0.05;
end
if ~isempty(options.spider.min) && isfinite(options.spider.min)
    axmin = options.spider.min;
else
    axmin = min(P(:))+range(P(:))*0.05;
end
AxesLimits = [repmat(axmin,1,y); repmat(axmax,1,y)];
[pl, ps] = spider_plot(P, ...
    'AxesLabels', tROI.AnatomicalRegion,...
    'AxesLimits', AxesLimits, ...
    'AxesShadedLimits', AxesLimits, ...
    'AxesInterval', options.spider.axesintval, ...
    'AxesLabelsEdge','none', ...
    'AxesDisplay', 'one', ...
    'AxesLabelsOffset', 0.05, ...
    'AxesFontSize', options.spider.axesfontsize,...
    'LabelFontSize', options.spider.labelfontsize, ...
    'LineWidth', options.spider.linewidth,...
    'FillOption', 'off',...
    'Marker', options.spider.marker, ...
    'MarkerSize', options.spider.markersize, ...
    'MinorGrid', options.spider.minorgrid, ...
    'MinorGridInterval', options.spider.minorgridintval, ...
    'AxesHorzAlign', 'quadrant', ...
    'AxesVertAlign', 'quadrant', ...
    'AxesLabelsRotate', 'on', ...
    'AxesDirection', options.spider.axesdirection, ...
    'AxesPrecision', options.spider.axesprecision,...
    'AxesZero','off',...
    'AxesZeroColor', 'black', ...
    'AxesLabelsRotate','on', ...
    'AxesOffset', 1, ...
    'Axesobject', ax, ...
    'AxesDirection', options.spider.axesdirection, ...
    'Color', options.tROI_colors);


% legend(Lg,'Location','northeastoutside')
% title('ROI Profiles [%ROI covered]');

% figure;
% spider_plot( ROICVR(1:y,:)', ...
%     'AxesLabels', L(1:y), ...
%     'AxesLimits', [-6*ones(1,y); 6*ones(1,y)], ...
%     'AxesShadedLimits', [-6*ones(1,y); 6*ones(1,y)], ...
%     'AxesInterval', 10, ...
%     'AxesLabelsEdge',' none', ...
%     'AxesColor', rgb('LightGrey'), ...
%     'AxesDisplay', 'one', ...
%     'AxesLabelsOffset', 0.05, ...
%     'LabelFontSize', 7, ...
%     'AxesHorzAlign', 'quadrant', ...
%     'AxesVertAlign', 'quadrant', ...
%     'AxesLabelsRotate', 'on', ...
%     'AxesDirection', 'reverse', ...
%     'LineTransparency', 0.5, ...
%     'Marker','none', ...
%     'Color', colors);
%
legend(ax,options.tROI_legend,'Location','best','Interpreter','none','FontSize', options.spider.legendfontsize)

end
