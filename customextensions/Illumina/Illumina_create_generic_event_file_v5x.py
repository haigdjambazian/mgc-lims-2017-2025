'''
Created on June 12, 2019

    Replcement for the "Illumina_create_generic_event_file.py" as Illumina_create_generic_event_file_v5x.py 
        aka *_v5x_fixKAPA_6IDX_oCap_TgCells.py
    Generates the event file for the pipeline
    Usage: 
    
    python3.5 Illumina_create_generic_event_file_v5x.py -u {username} -p {password} -s {IlluminaSeq step API URI} -r <HiSeqX|NovaSeq|iSeq|HiSeq4000>
    
    @author: Alexander Mazur, alexander.mazur@gmail.com
        
        update Jan 21 2022: (author: Haig Djambazian)
            - Bug fix with unset variable.
        update Nov 22 2021: (author: Haig Djambazian)
            - Adding "PCR Kit Name" metadata into event file.
            - Adding "Sequencing Technology" metadata into event file.
            - Adding "Flowcell Type" metadata into event file.
            - Adding "Experiment Name" aka "lab Run Counter" metadata into event file.
        update July 20 2020:
            - updated: Capture speed up
        update June 12 2020:
            - added support : external lib -> capture-> pooling-> replicas    
        update May 21 2020:
            - iPoolFraction updated for submitted samples
        update May 04 2020:
            -added Capture replicas support 
        update Feb. 28 2020:
            -added support for the replicas for the submitted libraries  
        update Feb. 20 2020:
            added Capture info for submitted libraries 
        update Jan. 19 2020:
            - added to report the "Target Cells" values for "10x genomics Singe Cell" protocol  
        update Oct. 2019:
            - submitted library corrected when ONLY subm libs
            - added KapaTag output
            - corrected output for old Lib prep steps "Lucigen AmpFREE Low DNA 1.0" and "Kapa Hyper Plus"
            - corrected output for the same samples passing the path with "Capture" and without one 
        
        all processes were tested with - create_event_file()
            - 91453 (PROD) - correct output with same samples passing the path with Capture and without ones  
            - 72509 (PROD) -  correct output with ChIP-Seq marks
            - 113858 (TEST) HiSeq 4000 capture + LibNorm replicas
            - 67307 (PROD) Novaseq Haloplex with "Library Pool" example 
            - 67189 (PROD same library ID multiple times for different sample names            
            - 63003 (PROD)
            - 92276 ("hard" example on TEST ) also looks good
            - 92263 (on TEST)
            - 58295 (same sample with different indexes on PROD)
            - 58299 (replicas in LibNorm on PROD)
                

Note:

python_version=3.5
 
'''
script_version="2020_07_20"

__author__ = 'Alexander Mazur'
import getopt,sys,os
sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
import glsapiutil3x

from optparse import OptionParser
import xml.dom.minidom

import datetime
import logging

import socket
from xml.dom.minidom import parseString
import subprocess
import configparser
import base64
import time


script_dir=os.path.dirname(os.path.realpath(__file__))


sDataPath='/data/glsftp/clarity/'
sEventPath='/lb/robot/research/processing/events/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')


def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')

    Parser.add_option('-n', "--sampleName", action='store', dest='sampleName')
    Parser.add_option('-d', "--sampleLUID", action='store', dest='sampleLUID')
    Parser.add_option('-r',"--IlluminaProtocol",default='NovaSeq', action='store', dest='IlluminaProtocol')
    Parser.add_option('-g',"--debug",default='0', action='store', dest='debug')
    Parser.add_option('-a',"--attachFilesLUIDs",action='store', dest='attachFilesLUIDs')    
        
    return Parser.parse_args()[0]

def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI
    global sftpHOSTNAME
    global systemHOST
    global ProcessID

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"
    systemHOST = socket.gethostname()
    sftpHOSTNAME="sftp://"+systemHOST
    ProcessID=tokens[-1]
    

    if DEBUG is True:
        print (HOSTNAME)
        print (BASE_URI)
        print (sftpHOSTNAME)
        print (systemHOST)


def get_process_UDFs(ProcessID):
    
    processURI=BASE_URI+'processes/'+ProcessID
    
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")
        sudfValue[udfName]=str(key.firstChild.nodeValue)
    return  sudfValue

def get_process_type_list():
    
    processURI=BASE_URI+'processtypes'
    
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    #print(r.content)
    sValue_hash={}
    sOUT= "<html></br> # Generated from https://bravoprodapp.genome.mcgill.ca/     </br>20190617 &nbsb Alexander Mazur </br>"
    sOUT+="<table><tr><th>Process Name></th><th>UDF Name</th><th>UDF Type</th><th>UDF presets</th></tr>"
    print (sOUT)
    for pTypeNode in rDOM.getElementsByTagName("process-type"):
        pTypeURI=pTypeNode.getAttribute("uri")
        pTypeName=pTypeNode.getAttribute("name")
        if pTypeURI not in sValue_hash:
            sValue_hash[pTypeURI]=pTypeName
            processUDF_List=get_process_type_info(pTypeURI)
            for udfURI in processUDF_List:
                (udfName, udfType, preset_arr ) = get_udf_info(udfURI)
                
                sUDF_presets="::".join(preset_arr)
                print ("<tr><td>"+pTypeName+"</td><td>"+udfName+"</td><td>"+udfType+"</td><td>"+sUDF_presets +"</td></tr>")
                
    print ("</table></html>")    
    
    return sValue_hash  

def get_artifacts_list(sampleLUID):
    
    processURI=BASE_URI+'artifacts?samplelimsid='+sampleLUID
    print(processURI)
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    #print(r.content)
    sValue_hash={}
    sOUT= "<html></br> # Generated from https://bravoprodapp.genome.mcgill.ca/     </br>20190617 &nbsb Alexander Mazur </br>"
    sOUT+="<table><tr><th>Process Name></th><th>UDF Name</th><th>UDF Type</th><th>UDF presets</th></tr>"
    #print (sOUT)
    for aNode in rDOM.getElementsByTagName("artifact"):
        aURI=aNode.getAttribute("uri")
        aLUID=aNode.getAttribute("limsid")
        if "92-" not in aLUID: 
            (artifactName, processID,stepName) = get_artifact_info(aURI)
            print(aLUID,artifactName, processID,stepName)
       
    #print ("</table></html>")    
    
    return sValue_hash

def find_artifact_chain_from_last(map_io,artifactLUID,upStepLUID):
    global i
    

    for key in map_io:
        inputArtifact, outputArtifact=key.split("xxx")
        parentProcessID=map_io[key]
        if outputArtifact==artifactLUID:
            
            (ppID,ppType,iNode,sudfValue) = pathProcessLUIDs[parentProcessID]
            
            #print(i,outputArtifact,parentProcessID,ppType)
            #if i>100000:
            #    break
            
            if parentProcessID==upStepLUID:
                #print("Done",i,inputArtifact,outputArtifact,parentProcessID,pathProcessLUIDs[parentProcessID])
                new_key=inputArtifact+"_"+outputArtifact
                artifacts_info[new_key]=globalArtifact,parentProcessID,pathProcessLUIDs[parentProcessID]
                if DEBUG:
                    print("Done",i,globalArtifact,inputArtifact,outputArtifact,parentProcessID,pathProcessLUIDs[parentProcessID])
                i+=1
                #break
            
            find_artifact_chain_from_last(map_io,inputArtifact,upStepLUID)

