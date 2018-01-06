# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 19:08:52 2017

@author: Guillaume
"""
### Imports de librairies
###############################################################################

import os
import pandas as pd
from sklearn.linear_model import Lasso
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GridSearchCV, KFold
import datetime
import numpy as np
from sklearn.preprocessing import label_binarize

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

def my_scaler(X_train,X_test,scaler):
    quanti1 = X_train.select_dtypes(include=['float64'])
    quanti2 = X_test.select_dtypes(include=['float64'])
    col_quanti1 = quanti1.columns
    col_quanti2 = quanti2.columns
    print(col_quanti1)
    print(col_quanti2)
    scaler.fit(X_train[col_quanti1])
    train_scaled = scaler.transform(X_train[col_quanti1])
    test_scaled = scaler.transform(X_test[col_quanti2])
    X_train[col_quanti1]=train_scaled
    X_test[col_quanti2]=test_scaled
    return X_train, X_test

def tune_model(files,villes,drop,replacement_month,replacement_date,regressor,params,dict_params,nb_cv_folds,output_file):
    for i in range(len(files)):
        file = 'data_agg_sep/'+files[i]
        file2 = 'test_sep_NAfilled/'+files[i]
        train = read_df(file).sample(frac=1)
        test = read_df(file2)
        scaler = StandardScaler()
        processed_df = preprocess_df(train,drop,replacement_month,replacement_date,drop_na=True)
        processed_test = preprocess_df(test,drop,replacement_month,replacement_date,drop_na=False)
        X_train = processed_df.drop(['tH2_obs'], axis=1)
        y_train = processed_df['tH2_obs']
        X_train, X_test = my_scaler(X_train,processed_test,scaler)
        clf = GridSearchCV(estimator=regressor(**params), param_grid=dict_params, cv=KFold(n_splits=nb_cv_folds),refit=True,n_jobs=-2,scoring='neg_mean_squared_error',verbose=1)
        print('Cross validation ongoing... Trying to find the best model for '+villes[i]+'... Be patient !')
        clf.fit(X_train, y_train)
        score = np.sqrt(abs(clf.best_score_))
        print("Best estimator for "+villes[i]+" :\n {}".format(clf.best_estimator_))
        print("Best score for "+villes[i]+" : %.4f" % score)
        prediction = clf.best_estimator_.predict(X_test)
        output_file.write("Best estimator for "+villes[i]+" :\n {}\n".format(clf.best_estimator_))
        output_file.write('################################\n')
        output_file.write("Best score for "+villes[i]+" : {}\n".format(score))
        output_file.write('###########################################################################\n')
        df = pd.DataFrame(prediction)
        filename = 'Results/Lasso/'+villes[i]+'_results.csv'
        df.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8')
        print("The results for {} have been saved successfully".format(villes[i]))

# Corps principal du script
###############################################################################

liste_scores = []
f = open('Results/Lasso/Best_tune.txt','w')
f.write('Résultats du {}\n'.format(datetime.datetime.now()))
f.write('################################\n')

date_transfo = pd.read_csv('transfo_dates2.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
var_dropped = ['capeinsSOL0','rr1SOL0']
dico_transfo = {'janvier': 1,'f<e9>vrier': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'ao<fb>t': 8,'septembre': 9,'octobre': 10,'novembre': 11,'d<e9>cembre': 12}
dict_params = {'alpha' : [0.0003,0.0005]}
params = {'normalize' : False, 'max_iter' : 20000}
files = os.listdir('data_agg_sep')
villes = ['Toulouse','Bordeaux','Rennes','Lille','Nice','Strasbourg','Paris']

if __name__ == '__main__':              
    tune_model(files,villes,var_dropped,dico_transfo,dico_dates,Lasso,params,dict_params,10,f)   

f.close()