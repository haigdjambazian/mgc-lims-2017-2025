'''
Created on March 19, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com, haig
    Updates:
        2022-05-26:
            - fixed multipage project list from api
        2020_08_19:
            - fixed long project luid issue
        -2019_03_01:
            - new network path -\\abacusfs.genome.mcgill.ca\robot\GeneTitan\ProjectDATA\Axiom_Arrays\
        -2018_12_14:
            -the network path mask  has been changed to "Axiom_Arrays"

'''
 

__author__ = 'Alexander Mazur'
script_version="2020_08_19"

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



#NO_TAPE_path="\\\\abacusfs.genome.mcgill.ca\\instruments\\GeneTitan_notapebackup\\ProjectDATA\\Axiom_Arrays\\"
NO_TAPE_path="\\\\abacusfs.genome.mcgill.ca\\robot\\GeneTitan\\ProjectDATA\\Axiom_Arrays\\"


# robocopy \\abacusfs.genome.mcgill.ca\instruments\GeneTitan_notapebackup\ProjectDATA\OPPERA\OPPERA_AX001 E:\OPPERA\OPPERA_AX001 *.cel /e /z /mir
def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
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


def create_io_map(stepURI_v2, sIO):
    
    ArtifactURIs=[]
    pURI=stepURI_v2+"/details"
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    details = parseString( pXML.content )
    #print api.GET( stepURI + "/details" )
    localIO=sIO
    for io in details.getElementsByTagName("input-output-map"):
        inputartURIState = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartURI = inputartURIState.split( "?" )[0]  # remove state
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        outputartURIState = io.getElementsByTagName("output")[0].getAttribute("uri")
        outputartURI = outputartURIState.split( "?" )[0]  # remove state
        outputartLUID = io.getElementsByTagName("output")[0].getAttribute("limsid")
        outputnode = io.getElementsByTagName("output")[0]
        
        if (outputnode.getAttribute("type") == "Analyte") and (outputnode.getAttribute("output-generation-type")=="PerInput") :    # replicates, therefore multiple outputs per input        
            if localIO == 'input':
                if inputartURI not in ArtifactURIs:
                   ArtifactURIs.append( inputartURI )
            if localIO == 'output':
                if outputartURI not in ArtifactURIs:
                   ArtifactURIs.append( outputartURI )               
    return ArtifactURIs

 
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
def get_active_container_info(artifactsXML):
    global activeContainers
    activeContainers={}
    

    
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        containerURI=node.getElementsByTagName('container')[0].getAttribute('uri')
        sampleLUID = node.getElementsByTagName("sample")[0].getAttribute("limsid")
        projLUID=sampleLUID[0:6]
        isControl=projLUID.split("-")
        if len(isControl) ==1:
            masterProjectLUID=masterProject[0]
            projectAcro=Projects_hash[masterProjectLUID].split("xxx")[1]
        
        if containerID not in activeContainers:
            containerName=get_container_name(containerURI)
            activeContainers[activeProcessID]=containerID+"xxx"+containerName+"xxx"+masterProjectLUID+"xxx"+projectAcro
    return
def get_master_project(artifactsXML):
    global masterProject,container_project

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
            #projLUID=sampleID[0:6]
            projLUID=find_project(sampleID)
            isCNTRL=projLUID.split("-")
            if len(isCNTRL)==1:
                if containerID not in container_project:
                    container_project[containerID]=projLUID
                if projLUID not in masterProject:
                    masterProject.append(projLUID)
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
                    if DEBUG:
                        print (projLUID,projectAcro,containerName, containerLIMSID,pProcessID)

    return meta_hash

def get_project_from_artifacts(artXML):
    
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
                key=activeProcessID#+"_"+pProcessID
                if (key not in meta_hash):
                    meta_hash[key]=projLUID+"xxx"+projectAcro+"xxx"+containerName+"xxx"+containerLIMSID
                    if DEBUG:
                        print (activeProcessID,projLUID,projectAcro,containerName, containerLIMSID,pProcessID)

    return meta_hash



