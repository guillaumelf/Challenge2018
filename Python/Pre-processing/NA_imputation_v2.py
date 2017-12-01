# -*- coding: utf-8 -*-
"""
Created on Sat Nov 25 18:43:59 2017

@author: Guillaume
"""

### Imports de librairies
#########################

from predictive_imputer import predictive_imputer
import pandas as pd
import os
import numpy as np

### Corps principal du script
#############################

var_dropped_train = ['Unnamed: 0','Unnamed: 0.1','capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','hcoulimSOL0','date','insee']
var_dropped_test = ['Unnamed: 0','capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','hcoulimSOL0','date','insee']

files = ['data_agg_sep/'+file for file in os.listdir('data_agg_sep')]
for file in files:
    df = pd.read_csv(file,sep=';',decimal=".",encoding="utf-8")
    processed_df = df.copy()
    processed_df['ddH10_rose4'] = processed_df['ddH10_rose4'].astype('category')
    processed_df['ech'] = processed_df['ech'].astype('category')
    processed_df['mois'] = processed_df['mois'].astype('category')
    processed_df = processed_df.drop(var_dropped_train,axis=1)
    processed_df = pd.get_dummies(processed_df, columns=["mois"])
    imputer = predictive_imputer.PredictiveImputer(f_model="RandomForest")
    X_trans = pd.DataFrame(imputer.fit(processed_df).transform(processed_df.copy()))
    X_trans = X_trans.ix[:,[0,1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]]
    X_trans.columns =['tH2_obs','ciwcH20','clwcH20','ffH10','huH2','iwcSOL0','nbSOL0_HMoy','nH20','ntSOL0_HMoy','pMER0','rr1SOL0','rrH20','tH2','tH2_VGrad_2.100','tH2_XGrad','tH2_YGrad','tpwHPA850','ux1H10','vapcSOL0','vx1H10']
    new_df = pd.concat([df[['date','insee','ddH10_rose4','capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','hcoulimSOL0','ech','mois']],X_trans], axis=1)
    filename = str(np.unique(new_df['insee'])[0])+'.csv'
    path = 'train_rf/'+filename
    new_df.to_csv(path,sep=';',header=True,decimal='.',encoding='utf-8',index=False)
    print('Done for {} !'.format(filename))


files = ['test_sep_NAfilled/'+file for file in os.listdir('test_sep_NAfilled')]
for file in files:
    df = pd.read_csv(file, sep=";",decimal=",",encoding="iso-8859-1")
    processed_df = df.copy()
    processed_df['ddH10_rose4'] = processed_df['ddH10_rose4'].astype('category')
    processed_df['ech'] = processed_df['ech'].astype('category')
    processed_df['mois'] = processed_df['mois'].astype('category')
    processed_df = processed_df.drop(var_dropped_test,axis=1)
    processed_df = pd.get_dummies(processed_df, columns=["mois"])
    print(processed_df.columns)
    imputer = predictive_imputer.PredictiveImputer(f_model="RandomForest")
    X_trans = pd.DataFrame(imputer.fit(processed_df).transform(processed_df.copy()))
    X_trans = X_trans.ix[:,[0,1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]]
    X_trans.columns =['ciwcH20','clwcH20','ffH10','huH2','iwcSOL0','nbSOL0_HMoy','nH20','ntSOL0_HMoy','pMER0','rr1SOL0','rrH20','tH2','tH2_VGrad_2.100','tH2_XGrad','tH2_YGrad','tpwHPA850','ux1H10','vapcSOL0','vx1H10']
    new_df = pd.concat([df[['date','insee','ddH10_rose4','capeinsSOL0','flir1SOL0','fllat1SOL0','flsen1SOL0','flvis1SOL0','hcoulimSOL0','ech','mois']],X_trans], axis=1)
    filename = str(np.unique(new_df['insee'])[0])+'.csv'
    path = 'test_rf/'+filename
    new_df.to_csv(path,sep=';',header=True,decimal='.',encoding='utf-8',index=False)
    print('Done for {} !'.format(filename))
