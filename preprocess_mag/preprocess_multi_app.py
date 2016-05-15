#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, os, signal, random, re, fnmatch, gc, csv
import time, locale, datetime, requests
import socket
import dns, dns.name, dns.query, dns.resolver, dns.exception
import collections
# import list_data
# import data
# import np
# from bs4 import BeautifulSoup
# from urlparse import urlparse

# import requests.packages.urllib3.util.ssl_
# requests.packages.urllib3.util.ssl_.DEFAULT_CIPHERS = 'ALL'


## static variables
DEBUG1 = 1
DEBUG2 = 1
DEBUG3 = 1
DEBUG4 = 0


###################
## Variables
###################
input_dir = "../collect/gen/"


def force_utf8_hack():
  reload(sys)
  sys.setdefaultencoding('utf-8')
  for attr in dir(locale):
    if attr[0:3] != 'LC_':
      continue
    aref = getattr(locale, attr)
    locale.setlocale(aref, '')
    (lang, enc) = locale.getlocale(aref)
    if lang != None:
      try:
        locale.setlocale(aref, (lang, 'UTF-8'))
      except:
        os.environ[attr] = lang + '.UTF-8'


###################
## DEBUG
# exit();
###################


###################
## Main
###################
if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit('Usage:    preprocess_multi_app.py <FileName>')
        sys.exit(1)

    force_utf8_hack()

    filename = sys.argv[1]
    if DEBUG2: print "Preprocess: %s" % (filename)


    ###################
    ## Read Event Time
    ###################
    if DEBUG2: print "Read Event Time"

    appType = dict()
    appType['PowerPoint'] = 0
    appType['Word'] = 1
    appType['Excel'] = 2
    appType['Chrome'] = 3
    appType['Firefox']=4
    appType['Safari'] = 5
    appType['Skype'] = 6
    appType['iTunes']= 7
    appType['VLC']=8
    appType['MPlayer']=9

    #events     = collections.defaultdict(list)  ## event and its indices
    f = open(input_dir + filename + ".multi_app_time_processed.txt", 'w')
    with open(input_dir + filename + ".multi_app_time.txt", 'rb') as csvfile:
      spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
      cnt = 0
      for row in spamreader:
        #events[row[0]] = [row[1], row[2]]
        f.write("%s,%d,%d\n" % (row[0], appType[row[1]], appType[row[2]]))
    f.close()

    ###################
    ## Read SensorLog Data
    ###################
    if DEBUG2: print "Read SensorLog Data"

    times  = []
    magx = []
    magy = []
    magz = []
    f = open(input_dir + filename + ".multi_mag_processed.txt", 'w')
    with open(input_dir + filename + ".multi_mag.txt", 'rb') as csvfile:
      spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
      cnt = 0
      for row in spamreader:
        #print str(len(row)) + ", " + ', '.join(row)


        if len(row) < 10: continue
        if row[4] == "" or row[5] == "" or row[6] == "": continue

        times.append(float(row[3]))
        magx.append(float(row[4]))
        magy.append(float(row[5]))
        magz.append(float(row[6]))
        # print "%d: %f, %f, %f, %f" % (cnt, times[cnt], magx[cnt], magy[cnt], magz[cnt])
        f.write("%f,%.15f,%.15f,%.15f\n" % (times[cnt], magx[cnt], magy[cnt], magz[cnt]))
        cnt += 1
    f.close()
