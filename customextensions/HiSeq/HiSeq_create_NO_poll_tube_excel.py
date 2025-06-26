# coding: UTF-8
'''
Created June 30, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
    updated (Jan. 30, 2018):
        - v.4 output files format support
        - script moved to Create Strip Tube (HiSeq X) 1.0
        - added Lucigen Library Kit support
        - added "Sample Tag" UDF from Library Kits
        - for v.4 output file ResultFiles IDs were replaced to Analyte IDs
        - generation of "Process setting" output file deprecated 
        

python v.3.5
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


parser = argparse.ArgumentParser(description='Generate Excel file for GeneTitan')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
#parser.add_argument('-processURI_v2',default='', help='processLuid from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-attachFilesLUIDs',default='', help='LUIDs for report files attachment')
parser.add_argument('-debug',default='', help='option for debugging')

'''
{stepURI:v2}
http://localhost:9080/api/v2/steps/24-1297
'''
args = parser.parse_args()

stepURI_v2=args.stepURI_v2
#processURI_v2=args.processURI_v2
user_psw = args.user_psw
attachLUIDs=args.attachFilesLUIDs
attachLUIDs=attachLUIDs[:-1]
DEBUG = args.debug
'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

sDataPath='/data/glsftp/clarity/'
sEventPath='/lb/robot/research/processing/events/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
sProjectName=''
sProbeArrayType=''
sBarcode=''
ProcessID=''
ArtifactsLUID={}
Projects_hash={}
Sample_array={}
Container_array={}
Processes_hash={'10x':"10x Genomics Linked Reads gDNA",'Kapa':"KAPA Hyper Plus", 'Lucigen':"Lucigen AmpFREE Low DNA 1.0"}
activeProcesses_hash={}
#Processes_hash={'Kapa':"KAPA Hyper Plus", 'Lucigen':"Lucigen AmpFREE Low DNA 1.0"}
FileReportLUIDs=attachLUIDs.split(' ')

pass
#sHeader='ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\tSampleLUID\tSampleName\tReference\tStart Date\tSample Tag\n'
sStripTubeHeader="Lane,Run McGill,Comments,Library Name,Country,Multiplex Key(s),Plate Barcode,Wells,Library Size,Conc.,Conc. Unit (nM or ng/�l),Volume (uL),Loading Conc. pM,PhiX,# OF LANES\n"



'''

