# coding: UTF-8
'''
Created June 30, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
    updated 202_03_25:
        - added new CSV format for the Excel
    updated 2020_03_05:
        - added the "Sequencing Type" UDF support and info was added as an extra column to the CSV file
        - added support to read info from 'Loading Target Con.' and 'PhiX Ratio' artifacts UDF
    updated 2020_01_22:
        - script has been moved to Library Normalization step,
        - no Illumina protocol required 
    updated 2019_09_26:
        - added support for the samples passed Pool/Capture steps
        - added <HiSeqX|NovaSeq> technology support
    updated 2019_09_18:
        - added support for the samples with submitted library - all samples have to pass LibQC
    updated (Jan. 30, 2018):
        - v.4 output files format support
        - script moved to Create Strip Tube (HiSeq X) 1.0
        - added Lucigen Library Kit support
        - added "Sample Tag" UDF from Library Kits
        - for v.4 output file ResultFiles IDs were replaced to Analyte IDs
        - generation of "Process setting" output file deprecated 
        
 
python v.3.5
'''

script_version="2020_03_27"
__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, sys
sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
import glsapiutil3x
import numpy as np
import numpy.polynomial.polynomial as poly
import time
import logging
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET
import base64
import configparser


  

script_dir=os.path.dirname(os.path.realpath(__file__))
sStripTubeHeader="Lane,Run McGill,Comments,Library Name,Country,Multiplex Key(s),Plate Barcode,Wells,Library Size,Conc.,Conc. Unit (nM or ng/uL),Volume (uL),Loading Conc. pM,PhiX,# OF LANES,Sequencing Type\n"

sGenericStripTubeHeader="SAMPLE NAME,Technician,Library Type,INDEX,Sequencing Type,Volume (ul),LibQC Name,BARCODE,Wells,Concentration (qPCR in nM),LIB SIZE (bp),COMPLETE RUN NAME,LANE,Lane Proportion,Loaging Target (pM) for MiSeq and HiSeqX,Loaging Target (nM) for NovaSeq,PhiX\n"

def setup_arguments():
    parser = argparse.ArgumentParser(description='Generate Excel file for HiSeq X')
    parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
    parser.add_argument('-username',default='', help='username')
    parser.add_argument('-password',default='', help='password')    
    parser.add_argument('-attachFilesLUIDs',default='', help='LUIDs for report files attachment')
    parser.add_argument('-debug',default='', help='option for DEBUGging')
    parser.add_argument('-IlluminaProtocol',default='HiSeqX', action='store', dest='IlluminaProtocol')

        
    return parser.parse_args()


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
    
    r = api.GET(ss)
    rDOM = parseString(r)
    nodes= rDOM.getElementsByTagName("project")
    for node in nodes:
        projLUID = node.getAttribute( "limsid" )
        projName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
        Projects_hash[projLUID]=projName
        if DEBUG:
            print (projLUID,projName)
        

    return 


def get_IS_project_params(processURI_v2):
    global user,psw,sLibraryKit, sBCLMode,sReference, ProcessID
    r = api.GET(processURI_v2)
    rDOM = parseString(r)
    nodes= rDOM.getElementsByTagName("prc:process")
    for input in nodes:
        uriType = input.getAttribute( "uri" )
        limsidType = input.getAttribute( "limsid" )
        ProcessID= limsidType     
    sLibraryKit="xxx"
    sBCLMode="xxx"
    sReference="xxx"    

    return sLibraryKit, sBCLMode,sReference
    

def get_artifacts_array(processLuid, artifactType, outputgenerationType,keyIO):
    ## get the process XML
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= api.GET(pURI)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    #print (pXML.content)
    pDOM = parseString( pXML)

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
    pXML= api.GET(pURI)        
    rDOM = parseString( pXML)
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        sampleID=node.getElementsByTagName('sample')[0].getAttribute('limsid')
        if sampleID not in samplesORG:
            samplesORG.append(sampleID)


