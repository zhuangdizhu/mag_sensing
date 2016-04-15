#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, os, signal, random, re, fnmatch, gc, csv
import time, locale, datetime, requests
import socket
#import dns, dns.name, dns.query, dns.resolver, dns.exception
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
        sys.exit('Usage:    preprocess_data.py <FileName>')
        sys.exit(1)

    force_utf8_hack()

    filename = sys.argv[1]
    if DEBUG2: print "Preprocess: %s" % (filename)

    appType = dict()
    appType['PowerPoint'] = 0
    appType['Word'] = 1
    appType['Excel'] = 2
    appType['Chrome'] = 3
    appType['Skype'] = 4
    appType['QuickTimePlayer'] = 5


    ###################
    ## Read Event Time
    ###################
    if DEBUG2: print "Read Event Time"

    event_traces   = []
    events     = dict()  ## event and its indices
    event_type = dict()  ## event and its type
    f = open(input_dir + filename + ".app_time_processed.txt", 'w')
    with open(input_dir + filename + ".app_time.txt", 'rb') as csvfile:
      spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
      cnt = 0
      for row in spamreader:
        event_traces.append(row[1])

        if row[1] in events:
          events[row[1]].append(cnt)
        else:
          events[row[1]] = [cnt]
          event_type[row[1]] = appType[row[1]]

        #format: timestamp, appName, class_label(0,1,2,..)
        f.write("%s %d\n" % (row[0], event_type[row[1]]))
        cnt += 1
    f.close()



    ###################
    ## Read SensorLog Data
    ###################
    if DEBUG2: print "Read SensorLog Data"

    ts2  = []
    magx = []
    magy = []
    magz = []
    for app_name, app_label in event_type.items():
        f = open(input_dir + filename + "_" + app_name + ".mag_processed.txt", 'w')
        app_count = 0
        with open(input_dir + filename + "_" + app_name + ".mag.txt", 'rb') as csvfile:
          spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
          cnt = 0
          for row in spamreader:
            #print str(len(row)) + ", " + ', '.join(row)

            if len(row) < 10:
                if len(row) == 4:
                    app_count += 1
                    #when the next processing component reads an -1, it will
                    #know that a loop finishes.
                    f.write("%f,%.15f,%.15f,%.15f,%f\n" %(-100,0,0,0,float(app_count)))
                continue
            elif row[4] == "" or row[5] == "" or row[6] == "": continue

            ts2.append(float(row[3]))
            magx.append(float(row[4]))
            magy.append(float(row[5]))
            magz.append(float(row[6]))
            #print "%d: %f, %f, %f, %f, %d" % (cnt, ts2[cnt], magx[cnt], magy[cnt], magz[cnt], app_label)
            f.write("%f,%.15f,%.15f,%.15f,%f\n" % (ts2[cnt], magx[cnt], magy[cnt], magz[cnt], float(app_label)))
            cnt += 1
        f.close()
