'''
Created on December 13, 2016

@author: Alexander Mazur, mazur@ieee.org
'''
__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os

from time import gmtime, strftime
import requests
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET

user=''
psw=''
#URI_base='https://bravotestapp.genome.mcgill.ca/api/v2/'

HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = True

script_dir=os.path.dirname(os.path.realpath(__file__))

parser = argparse.ArgumentParser(description='Applying quantified concentration values to the WebUI')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-labelSTD',default='0', help='Barcode for STD plate')
parser.add_argument('-name1',default='', help='Barcode NAME1')
parser.add_argument('-name2',default='Pico', help='Barcode NAME2')
parser.add_argument('-labelSuffix',default='', help='Barcode suffixes for different plates with the same LUIDs')


args = parser.parse_args()
stepURI_v2=args.stepURI_v2
user_psw = args.user_psw
labelSTD = args.labelSTD
labelSuffix = args.labelSuffix
name1 = args.name1
name2 = args.name2
#if not (na me1):
#    name1=strftime("%Y-%m-%d %H:%M")
iQty=1
sDF='10'


if (user_psw):
    (user,psw)=user_psw.split(':')




def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"

    if DEBUG:
        print (HOSTNAME)
        print (BASE_URI)



def get_placement_containers(stepURI_v2):
    global user,psw, container_barcodes, name1, name2, sDF,labelSTD
    sURI=stepURI_v2 +'/placements'
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
    #print (r.content)
    rDOM = parseString( r.content )
    i=0

    sDF='DF='+str(sDF)
    name2=name2+' '+sDF
    sCSV=""
    for node in rDOM.getElementsByTagName('selected-containers'):
#        s=node.toxml()
        sIndex=""
        containerLUID=node.getElementsByTagName('selected-container')[0].getAttribute('limsid')
        
        #ss=extract_container_ID (containerLUID)
        sContainerName=get_container_name(containerLUID)
        
        if (containerLUID):
            if not (name1):
                name1=sContainerName
            if (i==0):
                sCSV ='Plate ID,Name 1,Name 2\n'
                sCSV += containerLUID+'c,'+name1+' STD,'+name2+'\n'
            sCSV += containerLUID+','+name1+','+name2+'\n'
            i=i+1
    return sCSV




def get_container_name(containerID):
    global BASE_URI, user,psw
    sURI=BASE_URI+'containers/'+containerID
#    print('\n')
    
    #print('\n')
    r = requests.get(sURI, auth=(user, psw), verify=True)
    #print (r.content)
    rDOM = parseString(r.content )
    #print (r.content)
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue

    return ss

def get_container_name_limsid(containerURI):
    global BASE_URI, user,psw
    #sURI=BASE_URI+'containers/'+containerID
#    print('\n')
    
    #print('\n')
    r = requests.get(containerURI, auth=(user, psw), verify=True)
    #print (r.content)
    rDOM = parseString(r.content )
    #print (r.content)
    conNodes=rDOM.getElementsByTagName('con:container')
    node =conNodes.getElementsByTagName('name')
    containerName=node[0].firstChild.nodeValue
    containerLUID=conNodes.getAttribute('limsid')

    return containerLUID,containerName



def get_PG_calibration_params(stepURI_v2):
    global user,psw
    stepURI_v2 = stepURI_v2.replace('steps','processes')
    r = requests.get(stepURI_v2, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    sDF=getUDF(rDOM, 'DF')
    sRep_outlier=getUDF(rDOM, 'Replica outlier')
    sFitMethod=getUDF(rDOM, 'Fitting Method')    
    return int(sDF), sRep_outlier,sFitMethod

def get_HYbr_calibration_params(stepURI_v2):
    global user,psw,iQty
    stepURI_v2 = stepURI_v2.replace('steps','processes')
    r = requests.get(stepURI_v2, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    sQty=getUDF(rDOM, 'Barcodes Qty')
    
    if (sQty):
        iOut=int(sQty)
    else:
        iOut=iQty
    return iOut

def get_Hybr_placement_containers(stepURI_v2):
    global user,psw, container_barcodes, name1, name2,labelSTD,iQty
    sURI=stepURI_v2 +'/placements'
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
#    if DEBUG:
#        print (sURI,r.content)
    rDOM = parseString( r.content )
    i=0

    sCSV=""
    for node in rDOM.getElementsByTagName('selected-containers'):

        containerURI=node.getElementsByTagName('container')[0].getAttribute('uri')
       
        jj=0

#        sContainerName=get_container_name(containerLUID)
        (containerLUID,sContainerName)=get_container_name_limsid(containerURI)
        if DEBUG:
            print("containerLUID=\t"+containerURI+"\t"+sContainerName)
        
        if containerLUID:
            if not (name1):
                name1=sContainerName
            if (i==0):
                sCSV ='Plate ID,Name 1,Name 2\n'                
            while jj <iQty:
                sCSV += containerLUID+','+name1+','+str(jj+1)+'\n'
                jj +=1
            i=i+1
            
            
    return sCSV


def getUDF( rDOM, udfname ):
    response = ""
    elements = rDOM.getElementsByTagName( "udf:field" )
    for udf in elements:
        temp = udf.getAttribute( "name" )
        if temp == udfname:
            response = getInnerXml( udf.toxml(), "udf:field" )
            break
    return response

def getInnerXml(xml, tag):
    """Returns the contents inside of a tag in a given Xml tag string.
        Keyword arguments:
        xml -- The Xml tag string to extract contents from
        tag -- The tag in which to retrieve contents
    """
    tagname = '<' + tag + '.*?>'
    inXml = re.sub(tagname, '', xml)
    tagname = '</' + tag + '>'
    inXml = inXml.replace(tagname, '')
    return inXml

'''

    START

'''

setupGlobalsFromURI(stepURI_v2)
#print (BASE_URI)
#exit()


if (labelSTD=="1"):
    (sDF, sRep_outlier,sFitMethod)= get_PG_calibration_params(stepURI_v2)
    ss= get_placement_containers(stepURI_v2)
if (labelSTD=="0"):
    iQty= get_HYbr_calibration_params(stepURI_v2)
    ss= get_Hybr_placement_containers(stepURI_v2)


print(ss)
