'''
Created on March 19, 2017

@author: Alexander Mazur, alexander.mazur@gmail.com
Note: 

'''


__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os
from optparse import OptionParser
import numpy as np
import numpy.polynomial.polynomial as poly
import time
import requests
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET



  

user=''
psw=''
script_dir=os.path.dirname(os.path.realpath(__file__))
HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False


NO_TAPE_path="\\\\abacusfs.genome.mcgill.ca\\instruments\\GeneTitan_notapebackup\\ProjectDATA\\"


# robocopy \\abacusfs.genome.mcgill.ca\instruments\GeneTitan_notapebackup\ProjectDATA\OPPERA\OPPERA_AX001 E:\OPPERA\OPPERA_AX001 *.cel /e /z /mir
def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-c', "--cLUIDs", action='store', dest='compound LUIDs for the generated files')
    Parser.add_option('-a', "--activeStep", action='store', dest='activeStep')

    return Parser.parse_args()[0]



 
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

def create_io_map(stepURI_v2):
    global details,ArtifactURIs
    
    ArtifactURIs=[]
    pURI=stepURI_v2+"/details"
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    details = parseString( pXML.content )
    #print api.GET( stepURI + "/details" )
    for io in details.getElementsByTagName("input-output-map"):
        inputartURIState = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartURI = inputartURIState.split( "?" )[0]  # remove state
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")

        outputartURIState = io.getElementsByTagName("output")[0].getAttribute("uri")
        outputartURI = outputartURIState.split( "?" )[0]  # remove state
        outputartLUID = io.getElementsByTagName("output")[0].getAttribute("limsid")
        
        
#    INPUTS
#        if inputartURI not in ArtifactURIs:
#           ArtifactURIs.append( inputartURI )

        if outputartURI not in ArtifactURIs:
           ArtifactURIs.append( outputartURI )



    return 
def create_local_io_map(stepURI_v2):
    global details,localArtifactURIs
    
    localArtifactURIs=[]
    pURI=stepURI_v2+"/details"
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    details = parseString( pXML.content )
    #print api.GET( stepURI + "/details" )
    for io in details.getElementsByTagName("input-output-map"):
        inputartURIState = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartURI = inputartURIState.split( "?" )[0]  # remove state
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")

        outputartURIState = io.getElementsByTagName("output")[0].getAttribute("uri")
        outputartURI = outputartURIState.split( "?" )[0]  # remove state
        outputartLUID = io.getElementsByTagName("output")[0].getAttribute("limsid")
        
        
#    INPUTS
        if inputartURI not in localArtifactURIs:
           localArtifactURIs.append( inputartURI )
#    OUTPUTS
#        if outputartURI not in ArtifactURIs:
#           ArtifactURIs.append( outputartURI )



    return 

def get_local_containers(artifactsXML):
    details = parseString( artifactsXML )
    #print api.GET( stepURI + "/details" )
    for node in details.getElementsByTagName("container"):
        containerLUID=node.getAttribute('limsid')
        containerURI=node.getAttribute('uri')
        

        if containerLUID not in localContainers:
           localContainers.append( containerLUID )
           if DEBUG:
               print (containerLUID)



    return 


def prepare_artifacts_batch(ArtifactURIs):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    for artURI in ArtifactURIs:
        lXML.append( '<link uri="' + artURI + '" rel="artifacts"/>' )        
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 
    return lXML 

def retrieve_artifacts(sXML):
    global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'

    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
  
    return r.content

def get_meta_from_artifacts(artXML):
    
    meta_hash={}
    nodes = parseString( artXML )
    #print api.GET( stepURI + "/details" )
    for node in nodes.getElementsByTagName("art:artifact"):
        pProcessID = node.getElementsByTagName("parent-process")[0].getAttribute("limsid")

        containerURI = node.getElementsByTagName("container")[0].getAttribute("uri")
        containerLIMSID = node.getElementsByTagName("container")[0].getAttribute("limsid")
        if containerLIMSID in localContainers:
            containerName= get_container_name(containerURI)
            sampleLUID = node.getElementsByTagName("sample")[0].getAttribute("limsid")
            projLUID=sampleLUID[0:6]
            isControl=projLUID.split("-")
            if len(isControl) ==1:
                projectAcro=Projects_hash[projLUID].split("xxx")[1]
                key=containerLIMSID+"_"+pProcessID
                if (key not in meta_hash):
                    meta_hash[key]=projLUID+"xxx"+projectAcro+"xxx"+containerName
                    if DEBUG is True:
                        print (projLUID,projectAcro,containerName, containerLIMSID,pProcessID)

    return meta_hash



def write_robocopy(meta_hash):
    sRoboSW="robocopy "
    ss=""
    for key in meta_hash:
        (containerLIMSID,pProcessID)=key.split("_")
        (projLUID,projectAcro,containerName)=meta_hash[key].split("xxx")
