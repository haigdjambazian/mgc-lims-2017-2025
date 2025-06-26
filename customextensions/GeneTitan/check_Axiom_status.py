'''
Created on May 10, 2017

@author: Alexander Mazur, alexander.mazur@gmail.com
'''

__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os
import numpy as np
import numpy.polynomial.polynomial as poly
import time
import requests
import re
from xml.dom.minidom import parseString

import xml.etree.ElementTree as ET


  

user=''
psw=''
URI_base='https://bravotestapp.genome.mcgill.ca/api/v2/'
script_dir=os.path.dirname(os.path.realpath(__file__))

parser = argparse.ArgumentParser(description='Check the status of the Axiom Analysis pipeline')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
parser.add_argument('-processLuid',default='', help='processLuid from WebUI')
parser.add_argument('-fileLuid',default='', help='fileLuid from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')

'''
{stepURI:v2}
http://localhost:9080/api/v2/steps/24-1297
'''
args = parser.parse_args()
fileLuid=args.fileLuid
stepURI_v2=args.stepURI_v2
processLuid=args.processLuid
user_psw = args.user_psw

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

sDataPath='/lb/project/techdev/bravotest/GeneTitanprocessing_test_backuptape/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
hProjects={}
aparentProcessID=[]
artifactArray=[]
sProjectName=''
sProbeArrayType=''
container_barcodes=''
container_ID=''




'''

'''

def get_parent_process(processLuid):
    global user,psw, hProjects, URI_base, aparentProcessID
    process=URI_base+'processes/'+processLuid

    r = requests.get(process, auth=(user, psw), verify=True)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    pDOM = parseString( r.content )
    ## get the individual resultfiles outputs
    nodes = pDOM.getElementsByTagName( "parent-process" )
    for input in nodes:
        uriType = input.getAttribute( "uri" )
        limsidType = input.getAttribute( "limsid" )
        if limsidType not in aparentProcessID:
                aparentProcessID.append( limsidType )
        #print (uriType, limsidType)

    return

def check_status_done(aparentProcessID):
    global sDataPath
    sDoneFile=sDataPath+aparentProcessID[0]+'/'+aparentProcessID[0]+'.done'
    s="Run is in process...try again later"
    if (os.path.isfile(sDoneFile) ):
        s="Done"
    return s

def attach_report(aparentProcessID,fileLuid):
    global sDataPath
    sDoneFile=sDataPath+aparentProcessID[0]+'/'+aparentProcessID[0]+'.report.html'
    #sDest=script_dir+'/'+fileLuid+'_'+aparentProcessID[0]+'.report.html'
    sDest=fileLuid+'_'+aparentProcessID[0]+'.report.html'    
    #print(sDest)
    shutil.copy(sDoneFile, sDest)
    return
    

'''
    Start
    
'''

get_parent_process(processLuid)
#print (aparentProcessID)
statDone=check_status_done(aparentProcessID)
print(statDone)
if (statDone=='Done'):
    attach_report(aparentProcessID,fileLuid)
    


