function [ ALTLAB, act ] = cv_Label_config(ALTLAB, defaultsfl)
global NM

altlabflag = 0;
newlabel = 'no label defined';
newlabelname = 'no name defined';
newmode = 'no new mode defined';
newgroupnames = [];

if ~exist('defaultsfl','var') || isempty(defaultsfl); defaultsfl = false; end

if ~defaultsfl

    if isfield(ALTLAB,'flag'), altlabflag = ALTLAB.flag; end
    if isfield(ALTLAB,'newlabel'), newlabel = ALTLAB.newlabel; end
    if isfield(ALTLAB,'newlabelname'), newlabelname = ALTLAB.newlabelname; end
    if isfield(ALTLAB,'newmode'), newmode = ALTLAB.newmode; end
    if isfield(ALTLAB,'newgroupnames'), newgroupnames = ALTLAB.newgroupnames; end


    if altlabflag == 1
        FLAGSTR = 'yes';

        if ~isempty(newlabel), NEWLABELSTR = newlabelname; else, NEWLABELSTR = 'not provided'; end
        if ~isempty(newmode), NEWMODESTR = newmode; else, NEWMODESTR = 'not provided'; end

        menustr = ['Use alternative label [' FLAGSTR ']|' ...
            'Load new label variable [' NEWLABELSTR ' --> ' NEWMODESTR ']' ];
        menuact = 1:2;
    else
        FLAGSTR = 'no';

        menustr = ['Use alternative label [' FLAGSTR ']'];

        menuact = 1;

        newmode = '';
    end

    nk_PrintLogo
    mestr = 'Alternative label'; navistr = [' >>> ' mestr]; fprintf('\nYou are here: %s >>> ');
    act = nk_input(mestr,0,'mq', menustr, menuact);

    switch act
        case 1
            if altlabflag == 1, altlabflag = 0; elseif altlabflag == 0, altlabflag = 1; end

        case 2
            newlabel = nk_input('Label variable',0,'r',[],[NM.n_subjects_all 1]);
            newlabelname = nk_input('New label name',0, 's', newlabelname);
            newmodenr = nk_input('Learning mode',0,'m','Classification|Regression',1:2);
            if newmodenr == 1
                newmode = 'classification';
                % check whether this is compatible with the current cv
                % structure (if one exists)
                newgroupsN = numel(unique(newlabel));
                newgroups = unique(newlabel);
                newgroupnames = nk_input('Groupnames (as vector, no numeric names)',0,'e',[],newgroupsN);

                if isfield(NM, 'cv')
                    cv_ok = check_CV_class(NM.cv, NM.cases, newlabel, newgroups);
                    if ~cv_ok
                        altlabflag = 0;
                        newlabel = 'define different label';
                        newlabelname = 'no name defined';
                        newmode = NM.modeflag;
                    end
                end

                if newgroupsN > 2
                    NM.TrainParam.RAND.Decompose = ...
                        nk_input('Multi-group decomposition method',0,'m', ...
                        'One-vs-One|One-vs-All',[1,2],Decompn);

                    %NM.cv = update_cvstruct_for_multiclass(NM.cv, NM.TrainParam.RAND.Decompose, newgroupsN)

                end

                %                 if newgroupsN>2
                %                     warndlg('Mutli-class labels are currently not supported by the alternative label functionality. Enter a different label or disable alternative label.')
                %                     altlabflag = 0;
                %                     newlabel = 'define different label';
                %                     newlabelname = 'no name defined';
                %                     newmode = NM.modeflag;
                %                 end

            elseif newmodenr == 2
                newmode = 'regression';
            end

    end
else
    act = 0;
end
ALTLAB.flag = altlabflag;
% check whether new label was entered or only yes

ALTLAB.newlabel = newlabel;
ALTLAB.newlabelname = newlabelname;
ALTLAB.newmode = newmode;
if strcmp(newmode,'classification')
    ALTLAB.newgroupnames = newgroupnames;
elseif isfield(ALTLAB, 'newgroupnames')
    ALTLAB = rmfield(ALTLAB, 'newgroupnames');
end


function compatCVflag = check_CV_class(cv, indcases, label, groups)
compatCVflag = 1;

% TO DO: check if this fits with all cv frameworks!

% loop through groups and cv folds
for i = 1:numel(groups)
    % current group indices
    indi = find(label == groups(i));

    % check whether their are members of this group in all inner cv test
    % folds (if so, then this is also the case for all inner and outer
    % training folds)

    contains_wrapper = @(cvStruct) containsGroup(cvStruct, indi);
    containsCases = cellfun(contains_wrapper, cv.cvin);

    if ~any(containsCases, 'all')
        compatCVflag = 0;
        warndlg('New label and CV structure incompatible (each group is not represented in each fold)')
        return
    end

