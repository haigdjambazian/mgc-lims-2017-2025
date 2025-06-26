'''
Created on January 15, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
'''
__author__ = 'Alexander Mazur'



import sys,os

sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files

from optparse import OptionParser
from xml.dom.minidom import parseString
import collections
import urllib
import time
import requests
import re

#import glsapiutil   # 2106 version , needed for API calls
#import glsfileutil  # needed to download file
import xml.etree.ElementTree as ET

ArtifactsLUID=[]
DEBUG = False
def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')

    return Parser.parse_args()[0]


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



def get_artifacts_array(stepURI):

    global ArtifactsLUID

    pURI = stepURI + "/details" 
    pXML= requests.get(pURI, auth=(user, psw), verify=True)
    pDOM = parseString( pXML.content )

    nodes = pDOM.getElementsByTagName( "input-output-map" )
    for io in nodes:
        inputLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        if inputLUID not in ArtifactsLUID:
            ArtifactsLUID.append(inputLUID)
            if DEBUG:
                print (inputLUID)

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



def get_filepath_from_artifacts(sXML):    
    global CEL_filepath

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    
    
    
    root = ET.fromstring(sXML)
    ss=''
    
    
 
    proj="XXX"
    i=1
    if DEBUG:
        print ("#### get_filepath_from_artifacts ########")    
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

        if len(well_position)==3:
            well_position=well_position.replace(':','0')
        else:
            well_position=well_position.replace(':','')
        sample= child.find('sample')
        sample_ID=sample.attrib['limsid']
        metaProj=sample.attrib['limsid'][0:6]

        
        containerID=container.attrib['limsid']
        isControlContainer=child.find('control-type')
        if DEBUG:
            print (artifact_name, well_position,limsid,sample_ID,containerID)
       
        udf_child = child.findall('udf:field', nss)

        
        for sUDF in udf_child:
            if sUDF.attrib['name'] == '.arr File Location':
                sarrFile=sUDF.text
                localFile=extract_filepath(sarrFile)
                rename_file_CEL(localFile, artifact_name)                
                if DEBUG:
                    print(sarrFile,localFile)
                
        
        
        #print (limsid+"\t"+name)


    return

def extract_filepath(sftpPath):
    
    httpPath=HOSTNAME.replace("https","sftp")
    httpPath=httpPath.replace("http","sftp")
    localPath=sftpPath.replace(httpPath+":22","")
    return localPath

def rename_file_CEL(srcFile, sampleName):
    fileCEL=srcFile.replace(".arr",".cel")
    
    if os.path.isfile(fileCEL):
        newCEL=os.path.dirname(fileCEL)+'/'+sampleName+'_'+os.path.basename(fileCEL)
        os.rename(fileCEL,newCEL)
        print (fileCEL+'\t==>'+newCEL) 
       
    return

def main():

    global args, user, psw
    args = setup_arguments()
    user=args.username
    psw=args.password
    
    setupGlobalsFromURI( args.stepURI)
    get_artifacts_array(args.stepURI)
    sXML=prepare_artifacts_batch(ArtifactsLUID)
    if DEBUG:
        print("#############")            
        print (sXML)
        print("#############")        
    lXML=retrieve_artifacts(sXML)
    if DEBUG:
        print("##### artifacts XML   ########")            
        print (lXML)
        print("#############")        
             
    get_filepath_from_artifacts(lXML)



if __name__ == "__main__":
    main()