# -*- coding: utf-8 -*-
"""
Created on Mon Nov  6 22:38:09 2017

@author: Guillaume
"""

### Imports de librairies
#########################

import pandas as pd
from sklearn import cross_validation, preprocessing, ensemble
from sklearn.metrics import mean_squared_error
from math import sqrt
import os
import matplotlib.pyplot as plt
import numpy as np

### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

def preprocess_df(df,var_dropped,drop_na=True):
    processed_df = df.copy()
    le = preprocessing.LabelEncoder()
    processed_df.mois = le.fit_transform(processed_df.mois)
    processed_df = processed_df.drop(var_dropped,axis=1)
    if drop_na :
        processed_df = processed_df.dropna()
    return processed_df

### Corps principal du script
#############################

file = 'data_agg_sep/'+os.listdir('data_agg_sep')[0]
train = read_df(file)
var_dropped_train = ['date','insee','Unnamed: 0','Unnamed: 0.1','flir1SOL0','flvis1SOL0','fllat1SOL0','flsen1SOL0','rr1SOL0']
var_dropped_train2 = ['date','insee','Unnamed: 0','Unnamed: 0.1','rr1SOL0']
processed_df = preprocess_df(train,var_dropped_train2,drop_na=True)
X = processed_df.drop(['tH2_obs'], axis=1).values
y = processed_df['tH2_obs'].values
X_train, X_test, y_train, y_test = cross_validation.train_test_split(X,y,test_size=0.33)
params = {'n_estimators': 1500, 'min_samples_split': 2, 'loss': 'ls', 'learning_rate' : 0.05, 'max_depth' : 10, 'subsample': 0.5}
clf = ensemble.GradientBoostingRegressor(**params)
mod = clf.fit(X_train, y_train)
pred = mod.predict(X_test)
rmse = sqrt(mean_squared_error(y_test, pred))
print(rmse)

# #############################################################################
# Plot feature importance
feature_importance = clf.feature_importances_
# make importances relative to max importance
feature_importance = 100.0 * (feature_importance / feature_importance.max())
sorted_idx = np.argsort(feature_importance)
pos = np.arange(sorted_idx.shape[0]) + .5
plt.figure(figsize=(12, 6))
plt.barh(pos, feature_importance[sorted_idx], align='center')
plt.yticks(pos, processed_df.feature_names[sorted_idx])
plt.xlabel('Relative Importance')
plt.title('Variable Importance')
plt.show()