'''
Created on Feb 22, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
usage:
    /usr/bin/python3.5 /tmp/Illumina_create_generic_event_file.py   -user {username} -psw {password} -IlluminaProtocol=<HiSeqX|NovaSeq>   -stepURI_v2={stepURI_v2} -attachFilesLUIDs='92-489795 ... 92-489797'
     
    
    update 2019_03_20:
        ==> renamed to  "IlluminaSeq_create_generic_event_file.py"  from as IlluminaSeq_create_generic_event_file_n1_0320.py
        - added write_event function
    update 2019_03_19:
        - added create_event_GENERIC_file function to handle all possible multiple lib indexes, replicas, pooling an dcapture
            tested with:
            - 92276 ("hard" example on TEST ) also looks good
            - 92263 (on TEST)
            - 58295 (same sample with different indexes on PROD)
            - 58299 (replicas in LibNorm on PROD)
            - 
    update 2019_03_16:
        - added scan for multiple Libraries per sample 

    update 2019_03_12:
        - added scan in LibNorm hash to handle multiple Library Norm steps coming to Illumina Sequencing
        - updated artifact back tracking from Illumina Seq step to Library Norm or Library preparation steps

'''
__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, sys

from time import gmtime, strftime
import requests
import re
import time
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET
import base64
import configparser
import traceback


user=''
psw=''
#URI_base='https://bravotestapp.genome.mcgill.ca/api/v2/'

HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""


script_dir=os.path.dirname(os.path.realpath(__file__))

sDataPath='/data/glsftp/clarity/'
sEventPath='/lb/robot/research/processing/events/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')


def setupArguments():
    parser = argparse.ArgumentParser(description='Create CSV file for barcode printer')
    parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
    parser.add_argument('-user',default='', help='API user')
    parser.add_argument('-psw',default='', help='API password')
    parser.add_argument('-debug',default='', help='option for debugging')
    parser.add_argument('-IlluminaProtocol',default='NovaSeq', help='<HiSeqX|NovaSeq>')
    parser.add_argument('-attachFilesLUIDs',default='', help='LUIDs for report files attachment')
    
 
    return parser.parse_args()





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

def get_parent_process(processID,parentProcessID):
    sURI=BASE_URI+'processes/'+processID
    #print (sURI)
    r = requests.get(sURI, auth=(user, psw), verify=True)
    #print (r)
    rDOM = parseString( r.content )
    #print (r.content)
    ppTYpe=rDOM.getElementsByTagName( "type" )[0].firstChild.nodeValue
    if processID not in parentProcessLUIDs:
       parentProcessLUIDs[processID]=parentProcessID+","+ppTYpe
       print (processID+","+parentProcessLUIDs[processID])    
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in parentProcessLUIDs:
            get_parent_process(pProcessLUID,processID)

def get_processID_by_processType(parentProcessLUIDs,processType):
    ss={}
    for key in parentProcessLUIDs:
        (parentProcessID,ppTYpe,sNode,sUDFValues)=parentProcessLUIDs[key]
        if (ppTYpe == processType):
            ss[key]=parentProcessID
        
    return ss

def get_full_parent_process_paths(processID,parentProcessID,kNode):
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
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")
        #print(udfName,key.firstChild.nodeValue)
        sudfValue[udfName]=str(key.firstChild.nodeValue)

    if processID not in pathProcessLUIDs:
       pathProcessLUIDs[processID]=parentProcessID,ppType,str(iNode),sudfValue
       if DEBUG == "1":
           print (processID,pathProcessLUIDs[processID]) 
    #if ppType == activeStep:
    iNode+=1
    #print  (str(iNode),str(len(rDOM.getElementsByTagName( "parent-process" ))))            
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in pathProcessLUIDs:
            get_full_parent_process_paths(pProcessLUID,processID,iNode)


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

def get_map_io_by_process(processLuid, artifactType, outputGenerationType):
    ## get the process XML
    map_io={}
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    
    #print (pXML.content)
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
            #if iLUID not in map_io:
            map_io[new_key]=oLUID

    return map_io


def prepare_artifacts_batch(map_io,IOkey):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in map_io:
        if IOkey=='input':
            iArt=art.split('xxx')[0]
        if IOkey=='output':
            iArt=art.split('xxx')[1]

        #if '2-' not in iArt:
            #iArt=iArt+"PA1"
        scURI = BASE_URI+'artifacts/'+iArt
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
            if sampleID in IlluminaAnalysisSamples_hash:
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

def get_generic_sample_list(arrXML):
    arr_temp={}
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
            sampleID=samples.getAttribute('limsid')
            rr=0
            for reagentValue in reagentNode:
                #reagText='zzz'
                if rr==nr:
                    reagText=reagentValue.getAttribute('name')
                rr +=1            
            #new_key=  sampleID +"_"+artLUID 
            new_key=  sampleID             
            if new_key not in arr_temp:
                arr_temp[new_key]=pos+'xxx'+artLUID+'xxx'+artName+'xxx'+reagText+'xxx'+containerID
            nr+=1
    return arr_temp



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




def prepare_samples_list_for_batch(sXML):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    pDOM = parseString( sXML )
    nodes = pDOM.getElementsByTagName( "sample" )
    for node in nodes:
        sampleURI=node.getAttribute("uri")
        sampleID=node.getAttribute("limsid")
        if sampleID in IlluminaAnalysisSamples_hash:
            lXML.append( '<link uri="' + sampleURI + '" rel="samples"/>' )  

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_samples(sXML):
    sURI=BASE_URI+'samples/batch/retrieve'
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    return r.content



def get_lib_artifacts_info(artXML):
    sudfValue={}
    

    pDOM = parseString( artXML )
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        Lib_artifactLUID=artifact.getAttribute('limsid')
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        reagentLabel=artifact.getElementsByTagName('reagent-label')[0].getAttribute('name')
        sampleLUID=artifact.getElementsByTagName('sample')[0].getAttribute('limsid')
        udfNodes= artifact.getElementsByTagName("udf:field")
        libProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
        (parentProcessID,libProcessName,sNode,sUDFValues)=pathProcessLUIDs[libProcessLUID]
        
        
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            
        if Lib_artifactLUID not in LibProcesses_artifact_hash:
            LibProcesses_artifact_hash[Lib_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue)

        
    #return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue
    return 



def get_pools_artifacts_info(artXML):

    generic_hash={}
    

    pDOM = parseString( artXML )
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        sudfValue={}
        reagentLabels=[]
        poolSamples=[]
        artifactLUID=artifact.getAttribute('limsid')
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        reagentLabelNodes=artifact.getElementsByTagName('reagent-label')
        for node in reagentLabelNodes:
            if node.getAttribute('name') not in reagentLabels:
                reagentLabels.append(node.getAttribute('name'))
        
        sampleLUIDNodes=artifact.getElementsByTagName('sample')
        for sNode in sampleLUIDNodes:
            if sNode.getAttribute('limsid') not in poolSamples:
                poolSamples.append(sNode.getAttribute('limsid'))
        
        
        poolProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
        (parentProcessID,poolProcessName,sNode,sUDFValues)=pathProcessLUIDs[poolProcessLUID]
        

        udfNodes= artifact.getElementsByTagName("udf:field")        
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            
        #if artifactLUID not in PoolProcesses_artifact_hash:
        #    PoolProcesses_artifact_hash[artifactLUID]= (arttifactName,containerID,reagentLabels,poolProcessLUID, poolProcessName, poolSamples,sudfValue)
        if artifactLUID not in generic_hash:
            generic_hash[artifactLUID]= (arttifactName,containerID,reagentLabels,poolProcessLUID, poolProcessName, poolSamples,sudfValue)
            
    #return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue
    return generic_hash

def get_artifact_path(global_IO_hash,artifactLUID, startProcessLUID, stopProcessLUID):
    art_hash={}
    i=0
    #print(artifactLUID, startProcessLUID, stopProcessLUID)
    for key in global_IO_hash:
        (processLUID,iArtifact,oArtifact)=key.split('_')
        (previosProcessLUID, processName, iOrder)= global_IO_hash[key].split(',')
        if (startProcessLUID==processLUID) and (iArtifact==artifactLUID):
            #print  (processLUID,iArtifact,oArtifact,previosProcessLUID, processName, iOrder)
            art_hash[iArtifact+"_"+oArtifact]=previosProcessLUID
            i +=1
    for k in   art_hash:
        (iArtifact,oArtifact)=k.split("_")
        nextProcess=art_hash[k]
        get_artifact_path(global_IO_hash,oArtifact, nextProcess, stopProcessLUID)
        

