# -*- coding: utf-8 -*-
"""
Created on Fri Dec  1 13:13:01 2017

@author: Guillaume
"""

### Imports de librairies
#########################

import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.optimizers import RMSprop
from keras.wrappers.scikit_learn import KerasRegressor
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import KFold, GridSearchCV
import matplotlib.pyplot as plt
from keras.callbacks import EarlyStopping

### Définition locale de fonctions
###############################################################################

def read_df(file):
    df = pd.read_csv(file, sep=";",decimal=".",encoding="iso-8859-1")
    return df

def preprocess_df(df,var_dropped,replacement_month,replacement_date,drop_na=True):
    processed_df = df.copy()
    processed_df['mois'].replace(replacement_month, inplace=True)
    processed_df['date'].replace(replacement_date, inplace=True)
    processed_df['insee'] = processed_df['insee'].astype('category')
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

### Corps principal du script
#############################


# Importation des données

date_transfo = pd.read_csv('transfo_dates2.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
var_dropped = ['capeinsSOL0','rr1SOL0']
dico_transfo = {'janvier': 1,'février': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'août': 8,'septembre': 9,'octobre': 10,'novembre': 11,'décembre': 12}

train = preprocess_df(read_df('data_meteo/data_agregated.csv'),var_dropped,dico_transfo,dico_dates).sample(frac=1)
X_test = preprocess_df(read_df('data_meteo/test_agregated.csv'),var_dropped,dico_transfo,dico_dates)
answer = pd.read_csv('data_meteo/test_answer_template.csv', sep=";",decimal=".",encoding="utf-8")

# Préparation des données : Scaling des données pour que les variables soient à la même échelle

X_train = train.drop(['tH2_obs'], axis=1)
y_train = train['tH2_obs']

scaler = StandardScaler()
X_train, X_test = my_scaler(X_train,X_test,scaler)

X_train = pd.get_dummies(X_train, columns=['insee','ech','ddH10_rose4'])
X_test = pd.get_dummies(X_test, columns=['insee','ech','ddH10_rose4'])

# Création de l'algorithme

premiere_couche = Dense(units=100, activation="relu", input_dim=72)
couche_cachee1 = Dense(units=100, activation="relu")
couche_cachee2 = Dense(units=64, activation="relu")
couche_sortie = Dense(units=1)
opti = RMSprop(lr=0.0001)

def baseline_model():
    model = Sequential()
    model.add(premiere_couche)
    model.add(Dropout(0.02, noise_shape=None, seed=None))
    model.add(couche_cachee1)
    model.add(Dropout(0.02, noise_shape=None, seed=None))
#    model.add(couche_cachee2)
    model.add(couche_sortie)
    model.compile(optimizer=opti, loss="mean_squared_error")
    return model

# Représentation graphique

model = baseline_model()
#es = EarlyStopping(monitor='val_loss', min_delta=0, patience=0, verbose=0, mode='auto')
hist = model.fit(X_train, y_train, validation_split=0.3,epochs=500,batch_size=500,verbose=2)
loss = np.sqrt(hist.history['loss'])
val_loss = np.sqrt(hist.history['val_loss'])
n_iter = range(1,(len(hist.history['val_loss'])+1))
y_pred = model.predict(X_test)
print(y_pred[:5])

fig=plt.figure(figsize=(10,5))
plt.plot(n_iter,loss,c='b',label="train_loss")
plt.plot(n_iter,val_loss,c='r',label="val_loss")
plt.xlabel('itérations')
plt.ylabel('MSE')
plt.legend(loc=0)
plt.title('Evolutions des scores au cours des itérations')
plt.show()

# Prédiction

#seed = 7
#np.random.seed(seed)
#estimator = KerasRegressor(build_fn=baseline_model, epochs=100, verbose=2)
#dict_params = {'batch_size' : [200,500]}
#rg = GridSearchCV(estimator, param_grid=dict_params, cv=KFold(n_splits=5),refit=True,scoring='neg_mean_squared_error',verbose=2)
#rg.fit(X_train, y_train)
#
#score = np.sqrt(abs(rg.best_score_))
#print("Best score (RMSE) :\n {}".format(score))
#y_pred = rg.predict(X_test)
#print(y_pred[:20])

# Ecriture des résultats

answer['tH2_obs']=y_pred
answer.to_csv('test_filled.csv',sep=';',header=True,decimal='.',encoding='utf-8',index=False) 