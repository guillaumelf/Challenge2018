# -*- coding: utf-8 -*-
"""
Created on Sat Nov 25 18:43:59 2017

@author: Guillaume
"""

### Imports de librairies
#########################

from predictive_imputer import predictive_imputer
import pandas as pd
from concurrent.futures import ThreadPoolExecutor
from functools import reduce, partial
import os

### Définition locale de fonctions
##################################

def mapping_function(df,var_dropped):
    processed_df = df.copy()
    processed_df['ddH10_rose4'] = processed_df['ddH10_rose4'].astype('category')
    processed_df['ech'] = processed_df['ech'].astype('category')
    processed_df['mois'] = processed_df['mois'].astype('category')
    processed_df = processed_df.drop(var_dropped,axis=1)
    processed_df = pd.get_dummies(processed_df, columns=["mois"])
    imputer = predictive_imputer.PredictiveImputer(f_model="RandomForest")
    X_trans = imputer.fit(processed_df).transform(processed_df.copy())
    df[['tH2_obs','ciwcH20','clwcH20','ffH10','huH2','iwcSOL0','nbSOL0_HMoy','nH20','ntSOL0_HMoy','pMER0','rr1SOL0','rrH20','tH2','tH2_VGrad_2.100','tH2_XGrad','tH2_YGrad','tpwHPA850','ux1H10','vapcSOL0','vx1H10']] = X_trans[['tH2_obs','ciwcH20','clwcH20','ffH10','huH2','iwcSOL0','nbSOL0_HMoy','nH20','ntSOL0_HMoy','pMER0','rr1SOL0','rrH20','tH2','tH2_VGrad_2.100','tH2_XGrad','tH2_YGrad','tpwHPA850','ux1H10','vapcSOL0','vx1H10']]
    return df

def concat_data(df1,df2):
    frames = [df1, df2]
    result = pd.concat(frames)
    return(result)

### Corps principal du script
#############################

e = ThreadPoolExecutor()
files = ['data_agg_sep/'+file for file in os.listdir('data_agg_sep')]
new_f = []
for file in files:
    df = pd.read_csv(file,sep=';',decimal=".",encoding="utf-8")
    new_f.append(df)

var_dropped_train = ['Unnamed: 0','Unnamed: 0.1','capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','date','insee']
var_dropped_test = ['Unnamed: 0','capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','date','insee']

mapped_values_train = e.map(partial(mapping_function,var_dropped_train), new_f)
df_train = reduce(concat_data,mapped_values_train)

'''
On crée le fichier csv avec les données agrégées dans un unique dataframe
'''

#df_train.to_csv('train_filled.csv',sep=';',header=True,decimal='.',encoding='utf-8',index=False)