def get_full_artifact_info_LIB(artifactLUID):
    
    pURI = BASE_URI + "artifacts/" + artifactLUID
    pXML= api.GET(pURI)
    
    pDOM = parseString( pXML )
    artifactUDFs={}
    isPool=False
    for artifact in pDOM.getElementsByTagName( "art:artifact" ):
        arttifactName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        
        artifactLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        containerID=artifact.getElementsByTagName('container')[0].getAttribute('limsid')
        try:
            reagentLabel=artifact.getElementsByTagName('reagent-label')[0].getAttribute('name')
        except:
            reagentLabel="N/A"
        sampleLUID=artifact.getElementsByTagName('sample')[0].getAttribute('limsid')
        if len(artifact.getElementsByTagName('sample'))>1:
            isPool=True
        
        
        udfNodes= artifact.getElementsByTagName("udf:field")
        try:
            libProcessLUID=artifact.getElementsByTagName('parent-process')[0].getAttribute('limsid')
            libProcessName=parentProcessLUIDs[libProcessLUID].split(",")[1]
        except:
            libProcessLUID="Root"
            libProcessName=artifact.getAttribute('limsid')
        sudfValue="N/A"
        for key in udfNodes:
            udf = key.getAttribute( "name")
            sudfValue=key.firstChild.nodeValue
            artifactUDFs[udf]=sudfValue
            

                
        
    return artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,artifactUDFs,artifactLocation,isPool

        
    
def get_artifacts_array_by_process(processLuid, artifactType):
    ## get the process XML
    pURI = BASE_URI + "processes/" + processLuid
    
    pXML= api.GET(pURI)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    
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
        

        if oType == artifactType and ogType == "PerInput":
            if oLUID not in artifactsByProcess:
                artifactsByProcess.append(oLUID)

    return artifactsByProcess

def get_map_io_by_process(processLuid, artifactType, outputgenerationType,keyIO):
    ## get the process XML
    map_io={}
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= api.GET(pURI)
    pDOM = parseString( pXML)

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
    r = api.POST(sXML, sURI)
    return r



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
    r = api.POST(sXML,sURI)
   
    return r


def get_io_from_stepName(sStepName, artifactTYpe, ogType,keyIO):
    
    if DEBUG:
        print("artifacts IO from step "+sStepName)
    for key in parentProcessLUIDs:
        if (sStepName == parentProcessLUIDs[key].split(",")[1] ):
            if DEBUG:
                print(key,parentProcessLUIDs[key])
                
            map_io=get_map_io_by_process(key, artifactTYpe,ogType,keyIO)

            
            
                
    
    
    return map_io


