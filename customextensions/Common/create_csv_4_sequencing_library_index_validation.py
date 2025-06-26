'''
Created on August 2, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
    update 2019_01_03:
        - human sorting for destination plate + destination position
    update 2018_08_14:
        - print_plates_info_table added to create mapping table file
        - added  
        
    
Note: 


'''


__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os
import numpy as np

import time
import requests
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
        r = requests.get(sURI, auth=(user, psw), verify=True)
        rDOM = parseString(r.content )
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
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    return r.content

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
    #print("sOUT_split len=",str(len(sOUT_split)))
   
    #print(sBase64_lines)
    
    new_text=""
    ss=""
    #print("length="+str(len(sBase64_lines)))
    sHeader=[]
    try:
        
        for num,line in enumerate(sBase64_lines):
            sTemp_split=sOUT_split
            if num == 0:
                sHeader=line.split("\t")
            else:
                line_split=line.split("\t")
            #print("sBase64_lines len=",str(len(line_split)))
            #print(line,i)
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
                    sTemp_split[7]=sLibProcess                    
                        
    
    
                    sTemp = ','.join(sTemp_split)                    
                    sTemp=sTemp.replace("\n","")
                    ss +=sTemp+"\n"
                    
                    #ss +="\n"
                   
                new_text += ss
    except: #Exception as e:
        pass 
        #print(e)
    
    
    return new_text


'''
    START
'''

def main():
    global DEBUG,args, user,psw,pathProcessLUIDs,LibProcesses_artifact_hash, Container_hash,submittedSamples_hash,IlluminaAnalysisSamples_hash
    args = setupArguments()
    stepURI_v2=args.stepURI_v2
    user = args.user
    psw = args.psw
    DEBUG=args.debug

    
    pathProcessLUIDs={}
    LibProcesses_artifact_hash={}
    Container_hash={}
    submittedSamples_hash={}
    IlluminaAnalysisSamples_hash={}
    
    setupGlobalsFromURI(stepURI_v2)
    
    get_full_parent_process_paths(ProcessID,'',1)
    

    
    '''
    Get all samples info from Kapa, Lucigen etc steps
    
    print ('\n#####\t Library steps \t####')
    
    '''
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
    map_io_NormPool=get_map_io_by_process(ProcessID, 'Analyte', 'PerInput')
    '''
    Info for INPUT
    '''
    prepXML=prepare_artifacts_batch(map_io_NormPool,'input')
    aXML=retrieve_artifacts(prepXML)
    #NormPoolInfo_hash=get_generic_artifacts_info(aXML)
    NormPoolInfo_hash=get_generic_submitted_library_artifacts_info(aXML)
    
    '''
    Submitted samples info
    
    '''
    rsmplXML=prepare_samples_list_for_batch(aXML)
    smplXML=retrieve_samples(rsmplXML)
    get_submitted_samples_meta(smplXML)
    if DEBUG=='1':
        #print ("####### Submitted Samples to retrieve ###############")
        #print (aXML)
        #print (rsmplXML)
        print ("####### Submitted Samples INFO ###############")        
        for key in submittedSamples_hash:

            print (key,submittedSamples_hash[key])
    
    
    
    '''
    Info for OUTPUT
    '''
    prepOXML=prepare_artifacts_batch(map_io_NormPool,'output')
    aOXML=retrieve_artifacts(prepOXML)
    #outputNormPoolInfo_hash=get_generic_artifacts_info(aOXML)
    outputNormPoolInfo_hash=get_generic_submitted_library_artifacts_info(aOXML)
    


    
    get_container_names(Container_hash)
    
    if DEBUG=='1':
        
        print ("####### MAP_IO info ###############")
        for key in map_io_NormPool:
            print (key,map_io_NormPool[key])    
        print ("####### Libraries info ###############")
        for key in LibProcesses_artifact_hash:
            print (key,LibProcesses_artifact_hash[key])    
        
        
        print ("####### INPUT artifacts info ###############")
        for key in NormPoolInfo_hash:
            print (key,NormPoolInfo_hash[key])
            
        print ("####### OUTPUT artifacts info ###############")
        for key in outputNormPoolInfo_hash:
            print (key,outputNormPoolInfo_hash[key])            
        #exit()
    
    
    sHeader="Pool Name,Artifact ID,Pool Cycles,Plate Name,Well,sample,Library ID,Library Type,Index Name,Process ID\n"
    sOUT=sHeader
    for outputArtLUID in outputNormPoolInfo_hash:
        #(arttifactName,artifactLocation,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue, genericSamples, reagentLabels)=NormPoolInfo_hash[key]
        #outputArtLUID=get_artifactLUID_from_io_map(key,map_io_NormPool)
        (o_arttifactName,o_artifactLocation,o_containerID,o_reagentLabel,o_parentProcessLUID, o_parentProcessName, o_sampleLUID,o_sudfValue, o_genericSamples, o_reagentLabels)=outputNormPoolInfo_hash[outputArtLUID]

        containerName=Container_hash[o_containerID]
        #print(key,sudfValue)
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
            #if o_reagentLabel=='SubmittedLibrary':
            #submittedLibType=submittedUDFValue['Sample Type']

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
            except:
                pass
                                      
                #except Exception as e: 
                #    print(e)            
                      
            
            for libKey in LibProcesses_artifact_hash:
                (libArttifactName,libContainerID,libReagentLabel,libProcessLUID, libProcessName, libSampleLUID,libSudfValue)=LibProcesses_artifact_hash[libKey]
                
                #if (sampleLUID==libSampleLUID) and (libReagentLabel==reagentLabel):
                
                if (libSampleLUID == key_sample) and (libReagentLabel in o_reagentLabels):

                

                    #sOUT += sPoolingGroup+','+key+','+sPoolingCycles+','+containerName+','+artifactLocation+','+sampleLUID+','+libKey+','+libProcessName+','+libReagentLabel+','+ProcessID +'\n'
                         
                    sLibArtifact=libKey
                    sLibProcessName=libProcessName
                    sLibReagentLabel=libReagentLabel
                    #sOUT += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+key_sample+','+libKey+','+libProcessName+','+libReagentLabel+','+ProcessID +'\n'
                    sTemp += sPoolingGroup+','+outputArtLUID+','+sPoolingCycles+','+containerName+','+o_artifactLocation+','+key_sample+','+sLibArtifact+','+sLibProcessName+','+sLibReagentLabel+','+ProcessID +'\n'
                    #print (sPoolingGroup+','+key+','+sPoolingCycles+','+containerName+','+artifactLocation+','+sampleLUID+','+libKey+','+libProcessName+','+libReagentLabel+','+ProcessID)
                    #if DEBUG=='1':

            
        sOUT +=sBaseData +sTemp      
    
    print (sOUT)
    
    
    
    
    
    
         
if __name__ == "__main__":
    main()


