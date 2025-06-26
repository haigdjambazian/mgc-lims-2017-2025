'''
Created on May. 23, 2018


@author: Alexander Mazur, alexander.mazur@gmail.com


python v.2.7
'''
__author__ = 'Alexander Mazur'
import sys,os, socket

sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
from optparse import OptionParser
import xml.dom.minidom
from xml.dom.minidom import parseString
import collections
import urllib

import glsapiutil   # 2106 version , needed for API calls
import glsfileutil  # needed to download file
import xml.etree.ElementTree as ET

DEBUG=False
temp_dir="/opt/gls/clarity/ai/temp"



def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')

    Parser.add_option('-l', "--attachLUID", action='store', dest='attachLUID')


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

def get_artifacts_array(processLuid):
    global samplesMetaInfo
    
    samplesMetaInfo={}
    pURI = BASE_URI + "processes/" + processLuid
    
    pXML= api.GET(pURI)
    
    pDOM = parseString( pXML )


    for node in pDOM.getElementsByTagName( "input-output-map" ):
        input = node.getElementsByTagName("input")
        iURI = input[0].getAttribute( "post-process-uri" )
        iLUID = input[0].getAttribute( "limsid" )
        output=node.getElementsByTagName("output")
        oType = output[0].getAttribute( "output-type" )
        ogType = output[0].getAttribute( "output-generation-type" )
        oLUID = output[0].getAttribute( "limsid" )
        oURI=output[0].getAttribute( "uri" )

        if oType == "ResultFile" and ogType == "PerInput":
            outArtXML=api.GET(oURI)
            #print (outArtXML)
            outDOM=parseString(outArtXML)
            for snode in outDOM.getElementsByTagName( "art:artifact" ):
                artLUID=snode.getAttribute( "limsid" )
                sampleName=snode.getElementsByTagName('name')[0].firstChild.nodeValue
                sampleLUID=snode.getElementsByTagName('sample')[0].getAttribute( "limsid" )
                sampleURI=snode.getElementsByTagName('sample')[0].getAttribute( "uri" )
                
                #print (sampleLUID,sampleName)
                
                if sampleLUID not in samplesMetaInfo:
                    sUDFvalue=get_sample_udf_value(sampleURI, "External Name")
                    if sUDFvalue=="N/A":
                       sUDFvalue=sampleLUID 
                    samplesMetaInfo[sampleLUID]=oLUID+"xxx"+sampleName+"xxx"+sUDFvalue

def get_sample_udf_value(sampleURI, sUDFName):
    ss="N/A"
    smplXML=api.GET(sampleURI)
    smplDOM=parseString(smplXML)
    elements = smplDOM.getElementsByTagName( "udf:field" )
    for element in elements:
        if element.getAttribute( "name" ) == sUDFName: 
            ss=element.firstChild.nodeValue    
    
    return ss
def print_output():
    sHeader="LIMS ID\tSample Name\tArtifact ID\tExternal Name"
    print (sHeader)
    for key in samplesMetaInfo:
        (resultFileLUID,sampleName,sUDFvalue)=samplesMetaInfo[key].split("xxx")
        print (key+"\t"+sampleName+"\t"+resultFileLUID+"\t"+sUDFvalue)

def downloadfile( file_art_luid, destinationPath ):

    NEW_NAME = 'json_tempfile.txt'
    #print (file_art_luid, NEW_NAME)
    try:
        FH.getFile( file_art_luid, NEW_NAME )
    except:
        print ('trouble downloading result file, file luid not found')
        sys.exit(111)
    raw = open( NEW_NAME, "r")
    lines = raw.readlines()
    raw.close
    os.rename(NEW_NAME, destinationPath)
    
    return  lines   

def main():

    global args
    args = setup_arguments()
    setupGlobalsFromURI(args.stepURI)
    
    
    
    global api, user, psw#,HOST, BASE_URI
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    user=args.username
    psw=args.password
    json_luid=args.attachLUID
    
    
    get_artifacts_array(ProcessID)
    print_output()
    global FH
    FH = glsfileutil.fileHelper()
    FH.setAPIHandler( api )
    FH.setAPIAuthTokens( args.username, args.password )
    jsonTemp=downloadfile( json_luid,temp_dir+"/json_temp.json" )
#    f_out = open( temp_dir+"/json_temp.json", "w")
#    for line in jsonTemp:
#        f_out.write(line)
#    f_out.close()    
    

    
    
 




if __name__ == "__main__":
    main()
