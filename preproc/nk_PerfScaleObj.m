function [sY, IN] = nk_PerfScaleObj(Y, IN)
% =========================================================================
% FORMAT function [sY, IN] = nk_PerfScaleObj(Y, IN)
% =========================================================================
% Scaling of matrix Y to [0,1] (zero_one=1) or [-1,1] (zero_one=2) or
% reverting of the resepctive scaling to original values (revertflag=1)
% if minY and maxY are provided by the user then the function won't compute
% the min and max values from Y. The zerooutflag allows to replace
% non-finite feature generated by the scaling to be zeroed out. if
% overmatflag is true then the functon wil compute min and max over the
% entire matrix and not feature-wise.
%
% I/O Arguments (: Defaults): 
% -------------------------------------------------------------------------
% Y                   :       M cases x N features data matrix
% IN.minY, IN.maxY    : []    Min and Max values [computed from Y] 
% IN.overmatflag      : 0     [not across entire matrix] / feature-wise
% IN.ZeroOne          : 1     Scale to [0,1] 
% IN.revertflag       : 0     Revert scaling [no]
% IN.zerooutflag      : 1     Remove non-finite values [yes]
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (c) Nikolaos Koutsouleris, 10/2015

% =========================== WRAPPER FUNCTION ============================ 
if ~exist('IN','var'), IN = []; end
if iscell(Y) 
    sY = cell(1,numel(Y)); 
    for i=1:numel(Y), [sY{i}, IN] =  PerfScaleObj(Y{i}, IN); end
else
    [ sY, IN ] = PerfScaleObj(Y, IN );
end

% =========================================================================
function [sY, IN] = PerfScaleObj(Y, IN)

% Defaults
if isempty(IN),eIN=true; else, eIN=false; end
% Determine min and max over entire array?
if eIN|| ~isfield(IN,'overmatflag')     || isempty(IN.AcMatFl),     IN.AcMatFl = false;     end
% Scale to [0,1] or [-1,1]?
if eIN || ~isfield(IN,'ZeroOne')        || isempty(IN.ZeroOne),     IN.ZeroOne = 1;      end
% Revert any scaling?
if eIN || ~isfield(IN,'revertflag')     || isempty(IN.revertflag),  IN.revertflag = false;  end
% Zero-out non-finite features 
if eIN || ~isfield(IN,'zerooutflag')    || isempty(IN.zerooutflag), IN.zerooutflag = 2;  end

[mY, nY] = size(Y);

% Check for Minimum
if eIN || ~isfield(IN,'minY') || isempty(IN.minY)
    if IN.AcMatFl, IN.minY = repmat(min(Y(:)),1,nY); else, IN.minY = nm_nanmin(Y); end
elseif size(IN.minY,2) == 1 && nY > 1 
    IN.minY = repmat(IN.minY,1,nY);
end

% Check for Maximum
if eIN || ~isfield(IN,'maxY') || isempty(IN.maxY)
    if IN.AcMatFl, IN.maxY = repmat(max(Y(:)),1,nY); else, IN.maxY = nm_nanmax(Y); end
elseif size(IN.maxY,2) == 1 && nY > 1 
    IN.maxY = repmat(IN.maxY,1,nY);
end
if eIN || ~isfield(IN,'ise') || isempty(IN.ise)
    IN.ise = ~(IN.minY == IN.maxY);
end
if any(IN.ise==0), nY = size(Y(:,IN.ise),2); end

switch IN.ZeroOne
    case 1
        % Scale EACH FEATURE in the data to [0, 1]
        if ~IN.revertflag
            sY = (Y(:,IN.ise) - repmat(IN.minY(IN.ise),mY,1)) * spdiags(1./(IN.maxY(IN.ise)-IN.minY(IN.ise))', 0, nY, nY); 
        else
            sY = bsxfun(@plus,bsxfun(@times, Y(:,IN.ise), (IN.maxY(IN.ise) - IN.minY(IN.ise))),IN.minY(IN.ise));           
        end
    case 2
        % Scale EACH FEATURE in the data to [-1, 1]
        if ~IN.revertflag
            sY = 2 * bsxfun(@rdivide,bsxfun(@minus,Y(:,IN.ise),IN.minY(IN.ise)),IN.maxY(IN.ise)-IN.minY(IN.ise)) - 1;
        else
            sY = bsxfun(@times, Y(:,IN.ise)./2+0.5, (IN.maxY(IN.ise)-IN.minY(IN.ise)) + IN.minY(IN.ise));
        end
end

if issparse(sY), sY = full(sY); end
tY = Y; tY(:,IN.ise) = sY; sY = tY;
[ sY, IN ] = nk_PerfZeroOut(sY, IN);
