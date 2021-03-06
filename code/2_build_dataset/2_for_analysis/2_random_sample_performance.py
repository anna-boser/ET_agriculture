# This script takes random samples of the counterfactual dataset and tests the performance of the sklearn RF
# after leaving out a random 20% of the data. 

# It saves /data/for_analysis/sample_cv_gs//sklearn_frac_eval.csv
# Which is a dataframe of the overall r2, rmse, and r2_score for different fractions of the data. 

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
import time

outpath = str(here("./data/for_analysis/sample_cv_gs_mm/"))
fracs = [.00001, .0001, .001, .01, .1, 1] 
samples = {} #dictionary of subsamples

if not os.path.exists(outpath):
    os.makedirs(outpath)

    # read in dataset
    dataset = pd.read_csv(str(here("./data/for_analysis/counterfactual_cv_gs_mm.csv")))
    dataset = dataset.query('ET >= 0') # remove missing data
    dataset.head()
    
    for frac in fracs: # make and save subsets for each frac
        samples[frac] = dataset.sample(frac = frac)
        samples[frac].to_csv(outpath+"/sample"+str(frac)+".csv", index=False)
else:
    for frac in fracs: # read in subsets for each frac   
        samples[frac] = pd.read_csv(outpath+"/sample"+str(frac)+".csv")
        
        
outpath = str(here("./data/for_analysis/regressor_validation_cv_gs_mm/"))
if not os.path.exists(outpath):
    os.makedirs(outpath)
    
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
    regressor = RandomForestRegressor(n_estimators=100, random_state=0, verbose=True, n_jobs=-1) # I stick with the default recommended 100 trees in my forest
    start = time.time() # time how long it takes to train
    print("regressr fitting", flush=True)
    regressor.fit(X_train, y_train)
    end = time.time()
    print("regressr fit", flush=True)
    
    # predict y 
    y_pred = regressor.predict(X_test)
    print("predictions calculated", flush=True)
    
    # evaluate
    random_test = pd.DataFrame({'frac' : [frac], 
                   'r2' : [np.corrcoef(y_test, y_pred)[0,1]**2],
                   'r2_score' : [metrics.r2_score(y_test, y_pred)], 
                   'rmse' : [np.sqrt(metrics.mean_squared_error(y_test, y_pred))],
                   'train_time' : [end-start]})
    print(random_test, flush=True)
    random_split_eval.append(random_test)

    #pickle the trained regressor
    with open(outpath+"regressor"+str(frac)+".pkl", 'wb') as f:
        pickle.dump(regressor, f)
    print("pickle completed; prediction beginning", flush=True)

random_split_eval = pd.concat(random_split_eval, axis=0)
print(random_split_eval, flush = True)
    
random_split_eval.to_csv(outpath+"/sklearn_frac_eval.csv", index=False)
