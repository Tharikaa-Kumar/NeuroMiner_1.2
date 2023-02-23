function [ ALTLAB, act ] = nk_Label_config(ALTLAB, defaultsfl)
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
                newgroupnames = nk_input('Groupnames (as vector, no numeric names)',0,'e',[],size(newgroupsN,1));

                if isfield(NM, 'cv')
                    cv_ok = check_CV_class(NM.cv, NM.cases, newlabel, newgroups);
                    if ~cv_ok 
                        altlabflag = 0;
                        newlabel = 'define different label';
                        newlabelname = 'no name defined';
                        newmode = NM.modeflag;
                    end
                end

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
  