def create_generic_strip_tube_output_file(sXML):
    global projLUID,projName, sampleLUID,sampleName,uqSamples
    
    uqSamples={}
    longest_container_name = 0
    longest_runcounter_name = 0
    is_runcounter_numeric = True

    pDOM = parseString( sXML)


    nodes = pDOM.getElementsByTagName( "smp:sample" )
    sTabOutput=sStripTubeHeader
    separator=","
    for node in nodes:
        sampleLUID= node.getAttribute( "limsid" )

        lib_artifact_luid="N/A"
        lib_Protocol="N/A"
        smplTag="N/A"
        reagentLabel64=""

        submittedSampleName,projectLUID,submittedUDFValue=submittedSamples_hash[sampleLUID]
        try:
            sBase64=submittedUDFValue['BASE64POOLDATA'].replace("data:text/txt;base64","")
            sBase64Text=base64.b64decode(sBase64).decode('utf-8')
            sLines64=sBase64Text.splitlines()
            
            infoLineArray=sLines64[1].split("\t")
            
            reagentLabel64=infoLineArray[6]
            if len(sLines64)>2:
                for i in range(1,lent(slIne64)):
                    infoLineArray=sLines64[1].split("\t")
                    reagentLabel64 += infoLineArray[6]+":"                    
                
            if DEBUG:
                log("OK "+sampleLUID)
        except:
            pass     
            
               
        for key in Lib_hash:
            (arttifactName,containerLibID,reagentLabel,libProcessLUID, libProcessName, libSMPLID,sudfValue,libartifactLocation,isPoolLib)=Lib_hash[key]
            if libSMPLID ==sampleLUID:
                sTechnician="N/A"
                sLibraryType="N/A"
                
                # Library Prep protocl info
                if len(LibraryArtifacts_hash)>0:
                    for kk in LibraryArtifacts_hash:
                        libNormArtifact,libraryProcessLUID,(parentProcessID,ppType,iNode,sudfLibrayValue)=LibraryArtifacts_hash[kk]
                        librarySampleID,libraryArtifactLUID,org_libNormArt=kk.split('_')
                        new_kk=librarySampleID+"_"+key
                        
                        if (librarySampleID == sampleLUID) and (libNormArtifact==key):
                            try:
                                sTechnician=sudfLibrayValue["Library Technician"]
                            except:
                                pass
                            try:
                                sLibraryType=ppType
                            except:
                                pass
                            
                                            
                
                
                
                try:
                    sConcLib=sudfValue["Concentration"]
                except:
                    sConcLib="N/A"
                try:
                    sConcLibUnits=sudfValue["Conc. Units"]
                except:
                    sConcLibUnits="N/A"
                try:
                    sLibVolume=sudfValue["Library Volume (ul)"]
                except:
                    sLibVolume="N/A"
                    
                sPhiX="N/A" #"0.01"
                sLoadConc="N/A" #"200"
                sSeqType="N/A" 
                 
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
                            (artNameLibNorm,containerIDNorm,reagentLabelNorm,libProcessLUIDNorm, libProcessNameNorm, libSMPLIDNorm,sudfValueNorm,normartifactLocation,isPoolNorm)=Norm_hash[artLUIDLibNorm]
                            if DEBUG:
                                print (containerID,containerIDNorm,containerLibID)
                            
                            if (key == map_io_LibNorm[libNorm_key]):                    
                                (artNameLibNorm,containerIDNorm,reagentLabelNorm,libProcessLUIDNorm, libProcessNameNorm, libSMPLIDNorm,sudfValueNorm,normartifactLocation,isPoolNorm)=Norm_hash[artLUIDLibNorm]
                                sLoagingTargetHiSeq=""
                                sLoagingTargetNovaSeq=""
                                sLoagingTargetConcUnits=""
                                try:
                                    sLoadConc=sudfValueNorm["Loading Target Conc."]
                                except:
                                    pass
                                                                
                                try:
                                    sLoagingTargetConcUnits=sudfValueNorm["Loading Target Conc. Units"]
                                    if "nM" in sLoagingTargetConcUnits:
                                        sLoagingTargetNovaSeq=sLoadConc
                                    elif "pM" in sLoagingTargetConcUnits:
                                        sLoagingTargetHiSeq=sLoadConc  
                                    
                                except:
                                    pass 
                                    
                                                                 
                                try:
                                    sNumberLines=sudfValueNorm["Lane Fraction"]
                                except:
                                    sNumberLines="N/A"

                                try:
                                    sPhiX=sudfValueNorm["PhiX Ratio"]
                                except:
                                    pass                                
                                
                                sSeqType="N/A"
                                try:
                                    sSeqType=sudfValueNorm["Sequencing Type"]
                                except:
                                    pass                                    
                                sPoolContainer=""                                    

                                try:
                                    sPoolingGroup=sudfValueNorm["Pooling Group"]
                                    sPoolingGroup_split=sPoolingGroup.split("_")
                                    #if len(sPoolingGroup_split)>1:
                                    sLane=sPoolingGroup_split[1]
                                    sPoolContainer=sPoolingGroup_split[0]
                                    wellPosition=sLane
                                except :
                                    print("The lane number was not specified for sample "+sampleName )
                                    log("The lane number was not specified for sample "+sampleName)
                                    sys.exit(111)                                
                                
                                if int(sLane)>8:
                                    print(" The lane #"+sLane+" is out of the range of 1...8 for sample "+sampleName )
                                    log(" The lane #"+sLane+" is out of the range of 1...8 for sample "+sampleName )
                                    sys.exit(111)
                                    break                                
                                
                                #poolArtLUID=map_io_LibPool[artLUIDLibNorm]
                                #(pArttifactName,pContainerID,pReagentLabel,pLibProcessLUID, pLibProcessName, pSampleLUID,pSudfValue,partifactLocation)=Cluster_hash[poolArtLUID]
                                #if artName ==pArttifactName:
                                sPool=""
                                if isPoolNorm:
                                    sPool="...pool"
                                    sampleName=artNameLibNorm
                                reagent=reagentLabelNorm+sPool
                                
                                if reagentLabel64:
                                    reagent=reagentLabel64
                                
                                libContainerPosition,libContainerName=get_container_name(containerLibID)
                                new_containerID=libContainerName #+"_"+containerLibID+"_"+libProcessLUID
                                #sLibQCName=libContainerName.split("_")[0]
                                #sBarcode= libContainerName.replace(sLibQCName+"_","")
                                
                                #new_line=ContainerName+separator+separator+sampleName+"_"+lib_artifact_luid+separator+ projName+separator+reagent +separator+str(containerLibID)+separator+new_wellPosition+separator+sSizeBp+separator+sConcLib+separator+sConcLibUnits+separator+sLibVolume+separator+sLoadConc+separator+sPhiX
                                # old version
                                #new_line=ContainerName+separator+separator+sampleName+"_"+lib_artifact_luid+separator+ projName+separator+reagent +separator+new_containerID+separator+new_wellPosition+separator+sSizeBp+separator+sConcLib+separator+sConcLibUnits+separator+sLibVolume+separator+sLoadConc+separator+sPhiX+separator+sSeqType
                                
                                libContainerName_split=libContainerName.split("_")
                                try:
                                    sLibQCName=libContainerName.split("_")[0]
                                except:
                                    sLibQCName="N/A"
                                try:
                                    sBarcode=libContainerName.replace(sLibQCName+"_","")
                                except:
                                    sBarcode="N/A"

                                if len(ContainerName) > longest_container_name:
                                    longest_container_name = len(ContainerName)
                                
                                if len(sPoolContainer) > longest_runcounter_name:
                                    longest_runcounter_name = len(sPoolContainer)

                                if not sPoolContainer.isnumeric():
                                    is_runcounter_numeric = False

                                new_line=sampleName+separator+sTechnician+separator+sLibraryType+separator+reagent+separator+sSeqType+separator+sLibVolume+separator+sLibQCName+separator+sBarcode+separator+new_wellPosition+separator+sConcLib+separator+sSizeBp+separator+sPoolContainer+separator+"LANE"+separator+"Lane Proportion"+separator+sLoagingTargetHiSeq+separator+sLoagingTargetNovaSeq+separator+sPhiX                                
                                if new_line not in uqSamples:
                                    uqSamples[new_line] = (wellPosition, sNumberLines, ContainerName, libartifactLocation, sPoolContainer)
                                    
                                else:
                                    (wPos, nLines, ContainerName, libartifactLocation, sPoolContainer) = uqSamples[new_line]
                                    uqSamples[new_line] = (wPos+"."+wellPosition, nLines+"+"+sNumberLines, ContainerName, libartifactLocation, sPoolContainer)
                                    
                                    
                                sTabOutput +=wellPosition+separator+ContainerName+separator+sampleName+separator+ projName+separator+reagent +separator+str(containerLibID)+separator+new_wellPosition+separator+sSizeBp+separator+sConcLib+separator+sConcLibUnits+separator+sLibVolume+separator+sLoadConc+separator+sPhiX+separator+sNumberLines+separator+sSeqType+"\n"
    
    
    new_report=sGenericStripTubeHeader
    newSort_hash={}
    for key in uqSamples:
        #(wPos,nLines) = uqSamples[key]
        (wPos, nLines, ContainerName, libartifactLocation, runcounter) = uqSamples[key]
        nn=0
        if DEBUG:
            print("index",wPos,nLines,ContainerName,"line\t",key)
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

        if is_runcounter_numeric:
            runcounter = runcounter.zfill(longest_runcounter_name)
        else:
            runcounter = runcounter.ljust(longest_runcounter_name, "0")

        well_sorting_key = libartifactLocation.split(":")
        newSortedIndex = ContainerName.zfill(longest_container_name) + "xxx" + runcounter + "xxx" + new_wPos_sorted + "xxx" + well_sorting_key[1].zfill(3) + "xxx" + well_sorting_key[0]
        old_key=key.split(separator)
        
        old_key[-4]=str(nn)
        old_key[-5]=old_key[-6]+"."+new_wPos_sorted.replace(".","")
        new_old_key=','.join(old_key)        
        if newSortedIndex not in newSort_hash:
            newSort_hash[newSortedIndex]=new_old_key+"\n"
            
        new_report += new_wPos_sorted+separator+key+separator+""+str(nn)+"\n"
                
    new_sorted_report=sGenericStripTubeHeader
    for node in sorted(newSort_hash):
        new_sorted_report +=newSort_hash[node]
     
    return sTabOutput,new_report, new_sorted_report


