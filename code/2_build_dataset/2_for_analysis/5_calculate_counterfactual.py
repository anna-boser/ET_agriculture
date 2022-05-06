# This script trains the model on the entire natural data (counterfactual) dataset 
# It is then applied to the agriculture dataset in order to get the counterfactual :) 

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

hparam=True # do you want to use the saved hyperparameters or the default? 

outpath = str(here("./data/for_analysis/ag_counterfactual/"))
if not os.path.exists(outpath):
    os.makedirs(outpath)
print(outpath, flush=True)
    
# First, train the full model
    
# load full dataset
df = pd.read_csv(str(here("./data/for_analysis/counterfactual_cv_gs_mm.csv")))
# split between predictors and predicted
X_train = df.iloc[:, 0:(df.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
y_train = df.iloc[:, (df.shape[1]-1)].values # Predict ET
# print(X)

regressor = RandomForestRegressor(n_estimators=100, random_state=0, verbose=1, n_jobs = -1) #default 100 trees. n_jobs = -1 to have all cores run in parallel

if hparam==True:
    # retrieve the parameters that were generated in 3_hyperparameter_tuning
    hyperparameters = pickle.load(open(str(here("./data/for_analysis/hyperparameter_tune/"))+"/model_parameters.pkl", 'rb')) #rb is read mode. 
    regressor.set_params(**hyperparameters) # use the parameters from the randomized search
    

print("regressor defined, training beginning", flush=True)
regressor.fit(X_train, y_train)
print("training completed; pickle beginning", flush=True)

# pickle the trained model
with open(outpath+"/regressor.pkl", 'wb') as f:
    pickle.dump(regressor, f)
print("pickle completed; prediction beginning", flush=True)

# apply the model to agricultural pixels
df = pd.read_csv(str(here("./data/for_analysis/agriculture_cv_gs_mm.csv")))
X_ag = df.iloc[:, 0:(df.shape[1]-1)].values

y_pred = regressor.predict(X_test)
df = df.assign(ET_pred=y_pred)

# calculate the difference between the actual and counterfactual ET
df['ag_ET'] = df.ET- df.ET_pred
print("prediction completed; saving beginning", flush=True)

# save the new dataset
if hparam==True:
    df.to_csv(outpath+"/ag_counterfactual_hparam.csv", index=False)
else: 
    df.to_csv(outpath+"/ag_counterfactual_default.csv", index=False)