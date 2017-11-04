# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 23:42:16 2017

@author: Guillaume
"""

files = ['Results/Nice_results.csv','Results/Toulouse_results.csv','Results/Bordeaux_results.csv','Results/Rennes_results.csv','Results/Lille_results.csv','Results/Strasbourg_results.csv','Results/Paris_results.csv']
res = []
for i in range(len(files)):
    with open(files[i],'r',encoding='utf-8') as f:
        lines = f.readlines()
        res.append(lines)

result = open('Results/resultats_boosting.csv','w')
for i in range(1,len(res[0])):
    result.write(res[0][i].split(';')[1])
    result.write(res[1][i].split(';')[1])
    result.write(res[2][i].split(';')[1])
    result.write(res[3][i].split(';')[1])
    result.write(res[4][i].split(';')[1])
    result.write(res[5][i].split(';')[1])
    result.write(res[6][i].split(';')[1])
result.close()










