# -*- coding: utf-8 -*-
"""
Created on Fri Nov 10 12:48:58 2017

@author: Guillaume
"""

files = ['Results/Nice_results.csv','Results/Toulouse_results.csv','Results/Bordeaux_results.csv','Results/Rennes_results.csv','Results/Lille_results.csv','Results/Strasbourg_results.csv','Results/Paris_results.csv']
res = []
for i in range(len(files)):
    with open(files[i],'r') as f:
        lines = f.readlines()
        temp = []
        for i in range(1,len(lines)):
            temp.append(lines[i].split(';')[-1])
        res.append(temp)

result = open('Results/resultats.csv','w')
for i in range(len(res[0])):
    result.write(res[0][i])
    result.write(res[1][i])
    result.write(res[2][i])
    result.write(res[3][i])
    result.write(res[4][i])
    result.write(res[5][i])
    result.write(res[6][i])
result.close()