# -*- coding: utf-8 -*-
"""
Created on Tue Oct 24 17:06:52 2017

@author: Guillaume
"""

### Imports de librairies
#########################

import pandas as pd
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
import numpy as np

### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=".",encoding="utf-8")
    return df

def k_means_df(df,var_dropped,replacement_month,replacement_date):
    processed_df = df.copy()
    processed_df['date'].replace(replacement_date, inplace=True)
    processed_df['mois'].replace(replacement_month, inplace=True)
    processed_df['ech'] = processed_df['ech'].astype('category')
    processed_df['insee'] = processed_df['insee'].astype('category')
    processed_df['mois'] = processed_df['mois'].astype('category')
    processed_df = processed_df.drop(var_dropped,axis=1)
    quanti = processed_df.select_dtypes(include=['float64'])
    quali = processed_df.select_dtypes(exclude=['float64'])
    scaler = StandardScaler()
    df_scaled = pd.DataFrame(scaler.fit_transform(quanti))
    processed_df = pd.concat([df_scaled,quali], axis=1)
    processed_df = pd.get_dummies(processed_df, columns=['insee'])
    return processed_df

def preprocess_df(df,var_dropped,replacement_month,replacement_date,drop_na=True):
    processed_df = df.copy()
    processed_df['mois'].replace(replacement_month, inplace=True)
    processed_df['date'].replace(replacement_date, inplace=True)
    processed_df['ddH10_rose4'] = processed_df['ddH10_rose4'].astype('category')
    processed_df['ech'] = processed_df['ech'].astype('category')
    processed_df['mois'] = processed_df['mois'].astype('category')
    processed_df = processed_df.drop(var_dropped,axis=1)
    if drop_na :
        processed_df = processed_df.dropna()
    return processed_df

### Corps principal du script
#############################

# Import des fichiers

date_transfo = pd.read_csv('transfo_dates.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
train = read_df('data_train.csv')
test = read_df('data_test.csv')
dico_transfo = {'janvier': 1,'février': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'août': 8,'septembre': 9,'octobre': 10,'novembre': 11,'décembre': 12}

# Préparation des données pour les K-means

var_dropped_train = ['capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','hcoulimSOL0','ddH10_rose4','tH2_obs']
processed_train = k_means_df(train,var_dropped_train,dico_transfo,dico_dates)

var_dropped_test = ['capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','hcoulimSOL0','ddH10_rose4']
processed_test = k_means_df(test,var_dropped_test,dico_transfo,dico_dates)

# K-means et régression : choix du K optimal

train_drop = ['capeinsSOL0']

k_list = [10]
moy = []
sd = []
for i in range(10):
    for k in k_list:
        new_train = train.copy()
        clf = KMeans(n_clusters=k, random_state=0)
        kmeans = clf.fit(processed_train)
        new_train['cluster']=kmeans.labels_
        new_train = preprocess_df(new_train,train_drop,dico_transfo,dico_dates,drop_na=True)
        clusters = np.unique(new_train['cluster'])
        l_rmse = []
        for cl in clusters:
            df = new_train[new_train.cluster == cl]
            df = df.drop(['cluster'], axis=1)
            X = df.drop(['tH2_obs'], axis=1).values
            y = df['tH2_obs'].values
            X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=(1/3))
            regressor = LinearRegression()
            regressor.fit(X_train, y_train)
            y_hat = regressor.predict(X_test)
            rmse = np.sqrt(abs(mean_squared_error(y_test,y_hat)))
            l_rmse.append(rmse)
        moy.append(np.mean(l_rmse))
        sd.append(np.std(l_rmse))
  
# Graph    

fig=plt.figure(figsize=(13,8))
plt.plot([i for i in range(1,11)],moy)
plt.xlabel('itérations')
plt.ylabel('RMSE')
plt.title('Test de la stabilité du score pour K = 10')
fig.savefig('KMeans/kmeans_10.jpg')
plt.show()
#        
#fig=plt.figure(figsize=(13,8))
#plt.plot(k_list,sd)
#plt.xlabel('K')
#plt.ylabel('SD')
#plt.title('Ecart type du score RMSE en fonction du nombre de clusters')
#fig.savefig('KMeans/kmeans_sd.jpg')
#plt.show()
    
# K = 30 donne les meilleurs résultats

#pred=clf.predict(processed_test)
#test['cluster']=pred