# -*- coding: utf-8 -*-
"""
Created on Sat Oct 14 13:17:29 2017

@author: Guillaume
"""

### Imports de librairies
#########################

import pandas as pd
import glob
from concurrent.futures import ThreadPoolExecutor
from functools import reduce

### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

def concat_data(df1,df2):
    frames = [df1, df2]
    result = pd.concat(frames)
    return(result)

### Corps principal du script
#############################

'''
On sépare les tâches pour aller plus vite dans l'importation des 36 fichiers csv
'''
e = ThreadPoolExecutor()

files = glob.glob('data_meteo/train_*.csv')

'''
On applique le principe map reduce pour agréger tous les dataframes en un seul
'''

mapped_values = e.map(read_df, files)
df = reduce(concat_data,mapped_values)

'''
On crée le fichier csv avec les données agrégées dans un unique dataframe
'''

df.to_csv('data_meteo/data_agregated.csv',sep=';',header=True,decimal=',',encoding='utf-8')
