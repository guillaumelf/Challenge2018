# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 19:08:52 2017

@author: Guillaume
"""
### Imports de librairies
#########################

import numpy as np
import os
import pandas as pd
from sklearn import ensemble, preprocessing, cross_validation
from sklearn.metrics import mean_squared_error

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

###############################################################################
# Généralisation

var_dropped_train = ['date','insee','Unnamed: 0','Unnamed: 0.1','flir1SOL0','flvis1SOL0','fllat1SOL0','flsen1SOL0','rr1SOL0']
var_dropped_test = ['date','insee','Unnamed: 0','flir1SOL0','flvis1SOL0','fllat1SOL0','flsen1SOL0','rr1SOL0']

files = os.listdir('data_agg_sep')
villes = ['Toulouse','Bordeaux','Rennes','Lille','Nice','Strasbourg','Paris']
for i in range(len(files)):
    file = 'data_agg_sep/'+files[i]
    file2 = 'test_sep/'+files[i]
    train = read_df(file)
    test = pd.read_csv(file2, sep=";",decimal=".",encoding="utf-8")
    processed_df = preprocess_df(train,var_dropped_train,drop_na=True)
    processed_test = preprocess_df(test,var_dropped_test,drop_na=False)
    
    X = processed_df.drop(['tH2_obs'], axis=1).values
    y = processed_df['tH2_obs'].values
    X_train, X_test, y_train, y_test = cross_validation.train_test_split(X,y,test_size=0.33)
    
    params = {'n_estimators': 500, 'max_depth': 10, 'min_samples_split': 2,
          'learning_rate': 0.01, 'loss': 'ls'}
    clf = ensemble.GradientBoostingRegressor(**params)
    
    clf.fit(X_train, y_train)
    mse = mean_squared_error(y_test, clf.predict(X_test))
    prediction = clf.predict(processed_test)
    df = pd.DataFrame(prediction)
    print("RMSE "+villes[i]+" : %.4f" % np.sqrt(mse))
    filename = 'Results/'+villes[i]+'_results.csv'
    df.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8')
    print("Le résultat pour {} a bien été sauvegardé".format(villes[i]))
    

#file = 'data_agg_sep/'+files[0]
#train = read_df(file)
#processed_df = preprocess_df(train,var_dropped_train,drop_na=True)
#X = processed_df.drop(['tH2_obs'], axis=1).values
#y = processed_df['tH2_obs'].values
#X_train, X_test, y_train, y_test = cross_validation.train_test_split(X,y,test_size=0.33)
#print(X_train)
#np.sum(np.isnan(X_train))
#file2 = 'test_sep/'+files[0]
#test = pd.read_csv(file2, sep=";",decimal=".",encoding="utf-8")
#processed_test = preprocess_df(test,var_dropped_test,drop_na=False)
#print(processed_test)
#np.sum(np.isnan(processed_test))
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
