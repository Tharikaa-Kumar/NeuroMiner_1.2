# trainRFClassifier
# Python script to train a random forest classifier from NeuroMiner

from sklearn.ensemble import RandomForestClassifier
import pickle

# a few categorical arguments need to be 'translated' to fit function
# criterion
if crit == 1:
    crit = 'gini'
elif crit == 2:
    crit = 'log_loss'
elif crit == 3:
    crit = 'entropy'

# max_features
if n_maxfeat == -1:
    n_maxfeat = 'sqrt'
elif n_maxfeat == -2:
    n_maxfeat = 'log2'
elif n_maxfeat == 0:
    n_maxfeat = None

# max_depth
if maxd == 0:
    maxd = None

# min_samples_leaf
if minsl >= 1.0:
    minsl = int(minsl)

# min_samples_split
if minss > 1.0:
    minss = int(minss)

# max_leaf_nodes
if maxln == 0:
    maxln = None

# class_weight
if classw == 0:
    classw = None
elif classw == 1:
    classw = 'balanced'
elif classw == 2:
    classw = 'balanced_subsample'


# max_samples
if maxs == 0:
    maxs = None

rf = RandomForestClassifier(n_estimators = n_est,
        max_features = n_maxfeat,
        criterion = crit,
        max_depth = maxd,
        min_samples_split = minss,
        min_samples_leaf = minsl,
        min_weight_fraction_leaf = minwfl,
        max_leaf_nodes = maxln,
        min_impurity_decrease = minid,
        bootstrap = boot,
        oob_score = oobs,
        class_weight = classw,
        ccp_alpha = ccpa,
        max_samples = maxs
        ) # others: verbose, random_state, warm_start, n_jobs

rf.fit(feat, lab)
model_file = f'{rootdir}/RFC_model_{n_maxfeat}_{crit}_{maxd}_{minss}_{minsl}_{minwfl}_{maxln}_{minid}_{boot}_{oobs}_{classw}_{ccpa}_{maxs}.sav'
pickle.dump(rf, open(model_file, 'wb'))