def log( msg ):
    global LOG
    LOG.append( msg )
    logging.info(msg)
    print (msg)


def get_meta_sample_array(arrXML):
    rDOM = parseString( arrXML )
    Nodes =rDOM.getElementsByTagName('art:artifact')
    for node in Nodes:
        artLUID=node.getAttribute('limsid')
        artName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        wellPos=node.getElementsByTagName('location')
        containerID=node.getElementsByTagName('container')[0].getAttribute('limsid')
        pos=node.getElementsByTagName('value')[0].firstChild.nodeValue
        try:
            reagent=node.getElementsByTagName('reagent-label')[0].getAttribute('name')
            reagentNode=node.getElementsByTagName('reagent-label')
        except:
            #log('There is no reagent for sample: '+artLUID+"\t"+artName)
            pass
            #exit(111)
            
        sampleNode=node.getElementsByTagName('sample')
        nr=0
        rr=0
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        for samples in sampleNode:
            sampleID=samples.getAttribute('limsid')
            rr=0
            try:
                for reagentValue in reagentNode:
                    if rr==nr:
                        reagText=reagentValue.getAttribute('name')
                    rr +=1
            except:
                reagText="N/A"
                
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
        try:
            reagent=node.getElementsByTagName('reagent-label')[0].getAttribute('name')
            reagentNode=node.getElementsByTagName('reagent-label')
        except:
            #log('Cant find the reagent label for sample: '+artLUID+"\t"+artName)
            pass
            
        sampleNode=node.getElementsByTagName('sample')
        
        nr=0
        rr=0
        if containerID not in Container_array:
            Container_array[containerID]="yyy"
        for samples in sampleNode:
            sampleID=samples.getAttribute('limsid')
            rr=0
            try:
                for reagentValue in reagentNode:
                    if rr==nr:
                        reagText=reagentValue.getAttribute('name')
                    rr +=1
            except:
                reagText="N/A"            
            new_key=  sampleID +"_"+artLUID              
            if new_key not in metaArtefacthash:
                metaArtefacthash[new_key]=pos+'xxx'+artLUID+'xxx'+artName+'xxx'+reagText+'xxx'+containerID
            nr+=1
            
        #print (artLUID, artName) 
         
    
    return   metaArtefacthash  
    

