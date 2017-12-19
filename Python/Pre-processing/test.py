# -*- coding: utf-8 -*-
"""
Created on Thu Nov  9 08:11:10 2017

@author: Guillaume
"""
### Imports de librairies
###############################################################################

import matplotlib.pyplot as plt
import pandas as pd
#import os
from sklearn.cluster import KMeans
from predictive_imputer import predictive_imputer
import numpy as np

def preprocess_df(df,var_dropped,replacement_date,drop_na=True):
    processed_df = df.copy()
    processed_df['date'].replace(replacement_date, inplace=True)
    processed_df['ddH10_rose4'] = processed_df['ddH10_rose4'].astype('category')
    processed_df['ech'] = processed_df['ech'].astype('category')
    processed_df['mois'] = processed_df['mois'].astype('category')
    processed_df = processed_df.drop(var_dropped,axis=1)
    if drop_na :
        processed_df = processed_df.dropna()
    return processed_df

# Graph    

fig=plt.figure(figsize=(13,8))
plt.plot([5,10,15,20,25,30],[1.45,1.38,1.32,1.28,1.33,1.36])
plt.xlabel('K')
plt.ylabel('RMSE')
plt.title('Score RMSE moyen en fonction du nombre de clusters')
#fig.savefig('rmse_lignes.jpg')
plt.show()

#file = os.listdir('test_sep_NAfilled')[0]
#test = pd.read_csv('test_sep_NAfilled/'+file, sep=";",decimal=",",encoding="iso-8859-1")
#var_dropped_test = ['insee','Unnamed: 0']
#date_transfo = pd.read_csv('transfo_dates.csv', sep=";",decimal=".")
#dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
#processed_test = preprocess_df(test,var_dropped_test,dico_dates,drop_na=True)
#df = pd.get_dummies(processed_test, columns=['ddH10_rose4','ech','mois'])
#

#df2 = pd.DataFrame(np.random.randint(low=0, high=10, size=(5, 5)),columns=['a', 'b', 'c', 'd', 'e'])
#clf = KMeans(n_clusters=3, random_state=0)
#kmeans = clf.fit(df2)
#df2['cluster']=kmeans.labels_
#
#df3 = pd.DataFrame(np.random.randint(low=0, high=10, size=(3, 5)),columns=['a', 'b', 'c','d','e'])
#pred=clf.predict(df3)
#df3['cluster']=pred
#
#print(df2)
#print(df3)
