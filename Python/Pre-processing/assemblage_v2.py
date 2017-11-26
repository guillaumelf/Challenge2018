# -*- coding: utf-8 -*-
"""
Created on Tue Nov 21 21:33:16 2017

@author: Guillaume
"""

### Imports de librairies
#########################

import os
import pandas as pd
from concurrent.futures import ThreadPoolExecutor
from functools import reduce

### Définition locale de fonctions
##################################

def read_df(file):
    df = pd.read_csv('Results2/'+file, sep=";",decimal=".",encoding="utf-8")
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

files = os.listdir('Results2')
files.pop(-1)

'''
On applique le principe map reduce pour agréger tous les dataframes en un seul
'''

mapped_values = e.map(read_df, files)
df = reduce(concat_data,mapped_values)
df = df[['date','insee','ech','tH2_obs']]
print(df)

'''
On crée le fichier csv avec les données agrégées dans un unique dataframe
'''

#template = pd.read_csv('data_meteo/test_answer_template.csv', sep=",",encoding="utf-8")
#template = template.drop('tH2_obs',axis=1)
#result = template.set_index(['date','insee','ech']).join(df.set_index(['date','insee','ech']))
#print(result)
#result.to_csv('testfilled.csv',sep=';',header=True,decimal='.',index=False)