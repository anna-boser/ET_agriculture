# This script evaluates the model with leave out grid cells of various sizes

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn import metrics
from sklearn.model_selection import GroupKFold
from sklearn.model_selection import cross_val_predict
# import lightgbm as lgb
from pyprojroot import here
import math
import pickle
import os
import time

hparam = False
inc_xy=False # train with lat and lon as variables or not
inc_y=True # only include lat 

outpath = "/scratch/annaboser/fveg_cv_gs_mm_filtered50010000"
# outpath = str(here("./data/for_analysis/spatial_validation/"))
if not os.path.exists(outpath):
    os.makedirs(outpath)

# load full dataset
df = pd.read_csv(str(here("./data/for_analysis/fveg_cv_gs_mm_filtered50010000.csv")))
# split between predictors and predicted
if inc_xy:
    X = df.iloc[:, 0:(df.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
elif inc_y:
    X = df.iloc[:, 1:(df.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
else:
    X = df.iloc[:, 2:(df.shape[1]-1)].values # everything except lat, lon, and date, are predictors. 
y = df.iloc[:, (df.shape[1]-1)].values # Predict ET
# print(X)

# retrieve the parameters that were generated in 3_hyperparameter_tuning
if hparam==True:
    hyperparameters = pickle.load(open(str(here("./data/for_analysis/hyperparameter_tune/"))+"/model_parameters.pkl", 'rb')) #rb is read mode. 
    print(hyperparameters, flush=True)

# define an evaluation function 
def r2_rmse(g):
    r2 = np.corrcoef(g['ET'], g['ET_pred'])[0,1]**2
    r2_score = metrics.r2_score(g['ET'], g['ET_pred'])
    bias = np.mean(g['ET_pred']) - np.mean(g['ET'])
    rmse = np.sqrt(metrics.mean_squared_error(g['ET'], g['ET_pred']))
    count = g.shape[0]
    return pd.Series(dict(r2 = r2, r2_score = r2_score, rmse = rmse, bias = bias, count = count))

# define a function that performs the spatial split for a given size of cell. 
# Operate on the principle that one degree lat/lon is about 
def spatial_split(dist, df): #, frac=1
    
    # I first generate an extra column for my dataset called cv_fold which corresponds to its location
    
    # 1. Convert to miles to degrees. See: https://www.nhc.noaa.gov/gccalc.shtml
    # 2. Divide by number of degrees
    # 3. Floor operation
    # 4. turn back into coordinates
    # 5. String together
    
    x_size = dist/89000 # 1 degree lon (x) = 89km = 89000m
    y_size = dist/111000 # 1 degree lat (y) = 111km = 111000m
    
    df = df.assign(cv_fold = lambda x: x.x.apply(lambda val: str(math.floor(val/x_size)*x_size)) +","+ x.y.apply(lambda val: str(math.floor(val/y_size)*y_size)))
    print(df.head(), flush=True)

    # How many folds = number of cells or cv_folds
    # n_fold = df.cv_fold.nunique() # set is same as unique function in R
    # print(n_fold, flush=True)
    kf = GroupKFold(5) #leave out 20% of the data at a time
    split = kf.split(df, groups = df['cv_fold'])
    
    regressor = RandomForestRegressor(n_estimators=100, verbose=1, random_state=0, n_jobs = -1) 
    if hparam==True:
        regressor.set_params(**hyperparameters) # use the parameters from the randomized search
    print("predictions beginning", flush=True)
    start = time.time()
    y_pred = cross_val_predict(regressor, X, y, cv=split, verbose=1, n_jobs = -1)
    end = time.time()
    print("predictions completed; time elapsed: "+str(end-start), flush=True)
    cv_df = df.assign(ET_pred=y_pred)

#     cv_df = pd.DataFrame()

#     for i, (train_idx, test_idx) in enumerate(split):
#         print(f'Starting training fold {i + 1} of {n_fold}.')
#         _ = gc.collect()

#         X_train = X[train_idx,:]
#         X_test = X[test_idx,:]
#         y_train = y[train_idx]
#         y_test = y[test_idx]

#         regressor = RandomForestRegressor(random_state=0) 
#         regressor.set_params(**hyperparameters) # use the parameters from the randomized search
#         regressor.fit(X_train, y_train)
#         y_pred = regressor.predict(X_test)

#         cv_fold = np.repeat(df.loc[test_idx]['cv_fold'].iloc[0], X_test.shape[0])
#         df_to_append = pd.DataFrame({'cv_fold': cv_fold, 
#                                      'monthgroup': X_test[:,df.columns.get_loc('monthgroup')], 
#                                      'ET': y_test, 
#                                      'ET_pred': y_pred})

#         cv_df = cv_df.append(df_to_append, ignore_index = True)

    print("Done!!", flush=True)

    # save the full predictions using the spatial CV
    cv_df.to_csv(outpath+"/sklearn_RF_full_cv_outputs_"+str(dist)+".csv", index=False)
    print("full predictions saved", flush=True)

    # evaluate

    # get r2, rmse, and count by cv_fold
    cv_stats = cv_df.groupby('cv_fold').apply(r2_rmse).reset_index()

    # save this df
    cv_stats.to_csv(outpath+"/sklearn_RF_cv_fold_stats_"+str(dist)+".csv", index=False)
    print("evaluation by location saved", flush=True)

    # make a df for general stats for the spatial cv 
    spatial_cv = pd.DataFrame(r2_rmse(cv_df)).transpose()

    # save this df
    spatial_cv.to_csv(outpath+"/sklearn_RF_cv_validation_stats_"+str(dist)+".csv", index=False)
    print("full evaludation saved", flush=True)

    # grouped by month, get r2, rmse, and count
    cv_stats_by_month = cv_df.groupby('monthgroup').apply(r2_rmse).reset_index()

    # save 
    cv_stats_by_month.to_csv(outpath+"/sklearn_RF_cv_test_stats_by_month_"+str(dist)+".csv", index=False)
    print("evaluation by month saved", flush=True)
    
    return
    
    
# call the function for all the different distances you want to test
distances = [30000, 20000, 10000, 5000, 2000, 1000, 1]
for dist in distances: 
    spatial_split(dist, df)