end


function cc = containsGroup(cvin, groupind)
testfolds = cvin.TestInd;

intersect_wrapper = @(testf) isempty(intersect(testf,groupind));

emptyFolds = cellfun(intersect_wrapper, testfolds);

if any(emptyFolds, 'all')
    cc = 0;
else
    cc = 1;
end




% function cv = update_cvstruct_for_multiclass(cv, RAND, ngroups, newlabel)
% % One vs One, One vs All, Multigroup
% decomposeflag   = RAND.Decompose;
% % Are NaNs in the label?
% ulb = unique(newlabel,'rows');
% if any(~isfinite(ulb))
%     NaNflag = true; ind = logical(sum(isfinite(ulb),2));
%     ulb = ulb(ind,:);
% else
%     NaNflag = false;
% end
% [ix,jx] = size(cv.TrainInd);
% for i=1:ix
%     for ii=1:jx
%         cv.class{i,ii} = GenClass(g, ulb, nclass, Label(cv.TrainInd{i,ii}), decomposeflag, NaNflag);
% 
%         InPerms         = RAND.InnerPerm;
%         InFold          = RAND.InnerFold;
% 
%         class = cv.class{i,ii}
%         for j=1:InPerms
% 
%             for k=1:InFold
% 
%                 switch decomposeflag
% 
%                     case 1 % One-vs-One
% 
%                         for l=1:length(ngroups)
% 
%                             belongstrain = find(newlabel(cv.TrainInd{j,k}) == class{i}.groups(l));
%                             belongstest = find(newlabel(cv.TestInd{j,k}) == class{i}.groups(l));
% 
%                             if ~isempty(belongstrain)
%                                 tclass{i}.TrainInd{j,k} = [tclass{i}.TrainInd{j,k}; ...
%                                     cv.TrainInd{j,k}(belongstrain)];
%                                 tclass{i}.TrainLabel{j,k} = [tclass{i}.TrainLabel{j,k}; ...
%                                     groupind(l)*ones(size(belongstrain,1),1)];
%                             end
% 
%                             if ~isempty(belongstest)
%                                 tclass{i}.TestInd{j,k} = [tclass{i}.TestInd{j,k}; ...
%                                     cv.TestInd{j,k}(belongstest)];
%                                 tclass{i}.TestLabel{j,k} = [tclass{i}.TestLabel{j,k}; ...
%                                     groupind(l)*ones(size(belongstest,1),1)];
%                             end
% 
%                         end
%                         belongstrain = find(~isfinite(newlabel(cv.TrainInd{j,k})));
%                         if ~isempty(belongstrain)
%                             tclass{i}.TrainInd{j,k} = [tclass{i}.TrainInd{j,k}; ...
%                                 cv.TrainInd{j,k}(belongstrain)];
%                             tclass{i}.TrainLabel{j,k} = [tclass{i}.TrainLabel{j,k}; ...
%                                 nan(size(belongstrain,1),1)];
%                         end
% 
%                     case 2 % One-Vs-All
% 
%                         tclass{i}.TrainInd{j,k}  = cv.TrainInd{j,k};
%                         lb = zeros(size(cv.TrainInd{j,k}));
%                         indpos = newlabel(cv.TrainInd{j,k}) == class{i}.groups;
%                         indneg = newlabel(cv.TrainInd{j,k}) ~= class{i}.groups;
%                         indnan = ~isfinite(newlabel(cv.TrainInd{j,k}));
%                         lb(indpos) = 1; lb(indneg) = -1;
%                         if ~isempty(indnan), lb(indnan) = NaN; end
%                         tclass{i}.TrainLabel{j,k} = lb;
% 
%                         tclass{i}.TestInd{j,k}   = cv.TestInd{j,k};
%                         lb = zeros(size(cv.TestInd{j,k}));
%                         indpos = newlabel(cv.TestInd{j,k}) == class{i}.groups;
%                         indneg = newlabel(cv.TestInd{j,k}) ~= class{i}.groups;
%                         lb(indpos) = 1; lb(indneg) = -1;
%                         tclass{i}.TestLabel{j,k} = lb;
% 
%                     case 9 % Multi-group
% 
%                         tclass.TrainInd{j,k}  = cv.TrainInd{j,k};
%                         tclass.TestInd{j,k}   = cv.TestInd{j,k};
%                         tclass.TrainLabel{j,k} = newlabel(cv.TrainInd{j,k});
%                         tclass.TestLabel{j,k} = newlabel(cv.TestInd{j,k});
%                 end
%             end