def get_container_names(Container_array):
    
    for container_ID in Container_array:
        sURI=BASE_URI+'containers/'+container_ID
        r = api.GET(sURI)
        rDOM = parseString(r)
        node =rDOM.getElementsByTagName('name')
        contName = node[0].firstChild.nodeValue
        contPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
        Container_array[container_ID]=contPosition+'xxx'+contName
    return


def get_container_name(containerID):
    sURI=BASE_URI+'containers/'+containerID
    r = api.GET(sURI)
    rDOM = parseString(r)
    node =rDOM.getElementsByTagName('name')
    containerName = node[0].firstChild.nodeValue
    containerPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
    
    return containerPosition,containerName


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

def attach_file(sText,sFileAttachmentLUID,sFileNameBase,sSuffix):
    
    f_out=open(sFileAttachmentLUID+sFileNameBase+sSuffix,"w")
    f_out.write(sText)
    f_out.close()
    return


def get_parentProcess_IDs(processLuid):


    pURI = BASE_URI + "processes/" + processLuid
    pXML= api.GET(pURI)
    pDOM = parseString( pXML)
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


def get_rb_parentProcess_UDF(parentProcessLUIDs,ppName,udfName):
#    parentIDs=parentIDs.sort(reverse=True)
#    ppNode=parentIDs[0]
    for key in parentProcessLUIDs:
        if parentProcessLUIDs[key].split(",")[1] == ppName:
            pURI = BASE_URI + "processes/" + key
            pXML= api.GET(pURI)
            pDOM = parseString( pXML)
            node =pDOM.getElementsByTagName('type')
            pName = node[0].firstChild.nodeValue
            vv=getUDF( pDOM, udfName )
            if vv not in ppUDFValue:
                ppUDFValue[udfName]=vv
    return 


