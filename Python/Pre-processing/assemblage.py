# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 23:42:16 2017

@author: Guillaume
"""

files = ['Results/RandomForest/Nice_results.csv','Results/RandomForest/Toulouse_results.csv','Results/RandomForest/Bordeaux_results.csv','Results/RandomForest/Rennes_results.csv','Results/RandomForest/Lille_results.csv','Results/RandomForest/Strasbourg_results.csv','Results/RandomForest/Paris_results.csv']
res = []
for i in range(len(files)):
    with open(files[i],'r',encoding='utf-8') as f:
        lines = f.readlines()
        res.append(lines)

result = open('Results/RandomForest/resultats_rf.csv','w')
for i in range(1,len(res[0])):
    result.write(res[0][i].split(';')[1])
    result.write(res[1][i].split(';')[1])
    result.write(res[2][i].split(';')[1])
    result.write(res[3][i].split(';')[1])
    result.write(res[4][i].split(';')[1])
    result.write(res[5][i].split(';')[1])
    result.write(res[6][i].split(';')[1])
result.close()










