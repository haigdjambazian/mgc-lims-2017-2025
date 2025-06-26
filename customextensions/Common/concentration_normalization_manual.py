'''
Created on August 2, 2017

@author: Alexander Mazur, alexander.mazur@gmail.com
Note: 

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


parser = argparse.ArgumentParser(description='Calculate normalized Concentration values per sample')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
parser.add_argument('-processLuid',default='', help='processLuid from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-ar',default='r', help='Analyte or ResultFile ')
parser.add_argument('-ComponentLuids',default='', help='LUIDs for the generated files ')


'''
{stepURI:v2}
http://localhost:9080/api/v2/steps/24-1297
-stepURI_v2 https://bravotestapp.genome.mcgill.ca/api/v2/steps/24-13716
-processLuid 24-13716
'''
args = parser.parse_args()
stepURI_v2=args.stepURI_v2
processLuid=args.processLuid
user_psw = args.user_psw
Analyte_Result=args.ar
ComponentLuids=args.ComponentLuids

if Analyte_Result.upper() =='R':
    Analyte_Result="ResultFile"
else:
    Analyte_Result="Analyte"

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

LUIDs=ComponentLuids.split(" ")
sDataPath='/data/glsftp/clarity/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
hProjects={}
containers_arr={}
dest_containers_arr={}
ArtifactsLUID=[]
destArtifactsLUID=[]
Sample_Concentration={}
container_ID=''
sDestConcentration=''
sDestVolume=''
Affy_Controls={'Axiom gDNA103':"CtrlRack1",'CEPH1463-02':"CtrlRack2",'Negative Control':"Trough1"}



#processLuid = processLuid.replace('24-','')


'''
Affy Controls
Name    Src ID    Src Coord
Axiom gDNA 103    CtrlRack1    1
Axiom gDNA 103    CtrlRack1    3
Axiom gDNA 103    CtrlRack1    4
Axiom gDNA 103    CtrlRack1    5
CEPH1347-2    CtrlRack2    9
CEPH1347-2    CtrlRack2    9
CEPH1347-2    CtrlRack2    9
CEPH1347-2    CtrlRack2    9
CEPH1347-2    CtrlRack2    9
CEPH1347-2    CtrlRack2    9
CEPH1347-2    CtrlRack2    9
Negative Control    Trough1    1
Negative Control    Trough1    1
Negative Control    Trough1    1 



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


def get_artifacts_array(processLuid):

    global user,psw,ArtifactsLUID

    ## get the process XML
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    #print (pXML.content)
    pDOM = parseString( pXML.content )

    ## get the individual resultfiles outputs
    nodes = pDOM.getElementsByTagName( "input" )
    for input in nodes:
        iURI = input.getAttribute( "post-process-uri" )
        oLUID = input.getAttribute( "limsid" )
        if oLUID not in ArtifactsLUID:
            ArtifactsLUID.append( oLUID )

def get_dest_artifacts_array(processLuid):

    global user,psw,destArtifactsLUID

    ## get the process XML
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    #print (pXML.content)
    pDOM = parseString( pXML.content )

    ## get the individual resultfiles outputs
    nodes = pDOM.getElementsByTagName( "output" )
    for output in nodes:
        iURI = output.getAttribute( "uri" )
        oLUID = output.getAttribute( "limsid" )
        oType = output.getAttribute( "output-type" )
        ogType = output.getAttribute( "output-generation-type" )

#        if oType == "ResultFile" and ogType == "PerInput":  
              
        if oType == Analyte_Result and ogType == "PerInput":
            if oLUID not in destArtifactsLUID:
                destArtifactsLUID.append( oLUID )


def prepare_artifacts_batch(ArtifactsLUID):
    global BASE_URI
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


def get_org_samples_array(sXML):
    global sampleURIs

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    
    
    
    root = ET.fromstring(sXML)
    ss=''
    

    i=1
    sampleURIs=[]
    for child in root.findall('art:artifact',nss):
        #print (child)
        limsid=child.attrib['limsid']
        name = child.find('name')
        artifact_name=name.text
        #print (artifact_name)
        parentID=child.find('parent-process')
        sLocation=child.find('location')
        container=sLocation.find('container')

        sample= child.find('sample')
        sample_ID=sample.attrib['limsid']
        sample_URI=sample.attrib['uri']
        if sample_URI not in sampleURIs:
           sampleURIs.append( sample_URI)
        
    return

