# This script evaluates the model with leave out grid cells of various sizes


# define an evaluation function 
def r2_rmse(g):
    r2 = np.corrcoef(g['ET'], g['ET_pred'])[0,1]**2
    r2_score = metrics.r2_score(g['ET'], g['ET_pred'])
    rmse = np.sqrt(metrics.mean_squared_error(g['ET'], g['ET_pred']))
    count = g.shape[0]
    return pd.Series(dict(r2 = r2, r2_score = r2_score, rmse = rmse, count = count))