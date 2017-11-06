# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 19:08:52 2017

@author: Guillaume
"""
### Imports de librairies
###############################################################################

import os
import pandas as pd
from sklearn import ensemble, preprocessing
from sklearn.model_selection import GridSearchCV, KFold

### Définition locale de fonctions
###############################################################################

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

# Corps principal du script
###############################################################################

var_dropped_train = ['date','insee','Unnamed: 0','Unnamed: 0.1','flir1SOL0','flvis1SOL0','fllat1SOL0','flsen1SOL0','rr1SOL0']
var_dropped_test = ['date','insee','Unnamed: 0','flir1SOL0','flvis1SOL0','fllat1SOL0','flsen1SOL0','rr1SOL0']
dict_params = {"max_depth": [6,7,8,9,10],"learning_rate": [0.01,0.05,0.1]}
params = {'n_estimators': 500, 'min_samples_split': 2, 'loss': 'ls', 'subsample': 0.5}
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
    clf = GridSearchCV(estimator=ensemble.GradientBoostingRegressor(**params), param_grid=dict_params, cv=KFold(n_splits=5),refit=True)
    print('Cross validation ongoing... Trying to find the best model for '+villes[i]+'... Be patient !')
    clf.fit(X, y)
    print("Best estimator for "+villes[i]+" :\n {}".format(clf.best_estimator_))
    print("Best score for "+villes[i]+" : %.4f" % clf.best_score_)
    prediction = clf.best_estimator_.predict(processed_test)
    df = pd.DataFrame(prediction)
    filename = 'Results/'+villes[i]+'_results.csv'
    df.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8')
    print("The results for {} have been saved successfully".format(villes[i]))
    