def get_parent_process(processID,parentProcessID):
    sURI=BASE_URI+'processes/'+processID
    r = api.GET(sURI)
    rDOM = parseString( r )
    if DEBUG =="2": 
        print (r)
    ppTYpe=rDOM.getElementsByTagName( "type" )[0].firstChild.nodeValue
    if processID not in parentProcessLUIDs:
       parentProcessLUIDs[processID]=parentProcessID+","+ppTYpe
       if DEBUG:
           print (processID+","+parentProcessLUIDs[processID])    
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in parentProcessLUIDs:
            get_parent_process(pProcessLUID,processID)

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

def get_submitted_samples_meta(smplXML):
    pDOM = parseString( smplXML )
    
    for node in pDOM.getElementsByTagName( "smp:sample" ):
        submittedSampleLUID=node.getAttribute('limsid')
        submittedSampleName=node.getElementsByTagName("name")[0].firstChild.data
        projectLUID=node.getElementsByTagName("project")[0].getAttribute('limsid')

        udfNodes= node.getElementsByTagName("udf:field") 
        sudfValue={}       
        for key in udfNodes:
            udfName = key.getAttribute( "name")

            sudfValue[udfName]=str(key.firstChild.nodeValue)

        
        if submittedSampleLUID not in submittedSamples_hash:
            submittedSamples_hash[submittedSampleLUID]=submittedSampleName,projectLUID,sudfValue


def read_config_file(sFileName):
    
    config = configparser.RawConfigParser()
    config.read(sFileName)
    LibPooling=config.get(IlluminaProtocol,'LibPooling')
    LibNorm=config.get(IlluminaProtocol,'LibNorm')
    ClusterGen=config.get(IlluminaProtocol,'ClusterGen')
    Sequencing=config.get(IlluminaProtocol,'Sequencing')
    StripTube=config.get(IlluminaProtocol,'StripTube')
    if DEBUG:
        print (LibPooling,LibNorm,ClusterGen)
    return LibPooling,LibNorm,ClusterGen,Sequencing,StripTube


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


