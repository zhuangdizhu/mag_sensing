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
    if len(sys.argv) != 5:
        sys.exit('Usage:    preprocess_signal.py <Mode:Single(S) or Multipl(M)> <AppType:IOS(I) or Android(A)> <InputFile:FileName> <OutputFile:FileName')
        sys.exit('Example:  preprocess_signal.py S A 20150523.exp01 20150523exp01')
    force_utf8_hack()
    mode=sys.argv[1]
    app = sys.argv[2]
    input_filename = sys.argv[3]
    output_filename = sys.argv[4]
    if DEBUG2: print "Preprocess: %s %s %s %s" % (mode, app, input_filename, output_filename)
    ###################
    ## Read Event Time
    ###################
    if DEBUG2: print "Read Event Time"
    #event_ts   = []
    event_type = dict()  ## event and its type
    type_cnt   = 0
    if mode == "S":
        f = open(input_dir + output_filename + ".app_time_processed.txt", 'w')
        with open(input_dir + input_filename + ".app_time.txt", 'rb') as csvfile:
            spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
            for row in spamreader:
                if row[1] in event_type:
                    pass
                else:
                    event_type[row[1]] = type_cnt
                    type_cnt += 1
                f.write("%s,%d\n" % (row[0], event_type[row[1]]))

    else:
        f = open(input_dir + output_filename + ".multi_app_time_processed.txt", 'w')
        with open(input_dir + input_filename + ".multi_app_time.txt", 'rb') as csvfile:
            spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
            for row in spamreader:
                if row[1] in event_type:
                    pass
                else:
                    event_type[row[1]] = type_cnt
                    type_cnt += 1
                if row[2] in event_type:
                    pass
                else:
                    event_type[row[2]] = type_cnt
                    type_cnt += 1
                f.write("%s,%d,%d\n" % (row[0], event_type[row[1]], event_type[row[2]]))
    f.close()

    ###################
    ## Read SensorLog Data
    ###################
    if DEBUG2: print "Read SensorLog Data"
    ts2  = []
    magx = []
    magy = []
    magz = []
    mags = []
    postfix = ''
    if mode == "S":
        f = open(input_dir + output_filename + ".mag_processed.txt", 'w')
        postfix = ".mag.csv"

    else:
        f = open(input_dir + output_filename + ".multi_mag_processed.txt", 'w')
        postfix = ".multi_mag.csv"

    if app == 'A' or app == 'I':
        with open(input_dir + input_filename + postfix, 'rb') as csvfile:
            spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
            spamreader = list(spamreader)
            spamreader.pop(0)
            cnt = 0
            for row in spamreader:
                if app == 'A':
                    if len(row) < 5: continue
                    ts2.append(float(row[0]))
                    magx.append(float(row[1]))
                    magy.append(float(row[2]))
                    magz.append(float(row[3]))
                    mags.append(float(row[4]))
                    f.write("%.2f,%.2f,%.2f,%.2f,%.2f\n" % (ts2[cnt], magx[cnt], magy[cnt], magz[cnt], mags[cnt]))
                    cnt += 1
                elif app == 'I':
                    if row[0] == "" or row[13] == "" or row[14] == "" or row[15] == "": continue
                    ts2.append(float(row[0]))
                    magx.append(float(row[13]))
                    magy.append(float(row[14]))
                    magz.append(float(row[15]))
                    f.write("%.2f,%.2f,%.2f,%.2f\n" % (ts2[cnt], magx[cnt], magy[cnt], magz[cnt]))
                    cnt += 1
    elif app == 'I2':
        with open(input_dir + input_filename + ".x.txt", 'rb') as csvfile:
            spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
            spamreader = list(spamreader)
            for row in spamreader:
                #print(row[1])
                magx.append(float(row[1]))

                tmpTime = row[0].split()[1]
                curr_time = float(tmpTime.split(':')[2])+float(tmpTime.split(':')[1])*60
                ts2.append(curr_time)
        with open(input_dir + input_filename + ".y.txt", 'rb') as csvfile:
            spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
            spamreader = list(spamreader)
            for row in spamreader:
                magy.append(float(row[1]))
        with open(input_dir + input_filename + ".z.txt", 'rb') as csvfile:
            spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
            spamreader = list(spamreader)
            for row in spamreader:
                magz.append(float(row[1]))

        cnt = len(spamreader)
        for curr_cnt in range(cnt):
            f.write("%.2f,%.2f,%.2f,%.2f\n" %(ts2[curr_cnt],magx[curr_cnt],magy[curr_cnt],magz[curr_cnt]))
    f.close()
