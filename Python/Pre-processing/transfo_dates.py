# -*- coding: utf-8 -*-
"""
Created on Mon Nov 13 17:25:18 2017

@author: Guillaume
"""

### Imports
###########

import datetime
import math
import pandas as pd

### Creation des dates
######################

base = datetime.datetime(2013,8,7)
days_list = [365,365,366,365]
numdays = sum(days_list)
date_list = [base + datetime.timedelta(days=x) for x in range(0, numdays)]
date_clean = []
for date in date_list :
    date_clean.append(date.strftime("%Y-%m-%d"))

### Creation des valeurs
########################
 
values = []
for i in range(len(days_list)):
    base_num = 0
    days = days_list[i]
    pas = (math.pi*2)/days
    for i in range(days):
        values.append(base_num)
        base_num += pas

### Creation des valeurs
########################

coef_saison = [math.cos(x) for x in values]   
d = {'date' : pd.Series(date_clean),'coordonnees' : pd.Series(coef_saison)}
df = pd.DataFrame(d)

### Sauvegarde du dataframe 
###########################

filename = 'transfo_dates.csv'
df.to_csv(filename,sep=';',header=True,index=False,decimal='.')