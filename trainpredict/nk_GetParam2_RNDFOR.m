% ==========================================================================
% FORMAT [param, model] = nk_GetParam_MEXELM(Y, label, SlackParam, ~, ...
%                                           ModelOnly)
% ==========================================================================
% Train LIBLINEAR models and evaluate their performance using Y & label, 
% SlackParam,
% if ModelOnly = 1, return only model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (c) Nikolaos Koutsouleris, 08/2012

function [param, model] = nk_GetParam2_RNDFOR(Y, label, ModelOnly, Param)
global EVALFUNC MODELDIR MODEFL 

param = [];
switch MODEFL
    case 'classification'
        if iscell(Y)  % MKL-based learning not implemented yet
        else % Univariate case
            model = pyrunfile('py_classRF_train.py', 'model_file', ...
                feat = Y, lab = label, n_est = int64(Param(1)), ...
                n_maxfeat = int64(Param(2)), rootdir = MODELDIR);  
        end
    case 'regression'
        model = pyrunfile('py_regRF_train.py', 'model_file', ...
                feat = Y, lab = label, n_est = int64(Param(1)), ...
                n_maxfeat = int64(Param(2)), rootdir = MODELDIR);
end

if ~ModelOnly
    [param.target] = predict_liblin(label, Y, model);
    param.dec_values = param.target;
    param.val = EVALFUNC(label, param.dec_values);
end