def write_robocopy(meta_hash):
    sRoboSW="robocopy "
    ss=""
    for key in meta_hash:

        (containerLIMSID,containerName,projLUID,projectAcro,localProcessID)=meta_hash[key].split("xxx")
#    PArent Process
#        src=NO_TAPE_path+projectAcro+"_"+containerName+"_"+pProcessID+"\\"+containerName+"_"+pProcessID
#        dst="  E:\\"+projectAcro+"_"+containerName+"_"+pProcessID+"\\"+containerName+"_"+pProcessID
        #old 
        #src=NO_TAPE_path+projectAcro+"_"+projLUID+"\\"+containerName+"_"+localProcessID
        #new 2018_12_14
        #src=NO_TAPE_path+containerName+"_"+localProcessID
        src=sRawPath+containerName+"_"+localProcessID
        
#        dst="  E:\\"+projectAcro+"_"+containerName+"_"+localProcessID+"\\"+containerName+"_"+localProcessID
        #dst="  "+sLocalPCpath+"Axiom_Arrays"+"\\"+containerName+"_"+localProcessID
        dst="  "+sLocalPCpath+"\\"+containerName+"_"+localProcessID

        sFiles=" *.cel /e /z /mir"
        ss +=sRoboSW+src+dst+sFiles+"\r\n"
    return ss

     
