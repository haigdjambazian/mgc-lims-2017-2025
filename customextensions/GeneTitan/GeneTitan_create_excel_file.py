'''
Created on JAnuary 16, 2016

@author: Alexander Mazur, alexander.mazur@gmail.com

updated:
    2020_08_10:
        - fix for ProjectLUID 
    2018_12_13:
        - the root filepath has been changed to "Axiom_Arrays" instead of "CLSA_RAG401"
    2018_04_12:
        - rolled back to use local step ID and artifacts LUID
        - fixed issue with empty Project Acronim, default -"YYY"
    2018_03_20:
        - added activeStep option to use artifacts LUID and process ID from activeStep

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
#parser.add_argument('-processURI_v2',default='', help='processLuid from WebUI')
parser.add_argument('-fileLuid',default='', help='fileLuid from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-activeStep',default='DNA Amplification McGill 1.1', help='active Step')
parser.add_argument('-containerSource',default='input', help='containerSource')

'''
{stepURI:v2}
http://localhost:9080/api/v2/steps/24-1297
'''
args = parser.parse_args()
fileLuid=args.fileLuid
stepURI_v2=args.stepURI_v2
activeStep=args.activeStep
user_psw = args.user_psw
containerSource=args.containerSource

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

sDataPath='/data/glsftp/clarity/'
sExcelPath="/robot/GeneTitan/bravoprocess/toscanner/Axiom_Arrays/"
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
sProjectName=''
sProbeArrayType=''
sBarcode=''


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
            #Projects_hash[projLUID]=projName
            get_project_info(projLUID)
            
            if DEBUG:
                print (projLUID,projName, Projects_hash[projLUID])
    return 

def find_project(sampleLUID):
    projectLUID="N/A"
    for key in Projects_hash:
        if (key+'A') in sampleLUID:
            projectLUID=key
            
    return projectLUID

def get_project_info(projectID):
    projName=""
    sProjAcronym="YYY"
    if projectID not in Projects_hash:
        ss=BASE_URI+"projects/"+projectID
        r = requests.get(ss, auth=(user, psw), verify=True)
        rDOM = parseString(r.content)
        nodes= rDOM.getElementsByTagName("prj:project")
        for node in nodes:
           # projectNode = node.getElementsByTagName( "project" )
            projLUID = node.getAttribute( "limsid" )
            projName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
            
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
    global user,psw, container_barcodes,containerName
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
                print("########### end retXML ######")    
            get_master_project(retXML)   
            if DEBUG:
                print ('masterProject',masterProject)         
            get_artifacts_LUID_array(retXML, containerName)
            if DEBUG:
                for key in Projects_hash:
                    print (key, Projects_hash[key]) 
            sMeta=generate_meta_csv(retXML)
            #print (sMeta)

            
        i=i+1
    return sMeta
def get_io_map(activeStepURI):
    global iomap
    iomap = []

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
                if inputartLUID not in iomap:
                   iomap.append(inputartLUID)
            if containerSource=="output":               
    #    OUTPUTS
                if outputartLUID  not in iomap:
                   iomap.append( outputartLUID)
    
                
    
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
        #projLUID=sampleID[0:6]
        projLUID=find_project(sampleID)
        isCNTRL=projLUID.split("-")
        #print (projLUID,len(isCNTRL))
        if len(isCNTRL)==1:
            
            #(projName,sProjAcronym)=get_project_info(projLUID)
            #print (projLUID,projName,sProjAcronym)
            if (projLUID not in masterProject) and (projLUID !='N/A'):
                masterProject.append(projLUID)
                
                
    
    return 


def get_artifacts_LUID_array(artifactsXML,containerName):

    
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        sampleID=node.getElementsByTagName('sample')[0].getAttribute('limsid')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        #projLUID=sampleID[0:6]
        projLUID=find_project(sampleID)
        isControl=projLUID.split("-")
        if (len(isControl) ==2) or (projLUID=='N/A'):
            projLUID=masterProject[0]
        
        #get_project_info(projLUID)
        if artLUID not in Artifacts_hash:
            Artifacts_hash[artLUID]=sampleID+"xxx"+artName+"xxx"+projLUID+"xxx"+Projects_hash[projLUID]+"xxx"+containerName+"xxx"+containerID
            if DEBUG:
                print(sampleID+"xxx"+artName+"xxx"+projLUID+"xxx"+Projects_hash[projLUID]+"xxx"+containerName+"xxx"+containerID)
                
    
    return 
def get_active_container_info(artifactsXML):
    global activeContainers
    activeContainers={}
    

    
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        containerURI=node.getElementsByTagName('container')[0].getAttribute('uri')
        if containerID not in activeContainers:
            containerName=get_container_name(containerURI)
            activeContainers[activeProcessID]=containerID+"xxx"+containerName
                
    
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


def write_file(sText):
    '''
    Local Process ID
    '''
   # sExtra=Projects_Acronym+"_"+containerName+"_"+str(ProcessID)+"_2scanner.csv"
#    sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+Projects_Acronym+"_"+containerName+"_"+str(ProcessID)
    
    
    sExtra=containerName+"_"+str(ProcessID)+"_2scanner.csv"
    #old path mask
    #sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+containerName+"_"+str(ProcessID)
    sRoot=sExcelPath+containerName+"_"+str(ProcessID)
    
    
    
    '''
    Active Process ID
    '''    
    #sExtra=Projects_Acronym+"_"+containerName+"_"+str(activeProcessID)+"_2scanner.csv"
    #sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+Projects_Acronym+"_"+containerName+"_"+str(activeProcessID)
    if DEBUG:
        print (sRoot)
        print (sExtra)
    if not os.path.exists(sRoot):
        os.makedirs(sRoot)
    f_out=open(sRoot+"/"+sExtra,"w")
    f_out.write(sText)
    f_out.close()       
    return


def write_sorted_csv_file():
    '''
    Local Process ID
    '''
   # sExtra=Projects_Acronym+"_"+containerName+"_"+str(ProcessID)+"_2scanner.csv"
#    sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+Projects_Acronym+"_"+containerName+"_"+str(ProcessID)

    sExtra=containerName+"_"+str(ProcessID)+"_2scanner.csv"
    # old root name mask
    #sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+containerName+"_"+str(ProcessID)
    sRoot=sExcelPath+containerName+"_"+str(ProcessID)
    '''
    Active Process ID
    '''    
    #sExtra=Projects_Acronym+"_"+containerName+"_"+str(activeProcessID)+"_2scanner.csv"
    #sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+Projects_Acronym+"_"+containerName+"_"+str(activeProcessID)
    if DEBUG:
        print (sRoot)
        print (sExtra)
    if not os.path.exists(sRoot):
        os.makedirs(sRoot)
    f_out=open(sRoot+"/"+sExtra,"w")
    print (sHeader)
    for line in sorted(finalHash):
        f_out.write(finalHash[line]+"\n")
        #f_out.write(finalHash[line])
        #print (finalHash[line]+"\n")
        print (finalHash[line])
    f_out.close()       
    return

def write_project_file():
    '''
    Local Process ID
    '''
   # sExtra=Projects_Acronym+"_"+containerName+"_"+str(ProcessID)+"_2scanner.csv"
#    sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+Projects_Acronym+"_"+containerName+"_"+str(ProcessID)
    
    sText=containerName+"_"+str(ProcessID)
    sExtra=containerName+"_"+str(ProcessID)+".PROJECT"
    # old root path mask
    #sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+containerName+"_"+str(ProcessID)
    sRoot=sExcelPath+containerName+"_"+str(ProcessID)
    
    
    
    '''
    Active Process ID
    '''    
    #sExtra=Projects_Acronym+"_"+containerName+"_"+str(activeProcessID)+"_2scanner.csv"
    #sRoot=sExcelPath+Projects_Acronym+"_"+projLUID+"/"+Projects_Acronym+"_"+containerName+"_"+str(activeProcessID)
    if DEBUG:
        print (sRoot)
        print (sExtra)
    if not os.path.exists(sRoot):
        os.makedirs(sRoot)
    f_out=open(sRoot+"/"+sExtra,"w")
    f_out.write(sText)
    f_out.close()       
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
    
    global parentProcessLUIDs, activeProcessID,containerSource,Projects_hash

    setupGlobalsFromURI(stepURI_v2)
    parentProcessLUIDs={}
    Projects_hash={}
    
        
    (sProjectName, sProbeArrayType,sBarcode)=get_project_params(stepURI_v2)
    get_projects_list()
    if DEBUG:
        print(sProjectName, sProbeArrayType,sBarcode)
        
    '''
     Create list of parent processes
    '''    
    get_parent_process(ProcessID,"")
    '''
     Get an active processID
    '''        
    (activeProcessID,parentProcessID)=get_processID_by_processType(parentProcessLUIDs,activeStep)    
    
    activeProcessURI=BASE_URI+'steps/'+activeProcessID
    iomapID=get_io_map(activeProcessURI)
    sXML=prepare_artifacts_batch(iomapID)
    artXML=retrieve_artifacts(sXML)
    get_active_container_info(artXML)
    if DEBUG:
        print ('activeContainers',activeContainers)
        print('Projects hash',Projects_hash)
    '''
        Using the local process ID
    '''
    
    #sMeta=get_placement_containers(activeProcessURI)
    
        
    sMeta=get_placement_containers(stepURI_v2)
    if DEBUG:
        print (sMeta)
    
    write_sorted_csv_file()
    write_project_file()
    

if __name__ == "__main__":
    main()   
 
