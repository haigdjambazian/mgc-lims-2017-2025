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
import xml.dom.minidom
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
NO_TAPE_new="/robot/GeneTitan/ProjectDATA/"

# robocopy \\abacusfs.genome.mcgill.ca\instruments\GeneTitan_notapebackup\ProjectDATA\OPPERA\OPPERA_AX001 E:\OPPERA\OPPERA_AX001 *.cel /e /z /mir
def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
#    Parser.add_option('-c', "--cLUIDs", action='store', dest='compound LUIDs for the generated files')
    Parser.add_option('-a', "--activeStep", action='store', dest='activeStep')
    Parser.add_option('-c',"--containerSource", action='store', dest='containerSource')    

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
        
        
        if containerSource == 'input':
            if inputartURI not in ArtifactURIs:
               ArtifactURIs.append( inputartURI )
        if containerSource == 'output':
            if outputartURI not in ArtifactURIs:
               ArtifactURIs.append( outputartURI )               
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
    global meta_hash
    
    meta_hash={}

    nodes = parseString( artXML )
    #print api.GET( stepURI + "/details" )
    for node in nodes.getElementsByTagName("art:artifact"):
        pProcessID = node.getElementsByTagName("parent-process")[0].getAttribute("limsid")

        artType=node.getElementsByTagName('type')[0].firstChild.nodeValue
        if artType == 'Analyte':
            containerURI = node.getElementsByTagName("container")[0].getAttribute("uri")
            containerLIMSID = node.getElementsByTagName("container")[0].getAttribute("limsid")
            containerName= get_container_name(containerURI)
            artifactLUID=node.getAttribute("limsid")
            sampleLUID = node.getElementsByTagName("sample")[0].getAttribute("limsid")
            sampleName=node.getElementsByTagName('name')[0].firstChild.nodeValue
            projLUID=sampleLUID[0:6]
            isControl=projLUID.split("-")
            sText=""
            if len(isControl) ==1:
                projectAcro=Projects_hash[projLUID].split("xxx")[1]
                key=containerLIMSID+"_"+pProcessID
                if (key not in meta_hash):
                    meta_hash[key]=projLUID+"xxx"+projectAcro+"xxx"+containerName
    #                if DEBUG is True:
    #                    print (projLUID,projectAcro,containerName, containerLIMSID,pProcessID)
            
            
            if artifactLUID not in Artifacts_hash:
                if len(isControl) ==2:
                    projLUID=container_project[containerLIMSID]
                (projName,sProjAcronym)=Projects_hash[projLUID].split("xxx")
                sText=sampleLUID+"xxx"+sampleName+"xxx"+containerLIMSID+"xxx"+containerName+"xxx"+projName+"xxx"+sProjAcronym+"xxx"+projLUID+"xxx"+pProcessID
                Artifacts_hash[artifactLUID]=sText
                if DEBUG is True:
                    print(sText)

    return

def check_directory(meta_hash):
    for key in meta_hash:
        (containerLIMSID,pProcessID)=key.split("_")
        (projLUID,projectAcro,containerName)=meta_hash[key].split("xxx")
        src_robot =NO_TAPE_new+projectAcro+"_"+projLUID+"/"+projectAcro+"_"+containerName+"_"+pProcessID
        src_NO_TAPE=NO_TAPE_new+projectAcro+"_"+containerName+"_"+pProcessID+"/"+containerName+"_"+pProcessID
        ss =src_robot+"\n"
        scan_4_files(src_robot+"/t.t","cel")
        #print (ss)
    
def scan_4_files(inputFile,file_ext):
    global passedArtifacts
    passedArtifacts=[]
    inputDir = os.path.dirname(inputFile)
    input_filename = os.path.basename(inputFile)
    for file in os.listdir(inputDir):
        artIDFromFile=file.split("_")[-1].split(".")[0]
        if DEBUG:
            print (file,artIDFromFile)
        if file.lower().endswith(file_ext) :
            qcFlag="PASSED"
            if artIDFromFile not in passedArtifacts:
                passedArtifacts.append(artIDFromFile)
            input_file = os.path.join(inputDir, file)
    return

def artifact_QC_update(Artifacts_hash):
    print ("ArtifactLUID\tSampleLUID\tSampleName\tcontainerLUID\tcontainerName\tprojName\tsProjAcronym\tprojLUID\tpProcessID")
    for key in Artifacts_hash:
        (sampleLUID,sampleName,containerLIMSID,containerName,projName,sProjAcronym,projLUID,pProcessID)=Artifacts_hash[key].split("xxx")
        qcFlag="FAILED"
        if key in passedArtifacts:
            qcFlag="PASSED"
        print (key+"\t"+sampleLUID+"\t"+sampleName+"\t"+containerLIMSID+"\t"+containerName+"\t"+projName+"\t"+sProjAcronym+"\t"+projLUID+"\t"+pProcessID+"\t"+qcFlag)
        update_QC_flag(key, qcFlag )            


