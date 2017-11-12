# -*- coding: utf-8 -*-
"""
Created on Sat Nov 11 15:04:24 2017

@author: Guillaume
"""

from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn import ensemble
from sklearn.neighbors import KNeighborsRegressor
import pandas as pd
from math import sqrt
from concurrent.futures import ThreadPoolExecutor
from functools import reduce, partial
import numpy as np

### Définition locale de fonctions
###############################################################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

def preprocess_df(df,var_dropped=None,replacement=None,drop_na=True):
    processed_df = df.copy()
    if replacement is not None :
        processed_df['mois'].replace(replacement, inplace=True)
    processed_df['insee'] = processed_df['insee'].astype('category')
    processed_df['ddH10_rose4'] = processed_df['ddH10_rose4'].astype('category')
    processed_df['ech'] = processed_df['ech'].astype('category')
    processed_df['mois'] = processed_df['mois'].astype('category')
    processed_df['flvis1SOL0'] = processed_df['flvis1SOL0'].astype('float64')
    if var_dropped is not None:
        processed_df = processed_df.drop(var_dropped,axis=1)
    if drop_na :
        processed_df = processed_df.dropna()
    return processed_df

def get_score(var,df,regressor,params=None):
    if __name__ == '__main__':
        X = df.drop([var], axis=1).values
        y = df[var].values
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=(1/3), random_state=0)
        Regressor = regressor(**params)
        reg = Regressor.fit(X_train, y_train)
        pred = reg.predict(X_test)
        rmse = sqrt(abs(mean_squared_error(y_test,pred)))
        return([rmse])
    
def get_score_bis(var,df1,df2):
    y = df1[var].values
    pred = df2[var].values
    msk = np.random.rand(len(df2)) < (2/3)
    y_test, pred_test = y[~msk], pred[~msk]
    rmse = sqrt(abs(mean_squared_error(y_test,pred_test)))
    return([rmse])
    
def add_list(v1,v2):
    liste = v1 + v2
    return(liste)

### Corps principal du script
###############################################################################

e = ThreadPoolExecutor()

##############
# Pré-requis #
##############

train = read_df('data_meteo/data_agregated.csv')
dico_transfo = {'janvier': 1,'février': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'août': 8,'septembre': 9,'octobre': 10,'novembre': 11,'décembre': 12}
processed_df = preprocess_df(train,var_dropped=['Unnamed: 0','date'],replacement=dico_transfo)
quanti = processed_df.select_dtypes(include=['float64'])
quali = processed_df.select_dtypes(exclude=['float64'])
new_quali = pd.get_dummies(quali)
df2 = pd.concat([quanti, new_quali], axis=1)
names_list = list(quanti)

############################
# Random Forest imputation #
############################

regressor = ensemble.RandomForestRegressor
params = {'n_estimators': 50, 'bootstrap': True, 'n_jobs': -1}
mapped_values = e.map(partial(get_score, df=processed_df,regressor=regressor,params=params), names_list)
rmse_rf = reduce(add_list,mapped_values)

##################
# KNN imputation #
##################

regressor = KNeighborsRegressor
params = {'n_neighbors': 10, 'n_jobs': -1}
mapped_values = e.map(partial(get_score, df=df2,regressor=regressor,params=params), names_list)
rmse_knn = reduce(add_list,mapped_values)

############################
# Mean variable imputation #
############################

res_mean = quanti.apply(np.mean,axis=0)
lst = []
for i in range(quanti.shape[0]):
    lst.append(tuple(res_mean))
mean_df = pd.DataFrame.from_records(lst,columns=names_list)
mapped_values = e.map(partial(get_score_bis, df1=quanti, df2=mean_df), names_list)
rmse_mean = reduce(add_list,mapped_values)

##############################
# Median variable imputation #
##############################

res_med = quanti.apply(np.median,axis=0)
lst = []
for i in range(quanti.shape[0]):
    lst.append(tuple(res_mean))
median_df = pd.DataFrame.from_records(lst,columns=names_list)
mapped_values = e.map(partial(get_score_bis, df1=quanti, df2=median_df), names_list)
rmse_median = reduce(add_list,mapped_values)

###############################
# Concaténation des résultats #
###############################

lst = [tuple(rmse_rf),tuple(rmse_knn),tuple(rmse_mean),tuple(rmse_median)]
resultats = pd.DataFrame.from_records(lst,columns=names_list)
resultats = resultats.rename(index={0: 'Random Forest',1: '10-NN',2: 'Mean',3: 'Median'})
filename = 'NA_imputation_methods_results.csv'
resultats.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8')
