function [Y_interpreted, Y_predictions, Px] = nkdev_MakeTransparent(Y, L, IN, Px)
% =================================================================================
% function [Y_interpreted, Y_predictions, Px] = nkdev_MakeTransparent(Y, L, IN, Px)
% =================================================================================
% Y :   the data matrix to work with (e.g., NM.Y{1})
% L :   the label vector (e.g., [1 -1])
% IN :  the parameters required to rune the script (more or less
%       self-explaining, see below)
% Px :  The models generated in a previous run to compare different
%       parameter settings for the model interpretation
% =================================================================================
global SVM

if ~isfield(IN, 'RAND') || isempty(IN.RAND)
	% Setup permutation parameters
	RAND.OuterPerm = 1;
	RAND.InnerPerm = 1;
	RAND.OuterFold = 5;
	RAND.InnerFold = 5;
	RAND.Decompose = 1;
else
    RAND = IN.RAND;
end

if ~isfield(IN, 'verbose') || isempty(IN.verbose)
    verbose = true;
else
    verbose = IN.verbose;
end

if ~isfield(IN, 'SCALEMODE') || isempty(IN.SCALEMODE)
    SCALEMODE = 'scale';
else
    SCALEMODE = IN.SCALEMODE;
end

if ~isfield(IN, 'DRMODE') || isempty(IN.DRMODE)
    DRMODE = [];
else
    DRMODE = IN.DRMODE;
end

if ~isfield(IN,'algorithm') || isempty(IN.algorithm)
	algorithm = 'LINKERNSVM';
else
    algorithm = IN.algorithm;
end

if ~isfield(IN, 'upper_thresh') || isempty(IN.upper_thresh)
    IN.upper_thresh = 95;
end

if ~isfield(IN, 'lower_thresh') || isempty(IN.lower_thresh)
    IN.lower_thresh = 5;
end

if ~isfield(IN, 'nperms') || isempty(IN.nperms)
    IN.nperms = 1000;
end

if ~isfield(IN, 'frac') || isempty(IN.frac)
    IN.frac = .1;
end

if isinf(IN.nperms)
    if ~isfield(IN,'n_visited'), IN.n_visited = 5; end
    if ~isfield(IN,'max_iter'), IN.max_iter = 5000; end
else
    IN.n_visited = 0;
end

if ~isfield(IN,'saveparam') || isempty(IN.saveparam)
    saveparam = false;
else
    saveparam = IN.saveparam;
end

useparam = false;
if exist('Px','var') && ~isempty(Px)
    useparam = true;
end

% Define algorithm to use for the simulation
LIBSVMTRAIN = @svmtrain312;
LIBSVMPREDICT = @svmpredict312;

switch algorithm
	case 'LINKERNSVM'
		SVM.prog = 'LIBSVM';
		SVM.(SVM.prog).Weighting = 1;
		SVM.(SVM.prog).Optimization.b = 0;
		SCALEMODE = 'scale';
	case 'LINSVM'
		SVM.prog = 'LIBLIN';
		SVM.(SVM.prog).b = 0;
		SVM.(SVM.prog).classifier = 3;
        SVM.(SVM.prog).tolerance = 0.01;
		CMDSTR.WeightFact = 1;
		SCALEMODE = 'std';
	case 'L2LR'
		SVM.prog = 'LIBLIN';
		SVM.(SVM.prog).b = 0;
		SVM.(SVM.prog).classifier = 0;
        SVM.(SVM.prog).tolerance = 0.01;
		CMDSTR.WeightFact = 1;
		SCALEMODE = 'std';
	case 'L1SVC'
		SVM.prog = 'LIBLIN';
		SVM.(SVM.prog).b = 0;
		SVM.(SVM.prog).classifier = 5;
        SVM.(SVM.prog).tolerance = 0.01;
		SCALEMODE = 'std';
    case 'L1LR'
		SVM.prog = 'LIBLIN';
		SVM.(SVM.prog).b = 0;
		SVM.(SVM.prog).classifier = 6;
        SVM.(SVM.prog).tolerance = 0.01;
		SCALEMODE = 'std';
	case 'RF' % not implemented yet
end

% We basically always want to weight the decision boundary
SVM.(SVM.prog).Weighting = 1;
CMDSTR.WeightFact = 1;

% At the moment only binary classification is supported 
MODEFL = 'classification';

% We want to repeat this ten times for producing more stable results
reps = 10;
pCV = RAND.OuterPerm;
nCV = RAND.OuterFold;
R = zeros(reps,pCV*nCV);

xSVM = SVM;
Lx = L; Lx(L==-1) = 2;
if useparam && isfield(Px,'cv')
    cv = Px.cv;
else
    cv = nk_MakeCrossFolds(Lx, RAND, 'classification', [], {'A','B'} );
