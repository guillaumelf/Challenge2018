# -*- coding: utf-8 -*-
"""
Created on Wed Oct 25 13:53:06 2017

@author: Guillaume
"""

### Imports de librairies
#########################

import pandas as pd
from concurrent.futures import ThreadPoolExecutor
from functools import reduce
from sklearn import cross_validation, preprocessing
from sklearn.svm import SVR
from sklearn.model_selection import GridSearchCV, KFold
from sklearn.metrics import mean_squared_error
from math import sqrt
import numpy as np
import os

### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

def preprocess_df(df):
    processed_df = df.copy()
    le = preprocessing.LabelEncoder()
    processed_df.mois = le.fit_transform(processed_df.mois)
    processed_df = processed_df.drop(['date','insee','Unnamed: 0','Unnamed: 0.1'],axis=1)
    processed_df = processed_df.dropna()
    return processed_df

def concat_data(df1,df2):
    frames = [df1, df2]
    result = pd.concat(frames)
    return(result)

def perform_svm(file):
    file1 = 'data_agg_sep/'+file
    file2 = 'test_sep/'+file
    train1 = read_df(file1)
    test = read_df(file2)
    processed_df = preprocess_df(train1)
    processed_test = preprocess_df(test)
    
    X_train = processed_df.drop(['tH2_obs'], axis=1).values
    y_train = processed_df['tH2_obs'].values
    X_test = processed_test.values

    dict_params = {"C": [0.01,1]}
    clf = GridSearchCV(estimator=SVR(kernel='rbf'), param_grid=dict_params, cv=KFold(n_splits=10),refit=True,n_jobs=4)
    best_mod = clf.best_estimator_
    mod = best_mod.fit(X_train, y_train)
    pred = mod.predict(X_test)
    df = pd.DataFrame(pred)
    return(df)

### Corps principal du script
#############################

#e = ThreadPoolExecutor()
#
#files = os.listdir('data_agg_sep')[0:2]
#mapped_values = e.map(perform_svm, files)
#df = reduce(concat_data,mapped_values)

#rmse = sqrt(mean_squared_error(y_test, pred))
#print(rmse)

file = 'data_agg_sep/'+os.listdir('data_agg_sep')[0]
train1 = read_df(file)
train1 = train1.ix[0:2000]
processed_df = preprocess_df(train1)

X = processed_df.drop(['tH2_obs'], axis=1).values
y = processed_df['tH2_obs'].values
X_train, X_test, y_train, y_test = cross_validation.train_test_split(X,y,test_size=0.2)
#dict_params = {"C": [0.01,1]}
#clf = GridSearchCV(estimator=SVR(kernel='rbf'), param_grid=dict_params, cv=KFold(n_splits=3),refit=True,n_jobs=4)
clf = SVR(C=0.05, epsilon=0.2)
#best_mod = clf.best_estimator_
#mod = best_mod.fit(X_train, y_train)
mod = clf.fit(X_train, y_train)
pred = mod.predict(X_test)
df = pd.DataFrame(pred)
rmse = sqrt(mean_squared_error(y_test, pred))
print(rmse)