#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, os, signal, random, re, fnmatch, gc, csv
import time, locale, datetime, requests
import socket
import dns, dns.name, dns.query, dns.resolver, dns.exception
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
        sys.exit('Usage:    seperate_events.py <FileName>')
        sys.exit(1)
    force_utf8_hack()

    filename = sys.argv[1]
    if DEBUG2: print "Preprocess: %s" % (filename)


    ###################
    ## Read Event Time
    ###################
    if DEBUG2: print "Read Event Time"

    # fh = open(input_dir + filename + ".app_time.txt", 'r')
    ts1      = []
    event_ts = []
    events   = dict()
    with open(input_dir + filename + ".app_time.txt", 'rb') as csvfile:
      spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
      cnt = 0
      for row in spamreader:
        # print ', '.join(row)
        ts1.append(float(row[0]))
        event_ts.append(row[1])
        # print "%d: %f, %s" % (cnt, ts1[cnt], events[cnt])

        if row[1] in events:
          events[row[1]].append(cnt)
        else:
          events[row[1]] = [cnt]

        cnt += 1

    # print "\n".join(events.keys())



    ###################
    ## Read SensorLog Data
    ###################
    if DEBUG2: print "Read SensorLog Data"

    ts2  = []
    magx = []
    magy = []
    magz = []
    f = open(input_dir + filename + ".mag_processed.txt", 'w')
    with open(input_dir + filename + ".mag.txt", 'rb') as csvfile:
      spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
      cnt = 0
      for row in spamreader:
        # print str(len(row)) + ", " + ', '.join(row)

        if len(row) < 10: continue
        if row[4] == "" or row[5] == "" or row[6] == "": continue

        ts2.append(float(row[3]))
        magx.append(float(row[4]))
        magy.append(float(row[5]))
        magz.append(float(row[6]))
        # print "%d: %f, %f, %f, %f" % (cnt, ts2[cnt], magx[cnt], magy[cnt], magz[cnt])
        f.write("%f,%.15f,%.15f,%.15f\n" % (ts2[cnt], magx[cnt], magy[cnt], magz[cnt]))

        cnt += 1
    f.close()
