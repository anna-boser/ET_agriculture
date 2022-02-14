# This script uses sklearn random forest with 100 trees to predict ET for each of our timesteps. 
# We validate the model both with a simple 20% test set and a spatial crossvalidation on 1x1 coordinate degree cells. 
# We then apply the model to generate agriculture_sklearn_RF.csv. 

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn import metrics
from sklearn.model_selection import GroupKFold
from pyprojroot import here
import math
import gc
import pickle

# read in dataset
dataset = pd.read_csv(str(here("./data/for_analysis/counterfactual.csv")))
dataset.head()

# save a random subset of the data in case you want that because the full dataset is enormous
sample = dataset.sample(frac = .01)
sample.to_csv(str(here("./data/for_analysis/counterfactual_sample.csv")), index=False)

# split between predictors and predicted
X = dataset.iloc[:, 0:(dataset.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
# I might want to eventually redefine dates as times of year to make the actual year not matter

y = dataset.iloc[:, (dataset.shape[1]-1)].values # Predict ET
print(X)

# make train test split for a random (not spatial) hold out validation
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=0) # random state is for reproducibility to consistently get the same random shuffle

# build the regressor
regressor = RandomForestRegressor(n_estimators=100, random_state=0) # I stick with the default recommended 100 trees in my forest
regressor.fit(X_train, y_train)

# pickle the regressor
with open(here("./data/for_analysis/sklearn_RF.pkl"), 'wb') as f:
    pickle.dump(regressor, f)

# predict y 
y_pred = regressor.predict(X_test)

# evaluate
random_test = dict(val_type = 'random_test', 
                   r2 = np.corrcoef(y_test.apply(int), y_pred.apply(int))[0,1]**2,
                   r2_score = metrics.r2_score(y_test, y_pred), 
                   rmse = np.sqrt(metrics.mean_squared_error(y_test, y_pred)))

# Read in the ag dataset and predict ET using this regressor
ag = pd.read_csv(str(here("./data/for_analysis/agriculture.csv")))
ag.head()
X = ag.iloc[:, 0:(ag.shape[1]-1)].values # everything, including lat, lon, and date, are predictors. 
ag["ET_pred"] = regressor.predict(X)
ag.to_csv(str(here("./data/for_analysis/agriculture_sklearn_RF.csv")), index=False)

# For a spatially informed split I instead do cross-validation by splitting california into 1 degree lon by 1 degree lat cubes. 

# To do this I first generate an extra column for my dataset called cv_fold which corresponds to its location
dataset = dataset.assign(cv_fold = lambda x: x.x.apply(math.floor)*1000 + x.y.apply(math.floor))

# crossvalidate and make crossvalidation dataset

df = dataset

n_fold = len(set(df['cv_fold'])) # set is same as unique function in R
kf = GroupKFold(n_fold)
split = kf.split(df, groups = df['cv_fold'])

cv_df = pd.DataFrame(columns = ['cv_fold', 'start_date', 'ET', 'ET_pred'])

for i, (train_idx, test_idx) in enumerate(split):
    print(f'Starting training fold {i + 1} of {n_fold}.')
    _ = gc.collect()

    X_train = X[train_idx,:]
    X_test = X[test_idx,:]
    y_train = y[train_idx]
    y_test = y[test_idx]

    regressor = RandomForestRegressor(n_estimators=100, random_state=0) # I stick with the default recommended 100 trees in my forest
    regressor.fit(X_train, y_train)
    y_pred = regressor.predict(X_test)

    cv_fold = np.repeat(df.loc[test_idx]['cv_fold'].iloc[0], X_test.shape[0])
    df_to_append = pd.DataFrame({'cv_fold': cv_fold, 'start_date': X_test[:,df.columns.get_loc('start_date')], 'ET':y_test, 'ET_pred': y_pred})

    cv_df = cv_df.append(df_to_append, ignore_index = True)

print("Done!!")

# save this df
cv_df.to_csv(str(here("./data/for_analysis/sklearn_RF_full_cv_outputs_1x1.csv")), index=False)

# get r2, rmse, and count by cv_fold

def r2_rmse(g):
    r2 = np.corrcoef(g['ET'].apply(int), g['ET_pred'].apply(int))[0,1]**2
    r2_score = metrics.r2_score(g['ET'], g['ET_pred'])
    rmse = np.sqrt(metrics.mean_squared_error(g['ET'], g['ET_pred']))
    count = g.shape[0]
    return pd.Series(dict(r2 = r2, r2_score = r2_score, rmse = rmse, count = count))

cv_stats = cv_df.groupby('cv_fold').apply(r2_rmse).reset_index()

# save this df
cv_stats.to_csv(str(here("./data/for_analysis/sklearn_RF_cv_fold_stats_1x1.csv")), index=False)

# make a df for general stats for both the spatial cv and the random 20% test
spatial_cv = dict(val_type = "spatial_cv", 
                  r2 = np.corrcoef(cv_df['ET'].apply(int), cv_df['ET_pred'].apply(int))[0,1]**2,
                  r2_score = metrics.r2_score(cv_df['ET'], cv_df['ET_pred']), 
                  rmse = np.sqrt(metrics.mean_squared_error(cv_df['ET'], cv_df['ET_pred'])))

test_stats = pd.DataFrame([spatial_cv, random_test])
print(test_stats)

# save this df
test_stats.to_csv(str(here("./data/for_analysis/sklearn_RF_validation_stats_1x1.csv")), index=False)