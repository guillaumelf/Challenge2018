# -*- coding: utf-8 -*-
"""
Created on Wed Dec 20 15:36:44 2017

@author: Guillaume
"""
import re

files = ['test_sep_NAfilled/6088001.csv','test_sep_NAfilled/31069001.csv','test_sep_NAfilled/33281001.csv','test_sep_NAfilled/35281001.csv','test_sep_NAfilled/59343001.csv','test_sep_NAfilled/67124001.csv','test_sep_NAfilled/75114001.csv']
res = []
for i in range(len(files)):
    with open(files[i],'r',encoding='iso-8859-1') as f:
        lines = f.readlines()
        lines = [re.sub(r",",r".",elem) for elem in lines]
        res.append(lines)

result = open('data_meteo/test_agregated.csv','w')
result.write(res[0][0])
for i in range(1,len(res[0])):
    result.write(res[0][i])
    result.write(res[1][i])
    result.write(res[2][i])
    result.write(res[3][i])
    result.write(res[4][i])
    result.write(res[5][i])
    result.write(res[6][i])
result.close()