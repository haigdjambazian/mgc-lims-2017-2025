'''
Created on August 2, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
    aka - *_dd.py
    update 2020_01_16:
        - for submitted libs updated 'Samples name' and 'LibID' values
    update 2019_11_14:
        - fixed old library names
        - fixed issue with corrected indexes after Library prep step has been completed
        - tested complex samples paths - capture, replicas, pooling and submitted libraries 
    update 2019_01_03:
        - human sorting for destination plate + destination position
    update 2018_08_14:
        - print_plates_info_table added to create mapping table file
        - added  
        
    

Note:

python_version=3.5
 
'''
script_version="2020_01_16"


__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, sys
sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
import glsapiutil3x
import numpy as np

import time

import re, xml
from xml.dom.minidom import parseString
import base64




  

user=''
psw=''
#BASE_URI='https://bravotestapp.genome.mcgill.ca/api/v2/'
script_dir=os.path.dirname(os.path.realpath(__file__))
HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False
QC_status={'PASS':"PASSED", 'FAIL':"FAILED"}

def setupArguments():
    parser = argparse.ArgumentParser(description='Calculate normalized Concentration values per sample')
    parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
    parser.add_argument('-user',default='', help='API user')
    parser.add_argument('-psw',default='', help='API password')
    parser.add_argument('-ar',default='r', help='Analyte or ResultFile ')
    parser.add_argument('-ComponentLuids',default='', help='LUIDs for the generated files ') 
    parser.add_argument('-debug',default='', help='option for debugging')   
 
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


def get_full_parent_process_paths(processID,parentProcessID,kNode):
    global iNode
    iNode=kNode
    sURI=BASE_URI+'processes/'+processID
    r=api.GET(sURI)
    rDOM = parseString( r )
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
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in pathProcessLUIDs:
            get_full_parent_process_paths(pProcessLUID,processID,iNode)

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
        #print(udfName,key.firstChild.nodeValue)
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
    #print(pURI)
    pXML= api.GET(pURI)
    
    pDOM = parseString( pXML)

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
        if IOkey=='output' :
            iArt=art.split('xxx')[1]
            

        #if '2-' not in iArt:
            #iArt=iArt+"PA1"
        if ('92-' not in art):    
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
    headers = {'Content-Type': 'application/xml'}
    r = api.POST(sXML, sURI)
   
    return r  

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
    return 

def get_generic_artifacts_info(artXML):
    sudfValue={}
    reagentLabels=[]
    genericSamples=[]
    genericArtifact_hash={}

    pDOM = parseString( artXML )
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        reagentLabels=[]
        genericSamples=[]
        artifactLUID=artifact.getAttribute('limsid')
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        if containerID not in Container_hash:
            Container_hash[containerID]="yyy"
        
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
        sudfValue={}       
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            
        if artifactLUID not in genericArtifact_hash:
            #print (arttifactName,artifactLocation,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue)
            genericArtifact_hash[artifactLUID]= (arttifactName,artifactLocation,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue,genericSamples,reagentLabels)

        
    #return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue
    return  genericArtifact_hash


