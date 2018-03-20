
# -*- coding: utf-8 -*-
"""
This script shows how to read the data and correct timestamp.
Since India has +5:30 hours of timezone offset so I correct timezone accordingly
Created on Tue Mar 20 15:03:58 2018

@author: haroonr
"""

import pandas as pd
import datetime

#%% Read energy data correctly
energy_data_direc = "path to CSV file containing energy data"
df_e = pd.read_csv(energy_data_direc,index_col = 'timestamp')
df_e.index = pd.to_datetime(df_e.index,unit = 's')
df_e.index =  df_e.index + datetime.timedelta(minutes = 60*5 + 30) # adding 5:30 hours as India timezone offset
df_e['power']['2017-04-04'].plot()



#%% Read occupancy data correctly
occupancy_data_direc = "path to CSV file containing occupancy data"
df_o = pd.read_csv(occupancy_data_direc,index_col = 'timestamp')
df_o.index = pd.to_datetime(df_o.index,unit = 's')
df_o.index =  df_o.index + datetime.timedelta(minutes = 60*5 + 30) 
df_s = pd.Series(data = df_o.occupancy_count,index = df_o.index)
df_s['2017-04-04'].plot()
