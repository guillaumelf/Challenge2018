# -*- coding: utf-8 -*-
"""
Created on Tue Oct 24 17:09:50 2017
Separation des fichiers
@author: BEN
"""

## IMPORTATION PACKAGE
from sklearn.cluster import KMeans
import numpy as np
import pandas as pd
import glob
from concurrent.futures import ThreadPoolExecutor
from functools import reduce


### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df



########################
## OUVERTURE FICHIER

test=read_df('data_meteo/test.csv')
insee=list(set(test['insee'].values))


def extract_test(insee):
    data=test[test.insee == insee]
    nom=str(insee)+".csv"
    data.to_csv(nom,sep=";",header=True,decimal='.',encoding='utf-8')
    return(data)


e=ThreadPoolExecutor()
#e.map(extract_test,insee)


data_agg=read_df('data_meteo/data_agregated.csv')

def extract_agg(insee):
    data=data_agg[data_agg.insee == insee]
    nom=str(insee)+".csv"
    data.to_csv(nom,sep=";",header=True,decimal='.',encoding='utf-8')
    return(data)


#e.map(extract_agg,insee)


#############################
# fichier stations + ech
 
l_ech=[]
for i in range(36):
    l_ech.append(i+1)

l_final=[]
for i in insee:
    for j in l_ech:
        l_final.append([i,j])
    
#data_agg[data_agg.ech == 9][data_agg.insee== 6088001]



def extract_agg_tot(l):
    data=data_agg[data_agg.insee == l[0]][data_agg.ech==l[1]]
    nom=str(l[0])+"_"+str(l[1])+".csv"
    data.to_csv(nom,sep=";",header=True,decimal='.',encoding='utf-8')
    return(data)

#e.map(extract_agg_tot,l_final)


def extract_test_tot(l):
    data=test[test.insee == l[0]][test.ech==l[1]]
    nom=str(l[0])+"_"+str(l[1])+".csv"
    data.to_csv(nom,sep=";",header=True,decimal='.',encoding='utf-8')
    return(data)

#e.map(extract_test_tot,l_final)




