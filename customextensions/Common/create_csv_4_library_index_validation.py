'''
Created on August 2, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
    update 2019_08_23:
        - fix for the "ghost" appearance when sample didn't pass QC and re-run again  
    update 2019_01_03:
        - human sorting for destination plate + destination position
    update 2018_08_14:
        - print_plates_info_table added to create mapping table file
        - added  
        
    
Note: 


'''


__author__ = 'Alexander Mazur'


import os,sys, argparse, shutil, logging, math
sys.path.append('/opt/gls/clarity/customextensions/Common')
import glsapiutil3x
import numpy as np

import time
import requests
import re, xml
from xml.dom.minidom import parseString




  

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
            genericArtifact_hash[artifactLUID]= (arttifactName,artifactLocation,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue)

        
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

def find_artifact_chain_from_last(map_io,artifactLUID,upStepLUID):
    global i
    
    i=0
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
                if DEBUG=='1':
                    print("Done",i,globalArtifact,inputArtifact,outputArtifact,parentProcessID,pathProcessLUIDs[parentProcessID])
                i+=1
                #break
            
            find_artifact_chain_from_last(map_io,inputArtifact,upStepLUID)

def get_full_parent_artifact_paths(processID,parentProcessID,kNode):
    global iNode
    artifactType="Analyte"

    iNode=kNode
    sURI=BASE_URI+'processes/'+processID
    
    #r = requests.get(sURI, auth=(user, psw), verify=True)
    r=api.GET(sURI)
    rDOM = parseString( r)
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
        
def isInArtifactChain(artifactschain, artLibLUID):
    iStatus=0
    for key in artifactschain:
        inArtifact,outArtifact=key.split("_")
        if outArtifact == artLibLUID:
            iStatus=1
                
    return iStatus




'''
    START
'''

def main():
    global api,globalArtifact,DEBUG,args, user,psw,pathProcessLUIDs,LibProcesses_artifact_hash, Container_hash, map_io
    args = setupArguments()
    stepURI_v2=args.stepURI_v2
    user = args.user
    psw = args.psw
    DEBUG=args.debug
    api = glsapiutil3x.glsapiutil3()
    api.setURI( args.stepURI_v2 )
    api.setup( args.user, args.psw ) 

    
    pathProcessLUIDs={}
    LibProcesses_artifact_hash={}
    Container_hash={}
    map_io={}
    
    setupGlobalsFromURI(stepURI_v2)
    
    #get_full_parent_process_paths(ProcessID,'',1)
    get_full_parent_artifact_paths(ProcessID,'',1)
    if DEBUG=='1':
        for num, key in enumerate(pathProcessLUIDs): 
            parentProcessID,ppType, iNode,sudfValue=pathProcessLUIDs[key]
            print (parentProcessID,ppType,str(iNode))
    
        for num, key in enumerate(map_io):
            print (num, key,map_io[key])
    
    
    
    
    
    

    #exit()
    

    
    '''
    Get all samples info from Kapa, Lucigen etc steps
    
    print ('\n#####\t Library steps \t####')
    
    '''
    global uqLib_hash, artifacts_info
    uqLib_hash=[]
    artifacts_info={}
    for key in pathProcessLUIDs:
        if '151-' in key:
            #print (key,pathProcessLUIDs[key])
            map_io_LibS=get_map_io_by_process(key, 'Analyte', 'PerInput')
            lXML=prepare_artifacts_batch(map_io_LibS,'output')
            #print(lXML)
            aXML=retrieve_artifacts(lXML)
            #LibProcesses_artifact_hash={}
            get_lib_artifacts_info(aXML)
            if key not in uqLib_hash:
                uqLib_hash.append(key)
                       

    
    
    #print (LibProcesses_artifact_hash) 
    map_io_NormPool=get_map_io_by_process(ProcessID, 'Analyte', 'PerInput')
    prepXML=prepare_artifacts_batch(map_io_NormPool,'output')
    aXML=retrieve_artifacts(prepXML)
    NormPoolInfo_hash=get_generic_artifacts_info(aXML)
    
    get_container_names(Container_hash)
    for num, key in enumerate(NormPoolInfo_hash):
        if DEBUG=='1':
            print (num,key,NormPoolInfo_hash[key])
        globalArtifact=key
        for kk in uqLib_hash:
            find_artifact_chain_from_last(map_io,key,kk)
    
    if DEBUG=='1': 
        print ("##### NormPoolInfo_hash #########")

        print ("##### artifacts_info #########")
        for num, key in enumerate(artifacts_info):
            globalArtifact,parentProcessID,processMetInfo =artifacts_info[key]
            print(num,key,globalArtifact,parentProcessID)
        print ("####### end #######")
           
        print ("####### end #######")
        print ("####### LibProcesses_artifact_hash #######")
        for num,libKey in enumerate(LibProcesses_artifact_hash):
            (libArttifactName,libContainerID,libReagentLabel,libProcessLUID, libProcessName, libSampleLUID,libSudfValue)=LibProcesses_artifact_hash[libKey]
            print (num,libKey,libArttifactName,libContainerID,libReagentLabel,libProcessLUID, libProcessName, libSampleLUID,libSudfValue)
        print ("####### end #######")
    
    
    sHeader="Pool Name,Artifact ID,Pool Cycles,Plate Name,Well,sample,Library ID,Library Type,Index Name,Process ID\n"
    sOUT=sHeader
    for key in NormPoolInfo_hash:
        (arttifactName,artifactLocation,containerID,reagentLabel,parentProcessLUID, parentProcessName, sampleLUID,sudfValue)=NormPoolInfo_hash[key]
        #print(key,sudfValue)
        for libKey in LibProcesses_artifact_hash:
            (libArttifactName,libContainerID,libReagentLabel,libProcessLUID, libProcessName, libSampleLUID,libSudfValue)=LibProcesses_artifact_hash[libKey]
            iStatus=isInArtifactChain(artifacts_info, libKey)
            if (sampleLUID==libSampleLUID) and (libReagentLabel==reagentLabel) and (iStatus==1) :
                try:
                    sPoolingGroup=sudfValue['Pooling Group']
                except:
                    sPoolingGroup='N/A'
                try:
                    sPoolingCycles=sudfValue['Index Cycles']
                except:
                    sPoolingCycles='N/A'                
                containerName=Container_hash[containerID]
                sOUT += sPoolingGroup+','+key+','+sPoolingCycles+','+containerName+','+artifactLocation+','+sampleLUID+','+libKey+','+libProcessName+','+libReagentLabel+','+ProcessID +'\n'
                if DEBUG=='1':
                    print (sPoolingGroup+','+key+','+sPoolingCycles+','+containerName+','+artifactLocation+','+sampleLUID+','+libKey+','+libProcessName+','+libReagentLabel+','+ProcessID)
        
    
    print (sOUT)
    
    
    
    
    
    
         
if __name__ == "__main__":
    main()


