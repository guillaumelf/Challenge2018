# -*- coding: utf-8 -*-
"""
Created on Thu Dec 21 11:40:56 2017

@author: Sylvie
"""

### Imports de librairies
#########################

import pandas as pd
from sklearn.preprocessing import StandardScaler
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.optimizers import RMSprop
from keras.wrappers.scikit_learn import KerasRegressor
from sklearn.model_selection import train_test_split
from sklearn.model_selection import KFold, GridSearchCV
from keras.callbacks import EarlyStopping
from sklearn.preprocessing import label_binarize

### Définition locale de fonctions
###############################################################################

def read_df(file):
    df = pd.read_csv(file, sep=",",decimal=".",encoding="iso-8859-1")
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

def label_month(df):
    df_month = pd.DataFrame(label_binarize(df['mois'], classes=[i for i in range(1,13)]),columns=['mois'+str(i) for i in range(1,13)])
    df = df.reset_index(drop=True)
    df_month = df_month.reset_index(drop=True)
    new_df = pd.concat([df,df_month],axis=1,ignore_index=True)
    return new_df

### Corps principal du script
#############################


# Importation des données

date_transfo = pd.read_csv('transfo_dates2.csv', sep=";",decimal=".")
dico_dates = {date_transfo.ix[i,1]: date_transfo.ix[i,0] for i in range(date_transfo.shape[0])}
var_dropped = ['capeinsSOL0','rr1SOL0']
dico_transfo = {'janvier': 1,'f<e9>vrier': 2,'mars': 3,'avril': 4,'mai': 5,'juin': 6,'juillet': 7,'ao<fb>t': 8,'septembre': 9,'octobre': 10,'novembre': 11,'d<e9>cembre': 12}

train = preprocess_df(read_df('data_meteo/data_acp.csv'),var_dropped,dico_transfo,dico_dates).sample(frac=1)
X_test = preprocess_df(read_df('data_meteo/test_acp.csv'),var_dropped,dico_transfo,dico_dates)
answer = pd.read_csv('data_meteo/test_answer_template.csv', sep=";",decimal=".",encoding="utf-8")

# Préparation des données : Scaling des données pour que les variables soient à la même échelle

X_train = train.drop(['tH2_obs'], axis=1)
y_train = train['tH2_obs']

scaler = StandardScaler()
X_train, X_test = my_scaler(X_train,X_test,scaler)

X_train = pd.get_dummies(X_train, columns=['insee','ech','ddH10_rose4'])
X_test = pd.get_dummies(X_test, columns=['insee','ech','ddH10_rose4'])

X_train = label_month(X_train)
X_test = label_month(X_test)

# Création de la fonction qui construit le réseau de neurones

opti = RMSprop(lr=0.0001)
def baseline_model(lst_neurals=[128],drop_out_value=0.02):
    model = Sequential()
    model.add(Dropout(drop_out_value, input_shape=(95,)))
    for neural in lst_neurals:
        model.add(Dense(neural, activation='relu'))
        model.add(Dropout(drop_out_value))
    model.add(Dense(1, activation = 'relu'))
    model.compile(loss='mean_squared_error', optimizer=opti)
    return model

# Prédiction

es = EarlyStopping(monitor='val_loss', min_delta=0, patience=100, verbose=1, mode='auto')
estimator = KerasRegressor(build_fn=baseline_model, epochs=750, verbose=1, batch_size=500)
dict_params = {'lst_neurals' : [[100,100,64],[300,300,100],[200,200,100,50]],'drop_out_value':[0.02,0.05],'callbacks': [es]}
clf = GridSearchCV(estimator, param_grid=dict_params, cv=KFold(n_splits=5),refit=False,verbose=1,n_jobs=-1)
clf.fit(X_train, y_train) # On fit sur l'ensemble des données pour trouver les paramètres optimaux
best = clf.best_estimator_
x_train, x_val, Y_train, y_val = train_test_split(X_train, y_train, test_size=0.1)
best.fit(X_train, Y_train) # On refit sur une partie des données train avec les paramètres optimaux
y_pred = best.predict(X_test)
print(y_pred[:5])

# Ecriture des résultats

answer['tH2_obs']=y_pred
answer.to_csv('test_filled.csv',sep=';',header=True,decimal='.',encoding='utf-8',index=False) 
