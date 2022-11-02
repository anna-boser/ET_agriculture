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

hparam=False # do you want to use the saved hyperparameters or the default? 
trained_model=False

# Required if trained_model = TRUE. This will use a model trained in the validation stage and generate predictions. This was used in testing. 
# frac=0.1 #model trained on this fraction of the dataset
# trained_model_path=str(here("./data/for_analysis/regressor_validation_cv_gs_mm/"))+"/regressor"+str(frac)+".csv"

# get your training dataset

# Step 1: choose your base. Options: 
# input_base = "fveg_cv_gs_mm"
input_base = "fveg_cv_mm_filtered50010000"
# input_base = "cpad_cv_gs_mm"
# input_base = "counterfactual_cv_gs_mm" #(This is the CDL)
# input_base = "cpad_fveg_cv_gs_mm"
# input_base = "cdl_fveg_cv_gs_mm"

# Step 2: determine cutoff for how large the average ET should be to be excluded for fear that it is irrigated land contaminating the dataset. 
# Options: "", "<4", "<4.5", "<5"
perc_cutoff = "" 

# Step 3: determine if you want lat and lon to be included too
inc_xy=True # train with lat and lon as variables or not
inc_y=False # only include lat 

# Input dataset
input_dataset = str(here("./data/for_analysis/" + input_base + perc_cutoff + ".csv"))

# output file name: 
if trained_model==True:
    if hparam==True:
        output_name ="/ag_counterfactual_hparam"+str(frac)
    else: 
        output_name ="/ag_counterfactual_default"+str(frac)
else: 
    if hparam==True:
        if inc_xy==True:
            output_name ="/ag_counterfactual_hparam" + input_base + perc_cutoff 
        elif inc_y==True:
            output_name ="/ag_counterfactual_hparam" + input_base + perc_cutoff + "_no_x"
        else:
            output_name ="/ag_counterfactual_hparam" + input_base + perc_cutoff + "_no_xy"
    else: 
        if inc_xy==True:
            output_name ="/ag_counterfactual_default" + input_base + perc_cutoff 
        elif inc_y==True:
            output_name ="/ag_counterfactual_default" + input_base + perc_cutoff + "_no_x"
        else:
            output_name ="/ag_counterfactual_default" + input_base + perc_cutoff + "_no_xy"


# outpath = str(here("./data/for_analysis/ag_counterfactual/"))
outpath = "/scratch/annaboser/data/for_analysis/ag_counterfactual/" # save to scratch to avoid running out of space
if not os.path.exists(outpath):
    os.makedirs(outpath)
print(outpath, flush=True)
    
if trained_model==False:
    # First, train the full model
    print("Training model from scratch; loading dataset", flush=True)  

    # load full dataset
    df = pd.read_csv(input_dataset)
    # split between predictors and predicted
    if inc_xy:
        X_train = df.iloc[:, 0:(df.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
    elif inc_y:
        X_train = df.iloc[:, 1:(df.shape[1]-1)].values
    else:
        X_train = df.iloc[:, 2:(df.shape[1]-1)].values # everything except lat, lon, and date, are predictors. 
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
    with open(outpath+"/"+output_name+".pkl", 'wb') as f:
        pickle.dump(regressor, f)
    print("pickle completed; prediction beginning", flush=True)
else: 
    # read the existing model
    print("loading already trained model", flush=True)
    regressor = pickle.load(open(trained_model_path, 'rb')) #rb is read mode. 
    print("model loaded; prediction beginning", flush=True)

# apply the model to agricultural pixels
df = pd.read_csv(str(here("./data/for_analysis/agriculture_cv_gs_mm.csv")))
if inc_xy:
    X_ag = df.iloc[:, 0:(df.shape[1]-1)].values
elif inc_xy:
    X_ag = df.iloc[:, 1:(df.shape[1]-1)].values
else:
    X_ag = df.iloc[:, 2:(df.shape[1]-1)].values
print(X_ag.shape, flush=True)

y_pred = regressor.predict(X_ag)
df = df.assign(ET_pred=y_pred)

# calculate the difference between the actual and counterfactual ET
df['ag_ET'] = df.ET- df.ET_pred
print("prediction completed; saving beginning", flush=True)

# save the new dataset
df.to_csv(outpath+"/"+output_name+".csv", index=False)