'''
def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI
    global ProcessID
    global processURI_v2

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"
    ProcessID=tokens[-1]
    processURI_v2=BASE_URI+"processes/"+ProcessID

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
        if DEBUG:
            print (projLUID,projName)
        

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

def get_IS_project_params(processURI_v2):
    global user,psw,sLibraryKit, sBCLMode,sReference, ProcessID
    r = requests.get(processURI_v2, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    nodes= rDOM.getElementsByTagName("prc:process")
    for input in nodes:
        uriType = input.getAttribute( "uri" )
        limsidType = input.getAttribute( "limsid" )
        ProcessID= limsidType     
    sLibraryKit="xxx"
    sBCLMode="xxx"
    sReference="xxx"    

    return sLibraryKit, sBCLMode,sReference

def get_lib_artifact_UDF(artLUID, udfName):
    artURI=BASE_URI+'artifacts/'+artLUID 
    r = requests.get(artURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    nodes= rDOM.getElementsByTagName("udf:field")
    ss="N/A"
    for key in nodes:
        udf = key.getAttribute( "name")
        if (udf==udfName):
            ss=key.firstChild.nodeValue
            
    

    return ss 
    
    

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

def get_artifacts_array(processLuid, artifactType, outputgenerationType,keyIO):
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
        iLUID = input[0].getAttribute( "limsid" )
        output=node.getElementsByTagName("output")
        oType = output[0].getAttribute( "output-type" )
        ogType = output[0].getAttribute( "output-generation-type" )
        oLUID = output[0].getAttribute( "limsid" )
        
        get_samplesORG(iLUID)

        if oType == artifactType and ogType == outputgenerationType:
            if iLUID not in ArtifactsLUID:
                ArtifactsLUID[iLUID]=oLUID
    return ArtifactsLUID
                
def get_samplesORG(artifactID):
    pURI = BASE_URI + "artifacts/" + artifactID
    #print(pURI)
    pXML= requests.get(pURI, auth=(user, psw), verify=True)        
    rDOM = parseString( pXML.content)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        sampleID=node.getElementsByTagName('sample')[0].getAttribute('limsid')
        if sampleID not in samplesORG:
            samplesORG.append(sampleID)

def get_artifact_info_LIB(artifactLUID, udfName):
    
    pURI = BASE_URI + "artifacts/" + artifactLUID
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    #print (pXML.content)
    pDOM = parseString( pXML.content )
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        reagentLabel=artifact.getElementsByTagName('reagent-label')[0].getAttribute('name')
        sampleLUID=artifact.getElementsByTagName('sample')[0].getAttribute('limsid')
        udfNodes= artifact.getElementsByTagName("udf:field")
        libProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
        libProcessName=parentProcessLUIDs[libProcessLUID].split(",")[1]
        sudfValue="N/A"
        for key in udfNodes:
            udf = key.getAttribute( "name")
            if (udf==udfName):
                sudfValue=key.firstChild.nodeValue
        
    return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue

def get_full_artifact_info_LIB(artifactLUID):
    
    pURI = BASE_URI + "artifacts/" + artifactLUID
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    #print (pXML.content)
    pDOM = parseString( pXML.content )
    artifactUDFs={}
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        reagentLabel=artifact.getElementsByTagName('reagent-label')[0].getAttribute('name')
        sampleLUID=artifact.getElementsByTagName('sample')[0].getAttribute('limsid')
        
        udfNodes= artifact.getElementsByTagName("udf:field")
        libProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
        libProcessName=parentProcessLUIDs[libProcessLUID].split(",")[1]
        sudfValue="N/A"
        for key in udfNodes:
            udf = key.getAttribute( "name")
            sudfValue=key.firstChild.nodeValue
            artifactUDFs[udf]=sudfValue
            

                
        
    return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,artifactUDFs,artifactLocation

        
    
def get_artifacts_array_by_process(processLuid, artifactType):
    ## get the process XML
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
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
        

        if oType == artifactType and ogType == "PerInput":
            if oLUID not in artifactsByProcess:
                artifactsByProcess.append(oLUID)

    return artifactsByProcess

def get_map_io_by_process(processLuid, artifactType, outputgenerationType,keyIO):
    ## get the process XML
    map_io={}
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    
    #print (pXML.content)
    pDOM = parseString( pXML.content )

    ## get the individual resultfiles outputs
#    if not ogType:
#        ogType == "PerInput"
        
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
        

        if oType == artifactType and ogType == outputgenerationType:
            #if iLUID not in map_io:
                #map_io[iLUID]=oLUID
            if keyIO=='input':
                if iLUID not in map_io:
                    map_io[iLUID]=oLUID
                                
            if keyIO=='output': 
                if oLUID not in map_io:
                    map_io[oLUID]=iLUID

    return map_io


def get_artifacts_name_array(artifactsXML):

    
    rDOM = parseString( artifactsXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        sampleID=node.getElementsByTagName('sample')[0].getAttribute('limsid')
        if sampleID not in artifactsName:
            artifactsName[sampleID]=artLUID+"xxx"+artName
    
    return 

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

def retrieve_samples(sXML):
    sURI=BASE_URI+'samples/batch/retrieve'
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    return r.content



def prepare_artifacts_batch(ArtifactsLUID,sIO):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in ArtifactsLUID:
        if sIO=="output":
           scURI = BASE_URI+'artifacts/'+ArtifactsLUID[art]
        else:
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

def get_libProtocol_artifact(sampleLUID,libProtocol):
    #sURI=BASE_URI+'artifacts?samplelimsid='+sampleLUID+"&process-type=KAPA Hyper Plus"
    
    sURI=BASE_URI+'artifacts?samplelimsid='+sampleLUID+"&process-type="+Processes_hash[libProtocol]+"&type=Analyte"
    #sURI=BASE_URI+'artifacts?samplelimsid='+sampleLUID+"&process-type="+Processes_hash[libProtocol]
    #print (sURI)
    r = requests.get(sURI, auth=(user, psw), verify=True)    
    rDOM = parseString( r.content )
    
    nodes= rDOM.getElementsByTagName("artifact")
    kapa_artifact_luid="N/A"    
    for node in nodes:

        kapa_artifact_luid=node.getAttribute( "limsid" )

    return kapa_artifact_luid

def get_rollback_libProtocol_artifact():
    global SamplesLib_hash
    SamplesLib_hash={}
    
    for key in activeProcesses_hash:
        
        sURI=BASE_URI+"steps/"+key+"/details"

        #print (sURI)
        r = requests.get(sURI, auth=(user, psw), verify=True)    
        rDOM = parseString( r.content )
        processName=rDOM.getElementsByTagName("configuration")[0].firstChild.nodeValue 
        for node in rDOM.getElementsByTagName("input-output-map"):
            outputLUID=node.getElementsByTagName("output")[0].getAttribute("limsid")
            outputURI=node.getElementsByTagName("output")[0].getAttribute("uri")
            art=requests.get(outputURI, auth=(user, psw), verify=True)
            aDOM=parseString(art.content)
            sampleLUID=aDOM.getElementsByTagName("sample")[0].getAttribute("limsid")
            
            
            if DEBUG:
                print(key,sampleLUID,outputLUID,processName)
            new_key=sampleLUID+"_"+outputLUID    
            if new_key not in SamplesLib_hash:
                SamplesLib_hash[new_key]=outputLUID+"xxx"+processName
            
                
                
            

    return 



def get_artifacts_from_stepName(sStepName):
    respArtifactsXML=""
    if DEBUG:
        print("artifacts from step")
    for key in parentProcessLUIDs:
        

        if (sStepName == parentProcessLUIDs[key].split(",")[1] ):
            if DEBUG:
                print(key,parentProcessLUIDs[key])
            artLUIDs=get_artifacts_array_by_process(key, "Analyte")
            artURIXML=prepare_artifacts_batch(artLUIDs, "input")

            respArtifactsXML=retrieve_artifacts(artURIXML)
            get_artifacts_name_array(respArtifactsXML)
            
            
                
    
    
    return respArtifactsXML

def get_io_from_stepName(sStepName, artifactTYpe, ogType,keyIO):
    
    if DEBUG:
        print("artifacts IO from step "+sStepName)
    for key in parentProcessLUIDs:
        if (sStepName == parentProcessLUIDs[key].split(",")[1] ):
            if DEBUG:
                print(key,parentProcessLUIDs[key])
                
            map_io=get_map_io_by_process(key, artifactTYpe,ogType,keyIO)

            
            
                
    
    
    return map_io







def create_strip_tube_output_file(sXML):
    global projLUID,projName, sampleLUID,sampleName,uqSamples
    
    uqSamples={}
    
    pDOM = parseString( sXML)


    nodes = pDOM.getElementsByTagName( "smp:sample" )
    sTabOutput=sStripTubeHeader
    separator=","
    for node in nodes:
        sampleLUID= node.getAttribute( "limsid" )

        lib_artifact_luid="N/A"
        lib_Protocol="N/A"
        smplTag="N/A"
        for key in Lib_hash:
            (arttifactName,containerLibID,reagentLabel,libProcessLUID, libProcessName, libSMPLID,sudfValue,libartifactLocation)=Lib_hash[key]
            
            if libSMPLID ==sampleLUID:
                sConcLib=sudfValue["Concentration"]
                sConcLibUnits=sudfValue["Conc. Units"]
                sLibVolume=sudfValue["Library Volume (ul)"]
                sPhiX="0.01"
                sLoadConc="200" 
                 
                try:
                    sSizeBp=sudfValue["Size (bp)"]
                except:
                    sSizeBp="N/A"

                                                
                #lib_art = SamplesLib_hash[nLib].split("xxx")[0]
#                if DEBUG:
#                   print("sampleLUID",sampleLUID,SamplesLib_hash[nLib])
                if (key != "N/A"):
                    lib_artifact_luid=key
                    lib_Protocol=libProcessName 
                    smplTag=sudfValue
                    if DEBUG:
                        print("Lib_art",key,lib_artifact_luid,lib_Protocol,smplTag)       
                        
                        
         
        
                 
                    
                    
                    
                sampleName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
                projLUID=node.getElementsByTagName('project')[0].getAttribute( "limsid" )
                projName= Projects_hash[projLUID]
                elements = node.getElementsByTagName( "udf:field" )
                refGenome="N/A"
                for udf in elements:
                    temp = udf.getAttribute( "name" )
                    #print (temp)
                    if temp == "Reference Genome":
                        refGenome=udf.firstChild.nodeValue
                    
                for new_key in Sample_array:
                    (new_sampleLUID,artLUID)=new_key.split("_")
                    if new_sampleLUID==sampleLUID:
                    
                        (wellPosition,artLUID, artName,reagent, containerID)=Sample_array[new_key].split('xxx')
                        
                        for inArt, outArt in process_io_map.items():
                            if outArt == artLUID:
                                (inputwellPosition,inputartLUID, inputartName,inputreagent, inputcontainerID)=inputArtefacts_hash[sampleLUID+"_"+inArt].split('xxx')
                            
                        #new_wellPosition =wellPosition.replace(":","0")
                        if len(libartifactLocation)>3:
                            new_wellPosition =libartifactLocation.replace(":","")
                        else:
                            new_wellPosition =libartifactLocation.replace(":","0")
                        
                    
    #                artResultLUID=ArtifactsLUID[artLUID]
                        (ContainerPosition,ContainerName)=Container_array[containerID].split('xxx')
                        for libNorm_key in map_io_LibNorm:
                            #artLUIDLibNorm=map_io_LibNorm[key]
                            artLUIDLibNorm=libNorm_key
                            (artNameLibNorm,containerIDNorm,reagentLabelNorm,libProcessLUIDNorm, libProcessNameNorm, libSMPLIDNorm,sudfValueNorm,normartifactLocation)=Norm_hash[artLUIDLibNorm]
                            if DEBUG:
                                print (containerID,containerIDNorm,containerLibID)

                            
                            if (key == map_io_LibNorm[libNorm_key]):                    
    
                                (artNameLibNorm,containerIDNorm,reagentLabelNorm,libProcessLUIDNorm, libProcessNameNorm, libSMPLIDNorm,sudfValueNorm,normartifactLocation)=Norm_hash[artLUIDLibNorm]
                                poolArtLUID=map_io_LibPool[artLUIDLibNorm]
                                try:
                                    sNumberLines=sudfValueNorm["Lane Fraction"]
                                except:
                                    sNumberLines="N/A"                                    
                                
                                (pArttifactName,pContainerID,pReagentLabel,pLibProcessLUID, pLibProcessName, pSampleLUID,pSudfValue,partifactLocation)=Cluster_hash[poolArtLUID]
                                if artName ==pArttifactName:
                                    reagent=reagentLabelNorm
                                
                    #                (artLUIDLibNorm, artNameLibNorm)=artifactsName[sampleLUID].split("xxx")
                                    

                                    
                                    #sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(containerID)+"\t"+ ContainerName +"\t"+wellPosition+"\t"+reagent +"\t"+lib_artifact_luid+"\t"+lib_Protocol+"\t"+artLUIDLibNorm+"\t"+artNameLibNorm +"\t"+  str(sampleLUID)+"\t"+ sampleName+"\t"+refGenome+"\t"+ppUDFValue["Start Date"]+"\t"+smplTag+"\n"
                                    
                                    #new_line=ContainerName+"\t"+sampleName+"_"+lib_artifact_luid+"\t"+ projName+"\t"+reagent +"\t"+str(containerLibID)+"\t"+new_wellPosition+"\t"+sSizeBp+"\t"+sConcLib+"\t"+sConcLibUnits+"\t"+sLibVolume+"\t"+sLoadConc+"\t"+sPhiX+"\t"+sNumberLines
                                    new_line=ContainerName+separator+""+separator+sampleName+"_"+lib_artifact_luid+separator+ projName+separator+reagent +separator+str(containerLibID)+separator+new_wellPosition+separator+sSizeBp+separator+sConcLib+separator+sConcLibUnits+separator+sLibVolume+separator+sLoadConc+separator+sPhiX
                                    if new_line not in uqSamples:
                                        #uqSamples[new_line]=(wellPosition,sNumberLines)
                                        uqSamples[new_line]=(wellPosition,sNumberLines,ContainerName)
                                    else:
                                        #(wPos,nLines) = uqSamples[new_line]
                                        (wPos,nLines,ContainerName) = uqSamples[new_line]
                                        #uqSamples[new_line]=(wPos+"."+wellPosition,nLines+"+"+sNumberLines)
                                        uqSamples[new_line]=(wPos+"."+wellPosition,nLines+"+"+sNumberLines,ContainerName)
                                        
                                        
                                    sTabOutput +=wellPosition+separator+ContainerName+separator+sampleName+separator+ projName+separator+reagent +separator+str(containerLibID)+separator+new_wellPosition+separator+sSizeBp+separator+sConcLib+separator+sConcLibUnits+separator+sLibVolume+separator+sLoadConc+separator+sPhiX+separator+sNumberLines+"\n"
    
    
    new_report=sStripTubeHeader
    newSort_hash={}
    for key in uqSamples:
        #(wPos,nLines) = uqSamples[key]
        (wPos,nLines,ContainerName) = uqSamples[key]
        
        

        nn=0

        nn_split=nLines.split("+")
        ww=''.join(wPos.replace(":1",""))
        if len(nn_split)>1:
            #print (wPos,nLines, len(nn_split))
            for k in nn_split:
                nn +=float(k)
            
            wPos_sorted=''.join(sorted(ww.replace(".","")))
            new_wPos_sorted=wPos_sorted[:1]+"."+wPos_sorted[1:]
                   
        else:
            if nLines.isdigit():
                nn=float(nLines)
            else:
                nn=nLines
            new_wPos_sorted=ww

        newSortedIndex=ContainerName+"xxx"+new_wPos_sorted+"xxx"+key
        if newSortedIndex not in newSort_hash:
            newSort_hash[newSortedIndex]=new_wPos_sorted+separator+key+separator+""+str(nn)+"\n"
        #new_report += uqSamples[key].replace(":1","")+"\t"+key+"\n"
        new_report += new_wPos_sorted+separator+key+separator+""+str(nn)+"\n"
                
    new_sorted_report=sStripTubeHeader
    for node in sorted(newSort_hash):
        new_sorted_report +=newSort_hash[node]
     
    return sTabOutput,new_report, new_sorted_report

def create_NO_poll_strip_tube_output_file(sXML):
    global projLUID,projName, sampleLUID,sampleName,uqSamples
    
    uqSamples={}
    
    pDOM = parseString( sXML)


    nodes = pDOM.getElementsByTagName( "smp:sample" )
    sTabOutput=sStripTubeHeader
    separator=","
    for node in nodes:
        sampleLUID= node.getAttribute( "limsid" )

        lib_artifact_luid="N/A"
        lib_Protocol="N/A"
        smplTag="N/A"
        #print("sampleLUID",sampleLUID)
        for key in Lib_hash:
            (arttifactName,containerLibID,reagentLabel,libProcessLUID, libProcessName, libSMPLID,sudfValue,libartifactLocation)=Lib_hash[key]
            
            if libSMPLID ==sampleLUID:
                sConcLib=sudfValue["Concentration"]
                sConcLibUnits=sudfValue["Conc. Units"]
                sLibVolume=sudfValue["Library Volume (ul)"]
                sPhiX="0.01"
                sLoadConc="200" 
                 
                try:
                    sSizeBp=sudfValue["Size (bp)"]
                except:
                    sSizeBp="N/A"

                #print("\tFOR Lib_hash ",sampleLUID,"key",key)                                
                #lib_art = SamplesLib_hash[nLib].split("xxx")[0]
                #if DEBUG:
                
                if (key != "N/A"):
                    lib_artifact_luid=key
                    lib_Protocol=libProcessName 
                    smplTag=sudfValue
                    if DEBUG:
                        print("Lib_art",key,lib_artifact_luid,lib_Protocol,smplTag)       
                        
                        
         
        
                 
                    
                    
                    
                sampleName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
                projLUID=node.getElementsByTagName('project')[0].getAttribute( "limsid" )
                projName= Projects_hash[projLUID]
                elements = node.getElementsByTagName( "udf:field" )
                refGenome="N/A"
                for udf in elements:
                    temp = udf.getAttribute( "name" )
                    #print (temp)
                    if temp == "Reference Genome":
                        refGenome=udf.firstChild.nodeValue
                    
                for new_key in Sample_array:
                    #if isNOPool ==0:
                    (new_sampleLUID,artLUID)=new_key.split("_")
                    #else:
                    #    new_sampleLUID=new_key
                    
                    if new_sampleLUID==sampleLUID:
                        (wellPosition,artLUID, artName,reagent, containerID)=Sample_array[new_key].split('xxx')

                        #print ("\t\t FOR new_key Sample_array",new_sampleLUID,artLUID)
                        for inArt, outArt in process_io_map.items():
                            if outArt == artLUID:
                                (inputwellPosition,inputartLUID, inputartName,inputreagent, inputcontainerID)=inputArtefacts_hash[sampleLUID+"_"+inArt].split('xxx')
                            
                        #new_wellPosition =wellPosition.replace(":","0")
                        if len(libartifactLocation)>3:
                            new_wellPosition =libartifactLocation.replace(":","")
                        else:
                            new_wellPosition =libartifactLocation.replace(":","0")
                        
                    
    #                artResultLUID=ArtifactsLUID[artLUID]
                        (ContainerPosition,ContainerName)=Container_array[containerID].split('xxx')
                        for libNorm_key in map_io_LibNorm:
                            
                            #artLUIDLibNorm=map_io_LibNorm[key]
                            artLUIDLibNorm=libNorm_key
                            (artNameLibNorm,containerIDNorm,reagentLabelNorm,libProcessLUIDNorm, libProcessNameNorm, libSMPLIDNorm,sudfValueNorm,normartifactLocation)=Norm_hash[artLUIDLibNorm]
                            if DEBUG:
                                print (containerID,containerIDNorm,containerLibID)

                            
                            if (key == map_io_LibNorm[libNorm_key]):
                                
                                #print ("\t\t\t FOR lib_norm_key map_io_LibNorm","artLUIDLibNorm",artLUIDLibNorm,"artLUIDLibNorm",artLUIDLibNorm )
                                 
                                (artNameLibNorm,containerIDNorm,reagentLabelNorm,libProcessLUIDNorm, libProcessNameNorm, libSMPLIDNorm,sudfValueNorm,normartifactLocation)=Norm_hash[artLUIDLibNorm]
                                #poolArtLUID=map_io_LibPool[artLUIDLibNorm]
                                try:
                                    sNumberLines=sudfValueNorm["Lane Fraction"]
                                except:
                                    sNumberLines="N/A"                                    
                                
                                #(pArttifactName,pContainerID,pReagentLabel,pLibProcessLUID, pLibProcessName, pSampleLUID,pSudfValue,partifactLocation)=Cluster_hash[poolArtLUID]
                                #if artName ==pArttifactName:
                                reagent=reagentLabelNorm
                                #print ("\t\t\t FOR lib_norm_key map_io_LibNorm","artLUIDLibNorm",artLUIDLibNorm,"artLUIDLibNorm",artLUIDLibNorm,"sNumberLines",sNumberLines )
                            
                #                (artLUIDLibNorm, artNameLibNorm)=artifactsName[sampleLUID].split("xxx")
                                

                                
                                #sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(containerID)+"\t"+ ContainerName +"\t"+wellPosition+"\t"+reagent +"\t"+lib_artifact_luid+"\t"+lib_Protocol+"\t"+artLUIDLibNorm+"\t"+artNameLibNorm +"\t"+  str(sampleLUID)+"\t"+ sampleName+"\t"+refGenome+"\t"+ppUDFValue["Start Date"]+"\t"+smplTag+"\n"
                                
                                #new_line=ContainerName+"\t"+sampleName+"_"+lib_artifact_luid+"\t"+ projName+"\t"+reagent +"\t"+str(containerLibID)+"\t"+new_wellPosition+"\t"+sSizeBp+"\t"+sConcLib+"\t"+sConcLibUnits+"\t"+sLibVolume+"\t"+sLoadConc+"\t"+sPhiX+"\t"+sNumberLines
                                new_line=ContainerName+separator+""+separator+sampleName+"_"+lib_artifact_luid+separator+ projName+separator+reagent +separator+str(containerLibID)+separator+new_wellPosition+separator+sSizeBp+separator+sConcLib+separator+sConcLibUnits+separator+sLibVolume+separator+sLoadConc+separator+sPhiX
                                
                                if new_line not in uqSamples:
                                    #uqSamples[new_line]=(wellPosition,sNumberLines)
                                    uqSamples[new_line]=(wellPosition,sNumberLines,ContainerName)
                                    #print("\t\t\t\t New_line",new_line,wellPosition,sNumberLines,ContainerName)
                                else:
                                    #(wPos,nLines) = uqSamples[new_line]
                                    (wPos,nLines,ContainerName) = uqSamples[new_line]
                                    #uqSamples[new_line]=(wPos+"."+wellPosition,nLines+"+"+sNumberLines)
                                    uqSamples[new_line]=(wPos+"."+wellPosition,nLines+"+"+sNumberLines,ContainerName)
                                    #print("\t\t\t\t Update",new_line,wellPosition,sNumberLines,ContainerName)
                                    
                                    
                                sTabOutput +=wellPosition+separator+ContainerName+separator+sampleName+separator+ projName+separator+reagent +separator+str(containerLibID)+separator+new_wellPosition+separator+sSizeBp+separator+sConcLib+separator+sConcLibUnits+separator+sLibVolume+separator+sLoadConc+separator+sPhiX+separator+sNumberLines+"\n"
    
    
    new_report=sStripTubeHeader
    newSort_hash={}
    for key in uqSamples:
        #(wPos,nLines) = uqSamples[key]
        (wPos,nLines,ContainerName) = uqSamples[key]
        #print (key, uqSamples[key])
        

        nn=0

        nn_split=nLines.split("+")
        ww=''.join(wPos.replace(":1",""))
        if len(nn_split)>1:
            #print (wPos,nLines, len(nn_split))
            for k in nn_split:
                nn +=float(k)
            
            wPos_sorted=''.join(sorted(ww.replace(".","")))
            new_wPos_sorted=wPos_sorted[:1]+"."+wPos_sorted[1:]
                   
        else:
            if nLines.isdigit():
                nn=float(nLines)
            else:
                nn=nLines
            new_wPos_sorted=ww

        newSortedIndex=ContainerName+"xxx"+new_wPos_sorted+"xxx"+key
        if newSortedIndex not in newSort_hash:
            newSort_hash[newSortedIndex]=new_wPos_sorted+separator+key+separator+""+str(nn)+"\n"
        #new_report += uqSamples[key].replace(":1","")+"\t"+key+"\n"
        new_report += new_wPos_sorted+separator+key+separator+""+str(nn)+"\n"
                
    new_sorted_report=sStripTubeHeader
    for node in sorted(newSort_hash):
        new_sorted_report +=newSort_hash[node]
     
    return sTabOutput,new_report, new_sorted_report



def create_process_settings_file():
    sSamples=''
    i=0
    sep=""
    for ssSample in Sample_array:
        if i>0:
            sep=","
        sSamples += sep+ssSample 
        i+=1
    isDebug="False"
    sWorkDir='\\\\abacusfs\\hiseq\\170912_A00266_0008_AH3HJ5DMXX\\'
    sOut=""
    sOut +="ProcessLUID\t"+str(ProcessID)+"\n"
    sOut +="PipelineName\tHiSeq X\n"
    sOut +="ProjectLUID\t"+str(projLUID)+"\n"
    sOut +="ProjectName\t"+projName+"\n"
    sOut +="PipelineWorkDir\t"+sWorkDir+"\n"
    sOut +="isDebug\t"+isDebug+"\n"
    sOut +="SampleLUID\t"+sSamples+"\n"
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


def get_meta_sample_array(arrXML):
    rDOM = parseString( arrXML )
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        wellPos=node.getElementsByTagName('location')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        pos=node.getElementsByTagName('value')[0].firstChild.nodeValue
        reagent=node.getElementsByTagName('reagent-label')[0].getAttribute('name')
        reagentNode=node.getElementsByTagName('reagent-label')
        sampleNode=node.getElementsByTagName('sample')
        nr=0
        rr=0
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        for samples in sampleNode:
            sampleID=samples.getAttribute('limsid')
            rr=0
            for reagentValue in reagentNode:
                if rr==nr:
                    reagText=reagentValue.getAttribute('name')
                rr +=1
            #new_key=  sampleID
            #if isNOPool==0:
            new_key=  sampleID +"_"+artLUID
                              
            if new_key not in Sample_array:
                Sample_array[new_key]=pos+'xxx'+artLUID+'xxx'+artName+'xxx'+reagText+'xxx'+containerID
            nr+=1
            
        #print (artLUID, artName) 
    
    return     


def get_meta_artefact_array(arrXML):
    metaArtefacthash={}
    rDOM = parseString( arrXML )
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        wellPos=node.getElementsByTagName('location')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        pos=node.getElementsByTagName('value')[0].firstChild.nodeValue
        reagent=node.getElementsByTagName('reagent-label')[0].getAttribute('name')
        reagentNode=node.getElementsByTagName('reagent-label')
        sampleNode=node.getElementsByTagName('sample')
        nr=0
        rr=0
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        for samples in sampleNode:
            sampleID=samples.getAttribute('limsid')
            rr=0
            for reagentValue in reagentNode:
                if rr==nr:
                    reagText=reagentValue.getAttribute('name')
                rr +=1            
            new_key=  sampleID +"_"+artLUID              
            if new_key not in metaArtefacthash:
                metaArtefacthash[new_key]=pos+'xxx'+artLUID+'xxx'+artName+'xxx'+reagText+'xxx'+containerID
            nr+=1
            
        #print (artLUID, artName) 
         
    
    return   metaArtefacthash  
    

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
    f_out=open(FileReportLUIDs[-2]+sExtra,"w")
    f_out.write(sText)
    f_out.close()
    
    return
def write_event_file(sText,sFilePath):
    sExtra="_"+str(ProcessID)+"_samples.txt"
    #f_out=open(sFilePath+FileReportLUIDs[6]+sExtra,"w")
    #f_out.write(sText)
    #f_out.close()
    
    return

def get_parentProcess_IDs(processLuid):


    pURI = BASE_URI + "processes/" + processLuid
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    pDOM = parseString( pXML.content )
    ppType =pDOM.getElementsByTagName('type')
    if processLuid not in allParentsIDs:
        allParentsIDs[processLuid]=ppType[0].firstChild.nodeValue

    elements = pDOM.getElementsByTagName( "input" )
   
    for element in elements:
        try:
            ppNode = element.getElementsByTagName( "parent-process" )
            ppURI = ppNode[0].getAttribute( "uri" )
            ppID=ppNode[0].getAttribute( "limsid" )
            if ppID not in parentIDs:
                    parentIDs.append( ppID )
        except:
            ppID=""
            pass            
    if (ppID !=""):
        get_parentProcess_IDs(ppID)
    return parentIDs

def get_parentProcess_UDF(allParentsIDs,ppName,udfName):
#    parentIDs=parentIDs.sort(reverse=True)
#    ppNode=parentIDs[0]
    for key in allParentsIDs:
        if allParentsIDs[key] == ppName:
            pURI = BASE_URI + "processes/" + key
            pXML= requests.get(pURI, auth=(user, psw), verify=True)
            pDOM = parseString( pXML.content )
            node =pDOM.getElementsByTagName('type')
            pName = node[0].firstChild.nodeValue
            vv=getUDF( pDOM, udfName )
            if vv not in ppUDFValue:
                ppUDFValue[udfName]=vv
    return 

def get_rb_parentProcess_UDF(parentProcessLUIDs,ppName,udfName):
#    parentIDs=parentIDs.sort(reverse=True)
#    ppNode=parentIDs[0]
    for key in parentProcessLUIDs:
        if parentProcessLUIDs[key].split(",")[1] == ppName:
            pURI = BASE_URI + "processes/" + key
            pXML= requests.get(pURI, auth=(user, psw), verify=True)
            pDOM = parseString( pXML.content )
            node =pDOM.getElementsByTagName('type')
            pName = node[0].firstChild.nodeValue
            vv=getUDF( pDOM, udfName )
            if vv not in ppUDFValue:
                ppUDFValue[udfName]=vv
    return 


def get_parent_process(processID,parentProcessID):
    sURI=BASE_URI+'processes/'+processID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )
    if DEBUG =="2": 
        print (r.content)
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
        if (ppTYpe == processType):
            ss=(key,parentProcessID)
        
    return ss

def fill_activeProcess_hash(parentProcessLUIDs):
    
    #print ("#######")
    if DEBUG:
        print("## active processes######")    

    for key in parentProcessLUIDs:
        (parentProcessID,ppTYpe)=parentProcessLUIDs[key].split(",")
        #print (key, parentProcessID,ppTYpe)
        for kk in Processes_hash:
            if ppTYpe ==Processes_hash[kk] :
                activeProcesses_hash[key]=parentProcessID+","+ppTYpe
                if DEBUG:
                    print (key,activeProcesses_hash[key])
    

    


'''
    Start
    
