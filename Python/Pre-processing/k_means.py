# -*- coding: utf-8 -*-
"""
Created on Tue Oct 24 17:06:52 2017

@author: Guillaume
"""

### Imports de librairies
#########################

import pandas as pd
from sklearn.cluster import KMeans
import numpy as np

### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

### Corps principal du script
#############################

# Import du fichier 

test = read_df('data_meteo/test.csv')
print(test)

# Préparation des données

print(test.count())

print(np.sum(pd.isnull(test['flir1SOL0'])))

liste_1 = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre']
liste_2 = [1,2,3,4,5,6,7,8,9,10,11,12]
test.mois.replace(liste_1, liste_2,inplace=True)
test = test.drop(['date','flir1SOL0','flvis1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','rr1SOL0'], axis=1)
print(test.head())

# K-means

kmeans = KMeans(n_clusters=2, n_jobs=-1).fit(test)