#    PArent Process
#        src=NO_TAPE_path+projectAcro+"_"+containerName+"_"+pProcessID+"\\"+containerName+"_"+pProcessID
#        dst="  E:\\"+projectAcro+"_"+containerName+"_"+pProcessID+"\\"+containerName+"_"+pProcessID
        src=NO_TAPE_path+projectAcro+"_"+containerName+"_"+activeProcessID+"\\"+containerName+"_"+activeProcessID
        dst="  E:\\"+projectAcro+"_"+containerName+"_"+activeProcessID+"\\"+containerName+"_"+activeProcessID

        sFiles=" *.cel /e /z /mir"
        ss +=sRoboSW+src+dst+sFiles+"\n"
    return ss

     
def get_container_name(containerURI):
    global BASE_URI, user,psw
    r = requests.get(containerURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue
    return ss



def get_projects_list():
    ss=BASE_URI+"projects/"
    r = requests.get(ss, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    nodes= rDOM.getElementsByTagName("project")
    for node in nodes:

        projLUID = node.getAttribute( "limsid" )
        projName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
        if projLUID not in Projects_hash:
            Projects_hash[projLUID]=projName
            get_project_info(projLUID)
        if DEBUG:
            print (projLUID,projName)
    return 

def get_project_info(projectID):
    
    if projectID in Projects_hash:
        ss=BASE_URI+"projects/"+projectID
        r = requests.get(ss, auth=(user, psw), verify=True)
        rDOM = parseString(r.content)
        nodes= rDOM.getElementsByTagName("prj:project")
        for node in nodes:
           # projectNode = node.getElementsByTagName( "project" )
            projLUID = node.getAttribute( "limsid" )
            projName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
            sProjAcronym="xxx"
            for key in node.getElementsByTagName('udf:field'):
                udf = key.getAttribute( "name")
                if (udf=="Project acronym"):
                    sProjAcronym=key.firstChild.nodeValue  
                Projects_hash[projLUID]=projName+"xxx"+sProjAcronym
    return 

def get_parent_process(processID,parentProcessID):
    sURI=BASE_URI+'processes/'+processID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    #r=api.GET(sURI)
    rDOM = parseString( r.content )
    #print (r.content)
    ppTYpe=rDOM.getElementsByTagName( "type" )[0].firstChild.nodeValue
    if processID not in parentProcessLUIDs:
       parentProcessLUIDs[processID]=parentProcessID+","+ppTYpe
       if DEBUG:
           print (processID+","+parentProcessLUIDs[processID])    
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in parentProcessLUIDs:
            get_parent_process(pProcessLUID,processID)

def get_processID_by_processType(parentProcessLUIDs,processType):
    ss="N/A"
    for key in parentProcessLUIDs:
        (parentProcessID,ppTYpe)=parentProcessLUIDs[key].split(",")
        #print (parentProcessID,ppTYpe)
        if (ppTYpe == processType):
            ss=(key,parentProcessID)
            if key not in activeLUIDs:
                activeLUIDs[key]=parentProcessID            
            if DEBUG:
                print (ss)
        
    return ss
  

       

'''
    Start
    
'''




def main():
    global args, user, psw, Projects_hash,parentProcessLUIDs, activeProcessID, activeLUIDs,  localContainers, localArtifactURIs
    args = setup_arguments()
    user=args.username
    psw=args.password
    activeStep=args.activeStep
    Projects_hash={}
    parentProcessLUIDs={}
    activeLUIDs={}
    localContainers=[]
    
        
    if (args.stepURI) :
        setupGlobalsFromURI(args.stepURI)
        get_projects_list()
        
        create_local_io_map(args.stepURI)
        localArtRIXML=prepare_artifacts_batch(localArtifactURIs)
        if DEBUG:
            print (localArtRIXML)
        localRetXML=retrieve_artifacts(localArtRIXML)
        #print (localRetXML)   
        get_local_containers(localRetXML)     
        #exit()
        '''
         Create list of parent processes
        '''    
        get_parent_process(ProcessID,"")
        '''
         Get an active processID
        '''        
        (activeProcessID,parentProcessID)=get_processID_by_processType(parentProcessLUIDs,activeStep) 
        for activeProcessID in activeLUIDs:   
        
            activeProcessURI=BASE_URI+'steps/'+activeProcessID        
            if DEBUG:
                print (activeProcessURI)    
            
            
            create_io_map(activeProcessURI)
            artRIXML=prepare_artifacts_batch(ArtifactURIs)
            if DEBUG:
                print (artRIXML)
            retXML=retrieve_artifacts(artRIXML)
    #        print (retXML)
            m_hash=get_meta_from_artifacts(retXML)
    #        for key in m_hash:
    #            print (key, m_hash[key])
            sRoboCopy=write_robocopy(m_hash)
            print (sRoboCopy)
        

       
        
if __name__ == "__main__":
    main()   
    