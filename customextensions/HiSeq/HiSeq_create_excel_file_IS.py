'''
Created Nov. 21, 2017

@author: Alexander Mazur, alexander.mazur@gmail.com
    updated (Jan. 30, 2018):
        - v.4 output files format support
        - script moved to Illumina Sequencing Step
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
#Processes_hash={'Kapa':"KAPA Hyper Plus", 'Lucigen':"Lucigen AmpFREE Low DNA 1.0"}
FileReportLUIDs=attachLUIDs.split(' ')

pass
sHeader='ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\tSampleLUID\tSampleName\tReference\tStart Date\tSample Tag\n'



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

def get_artifacts_array(processLuid):
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

        if oType == "ResultFile" and ogType == "PerInput":
            if oLUID not in ArtifactsLUID:
                ArtifactsLUID[iLUID]=oLUID

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

def retrieve_asamples(sXML):
    sURI=BASE_URI+'samples/batch/retrieve'
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    return r.content



def prepare_artifacts_batch(ArtifactsLUID):

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

def get_artifacts_from_stepName(sStepName):
    respArtifactsXML=""
    for key in allParentsIDs:
        if (sStepName == allParentsIDs[key]):

            artLUIDs=get_artifacts_array_by_process(key, "Analyte")
            artURIXML=prepare_artifacts_batch(artLUIDs)

            respArtifactsXML=retrieve_artifacts(artURIXML)
            get_artifacts_name_array(respArtifactsXML)
            
            
                
    
    
    return respArtifactsXML

def create_v3_tab_del_output_file(sXML):
    global projLUID,projName, sampleLUID,sampleName
    pDOM = parseString( sXML)


    nodes = pDOM.getElementsByTagName( "smp:sample" )
    sTabOutput=sHeader
    
    for node in nodes:
        sampleLUID= node.getAttribute( "limsid" )
        lib_artifact_luid="N/A"
        lib_Protocol="N/A"
        for key in Processes_hash:
            lib_art = get_libProtocol_artifact(str(sampleLUID), key)
            if (lib_art != "N/A"):
                lib_artifact_luid=lib_art
                lib_Protocol=Processes_hash[key]        
                
                
            
            
            
            
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
            
        
        (wellPosition,artLUID, artName,reagent, containerID)=Sample_array[sampleLUID].split('xxx')
        artResultLUID=ArtifactsLUID[artLUID]
        (ContainerPosition,ContainerName)=Container_array[containerID].split('xxx')
        
        #print (str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(ContainerID)+"\t"+ ContainerName +"\t"+ContainerPosition+"\t"+ str(sampleLUID)+"\t"+ sampleName+"\t"+Reference+"\t"+sLibraryKit+"\t"+ sBCLMode )
        #sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(containerID)+"\t"+ ContainerName +"\t"+wellPosition+"\t"+reagent +"\t"+kapa_artifact_luid+"\t"+Processes_hash['Kapa']+"\t"+artLUID+"\t"+artName +"\t"+  str(sampleLUID)+"\t"+ sampleName+"\t"+refGenome+"\t"+sLibraryKit+"\t"+ sBCLMode+"\n" 
        sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(containerID)+"\t"+ ContainerName +"\t"+wellPosition+"\t"+reagent +"\t"+lib_artifact_luid+"\t"+lib_Protocol+"\t"+artResultLUID+"\t"+artName +"\t"+  str(sampleLUID)+"\t"+ sampleName+"\t"+refGenome+"\t"+sLibraryKit+"\t"+ sBCLMode+"_"+ppUDFValue["Flowcell Lot"]+"_"+ppUDFValue["Start Date"]+"\n"
        
     
    return sTabOutput

def create_v4_tab_del_output_file(sXML):
    global projLUID,projName, sampleLUID,sampleName
    pDOM = parseString( sXML)


    nodes = pDOM.getElementsByTagName( "smp:sample" )
    sTabOutput=sHeader
    
    for node in nodes:
        sampleLUID= node.getAttribute( "limsid" )
        lib_artifact_luid="N/A"
        lib_Protocol="N/A"
        smplTag="N/A"
        for key in Processes_hash:
            lib_art = get_libProtocol_artifact(str(sampleLUID), key)
            if (lib_art != "N/A"):
                lib_artifact_luid=lib_art
                lib_Protocol=Processes_hash[key] 
                smplTag=get_lib_artifact_UDF(lib_art, "Sample Tag")       
                
                
            
            
            
            
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
            
        
        (wellPosition,artLUID, artName,reagent, containerID)=Sample_array[sampleLUID].split('xxx')
        artResultLUID=ArtifactsLUID[artLUID]
        (ContainerPosition,ContainerName)=Container_array[containerID].split('xxx')
        (artLUIDLibNorm, artNameLibNorm)=artifactsName[sampleLUID].split("xxx")
        
        #print (str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(ContainerID)+"\t"+ ContainerName +"\t"+ContainerPosition+"\t"+ str(sampleLUID)+"\t"+ sampleName+"\t"+Reference+"\t"+sLibraryKit+"\t"+ sBCLMode )
        #sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(containerID)+"\t"+ ContainerName +"\t"+wellPosition+"\t"+reagent +"\t"+kapa_artifact_luid+"\t"+Processes_hash['Kapa']+"\t"+artLUID+"\t"+artName +"\t"+  str(sampleLUID)+"\t"+ sampleName+"\t"+refGenome+"\t"+sLibraryKit+"\t"+ sBCLMode+"\n" 
        #sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(containerID)+"\t"+ ContainerName +"\t"+wellPosition+"\t"+reagent +"\t"+lib_artifact_luid+"\t"+lib_Protocol+"\t"+artResultLUID+"\t"+artName +"\t"+  str(sampleLUID)+"\t"+ sampleName+"\t"+refGenome+"\t"+ppUDFValue["Start Date"]+"\n"
        sTabOutput +=str(ProcessID)+"\t"+str(projLUID)+"\t"+ projName+"\t"+str(containerID)+"\t"+ ContainerName +"\t"+wellPosition+"\t"+reagent +"\t"+lib_artifact_luid+"\t"+lib_Protocol+"\t"+artLUIDLibNorm+"\t"+artNameLibNorm +"\t"+  str(sampleLUID)+"\t"+ sampleName+"\t"+refGenome+"\t"+ppUDFValue["Start Date"]+"\t"+smplTag+"\n"
        
     
    return sTabOutput



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
            if sampleID not in Sample_array:
                Sample_array[sampleID]=pos+'xxx'+artLUID+'xxx'+artName+'xxx'+reagText+'xxx'+containerID
            nr+=1
            
        #print (artLUID, artName) 
         
    
    return     
    

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
    f_out=open(sFilePath+FileReportLUIDs[6]+sExtra,"w")
    f_out.write(sText)
    f_out.close()
    
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


'''
    Start
    