def get_artifact_back_path(global_IO_hash,artifactLUID, startProcessLUID, stopProcessLUID):
    #art_hash={}
    i=0
    

    for key in global_IO_hash:
        (iArtifact,oArtifact)=key.split('_')
        (processLUID, (parentLUID, processName, iOrder, sudfValues))=global_IO_hash[key]
        if (oArtifact==artifactLUID):
            if DEBUG =='2':
                print  ("path:\t"+oArtifact+"=>"+iArtifact+"\t process: "+parentLUID+"=>"+processLUID+"\t"+processName+"\t"+iOrder)
            
            #art_hash[iArtifact+"_"+oArtifact]=parentLUID

            if processLUID==startProcessLUID:
                
                aa_hash.append([iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder]) #=(iArtifact,oArtifact)
                
                if DEBUG =='2':
                    print  ("OK:\t"+oArtifact+"=>"+iArtifact+"\t process: "+parentLUID+"=>"+processLUID+"\t"+processName+"\t"+iOrder)
                    
                #break
                
                
            get_artifact_back_path(global_IO_hash,iArtifact, startProcessLUID,parentLUID)

    return #aa_hash

def get_artifact_back_path_LibNorm(global_IO_hash,artifactLUID, startProcessLUID, stopProcessLUID):
    #art_hash={}
    i=0
    for key in global_IO_hash:
        (iArtifact,oArtifact)=key.split('_')
        (processLUID, (parentLUID, processName, iOrder, sudfValues))=global_IO_hash[key]
        if (oArtifact==artifactLUID):
            #print  ("DEBUG Libnorm:\t"+oArtifact+"=>"+iArtifact+"\t process: "+parentLUID+"=>"+processLUID+"\t"+processName+"\t"+iOrder)
            #art_hash[iArtifact+"_"+oArtifact]=parentLUID
            
            if processLUID==startProcessLUID:
                if DEBUG =='2':
                    print  ("OK Libnorm:\t"+oArtifact+"=>"+iArtifact+"\t process: "+parentLUID+"=>"+processLUID+"\t"+processName+"\t"+iOrder)
                
                #aa_hash.append(artifactLUID) #=(iArtifact,oArtifact)
                aa_hash.append([iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder]) #=(iArtifact,oArtifact)
                #print ("OK",aa_hash,processName,processLUID)
                #break
                
                
            get_artifact_back_path_LibNorm(global_IO_hash,iArtifact, startProcessLUID,parentLUID)
            
    '''        
    for k in   art_hash:
        (iArtifact,oArtifact)=k.split("_")
        nextProcess=art_hash[k]
        get_artifact_back_path(global_IO_hash,iArtifact, nextProcess, stopProcessLUID)
    '''
    return #aa_hash



def get_artifacts_from_global_IO(global_IO_hash, procName, procLUID):
    art_hash={}
    io_art_hash={}
    i=0
    #print(artifactLUID, startProcessLUID, stopProcessLUID)
    for key in global_IO_hash:
        (iArtifact,oArtifact)=key.split('_')
        (processLUID, (parentLUID, processName, iOrder, sudfValues))=global_IO_hash[key]
        
        if (processName==procName):
            art_hash[iArtifact]=oArtifact
            io_art_hash[iArtifact+"_"+oArtifact]=processLUID
                     
    return art_hash,io_art_hash


 
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
        if DEBUG:
            print (projLUID,projName)
        

    return 
def get_udf_value(sUDFValues,sUDFName):
    s=''
    try:
        s=sUDFValues[sUDFName]
    except:
        s="N/A"
    return s
    
              