def get_container_name(containerURI):
    global BASE_URI, user,psw
    r = requests.get(containerURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue
    return ss


def get_projects_list():
    
    pURI=BASE_URI+"projects/"
    
    while(1):
        #r = requests.get(ss, auth=(user, psw), verify=True) 
        # r=api.GET(pURI)
        r = requests.get(pURI, auth=(user, psw), verify=True)
        rDOM = parseString(r.content)
        nextnodes= rDOM.getElementsByTagName("next-page")
        nodes= rDOM.getElementsByTagName("project")
        for node in nodes:
            # projectNode = node.getElementsByTagName( "project" )
            projLUID = node.getAttribute( "limsid" )
            projName=node.getElementsByTagName('name')[0].firstChild.nodeValue
            Projects_hash[projLUID]=projName
            get_project_info(projLUID)
            if DEBUG:
                print (projLUID,projName)
        
        if len(nextnodes) == 0:
            break
        
        for nextnode in nextnodes:
            pURI=nextnode.getAttribute( "uri" )
        
    return


# def get_projects_list():
#     ss=BASE_URI+"projects/"
#     r = requests.get(ss, auth=(user, psw), verify=True)
#     rDOM = parseString(r.content)
#     nodes= rDOM.getElementsByTagName("project")
#     for node in nodes:
# 
#         projLUID = node.getAttribute( "limsid" )
#         projName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
#         if projLUID not in Projects_hash:
#             Projects_hash[projLUID]=projName
#             get_project_info(projLUID)
#         if DEBUG:
#             print (projLUID,projName)
#     return 

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
            sProjAcronym="YYY"
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



def get_parent_process_paths(processID,parentProcessID,kNode):
    global iNode
    iNode=kNode
    sURI=BASE_URI+'processes/'+processID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    #r=api.GET(sURI)
    rDOM = parseString( r.content )
    #print (r.content)
          
#    if len(rDOM.getElementsByTagName( "parent-process" ))<1:
#       iNode +=1
    ppType=rDOM.getElementsByTagName( "type" )[0].firstChild.nodeValue
    if processID not in pathProcessLUIDs:
       pathProcessLUIDs[processID]=parentProcessID+","+ppType+","+str(iNode)
       if DEBUG:
           print (processID+","+pathProcessLUIDs[processID]) 
    if ppType == activeStep:
        iNode+=1
    #print  (str(iNode),str(len(rDOM.getElementsByTagName( "parent-process" ))))            
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in pathProcessLUIDs:
            get_parent_process_paths(pProcessLUID,processID,iNode)


def get_processID_by_path(pathProcessLUIDs,processTypeStart,processTypeStop):
    ss={}
    kk=''
    myNode=''
    if DEBUG:
        print('###############')
    for key in pathProcessLUIDs:
        (parentProcessID,ppType,sNode)=pathProcessLUIDs[key].split(",")
        if DEBUG:
            print (key,parentProcessID,ppType,sNode)
        
        if (ppType==processTypeStart) or (ppType==processTypeStop):
            if sNode not in ss:
                ss[sNode]=key+"xxx"+ppType
            else:
                if (ppType==processTypeStart):
                    ss[sNode]= key+"xxx"+ppType+"xxx"+ss[sNode]
                if (ppType==processTypeStop):
                    ss[sNode]= ss[sNode]+"xxx"+key+"xxx"+ppType

    if DEBUG:
        print (ss)

        
    return ss

def get_process_UDFs(ProcessID):
    global user,psw, hProjects
    processURI=BASE_URI+'processes/'+ProcessID
    
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    sLocalPCpath=getUDF(rDOM, 'Local PC path')
    sRawPath=getUDF(rDOM, 'RawData path')
    if not sLocalPCpath:
        sLocalPCpath="E:\\"
    if not sRawPath:
        sRawPath=NO_TAPE_path
        

    return sLocalPCpath,sRawPath

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

def find_project(sampleLUID):
    projectLUID="N/A"
    for key in Projects_hash:
        if (key+'A') in sampleLUID:
            projectLUID=key
            
    return projectLUID
       

'''
    Start
    
'''




def main():
    global args, user, psw, Projects_hash,parentProcessLUIDs,pathProcessLUIDs ,kNode, activeStep,activeProcessID, activeLUIDs,  localContainers, localArtifactURIs
    global sLocalPCpath,sRawPath
    
    args = setup_arguments()
    user=args.username
    psw=args.password
    stepURI_v2=args.stepURI
    activeStep=args.activeStep
    containerSource=args.containerSource
    Projects_hash={}
    parentProcessLUIDs={}
    pathProcessLUIDs={}
    activeLUIDs={}
    localContainers=[]
    
    
        
    if (args.stepURI) :
        setupGlobalsFromURI(args.stepURI)
        
        sLocalPCpath, sRawPath=get_process_UDFs(ProcessID)
        
        get_projects_list()
        
        create_local_io_map(args.stepURI)
        localArtRIXML=prepare_artifacts_batch(localArtifactURIs)
        
        if DEBUG:
            print (localArtRIXML)
        localRetXML=retrieve_artifacts(localArtRIXML)
        #print (localRetXML)   
        get_local_containers(localRetXML)  
        #print (Projects_hash)        

        '''
         Create list of parent processes
        '''    
#        get_parent_process(ProcessID,"")
        get_parent_process_paths(ProcessID,'',1)
        
        trace_process_hash=get_processID_by_path(pathProcessLUIDs,'Denaturation and Hybridization McGill 1.0','DNA Amplification McGill 1.1')        
        
        
        '''
         Get the processID from trace_process_hash
        '''        
         

        for key in trace_process_hash:   
            (startProcessID,startProcessName,stopProcessID, stopProcessNmae)=trace_process_hash[key].split('xxx')
            activeProcessID=stopProcessID
            activeProcessURI=BASE_URI+'steps/'+activeProcessID       
            if DEBUG:
                print (activeProcessURI)    
            activeArtURIs=create_io_map(activeProcessURI, "input")
            activeRIXML=prepare_artifacts_batch(activeArtURIs)
            if DEBUG>2:
                print (activeRIXML)
            retXML=retrieve_artifacts(activeRIXML)
            
            if DEBUG>2:
                print (retXML)
            get_master_project(retXML)
            get_active_container_info(retXML)
            activeContainers[activeProcessID]=activeContainers[activeProcessID]+"xxx"+startProcessID
            sRoboCopy=write_robocopy(activeContainers)
            print (sRoboCopy)
            #print(script_version)

        

       
        
if __name__ == "__main__":
    main()   
    