end
ncm = any(isnan(Y(:)));
Y_interpreted = zeros(size(Y));
Y_predictions = zeros(size(Y,1),1);
for j=1:pCV
	
	% We could use here a multi-core to parallelize the CV cycle
    for i=1:nCV
        
        Tr = cv.TrainInd{j,i};
        Ts = cv.TestInd{j,i};					
		Lr = L(Tr);
        Ls = L(Ts);
        W = ones(numel(Lr),1);

        %% Scaling / standardization 
		switch SCALEMODE
			case 'scale'
                if verbose, fprintf('\nScale data matrix.'); end
                if ~useparam 
    				[Tr_Y, IN_1] = nk_PerfScaleObj(Y(Tr,:)); % Train scaling model
                else
                    IN_1 = Px.IN_1{j,i};
                    Tr_Y = nk_PerfScaleObj(Y(Tr,:), IN_1); 
                end
				Ts_Y = nk_PerfScaleObj(Y(Ts,:), IN_1); % Apply it to the test data
			case 'std'
                if verbose, fprintf('\nStandardize data matrix.'); end
                if ~useparam
				    [Tr_Y, IN_1] = nk_PerfStandardizeObj(Y(Tr,:)); % Train standardization model
                else
                    IN_1 = Px.IN_1{j,i};
                    Tr_Y = nk_PerfStandardizeObj(Y(Tr,:), IN_1); 
                end
				Ts_Y = nk_PerfStandardizeObj(Y(Ts,:), IN_1); % Apply it to the test data
        end
        
        %% Imputation
        if ncm
            if verbose, fprintf('\nImpute data matrix.'); end
            if ~useparam
                [Tr_Y, IN_2] = nk_PerfImputeObj(Tr_Y); % Train imputation model
            else
                IN_2 = Px.IN_2{j,i};
                Tr_Y = nk_PerfImputeObj(Tr_Y,IN_2); 
            end
            Ts_Y = nk_PerfImputeObj(Ts_Y, IN_2); % Apply it to the test data
        else
            IN_2 = [];
        end
        
        %% Dimensionality reduction
        if ~isempty(DRMODE)
            if verbose, fprintf('\nReduce data matrix using %s.', DRMODE.DR.RedMode); end
            if ~useparam
                [map_Tr_Y, IN_3] = nk_PerfRedObj(Tr_Y, DRMODE); % Train dimensionality reduction model
            else
                IN_3 = Px.IN_3{j,i};
                map_Tr_Y = nk_PerfRedObj(Tr_Y, IN_3);
            end
            map_Ts_Y = nk_PerfRedObj(Ts_Y, IN_3); % Train dimensionality reduction model
        end

        if ~useparam
            switch algorithm
                case 'LINKERNSVM'
                    % standard LIBSVM params:
                    cmd = '-s 0 -t 0 -c 1';
                    % set weighting!
                    cmd = nk_SetWeightStr(xSVM, MODEFL, CMDSTR, Lr, cmd);
                    % Train model
                    model = LIBSVMTRAIN(W, Lr, map_Tr_Y, cmd);
                   
                case {'LINSVM', 'L2LR', 'L1LR', 'L1SVC'}
                    %Define command string
                    cmd = nk_DefineCmdStr(xSVM, MODEFL); 
                    cmd = [ ' -c 1' cmd.simplemodel cmd.quiet ];
                    % set weighting!
                    cmd = nk_SetWeightStr(xSVM, MODEFL, CMDSTR, Lr, cmd);
                    % Train model
                    model = train_liblin244(Lr, sparse(map_Tr_Y), cmd);
            end
        else
            model = Px.IN_4{j,i};
        end
        
        %% Predict data
        switch algorithm
            case  'LINKERNSVM'
                 [ ~, ~, Ts_Y_predict ] = LIBSVMPREDICT( Ls, map_Ts_Y, model, sprintf(' -b %g',xSVM.LIBSVM.Optimization.b) );
                 
            case {'LINSVM', 'L2LR', 'L1LR', 'L1SVC'}
                 [ ~, ~, Ts_Y_predict ] = predict_liblin244( Ls, sparse(map_Ts_Y), model, sprintf(' -b %g -q',xSVM.LIBLIN.b) ); 
                 Ts_Y_predict = Ts_Y_predict(:,1);
        end

        Ts_Y_map = zeros(size(Ts_Y));

        % Loop through test cases
        for h=1:numel(Ts)
            
            fprintf('.')
            
            % Create modified instances of current case
            if verbose, fprintf('\nCreate artificial data matrix of subject %g.', Ts(h)); end
            if isfield(IN,'MAP')
                IN.MAP.map = model.w/norm(model.w,2);
            end
            switch IN.method
                case 'posneg'
                    [h_Ts_Y_pos, h_Ts_Y_neg, h_Idx] = nkdev_CreateData4ModelInterpreterPosNeg(Tr_Y, Ts_Y(h,:), IN, IN_3); 
                    fprintf(' ... average no. of feature visits = %1.1f, %g features per iteration', mean(sum(h_Idx)), mean(sum(h_Idx,2)));
                    
                    % Label of current case
                    h_Ls = repmat(Ls(h,:), size(h_Ts_Y_pos,1),1);
                    
                    % Dimensionality reduction
                    if ~isempty(DRMODE)
                        if verbose, fprintf('\nReduce artificial data matrix of subject %g using %s.', Ts(h), DRMODE.DR.RedMode); end
                        h_map_Ts_Y_pos = nk_PerfRedObj(h_Ts_Y_pos, IN_3);
                        h_map_Ts_Y_neg = nk_PerfRedObj(h_Ts_Y_neg, IN_3);
                    end

                    % Apply algorithm to all artificial instances of current case
                    if verbose, fprintf('\nGenerate predictions from artificial data matrix of subject %g using %s.', Ts(h), algorithm); end
                    switch algorithm
                        case  'LINKERNSVM'
                             [ ~, ~, h_ds_pos ] = LIBSVMPREDICT( h_Ls, h_map_Ts_Y_pos, model, sprintf(' -b %g',xSVM.LIBSVM.Optimization.b) );
                             [ ~, ~, h_ds_neg ] = LIBSVMPREDICT( h_Ls, h_map_Ts_Y_neg, model, sprintf(' -b %g',xSVM.LIBSVM.Optimization.b) );
                        case {'LINSVM', 'L2LR', 'L1LR', 'L1SVC'}
                             [ ~, ~, h_ds_pos ] = predict_liblin244( h_Ls, sparse(h_map_Ts_Y_pos), model, sprintf(' -b %g -q',xSVM.LIBLIN.b) ); 
                             [ ~, ~, h_ds_neg ] = predict_liblin244( h_Ls, sparse(h_map_Ts_Y_neg), model, sprintf(' -b %g -q',xSVM.LIBLIN.b) ); 
                             h_ds_pos = h_ds_pos(:,1);
                             h_ds_neg = h_ds_neg(:,1);
                    end
                    fprintf('+')
            
                    % Analyze model's predictions for current case
                    Ts_Y_map(h,:) = nkdev_MapModelPredictionsPosNeg(Ts_Y_predict(h), [h_ds_pos h_ds_neg], h_Idx);

                case 'median'

                    [h_Ts_Y_median, h_Idx] = nkdev_CreateData4ModelInterpreterMedian(Tr_Y, Ts_Y(h,:), IN, IN_3); 
                    fprintf(' ... average no. of feature visits = %1.1f, %g features per iteration', mean(sum(h_Idx)), mean(sum(h_Idx,2)));
                    
                    % Label of current case
                    h_Ls = repmat(Ls(h,:), size(h_Ts_Y_median,1),1);
                    
                    % Dimensionality reduction
                    if ~isempty(DRMODE)
                        if verbose, fprintf('\nReduce artificial data matrix of subject %g using %s.', Ts(h), DRMODE.DR.RedMode); end
                        h_map_Ts_Y_median = nk_PerfRedObj(h_Ts_Y_median, IN_3);
                    end

                    % Apply algorithm to all artificial instances of current case
                    if verbose, fprintf('\nGenerate predictions from artificial data matrix of subject %g using %s.', Ts(h), algorithm); end
                    switch algorithm
                        case  'LINKERNSVM'
                             [ ~, ~, h_ds_median ] = LIBSVMPREDICT( h_Ls, h_map_Ts_Y_median, model, sprintf(' -b %g',xSVM.LIBSVM.Optimization.b) );                            
                        case {'LINSVM', 'L2LR', 'L1LR', 'L1SVC'}
                             [ ~, ~, h_ds_median ] = predict_liblin244( h_Ls, sparse(h_map_Ts_Y_median), model, sprintf(' -b %g -q',xSVM.LIBLIN.b) ); 
                             h_ds_median = h_ds_median(:,1);
                    end
                    fprintf('+')
            
                    % Analyze model's predictions for current case
                    Ts_Y_map(h,:) = nkdev_MapModelPredictionsMedian(Ts_Y_predict(h), h_ds_median, h_Idx);
            end
            if isfield(IN,'brainmask')
                nk_WriteVol(Ts_Y_map(h,:),sprintf('Subject_%g_interpretedZ',Ts(h)),1,IN.brainmask,IN.badcoords,0,'gt');
            end
        end

        Y_interpreted(Ts,:) = Y_interpreted(Ts,:) + Ts_Y_map;
        Y_predictions(Ts) = Y_predictions(Ts) + Ts_Y_predict;

        if saveparam
            Px.cv = cv;
            Px.IN_1{j,i} = IN_1;
            Px.IN_2{j,i} = IN_2;
            Px.IN_3{j,i} = IN_3;
            Px.IN_4{j,i} = model;
        end
    end
end
Y_interpreted = Y_interpreted/pCV;
Y_predictions = Y_predictions/pCV;