def find_lib_artifact_chain_from_last(map_io,artifactLUID,upStepLUID):
    global i
    #artifacts_info={}

    for key in map_io:
        inputArtifact, outputArtifact=key.split("xxx")
        parentProcessID=map_io[key]
        if outputArtifact==artifactLUID:
            
            
            (ppID,ppType,iNode,sudfValue) = pathProcessLUIDs[parentProcessID]
            
            if parentProcessID==upStepLUID:
                #print("Done",i,inputArtifact,outputArtifact,parentProcessID,pathProcessLUIDs[parentProcessID])
                if "PA1" not in inputArtifact:
                    rootSample=get_artifact_meta(inputArtifact)
                else:
                    rootSample=inputArtifact.replace("PA1","")
                #new_key=inputArtifact+"_"+outputArtifact
                new_key=rootSample+"_"+outputArtifact+"_"+globalArtifact
                res = [i for i in IlluminaSequenceSamples if rootSample in i]
                if len(res)>0:
                    
                    artifacts_info[new_key]=globalArtifact,parentProcessID,pathProcessLUIDs[parentProcessID]
                    if DEBUG==2:
                        print("Done",i,globalArtifact,inputArtifact,outputArtifact,parentProcessID)
                    i+=1
                #break
            
            find_lib_artifact_chain_from_last(map_io,inputArtifact,upStepLUID)

def get_artifact_from_to(map_io,artifactLUID,upStepLUID, masterArtifact):
    global i,art_hash
    #artifacts_info={}

    for key in map_io:
        inputArtifact, outputArtifact=key.split("xxx")
        parentProcessID=map_io[key]
        if outputArtifact==artifactLUID:
            
            
            (ppID,ppType,iNode,sudfValue) = pathProcessLUIDs[parentProcessID]
            
            if parentProcessID==upStepLUID:
                #print("Done",i,inputArtifact,outputArtifact,parentProcessID,pathProcessLUIDs[parentProcessID])
                if "PA1" not in inputArtifact:
                    rootSample=get_artifact_meta(inputArtifact)
                else:
                    rootSample=inputArtifact.replace("PA1","")
                #new_key=inputArtifact+"_"+outputArtifact
                new_key=rootSample+"_"+outputArtifact+"_"+masterArtifact
                res = [i for i in IlluminaSequenceSamples if rootSample in i]
                if len(res)>0:
                    
                    art_hash[new_key]=masterArtifact,parentProcessID,pathProcessLUIDs[parentProcessID]
                    if DEBUG==2:
                        print("Done",i,masterArtifact,inputArtifact,outputArtifact,parentProcessID,art_hash[new_key])
                    i+=1
                #break
            
            get_artifact_from_to(map_io,inputArtifact,upStepLUID,masterArtifact)
    return
 

def find_process_artifacts(map_io, processID):
    uq_hash={}
    
    for key in map_io:
        inputArtifact, outputArtifact=key.split("xxx")
        parentProcessID=map_io[key]
        if parentProcessID==processID:
            (ppID,ppType,iNode,sudfValue) = pathProcessLUIDs[parentProcessID]
            new_key=inputArtifact#+"xxx"+outputArtifact
            if inputArtifact not in uq_hash:
                uq_hash[new_key]=(ppID,ppType,iNode,sudfValue)
                if DEBUG:
                    print("Done",inputArtifact, outputArtifact,parentProcessID, ppType)
            
        #find_process_artifacts(map_io, processID)                
    return uq_hash
    

