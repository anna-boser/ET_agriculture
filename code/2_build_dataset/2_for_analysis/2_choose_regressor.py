import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn import metrics
from sklearn.model_selection import GroupKFold
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import RandomizedSearchCV
# import lightgbm as lgb
from pyprojroot import here
import math
import gc
import pickle
import os

# break dataset into .001, .01, .1. 
# if you don't have subsamples of the dataset, make them, otherwise, load them

outpath = str(here("./data/for_analysis/sample/"))
fracs = [.00001, .0001, .001, .01, .1, 1] # I should add the full dataset as an option
samples = {} #dictionary of subsamples

if not os.path.exists(outpath):
    os.makedirs(outpath)

    # read in dataset
    dataset = pd.read_csv(str(here("./data/for_analysis/counterfactual.csv")))
    dataset = dataset.query('ET >= 0') # remove missing data
    dataset.head()
    
    for frac in fracs: # make and save subsets for each frac
        samples[frac] = dataset.sample(frac = frac)
        samples[frac].to_csv(outpath+"/sample"+str(frac)+".csv", index=False)
else:
    for frac in fracs: # read in subsets for each frac   
        samples[frac] = pd.read_csv(outpath+"/sample"+str(frac)+".csv")
        

# train a rf on all sizes of data. 

random_split_eval = []

