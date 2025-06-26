'''
Created on May 05, 2017

@author: Alexander Mazur, alexander.mazur@gmail.com
'''
from numpy.lib.user_array import container

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
#BASE_URI='https://bravotestapp.genome.mcgill.ca/api/v2/'
script_dir=os.path.dirname(os.path.realpath(__file__))
HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False


parser = argparse.ArgumentParser(description='Generate Excel file for Axiom Analysis')
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

sDataPath='/data/glsftp/clarity/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
hProjects={}
aparentProcessID=[]
artifactArray={}
sProjectName=''
sProbeArrayType=''
container_barcodes=''
Affy_barcode=''
sHeader='Sample File Path,Project,Plate Type,Probe Array Type,Probe Array Position,Barcode,Sample File Name,Array Name'



'''

'''
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





def get_projects(BASE_URI):
    global user,psw, hProjects
    sprojects=BASE_URI+'projects'
    r = requests.get(sprojects, auth=(user, psw), verify=True)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    #print (r.content)
    root = ET.fromstring(r.content)
    for child in root:
        limsid=child.attrib['limsid']
        project_name=child[0].text
        #print (limsid, project_name)
        hProjects[limsid]=project_name
    return

def get_parent_process(processLuid):
    global user,psw, hProjects, BASE_URI, aparentProcessID
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

def get_parent_process_UDFs(aparentProcessID):
    global user,psw, hProjects
    processURI=BASE_URI+'processes/'+aparentProcessID
    
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    
#    sProjectName=getUDF(rDOM, 'AGCC Project')
    sProbeArrayType=getUDF(rDOM, 'Array Type')
    sBarcode=getUDF(rDOM, 'Barcode')    

    return sBarcode, sProbeArrayType


 

def get_output_artifacts_from_step(stepID):
    global BASE_URI,user,psw, container_ID, aparentProcessID
    sURI=BASE_URI+'steps/'+stepID +'/placements'
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM=parseString( r.content )
    myNodes=rDOM.getElementsByTagName('container')
    for node in myNodes:
        container_ID=node.getAttribute('limsid')
    #containerID=cont.getAttribute('uri')
    #container_barcodes=get_container_name('', containerID)
    scNodes =rDOM.getElementsByTagName('output-placement')
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for sc in scNodes:
        scURI = sc.getAttribute( "uri")
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def get_input_artifacts_from_step(stepID):
    global BASE_URI,user,psw, container_ID, aparentProcessID
    sURI=BASE_URI+'steps/'+stepID+'/details' 
    s=""
    
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )    
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM=parseString( r.content )
    for io in rDOM.getElementsByTagName("input-output-map"):
        inputartURI = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        if inputartURI not in artifactArray:
            lXML.append( '<link uri="' + inputartURI+ '" rel="artifacts"/>' )
            artifactArray[inputartURI] =inputartLUID       

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 


   
def get_filesID_from_artifacts(sXML):    
    global user,psw, hProjects, BASE_URI, aparentProcessID,container_barcodes, Affy_barcode, sProbeArrayType
    process=BASE_URI+'processes/'+processLuid

#    r = requests.get(process, auth=(user, psw), verify=True)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    pDOM = parseString( sXML )
    
    #print (sXML)
    root = ET.fromstring(sXML)
    ss=''
    
    sHeader='ProjectName,ProjectID,ContainerID,ContainerName,AffyBarCode,ProbeArrayType,Position,SampleName,SampleID,ArtifactID,FileLocation,ProcessID'
    print(sHeader)
    proj="XXX"
    for child in root.findall('art:artifact',nss):
        #print (child)
        limsid=child.attrib['limsid']
        name = child.find('name')
        parentID=child.find('parent-process')
        sLocation=child.find('location')
        container=sLocation.find('container')
        containerName=containerIDs[container.attrib['limsid']]
        
        pos=sLocation.find('value')
        sample= child.find('sample')
        metaProj=sample.attrib['limsid'][0:6]

        for sProj in hProjects:
            if (metaProj.find(sProj)>=0):
                #print (hProjects[sProj])
                proj=hProjects[sProj]
                

                
                
        
        comment=''
        for udf in child.findall('udf:field', nss):
            if udf.attrib['name']=='.arr File Location':
                comment=udf.text
                print(proj+','+ metaProj+','+container.attrib['limsid']+','+containerName+','+Affy_barcode+','+sProbeArrayType+','+pos.text+','+name.text+','+sample.attrib['limsid']+','+limsid+','+ comment+','+ parentID.attrib['limsid'] )
    return

def get_containers_from_artifacts(sXML):    
    global containerIDs

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    root = ET.fromstring(sXML)
    ss=''
    containerIDs={}
    for child in root.findall('art:artifact',nss):
        sLocation=child.find('location')
        container=sLocation.find('container')
        if container.attrib['limsid'] not in containerIDs:
            containerIDs[container.attrib['limsid']]=container.attrib['uri']

    return
def get_containers_ID(containerIDs):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for cURI in containerIDs:
        
        lXML.append( '<link uri="' + containerIDs[cURI] + '" rel="containers"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 
    
    return lXML


def retrieve_artifacts(sXML):
    global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content

def retrieve_containers(sXML):

    sURI=BASE_URI+'containers/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content


def extract_container_ID (sXML):
    global BASE_URI
    s=''
    sLocalBaseURI="http://localhost:9080/api/v2/"
    s=sXML.replace('<container uri="'+BASE_URI+'containers/','')
    s=sXML.replace('<container uri="'+sLocalBaseURI+'containers/','')
    s=s.replace('"/>', '')
    s="".join(s.split())
    
    return s


def get_containers_name(rcXML):
    rDOM = parseString(rcXML )
    
 
    for child in rDOM.getElementsByTagName("con:container"):
       
        containerLUMSID=child.getAttribute("limsid")
        containerName=child.getElementsByTagName("name")[0]
        if containerLUMSID in containerIDs:
            containerIDs[containerLUMSID]=containerName.firstChild.data
        #print (limsid, sName.firstChild.data)

    return 


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

def getUDF( rDOM, udfname ):
    response = ""
    elements = rDOM.getElementsByTagName( "udf:field" )
    for udf in elements:
        temp = udf.getAttribute( "name" )
        if temp == udfname:
            response = getInnerXml( udf.toxml(), "udf:field" )
            break
    return response




'''
    Start
    
'''

setupGlobalsFromURI(stepURI_v2)


get_projects(BASE_URI)
#print (hProjects)
get_parent_process(processLuid)
(Affy_barcode, sProbeArrayType)=get_parent_process_UDFs(aparentProcessID[0])
#print (aparentProcessID)
#sXML=get_output_artifacts_from_step(aparentProcessID[0])
sXML=get_input_artifacts_from_step(processLuid)
#print (sXML)
artXML=(retrieve_artifacts(sXML))
#print (artXML)
get_containers_from_artifacts(artXML) 


ccXML=get_containers_ID(containerIDs)

rcXML=retrieve_containers(ccXML)

#print (rcXML)
get_containers_name(rcXML)
get_filesID_from_artifacts(artXML)

exit()
#container_barcodes=get_container_name(container_ID, '')

#print (container_barcodes)