def get_generic_submitted_library_artifacts_info(artXML):
    sudfValue={}
    reagentLabels=[]
    genericSamples=[]
    genericArtifact_hash={}

    pDOM = parseString( artXML )
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        reagentLabels=[]
        genericSamples=[]
        artifactLUID=artifact.getAttribute('limsid')
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        if containerID not in Container_hash:
            Container_hash[containerID]="yyy"
        
        reagentLabelNodes=artifact.getElementsByTagName('reagent-label')
        if len(reagentLabelNodes)>0:
            reagentLabel=artifact.getElementsByTagName('reagent-label')[0].getAttribute('name')
            
            for node in reagentLabelNodes:
                if node.getAttribute('name') not in reagentLabels:
                    reagentLabels.append(node.getAttribute('name'))
        else:
            reagentLabel="SubmittedLibrary"
            reagentLabels.append("SubmittedLibrary")
            
        
        sampleLUIDNodes=artifact.getElementsByTagName('sample')
        sampleLUID=artifact.getElementsByTagName('sample')[0].getAttribute('limsid')
        for sNode in sampleLUIDNodes:
            if sNode.getAttribute('limsid') not in genericSamples:
                genericSamples.append(sNode.getAttribute('limsid'))
                
        
        try:
            parentProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
            (parentProcessID,parentProcessName,sNode,sUDFValues)=pathProcessLUIDs[parentProcessLUID]
        except:
            parentProcessLUID="N/A"
            parentProcessName="SubmittedLibrary"
            
            
        

        udfNodes= artifact.getElementsByTagName("udf:field") 
        sudfValue={}       
        for key in udfNodes:
            udfName = key.getAttribute( "name")
            #print(udfName,key.firstChild.nodeValue)
            sudfValue[udfName]=str(key.firstChild.nodeValue)
            
        if artifactLUID not in genericArtifact_hash:
            #print (arttifactName,artifactLocation,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue)
            genericArtifact_hash[artifactLUID]= (arttifactName,artifactLocation,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue,genericSamples,reagentLabels)

        
    #return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue
    return  genericArtifact_hash




def get_container_names(Container_hash):
    
    for container_ID in Container_hash:
        sURI=BASE_URI+'containers/'+container_ID
        r = api.GET(sURI)
        rDOM = parseString(r)
        node =rDOM.getElementsByTagName('name')
        contName = node[0].firstChild.nodeValue
        contPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
        Container_hash[container_ID]=contName
    return

def get_artifactLUID_from_io_map(inputLUID,map_io_NormPool):
    
    for key in map_io_NormPool:
        (inputArtLUID,outputArtLUID)=key.split('xxx')
        if inputLUID==inputArtLUID:
            return outputArtLUID

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
    #nodes = pDOM.getElementsByTagName( "sample" )
    for node in pDOM.getElementsByTagName( "sample" ):
        sampleURI=node.getAttribute("uri")
        sampleID=node.getAttribute("limsid")
        #if sampleID in IlluminaAnalysisSamples_hash:
        lXML.append( '<link uri="' + sampleURI + '" rel="samples"/>' )  

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML     

def retrieve_samples(sXML):
    sURI=BASE_URI+'samples/batch/retrieve'
    headers = {'Content-Type': 'application/xml'}
    r = api.POST(sXML, sURI)
    return r

def get_base64_to_meta_report(sOUT,sBase64Text,sampleID):
    sOUT_split=sOUT.split(",")
    sBase64_lines=sBase64Text.split("\n")
    print("sOUT_split len=",str(len(sOUT_split)))
   
    #print(sBase64_lines)
    i=0
    new_text=""
    ss=""
    #print("length="+str(len(sBase64_lines)))
    try:
        for line in sBase64_lines:
            line_split=line.split("\t")
            print("sBase64_lines len=",str(len(line_split)))
            print(line,i)
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

def get_base64_for_libNorm(sOUT,sBase64Text,sampleID):
    sOUT_split=sOUT.split(",")
    sBase64_lines=sBase64Text.split("\n")
    
    new_text=""
    ss=""

    sHeader=[]
    try:
        
        for num,line in enumerate(sBase64_lines):
            sTemp_split=sOUT_split
            if num == 0:
                sHeader=line.split("\t")
            else:
                line_split=line.split("\t")
                if num !=0:
                    ss=""
                    iIndex=sHeader.index('Index')
                    sSubIndex=line_split[iIndex]
                    if sSubIndex: 
                        sTemp_split[8]=sSubIndex
                    else:
                        sTemp_split[8]="N/A"
                    
                    iLibProcess=sHeader.index('LibraryProcess')
                    sLibProcess=line_split[iLibProcess]
                    sTemp_split[7]=sLibProcess

                    iSmplName=sHeader.index('SampleName')
                    sSmplName=line_split[iSmplName]
                    sTemp_split[5]=sSmplName

                    iLibID=sHeader.index('LibraryLUID')
                    sLibID=line_split[iLibID]
                    if sLibID == 'N/A':
                        sTemp_split[6]=sampleID+"-"+str(num)
                        
                    sTemp = ','.join(sTemp_split)                    
                    sTemp=sTemp.replace("\n","")
                    ss +=sTemp+"\n"
                   
                new_text += ss
    except: #Exception as e:
        pass 
        #print(e)
    return new_text