'''
def main():
    
    if (stepURI_v2) :
        setupGlobalsFromURI(stepURI_v2)
        get_projects_list()
        global sLibraryKit, sBCLMode, Reference, ProcessID,ppUDFValue,parentIDs,allParentsIDs,artifactsName, parentProcessLUIDs, samplesORG
        ppUDFValue={}
        parentIDs = []
        allParentsIDs={}
        artifactsName={}
        parentProcessLUIDs={}
        samplesORG=[]
        (sLibraryKit, sBCLMode, Reference)=get_IS_project_params(processURI_v2)
        
        get_parent_process(ProcessID,'')
        fill_activeProcess_hash(parentProcessLUIDs)


        if DEBUG:        
            print (ProcessID,sLibraryKit, sBCLMode, Reference)

        global process_io_map
        
        process_io_map=get_artifacts_array(ProcessID, "Analyte","PerInput","")
        
        if DEBUG:
            print ("\n##### process IO map ####\n")
            print (process_io_map)
            print ("\n##### --------  ####\n")
            print (samplesORG)
        if DEBUG:        
            for key in allParentsIDs:
                print (key,allParentsIDs[key])
   

        get_rb_parentProcess_UDF(parentProcessLUIDs,"Create Strip Tube (HiSeq X) 1.0","Start Date")
        
                
        if DEBUG:
            print ("###### artifacts ##########")
            print (ArtifactsLUID)
            print ("################")
        #sXML=prepare_artifacts_batch(ArtifactsLUID, "input")
        sXML=prepare_artifacts_batch(ArtifactsLUID, "output")
        if DEBUG:
            print ("####### artifacts XML for  batch #########")
            print (sXML)
            print ("################")          
         
        lXML=retrieve_artifacts(sXML)
        if DEBUG:
            print ("####### Samples XML #########")
            print (lXML)
            print ("################")         

        global isNOPool
        isNOPool=0
        ss=get_processID_by_processType(parentProcessLUIDs,"Library Pooling (HiSeq X) 1.0")

        if ss =="N/A":
            isNOPool=1
                            
        get_meta_sample_array(lXML)
        
        
        # output Artefacts
        #Sample_array=get_meta_artefact_array(lXML)
        
        if DEBUG:
            print ("####### sorted Sample array #########")        
            for key in sorted(Sample_array):
                print (key, Sample_array[key])
            print ("################")            
   
        inputXML=prepare_artifacts_batch(ArtifactsLUID, "input")
        if DEBUG:
            print ("####### input artifacts XML for  batch #########")
            print (inputXML)
            print ("################")          
         
        inputRetXML=retrieve_artifacts(inputXML)
        if DEBUG:
            print ("####### Samples XML #########")
            print (inputRetXML)
            print ("################")         
   
   
        global inputArtefacts_hash
        inputArtefacts_hash=get_meta_artefact_array(inputRetXML)
        if DEBUG:
            print ("####### sorted inputArtefacts array #########")        
            for key in sorted(inputArtefacts_hash):
                print (key, inputArtefacts_hash[key])
            print ("################")  
   
                    
        
        get_container_names(Container_array)


        xXML = prepare_samples_list_for_batch(lXML)

        zXML=retrieve_samples(xXML)
        
        if DEBUG:
            print ("####### samples XML #########")
            print (zXML)
            print ("################")   

#        get_artifacts_from_stepName("Library Normalization (HiSeq X) 1.0 McGill 1.4")
        global map_io_LibNorm, map_io_LibPool
        map_io_LibNorm=get_io_from_stepName("Library Normalization (HiSeq X) 1.0 McGill 1.4", "Analyte","PerInput","output" )
        
        global Lib_hash, Norm_hash,Cluster_hash,Pool_hash
        Lib_hash={}
        Norm_hash={}
        Pool_hash={}
        Cluster_hash={}
        if DEBUG:
            print (map_io_LibNorm)
            print ("\n###### Lib Hash ######\n")

           
        for key in map_io_LibNorm:
            artOut=map_io_LibNorm[key]

            (Lib_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)=get_full_artifact_info_LIB(artOut)
            if Lib_artifactLUID not in Lib_hash:
                Lib_hash[Lib_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)
                if DEBUG:
                    print (key,map_io_LibNorm[key],Lib_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)
        
        if DEBUG:
            print ("\n#### Lib Norm ########\n")
        for key in map_io_LibNorm:
            
            (Norm_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)=get_full_artifact_info_LIB(key)
            if Norm_artifactLUID not in Norm_hash:
                Norm_hash[Norm_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)
                if DEBUG:
                    print (key,map_io_LibNorm[key],Norm_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)            
    
            
        if isNOPool==0:
            map_io_LibPool=get_io_from_stepName("Library Pooling (HiSeq X) 1.0","Analyte","PerAllInputs","input")
            if DEBUG:
                print (map_io_LibPool)
                print ("\n###### LibPool INPUT ######\n")
            for key in map_io_LibPool:
                (Pool_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)=get_full_artifact_info_LIB(key)
                if Pool_artifactLUID not in Pool_hash:
                    Pool_hash[Pool_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)
                    if DEBUG:
                        print (key ,map_io_LibPool[key],Pool_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)
            
            if DEBUG:
                print ("\n######LibPool OUTPUT ######\n")     
                   
            for key in map_io_LibPool:
                artOut=map_io_LibPool[key]
                (Cluster_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)=get_full_artifact_info_LIB(artOut)
                if Cluster_artifactLUID not in Cluster_hash:
                    Cluster_hash[Cluster_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)
                    if DEBUG:
                        print (key, artOut,Cluster_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation)
        
            
            (outFile, new_report,new_sorted_report)=create_strip_tube_output_file(zXML)
            #print ("Poll +")
        else:
            #print ("No Poll")
            (outFile, new_report,new_sorted_report)=create_NO_poll_strip_tube_output_file(zXML)
        
        
        
        if DEBUG:
            print(Container_array)
            
        #outFile=create_new_rollback_tab_del_output_file(zXML)
        #(outFile, new_report,new_sorted_report)=create_strip_tube_output_file(zXML)
        
        
        print (new_sorted_report)
        #print (new_report)
        #print (outFile)
        #print ("\n##########\n",new_sorted_report)
        
        #write_event_file(outFile, sEventPath)

 

        
if __name__ == "__main__":
    main()   
  