'''
def main():
    
    if (stepURI_v2) :
        setupGlobalsFromURI(stepURI_v2)
        get_projects_list()
        global sLibraryKit, sBCLMode, Reference, ProcessID,ppUDFValue,parentIDs,allParentsIDs,artifactsName
        ppUDFValue={}
        parentIDs = []
        allParentsIDs={}
        artifactsName={}
        (sLibraryKit, sBCLMode, Reference)=get_IS_project_params(processURI_v2)
        if DEBUG is True:        
            print (ProcessID,sLibraryKit, sBCLMode, Reference)


        get_artifacts_array(ProcessID)
        get_parentProcess_IDs(ProcessID)
        if DEBUG is True:        
            for key in allParentsIDs:
                print (key,allParentsIDs[key])
   
#        get_parentProcess_UDF(allParentsIDs,"Cluster Generation (HiSeq X) 1.0 McGill 1.0","Flowcell Lot")
        get_parentProcess_UDF(allParentsIDs,"Cluster Generation (HiSeq X) 1.0 McGill 1.0","Start Date")
        #exit()         
        if DEBUG is True:
            print ("################")
            print (ArtifactsLUID)
            print ("################")
        sXML=prepare_artifacts_batch(ArtifactsLUID)
        if DEBUG is True:
            print ("################")
            print (sXML)
            print ("################")          
 
        lXML=retrieve_artifacts(sXML)


        get_meta_sample_array(lXML)
        if DEBUG is True:
            print ("################")        
            for key in sorted(Sample_array):
                print (key, Sample_array[key])
            print ("################")            
        if DEBUG is True:
            print ("################")
            print (lXML)
            print ("################")    
                    
        
        get_container_names(Container_array)

        xXML = prepare_samples_list_for_batch(lXML)

        zXML=retrieve_asamples(xXML)
        
        if DEBUG is True:
            print ("################")
            print (zXML)
            print ("################")   

        get_artifacts_from_stepName("Library Normalization (HiSeq X) 1.0 McGill 1.4")

        outFile=create_v4_tab_del_output_file(zXML)
        print (outFile)
        write_event_file(outFile, sEventPath)
        
        
        
        
        #Processes_hash={'Kapa':"KAPA Hyper Plus", 'Lucigen':"Lucigen AmpFREE Low DNA 1.0", 'IllLibNorm':"Library Normalization (HiSeq X) 1.0 McGill 1.1"}


        
        #exit()
        #sOut= create_process_settings_file()
        #write_file2(sOut)
 

        
if __name__ == "__main__":
    main()   
  