def prepare_samples_batch(sampleURIs):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in sampleURIs:
        lXML.append( '<link uri="' + art + '" rel="samples"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_samples(sXML):
    global BASE_URI, user,psw
    sURI=BASE_URI+'samples/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content




def get_phisical_position(sAlphaNumPosition):
    
    s=sAlphaNumPosition[0].upper()
    sASCII= ord(s)
    sDigit=sAlphaNumPosition[1:].upper()
    sDigit=sDigit.replace(':0','')
    sDigit=sDigit.replace(':','') 
    
    sPhPos=(int(sASCII)-64)+(int(sDigit)-1)*8
    
    return sPhPos
    
def get_process_UDFs(ProcessID):
    global user,psw, hProjects,sDestConcentration, sDestVolume, sControls, sThreshold,sConcentrationFrom, sTarget, iQuantity
    processURI=BASE_URI+'processes/'+ProcessID
    
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    
#    sProjectName=getUDF(rDOM, 'AGCC Project')
    sDestConcentration=getUDF(rDOM, 'Destination Concentration (ng/ul)')
    sDestVolume=getUDF(rDOM, 'Destination Volume (ul)')
    sControls=getUDF(rDOM, 'Controls')
    sThreshold=getUDF(rDOM, 'Threshold, ng/ul')
    sConcentrationFrom=getUDF(rDOM, 'Concentration from') 
    sTarget= getUDF(rDOM, 'Target')
    iQuantity= getUDF(rDOM, 'Quantity (ng)')
        
    return sDestConcentration, sDestVolume, sControls, sThreshold,sConcentrationFrom, sTarget, iQuantity    

def calculate_dilution(sSrcConcentration,sDestConcentration, sDestVolume):
    
    if (sSrcConcentration == 999):
        x=20
        w=0
    else:
        if (sTarget == "Quantity"):
            x=float(iQuantity)/float(sSrcConcentration)
        else:
            x=float(sDestConcentration)*float(sDestVolume)/float(sSrcConcentration)
        w=float(sDestVolume)-x
    return x,w
    
def get_concentration_from_artifacts(sXML):    
    global Sample_Concentration

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    
    
    
    root = ET.fromstring(sXML)
    ss=''
    
    sHeader='Src ID\tSrc Coord\tDst ID\tDst Coord\tDiluent Vol\tSample Vol\tCoord\tSample Name'
 
    proj="XXX"
    i=1
    
    for child in root.findall('art:artifact',nss):
        #print (child)
        limsid=child.attrib['limsid']
        name = child.find('name')
        artifact_name=name.text
        #print (artifact_name)
        parentID=child.find('parent-process')
        sLocation=child.find('location')
        container=sLocation.find('container')
        
        pos=sLocation.find('value')
        well_position=pos.text
        #print (well_position)
        if len(well_position)==3:
            well_position=well_position.replace(':','0')
        else:
            well_position=well_position.replace(':','')
        sample= child.find('sample')
        sample_ID=sample.attrib['limsid']
        metaProj=sample.attrib['limsid'][0:6]

        
        containerID=container.attrib['limsid']
        isControlContainer=child.find('control-type')
        containerName=get_container_name(containerID)
        
        #if (containerID not in containers_arr) and (isControlContainer is None):
        #   containers_arr[containerID] = "Src"+str(i)
        #   i+=1
        
        
        udf_child = child.findall('udf:field', nss)
        #print (sample_ID)
        if (sConcentrationFrom == "Submitted Sample") and (isControlContainer is None): 
            Sample_Concentration[sample_ID]="xxx__"+well_position+"__"+containers_arr[containerID]+"__"+artifact_name+"__"+containerID+"__"+containerName        
        for sUDF in udf_child:
            if sUDF.attrib['name'] == 'Concentration':
                sConcentration=sUDF.text
                if sample_ID not in Sample_Concentration:
                    Sample_Concentration[sample_ID]=sConcentration+"__"+well_position+"__"+containers_arr[containerID]+"__"+artifact_name+"__"+containerID+"__"+containerName
                    #print (sample_ID+"\t"+sConcentration+"\t"+well_position+"\t"+containers_arr[containerID]+"\t"+artifact_name)
            
           # else:

                
                
        
        
        #print (limsid+"\t"+name)


    return



def get_concentration_from_org_samples(sXML):    
    global containers_arr, Sample_Concentration
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project", 'smp':"http://genologics.com/ri/sample"}
    root = ET.fromstring(sXML)
    ss=''
    
    proj="XXX"
    i=1
    
    for child in root.findall('smp:sample',nss):
        #print (child)
        sample_ID=child.attrib['limsid']
        name = child.find('name')
        artifact_name=name.text
        udf_child = child.findall('udf:field', nss)
        for sUDF in udf_child:
            if sUDF.attrib['name'] == 'Sample Conc.':
                sConcentration=sUDF.text
                if sample_ID in Sample_Concentration:
                    artifact_concentration=Sample_Concentration[sample_ID]
                    artifact_concentration=artifact_concentration.replace('xxx',sConcentration)
                    Sample_Concentration[sample_ID]= artifact_concentration
                    #print (sample_ID+"\t"+sConcentration+"\t"+well_position+"\t"+containers_arr[containerID]+"\t"+artifact_name)
            
            
        
        
        #print (limsid+"\t"+name)


    return

def get_well_position_from_artifacts(sXML):    
    global dest_containers_arr

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    pDOM = parseString( sXML )
    
    #print (sXML)
    root = ET.fromstring(sXML)
    ss=''
    
    sHeader='Sample Name,Container Name,Src ID,Src Coord,Dst ID,Dst Coord,Diluent Vol,Sample Vol,Sample LIMSID'
    #sEMCHeader='SampleName,Src,SrcWell,DstPlate,DstWell,VolSample,VolWater,VolCtrl'
    
    print(sHeader)
    proj="XXX"
    sOUT="Sample Name,Container Name,Src ID,Src Coord,Dst ID,Dst Coord,Diluent Vol,Sample Vol,Sample LIMSID, Concentration_Org\n"
    i=1
    Affyreagent_counter =1
    f_out=open(LUIDs[1]+"_log.csv","w")
    for child in root.findall('art:artifact',nss):
        #print (child)
        limsid=child.attrib['limsid']
        name = child.find('name')
        dest_sample_name=name.text
        parentID=child.find('parent-process')
        sLocation=child.find('location')
        container=sLocation.find('container')
        
        pos=sLocation.find('value')
        well_position=pos.text
        #print (well_position)
        if len(well_position)==3:
            well_position=well_position.replace(':','0')
        else:
            well_position=well_position.replace(':','')
        sample= child.find('sample')
        
        metaProj=sample.attrib['limsid'][0:6]
        dest_containerID=container.attrib['limsid']
        sRobotPosition=get_phisical_position(well_position)
        
        if dest_containerID not in dest_containers_arr:
           dest_containers_arr[dest_containerID] = "Dst"+str(i)
           i+=1
        sConcentration="Ctrl"  
        sample_ID=sample.attrib['limsid']
        sSRCPosition='1'
        SrcID='CtrlRack1'
        Concentration_org=0
        sSRCPosition='1'        
        if sample_ID not in Sample_Concentration:
            sConcentration=999
            containerID='0000'
            containerName='YYY'
        else:
            (Concentration_org,src_position,SrcID, Sample_Name, containerID,containerName)=Sample_Concentration[sample_ID].split('__')
            sConcentration=Concentration_org
            #sSRCPosition=get_phisical_position(src_position)
            sSRCPosition=src_position
            if sSRCPosition =="101":
                sSRCPosition="Tube"

        

#        print (Sample_Name)
        if dest_sample_name in Affy_Controls:
            #print (dest_sample_name+"\t"+str(Affyreagent_counter))
            SrcID=Affy_Controls[dest_sample_name]
            sample_ID=limsid+"_"+sample_ID
            if (dest_sample_name == 'CEPH1463-02'):
                sSRCPosition=9
                
            if (dest_sample_name == 'Axiom gDNA103'):
                sSRCPosition=str(Affyreagent_counter)
                Affyreagent_counter +=1
            
        
        (x,w)=calculate_dilution(sConcentration,sDestConcentration, sDestVolume)    
        DstID=dest_containers_arr[dest_containerID]
        #sOUT = sOUT + SrcID+','+str(sSRCPosition)+','+DstID+','+str(sRobotPosition)+','+str(w)+","+str(x)+','+well_position+','+sample_ID+','+str(Concentration_org)+'\n'
        sOUT = sOUT + Sample_Name+','+containerName+','+ SrcID+','+str(sSRCPosition)+','+DstID+','+well_position+','+str(w)+","+str(x)+','+sample_ID+','+str(Concentration_org)+'\n'
        if w <0:
            w=0
            x=sDestConcentration
        #if (float(Concentration_org) >= float(sThreshold)) or (dest_sample_name in Affy_Controls):
        
        #print(SrcID+','+str(sSRCPosition)+','+DstID+','+str(sRobotPosition)+','+str(w)+","+str(x)+','+well_position+','+sample_ID)
        print(Sample_Name+','+containerName+','+ SrcID+','+str(sSRCPosition)+','+DstID+','+well_position+','+str(w)+","+str(x)+','+sample_ID)
        
    
    f_out.write(sOUT)
    f_out.close()
        
    return


def get_sorted_containers(sXML):    
    global containers_arr

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    
    
    
    root = ET.fromstring(sXML)
    ss=''
    
    sHeader='Src ID\tSrc Coord\tDst ID\tDst Coord\tDiluent Vol\tSample Vol\tCoord\tSample Name'
 
    proj="XXX"
    i=1
    locContainers={}
    for child in root.findall('art:artifact',nss):
        #print (child)
        limsid=child.attrib['limsid']
        name = child.find('name')
        artifact_name=name.text
        #print (artifact_name)
        parentID=child.find('parent-process')
        sLocation=child.find('location')
        container=sLocation.find('container')
        
        pos=sLocation.find('value')
        well_position=pos.text
        #print (well_position)
        if len(well_position)==3:
            well_position=well_position.replace(':','0')
        else:
            well_position=well_position.replace(':','')
        sample= child.find('sample')
        sample_ID=sample.attrib['limsid']
        metaProj=sample.attrib['limsid'][0:6]

        
        containerID=container.attrib['limsid']
        isControlContainer=child.find('control-type')
        
        if (containerID not in locContainers) and (isControlContainer is None):
           locContainers[containerID] = str(i)
           i+=1
    
    j=1
    for contr in sorted(locContainers):
        containers_arr[contr]="Src"+str(j)
        j +=1
    
    return



def get_placement_containers(stepURI_v2):
    global user,psw, container_barcodes
    sURI=stepURI_v2 +'/placements'
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )
#    print('\n')    
#    print (r.content)
#    print('\n')
     
    i=0
    for node in rDOM.getElementsByTagName('selected-containers')[0].childNodes:
        s=node.toxml()
        ss=extract_container_ID (s)
        if (ss):
