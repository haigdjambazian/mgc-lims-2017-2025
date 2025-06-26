'''
Created on July 30, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
original name - NavaSeq_create_status_request.py has been changed to IlluminaSeq_create_status_request.py

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
#BASE_URI='https://bravotestapp.genome.mcgill.ca/api/v2/'
script_dir=os.path.dirname(os.path.realpath(__file__))

HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False

parser = argparse.ArgumentParser(description='Generate status request file for Illumina ')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')

parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-attachFilesLUIDs',default='', help='LUIDs for report files attachment')
parser.add_argument('-filepath',default='/opt/gls/clarity/ai/temp/', help='temp file path')



args = parser.parse_args()
stepURI_v2=args.stepURI_v2
user_psw = args.user_psw

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

sTempDataPath='/opt/gls/clarity/ai/temp/'
#sSubFolderName=sDataPath+time.strftime('%Y/%m/')
sProjectName=''
sProbeArrayType=''
sBarcode=''
ProcessID=''
ArtifactsLUID={}
Projects_hash={}
#(FileReportLUID1, FileReportLUID2, FileReportLUID3,FileReportLUID4,FileReportLUID5)=attachLUIDs.split(' ')

sHeader='ProcessLUID\tContainerLUID\tContainerName\tLane\tArtifactLUID\tAtrifactName\n'



'''

'''
def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI
    global ProcessID

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"
    ProcessID=tokens[-1]

    if DEBUG is True:
        print (HOSTNAME)
        print (BASE_URI)

def get_projects_list():
    ss=BASE_URI+"projects/"
    
    r = requests.get(ss, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    nodes= rDOM.getElementsByTagName("project")
    for node in nodes:
       # projectNode = node.getElementsByTagName( "project" )
        projLUID = node.getAttribute( "limsid" )
        projName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
        Projects_hash[projLUID]=projName
        

    return 




def get_project_params(processURI_v2):
    global user,psw,sLibraryKit, sBCLMode,sReference, ProcessID
    r = requests.get(processURI_v2, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    nodes= rDOM.getElementsByTagName("prc:process")
    for input in nodes:
        uriType = input.getAttribute( "uri" )
        limsidType = input.getAttribute( "limsid" )
        ProcessID= limsidType     
    sLibraryKit=getUDF(rDOM, 'LibraryKit')
    sBCLMode=getUDF(rDOM, 'BCLMode')
    sReference=getUDF(rDOM, 'Reference')    

    return sLibraryKit, sBCLMode,sReference


def get_process_UDFs(ProcessID):
    global user,psw, hProjects,sLibraryKit, sBCLMode, sReference
    processURI=BASE_URI+'processes/'+ProcessID
    
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    
#    sProjectName=getUDF(rDOM, 'AGCC Project')
    sLibraryKit=getUDF(rDOM, 'LibraryKit')
    sBCLMode=getUDF(rDOM, 'BCLMode')
    sReference=getUDF(rDOM, 'Reference')
          
    return sLibraryKit, sBCLMode, sReference    

def create_io_map(processLuid):

    global user,psw
    io_map={}
    
    

    ## get the process XML
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    #print (pXML.content)
    pDOM = parseString( pXML.content )

    ## get the individual resultfiles outputs
    nodes = pDOM.getElementsByTagName( "input-output-map" )
    for node in nodes:
        input = node.getElementsByTagName("input")
        iURI = input[0].getAttribute( "post-process-uri" )
        iLUID = input[0].getAttribute( "limsid" )
        output=node.getElementsByTagName("output")
        oType = output[0].getAttribute( "output-type" )
        ogType = output[0].getAttribute( "output-generation-type" )
        oLUID = output[0].getAttribute( "limsid" )

        if oType == "ResultFile" and ogType == "PerInput":
            if oLUID not in io_map:
                io_map[ iLUID]=oLUID
    return io_map 

def prepare_samples_list_for_batch(sXML):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    pDOM = parseString( sXML )
    nodes = pDOM.getElementsByTagName( "sample" )
    for node in nodes:
        sampleURI=node.getAttribute("uri")
        lXML.append( '<link uri="' + sampleURI + '" rel="samples"/>' )  

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_asamples(sXML):
    sURI=BASE_URI+'samples/batch/retrieve'
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    return r.content



def prepare_artifacts_batch(ArtifactsLUID):
    global BASE_URI
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in ArtifactsLUID:
        scURI = BASE_URI+'artifacts/'+art
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_artifacts(sXML):
    global BASE_URI, user,psw, containerName
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content

def create_status_request_file():
    sTabOutput=sHeader
    
    for artifactLUID in container_hash:
        (artifactName,artPosition,containerLUID,containerName)=container_hash[artifactLUID]
        
        lane=artPosition.split(':')[0]
        #resultFileLUID=artifact_io_map[artifactLUID]
        #print (str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(ContainerID)+"\t"+ ContainerName +"\t"+ContainerPosition+"\t"+ str(sampleLUID)+"\t"+ sampleName+"\t"+Reference+"\t"+sLibraryKit+"\t"+ sBCLMode )
        sTabOutput +=str(ProcessID)+"\t"+str(containerLUID)+"\t"+ containerName +"\t"+lane+"\t"+ str(artifactLUID)+"\t"+ str(artifactName)+"\n" 
        
     
    return sTabOutput



def extract_containers (sXML):
    global container_hash
    container_hash={}
    rDOM = parseString( sXML )
    for nodes  in rDOM.getElementsByTagName('art:artifact'):
        artLUID= nodes.getAttribute( "limsid" )
        artName= nodes.getElementsByTagName('name')[0].firstChild.nodeValue
        artPosition=nodes.getElementsByTagName('value')[0].firstChild.nodeValue
        containerLUID=nodes.getElementsByTagName('container')[0].getAttribute('limsid')
        if artLUID not in container_hash:
            containerName=get_container_name(containerLUID)
            container_hash[artLUID]=(artName,artPosition,containerLUID,containerName)
    return container_hash


def get_container_name(containerID):
    sURI=BASE_URI+'containers/'+containerID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    contName = node[0].firstChild.nodeValue
    #contPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
    return contName



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

def write_file2(sText):
    sExtra=str(ProcessID)+"_status_request.txt"
    f_out=open(FileReportLUID2+sExtra,"w")
    f_out.write(sText)
    f_out.close()
    
    return

'''
    Start
    
'''
def main():
    
    if (stepURI_v2) :
        setupGlobalsFromURI(stepURI_v2)
       
        global artifact_io_map
        artifact_io_map=create_io_map(ProcessID)
        sXML=prepare_artifacts_batch(artifact_io_map)
        lXML=retrieve_artifacts(sXML)
        container_hash =extract_containers(lXML)
        outFile=create_status_request_file()
        print (outFile)
        
 

        
if __name__ == "__main__":
    main()   
  