def update_QC_flag(artID, qcFlag ):
    headers = {'Content-Type': 'application/xml'}
    sURI=BASE_URI+'artifacts/'+artID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    DOM = parseString( r.content)    
    nodeName="qc-flag"

    if DEBUG > 2: print( DOM.toprettyxml() )
    if DOM.parentNode is None:
        isBatch = False
    else:
        isBatch = True

    newDOM = xml.dom.minidom.getDOMImplementation()
    newDoc = newDOM.createDocument( None, None, None )
#   if the node already exists, delete it
    elements = DOM.getElementsByTagName( nodeName)
    for element in elements:
        if element.toxml():
            try:
                if isBatch:
                   DOM.removeChild( element )
                else:
                        DOM.childNodes[0].removeChild( element )
            except (xml.dom.NotFoundErr, e):
                if DEBUG > 0: print( "Unable to Remove existing UDF node" )

            break

        # now add the new UDF node
    txt = newDoc.createTextNode( qcFlag)
    newNode = newDoc.createElement( nodeName)
    #newNode.setAttribute( "name", udfname )
    #newNode.setAttribute( "type", udftype )
    newNode.appendChild( txt )
    if isBatch:
        DOM.appendChild( newNode )
    else:
        DOM.childNodes[0].appendChild( newNode )
    r = requests.put(sURI, data=DOM.toxml(), auth=(user, psw), verify=True, headers=headers)        
    #r = api.PUT(DOM.toxml(),sURI)
    return r
    
    

def get_master_project(artifactsXML):
    global masterProject, container_project

    masterProject=[]
    container_project={}
    
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        artType=node.getElementsByTagName('type')[0].firstChild.nodeValue
        if artType == 'Analyte':
            sampleID=node.getElementsByTagName('sample')[0].getAttribute('limsid')
            #print(artLUID)
            containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
            projLUID=sampleID[0:6]
            isCNTRL=projLUID.split("-")
            if len(isCNTRL)==1:
                if containerID not in container_project:
                    container_project[containerID]=projLUID
                if projLUID not in masterProject:
                    masterProject.append(projLUID)
    return 
     
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
    rDOM = parseString( r.content )
    #print (r.content)
    ppTYpe=rDOM.getElementsByTagName( "type" )[0].firstChild.nodeValue
    if processID not in parentProcessLUIDs:
       parentProcessLUIDs[processID]=parentProcessID+","+ppTYpe
       #print (processID+","+parentProcessLUIDs[processID])    
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in parentProcessLUIDs:
            get_parent_process(pProcessLUID,processID)

def get_processID_by_processType(parentProcessLUIDs,processType):
    ss="N/A"
    for key in parentProcessLUIDs:
        (parentProcessID,ppTYpe)=parentProcessLUIDs[key].split(",")
        if (ppTYpe == processType):
            ss=(key,parentProcessID)
        
    return ss
   
 
       

'''
    Start
    
'''


def main():
    global args, user, psw, Projects_hash, Artifacts_hash, activeProcessID,parentProcessLUIDs,containerSource
    args = setup_arguments()
    #print (args)
    user=args.username
    psw=args.password
    activeStep=args.activeStep
    containerSource=args.containerSource
    Projects_hash={}
    Artifacts_hash={}
    parentProcessLUIDs={}
    
        
    if (args.stepURI) :
        setupGlobalsFromURI(args.stepURI)
        get_projects_list()
        '''
         Create list of parent processes
        '''    
        get_parent_process(ProcessID,"")
        '''
         Get an active processID
        '''        
        (activeProcessID,parentProcessID)=get_processID_by_processType(parentProcessLUIDs,activeStep)    
    
        activeProcessURI=BASE_URI+'steps/'+activeProcessID        
        
        print ('active ProcessID='+activeProcessID)
        #create_io_map(args.stepURI)
        #exit()
        create_io_map(activeProcessURI)
        artRIXML=prepare_artifacts_batch(ArtifactURIs)
#        if DEBUG:
#            print (artRIXML)
        artifactsXML=retrieve_artifacts(artRIXML)
        get_master_project(artifactsXML)

        get_meta_from_artifacts(artifactsXML)
        check_directory(meta_hash)
        artifact_QC_update(Artifacts_hash)


        

       
        
if __name__ == "__main__":
    main()   
    