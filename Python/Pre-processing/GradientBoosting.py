# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 19:08:52 2017

@author: Guillaume
"""
### Imports de librairies
###############################################################################

import os
import pandas as pd
from sklearn import ensemble
from sklearn.model_selection import GridSearchCV, KFold
import datetime
import numpy as np

### Définition locale de fonctions
###############################################################################

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

def tune_model(files,villes,train_drop,test_drop,replacement_month,replacement_date,regressor,params,dict_params,nb_cv_folds,output_file):
    for i in range(len(files)):
        file = 'data_agg_sep/'+files[i]
        file2 = 'test_sep_NAfilled/'+files[i]
        train = read_df(file)
        test = pd.read_csv(file2, sep=";",decimal=",",encoding="iso-8859-1")
        processed_df = preprocess_df(train,train_drop,replacement_month,replacement_date,drop_na=True)
        processed_test = preprocess_df(test,test_drop,replacement_month,replacement_date,drop_na=False)
        X = processed_df.drop(['tH2_obs'], axis=1).values
        y = processed_df['tH2_obs'].values
        clf = GridSearchCV(estimator=regressor(**params), param_grid=dict_params, cv=KFold(n_splits=nb_cv_folds),refit=True,n_jobs=-1,scoring='neg_mean_squared_error')
        print('Cross validation ongoing... Trying to find the best model for '+villes[i]+'... Be patient !')
        clf.fit(X, y)
        score = np.sqrt(abs(clf.best_score_))
        liste_scores.append(score)
        print("Best estimator for "+villes[i]+" :\n {}".format(clf.best_estimator_))
        print("Best score for "+villes[i]+" : %.4f" % score)
        prediction = clf.best_estimator_.predict(processed_test)
        output_file.write("Best estimator for "+villes[i]+" :\n {}\n".format(clf.best_estimator_))
        output_file.write('################################\n')
        output_file.write("Best score for "+villes[i]+" : {}\n".format(score))
        output_file.write('###########################################################################\n')
        df = pd.DataFrame(prediction)
        filename = 'Results/'+villes[i]+'_results.csv'
        df.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8')
        print("The results for {} have been saved successfully".format(villes[i]))

# Corps principal du script
###############################################################################

liste_scores = []
f = open('Results/Best_tune.txt','w')
f.write('Résultats du {}\n'.format(datetime.datetime.now()))
f.write('################################\n')

date_transfo = pd.read_csv('transfo_dates.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
var_dropped_train = ['insee','Unnamed: 0','Unnamed: 0.1','capeinsSOL0','rr1SOL0']
var_dropped_test = ['insee','Unnamed: 0','capeinsSOL0','rr1SOL0']
dico_transfo = {'janvier': 1,'février': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'août': 8,'septembre': 9,'octobre': 10,'novembre': 11,'décembre': 12}
dict_params = {'max_depth' : [8]}
params = {'loss' : 'ls','n_estimators': 1200, 'subsample': 0.9,'learning_rate': 0.05, 'alpha' : 0.9}
files = os.listdir('data_agg_sep')
villes = ['Toulouse','Bordeaux','Rennes','Lille','Nice','Strasbourg','Paris']

if __name__ == '__main__':              
    tune_model(files,villes,var_dropped_train,var_dropped_test,dico_transfo,dico_dates,ensemble.GradientBoostingRegressor,params,dict_params,5,f)   

#moy = np.mean(liste_scores)
#mini = np.min(liste_scores)
#maxi = np.max(liste_scores)
#sd = np.std(liste_scores)
#taille = len(liste_scores)
#f.write('Nombre de modèles : {}\nPire score : {}\nMeilleur score : {}\nScore moyen : {}\nEcart type : {}\n'.format(taille,maxi,mini,moy,sd))
#f.write('################################\n')
f.close()