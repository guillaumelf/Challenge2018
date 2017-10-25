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
from sklearn import datasets, svm, cross_validation, tree, preprocessing, metrics
from sklearn.model_selection import GridSearchCV, cross_val_score, KFold

### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

def preprocess_df(df):
    processed_df = df.copy()
    le = preprocessing.LabelEncoder()
    processed_df.mois = le.fit_transform(processed_df.mois)
    processed_df = processed_df.drop(['date','insee'],axis=1)
    processed_df = processed_df.dropna()
    return processed_df

### Corps principal du script
#############################

'''
On sépare les tâches pour aller plus vite dans l'importation des 36 fichiers csv
'''
e = ThreadPoolExecutor()

# Exemple pour un fichier

'''
Préparation des données
'''

train1 = read_df('data_meteo/train_1.csv')
processed_df = preprocess_df(train1)

X = processed_df.drop(['tH2_obs'], axis=1).values
y = processed_df['tH2_obs'].values

svr_rbf = svm.SVR(kernel='rbf')


'''
Validation croisée Hold Out
'''

X_train, X_test, y_train, y_test = cross_validation.train_test_split(X,y,test_size=0.33)

svr_rbf.fit(X_train, y_train)
svr_rbf.score(X_test, y_test)

'''
Validation croisée 10 blocs
'''
dict_params = {"C": [.01, .1, 1., 10.]}
clf = GridSearchCV(estimator=svm.SVR(kernel='rbf'), param_grid=dict_params, cv=KFold(n_splits=10))
clf.fit(X, y)

print(clf.best_estimator_)





