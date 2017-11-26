# -*- coding: utf-8 -*-
"""
Created on Thu Nov 23 08:01:31 2017

@author: Guillaume
"""

### Imports de librairies
###############################################################################

import os
import pandas as pd
from sklearn import ensemble
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import GridSearchCV, KFold
import datetime
import numpy as np

### Définition locale de fonctions
###############################################################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=".",encoding="utf-8")
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
    
    # Première boucle d'apprentissage par station
    
    for i in range(len(files)):
        file = 'data_agg_sep/'+files[i]
        train = read_df(file)
        processed_df = preprocess_df(train,train_drop,replacement_month,replacement_date,drop_na=True)
        X = processed_df.drop(['tH2_obs'], axis=1).values
        y = processed_df['tH2_obs'].values
        clf = GridSearchCV(estimator=regressor(**params), param_grid=dict_params, cv=KFold(n_splits=nb_cv_folds),refit=True,n_jobs=-1,scoring='neg_mean_squared_error')
        print('Cross validation ongoing... Trying to find the best model for '+villes[i]+'... Be patient !')
        clf.fit(X, y)
        print("Best estimator for "+villes[i]+" :\n {}".format(clf.best_estimator_))
        print("Best score for "+villes[i]+" : %.4f" % np.sqrt(abs(clf.best_score_)))
        print("Now let's run again the model for the 36 echeances")
        fic = files[i].split('.')[0]
        new_files = os.listdir('train_sep_ech_station')
        city = [file for file in new_files if file.startswith(fic)]
        
        # Seconde boucle d'apprentissage, cette fois-ci par échéance à partir du modèle sur la station (argument init dans le dictionnaire new_params)
        
        for j in range(len(city)):
            file1 = 'train_sep_ech_station/'+city[j]
            file2 = 'test_sep_wna/'+city[j]
            train = pd.read_csv(file1, sep=";",decimal=".",encoding="utf-8")
            test = pd.read_csv(file2, sep=";",decimal=".",encoding="utf-8")
            var_dropped_train = [train_drop[0],train_drop[3],train_drop[4]]
            var_dropped_test = [test_drop[0],test_drop[2],test_drop[3]]
            processed_df = preprocess_df(train,var_dropped_train,replacement_month,replacement_date,drop_na=True)
            processed_test = preprocess_df(test,var_dropped_test,replacement_month,replacement_date,drop_na=False)
            X = processed_df.drop(['tH2_obs'], axis=1).values
            y = processed_df['tH2_obs'].values
            X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33,random_state=0)
            new_params = {'loss': 'ls', 'n_estimators': 500, 'max_depth' : 3, 'subsample': 0.8, 'learning_rate': 0.05, 'init': clf.best_estimator_}
            reg = ensemble.GradientBoostingRegressor(**new_params)
            print('Prediction ongoing for file {}'.format(city[j]))
            reg.fit(X_train, y_train)
            y_hat = clf.predict(X_test)
            rmse = np.sqrt(abs(mean_squared_error(y_test,y_hat)))
            liste_scores.append(rmse)
            print("Best score : %.4f" % rmse)
            print('#####################################################')
            prediction = reg.predict(processed_test)
            output_file.write("Best estimator for {} :\n {}\n".format(city[j].split('.')[0],reg))
            output_file.write('################################\n')
            output_file.write("Best score : {}\n".format(rmse))
            output_file.write('###########################################################################\n')
            test['tH2_obs'] = prediction
            filename = 'Results2/'+city[j]
            test.to_csv(filename,sep=';',header=True,decimal='.',encoding='utf-8',index=False)
            print('The results for have been saved successfully')
            n_iter = len(city)-(j+1)
            if n_iter > 1:
                print("It's OK... Only {} models to go before it's over !".format(n_iter))
            elif n_iter == 1:
                print("Last but not least... It's been a long way !")
            else :
                print("Be at peace, it's done !")

# Corps principal du script
###############################################################################

liste_scores = []

f = open('Results2/Best_tune_per_ech_station.txt','w')
f.write('Résultats du {}\n'.format(datetime.datetime.now()))
f.write('################################\n')

date_transfo = pd.read_csv('transfo_dates.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
var_dropped_train = ['insee','Unnamed: 0','Unnamed: 0.1','capeinsSOL0','rr1SOL0']
var_dropped_test = ['insee','Unnamed: 0','capeinsSOL0','rr1SOL0']
dico_transfo = {'janvier': 1,'février': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'août': 8,'septembre': 9,'octobre': 10,'novembre': 11,'décembre': 12}
dict_params = {'subsample': [0.8,0.9]}
params = {'loss': 'ls', 'n_estimators': 1200, 'max_depth' : 8,'learning_rate': 0.05}
files = os.listdir('data_agg_sep')
villes = ['Toulouse','Bordeaux','Rennes','Lille','Nice','Strasbourg','Paris']

if __name__ == '__main__':              
    tune_model(files,villes,var_dropped_train,var_dropped_test,dico_transfo,dico_dates,ensemble.GradientBoostingRegressor,params,dict_params,5,f)   

if len(liste_scores) > 0:
    moy = np.mean(liste_scores)
    mini = np.min(liste_scores)
    maxi = np.max(liste_scores)
    sd = np.std(liste_scores)
    taille = len(liste_scores)
    f.write('Nombre de modèles : {}\nPire score : {}\nMeilleur score : {}\nScore moyen : {}\nEcart type : {}\n'.format(taille,maxi,mini,moy,sd))
    f.write('################################\n')
f.close()