def find_process_artifacts(map_io, processID):
    uq_hash={}
    
    for key in map_io:
        inputArtifact, outputArtifact=key.split("xxx")
        parentProcessID=map_io[key]
        if parentProcessID==processID:
            (ppID,ppType,iNode,sudfValue) = pathProcessLUIDs[parentProcessID]
            new_key=inputArtifact+"xxx"+outputArtifact
            if inputArtifact not in uq_hash:
                uq_hash[new_key]=(ppID,ppType,iNode,sudfValue)
                if DEBUG:
                    print("Done",inputArtifact, outputArtifact,parentProcessID, ppType)
            
        #find_process_artifacts(map_io, processID)                
    return uq_hash

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

def get_generic_sample_list(arrXML):
    arr_temp={}

    rDOM = parseString( arrXML )
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        try:
            parentProcessLUID=node.getElementsByTagName("parent-process")[0].getAttribute('limsid')
        except:
            parentProcessLUID=artLUID
        wellPos=node.getElementsByTagName('location')
        try:
            containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        except:
            print(artLUID,artName)
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

def find_lib_artifact_chain_from_last(map_io,artifactLUID,upStepLUID):
    global i
    i=0

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
                new_key=rootSample+"_"+outputArtifact+"_"+globalArtifact
                res = [i for i in IlluminaSequenceSamples if rootSample in i]
                if len(res)>0:
                    
                    artifacts_info[new_key]=globalArtifact,parentProcessID,pathProcessLUIDs[parentProcessID]
                    if DEBUG:
                        print("Done artifacts_info",i,globalArtifact,inputArtifact,outputArtifact,parentProcessID)
                    i+=1
                #break
            
            find_lib_artifact_chain_from_last(map_io,inputArtifact,upStepLUID)
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