def create_event_file(IlluminaSeq_hash):
    sHeader= 'ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\t'
    sHeader +='SampleLUID\tSampleName\tReference\tStart Date\tSample Tag\tTarget Cells\tLibrary Metadata ID\tSpecies\tUDF/Genome Size (Mb)\tGender\t'
    sHeader +='Pool Fraction\tCapture Type\tCaptureLUID\tCapture Name\tCapture REF_BED\tCapture Metadata ID\tArtifactLUIDClustering\n'
    
    sOUT=sHeader
    global aa_hash
    iCount=0
    try:
        for k in IlluminaSeq_hash:
            sTargetCells="N/A"
            sLibraryMetadataID="N/A"
            #sSpecies="N/A"
            #sUDF_GenomeSize_Mb="N/A"
            #sGender="N/A"
            #sPoolFraction="N/A"
            sCaptureType="N/A"
            sCaptureLUID="N/A"
            sCaptureName="N/A"
            sCaptureREF_BED="N/A"
            sCaptureMetadataID="N/A"
            sArtifactLUIDClustering="N/A"
            sSampleTag="N/A"
            (sampleID,iArtifactLUID)=k.split('x')
            
            (pos,artLUID,artName,reagText,containerID,parentProcessLUID)=IlluminaSeq_hash[k]
            (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[sampleID]
            try:
                sStartDate=get_process_udf('Start Date')
            except:
                sStartDate='N/A'
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
                
                
            projectName=Projects_hash[projectLUID]
            (positioninContainer,containerName)=Container_array[containerID].split('xxx')

                
            
            sLibMeta=get_lib_meta(LibProcesses_artifact_hash, sampleID)
            #if DEBUG=='1':
            #    print ("sampleid:\t",str(iCount),sampleID,sLibMeta)            
            for prelibArtifactLUID,reagentLabel,prelibProcessLUID, prelibProcessName in sLibMeta:
                aa_hash=[]
                get_artifact_back_path(global_IO_hash,iArtifactLUID, prelibProcessLUID, ProcessID)
                 
                for iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder in aa_hash:
                    if sampleID in iArtifact :
                       libArtifactLUID=oArtifact
                       libProcessLUID= startProcessLUID
                       libProcessName=processName
                       if DEBUG=='1':
                            print("aa_hash info ",iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder)
                    
                       break

            #(libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)=get_lib_meta(LibProcesses_artifact_hash, sampleID)

            
            #if DEBUG=='1':
            #    print("LibArtifact ==>",libArtifactLUID,iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, libProcessLUID,iOrder)
            
            LibNormArtLUID_NS=''
            LibNormArtName_NS=''
            #
            #  Find  number of samples in the pre Pool
            iPrePoolNumberSamplesperPool=0         
            for i in prePool_hash:
                (arttifactName,containerID,reagentLabels,poolProcessLUID, poolProcessName, poolSamples,sudfValue)=prePool_hash[i]
                if sampleID in poolSamples:
                    iPrePoolNumberSamplesperPool=len(poolSamples)
                    sCaptureType=poolProcessName #"N/A"
                    sCaptureLUID=i
                    sCaptureMetadataID=poolProcessLUID
                    sCaptureName=arttifactName
                    if len(sCaptureName)>36:
                        sCaptureName=sCaptureName[0:30]+"..."
                    
            
            for LibNormArt in LibNorm_hash:
                
                    
                '''
                aa_hash=[]
                for liNormLUID, libProcessLUID in LibNormID.items():
                    get_artifact_back_path_LibNorm(global_IO_hash,iArtifactLUID, liNormLUID, ProcessID)
                    if len(aa_hash)>0:
                        for iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder in aa_hash:
                            LibNormArt=oArtifact
                            if (DEBUG=='1') :
                               print ("LibNorm from aa_hash=",iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder)
                '''    
                sPoolFraction='N/A'
                
                #if len(aa_hash)>0:
                                    
                (libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)=LibNorm_hash[LibNormArt]
                #if DEBUG=='1':
                #    print("LibNorm=>",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                
                if iPool ==1:
                    if sampleID in libNormGenericSample:
                        if DEBUG=='1':
                            print("OK LibNorm",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                        
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        if len(LibNormArtName_NS) >36:
                            LibNormArtName_NS=LibNormArtName_NS[0:30]+"..."
                            
                        
                        sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        if iPrePoolNumberSamplesperPool !=0:
                            sPoolFraction='%.5f' %(float(sPoolFraction)/iPrePoolNumberSamplesperPool)
    
                        '''
                        try:
                            sPoolFraction=libNormsUDFValue['Lane Fraction']
                            sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        except:
                            pass
                        '''
                else:
                    if sampleID == libNormGenericSample:
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        
                            
            
            sTemp =''
            #   parentProcessLUID
            sTemp= ProcessID+'\t'+projectLUID+'\t'+projectName+'\t'+containerID+'\t'+containerName+'\t'+pos+'\t'+reagentLabel+\
             '\t'+libArtifactLUID+'\t'+libProcessName+'\t'+LibNormArtLUID_NS+'\t'+LibNormArtName_NS+\
             '\t'+sampleID+'\t'+submittedSampleName+'\t'+sReference+'\t'+sStartDate+\
             '\t'+sSampleTag+'\t'+sTargetCells+'\t'+libProcessLUID+'\t'+sSpecies+'\t'+sUDF_GenomeSize_Mb+'\t'+sGender+'\t'+sPoolFraction+\
             '\t'+sCaptureType+'\t'+sCaptureLUID+'\t'+ sCaptureName+'\t'+sCaptureREF_BED+'\t'+sCaptureMetadataID+'\t'+artLUID+\
            '\n'   
            #sOUT += sTemp
            #+sBaseData
            sBaseData=''
            try:
                submittedLibType=submittedUDFValue['Sample Type']
                '''
                if submittedLibType=='Library Pool':
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''
                '''
                if ('Library' in submittedLibType):
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''              
            except:
                pass
            
            sOUT +=sBaseData +sTemp
            #if iCount>3:
            #    break
            iCount +=1
    except Exception as e: 
        print(e)
        
                
    return sOUT

def create_event_multiLib_file(IlluminaSeq_hash):
    sHeader= 'ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\t'
    sHeader +='SampleLUID\tSampleName\tReference\tStart Date\tSample Tag\tTarget Cells\tLibrary Metadata ID\tSpecies\tUDF/Genome Size (Mb)\tGender\t'
    sHeader +='Pool Fraction\tCapture Type\tCaptureLUID\tCapture Name\tCapture REF_BED\tCapture Metadata ID\tArtifactLUIDClustering\n'
    
    sOUT=sHeader
    global aa_hash,uq_hash
    iCount=0
    uq_hash={}
    try:
        for k in IlluminaSeq_hash:
            sTargetCells="N/A"
            sLibraryMetadataID="N/A"
            #sSpecies="N/A"
            #sUDF_GenomeSize_Mb="N/A"
            #sGender="N/A"
            #sPoolFraction="N/A"
            sCaptureType="N/A"
            sCaptureLUID="N/A"
            sCaptureName="N/A"
            sCaptureREF_BED="N/A"
            sCaptureMetadataID="N/A"
            sArtifactLUIDClustering="N/A"
            sSampleTag="N/A"
            (sampleID,iArtifactLUID)=k.split('x')
            
            (pos,artLUID,artName,reagText,containerID,parentProcessLUID)=IlluminaSeq_hash[k]
            (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[sampleID]
            try:
                sStartDate=get_process_udf('Start Date')
            except:
                sStartDate='N/A'
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
                
                
            projectName=Projects_hash[projectLUID]
            (positioninContainer,containerName)=Container_array[containerID].split('xxx')

                
            
            sLibMeta=get_lib_meta(LibProcesses_artifact_hash, sampleID)
            sLibMeta_local=sLibMeta
            #if DEBUG=='1':
            #    print ("sampleid:\t",str(iCount),sampleID,sLibMeta)            
            for prelibArtifactLUID,reagentLabel,prelibProcessLUID, prelibProcessName in sLibMeta:
                aa_hash=[]
                get_artifact_back_path(global_IO_hash,iArtifactLUID, prelibProcessLUID, ProcessID)
                 
                for iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder in aa_hash:
                    if sampleID in iArtifact :
                       libArtifactLUID=oArtifact
                       libProcessLUID= startProcessLUID
                       libProcessName=processName
                       if DEBUG=='1':
                            print("aa_hash info ",iArtifact,oArtifact,reagentLabel,parentLUID, processLUID, startProcessLUID,processName, iOrder)
                    
                       break

            #(libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)=get_lib_meta(LibProcesses_artifact_hash, sampleID)

            
            #if DEBUG=='1':
            #    print("LibArtifact ==>",libArtifactLUID,iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, libProcessLUID,iOrder)
            
            LibNormArtLUID_NS=''
            LibNormArtName_NS=''
            #
            #  Find  number of samples in the pre Pool
            iPrePoolNumberSamplesperPool=0         
            for i in prePool_hash:
                (arttifactName,containerID,reagentLabels,poolProcessLUID, poolProcessName, poolSamples,sudfValue)=prePool_hash[i]
                if sampleID in poolSamples:
                    iPrePoolNumberSamplesperPool=len(poolSamples)
                    sCaptureType=poolProcessName #"N/A"
                    sCaptureLUID=i
                    sCaptureMetadataID=poolProcessLUID
                    sCaptureName=arttifactName
                    if len(sCaptureName)>36:
                        sCaptureName=sCaptureName[0:30]+"..."
                    
            sTemp =''
            for LibNormArt in LibNorm_hash:
                
                    
                '''
                aa_hash=[]
                for libNormLUID, libProcessLUID in LibNormID.items():
                    get_artifact_back_path_LibNorm(global_IO_hash,iArtifactLUID, libNormLUID, ProcessID)
                    if len(aa_hash)>0:
                        for oArtifact in aa_hash:
                            if LibNormArt == oArtifact:
                            #LibNormArt=oArtifact
                                if (DEBUG=='1') :
                                   print ("\tLibNorm from aa_hash=",iArtifactLUID,oArtifact,libNormLUID, ProcessID)
                '''    
                sPoolFraction='N/A'
                
                #if len(aa_hash)>0:
                                    
                (libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)=LibNorm_hash[LibNormArt]
                #if DEBUG=='1':
                #    print("LibNorm=>",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                
                if iPool ==1:
                    if sampleID in libNormGenericSample:
                        if DEBUG=='1':
                            print("OK LibNorm",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                        
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        if len(LibNormArtName_NS) >36:
                            LibNormArtName_NS=LibNormArtName_NS[0:30]+"..."
                            
                        
                        sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        if iPrePoolNumberSamplesperPool !=0:
                            sPoolFraction='%.5f' %(float(sPoolFraction)/iPrePoolNumberSamplesperPool)
    
                        
                        if DEBUG=='1':
                            print("TEMP",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                        
                        for prelibArtifactLUID,reagentLabelLibrary,prelibProcessLUID, prelibProcessName in sLibMeta:
                            if reagentLabelLibrary in libNormReagentLabels:
                                reagentLabel=reagentLabelLibrary
                                libArtifactLUID=prelibArtifactLUID
                                libProcessName=prelibProcessName                                
                        
                        
                        
                        #new_index=sampleID+"_"+reagentLabel+"_"+pos#+"_"+LibNormArtLUID_NS   
                        #new_index=reagentLabel+"_"+pos+"_"+LibNormArtLUID_NS
                        
                        #if new_index not in uq_hash:
                        #if LibNormArt == oArtifact:    
                        sTemp += ProcessID+'\t'+projectLUID+'\t'+projectName+'\t'+containerID+'\t'+containerName+'\t'+pos+'\t'+reagentLabel+\
                         '\t'+libArtifactLUID+'\t'+libProcessName+'\t'+LibNormArtLUID_NS+'\t'+LibNormArtName_NS+\
                         '\t'+sampleID+'\t'+submittedSampleName+'\t'+sReference+'\t'+sStartDate+\
                         '\t'+sSampleTag+'\t'+sTargetCells+'\t'+libProcessLUID+'\t'+sSpecies+'\t'+sUDF_GenomeSize_Mb+'\t'+sGender+'\t'+sPoolFraction+\
                         '\t'+sCaptureType+'\t'+sCaptureLUID+'\t'+ sCaptureName+'\t'+sCaptureREF_BED+'\t'+sCaptureMetadataID+'\t'+artLUID+\
                        '\n'
                           
                        
                        #uq_hash[new_index]=1
                        '''
                        try:
                            sPoolFraction=libNormsUDFValue['Lane Fraction']
                            sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        except:
                            pass
                        '''
                else:
                    if sampleID == libNormGenericSample:
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        
                            
            
                
                #   parentProcessLUID

                #sOUT += sTemp
                #+sBaseData
            sBaseData=''
            try:
                submittedLibType=submittedUDFValue['Sample Type']
                '''
                if submittedLibType=='Library Pool':
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''
                '''
                if ('Library' in submittedLibType):
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''              
            except:
                pass
            
            sOUT +=sBaseData +sTemp
            #if iCount>3:
            #    break
            iCount +=1
    except Exception as e: 
        print(e)
        
                
    return sOUT
def create_event_MixLib_file(IlluminaSeq_hash):
    sHeader= 'ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\t'
    sHeader +='SampleLUID\tSampleName\tReference\tStart Date\tSample Tag\tTarget Cells\tLibrary Metadata ID\tSpecies\tUDF/Genome Size (Mb)\tGender\t'
    sHeader +='Pool Fraction\tCapture Type\tCaptureLUID\tCapture Name\tCapture REF_BED\tCapture Metadata ID\tArtifactLUIDClustering\n'
    
    sOUT=sHeader
    global aa_hash,uq_hash
    iCount=0
    uq_hash={}
    try:
        for k in IlluminaSeq_hash:
            sTargetCells="N/A"
            sLibraryMetadataID="N/A"
            #sSpecies="N/A"
            #sUDF_GenomeSize_Mb="N/A"
            #sGender="N/A"
            #sPoolFraction="N/A"
            sCaptureType="N/A"
            sCaptureLUID="N/A"
            sCaptureName="N/A"
            sCaptureREF_BED="N/A"
            sCaptureMetadataID="N/A"
            sArtifactLUIDClustering="N/A"
            sSampleTag="N/A"
            (sampleID,iArtifactLUID)=k.split('x')
            
            (pos,artLUID,artName,reagText,containerID,parentProcessLUID)=IlluminaSeq_hash[k]
            (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[sampleID]
            try:
                sStartDate=get_process_udf('Start Date')
            except:
                sStartDate='N/A'
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
                
                
            projectName=Projects_hash[projectLUID]
            (positioninContainer,containerName)=Container_array[containerID].split('xxx')

                
            
            sLibMeta=get_lib_meta(LibProcesses_artifact_hash, sampleID)
            sLibMeta_local=sLibMeta
            #if DEBUG=='1':
            #    print ("sampleid:\t",str(iCount),sampleID,sLibMeta)            
            for prelibArtifactLUID,reagentLabel,prelibProcessLUID, prelibProcessName in sLibMeta:
                aa_hash=[]
                get_artifact_back_path(global_IO_hash,iArtifactLUID, prelibProcessLUID, ProcessID)
                 
                for iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder in aa_hash:
                    if sampleID in iArtifact :
                       libArtifactLUID=oArtifact
                       libProcessLUID= startProcessLUID
                       libProcessName=processName
                       if DEBUG=='1':
                            print("aa_hash info ",iArtifact,oArtifact,reagentLabel,parentLUID, processLUID, startProcessLUID,processName, iOrder)
                    
                       break

            #(libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)=get_lib_meta(LibProcesses_artifact_hash, sampleID)

            
            #if DEBUG=='1':
            #    print("LibArtifact ==>",libArtifactLUID,iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, libProcessLUID,iOrder)
            
            LibNormArtLUID_NS=''
            LibNormArtName_NS=''
            #
            #  Find  number of samples in the pre Pool
            iPrePoolNumberSamplesperPool=0         
            for i in prePool_hash:
                (arttifactName,containerID,reagentLabels,poolProcessLUID, poolProcessName, poolSamples,sudfValue)=prePool_hash[i]
                if sampleID in poolSamples:
                    iPrePoolNumberSamplesperPool=len(poolSamples)
                    sCaptureType=poolProcessName #"N/A"
                    sCaptureLUID=i
                    sCaptureMetadataID=poolProcessLUID
                    sCaptureName=arttifactName
                    if len(sCaptureName)>36:
                        sCaptureName=sCaptureName[0:30]+"..."
                    
            sTemp =''
            for LibNormArt in LibNorm_hash:
                
                    
                
                aa_hash=[]
                for libNormLUID, libProcessLUID in LibNormID.items():
                    get_artifact_back_path_LibNorm(global_IO_hash,iArtifactLUID, libNormLUID, ProcessID)
                    if len(aa_hash)>0:
                        for iLibNormArtifact,oLibNormArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder in aa_hash:
                            if LibNormArt == oLibNormArtifact:
                            #LibNormArt=oArtifact
                                if (DEBUG=='1') :
                                   print ("\tLibNorm from aa_hash=",iArtifactLUID,oArtifact,libNormLUID, ProcessID)
                    
                sPoolFraction='N/A'
                
                #if len(aa_hash)>0:
                                    
                (libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)=LibNorm_hash[LibNormArt]
                #if DEBUG=='1':
                #    print("LibNorm=>",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                
                if iPool ==1:
                    if sampleID in libNormGenericSample:
                        if DEBUG=='1':
                            print("OK LibNorm",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                        
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        if len(LibNormArtName_NS) >36:
                            LibNormArtName_NS=LibNormArtName_NS[0:30]+"..."
                            
                        
                        sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        if iPrePoolNumberSamplesperPool !=0:
                            sPoolFraction='%.5f' %(float(sPoolFraction)/iPrePoolNumberSamplesperPool)
    
                        
                        if DEBUG=='1':
                            print("TEMP",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                        
                        for prelibArtifactLUID,reagentLabelLibrary,prelibProcessLUID, prelibProcessName in sLibMeta:
                            if reagentLabelLibrary in libNormReagentLabels:
                                reagentLabel=reagentLabelLibrary
                                libArtifactLUID=prelibArtifactLUID
                                libProcessName=prelibProcessName                                
                        
                        
                        
                        #new_index=sampleID+"_"+reagentLabel+"_"+pos#+"_"+LibNormArtLUID_NS   
                        #new_index=reagentLabel+"_"+pos+"_"+LibNormArtLUID_NS
                        
                        #if new_index not in uq_hash:
                        #if LibNormArt == oArtifact:
                        if LibNormArt == oLibNormArtifact:    
                            sTemp += ProcessID+'\t'+projectLUID+'\t'+projectName+'\t'+containerID+'\t'+containerName+'\t'+pos+'\t'+reagentLabel+\
                             '\t'+libArtifactLUID+'\t'+libProcessName+'\t'+LibNormArtLUID_NS+'\t'+LibNormArtName_NS+\
                             '\t'+sampleID+'\t'+submittedSampleName+'\t'+sReference+'\t'+sStartDate+\
                             '\t'+sSampleTag+'\t'+sTargetCells+'\t'+libProcessLUID+'\t'+sSpecies+'\t'+sUDF_GenomeSize_Mb+'\t'+sGender+'\t'+sPoolFraction+\
                             '\t'+sCaptureType+'\t'+sCaptureLUID+'\t'+ sCaptureName+'\t'+sCaptureREF_BED+'\t'+sCaptureMetadataID+'\t'+artLUID+\
                            '\n'
                           
                        
                        #uq_hash[new_index]=1
                        '''
                        try:
                            sPoolFraction=libNormsUDFValue['Lane Fraction']
                            sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        except:
                            pass
                        '''
                else:
                    if sampleID == libNormGenericSample:
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        
                            
            
                
                #   parentProcessLUID

                #sOUT += sTemp
                #+sBaseData
            sBaseData=''
            try:
                submittedLibType=submittedUDFValue['Sample Type']
                '''
                if submittedLibType=='Library Pool':
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''
                '''
                if ('Library' in submittedLibType):
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''              
            except:
                pass
            
            sOUT +=sBaseData +sTemp
            #if iCount>3:
            #    break
            iCount +=1
    except Exception as e: 
        print(e)
        
                
    return sOUT

def create_event_GENERIC_file(IlluminaSeq_hash):
    sHeader= 'ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\t'
    sHeader +='SampleLUID\tSampleName\tReference\tStart Date\tSample Tag\tTarget Cells\tLibrary Metadata ID\tSpecies\tUDF/Genome Size (Mb)\tGender\t'
    sHeader +='Pool Fraction\tCapture Type\tCaptureLUID\tCapture Name\tCapture REF_BED\tCapture Metadata ID\tArtifactLUIDClustering\t'
    sHeader +='Library Size\tLibrary Kit Name\tCapture Kit Type\tCapture Bait Version\n'
    
    sOUT=sHeader
    global aa_hash,uq_hash
    iCount=0
    uq_hash={}
    
    try:
        reagentLabel=''
        libArtifactLUID=''
        libProcessName=''        
        for k in IlluminaSeq_hash:

            sTargetCells="N/A"
            sLibraryMetadataID="N/A"
            #sSpecies="N/A"
            #sUDF_GenomeSize_Mb="N/A"
            #sGender="N/A"
            #sPoolFraction="N/A"
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
            
            
            
            (sampleID,iArtifactLUID)=k.split('x')
            
            (pos,artLUID,artName,reagText,containerID,parentProcessLUID)=IlluminaSeq_hash[k]
            (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[sampleID]
            try:
                sStartDate=get_process_udf('Start Date')
            except:
                sStartDate='N/A'
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
                
                
            projectName=Projects_hash[projectLUID]
            (positioninContainer,containerName)=Container_array[containerID].split('xxx')

                
            
            sLibMeta=get_lib_meta(LibProcesses_artifact_hash, sampleID)
            sLibMeta_local=sLibMeta
            #if DEBUG=='1':
            #    print ("sampleid:\t",str(iCount),sampleID,sLibMeta)    
            '''        
            for prelibArtifactLUID,reagentLabel,prelibProcessLUID, prelibProcessName in sLibMeta:
                aa_hash=[]
                get_artifact_back_path(global_IO_hash,iArtifactLUID, prelibProcessLUID, ProcessID)
                 
                for iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder in aa_hash:
                    if sampleID in iArtifact :
                       libArtifactLUID=oArtifact
                       libProcessLUID= startProcessLUID
                       libProcessName=processName
                       if DEBUG=='1':
                            print("aa_hash info ",iArtifact,oArtifact,reagentLabel,parentLUID, processLUID, startProcessLUID,processName, iOrder)
                    
                       break
            '''
            #(libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)=get_lib_meta(LibProcesses_artifact_hash, sampleID)

            
            #if DEBUG=='1':
            #    print("LibArtifact ==>",libArtifactLUID,iArtifact,oArtifact,parentLUID, processLUID, startProcessLUID,processName, libProcessLUID,iOrder)
            
            LibNormArtLUID_NS=''
            LibNormArtName_NS=''
            #
            #  Find  number of samples in the pre Pool
            iPrePoolNumberSamplesperPool=0         
            for i in prePool_hash:
                (arttifactName,containerID,reagentLabels,poolProcessLUID, poolProcessName, poolSamples,sudfValue)=prePool_hash[i]
                if sampleID in poolSamples:
                    iPrePoolNumberSamplesperPool=len(poolSamples)
                    sCaptureType=poolProcessName #"N/A"
                    sCaptureLUID=i
                    sCaptureMetadataID=poolProcessLUID
                    sCaptureName=arttifactName
                    if len(sCaptureName)>36:
                        sCaptureName=sCaptureName[0:30]+"..."
                    (parentProcessID,ppType,iNode,sudfCaptureValue)=pathProcessLUIDs[poolProcessLUID] 
                    try:
                        sUDF_CaptureKitType=get_udf_value(sudfCaptureValue,'Capture Kit Type')
                    except:
                        sUDF_CaptureKitType='N/A'
                    try:
                        sUDF_CaptureBaitVersion=get_udf_value(sudfCaptureValue,'Capture Bait Version')
                    except:
                        sUDF_CaptureBaitVersion='N/A'
                        
   
                    
            sTemp =''
            for LibNormArt in LibNorm_hash:
                
                    
                
   
                sPoolFraction='N/A'
                
                #if len(aa_hash)>0:
                                    
                (libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)=LibNorm_hash[LibNormArt]
                #if DEBUG=='1':
                #    print("LibNorm=>",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                
                if iPool ==1:
                    if sampleID in libNormGenericSample:
                        if DEBUG=='1':
                            print("OK LibNorm",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                        aa_hash=[]
                        for libNormLUID, libProcessLUID in LibNormID.items():
                            get_artifact_back_path_LibNorm(global_IO_hash,iArtifactLUID, libNormLUID, ProcessID)
                            if len(aa_hash)>0:
                                for iLibNormArtifact,oLibNormArtifact,parentLUID, processLUID, startProcessLUID,processName, iOrder in aa_hash:
                                    if LibNormArt == oLibNormArtifact:
                                    
                                    
                                    
                                        if (DEBUG=='1') :
                                           print ("\tLibNorm from aa_hash=",iLibNormArtifact,oLibNormArtifact,libNormLUID, ProcessID)
                                        break
         
                        
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        if len(LibNormArtName_NS) >36:
                            LibNormArtName_NS=LibNormArtName_NS[0:30]+"..."
                            
                        
                        sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        if iPrePoolNumberSamplesperPool !=0:
                            sPoolFraction='%.5f' %(float(sPoolFraction)/iPrePoolNumberSamplesperPool)
    
                        
                        #if DEBUG=='1':
                        #    print("TEMP",sampleID,LibNormArt,libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)
                        
                        for prelibArtifactLUID,reagentLabelLibrary,prelibProcessLUID, prelibProcessName in sLibMeta:
                            if reagentLabelLibrary in libNormReagentLabels:
                                reagentLabel=reagentLabelLibrary
                                libArtifactLUID=prelibArtifactLUID
                                libProcessName=prelibProcessName    
                                #print (prelibProcessLUID) 
                                (parentProcessID,ppType,iNode,sudfPreLibValue)=pathProcessLUIDs[prelibProcessLUID]                                        
                                    #LibNormArt=oArtifact
                                try:
                                    sUDF_LibraryKitName =get_udf_value(sudfPreLibValue,'Library Kit Name')
                                except:
                                    sUDF_LibraryKitName ='N/A'                        

                                try:
                                    sUDF_LibrarySize =get_udf_value(sudfPreLibValue,'Library Size')
                                except:
                                    sUDF_LibrarySize ='N/A'                            
                        
                        
                        
                        #new_index=sampleID+"_"+reagentLabel+"_"+pos#+"_"+LibNormArtLUID_NS   
                        #new_index=reagentLabel+"_"+pos+"_"+LibNormArtLUID_NS
                        
                        #if new_index not in uq_hash:
                        #if LibNormArt == oArtifact:
                        if DEBUG=='1':
                            print("LibNormArt,oLibNormArtifact",LibNormArt,oLibNormArtifact)
                        if LibNormArt == oLibNormArtifact:    
                            sTemp += ProcessID+'\t'+projectLUID+'\t'+projectName+'\t'+containerID+'\t'+containerName+'\t'+pos+'\t'+reagentLabel+\
                             '\t'+libArtifactLUID+'\t'+libProcessName+'\t'+LibNormArtLUID_NS+'\t'+LibNormArtName_NS+\
                             '\t'+sampleID+'\t'+submittedSampleName+'\t'+sReference+'\t'+sStartDate+\
                             '\t'+sSampleTag+'\t'+sTargetCells+'\t'+libProcessLUID+'\t'+sSpecies+'\t'+sUDF_GenomeSize_Mb+'\t'+sGender+'\t'+sPoolFraction+\
                             '\t'+sCaptureType+'\t'+sCaptureLUID+'\t'+ sCaptureName+'\t'+sCaptureREF_BED+'\t'+sCaptureMetadataID+'\t'+artLUID+\
                             '\t'+sUDF_LibrarySize+'\t'+sUDF_LibraryKitName+'\t'+sUDF_CaptureKitType+'\t'+sUDF_CaptureBaitVersion+\
                            '\n'
                           
                        
                        #uq_hash[new_index]=1
                        '''
                        try:
                            sPoolFraction=libNormsUDFValue['Lane Fraction']
                            sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        except:
                            pass
                        '''
                else:
                    if sampleID == libNormGenericSample:
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        
                            
            
                
                #   parentProcessLUID

                #sOUT += sTemp
                #+sBaseData
            sBaseData=''
            try:
                submittedLibType=submittedUDFValue['Sample Type']
                '''
                if submittedLibType=='Library Pool':
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''
                '''
                if ('Library' in submittedLibType):
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''              
            except:
                pass
            
            sOUT +=sBaseData +sTemp
            #if iCount>3:
            #    break
            iCount +=1
    except Exception as e: 
        print(e)
        
                
    return sOUT



def create_submitted_library_event_file(IlluminaSeq_hash):
    sHeader= 'ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\t'
    sHeader +='SampleLUID\tSampleName\tReference\tStart Date\tSample Tag\tTarget Cells\tLibrary Metadata ID\tSpecies\tUDF/Genome Size (Mb)\tGender\t'
    sHeader +='Pool Fraction\tCapture Type\tCaptureLUID\tCapture Name\tCapture REF_BED\tCapture Metadata ID\tArtifactLUIDClustering\n'
    
    global aa_hash
    sOUT=sHeader
    try:
        for k in IlluminaSeq_hash:
            sTargetCells="N/A"
            sLibraryMetadataID="N/A"
            #sSpecies="N/A"
            #sUDF_GenomeSize_Mb="N/A"
            #sGender="N/A"
            #sPoolFraction="N/A"
            sCaptureType="N/A"
            sCaptureLUID="N/A"
            sCaptureName="N/A"
            sCaptureREF_BED="N/A"
            sCaptureMetadataID="N/A"
            sArtifactLUIDClustering="N/A"
            sSampleTag="N/A"
            (sampleID,iArtifactLUID)=k.split('x')
            (pos,artLUID,artName,reagText,containerID,parentProcessLUID)=IlluminaSeq_hash[k]
            (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[sampleID]
            try:
                sStartDate=get_process_udf('Start Date')
            except:
                sStartDate='N/A'
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
                
                
            projectName=Projects_hash[projectLUID]
            (positioninContainer,containerName)=Container_array[containerID].split('xxx')

            '''
            sLibMeta=get_lib_meta(LibProcesses_artifact_hash, sampleID)
            for libArtifactLUID,reagentLabel,libProcessLUID, libProcessName in sLibMeta:
                aa_hash=[]
                get_artifact_back_path(global_IO_hash,iArtifactLUID, libProcessLUID, ProcessID)
                if len(aa_hash)>0:
                    break
            '''
            
            
            #(libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)=get_lib_meta(LibProcesses_artifact_hash, sampleID)
            (libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)=get_lib_meta_no_Pool(LibProcesses_artifact_hash, sampleID)
            
            
            
            
            
            LibNormArtLUID_NS=''
            LibNormArtName_NS=''
            #
            #  Find  number of samples in the pre Pool
            iPrePoolNumberSamplesperPool=0         
            
            for LibNormArt in LibNorm_hash:
                (libNormArttifactName,libNormContainerID,libNormReagentLabels,libNormParentProcessLUID, libNormParentProcessName, libNormGenericSample,libNormsUDFValue)=LibNorm_hash[LibNormArt]
                sPoolFraction='N/A'
                if iPool ==1:
                    if sampleID in libNormGenericSample:
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                        if len(LibNormArtName_NS) >36:
                            LibNormArtName_NS=LibNormArtName_NS[0:30]+"..."
                            
                        
                        sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        if iPrePoolNumberSamplesperPool !=0:
                            sPoolFraction='%.5f' %(float(sPoolFraction)/iPrePoolNumberSamplesperPool)
    
                        '''
                        try:
                            sPoolFraction=libNormsUDFValue['Lane Fraction']
                            sPoolFraction=get_udf_value(libNormsUDFValue,'Lane Fraction')
                        except:
                            pass
                        '''
                else:
                    if sampleID == libNormGenericSample:
                        LibNormArtLUID_NS=LibNormArt
                        LibNormArtName_NS=libNormArttifactName
                    
                        
            
            sTemp =''   
            sTemp= ProcessID+'\t'+projectLUID+'\t'+projectName+'\t'+containerID+'\t'+containerName+'\t'+pos+'\t'+reagentLabel+\
             '\t'+libArtifactLUID+'\t'+libProcessName+'\t'+LibNormArtLUID_NS+'\t'+LibNormArtName_NS+\
             '\t'+sampleID+'\t'+submittedSampleName+'\t'+sReference+'\t'+sStartDate+\
             '\t'+sSampleTag+'\t'+sTargetCells+'\t'+libProcessLUID+'\t'+sSpecies+'\t'+sUDF_GenomeSize_Mb+'\t'+sGender+'\t'+sPoolFraction+\
             '\t'+sCaptureType+'\t'+sCaptureLUID+'\t'+ sCaptureName+'\t'+sCaptureREF_BED+'\t'+sCaptureMetadataID+'\t'+artLUID+\
            '\n'   
            #sOUT += sTemp
            #+sBaseData
            sBaseData=''
            try:
                submittedLibType=submittedUDFValue['Sample Type']
#                if submittedLibType=='Library Pool':
#                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
#                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
#                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
#                    sTemp=''
                    
                #if (submittedLibType=='Library') or (submittedLibType=='Illumina Library'):
                if ('Library' in submittedLibType):
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,sampleID)
                    sTemp=''                
            except:
                pass
            
            sOUT +=sBaseData +sTemp
    except Exception as e: 
        print(e)
        
                
    return sOUT



def get_lib_meta(LibProcesses_artifact_hash, sampleID):
    #s=('','','','')
    s=[]
    for key in LibProcesses_artifact_hash:
        
        (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue)=LibProcesses_artifact_hash[key]
        
        if (sampleLUID==sampleID) and (sampleLUID in IlluminaAnalysisSamples_hash):
            s.append([key,reagentLabel,libProcessLUID, libProcessName])
            #if DEBUG == "1":
            #    print ("get_lib_meta=",key,sampleID,arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName)
            #break
    if DEBUG == "2":
        print (s)
    return s

def get_lib_meta_no_Pool(LibProcesses_artifact_hash, sampleID):
    s=('','','','')
    #s=[]
    for key in LibProcesses_artifact_hash:
        
        (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue)=LibProcesses_artifact_hash[key]
        if sampleLUID==sampleID:
            #s.append([key,reagentLabel,libProcessLUID, libProcessName])
            s=(key,reagentLabel,libProcessLUID, libProcessName)
            if DEBUG == "1":
                print ("get_lib_meta=",key,sampleID,arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName)
            break
    
    return s


            
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

    

def prepare_artifacts_from_map_io(map_io, IOkey):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in map_io:
        if IOkey=='input':
            iArt=art
        if IOkey=='output':
            iArt=art[art]

        #if '2-' not in iArt:
            #iArt=iArt+"PA1"
        scURI = BASE_URI+'artifacts/'+iArt
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def prepare_artifacts_from_pool_map_io(map_io, IOkey):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in map_io:
        (iArt,oArt)=art.split("_")
        if IOkey=='input':
            iArt=art
        if IOkey=='output':
            iArt=oArt

        #if '2-' not in iArt:
            #iArt=iArt+"PA1"
        scURI = BASE_URI+'artifacts/'+iArt
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 



def get_generic_meta_sample_array(arrXML):
    generic_hash={}
    rDOM = parseString( arrXML )
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        #print (artLUID, artName)
        wellPos=node.getElementsByTagName('location')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        pos=node.getElementsByTagName('value')[0].firstChild.nodeValue
        parentProcessLUID=node.getElementsByTagName( "parent-process" )[0].getAttribute('limsid')
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        
        try:
            reagent=node.getElementsByTagName('reagent-label')[0].getAttribute('name')
            reagentNode=node.getElementsByTagName('reagent-label')
        except:
            reagText="N/A"
            reagentNode=''
        
        sampleNode=node.getElementsByTagName('sample')
        nr=0
        rr=0
        
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        for samples in sampleNode:
            sampleID=samples.getAttribute('limsid')
            new_sampleID=sampleID+"x"+artLUID
            rr=0
            reagText="N/A"
            if len(reagentNode)>0:
                for reagentValue in reagentNode:
                    if rr==nr:
                        reagText=reagentValue.getAttribute('name')
                    rr +=1
                            
            if new_sampleID not in generic_hash:
                generic_hash[new_sampleID]=pos,artLUID,artName,reagText,containerID,parentProcessLUID
            nr+=1
            
        #print (artLUID, artName) 
         
    
    return generic_hash 

def get_generic_artifacts_info(artXML):
    sudfValue={}
    reagentLabels=[]
    genericSamples=[]
    genericArtifact_hash={}

    pDOM = parseString( artXML )
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        artifactLUID=artifact.getAttribute('limsid')
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        reagentLabelNodes=artifact.getElementsByTagName('reagent-label')
        reagentLabel=artifact.getElementsByTagName('reagent-label')[0].getAttribute('name')
        
        for node in reagentLabelNodes:
            if node.getAttribute('name') not in reagentLabels:
                reagentLabels.append(node.getAttribute('name'))
        
        sampleLUIDNodes=artifact.getElementsByTagName('sample')
        sampleLUID=artifact.getElementsByTagName('sample')[0].getAttribute('limsid')
        for sNode in sampleLUIDNodes:
            if sNode.getAttribute('limsid') not in genericSamples:
                genericSamples.append(sNode.getAttribute('limsid'))
                
        
        
        parentProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
        (parentProcessID,parentProcessName,sNode,sUDFValues)=pathProcessLUIDs[parentProcessLUID]
        

        udfNodes= artifact.getElementsByTagName("udf:field")        
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            
        if artifactLUID not in genericArtifact_hash:
            genericArtifact_hash[artifactLUID]= (arttifactName,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue)

        
    #return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue
    return  genericArtifact_hash

def get_multi_artifacts_info(artXML):
    sudfValue={}
    reagentLabels=[]
    multiSamples=[]
    multiArtifact_hash={}

    pDOM = parseString( artXML )
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        sudfValue={}
        reagentLabels=[]
        multiSamples=[]
        
        artifactLUID=artifact.getAttribute('limsid')
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        reagentLabelNodes=artifact.getElementsByTagName('reagent-label')
        #reagentLabel=artifact.getElementsByTagName('reagent-label')[0].getAttribute('name')
        
        for node in reagentLabelNodes:
            if node.getAttribute('name') not in reagentLabels:
                reagentLabels.append(node.getAttribute('name'))
        
        sampleLUIDNodes=artifact.getElementsByTagName('sample')
        #sampleLUID=artifact.getElementsByTagName('sample')[0].getAttribute('limsid')
        for sNode in sampleLUIDNodes:
            if sNode.getAttribute('limsid') not in multiSamples:
                multiSamples.append(sNode.getAttribute('limsid'))
                
        
        
        parentProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
        (parentProcessID,parentProcessName,sNode,sUDFValues)=pathProcessLUIDs[parentProcessLUID]
        

        udfNodes= artifact.getElementsByTagName("udf:field")        
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            
        if artifactLUID not in multiArtifact_hash:
            multiArtifact_hash[artifactLUID]= (arttifactName,containerID,reagentLabels,parentProcessLUID, parentProcessName, multiSamples,sudfValue)

        
    #return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue
    return  multiArtifact_hash
         
    
def get_container_names(Container_array):
    
    for container_ID in Container_array:
        sURI=BASE_URI+'containers/'+container_ID
        r = requests.get(sURI, auth=(user, psw), verify=True)
        rDOM = parseString(r.content )
        node =rDOM.getElementsByTagName('name')
        contName = node[0].firstChild.nodeValue
        contPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
        Container_array[container_ID]=contPosition+'xxx'+contName
    

    return    

def get_base64_to_meta_report(sOUT,sBase64Text,sampleID):
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
                    elif jj ==17:
                        sTemp=sampleID
                                      
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

def get_extra_lib_info(sLibMeta,libNormReagentLabels):
    for c in range(len(sLibMeta)):    
        prelibArtifactLUID,reagentLabelLibrary,prelibProcessLUID, prelibProcessName =sLibMeta[c]
        if reagentLabelLibrary in libNormReagentLabels:
            reagentLabel=reagentLabelLibrary
            libArtifactLUID=prelibArtifactLUID
            libProcessName=prelibProcessName
            sLibMeta.pop( c )  
        else:
            reagentLabel="__"
            libArtifactLUID="__"
            libProcessName="__"                
    
    return reagentLabel,libArtifactLUID,libProcessName

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
    global DEBUG,IlluminaProtocol,global_IO_hash,args, user,psw, parentProcessLUIDs,pathProcessLUIDs, activeStep,Container_array,Samples_hash,LibProcesses_artifact_hash,PoolProcesses_artifact_hash, submittedSamples_hash
    global FileReportLUIDs
    args = setupArguments()
    stepURI_v2=args.stepURI_v2
    user = args.user
    psw = args.psw
    DEBUG=args.debug
    attachLUIDs=args.attachFilesLUIDs
    attachLUIDs=attachLUIDs[:-1]
    FileReportLUIDs=attachLUIDs.split(' ')
    
    
    IlluminaProtocol = args.IlluminaProtocol
    parentProcessLUIDs={}
    pathProcessLUIDs={}
    activeStep=""
    Container_array={}
    Samples_hash={}
    LibProcesses_artifact_hash={}
    PoolProcesses_artifact_hash={}
    global_IO_hash={}
    submittedSamples_hash={}
    global Projects_hash, IlluminaAnalysisSamples_hash
    Projects_hash={}
    IlluminaAnalysisSamples_hash={}
    
    
    setupGlobalsFromURI(stepURI_v2)
    global LibPooling,LibNorm,ClusterGen,Sequencing
    LibPooling,LibNorm,ClusterGen,Sequencing=read_config_file(script_dir+"/protocols.txt")
    #get_parent_process(ProcessID,"")
     

    #ss=get_processID_by_processType(parentProcessLUIDs,'DNA Amplification McGill 1.1')
    #print (ss)
    get_projects_list()
    ss=get_full_parent_process_paths(ProcessID,'',1)
    
    global iLibraryProcesses, iPoolProcesses,LibNormID
    
    iLibraryProcesses=0
    iPoolProcesses=0
    
    for key in pathProcessLUIDs:
        if '151-' in key:
            iLibraryProcesses=1
    for key in pathProcessLUIDs:
        if '122-' in key:
            iPoolProcesses=1
    
    # Find samples in Illumina Analysis process
    map_io_IlluminaAnalysis=get_map_io_by_process(ProcessID, 'ResultFile', 'PerInput')
    #print (map_io_IlluminaAnalysis)
    lXML=prepare_artifacts_batch(map_io_IlluminaAnalysis,'input')
    #print(lXML)
    aXML=retrieve_artifacts(lXML)
        
    #get_meta_sample_array(aXML)
    IlluminaAnalysisSamples_hash=get_generic_sample_list(aXML) 
    
    #for key in IlluminaAnalysisSamples_hash:
    #    print (key,IlluminaAnalysisSamples_hash[key])
    if DEBUG =='1':
        print("Samples:\t"+str(len(IlluminaAnalysisSamples_hash)))
    

    #Library Normalization Robot
    
    '''
    Get all samples info from "Library Normalization (NovaSeq) 1.0 McGill 1.4" step
    
    '''
    if (iLibraryProcesses==1) or (iLibraryProcesses==0):
        #sStep='Library Normalization (NovaSeq) 1.0 McGill 1.4'
        sStep=LibNorm
              
        libNorm_map=get_processID_by_processType(pathProcessLUIDs,sStep) # DNA Samples QC
        LibNormID=libNorm_map
        if DEBUG=='1':
            print ("### LibNomr IDs #######")
            print (libNorm_map)
            print ("### END LibNomr IDs #######")
        
        #sLibNormRobotLUID,sParentLUID
        global map_io_LibNorm,map_io_LibS,map_io_Pools, LibNorm_hash,LibBatch_hash
        LibNorm_hash={}
        LibBatch_hash={}
        #print("\n#### SUBMITED SAMPLES #####")
        for kk in libNorm_map:
            tmp_hash={}
            #print (sStep,kk)
            map_io_LibNorm=get_map_io_by_process(kk, 'Analyte', 'PerInput')
            lXML=prepare_artifacts_batch(map_io_LibNorm,'input')
            #print(lXML)
            aXML=retrieve_artifacts(lXML)
            
                
            get_meta_sample_array(aXML)
            if DEBUG =='1':
                print ( kk,"Samples_hash:\t"+str(len( Samples_hash)))
            
            rsmplXML=prepare_samples_list_for_batch(aXML)
            smplXML=retrieve_samples(rsmplXML)
            #print(smplXML)
            get_submitted_samples_meta(smplXML)
            
            
            # output artifacts for Lib norm NovaSeq step
            # No pooling before LibNorm NovaSeq 
    
    
            outXML=prepare_artifacts_batch(map_io_LibNorm,'output')
            #print(lXML)
            LibNormOutXML=retrieve_artifacts(outXML)
            
            #LibNorm_hash=get_generic_artifacts_info(LibNormOutXML)
            tmp_hash=get_multi_artifacts_info(LibNormOutXML)
            
            LibNorm_hash.update(tmp_hash)
            if DEBUG =='1':
                print("\n#### LibNorm_hash  Library Normalization  #####")
                for key in LibNorm_hash:
                    print (key,LibNorm_hash[key])
                print("\n#### ------------ #####")
        
                print ("LibNorm_hash:\t"+str(len(LibNorm_hash)))    
        #exit()
        if DEBUG =='1':
            for key in submittedSamples_hash:
                print (key,submittedSamples_hash[key])
        #exit()
        DEBUG1=0
        if DEBUG1 ==0:
            for key in pathProcessLUIDs:
                #key=pathProcessLUIDs[k].split(',')[0]
                new_map_io=get_map_io_by_process(key, 'Analyte','PerInput')
                for kk in new_map_io:
                    (iArt,oArt)=kk.split("xxx")
                    #print ("1\t"+kk+","+new_map_io[kk]+","+key+","+pathProcessLUIDs[key])
                    new_key=iArt+"_"+oArt
                    if new_key not in global_IO_hash:
                        global_IO_hash[new_key]=key,pathProcessLUIDs[key]
                    
                #print (key,pathProcessLUIDs[key],new_map_io)    
           
            #print ('\n#####\t Samples\t####')
        if DEBUG1 ==0:
            for key in pathProcessLUIDs:
                new_map_io=get_map_io_by_process(key, 'Sample','PerInput')
                for kk in new_map_io:
                    (iArt,oArt)=kk.split("xxx")
                    #print (kk+","+new_map_io[kk]+","+key+","+pathProcessLUIDs[key])
                    #print (iArt+","+oArt+","+key+","+pathProcessLUIDs[key])
                    new_key=iArt+"_"+oArt
                    if new_key not in global_IO_hash:
                        global_IO_hash[new_key]=key,pathProcessLUIDs[key]
                #print (key,pathProcessLUIDs[key],new_map_io)      
        
            #"PerAllInputs" output-type="Sample"
            for key in pathProcessLUIDs:
                new_map_io=get_map_io_by_process(key, 'Sample','PerAllInputs')
                for kk in new_map_io:
                    (iArt,oArt)=kk.split("xxx")
                    #print (kk+","+new_map_io[kk]+","+key+","+pathProcessLUIDs[key])
                    #print (iArt+","+oArt+","+key+","+pathProcessLUIDs[key])
                    new_key=iArt+"_"+oArt
                    if new_key not in global_IO_hash:
                        global_IO_hash[new_key]=key,pathProcessLUIDs[key]
                #print (key,pathProcessLUIDs[key],new_map_io)    
            
            #print ('\n#####\t ResultFile \t####')
            for key in pathProcessLUIDs:
                new_map_io=get_map_io_by_process(key, 'ResultFile','PerInput')
                for kk in new_map_io:
                    (iArt,oArt)=kk.split("xxx")
                    #print (kk+","+new_map_io[kk]+","+key+","+pathProcessLUIDs[key])
                    #print (iArt+","+oArt+","+key+","+pathProcessLUIDs[key])
                    new_key=iArt+"_"+oArt
                    if new_key not in global_IO_hash:
                        global_IO_hash[new_key]=key,pathProcessLUIDs[key]
                                        
                #print (key,pathProcessLUIDs[key],new_map_io)    
        
            #print ('\n#####\t Pooling \t####')
            for key in pathProcessLUIDs:
                new_map_io=get_map_io_by_process(key, 'Analyte','PerAllInputs')
                for kk in new_map_io:
                    (iArt,oArt)=kk.split("xxx")
                    #print (kk+","+new_map_io[kk]+","+key+","+pathProcessLUIDs[key])
                    #print (iArt+","+oArt+","+key+","+pathProcessLUIDs[key])
                    new_key=iArt+"_"+oArt
                    if new_key not in global_IO_hash:
                        global_IO_hash[new_key]=key,pathProcessLUIDs[key]
                #print (key,pathProcessLUIDs[key],new_map_io)    
            if DEBUG == "1":        
                print ('\n#####\t global IO \t####')
                for ii in sorted(global_IO_hash):
                    print(ii,global_IO_hash[ii]) 
                print ('\n#####\t lastProcessArtifacts_hash \t####')
            
            lastProcessArtifacts_hash,full_lastProcessArtifacts_hash=get_artifacts_from_global_IO(global_IO_hash, Sequencing, '')
            if DEBUG == "1":
                print(lastProcessArtifacts_hash)
                print ('\n#####\t lastProcessArtifacts_hash  full \t####')
                print(full_lastProcessArtifacts_hash)
                
                print ('\n#####\t Lib Batch  \t####')
        libBatchArtifacts_hash,full_LibBatchArtifacts_hash=get_artifacts_from_global_IO(global_IO_hash, 'Library Batch', '')
        if DEBUG == "1":
            print(libBatchArtifacts_hash)
            print ('\n#####\t Lib Batch  full \t####')
            print(full_LibBatchArtifacts_hash)        
    
    
        libPoolArtifacts_hash,full_LibPoolArtifacts_hash=get_artifacts_from_global_IO(global_IO_hash, 'Capture', '')
        if DEBUG == "1":
            print ('\n#####\t Pool Samples \t####')
            print(libPoolArtifacts_hash)
            print ('\n#####\t Pool Samples full \t####')
            print(full_LibPoolArtifacts_hash)   
        pPoolArtsXML=prepare_artifacts_from_pool_map_io(full_LibPoolArtifacts_hash, 'output')
        rPoolArtsXML=retrieve_artifacts(pPoolArtsXML)
        global prePool_hash
        prePool_hash=get_pools_artifacts_info(rPoolArtsXML)  
        if DEBUG == "1":
            print ('\n#####\t Pool Samples \t####')
            print(libPoolArtifacts_hash)
            print ('\n#####\t Pool Samples full \t####')
            print(full_LibPoolArtifacts_hash)              
            print ('\n#####\t pre Pool Samples full HASH \t####')
            for i in prePool_hash:
                (arttifactName,containerID,reagentLabels,poolProcessLUID, poolProcessName, poolSamples,sudfValue)=prePool_hash[i]
                print(i,containerID, str(len(reagentLabels)),poolProcessLUID, poolProcessName,str(len(poolSamples)),sudfValue)
            
    
            
        '''
        lastProcessArtifacts_hash={}
        lastProcessArtifacts_hash=get_artifacts_from_global_IO(global_IO_hash, 'Library Batch', '')
        
        print(lastProcessArtifacts_hash)
        '''
        prepIlluminaSeqArtXML=prepare_artifacts_from_map_io(lastProcessArtifacts_hash, 'input')
        IlluminaSeqXML=retrieve_artifacts(prepIlluminaSeqArtXML)
        
        IlluminaSeq_hash=get_generic_meta_sample_array(IlluminaSeqXML)
        
        get_container_names(Container_array)
            
        if DEBUG==True:
            print ('\n#####\t Illumina Sequencing  \t####')
            for i in IlluminaSeq_hash:
                print(i,IlluminaSeq_hash[i])
            
    
        for jj in pathProcessLUIDs:
            if '122-' in jj:
                #print (jj,pathProcessLUIDs[jj])
                map_io_Pools=get_map_io_by_process(jj, 'Sample', 'PerAllInputs')
                lXML=prepare_artifacts_batch(map_io_Pools,'output')
                #print(lXML)
                aXML=retrieve_artifacts(lXML)
                #LibProcesses_artifact_hash={}
                
                get_pools_artifacts_info(aXML)
                #print (LibProcesses_artifact_hash)            
    
        #for kk in PoolProcesses_artifact_hash:
        #    print (kk,PoolProcesses_artifact_hash[kk])
    
        
        for key in pathProcessLUIDs:
            if '151-' in key:
                #print (key,pathProcessLUIDs[key])
                map_io_LibS=get_map_io_by_process(key, 'Analyte', 'PerInput')
                lXML=prepare_artifacts_batch(map_io_LibS,'output')
                #print(lXML)
                aXML=retrieve_artifacts(lXML)
                #LibProcesses_artifact_hash={}
                get_lib_artifacts_info(aXML)
                #print (LibProcesses_artifact_hash)            
    
        if DEBUG=='1':
            print ('\n#####\t LibProcesses_artifact_hash  \t####')
            for kk in LibProcesses_artifact_hash:
                print (kk,LibProcesses_artifact_hash[kk])
            
        #(libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)=get_lib_meta(LibProcesses_artifact_hash, 'BOU951A97')
        #print (libArtifactLUID,reagentLabel,libProcessLUID, libProcessName)
        
        #get_artifact_back_path(global_IO_hash,artifactLUID, startProcessLUID, stopProcessLUID)
        #get_artifacts_from_global_IO(global_IO_hash, procName, procLUID)
        
        '''
        # TEST for multiple Libraries
        
        hh=get_processID_by_processType(pathProcessLUIDs,LibNorm)
        for LibNormLUID,LibNormParentLUID in hh.items():
            break
        
        #print (LibNorm, ProcessID,LibNormLUID)
        
        '''
        
        
        global aa_hash,libNR_hash
        aa_hash=[]
        libNR_hash=[]
        if DEBUG=='2':
            #get_artifact_back_path(global_IO_hash,'2-425542', '24-58289', ProcessID)
            get_artifact_back_path_LibNorm(global_IO_hash,'2-425702', '24-58296', ProcessID)            
            print ("######### aa test ###########")
            if len(aa_hash)>0:
                for key in aa_hash:
                    print (key)
            else:
                print("not correct path")
                
        
        #exit()
        global iPool
        iPool=1
        if DEBUG == "1":
            print("iLibraryProcesses="+str(iLibraryProcesses))
        if iLibraryProcesses==1:
            #sOUT=create_event_multiLib_file(IlluminaSeq_hash)
            #sOUT=create_event_MixLib_file(IlluminaSeq_hash)
            sOUT=create_event_GENERIC_file(IlluminaSeq_hash)

        if iLibraryProcesses==0:
            sOUT=create_submitted_library_event_file(IlluminaSeq_hash)

        print(sOUT)   
        
        write_event_file(sOUT, sEventPath)
                                 
        #trace_process_hash=get_processID_by_path(pathProcessLUIDs,'Library Normalization Robot','')
    '''
    Start Submitted Library, Library Pooling
    
    '''
        
    
    
         
if __name__ == "__main__":
    main()

