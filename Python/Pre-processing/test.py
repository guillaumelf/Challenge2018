# -*- coding: utf-8 -*-
"""
Created on Thu Nov  9 08:11:10 2017

@author: Guillaume
"""
import pandas as pd
import os

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

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

var_dropped_train = ['insee','Unnamed: 0','Unnamed: 0.1','rr1SOL0']
date_transfo = pd.read_csv('transfo_dates.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
dico_transfo = {'janvier': 1,'février': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'août': 8,'septembre': 9,'octobre': 10,'novembre': 11,'décembre': 12}


files = os.listdir('data_agg_sep')
file = 'data_agg_sep/'+files[0]
train = read_df(file)
processed_df = preprocess_df(train,var_dropped_train,dico_transfo,dico_dates,drop_na=True)