'''
    Start
    
'''
def main():
    global api, LOG,sLibraryKit, sBCLMode, Reference, ProcessID,ppUDFValue,parentIDs,allParentsIDs,artifactsName,\
     parentProcessLUIDs, samplesORG,submittedSamples_hash,LibPooling,LibNorm,ClusterGen,Sequencing,StripTube,DEBUG,\
     Projects_hash,IlluminaProtocol,Processes_hash,Sample_array,Container_array,activeProcesses_hash,ArtifactsLUID,\
     pathProcessLUIDs,map_io,IlluminaSequenceSamples,i
    
    args = setup_arguments()
    
    stepURI_v2=args.stepURI_v2
    username = args.username
    password=args.password
    IlluminaProtocol=args.IlluminaProtocol
    DEBUG=False
    dbg = args.debug
    if dbg=="1":
        DEBUG=True
    
        
    
    #DEBUG=True
    attachLUIDs=args.attachFilesLUIDs
    
    FileReportLUIDs=attachLUIDs.split(' ') 
        
    attachLUIDs=attachLUIDs[:-1]
        
    api = glsapiutil3x.glsapiutil3()
    api.setURI( args.stepURI_v2)
    api.setup( args.username, args.password )     
    sDataPath='/data/glsftp/clarity/'
    sEventPath='/lb/robot/research/processing/events/'
    sSubFolderName=sDataPath+time.strftime('%Y/%m/')
    sProjectName=''
    sProbeArrayType=''
    sBarcode=''
    ProcessID=''
    ArtifactsLUID={}
    pathProcessLUIDs={}
    Projects_hash={}
    Sample_array={}
    Container_array={}
    map_io={}
    Processes_hash={'10x':"10x Genomics Linked Reads gDNA",'Kapa':"KAPA Hyper Plus", 'Lucigen':"Lucigen AmpFREE Low DNA 1.0"}
    activeProcesses_hash={}
    
    
    
    if (stepURI_v2) :
        setupGlobalsFromURI(stepURI_v2)
        get_projects_list()

        ppUDFValue={}
        parentIDs = []
        allParentsIDs={}
        artifactsName={}
        parentProcessLUIDs={}
        
        
        samplesORG=[]
        LOG = []
        submittedSamples_hash={}

        
        
        #(sLibraryKit, sBCLMode, Reference)=get_IS_project_params(processURI_v2)
        #LibPooling,LibNorm,ClusterGen,Sequencing,StripTube=read_config_file(script_dir+"/protocols.txt")
        
        
        get_parent_process(ProcessID,'')
        
        get_full_parent_artifact_paths(ProcessID,'',1)
        
        
        fill_activeProcess_hash(parentProcessLUIDs)


        #if DEBUG:        
        #    print (ProcessID,sLibraryKit, sBCLMode, Reference)

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
   

        #get_rb_parentProcess_UDF(parentProcessLUIDs,"Create Strip Tube (HiSeq X) 1.0","Start Date")
        #get_rb_parentProcess_UDF(parentProcessLUIDs,StripTube,"Start Date")
        
                
        if DEBUG:
            print ("###### artifacts ##########")
            print (ArtifactsLUID)
            print ("################")
        
        
        # OUTPUT Artifacts)
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
            
        # 
        get_meta_sample_array(lXML)
        
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
        IlluminaSequenceSamples=get_generic_sample_list(inputRetXML)

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


        global map_io_LibNorm, map_io_LibPool,uq_hash,globalArtifact,artifacts_info,LibraryArtifacts_hash

        
        # GET Library Prep info
        #
        uq_hash=find_process_artifacts(map_io, ProcessID)
        
       
        LibIDs =[]
        for key in pathProcessLUIDs:
            if "151-" in key:
                
                if key not in LibIDs: 
                   # print (key,pathProcessLUIDs[key])
                    LibIDs.append(key)    
        artifacts_info={}
        
        for key in sorted(uq_hash):
            i=0
            globalArtifact=key
            for libID in sorted(LibIDs): #captureID:
                find_lib_artifact_chain_from_last(map_io,key,libID)
        
        LibraryArtifacts_hash=artifacts_info.copy()
        artifacts_info={}
          
        if DEBUG==3:
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
              
        
        
        #
        #    From Create Strip Tube step
        #map_io_LibNorm=get_io_from_stepName(LibNorm, "Analyte","PerInput","output" )
        
        #
        #    From LibNorm step
        
        map_io_LibNorm=get_map_io_by_process(ProcessID, "Analyte","PerInput","output")
        
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
            

            (Lib_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)=get_full_artifact_info_LIB(artOut)
            if Lib_artifactLUID not in Lib_hash:
                Lib_hash[Lib_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)
                if DEBUG:
                    print (key,map_io_LibNorm[key],Lib_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)
        
        if DEBUG:
            print ("\n#### Lib Norm ########\n")
        for key in map_io_LibNorm:
            
            (Norm_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)=get_full_artifact_info_LIB(key)
            if Norm_artifactLUID not in Norm_hash:
                Norm_hash[Norm_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)
                if DEBUG:
                    print (key,map_io_LibNorm[key],Norm_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)            
    
            

        
        if DEBUG=='2':
            map_io_LibPool=get_io_from_stepName(LibPooling,"Analyte","PerAllInputs","input")            
            print (map_io_LibPool)
            print ("\n###### LibPool INPUT ######\n")
            for key in map_io_LibPool:
                (Pool_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)=get_full_artifact_info_LIB(key)
                if Pool_artifactLUID not in Pool_hash:
                    Pool_hash[Pool_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)
                    if DEBUG:
                        print (key ,map_io_LibPool[key],Pool_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)
        
        if DEBUG=='2':
            print ("\n######LibPool OUTPUT ######\n")     
               
            for key in map_io_LibPool:
                artOut=map_io_LibPool[key]
                (Cluster_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)=get_full_artifact_info_LIB(artOut)
                if Cluster_artifactLUID not in Cluster_hash:
                    Cluster_hash[Cluster_artifactLUID]= (arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)
                    if DEBUG:
                        print (key, artOut,Cluster_artifactLUID, arttifactName,containerID,reagentLabel,libProcessLUID, libProcessName, sampleLUID,sudfValue,artifactLocation,isPool)
        
        if DEBUG:
            print(Container_array)
            

        get_submitted_samples_meta(zXML)
        (outFile, new_report,new_sorted_report)=create_generic_strip_tube_output_file(zXML)
        

        attach_file(new_sorted_report,FileReportLUIDs[1],"","_for_excel.csv")
        



 

        
if __name__ == "__main__":
    main()   
  
