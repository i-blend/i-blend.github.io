#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 19 14:13:08 2018
@author: haroonr
"""
'''
This script fetches four parameters from WU station. It formats and stores them in a CSV file
Requirements: API key. Create your account on weatherunderground and get free API key
'''

import csv
import datetime
import requests 
from time import sleep

def download_weather_data(station_id,start_date,end_date,savefilename):
  
  with open(savefilename, 'wb') as outfile:
    writer = csv.writer(outfile)
    headers = ['date','temperature','humidity','wind speed','wind direction'] 
    writer.writerow(headers)
    datex = start_date
    while datex <= end_date:
      date_string = datex.strftime('%Y%m%d')
      url = ("http://api.wunderground.com/api/{}/history_{}/q/{}.json".format(api_key,date_string,station_id))
      data = requests.get(url).json()
      for history in data['history']['observations']:
        row = []
        row.append(str(history['date']['pretty']))
        row.append(str(history['tempm']))	
        row.append(str(history['hum']))
        row.append(str(history['wspdm']))
        row.append(str(history['wdird']))
        writer.writerow(row)
      sleep(30) # in seconds, limit is 10 calls per minute
      datex += datetime.timedelta(days = 1) 

api_key = 'XXXX' #  put your API key here. Create a free account on Weatherunderground.com and you will get a key. 
station_id ='VIDP' # VIDP is international airport of Delhi while as VIDD is safdarjung airport. VIDD is nearest one but it has low data resolution
start_date = datetime.date(2018,2,15)
end_date = datetime.date(2018,2,25)
savefilename = "directory path to save your file"
download_weather_data(station_id,start_date,end_date,savefilename)

#%%
