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

# choose the dataset size to continue working with
dataset = pd.read_csv(outpath+"/sample"+str(.001)+".csv")

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
    regressor.fit(X_train, y_train)
    y_pred = regressor.predict(X_test)

    # cv_fold = np.repeat(df.loc[test_idx]['cv_fold'].iloc[0], X_test.shape[0])
    df_to_append = pd.DataFrame({# 'cv_fold': cv_fold, 
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

test_stats = pd.concat([spatial_cv])
print(test_stats)

# save this df
test_stats.to_csv(str(here("./data/for_analysis/sklearn_RF_validation_stats_1x1.csv")), index=False)

# grouped by month, get r2, rmse, and count
cv_stats_by_month = cv_df.groupby('monthgroup').apply(r2_rmse).reset_index()
cv_stats_by_month["fold_type"] = "spatial_cv"

# concat
test_stats_by_month = pd.concat([cv_stats_by_month])
print(test_stats_by_month)

# save 
test_stats_by_month.to_csv(str(here("./data/for_analysis/sklearn_RF_test_stats_by_month_1x1.csv")), index=False)

