'''
Created on June 27, 2017

@author: Alexander Mazur, alexander.mazur@gmail.com
'''

__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os, socket
import numpy as np
import time
import requests
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET


user=''
psw=''
#BASE_URI='https://bravotestapp.genome.mcgill.ca/api/v2/'
script_dir=os.path.dirname(os.path.realpath(__file__))
HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False


parser = argparse.ArgumentParser(description='Generate get parentProcessLUID and delete file .unassigned to flash AGCC daemon')
parser.add_argument('-processLuid',default='', help='processLuid from WebUI')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')


args = parser.parse_args()

processLuid=args.processLuid
user_psw = args.user_psw
stepURI_v2=args.stepURI_v2

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

aparentProcessID=[]

def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"

    if DEBUG is True:
        print (HOSTNAME)
        print (BASE_URI)




def get_parent_process(processLuid):
    global user,psw, BASE_URI, aparentProcessID
    process=BASE_URI+'processes/'+processLuid

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

def delete_unassigned_file(parentProcessID):
    sHost=socket.gethostname()
    s=""
    if (sHost.find('dev') >0):
        s="dev"
    if (sHost.find('test') >0):
        s="test"
    if (sHost.find('prod') >0):
        s="prod"
        
     
    bashCommand = "rm /lb/robot/GeneTitan/"+s+"/"+parentProcessID+"/.unprocessed"
    #print (bashCommand)
    import subprocess
    process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
    (output, error) = process.communicate()
    print (output, error)
    
    




'''
    Start
    
'''

setupGlobalsFromURI(stepURI_v2)

get_parent_process(processLuid)
delete_unassigned_file(aparentProcessID[0])
#print (aparentProcessID[0])
