# -*- coding: utf-8 -*-
"""
Created on Tue Nov 21 18:44:18 2017

@author: Guillaume
"""

import os
import pandas as pd

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=",",encoding="utf-8")
    return df

files = os.listdir('data_agg_sep')
for j in range(len(files)):
    file = 'data_agg_sep/'+files[j]
    train = read_df(file)
    train = train.drop(['Unnamed: 0','Unnamed: 0.1'],axis=1)
    for i in range(1,37):
        df = train[train.ech == i]
        filename = 'train_sep_ech_station/'+files[j].split('.')[0]+'_ech'+str(i)+'.csv'
        df.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8',index=False)
        
files = os.listdir('test_sep_NAfilled')
for j in range(len(files)):
    file = 'test_sep_NAfilled/'+files[j]
    train = pd.read_csv(file, sep=";",decimal=",",encoding="iso-8859-1")
    train = train.drop(['Unnamed: 0'],axis=1)
    for i in range(1,37):
        df = train[train.ech == i]
        filename = 'test_sep_wna/'+files[j].split('.')[0]+'_ech'+str(i)+'.csv'
        df.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8',index=False)