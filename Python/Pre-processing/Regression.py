# -*- coding: utf-8 -*-
"""
Created on Tue Dec 26 13:27:10 2017

@author: Guillaume
"""

### Imports de librairies
###############################################################################

import os
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
import datetime
import numpy as np
from sklearn.preprocessing import label_binarize
from sklearn.metrics import mean_squared_error

### Définition locale de fonctions
###############################################################################

def read_df(file):
    df = pd.read_csv(file, sep=",",decimal=".",encoding="iso-8859-1")
    return df

def label_month(df):
    df_month = pd.DataFrame(label_binarize(df['mois'], classes=[i for i in range(1,13)]),columns=['mois'+str(i) for i in range(1,13)])
    df = df.reset_index(drop=True)
    df_month = df_month.reset_index(drop=True)
    new_df = pd.concat([df,df_month],axis=1,ignore_index=True)
    return new_df

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

def tune_model(files,villes,drop,replacement_month,replacement_date,regressor,output_file):
    for i in range(len(files)):
        file = 'data_agg_sep/'+files[i]
        file2 = 'test_sep_NAfilled/'+files[i]
        train = read_df(file).sample(frac=1)
        test = read_df(file2)
        processed_df = preprocess_df(train,drop,replacement_month,replacement_date,drop_na=True)
        processed_test = preprocess_df(test,drop,replacement_month,replacement_date,drop_na=False)
        X = processed_df.drop(['tH2_obs'], axis=1).values
        y = processed_df['tH2_obs'].values
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=(1/3))
        regressor = LinearRegression()
        regressor.fit(X_train, y_train)
        y_hat = regressor.predict(X_test)
        rmse = np.sqrt(abs(mean_squared_error(y_test,y_hat)))
        print("RMSE score for "+villes[i]+" : %.4f" % rmse)
        prediction = regressor.predict(processed_test)
        output_file.write("Best score for "+villes[i]+" : {}\n".format(rmse))
        output_file.write('###########################################################################\n')
        df = pd.DataFrame(prediction)
        filename = 'Results/Regression/'+villes[i]+'_results.csv'
        df.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8')
        print("The results for {} have been saved successfully".format(villes[i]))

# Corps principal du script
###############################################################################


f = open('Results/Regression/Best_tune.txt','w')
f.write('Résultats du {}\n'.format(datetime.datetime.now()))
f.write('################################\n')

date_transfo = pd.read_csv('transfo_dates2.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
var_dropped = ['capeinsSOL0','rr1SOL0']
dico_transfo = {'janvier': 1,'f<e9>vrier': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'ao<fb>t': 8,'septembre': 9,'octobre': 10,'novembre': 11,'d<e9>cembre': 12}
files = os.listdir('data_agg_sep')
villes = ['Toulouse','Bordeaux','Rennes','Lille','Nice','Strasbourg','Paris']

if __name__ == '__main__':              
    tune_model(files,villes,var_dropped,dico_transfo,dico_dates,LinearRegression,f)   

f.close()