def get_artifact_info(artifactURI):
    
    
    
    r = requests.get(artifactURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    #print(r.content)
    sValue_hash={}
    processID=""
    for aNode in rDOM.getElementsByTagName("art:artifact"):
        try:
            stepURI=aNode.getElementsByTagName("parent-process")[0].getAttribute("uri")
            processID,stepName=get_step_info(stepURI)
            
        except:
            stepName="Root Artifact"
            
        artifactName=aNode.getElementsByTagName("name")[0].firstChild.data
    return artifactName, processID, stepName

def get_artifact_meta(artifactLUID):
    
    aURI=BASE_URI+"artifacts/"+artifactLUID
    
    #r = requests.get(aURI, auth=(user, psw), verify=True)
    r=api.GET(aURI)
    rDOM = parseString(r)
    #print(r.content)
    sValue_hash={}
    processID=""
    for aNode in rDOM.getElementsByTagName("art:artifact"):
        sampleLUID=aNode.getElementsByTagName("sample")[0].getAttribute("limsid")
        
    return sampleLUID

 


def get_step_info(stepURI):
    
    
    
    #r = requests.get(stepURI, auth=(user, psw), verify=True)
    r=api.GET(stepURI)
    rDOM = parseString(r)
    #print(r.content)
    stepName=''
    processID=rDOM.getElementsByTagName("prc:process")[0].getAttribute("limsid")
    for sNode in rDOM.getElementsByTagName("type"):
        stepName=sNode.firstChild.data
        
    
    return processID,stepName  
 

def get_process_type_info(processURI):
    
    
    
    #r = requests.get(processURI, auth=(user, psw), verify=True)
    r=api.GET(processURI)
    rDOM = parseString(r)
    #print(r.content)
    sValue_hash={}
    for pTypeNode in rDOM.getElementsByTagName("field-definition"):
        pTypeURI=pTypeNode.getAttribute("uri")
        pTypeName=pTypeNode.getAttribute("name")
        if pTypeURI not in sValue_hash:
            sValue_hash[pTypeURI]=pTypeName
        
    
    return sValue_hash  
  
def get_udf_info(udfURI):
    
    
    
    r = requests.get(udfURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    #print(r.content)
    sValue_hash={}
    preset_arr=[]
    
    for pTypeNode in rDOM.getElementsByTagName("cnf:field"):
        udfType=pTypeNode.getAttribute("type")
        udfName=pTypeNode.getElementsByTagName("name")[0].firstChild.nodeValue
        udfAttachTo=pTypeNode.getElementsByTagName("attach-to-name")[0].firstChild.nodeValue
        presetNode=pTypeNode.getElementsByTagName("preset")
        for node in presetNode:
            presetValue=node.firstChild.nodeValue
            #print("\t\t\t",presetValue)
            preset_arr.append(presetValue)

        
    
    return udfName, udfType, preset_arr  
         

def get_full_parent_artifact_paths(processID,parentProcessID,kNode):
    global iNode
    artifactType="Analyte"

    iNode=kNode
    sURI=BASE_URI+'processes/'+processID
    r=api.GET(sURI)
    rDOM = parseString( r)

    ppType=rDOM.getElementsByTagName( "type" )[0].firstChild.nodeValue
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")

        sudfValue[udfName]=str(key.firstChild.nodeValue)

    if processID not in pathProcessLUIDs:
       pathProcessLUIDs[processID]=parentProcessID,ppType,str(iNode),sudfValue
       if DEBUG == "1":
           print (processID,pathProcessLUIDs[processID]) 
    #if ppType == activeStep:
    iNode+=1
    #print  (str(iNode),str(len(rDOM.getElementsByTagName( "parent-process" ))))   
    nodes = rDOM.getElementsByTagName( "input-output-map" )
    for node in nodes:
        input = node.getElementsByTagName("input")
        iURI = input[0].getAttribute( "post-process-uri" )
        iLUID = input[0].getAttribute( "limsid" )
        output=node.getElementsByTagName("output")
        oType = output[0].getAttribute( "output-type" )
        ogType = output[0].getAttribute( "output-generation-type" )
        oLUID = output[0].getAttribute( "limsid" )

        new_key=iLUID+"xxx"+oLUID
        map_io[new_key]=processID
        
        for node in node.getElementsByTagName( "parent-process" ):
            pProcessLUID=node.getAttribute('limsid')
            if pProcessLUID not in pathProcessLUIDs:
                get_full_parent_artifact_paths(pProcessLUID,processID,iNode)        
        
             



def get_map_io_by_process(processLuid, artifactType, outputGenerationType):
    ## get the process XML
    map_io={}
    pURI = BASE_URI + "processes/" + processLuid

    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    

    pDOM = parseString( pXML.content )

    ## get the individual resultfiles outputs
    artifactsByProcess=[]
    nodes = pDOM.getElementsByTagName( "input-output-map" )
    for node in nodes:
        input = node.getElementsByTagName("input")
        iURI = input[0].getAttribute( "post-process-uri" )
        iLUID = input[0].getAttribute( "limsid" )
        output=node.getElementsByTagName("output")
        oType = output[0].getAttribute( "output-type" )
        ogType = output[0].getAttribute( "output-generation-type" )
        oLUID = output[0].getAttribute( "limsid" )
        
        new_key=iLUID+"xxx"+oLUID
        if oType == artifactType and ogType == outputGenerationType:#"PerInput":

            map_io[new_key]=oLUID

    return map_io

def get_processID_by_processType(pathProcessLUIDs,processType):
    ss={}
    for key in pathProcessLUIDs:
        (parentProcessID,ppTYpe,sNode,sUDFValues)=pathProcessLUIDs[key]
        if (ppTYpe == processType):
            ss[key]=parentProcessID
        
    return ss

def get_processIDs_by_preffix_processID(pathProcessLUIDs,preffixID, excludeProcessName):
    ss={}
    for key in pathProcessLUIDs:
        (parentProcessID,ppType,sNode,sUDFValues)=pathProcessLUIDs[key]
        if (preffixID in key) and (ppType != excludeProcessName):
            ss[key]=ppType
    return ss


def prepare_artifacts_batch(map_io):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in map_io:
        scURI = BASE_URI+'artifacts/'+art
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def prepare_generic_artifacts_batch(map_io,IOkey):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in map_io:
        if IOkey=='input':
            iArt=art.split('_')[0]
        if IOkey=='output':
            iArt=art.split('_')[1]

        #if '2-' not in iArt:
            #iArt=iArt+"PA1"
        scURI = BASE_URI+'artifacts/'+iArt
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 



def retrieve_artifacts(sXML):
    global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    r=api.POST(sXML, sURI)
    return r
   
def get_generic_sample_list(arrXML):
    arr_temp={}

    rDOM = parseString( arrXML )
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        parentProcessLUID=node.getElementsByTagName("parent-process")[0].getAttribute('limsid')
        wellPos=node.getElementsByTagName('location')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        pos=node.getElementsByTagName('value')[0].firstChild.nodeValue
        #reagent=node.getElementsByTagName('reagent-label')[0].getAttribute('name')
        reagentNode=node.getElementsByTagName('reagent-label')
        sampleNode=node.getElementsByTagName('sample')
        udfNodes= node.getElementsByTagName("udf:field") 
        sudfValue={}       
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            sudfValue[udfName]=str(key.firstChild.nodeValue)
        nr=0
        rr=0
        reagText='zzz'
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        for samples in sampleNode:
            sampleID=samples.getAttribute('limsid')
            rr=0
            for reagentValue in reagentNode:
                #reagText='zzz'
                if rr==nr:
                    reagText=reagentValue.getAttribute('name')
                rr +=1            
            new_key=  sampleID +"_"+artLUID 
            #new_key=  sampleID             
            if new_key not in arr_temp:

                arr_temp[new_key]=pos,artLUID,artName,reagText,containerID,parentProcessLUID,sudfValue
            nr+=1
    return arr_temp


def read_config_file(sFileName):
    
    config = configparser.RawConfigParser()
    config.read(sFileName)
    LibPooling=config.get(IlluminaProtocol,'LibPooling')
    LibNorm=config.get(IlluminaProtocol,'LibNorm')
    ClusterGen=config.get(IlluminaProtocol,'ClusterGen')
    Sequencing=config.get(IlluminaProtocol,'Sequencing')
    if DEBUG:
        print (LibPooling,LibNorm,ClusterGen)
    return LibPooling,LibNorm,ClusterGen,Sequencing

def get_projects_list():
    
    pURI=BASE_URI+"projects/"
    
    while(1):
        #r = requests.get(ss, auth=(user, psw), verify=True) 
        r=api.GET(pURI)
        rDOM = parseString(r)
        nextnodes= rDOM.getElementsByTagName("next-page")
        nodes= rDOM.getElementsByTagName("project")
        for node in nodes:
            # projectNode = node.getElementsByTagName( "project" )
            projLUID = node.getAttribute( "limsid" )
            projName=node.getElementsByTagName('name')[0].firstChild.nodeValue
            Projects_hash[projLUID]=projName
            if DEBUG:
                print (projLUID,projName)
        
        if len(nextnodes) == 0:
            break
        
        for nextnode in nextnodes:
            pURI=nextnode.getAttribute( "uri" )
        
    return

def get_container_names(Container_array):
    
    for container_ID in Container_array:
        sURI=BASE_URI+'containers/'+container_ID
        #r = requests.get(sURI, auth=(user, psw), verify=True)
        r= api.GET(sURI)
        rDOM = parseString(r )
        node =rDOM.getElementsByTagName('name')
        contName = node[0].firstChild.nodeValue
        contPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
        Container_array[container_ID]=contPosition+'xxx'+contName
    

    return
def get_submitted_samples_meta(smplXML):
    pDOM = parseString( smplXML )
    
    for node in pDOM.getElementsByTagName( "smp:sample" ):
        submittedSampleLUID=node.getAttribute('limsid')
        submittedSampleName=node.getElementsByTagName("name")[0].firstChild.data
        projectLUID=node.getElementsByTagName("project")[0].getAttribute('limsid')
        #print(submittedSampleLUID,submittedSampleName,projectLUID)
        udfNodes= node.getElementsByTagName("udf:field") 
        sudfValue={}       
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            #if (udfName =="BASE64POOLDATA"):
            #    s64base=str(key.firstChild.nodeValue).replace("data:text/txt;base64","")
            #    print(base64.b64decode(s64base).decode('utf-8'))
        
        if submittedSampleLUID not in submittedSamples_hash:
            submittedSamples_hash[submittedSampleLUID]=submittedSampleName,projectLUID,sudfValue


def get_meta_sample_array(arrXML):
    rDOM = parseString( arrXML )
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        wellPos=node.getElementsByTagName('location')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        pos=node.getElementsByTagName('value')[0].firstChild.nodeValue
        #reagent=node.getElementsByTagName('reagent-label')[0].getAttribute('name')
        reagentNode=node.getElementsByTagName('reagent-label')
        sampleNode=node.getElementsByTagName('sample')
        nr=0
        rr=0
        reagText='zzz'
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        for samples in sampleNode:
            #
            # Added Samples check to remove unused samples
            # 
            sampleID=samples.getAttribute('limsid')
            #if sampleID in IlluminaAnalysisSamples_hash:
            rr=0
            for reagentValue in reagentNode:
                #reagText='zzz'
                if rr==nr:
                    reagText=reagentValue.getAttribute('name')
                rr +=1            
            new_key=  sampleID +"_"+artLUID              
            if new_key not in Samples_hash:
                Samples_hash[new_key]=pos+'xxx'+artLUID+'xxx'+artName+'xxx'+reagText+'xxx'+containerID
            nr+=1
    return

def prepare_samples_list_for_batch(sXML):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    pDOM = parseString( sXML )
    nodes = pDOM.getElementsByTagName( "sample" )
    for node in nodes:
        sampleURI=node.getAttribute("uri")
        sampleID=node.getAttribute("limsid")
        #if sampleID in IlluminaAnalysisSamples_hash:
        lXML.append( '<link uri="' + sampleURI + '" rel="samples"/>' )  

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_samples(sXML):
    sURI=BASE_URI+'samples/batch/retrieve'
    #headers = {'Content-Type': 'application/xml'}
    #r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    r=api.POST(sXML,sURI)
    return r


def get_submitted_samples_meta(smplXML):
    pDOM = parseString( smplXML )
    
    for node in pDOM.getElementsByTagName( "smp:sample" ):
        submittedSampleLUID=node.getAttribute('limsid')
        submittedSampleName=node.getElementsByTagName("name")[0].firstChild.data
        projectLUID=node.getElementsByTagName("project")[0].getAttribute('limsid')
        #print(submittedSampleLUID,submittedSampleName,projectLUID)
        udfNodes= node.getElementsByTagName("udf:field") 
        sudfValue={}       
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            #if (udfName =="BASE64POOLDATA"):
            #    s64base=str(key.firstChild.nodeValue).replace("data:text/txt;base64","")
            #    print(base64.b64decode(s64base).decode('utf-8'))
        
        if submittedSampleLUID not in submittedSamples_hash:
            submittedSamples_hash[submittedSampleLUID]=submittedSampleName,projectLUID,sudfValue

def get_process_udf(sUDFName):
    #pathProcessLUIDs[processID]=parentProcessID,ppType,str(iNode),sudfValue
    s='N/A'
    for key in pathProcessLUIDs:
        parentProcessID,ppType,iNode,sudfValue = pathProcessLUIDs[key]
        try:
            if sudfValue[sUDFName]:
                s=sudfValue[sUDFName]
                break
        except:
            pass
        
    
    return s 
def get_udf_value(sUDFValues,sUDFName):
    s=''
    try:
        s=sUDFValues[sUDFName]
    except:
        s="N/A"
    return s


def get_DEBUG_base64_to_meta_report(sOUT,sBase64Text,sampleID):
    sOUT_split=sOUT.split("\t")
    sBase64_lines=sBase64Text.split("\n")
    #print(sOUT_split)
    #print(sBase64_lines)
    i=0
    new_text=""
    ss=""
    #print("length="+str(len(sBase64_lines)))
    try:
        for line in sBase64_lines:
            line_split=line.split("\t")
            #print(line,i)
            if i !=0:
                ss=""
                for jj in range(0,len(line_split)):
                    sOUT_item=sOUT_split[jj]
                    sBase64_item=line_split[jj]
                    if DEBUG=='1':
                        print('BASE64 decode', jj,sOUT_item, sBase64_item)
                    sTemp=sOUT_item
                    #if (sOUT_item != "N/A") and (sOUT_item):
                    #    sTemp=sOUT_item

                    if jj ==7:
                        sTemp=sampleID+"-"+str(i)
                    #elif jj ==17:
                    #    sTemp=sampleID
                 
                    if (sBase64_item != "N/A"):
                        sTemp=sBase64_item   
                    
                    sTemp=sTemp.replace("\n","")
                    ss +=sTemp +"\t"
                
                if len(ss) < 4:
                    ss=''
                else:
                    ss=ss[:-1]+"\n"
                #ss +="\n"
            i = i+1    
            new_text += ss
    except Exception as e: 
        print(e)
    return new_text

def get_base64_to_meta_report(sOUT,sBase64Text,sampleID):
    sOUT_split=sOUT.split("\t")
    sBase64_lines=sBase64Text.split("\n")

    i=0
    new_text=""
    ss=""

    try:
        for line in sBase64_lines:
            line_split=line.split("\t")
            if i !=0:
                ss=""
                for jj in range(0,len(line_split)):
                    sOUT_item=sOUT_split[jj]
                    sBase64_item=line_split[jj]
                    if DEBUG:
                        print('BASE64 decode', jj,sOUT_item, sBase64_item)
                    sTemp=sOUT_item
                    if jj ==7:
                        sTemp=sampleID+"-"+str(i)
                 
                    if (sBase64_item != "N/A") and (jj!=21):
                        sTemp=sBase64_item   
                    #
                    # Lane Fraction * Pool Fraction
                    #    
                    if (jj==21) and (sBase64_item != "N/A"):
                        sTemp=str(float(sBase64_item)*float(sOUT_item))
                        
                    sTemp=sTemp.replace("\n","")
                    ss +=sTemp +"\t"

                if len(ss) < 4:
                    ss=''
                else:
                    if len(line_split)<len(sOUT_split):
                        ss +="\t".join(sOUT_split[len(line_split):len(sOUT_split)])                    
                    ss=ss[:-1]+"\n"
                
                
            i = i+1    
            new_text += ss
    except Exception as e: 
        print(e)
    return new_text






def create_event_file(IlluminaSeq_hash):
    sHeader= 'ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\t'
    sHeader +='SampleLUID\tSampleName\tReference\tStart Date\tSample Tag\tTarget Cells\tLibrary Metadata ID\tSpecies\tUDF/Genome Size (Mb)\tGender\t'
    sHeader +='Pool Fraction\tCapture Type\tCaptureLUID\tCapture Name\tCapture REF_BED\tCapture Metadata ID\tArtifactLUIDClustering\t'
    sHeader +='Library Size\tLibrary Kit Name\tCapture Kit Type\tCapture Bait Version\tChIP-Seq Mark\tSequencer Type\tFlowcell Type\tRun Counter\tPCR Kit Name\n'
    sOUT=sHeader
    global aa_hash,uq_hash,art_hash
    iCount=0
    uq_hash={}
    reagentLabel=''
    libArtifactLUID=''
    libProcessName=''  
    sTemp=''
    sBaseData=''
    ssDBG=''
    for k in IlluminaSeq_hash:
        sTargetCells="N/A"
        sLibraryMetadataID="N/A"
        LibNormArtLUID_NS="N/A"
        LibNormArtName_NS="N/A"
        libProcessLUID="N/A"
        sSpecies="N/A"
        sUDF_GenomeSize_Mb="N/A"
        sGender="N/A"
        sPoolFraction="N/A"
        iLaneFraction=0
        sCaptureType="N/A"
        sCaptureLUID="N/A"
        sCaptureName="N/A"
        sCaptureREF_BED="N/A"
        sCaptureMetadataID="N/A"
        sArtifactLUIDClustering="N/A"
        sSampleTag="N/A"
        sUDF_CaptureKitType='N/A'
        sUDF_CaptureBaitVersion='N/A'
        sUDF_LibraryKitName ='N/A' 
        sUDF_LibrarySize ='N/A' 
        sUDF_ChIPSeq_Mark='N/A'
        sPCRKITNAME='N/A'
        (sampleID,iArtifactLUID)=k.split('_')
        
        (pos,artLUID,artName,reagText,containerID,parentProcessLUID,illuminaUDFs)=IlluminaSeq_hash[k]
        
        (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[sampleID]
        if DEBUG:
            print(datetime.datetime.now(),iCount,pos,submittedSampleName,artLUID,artName,reagText,containerID,parentProcessLUID)
        try:
            sStartDate=get_process_udf('Start Date')
        except:
            sStartDate='N/A'
        try:
            sONTSeqConf=get_process_udf('Sequencing Configuration')
        except:
            sONTSeqConf='N/A'
        try:
            sIlluFCType=get_process_udf('Flowcell Type')
        except:
            sIlluFCType='N/A'
        try:
            sRunCounter=get_process_udf('Experiment Name')
        except:
            sRunCounter='N/A'
        try:
            sReference=get_udf_value(submittedUDFValue,'Reference Genome')
        except:
            sReference='N/A'
        try:
            sGender=get_udf_value(submittedUDFValue,'Gender')
        except:
            sGender='N/A'
        try:
            sSpecies=get_udf_value(submittedUDFValue,'Species')
        except:
            sSpecies='N/A'
        try:
            sUDF_GenomeSize_Mb=get_udf_value(submittedUDFValue,'Genome Size')
        except:
            sUDF_GenomeSize_Mb='N/A'
        
        sSequencerType=IlluminaProtocol
        sFCType='N/A'
        if sIlluFCType != 'N/A':
            sFCType=sIlluFCType;
        
        if sONTSeqConf != 'N/A':
            (sFCType,dummy,sSequencerType)=sONTSeqConf.split(' ');
            sSequencerType=IlluminaProtocol+'_'+sSequencerType;
        
        projectName=Projects_hash[projectLUID]
        (positioninContainer,containerName)=Container_array[containerID].split('xxx')
        sTemp=''
        if len(LibraryArtifacts_hash)>0:
            for kk in LibraryArtifacts_hash:
                illumSeqArtifact,libProcessLUID,(parentProcessID,ppType,iNode,sudfValue)=LibraryArtifacts_hash[kk]
                libSampleID,libArtifactLUID,org_illuminaArt=kk.split('_')
                new_kk=libSampleID+"_"+libArtifactLUID
                
                if (libSampleID == sampleID) and (illumSeqArtifact==iArtifactLUID):
                    libPos, libArtLUID, libSampleName, libIndex, libContainerLUID, libProcessLUID, librarySamplesUDFs=librarySamples[new_kk]
                    
                    reagentLabel=libIndex
                    libArtifactLUID=libArtLUID
                    libProcessName=ppType
                    try:
                        sUDF_LibraryKitName =get_udf_value(sudfValue,'Library Kit Name')
                    except:
                        pass   
                    try:
                        sUDF_KitName =get_udf_value(sudfValue,'Kit Name')
                    except:
                        pass
                    if sUDF_LibraryKitName == 'N/A':
                        sUDF_LibraryKitName=sUDF_KitName
                    try:
                        sUDF_ChIPSeq_Mark =get_udf_value(librarySamplesUDFs,'ChIP-Seq Mark')
                    except:
                        pass   
    
                    try:
                        sSampleTag =get_udf_value(librarySamplesUDFs,'Sample Tag')
                    except:
                        pass
                    try:                                           
                        sTargetCells =get_udf_value(librarySamplesUDFs,'Target Cells')
                    except:
                        pass
                    
                    if libProcessName=="Add Multiple Reagents":
                        
                        oldLibArt=oldLib_io[libArtLUID]
                        oldLib_kk=libSampleID+"_"+oldLibArt
                        oldlibPos, oldlibArtLUID, oldlibSampleName, oldlibIndex, oldlibContainerLUID, oldlibProcessLUID, oldlibrarySamplesUDFs=oldlibrarySamples[oldLib_kk]
                        
                        (oldppID,oldProcessName,oldiNode,oldsudfValue)=pathProcessLUIDs[oldlibProcessLUID]
                        
                        libArtifactLUID=oldlibArtLUID
                        libProcessName=oldProcessName
                        libProcessLUID=oldlibProcessLUID
                        try:
                            sUDF_LibraryKitName =get_udf_value(oldsudfValue,'Kit')
                        except:
                            pass 
                        try:
                            sUDF_ChIPSeq_Mark =get_udf_value(oldlibrarySamplesUDFs,'ChIP-Seq Mark')
                        except:
                            pass   
                        try:
                            sSampleTag =get_udf_value(oldlibrarySamplesUDFs,'Sample Tag')
                        except:
                            pass
                    
                    #
                    #
                    #    Library Normalization
                    #
                    #    
                    
                    for num,ll in enumerate(LibNormArtifacts_hash):
                        illumSeqArtifact_fromLibNorm,libNormProcessLUID,(lbNormParentProcessID,ppTypeLibNorm,iNode,sudfValueLibNorm)=LibNormArtifacts_hash[ll]
                        inputlibNormArtifactLUID,outlibNormArtifactLUID=ll.split('_')
                        if (illumSeqArtifact_fromLibNorm==iArtifactLUID):
                            new_index=sampleID+"_"+outlibNormArtifactLUID
                            try:
                                libNormPos, libNormArtLUID, libNormSampleName, libNormIndex, libNormContainerLUID, libNormProcessLUID, libnormSamplesUDFs=libNormSamples[new_index]
                                art_hash={}
                                get_artifact_from_to(map_io,outlibNormArtifactLUID,libProcessLUID,iArtifactLUID)
                                for key in art_hash:
                                    upSampleID,upArtifactLUID,illSeqArtLUID=key.split('_')
                                    if (libArtifactLUID==upArtifactLUID) and (upSampleID==sampleID): 
                                        LibNormArtLUID_NS=libNormArtLUID
                                        LibNormArtName_NS=libNormSampleName
                                        if DEBUG:
                                            print("\tLibNorm new_index:",num,libArtLUID,libIndex,libNormIndex,iArtifactLUID,illumSeqArtifact_fromLibNorm,new_index,LibNormArtName_NS,LibNormArtLUID_NS,inputlibNormArtifactLUID,libNormSampleName, libNormIndex)                            
                                        
                                        try:
                                            iLaneFraction=float(get_udf_value(libnormSamplesUDFs,'Lane Fraction'))
                                            sPoolFraction=str(iLaneFraction)
                                            
                                        except:
                                            pass
                            except Exception as e :
                                #print(e)
                                pass  
                    
                    #
                    #
                    #    PCR
                    #
                    #
                    sPCRKITNAME='N/A';
                    for num,ll in enumerate(PCRArtifacts_hash):
                        PCRArtifact_fromPCR,PCRProcessLUID,(PCRParentProcessID,ppTypePCR,iNode,sudfValuePCR)=PCRArtifacts_hash[ll]
                        inputPCRArtifactLUID,outPCRArtifactLUID=ll.split('_')
                        if (PCRArtifact_fromPCR==iArtifactLUID):
                            new_index=sampleID+"_"+outPCRArtifactLUID
                            try:
                                PCRPos, PCRArtLUID, PCRSampleName, PCRIndex, PCRContainerLUID, PCRProcessLUID, PCRSamplesUDFs=PCRSamples[new_index]
                                art_hash={}
                                get_artifact_from_to(map_io,outPCRArtifactLUID,PCRProcessLUID,iArtifactLUID)
                                for key in art_hash:
                                    upSampleID,upArtifactLUID,PCRArtLUID=key.split('_')
                                    if (outPCRArtifactLUID==upArtifactLUID) and (upSampleID==sampleID): 
                                        PCRArtLUID_NS=PCRArtLUID
                                        PCRArtName_NS=PCRSampleName
                                        if DEBUG:
                                            print("\tPCR new_index:",num,PCRArtLUID,PCRIndex,PCRIndex,iArtifactLUID,PCRArtifact_fromPCR,new_index,PCRArtName_NS,PCRArtLUID_NS,inputPCRArtifactLUID,PCRSampleName, PCRIndex)                        
                                        try:
                                            sPCRKITNAME=get_udf_value(sudfValuePCR,'PCR Kit Name')
                                        except:
                                            pass
                            
                            except Exception as e :
                                #print(e)
                                pass
                    
                    #
                    #
                    # Capture
                    #
                    sCaptureType="N/A"
                    sCaptureLUID="N/A"
                    sCaptureName="N/A"
                    sCaptureREF_BED="N/A"
                    sCaptureMetadataID="N/A"
                    sUDF_CaptureKitType='N/A'
                    sUDF_CaptureBaitVersion='N/A'
                    for cc in CaptureArtifacts_hash:
                        illumSeqArtifact_fromCapture,captureProcessLUID,(captureParentProcessID,ppTypeCapture,iNode,sudfValueCapture)=CaptureArtifacts_hash[cc]
                        #inputCaptureArtifactLUID,outCaptureArtifactLUID=cc.split('_')
                        #inputCaptureArtifactLUID,outCaptureArtifactLUID,org_IllSeqArt=cc.split('_')
                        CaptureSampleLUID,outCaptureArtifactLUID,org_IllSeqArt=cc.split('_')
                        if (illumSeqArtifact_fromCapture==iArtifactLUID) and (CaptureSampleLUID==sampleID):
                            new_index=sampleID+"_"+outCaptureArtifactLUID
                            try:
                                capPos, capArtLUID, capSampleName, capIndex, capContainerLUID, capProcessLUID, capSamplesUDFs=captureSamples[new_index]
                                art_hash={}
                                get_artifact_from_to(map_io,outCaptureArtifactLUID,captureProcessLUID,iArtifactLUID)
                                
                                for key in art_hash:
                                    upSampleID,upArtifactLUID,illSeqArtLUID=key.split('_')
                                    if (outCaptureArtifactLUID==upArtifactLUID) and (upSampleID==sampleID):
                                        if DEBUG:
                                            print("\t\tCapture="+cc,"Chain samplesLUID="+upSampleID,"Capture  sampleLUID:"+CaptureSampleLUID,"IllSeq sampleLUID"+sampleID, "capArtLUID="+capArtLUID,"outCaptureArtifactLUID="+outCaptureArtifactLUID,"upArtifactLUID="+upArtifactLUID)
                                
                                        sCaptureLUID=capArtLUID
                                        sCaptureName=capSampleName
                                        sCaptureType=ppTypeCapture
                                        sCaptureMetadataID=capProcessLUID
                                        try:
                                            sUDF_CaptureKitType=get_udf_value(sudfValueCapture,'Capture Kit Type')
                                        except:
                                            pass
                                        try:
                                            sUDF_CaptureBaitVersion=get_udf_value(sudfValueCapture,'Capture Bait Version')
                                        except:
                                            pass
                                        try:
                                            sCaptureREF_BED=get_udf_value(sudfValueCapture,'Reference')
                                        except:
                                            pass
                                        try:
                                            iSamplesInPool=float(get_udf_value(capSamplesUDFs,'Number of Sample in Pool'))
                                            sPoolFraction='%.5f' %(iLaneFraction/iSamplesInPool)
                                        except:
                                            pass
                            
                            
                            
                            except Exception as e:
                                #print(e)
                                pass
                    
                    if len(LibNormArtName_NS) >36:
                        LibNormArtName_NS=LibNormArtName_NS[0:30]+"..."
                    
                    if len(sCaptureName) >36:
                        sCaptureName=sCaptureName[0:30]+"..."
                    
                    sTemp += ProcessID+'\t'+projectLUID+'\t'+projectName+'\t'+containerID+'\t'+containerName+'\t'+pos+'\t'+reagentLabel+\
                     '\t'+libArtifactLUID+'\t'+libProcessName+'\t'+LibNormArtLUID_NS+'\t'+LibNormArtName_NS+\
                     '\t'+sampleID+'\t'+submittedSampleName+'\t'+sReference+'\t'+sStartDate+\
                     '\t'+sSampleTag+'\t'+sTargetCells+'\t'+libProcessLUID+\
                     '\t'+sSpecies+'\t'+sUDF_GenomeSize_Mb+'\t'+sGender+'\t'+sPoolFraction+\
                     '\t'+sCaptureType+'\t'+sCaptureLUID+'\t'+ sCaptureName+'\t'+sCaptureREF_BED+'\t'+sCaptureMetadataID+'\t'+iArtifactLUID+\
                     '\t'+sUDF_LibrarySize+'\t'+sUDF_LibraryKitName+'\t'+sUDF_CaptureKitType+'\t'+sUDF_CaptureBaitVersion+'\t'+sUDF_ChIPSeq_Mark+\
                     '\t'+sSequencerType+'\t'+sFCType+'\t'+sRunCounter+'\t'+sPCRKITNAME+\
                     '\n'
                    
                    
                    
                sBaseData=''
    
        #
        #
        #    Submitted Library
        #
        try:
            submittedLibType=submittedUDFValue['Sample Type']
            if ('Library' in submittedLibType):
                
                for ll in LibNormArtifacts_hash:
                    illumSeqArtifact_fromLibNorm,libNormProcessLUID,(lbNormParentProcessID,ppTypeLibNorm,iNode,sudfValueLibNorm)=LibNormArtifacts_hash[ll]
                    inputlibNormArtifactLUID,outlibNormArtifactLUID=ll.split('_')
                    if (illumSeqArtifact_fromLibNorm==iArtifactLUID):
                        new_index=sampleID+"_"+outlibNormArtifactLUID
                        #for  ln in libNormSamples:
                        try:
                            libNormPos, libNormArtLUID, libNormSampleName, libNormIndex, libNormContainerLUID, libNormProcessLUID, libnormSamplesUDFs=libNormSamples[new_index]
                            inputlibNormSampleID1,outlibNormArtifactLUID1=new_index.split("_") #ln.split('_')

                            
                            if (inputlibNormSampleID1 == sampleID):
                                LibNormArtLUID_NS=libNormArtLUID
                                LibNormArtName_NS=libNormSampleName
                                if DEBUG:
                                    print("\tsubm lib:",new_index,inputlibNormSampleID1,outlibNormArtifactLUID1,libNormArtLUID,libNormSampleName)
                                try:
                                    iLaneFraction=float(get_udf_value(libnormSamplesUDFs,'Lane Fraction'))
                                    sPoolFraction=str(iLaneFraction)
                                except:
                                    pass
                        except:
                            pass
                            #print(e)     

                #
                #
                # Capture
                #
                sCaptureType="N/A"
                sCaptureLUID="N/A"
                sCaptureName="N/A"
                sCaptureREF_BED="N/A"
                sCaptureMetadataID="N/A"
                sUDF_CaptureKitType='N/A'
                sUDF_CaptureBaitVersion='N/A'                
                for cc in CaptureArtifacts_hash:
                    illumSeqArtifact_fromCapture,captureProcessLUID,(captureParentProcessID,ppTypeCapture,iNode,sudfValueCapture)=CaptureArtifacts_hash[cc]
                    #inputCaptureArtifactLUID,outCaptureArtifactLUID=cc.split('_')
                    inputCaptureArtifactLUID,outCaptureArtifactLUID,org_IllSeqArt=cc.split('_')
                    if (illumSeqArtifact_fromCapture==iArtifactLUID):
                        new_index=sampleID+"_"+outCaptureArtifactLUID
                        try:
                            capPos, capArtLUID, capSampleName, capIndex, capContainerLUID, capProcessLUID, capSamplesUDFs=captureSamples[new_index]
                            art_hash={}
                            get_artifact_from_to(map_io,outCaptureArtifactLUID,captureProcessLUID,iArtifactLUID)
                            
                            for key in art_hash:
                                upSampleID,upArtifactLUID,illSeqArtLUID=key.split('_')
                                
                                if (outCaptureArtifactLUID==upArtifactLUID) and (upSampleID==sampleID): 
                                    if DEBUG:
                                        print("\t\tCapture="+cc,"Capture  samples:","capArtLUID=",capArtLUID,"capSampleName=",capSampleName,ppTypeCapture,capProcessLUID)
                            
                                    sCaptureLUID=capArtLUID
                                    sCaptureName=capSampleName
                                    sCaptureType=ppTypeCapture
                                    sCaptureMetadataID=capProcessLUID
                                    try:
                                        sUDF_CaptureKitType=get_udf_value(sudfValueCapture,'Capture Kit Type')
                                    except:
                                        pass
                                    try:
                                        sUDF_CaptureBaitVersion=get_udf_value(sudfValueCapture,'Capture Bait Version')
                                    except:
                                        pass
                                    try:
                                        sCaptureREF_BED=get_udf_value(sudfValueCapture,'Reference')
                                    except:
                                        pass
                                    try:
                                        iSamplesInPool=float(get_udf_value(capSamplesUDFs,'Number of Sample in Pool'))
                                        sPoolFraction='%.5f' %(iLaneFraction/iSamplesInPool)
                                    except:
                                        pass
                        except Exception as e:
                            #print(e)
                            pass
                
                
                
                sLast = ProcessID+'\t'+projectLUID+'\t'+projectName+'\t'+containerID+'\t'+containerName+'\t'+pos+'\t'+reagentLabel+\
                 '\t'+libArtifactLUID+'\t'+libProcessName+'\t'+LibNormArtLUID_NS+'\t'+LibNormArtName_NS+\
                 '\t'+sampleID+'\t'+submittedSampleName+'\t'+sReference+'\t'+sStartDate+\
                 '\t'+sSampleTag+'\t'+sTargetCells+'\t'+libProcessLUID+\
                 '\t'+sSpecies+'\t'+sUDF_GenomeSize_Mb+'\t'+sGender+'\t'+sPoolFraction+\
                 '\t'+sCaptureType+'\t'+sCaptureLUID+'\t'+ sCaptureName+'\t'+sCaptureREF_BED+'\t'+sCaptureMetadataID+'\t'+iArtifactLUID+\
                 '\t'+sUDF_LibrarySize+'\t'+sUDF_LibraryKitName+'\t'+sUDF_CaptureKitType+'\t'+sUDF_CaptureBaitVersion+'\t'+sUDF_ChIPSeq_Mark+\
                 '\t'+sSequencerType+'\t'+sFCType+'\t'+sRunCounter+'\t'+sPCRKITNAME+\
                 '\n'
                if DEBUG:
                    print(sLast)
                sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                #sBaseData=get_DEBUG_base64_to_meta_report(sLast,sBase64Text,sampleID)
                sBaseData=get_base64_to_meta_report(sLast,sBase64Text,sampleID)
                              
        except Exception as e:
            #print(e)
            pass

                
        sOUT +=sBaseData +sTemp
        iCount +=1
#    except Exception as e: 
#        print(e)
    return sOUT



def isReplicas(libNorm_hash):
    uq_Input=[]
    uq_Output=[]
    print (libNorm_hash)
    for key in libNorm_hash:
        print(key)
        try:
            inputArtifact, outputArtifact=key.split("_")
            print(inputArtifact, outputArtifact)
            if inputArtifact not in uq_Input:
                uq_Input.append(inputArtifact)
            if outputArtifact not in uq_Output:
                uq_Output.append(outputArtifact)
        except Exception as e:
            print (e)        
        
    
    return len(uq_Input), len(uq_Output)


def write_event_file(sText,sFilePath):
    sExtra="_"+str(ProcessID)+"_samples.txt"
    f_out=open(sFilePath+FileReportLUIDs[6]+sExtra,"w")
    f_out.write(sText)
    f_out.close()
    
    return

'''

    START
    
'''



def main():

    global api
    global ARGS
    global TODAY, LOG,COLS,ROWS,DEBUG,args,user, psw,    map_io, \
    pathProcessLUIDs,IlluminaProtocol, Projects_hash,Container_array,\
    Samples_hash,submittedSamples_hash, oldLibraries, oldLib_hash, art_hash,FileReportLUIDs
    DEBUG=False

    args = setup_arguments()
    user=args.username
    psw=args.password
    api = glsapiutil3x.glsapiutil3()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password ) 
       
    sampleLUID=args.sampleLUID
    IlluminaProtocol=args.IlluminaProtocol
    attachLUIDs=args.attachFilesLUIDs
    attachLUIDs=attachLUIDs[:-1]
    FileReportLUIDs=attachLUIDs.split(' ')    
    debug=args.debug
    if debug=='1':
        DEBUG=True
    map_io={}
    pathProcessLUIDs={}
    Projects_hash={}
    Container_array={}
    Samples_hash={}
    submittedSamples_hash={}
    oldLibraries=["Lucigen AmpFREE Low DNA 1.0","Kapa Hyper Plus"]
    oldLib_hash={}
    art_hash={}
        
    setupGlobalsFromURI( args.stepURI )
    global LibPooling,LibNorm,ClusterGen,Sequencing
    
    LibPooling,LibNorm,ClusterGen,Sequencing=read_config_file(script_dir+"/protocols.txt")
    if DEBUG:
        print(LibPooling,LibNorm,ClusterGen,Sequencing)
    
    get_projects_list()

    
    if DEBUG:    
        for proJ in sorted(Projects_hash):
            print(proJ, Projects_hash[proJ])
    
    get_full_parent_artifact_paths(ProcessID,'',1)
    
    if DEBUG:
        print ("#### All processes")
        for kk in sorted(pathProcessLUIDs):
            print(kk, pathProcessLUIDs[kk])
       
    if DEBUG==1:    
        print ("#### MAP IO")            
        for key in sorted(map_io):
            print(key,map_io[key])
    global i, LibIDs,IlluminaSequenceSamples,artifacts_info, globalArtifact,\
    LibraryArtifacts_hash,librarySamples,libNormSamples,LibNormArtifacts_hash,\
    CaptureArtifacts_hash, captureSamples,oldLibraryArtifacts_hash,PCRArtifacts_hash,PCRSamples

    
    i=0
    uq_hash=find_process_artifacts(map_io, ProcessID)
    batchXML=prepare_artifacts_batch(uq_hash)
    rXML=retrieve_artifacts(batchXML)

    IlluminaSequenceSamples=get_generic_sample_list(rXML)
    
    get_container_names(Container_array)
    if DEBUG:
        print(Container_array)
    
    
    get_meta_sample_array(rXML)
    
    if DEBUG:
        print ( "Samples_hash:\t"+str(len( Samples_hash)))
    
    rsmplXML=prepare_samples_list_for_batch(rXML)
    smplXML=retrieve_samples(rsmplXML)
    
    get_submitted_samples_meta(smplXML)


    
    if DEBUG:
        jj=0
        print ("#### Illumina Sequencing artifacts")
        for key in IlluminaSequenceSamples:
            print(jj,key,IlluminaSequenceSamples[key])
            jj +=1   
   
    global oldLib_io,oldLibraryArtifacts_hash,oldlibrarySamples   
    oldLibIDs=[]

    for key in pathProcessLUIDs:
        parentProcessID,ppType,iNode,sudfValue=pathProcessLUIDs[key]
        #print(key,ppType)
        if ppType in oldLibraries:
            if key not in oldLibIDs:
                #print(key,ppType)
                oldLibIDs.append(key)
                
    
    artifacts_info={}
    for key in sorted(uq_hash):
        i=0
        globalArtifact=key
        
        for oldlibID in sorted(oldLibIDs): #captureID:
            if DEBUG:
                print (key,"oldlibID =>",oldlibID)  
            find_lib_artifact_chain_from_last(map_io,key,oldlibID)
    
    oldLibraryArtifacts_hash=artifacts_info.copy()
    
    oldlibXML=prepare_generic_artifacts_batch(oldLibraryArtifacts_hash, 'output')
    rXML=retrieve_artifacts(oldlibXML)
    oldlibrarySamples=get_generic_sample_list(rXML)

    
    if DEBUG:    
        print("\n ###### old Libraries ###########\n")
        j=0
        for kk in oldlibrarySamples:
            print (j,kk, oldlibrarySamples[kk])
            j+=1

    oldLib_io={}
    for kk in oldlibrarySamples:
        smplLUID,outArt=kk.split("_")
        for k in map_io:
            iArt,oArt=k.split("xxx")
            if oArt==outArt:
                oldLib_io[iArt]=oArt
    
       
    LibIDs =[]
    for key in pathProcessLUIDs:
        if "151-" in key:
            if key not in LibIDs: 
                LibIDs.append(key)    
    artifacts_info={}
    for key in sorted(uq_hash):
        i=0
        globalArtifact=key
        for libID in sorted(LibIDs): #captureID:
            find_lib_artifact_chain_from_last(map_io,key,libID)
    
    LibraryArtifacts_hash=artifacts_info.copy()
    artifacts_info={}    
    if DEBUG:
        print ("######### Libraries artifacts_info ##############")
        i=0
        for kk in LibraryArtifacts_hash:
            print (i,kk, LibraryArtifacts_hash[kk])
            i+=1   
    
    libXML=prepare_generic_artifacts_batch(LibraryArtifacts_hash, 'output')
    rXML=retrieve_artifacts(libXML)
    librarySamples=get_generic_sample_list(rXML)
    if DEBUG:    
        print("\n ###### Libraries ###########\n")
        j=0
        for kk in librarySamples:
            print (j,kk, librarySamples[kk])
            j+=1
        
    LibNormIDs=get_processID_by_processType(pathProcessLUIDs,LibNorm)       
    artifacts_info={}
    for key in uq_hash:
        i=0
        globalArtifact=key
        for libNormID in LibNormIDs: 
            find_artifact_chain_from_last(map_io,key,libNormID)
    LibNormArtifacts_hash=artifacts_info.copy()

    if DEBUG:
        iCount,oCount=isReplicas(artifacts_info)
        print (iCount,oCount) 
    
    if DEBUG:
        print("\n ###### Library Normalization ###########\n")
        i=0
        for kk in LibNormArtifacts_hash:
            print (i,kk, LibNormArtifacts_hash[kk])
            i+=1

    libNormXML=prepare_generic_artifacts_batch(LibNormArtifacts_hash, 'output')
    rXML=retrieve_artifacts(libNormXML)
    libNormSamples=get_generic_sample_list(rXML)
    if DEBUG:    
        print("\n ###### LibNorm Samples ###########\n")
        j=0
        for kk in libNormSamples:
            print (j,kk, libNormSamples[kk])
            j+=1
    
    PCRIDs=get_processID_by_processType(pathProcessLUIDs,'VirusSeq PCR')
    artifacts_info={}
    for key in uq_hash:
        i=0
        globalArtifact=key
        for PCRID in PCRIDs: 
            find_artifact_chain_from_last(map_io,key,PCRID)
    PCRArtifacts_hash=artifacts_info.copy()

    if DEBUG:
        print("\n ###### VirusSeq PCR ###########\n")
        i=0
        for kk in PCRArtifacts_hash:
            print (i,kk, PCRArtifacts_hash[kk])
            i+=1

    PCRXML=prepare_generic_artifacts_batch(PCRArtifacts_hash, 'output')
    rXML=retrieve_artifacts(PCRXML)
    PCRSamples=get_generic_sample_list(rXML)
    if DEBUG:    
        print("\n ###### PCR Samples ###########\n")
        j=0
        for kk in PCRSamples:
            print (j,kk, PCRSamples[kk])
            j+=1
    
    
    
    captureIDs=get_processIDs_by_preffix_processID(pathProcessLUIDs,'122-', LibPooling)
    
    
    artifacts_info={}
    for key in uq_hash:
        i=0
        globalArtifact=key
        for capID in captureIDs: 
            #find_artifact_chain_from_last(map_io,key,capID) 
            find_lib_artifact_chain_from_last(map_io,key,capID)
        
        i=0
    
    CaptureArtifacts_hash=artifacts_info.copy()
    
    captureXML=prepare_generic_artifacts_batch(CaptureArtifacts_hash, 'output')
    rXML=retrieve_artifacts(captureXML)
    captureSamples=get_generic_sample_list(rXML)    
    
    
    artifacts_info={}
    if DEBUG:
        print("\n ###### Capture Artifacts hash ###########\n")    
        for kk in CaptureArtifacts_hash:
            print (i,kk, CaptureArtifacts_hash[kk])
            i+=1
        
    if DEBUG:    
        print("\n ###### Capture Samples ###########\n")
        j=0
        for kk in captureSamples:
            print (j,kk, captureSamples[kk])
            j+=1
        
    #exit()    
    poolingIDs=get_processID_by_processType(pathProcessLUIDs,"Library Pool")
    artifacts_info={}
    for key in uq_hash:
        i=0
        for poolID in poolingIDs: 
            find_artifact_chain_from_last(map_io,key,poolID) 
            
    PoolArtifacts_hash=artifacts_info.copy() 
    artifacts_info={}
    i=0
    if DEBUG:
        print("\n ###### Pool Samples ###########\n")            
        for kk in PoolArtifacts_hash:
            print (i,kk, PoolArtifacts_hash[kk])
            i+=1
                
        print ("library IDs",LibIDs)
        print("Library Normalization IDs",LibNormIDs)
        print ("Capture IDs",captureIDs)
        print ("Pool samples ID", poolingIDs)

    
    '''
        
        MAIN
    
    '''
    

    sOUT=create_event_file(IlluminaSequenceSamples)
    
    print(sOUT)
    
    write_event_file(sOUT, sEventPath)
    
    
        
    
    

if __name__ == "__main__":
    main()
    