def get_csv_report():
    sHeader="Pool Name,Artifact ID,Pool Cycles,Plate Name,Well,sample,Library ID,Library Type,Index Name,Process ID\n"
    sOUT=sHeader
    kk=0
    for outputArtLUID in outputNormPoolInfo_hash:
        try:
            (o_arttifactName,o_artifactLocation,o_containerID,o_reagentLabel,o_parentProcessLUID, o_parentProcessName, o_sampleLUID,o_sudfValue, o_genericSamples, o_reagentLabels)=outputNormPoolInfo_hash[outputArtLUID]
            print(outputArtLUID,o_arttifactName,o_artifactLocation,o_containerID,o_reagentLabel,o_parentProcessLUID, o_parentProcessName, o_sampleLUID, o_genericSamples, o_reagentLabels)
    
            containerName=Container_hash[o_containerID]
            sPoolingCycles='8-8'
            sPoolingGroup='N/A'
            sLibArtifact='N/A'
            sLibProcessName='N/A'
            sLibReagentLabel='N/A'
            try:
                sPoolingGroup=o_sudfValue['Pooling Group']
            except:
                pass
            try:
                sPoolingCycles=o_sudfValue['Index Cycles']
            except:
                pass        
                         
            sTemp=''
            for num, key_sample in enumerate(o_genericSamples):
            
                #print (num, key_sample )
                (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[key_sample]  
                sBaseData=''
                try:
                    submittedLibType=submittedUDFValue['Sample Type']
                    
                    if ('Library' in submittedLibType):
                        sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+key_sample+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                        
                        sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                        sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                        #sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,o_sampleLUID)
                        sBaseData=get_base64_for_libNorm(sTemp,sBase64Text,o_sampleLUID)
                        
                        #print ('sTemp, BaseData',sTemp,sBaseData)
                        sTemp=''
                        print(str(kk)+"\t base64")
                except:
                    pass
                                          
                    #except Exception as e: 
                    #    print(e)            
                          
                
                for libKey in LibProcesses_artifact_hash:
                    (libArttifactName,libContainerID,libReagentLabel,libProcessLUID, libProcessName, libSampleLUID,libSudfValue)=LibProcesses_artifact_hash[libKey]
                    
                    
                   
                    if (libSampleLUID == key_sample) and (libReagentLabel in o_reagentLabels):
                             
                        sLibArtifact=libKey
                        sLibProcessName=libProcessName
                        sLibReagentLabel=libReagentLabel
                        #print(str(kk)+"\t Library\t"+slibProcessName)
                        if libProcessName=="Add Multiple Reagents":
                    
                            oldLibArt=oldLib_io[libKey]
                            oldLib_kk=libSampleLUID+"_"+oldLibArt
                            oldlibPos, oldlibArtLUID, oldlibSampleName, oldlibIndex, oldlibContainerLUID, oldlibProcessLUID, oldlibrarySamplesUDFs=oldlibrarySamples[oldLib_kk]
                            
                            (oldppID,oldProcessName,oldiNode,oldsudfValue)=pathProcessLUIDs[oldlibProcessLUID]
                            
                            sLibArtifact=oldlibArtLUID
                            slibProcessName=oldProcessName
                            #print (submittedSampleName,libSampleLUID,slibProcessName)
                            #print(str(kk)+"\t Add reagent\t"+slibProcessName)


                            
                            #libProcessLUID=oldlibProcessLUID
                        
                        #sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+key_sample+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                        
                        sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+submittedSampleName+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                        print("\t"+str(kk)+"\t"+sTemp)
                        kk +=1
        except Exception as e:
            print ("Error:\t"+str(e))
                    
    

            
        sOUT +=sBaseData +sTemp 
             
    return sOUT

def get_new_csv_report():
    global art_hash
    sHeader="Pool Name,Artifact ID,Pool Cycles,Plate Name,Well,sample,Library ID,Library Type,Index Name,Process ID\n"
    sOUT=sHeader
    kk=0
    if DEBUG:
        print("\n############## csv report #############")
    sBaseData=''
    sTemp=''
    for outputArtLUID in outputNormPoolInfo_hash:
    #for key in IlluminaSequenceSamples:
    #    o_sampleLUID,outputArtLUID=key.split("_")
        try:
            (o_arttifactName,o_artifactLocation,o_containerID,o_reagentLabel,o_parentProcessLUID, o_parentProcessName, o_sampleLUID,o_sudfValue, o_genericSamples, o_reagentLabels)=outputNormPoolInfo_hash[outputArtLUID]
            #(o_artifactLocation,artLUID,o_arttifactName,o_reagentLabel,o_containerID,o_parentProcessLUID,o_sudfValue)=IlluminaSequenceSamples[key]
        except Exception as e:
            print ("Error 1:\t"+str(e)+"\t"+outputArtLUID)
        try:                
            containerName=Container_hash[o_containerID]
            sPoolingCycles='8-8'
            sPoolingGroup='N/A'
            sLibArtifact='N/A'
            sLibProcessName='N/A'
            sLibReagentLabel='N/A'
            try:
                sPoolingGroup=o_sudfValue['Pooling Group']
            except:
                pass
            try:
                sPoolingCycles=o_sudfValue['Index Cycles']
            except:
                pass        
            
            if DEBUG:
                print("LNorm",sPoolingGroup,outputArtLUID,o_sampleLUID,sPoolingCycles,containerName,o_artifactLocation,o_genericSamples,o_reagentLabels)        
            sTemp=''
            for num, key_sample in enumerate(o_genericSamples):
                (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[key_sample]  
                sBaseData=''
                try:
                    submittedLibType=submittedUDFValue['Sample Type']
                    
                    if ('Library' in submittedLibType):
                        sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+key_sample+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                        
                        sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                        sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                        #sBaseData=get_base64_to_meta_report(sTemp,sBase64Text,o_sampleLUID)
                        sBaseData=get_base64_for_libNorm(sTemp,sBase64Text,o_sampleLUID)
                        sTemp=''
                except:
                    pass
                
                for libKey in LibProcesses_artifact_hash:
                    (libArttifactName,libContainerID,libReagentLabel,libProcessLUID, libProcessName, libSampleLUID,libSudfValue)=LibProcesses_artifact_hash[libKey]
                    if libSampleLUID==o_sampleLUID:
                        art_hash={}
                        get_artifact_idx_from_to(map_io,outputArtLUID,libProcessLUID,outputArtLUID)
                        
                        if DEBUG and len(art_hash)>0:
                            print("\tart_hash\t"+libKey+"\t"+libSampleLUID+"\t"+o_sampleLUID,art_hash)
                        for key in art_hash:
                            upSampleID,upArtifactLUID,illSeqArtLUID=key.split('_')
                            if (libKey==upArtifactLUID) and (upSampleID==o_sampleLUID): 
                                sLibArtifact=libKey
                                sLibProcessName=libProcessName
                                sLibReagentLabel=libReagentLabel
                                if libProcessName=="Add Multiple Reagents":
                                    oldLibArt=oldLib_io[libKey]
                                    oldLib_kk=libSampleLUID+"_"+oldLibArt
                                    oldlibPos, oldlibArtLUID, oldlibSampleName, oldlibIndex, oldlibContainerLUID, oldlibProcessLUID, oldlibrarySamplesUDFs=oldlibrarySamples[oldLib_kk]
                                    (oldppID,oldProcessName,oldiNode,oldsudfValue)=pathProcessLUIDs[oldlibProcessLUID]
        
                                    sLibArtifact=oldlibArtLUID
                                    sLibProcessName=oldProcessName
                                sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+submittedSampleName+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                                if DEBUG:
                                    print(str(kk)+"\t"+sTemp)
                                    kk +=1

        except Exception as e:
            if DEBUG:
                print ("Error 2:\t"+str(e)+"\t"+outputArtLUID)
        sOUT +=sBaseData +sTemp
         
    return sOUT

def get_generic_csv_report():
    global art_hash
    sHeader="Pool Name,Artifact ID,Pool Cycles,Plate Name,Well,sample,Library ID,Library Type,Index Name,Process ID\n"
    sOUT=sHeader
    kk=0
    if DEBUG:
        print("\n############## csv report #############")
    sBaseData=''
    sTemp=''
    for key in IlluminaSequenceSamples:
        o_sampleLUID,outputArtLUID=key.split("_")
        try:
            (o_artifactLocation,artLUID,o_arttifactName,o_reagentLabel,o_containerID,o_parentProcessLUID,o_sudfValue)=IlluminaSequenceSamples[key]
        except Exception as e:
            print ("Error 1:\t"+str(e)+"\t"+outputArtLUID)
        try:                
            containerName=Container_hash[o_containerID]
            sPoolingCycles='8-8'
            sPoolingGroup='N/A'
            sLibArtifact='N/A'
            sLibProcessName='N/A'
            sLibReagentLabel='N/A'
            try:
                sPoolingGroup=o_sudfValue['Pooling Group']
            except:
                pass
            try:
                sPoolingCycles=o_sudfValue['Index Cycles']
            except:
                pass        
            
            if DEBUG:
                print("LNorm",sPoolingGroup,outputArtLUID,o_sampleLUID,sPoolingCycles,containerName,o_artifactLocation,o_reagentLabel)
            sTemp=''
            key_sample=o_sampleLUID
            (submittedSampleName,projectLUID,submittedUDFValue)=submittedSamples_hash[key_sample]  
            sBaseData=''
            try:
                submittedLibType=submittedUDFValue['Sample Type']
                
                if ('Library' in submittedLibType):
                    sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+key_sample+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                    
                    sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
                    sBase64Text=base64.b64decode(sBase64).decode('utf-8')+'\n'
                    sBaseData=get_base64_for_libNorm(sTemp,sBase64Text,o_sampleLUID)
                    
                    sTemp=''
            except:
                pass
            
            for libKey in LibProcesses_artifact_hash:
                (libArttifactName,libContainerID,libReagentLabel,libProcessLUID, libProcessName, libSampleLUID,libSudfValue)=LibProcesses_artifact_hash[libKey]
                if libSampleLUID==o_sampleLUID:
                    art_hash={}
                    get_artifact_idx_from_to(map_io,outputArtLUID,libProcessLUID,outputArtLUID)
                    
                    if DEBUG and len(art_hash)>0:
                        print("\tart_hash\t"+libKey+"\t"+libSampleLUID+"\t"+o_sampleLUID+"\t"+libProcessName,art_hash)
                    for key in art_hash:
                        upSampleID,upArtifactLUID,illSeqArtLUID=key.split('_')
                        if (libKey==upArtifactLUID) and (upSampleID==o_sampleLUID): 
                            sLibArtifact=libKey
                            sLibProcessName=libProcessName
                            sLibReagentLabel=libReagentLabel
                            if libProcessName=="Add Multiple Reagents":
                                try:
                                    oldLibArt=oldLib_io[libKey]
                                except Exception as e:
                                    print(e)
                                    print(libKey,oldLib_io)
                                    sys.exit(111)
                                    
                                oldLib_kk=libSampleLUID+"_"+oldLibArt
                                oldlibPos, oldlibArtLUID, oldlibSampleName, oldlibIndex, oldlibContainerLUID, oldlibProcessLUID, oldlibrarySamplesUDFs=oldlibrarySamples[oldLib_kk]
                                (oldppID,oldProcessName,oldiNode,oldsudfValue)=pathProcessLUIDs[oldlibProcessLUID]
    
                                sLibArtifact=oldlibArtLUID
                                sLibProcessName=oldProcessName
                                if DEBUG:
                                    print("\t\tAdd Multiple Reagents",libSampleLUID+"\t"+oldLibArt+"\t"+oldProcessName)                                
                            sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+submittedSampleName+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                            if DEBUG:
                                print(str(kk)+"\t"+sTemp)
                                kk +=1

        except Exception as e:
            if DEBUG:
                print ("Error 2:\t"+str(e)+"\t"+outputArtLUID)
        sOUT +=sBaseData +sTemp
         
    return sOUT



def get_artifact_idx_from_to(map_io,artifactLUID,upStepLUID, masterArtifact):
    global i,art_hash
    for key in map_io:
        inputArtifact, outputArtifact=key.split("xxx")
        parentProcessID=map_io[key]
        if outputArtifact==artifactLUID:
            (ppID,ppType,iNode,sudfValue) = pathProcessLUIDs[parentProcessID]
            
            if parentProcessID==upStepLUID:
                if "PA1" not in inputArtifact:
                    rootSample=get_artifact_meta(inputArtifact)
                else:
                    rootSample=inputArtifact.replace("PA1","")
                new_key=rootSample+"_"+outputArtifact+"_"+masterArtifact
                res = [i for i in IlluminaSequenceSamples if rootSample in i]
                if len(res)>0:
                    
                    art_hash[new_key]=masterArtifact,parentProcessID
                    if DEBUG==2:
                        print("Done",i,masterArtifact,inputArtifact,outputArtifact,parentProcessID,art_hash[new_key])
                    i+=1
            get_artifact_idx_from_to(map_io,inputArtifact,upStepLUID,masterArtifact)
    return


'''
    START
'''

def main():
    global api,DEBUG,args, user,psw,pathProcessLUIDs,LibProcesses_artifact_hash, Container_hash,\
    submittedSamples_hash,IlluminaAnalysisSamples_hash, oldLibraries, oldLib_hash, map_io,\
    globalArtifact,IlluminaSequenceSamples,Container_array, artifacts_info,art_hash
    args = setupArguments()
    stepURI_v2=args.stepURI_v2
    user = args.user
    psw = args.psw
    dbg=args.debug
    DEBUG=False
    if dbg =='1':
        DEBUG=True
    
    api = glsapiutil3x.glsapiutil3()
    api.setURI( args.stepURI_v2)
    api.setup( args.user, args.psw ) 

    
    pathProcessLUIDs={}
    LibProcesses_artifact_hash={}
    Container_hash={}
    Container_array={}
    submittedSamples_hash={}
    IlluminaAnalysisSamples_hash={}
    oldLibraries=["Lucigen AmpFREE Low DNA 1.0","Kapa Hyper Plus"]
    oldLib_hash={}
    map_io={} 
    artifacts_info={}   
    
    setupGlobalsFromURI(stepURI_v2)
    
    #get_full_parent_process_paths(ProcessID,'',1)
    get_full_parent_artifact_paths(ProcessID,'',1)
    
    uq_hash=find_process_artifacts(map_io, ProcessID)

    batchXML=prepare_artifacts_batch(uq_hash,'output')
    rXML=retrieve_artifacts(batchXML)

    
    IlluminaSequenceSamples=get_generic_sample_list(rXML)    

    '''
    start process old LIb steps 
    '''
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
            oldLibArt,libNormOutArt=key.split("xxx")
            find_lib_artifact_chain_from_last(map_io,oldLibArt,oldlibID)
    
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

    '''
    STOP old lIbs
    '''

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

        
    for key in pathProcessLUIDs:
        if '151-' in key:
            map_io_LibS=get_map_io_by_process(key, 'Analyte', 'PerInput')
            lXML=prepare_artifacts_batch(map_io_LibS,'output')
            aXML=retrieve_artifacts(lXML)
            get_lib_artifacts_info(aXML)
                       
    '''
    LIB samples
    
    '''
    map_io_NormPool=get_map_io_by_process(ProcessID, 'Analyte', 'PerInput')
    '''
    Info for INPUT
    '''
    prepXML=prepare_artifacts_batch(map_io_NormPool,'input')
    aXML=retrieve_artifacts(prepXML)
    NormPoolInfo_hash=get_generic_submitted_library_artifacts_info(aXML)
    
    '''
    Submitted samples info
    
    '''
    rsmplXML=prepare_samples_list_for_batch(aXML)
    smplXML=retrieve_samples(rsmplXML)
    get_submitted_samples_meta(smplXML)
    if DEBUG=='1':
        print ("####### Submitted Samples INFO ###############")        
        for key in submittedSamples_hash:

            print (key,submittedSamples_hash[key])
    
    
    
    '''
    Info for OUTPUT
    '''
    prepOXML=prepare_artifacts_batch(map_io_NormPool,'output')
    aOXML=retrieve_artifacts(prepOXML)

    global outputNormPoolInfo_hash
    outputNormPoolInfo_hash=get_generic_submitted_library_artifacts_info(aOXML)
    
    get_container_names(Container_hash)
    
    if DEBUG:
        
        print ("####### MAP_IO info ###############")
        for key in map_io_NormPool:
            print (key,map_io_NormPool[key])    
        print ("####### Libraries info ###############")
        for key in LibProcesses_artifact_hash:
            print (key,LibProcesses_artifact_hash[key])    

        print ("####### First step samples info ###############")
        for key in IlluminaSequenceSamples:
            print(key, IlluminaSequenceSamples[key])
        
        print ("\n####### output ###############\n")        
        
        print ("####### INPUT artifacts info ###############")
        for key in NormPoolInfo_hash:
            print (key,NormPoolInfo_hash[key])
            
        print ("####### OUTPUT artifacts info ###############")
        for key in outputNormPoolInfo_hash:
            print (key,"\n",outputNormPoolInfo_hash[key])            

    
        print(uq_hash)
        print ("\n####### OLD Libraries info ###############")
        for key in oldLibraryArtifacts_hash:
            print (key) 
        print ("####### Libraries info ###############")
        for key in LibraryArtifacts_hash:
            print(key)
        
        print ("\n####### output ###############\n")
    
    sOUT=get_generic_csv_report()
    print (sOUT)

         
if __name__ == "__main__":
    main()


