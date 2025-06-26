'''
Created on Sep. 29, 2017

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
#BASE_URI='https://bravotestapp.genome.mcgill.ca/api/v2/'
script_dir=os.path.dirname(os.path.realpath(__file__))

HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False

parser = argparse.ArgumentParser(description='Generate Excel file for GeneTitan')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
parser.add_argument('-processURI_v2',default='', help='processLuid from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-attachFilesLUIDs',default='', help='LUIDs for report files attachment')

'''
{stepURI:v2}
http://localhost:9080/api/v2/steps/24-1297
'''
args = parser.parse_args()

stepURI_v2=args.stepURI_v2
processURI_v2=args.processURI_v2
user_psw = args.user_psw
attachLUIDs=args.attachFilesLUIDs
attachLUIDs=attachLUIDs[:-1]

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

sDataPath='/data/glsftp/clarity/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
sProjectName=''
sProbeArrayType=''
sBarcode=''
ProcessID=''
ArtifactsLUID=[]
Projects_hash={}
(FileReportLUID1, FileReportLUID2, FileReportLUID3,FileReportLUID4,FileReportLUID5)=attachLUIDs.split(' ')

sHeader='ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tSampleLUID\tSampleName\tReference\tLibraryKit\tBCLMode\n'



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

def get_artifacts_array(processLuid):

    global user,psw,ArtifactsLUID

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
        oLUID = input[0].getAttribute( "limsid" )
        output=node.getElementsByTagName("output")
        oType = output[0].getAttribute( "output-type" )
        ogType = output[0].getAttribute( "output-generation-type" )

        if oType == "ResultFile" and ogType == "PerInput":
            if oLUID not in ArtifactsLUID:
                ArtifactsLUID.append( oLUID )


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
    global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content

def create_tab_del_output_file(sXML):
    global projLUID,projName, sampleLUID,sampleName
    pDOM = parseString( sXML)


    nodes = pDOM.getElementsByTagName( "smp:sample" )
    sTabOutput=sHeader
    
    for node in nodes:
        sampleLUID= node.getAttribute( "limsid" )
        sampleName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
        projLUID=node.getElementsByTagName('project')[0].getAttribute( "limsid" )
        projName= Projects_hash[projLUID]
        #print (str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(ContainerID)+"\t"+ ContainerName +"\t"+ContainerPosition+"\t"+ str(sampleLUID)+"\t"+ sampleName+"\t"+Reference+"\t"+sLibraryKit+"\t"+ sBCLMode )
        sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(ContainerID)+"\t"+ ContainerName +"\t"+ContainerPosition+"\t"+ str(sampleLUID)+"\t"+ sampleName+"\t"+Reference+"\t"+sLibraryKit+"\t"+ sBCLMode+"\n" 
        
     
    return sTabOutput

def create_process_settings_file():
    isDebug="False"
    sWorkDir='\\\\abacusfs\\hiseq\\170912_A00266_0008_AH3HJ5DMXX\\'
    sOut=""
    sOut +="ProcessLUID\t"+str(ProcessID)+"\n"
    sOut +="PipelineName\tNovaSeq\n"
    sOut +="ProjectLUID\t"+str(projLUID)+"\n"
    sOut +="ProjectName\t"+projName+"\n"
    sOut +="PipelineWorkDir\t"+sWorkDir+"\n"
    sOut +="isDebug\t"+isDebug+"\n"
    sOut +="SampleLUID\t\n"
    sOut +='''isBatch\tFalse
CommandLine\t
LogFile\t
ErrorFile\t
AttachDocument1\t
AttachDocumentNN\t
AttachQuickReport\t
AttachFullReport\t
LibraryReport\t
GenotypingReport\t
SequencingReport\t
ReadFile1\t
ReadFile2\t
ReadFile3\t
ReadFile4\t
AnalysisReport1\t
AnalysisReport2\t
AnalysisData\t
AlignmentData\t
StatsData\t
SampleQCReport\t
ReadFile5\t 
'''

    
    
    
    
    return sOut

def extract_container_ID (sXML):
    rDOM = parseString( sXML )
    scNodes =rDOM.getElementsByTagName('container')
    containerID= scNodes[0].getAttribute( "limsid" )
    return containerID


def get_container_name(containerID):
    sURI=BASE_URI+'containers/'+containerID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    contName = node[0].firstChild.nodeValue
    contPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
    

    return contName,contPosition



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
    sExtra="_"+str(ProcessID)+"_settings.txt"
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
        get_projects_list()
        global sLibraryKit, sBCLMode, Reference, ProcessID
        (sLibraryKit, sBCLMode, Reference)=get_project_params(processURI_v2)
#        print (sLibraryKit, sBCLMode, Reference)
#        print (ProcessID)

        get_artifacts_array(ProcessID)
#        print (ArtifactsLUID)
        sXML=prepare_artifacts_batch(ArtifactsLUID)
        #print (sXML)
        lXML=retrieve_artifacts(sXML)
        #print (lXML)
#        for key in sorted(Projects_hash):
#            print (key, Projects_hash[key])
        global ContainerID, ContainerName, ContainerPosition    
        ContainerID =extract_container_ID (lXML)
        (ContainerName, ContainerPosition)=get_container_name(ContainerID)
#        print (ContainerID +"\t"+ContainerName) 
        xXML = prepare_samples_list_for_batch(lXML)

        zXML=retrieve_asamples(xXML)
        #print (zXML)   
        outFile=create_tab_del_output_file(zXML)
        sOut= create_process_settings_file()
        
        print (outFile)
        write_file2(sOut)
 

        
if __name__ == "__main__":
    main()   
  
