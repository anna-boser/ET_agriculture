# This script takes a subset of the counterfactual dataset and finds better hyperparameters that we will use. 

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

outpath = str(here("./data/for_analysis/hyperparameter_tune/"))
if not os.path.exists(outpath):
    os.makedirs(outpath)

# choose the dataset size to continue working with
dataset = pd.read_csv(str(here("./data/for_analysis/sample_cv_gs/sample0.001.csv")))

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
                      
# Save the parameters to be used in 4_model_validation
with open(outpath+"model_parameters.pkl", 'wb') as f:
    pickle.dump(rf_random.best_params_, f)

# evaluate this improved RF
# predict y 
y_pred = rf_random.predict(X_test)

# make a df with monthgroup, y, and pred
df_rand_eval = pd.DataFrame({'x': X_test[:,dataset.columns.get_loc('x')]
                             'y': X_test[:,dataset.columns.get_loc('y')]
                             'monthgroup': X_test[:,dataset.columns.get_loc('monthgroup')], 
                             'ET':y_test, 
                             'ET_pred': y_pred})
                      
# save the full dataframe of true and predicted for this sample
df_rand_eval.to_csv(outpath+"/full_perdictions.csv", index=False)

# evaluate
random_test = pd.DataFrame(r2_rmse(df_rand_eval)).transpose()
random_test["fold_type"] = "random_test"
print(random_test)
                      
# save
random_test.to_csv(outpath+"/random_test_eval.csv", index=False)

# evaluate by monthgroup
random_test_by_month = df_rand_eval.groupby(['monthgroup']).apply(r2_rmse).reset_index()
random_test_by_month["fold_type"] = "random_test"
print(random_test_by_month)

# save
random_test_by_month.to_csv(outpath+"/random_test_eval_by_month.csv", index=False)