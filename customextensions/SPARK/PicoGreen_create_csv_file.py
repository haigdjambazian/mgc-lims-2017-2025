'''
Created on JAnuary 16, 2016

@author: Alexander Mazur, alexander.mazur@gmail.com

updated:
    2018_05_04:


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

parser = argparse.ArgumentParser(description='Generate Excel file for PicoGreen EMC')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
#parser.add_argument('-processURI_v2',default='', help='processLuid from WebUI')
parser.add_argument('-fileLUIDs',default='', help='fileLUIDs from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-artifactType',default='Analyte', help='Artifact type  -<Analyte|ResultFile>')
parser.add_argument('-containerSource',default='input', help='containerSource')


args = parser.parse_args()
fileLuid=args.fileLUIDs
stepURI_v2=args.stepURI_v2

user_psw = args.user_psw
containerSource=args.containerSource
artifactType=args.artifactType

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

sDataPath='/data/glsftp/clarity/'
sTemplatePath="/opt/gls/clarity/ai/temp/"
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
sProjectName=''
sProbeArrayType=''
sBarcode=''

Projects_hash={}
Artifacts_hash={}
sHeader='Sample File Path,Project,Plate Type,Probe Array Type,Probe Array Position,Barcode,Sample File Name,Array Name'



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

        projLUID = node.getAttribute( "limsid" )
        projName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
        if projLUID not in Projects_hash:
            Projects_hash[projLUID]=projName
        if DEBUG:
            print (projLUID,projName)
    return 

def get_project_info(projectID):
    projName=""
    sProjAcronym=""
    if projectID not in Projects_hash:
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
            Projects_hash[projLUID]=projName+"xxx"+sProjAcronym#+"xxx"
    return projName,sProjAcronym



def get_project_params(stepURI_v2):
    global user,psw,sProjectName, sProbeArrayType,sBarcode
    ss=stepURI_v2+"/details"
    r = requests.get(ss, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    nodes= rDOM.getElementsByTagName("stp:details")
    for input in nodes:
        uriType = input.getAttribute( "uri" )
        limsidType = input.getAttribute( "limsid" )

    sProjectName=getUDF(rDOM, 'AGCC Project')
    sProbeArrayType=getUDF(rDOM, 'Array Type')
    sBarcode=getUDF(rDOM, 'Barcode')    

    return sProjectName, sProbeArrayType,sBarcode

def get_placement_containers(stepURI_v2):
    global user,psw, container_barcodes
    sURI=stepURI_v2 +'/placements'
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )
    if DEBUG:
        print('\n')    
        print (r.content)
        print('\n')
    
    i=0
    sMeta=''
    for node in rDOM.getElementsByTagName('selected-containers'):
        containerURI = node.getElementsByTagName("container")[0].getAttribute("uri")
        
        if (containerURI):
#            kk=":".join("{:02x}".format(ord(c)) for c in ss)
            containerName=get_container_name(containerURI)
            
            '''
             use
            container_barcodes[ss]=sName
            
            '''
            # print ('containerID:\t'+ss+'\ncontainerName:\t'+sName)
            sXML=get_container_data(containerURI)
            if DEBUG:
                print("########### sXML######")
                print (sXML)
                print("########### sXML######")                
            retXML=retrieve_artifacts(sXML)
            if DEBUG:
                print("########### retXML######")
                print (retXML)
                print("########### retXML ######")    
            get_master_project(retXML)   
            if DEBUG:
                print (masterProject)         
            get_artifacts_LUID_array(retXML, containerName)
            if DEBUG:
                for key in Projects_hash:
                    print (key, Projects_hash[key]) 
            sMeta=generate_meta_csv(retXML)
            #print (sMeta)

            
        i=i+1
    return sMeta
def get_io_map_selected(activeStepURI):
    global iomapSelected
    iomapSelected = []

    sURI = activeStepURI + "/details"
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )  
    for io in rDOM.getElementsByTagName("input-output-map"):
        inputartURI = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        outputnode = io.getElementsByTagName("output")[0]
        outputartURI = outputnode.getAttribute("uri")
        # AM
        outputartLUID  = outputnode.getAttribute("limsid")

        # only want artifact outputs
        # ORIGINAL used "Analyte"
        if (outputnode.getAttribute("type") == "Analyte") and (outputnode.getAttribute("output-generation-type")=="PerInput") :    # replicates, therefore multiple outputs per input
            if containerSource=="input":
    #    INPUTS
                if inputartLUID not in iomapSelected:
                   iomapSelected.append(inputartLUID)
            if containerSource=="output":               
    #    OUTPUTS
                if outputartLUID  not in iomapSelected:
                   iomapSelected.append( outputartLUID)
    
                
    
    return iomap

def get_io_map(activeStepURI):
    global iomap
    iomap = {}

    sURI = activeStepURI + "/details"
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )  
    for io in rDOM.getElementsByTagName("input-output-map"):
        inputartURI = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        outputnode = io.getElementsByTagName("output")[0]
        outputartURI = outputnode.getAttribute("uri")
        # AM
        outputartLUID  = outputnode.getAttribute("limsid")

        # only want artifact outputs
        # ORIGINAL used "Analyte"
        if (outputnode.getAttribute("type") == artifactType) and (outputnode.getAttribute("output-generation-type")=="PerInput") :    # replicates, therefore multiple outputs per input
            if inputartLUID not in iomap:
               iomap[inputartLUID]=outputartLUID

    
                
    
    return iomap    
    

def prepare_artifacts_batch(iomapID):
    #global BASE_URI
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    sURI=""
    for key in iomapID:
        sURI = BASE_URI+'artifacts/'+key
        lXML.append( '<link uri="' + sURI + '" rel="artifacts"/>' )        
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 


def get_master_project(artifactsXML):
    global masterProject

    masterProject=[]
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        sampleID=node.getElementsByTagName('sample')[0].getAttribute('limsid')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        #isCNTRL=node.getElementsByTagName('control-type')[0].getAttribute('uri')
        projLUID=sampleID[0:6]
        isCNTRL=projLUID.split("-")
        #print (projLUID,len(isCNTRL))
        if len(isCNTRL)==1:
            
            #(projName,sProjAcronym)=get_project_info(projLUID)
            #print (projLUID,projName,sProjAcronym)
            if projLUID not in masterProject:
                masterProject.append(projLUID)
                
                
    
    return 


def get_PicoGreen_artifacts_LUID_array(artifactsXML):

    
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        sampleID=node.getElementsByTagName('sample')[0].getAttribute('limsid')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        projLUID=sampleID[0:6]

        if artLUID not in Artifacts_hash:
            Artifacts_hash[artLUID]=artName+"xxx"+sampleID+"xxx"+projLUID+"xxx"+containerID
            if DEBUG>2:
                print(artLUID+"\t"+artName+"\t"+sampleID+"\t"+projLUID+"\t"+containerID)
                
    
    return 
def get_active_container_info(artifactsXML):
    global Containers
    Containers={}
    

    
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        containerURI=node.getElementsByTagName('container')[0].getAttribute('uri')
        if containerID not in Containers:
            containerName=get_container_name(containerURI)
            Containers[containerID]=containerName
                
    
    return
def generate_meta_csv(sXML):
    global data_quant, container_barcodes, script_dir, sProjectName, sProbeArrayType,sBarcode, sHeader, ProcessID,sampleID,artName,projLUID,Project_Name,Projects_Acronym,containerName,containerID, finalHash
    
    finalHash={}

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact"}
    #print (sXML)
    root = ET.fromstring(sXML)
    ss=sHeader+'\n'
    sNewProjectName=sProjectName.replace(' ','_')
    
    for child in root:
        sPos=child[5][1].text
        if (len(sPos) ==3):
            sPos=sPos.replace(':','0')
        else:
            sPos=sPos.replace(':','')  
        sSample_name=child[0].text
        sSample_name=sSample_name.replace(':','_')    
        #sSampleFileName=sNewProjectName+'_'+sPos+'_'+sSample_name+'_'+child.attrib['limsid']+'.ARR'
        #sSampleFileName=child.attrib['limsid']+'.ARR'

        sSampleFileName=child.attrib['limsid']
        '''
        before Mar.29, 2018 - sProjectName=ProcessID
        from Mar.29, 2018 - sProjectName=activeProcessID
        '''
        #sProjectName=activeProcessID
        sProjectName=ProcessID
        (activeContainerID,activeContainerName)=activeContainers[activeProcessID].split("xxx")
        (sampleID,artName,projLUID,Project_Name,Projects_Acronym,containerName,containerID)=Artifacts_hash[sSampleFileName].split("xxx")
        containerName = activeContainerName

#        ss = ss+','+sProjectName+','+sProbeArrayType+'-96,'+sProbeArrayType+','+sPos+','+sBarcode+','+sSampleFileName+','+child.attrib['limsid']+'\n'
#        ss += ','+Projects_Acronym+"_"+containerName+"_"+sProjectName+','+sProbeArrayType+'-96,'+sProbeArrayType+','+sPos+','+sBarcode+','+artName+"_"+sSampleFileName+','+child.attrib['limsid']+'\n'
        #ss += ','+containerName+"_"+sProjectName+','+sProbeArrayType+'-96,'+sProbeArrayType+','+sPos+','+sBarcode+','+artName+"_"+sSampleFileName+','+child.attrib['limsid']+'\n'
        ss += ','+containerName+"_"+sProjectName+','+sProbeArrayType+'-96,'+sProbeArrayType+','+sPos+','+sBarcode+','+artName+"_"+sSampleFileName+','+artName+"_"+sSampleFileName+'\n'
        if sPos not in finalHash:
            finalHash[sPos]=','+containerName+"_"+sProjectName+','+sProbeArrayType+'-96,'+sProbeArrayType+','+sPos+','+sBarcode+','+artName+"_"+sSampleFileName+','+artName+"_"+sSampleFileName
    
    return ss



def get_container_data(containerURI):
    r = requests.get(containerURI, auth=(user, psw), verify=True)    
    sXML = extract_artifacts_ID(r.content)
    #print(r.content)
    return sXML

def retrieve_artifacts(sXML):
    
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content


def extract_container_ID (sXML):
    container_ID='x'
    s_split=sXML.split('/')
    container_ID=s_split[len(s_split)-2].replace('"','')
    
    return container_ID


def get_container_name(containerURI):
    global BASE_URI, user,psw
    #URI=BASE_URI+'containers/'+containerID
#    print('\n')
#    print (sURI)
    #print('\n')
    r = requests.get(containerURI, auth=(user, psw), verify=True)
    # print (r.content)
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue

    return ss


def extract_artifacts_ID(sXML):
    s=""
    rDOM = parseString( sXML )
    scNodes =rDOM.getElementsByTagName('placement')
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


def create_PicoGreen_file():
    sHeader="LIMS ID (Sample),Sample Name,QC,Concentration,Conc. Units,Mass,Mass Units\n"
    sText =sHeader
    for key in Artifacts_hash:
        (artName,sampleID,projLUID,containerID)=Artifacts_hash[key].split("xxx")
        sText +=key+","+artName+",,,ng/ul,,ng\n"
       
    return sText





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


def main():
    
    global pcontainerSource

    setupGlobalsFromURI(stepURI_v2)
    
    

    iomapID=get_io_map(stepURI_v2)
    if DEBUG:
        for key in iomapID:
            print (key, iomapID[key])
    sXML=prepare_artifacts_batch(iomapID)
    artXML=retrieve_artifacts(sXML)
    if DEBUG>2:
        print (artXML)
    #get_active_container_info(artXML)
    #if DEBUG:
    #    print (Containers)
    get_PicoGreen_artifacts_LUID_array(artXML)
    sText=create_PicoGreen_file()
    print (sText)

    

if __name__ == "__main__":
    main()   
 