#            kk=":".join("{:02x}".format(ord(c)) for c in ss)
#            sName=get_container_name(ss)

            print (str(i)+'\tcontainerID:\t'+ss)
        i=i+1
    return
def extract_container_ID (sXML):
    container_ID='x'
    s_split=sXML.split('/')
    container_ID=s_split[len(s_split)-2].replace('"','')
    
    return container_ID

def get_container_name(containerLUID):
    
    containerURI=BASE_URI+'containers/'+containerLUID

    #r = api.GET(containerURI)
    #rDOM = parseString(r )
    r = requests.get(containerURI, auth=(user, psw), verify=True)    
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue
    return ss
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
    if (stepURI_v2) :
        setupGlobalsFromURI(stepURI_v2)
        (sDestConcentration, sDestVolume, sControls, sThreshold, sConcentrationFrom, sTarget, iQuantity)=get_process_UDFs(processLuid)
        #print (sDestConcentration, sDestVolume, sControls, sThreshold, sConcentrationFrom)
    
        get_artifacts_array(processLuid)
        
    #    for artif in ArtifactsLUID:
    #        print (artif)

        sXML=prepare_artifacts_batch(ArtifactsLUID)
        lXML=retrieve_artifacts(sXML)

        '''
        Sort containers A->Z
        '''
        get_sorted_containers(lXML)
        #for contr in containers_arr:
        #    print (contr, containers_arr[contr])
        
        #exit()
        get_concentration_from_artifacts(lXML)
        #for sample_ID in Sample_Concentration:
        #    print (sample_ID, Sample_Concentration[sample_ID])        
        
        
                    
        if (sConcentrationFrom == "Submitted Sample"):
            get_org_samples_array(lXML)
            samplesXML=prepare_samples_batch(sampleURIs)
            retSamplesXML=retrieve_samples(samplesXML)
            
            #print (retSamplesXML)
            
            get_concentration_from_org_samples(retSamplesXML)
        
        #for sample_ID in Sample_Concentration:
         #   print (sample_ID, Sample_Concentration[sample_ID])

        get_dest_artifacts_array(processLuid)
        dest_sXML=prepare_artifacts_batch(destArtifactsLUID)
        dest_lXML=retrieve_artifacts(dest_sXML)

        get_well_position_from_artifacts(dest_lXML)
        
        #for containerID in containers_arr:
         #   print (containerID,containers_arr[containerID])
       
        
if __name__ == "__main__":
    main()   
    
    