for frac in fracs: 
    
    dataset = samples[frac]
    
    # split between predictors and predicted
    X = dataset.iloc[:, 0:(dataset.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
    # I might want to eventually redefine dates as times of year to make the actual year not matter

    y = dataset.iloc[:, (dataset.shape[1]-1)].values # Predict ET
    # print(X)

    # make train test split for a random (not spatial) hold out validation
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=0) # random state is for reproducibility to consistently get the same random shuffle

    # build the regressor
    regressor = RandomForestRegressor(n_estimators=100, random_state=0) # I stick with the default recommended 100 trees in my forest
    regressor.fit(X_train, y_train)
    
    # predict y 
    y_pred = regressor.predict(X_test)
    
    # evaluate
    random_test = pd.DataFrame({'frac' : [frac], 
                   'r2' : [np.corrcoef(y_test, y_pred)[0,1]**2],
                   'r2_score' : [metrics.r2_score(y_test, y_pred)], 
                   'rmse' : [np.sqrt(metrics.mean_squared_error(y_test, y_pred))]})
    random_split_eval.append(random_test)

random_split_eval = pd.concat(random_split_eval, axis=0)
print(random_split_eval)
    
random_split_eval.to_csv(str(here("./data/for_analysis/sklearn_frac_eval.csv")), index=False)

# choose the dataset size to continue working with
dataset = samples[.001]
del samples

# split between predictors and predicted
X = dataset.iloc[:, 0:(dataset.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
# I might want to eventually redefine dates as times of year to make the actual year not matter

y = dataset.iloc[:, (dataset.shape[1]-1)].values # Predict ET
# print(X)

# make train test split for a random (not spatial) hold out validation
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=0) # random state is for reproducibility to consistently get the same random shuffle

# define an evaluation function 
def r2_rmse(g):
    r2 = np.corrcoef(g['ET'], g['ET_pred'])[0,1]**2
    r2_score = metrics.r2_score(g['ET'], g['ET_pred'])
    rmse = np.sqrt(metrics.mean_squared_error(g['ET'], g['ET_pred']))
    count = g.shape[0]
    return pd.Series(dict(r2 = r2, r2_score = r2_score, rmse = rmse, count = count))

# try to improve the RF by tuning hyperparameters
# see: https://towardsdatascience.com/hyperparameter-tuning-the-random-forest-in-python-using-scikit-learn-28d2aa77dd74

# Number of trees in random forest
n_estimators = [int(x) for x in np.linspace(start = 100, stop = 2000, num = 10)]
# Number of features to consider at every split
max_features = ['auto', 'sqrt']
# Maximum number of levels in tree
max_depth = [int(x) for x in np.linspace(10, 110, num = 11)]
max_depth.append(None)
# Minimum number of samples required to split a node
min_samples_split = [2, 5, 10]
# Minimum number of samples required at each leaf node
min_samples_leaf = [1, 2, 4]
# Method of selecting samples for training each tree
bootstrap = [True, False]

# Create the random grid
random_grid = {'n_estimators': n_estimators,
               'max_features': max_features,
               'max_depth': max_depth,
               'min_samples_split': min_samples_split,
               'min_samples_leaf': min_samples_leaf,
               'bootstrap': bootstrap}

# Use the random grid to search for best hyperparameters

# First create the base model to tune
rf = RandomForestRegressor()
# Random search of parameters, using 3 fold cross validation, 
# search across 100 different combinations, and use all available cores
rf_random = RandomizedSearchCV(estimator = rf, param_distributions = random_grid, n_iter = 100, cv = 3, verbose=2, random_state=42, n_jobs = -1)
# Fit the random search model
rf_random.fit(X_train, y_train)

# We can view the best parameters from fitting the random search
print(rf_random.best_params_)

# evaluate this improved RF
# predict y 
y_pred = rf_random.predict(X_test)

# evaluate
# random_test = dict(val_type = 'random_test', 
#                    r2 = np.corrcoef(y_test, y_pred)[0,1]**2,
#                    r2_score = metrics.r2_score(y_test, y_pred), 
#                    rmse = np.sqrt(metrics.mean_squared_error(y_test, y_pred)))

# make a df with monthgroup, y, and pred
df_rand_eval = pd.DataFrame({'monthgroup': X_test[:,dataset.columns.get_loc('monthgroup')], 
                             'ET':y_test, 
                             'ET_pred': y_pred})

# evaluate
random_test = pd.DataFrame(r2_rmse(df_rand_eval)).transpose()
random_test["fold_type"] = "random_test"
print(random_test)

# evaluate by monthgroup
random_test_by_month = df_rand_eval.groupby(['monthgroup']).apply(r2_rmse).reset_index()
random_test_by_month["fold_type"] = "random_test"
print(random_test_by_month)

# To do this I first generate an extra column for my dataset called cv_fold which corresponds to its location
dataset = dataset.assign(cv_fold = lambda x: x.x.apply(math.floor)*1000 + x.y.apply(math.floor))

# crossvalidate and make crossvalidation dataset

df = dataset
del dataset

# elect the best model to try validating by location

n_fold = len(set(df['cv_fold'])) # set is same as unique function in R
kf = GroupKFold(n_fold)
split = kf.split(df, groups = df['cv_fold'])

cv_df = pd.DataFrame()

for i, (train_idx, test_idx) in enumerate(split):
    print(f'Starting training fold {i + 1} of {n_fold}.')
    _ = gc.collect()

    X_train = X[train_idx,:]
    X_test = X[test_idx,:]
    y_train = y[train_idx]
    y_test = y[test_idx]

    regressor = RandomForestRegressor(random_state=0) 
    regressor.set_params(**rf_random.best_params_) # use the parameters from the randomized search
    regressor.fit(X_train, y_train)
    y_pred = regressor.predict(X_test)

    cv_fold = np.repeat(df.loc[test_idx]['cv_fold'].iloc[0], X_test.shape[0])
    df_to_append = pd.DataFrame({'cv_fold': cv_fold, 
                                 'monthgroup': X_test[:,df.columns.get_loc('monthgroup')], 
                                 'ET': y_test, 
                                 'ET_pred': y_pred})

    cv_df = cv_df.append(df_to_append, ignore_index = True)

print("Done!!")

# save the full predictions using the spatial CV
cv_df.to_csv(str(here("./data/for_analysis/sklearn_RF_full_cv_outputs_1x1.csv")), index=False)

# evaluate

# get r2, rmse, and count by cv_fold
cv_stats = cv_df.groupby('cv_fold').apply(r2_rmse).reset_index()

# save this df
cv_stats.to_csv(str(here("./data/for_analysis/sklearn_RF_cv_fold_stats_1x1.csv")), index=False)

# make a df for general stats for both the spatial cv and the random 20% test
spatial_cv = pd.DataFrame(r2_rmse(cv_df)).transpose()
spatial_cv["fold_type"] = "spatial_cv"

test_stats = pd.concat([spatial_cv, random_test])
print(test_stats)

# save this df
test_stats.to_csv(str(here("./data/for_analysis/sklearn_RF_validation_stats_1x1.csv")), index=False)

# grouped by month, get r2, rmse, and count
cv_stats_by_month = cv_df.groupby('monthgroup').apply(r2_rmse).reset_index()
cv_stats_by_month["fold_type"] = "spatial_cv"

# concat
test_stats_by_month = pd.concat([cv_stats_by_month, random_test_by_month])
print(test_stats_by_month)

# save 
test_stats_by_month.to_csv(str(here("./data/for_analysis/sklearn_RF_test_stats_by_month_1x1.csv")), index=False)

