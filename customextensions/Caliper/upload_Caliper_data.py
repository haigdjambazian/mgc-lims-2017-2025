# encoding: utf-8
'''
Created on Nov. 15, 2017


@author: Alexander Mazur, alexander.mazur@gmail.com
    update 2019_04_12:
        - added decode("ascii","") option to parse filenames with non ascii characters 
    update 2019_03_26:
        - added new_key as sampleName_ProcessID and check the 0 position in the jpeg filename


python v.2.7
'''
__author__ = 'Alexander Mazur'


script_version="2019_04_12"
#DEBUG = False
#samples_controls_placement_file= "/opt/gls/clarity/ai/temp/novaseq_template.csv"
import sys,os

sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files

from optparse import OptionParser
from xml.dom.minidom import parseString
import xml.dom.minidom
import collections, socket
import urllib
import glsapiutil   # 2106 version , needed for API calls
import glsfileutil  # needed to download file
import subprocess
import zipfile
import os
import re
from shutil import copyfile
#import warnings
#warnings.simplefilter('always')

sPROD_bug="http://localhost:9080"
sWellFileTempPath='/opt/gls/clarity/ai/temp/'
sWellFileMask='_WellTable.csv'

def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-z', "--zipFile", action='store', dest='zipFile')     # placement CSV
    Parser.add_option('-d', "--debug", action='store', dest='debug', default='1')
    Parser.add_option('-l', "--attachLUIDs", action='store', dest='attachLUIDs')
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

def getFileLocation(rfLUID ):

    ## get the details from the resultfile artifact
    aURI = BASE_URI + "artifacts/" + rfLUID
    if DEBUG is True:
        print( "Trying to lookup: " + aURI )
    aXML = api.GET( aURI )
    if DEBUG is True:
        print (aXML)
    aDOM = parseString( aXML )

    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        fileURI=nodes[0].getAttribute( "uri" )
        dlURI = BASE_URI  + "files/" + fLUID + "/download"
        fXML = api.GET( fileURI )
        if DEBUG is True:
            print(fXML )
        fDOM = parseString( fXML )
        flocNode = fDOM.getElementsByTagName( "content-location" )[0].firstChild.data
        fileLocation=flocNode.replace(sftpHOSTNAME,'')
        fileLocation=fileLocation.replace('sftp://bravoprodapp.genome.mcgill.ca','')
        if DEBUG is True:
            print( "file location %s" % flocNode+"\n"+ fileLocation)

    return fileLocation

def list_files_from_zip(sFileLocation, sMask):
    stories_zip = zipfile.ZipFile(sFileLocation)
 
    for file in stories_zip.namelist():
        if sMask in stories_zip.getinfo(file).filename:
            sF=unicode(stories_zip.getinfo(file).filename,errors='replace')
            #sF=stories_zip.getinfo(file).filename.decode('unicode_escape').encode('utf-8')
            sFile=sF.split("/")
            
            
            
            for key in Samples_hash:
                result=sFile[1].find(key)
                if  result ==0:
                    Samples_hash[key]=Samples_hash[key]+"xxx"+stories_zip.getinfo(file).filename
                    #print (stories_zip.getinfo(file).filename )


def get_artifacts_array(processLuid, artifactType, outputgenerationType,keyIO):
    ## get the process XML
    pURI = BASE_URI + "processes/" + processLuid
    #print(pURI)
    pXML= api.GET(pURI)
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    #print (pXML)
    pDOM = parseString( pXML )

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
        
        

        if oType == artifactType and ogType == outputgenerationType:
            if iLUID not in ArtifactsLUID:
                ArtifactsLUID[iLUID]=oLUID
    return ArtifactsLUID               

def prepare_artifacts_batch(ArtifactsLUID):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for key in ArtifactsLUID:
        art=ArtifactsLUID[key]
        scURI = BASE_URI+'artifacts/'+art
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_artifacts(sXML):
    
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = api.POST(sXML,sURI)
    #print (r)
    #rDOM = parseString( r.content )    
    return r

def prepare_samples_batch(SamplesLUID):
    #global BASE_URI
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for smpl in SamplesLUID:
        scURI = BASE_URI+'samples/'+smpl
        lXML.append( '<link uri="' + scURI + '" rel="samples"/>' )        

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_samples(sXML):

    sURI=BASE_URI+'samples/batch/retrieve'
    headers = {'Content-Type': 'application/xml'}
    r = api.POST(sXML,sURI) 

    return r
def get_meta_from_artifacts(aXML):
    rDOM = parseString( aXML )

    
    for artifact in rDOM.getElementsByTagName("art:artifact"):
        sampleName=artifact.getElementsByTagName("name")[0].firstChild.data
        #nodes= artifact.getElementsByTagName("udf:field")
        artifactLUID=artifact.getAttribute( "limsid" )
        new_key=sampleName+"_"+ProcessID +"_"+artifactLUID
        if new_key not in Samples_hash:
           Samples_hash[new_key]=artifactLUID  
             
def extract_files_from_zip(sZipArchive,sFileExtensions,sTempDir):
    #archive = 'archive.zip'
    #directory = './'
    #extensions = ('.txt', '.pdf')
    zip_file = zipfile.ZipFile(sZipArchive, 'r')
    try:
        #[zip_file.extract(file, sTempDir) for file in zip_file.namelist() if file.endswith(sFileExtensions)]
        [zip_file.extract(file, sTempDir) for file in zip_file.namelist() if file.endswith(sFileExtensions)]
    except:
        #print("Error raised with  extraction "+file)
        print("Error raised with  extraction "+unicode(file,errors='replace'))
    zip_file.close()  
      
def prepare_xml_for_glsstorage(sArtifactLUID, sFileLocation):
    '''
    <file:file xmlns:file="http://genologics.com/ri/file">
    <attached-to>http://localhost:8080/api/v2/artifacts/LUN3A1PA1</attached-to>
    <original-location>/home/glsftp/Testing/results.csv</original-location>
    </file:file>
    '''
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><file:file xmlns:file="http://genologics.com/ri/file">' )
    scURI = BASE_URI+'artifacts/'+sArtifactLUID
    lXML.append( '<attached-to>' + scURI + '</attached-to>' )        
    lXML.append( '<original-location>' + sFileLocation + '</original-location>' ) 
    #print (scURI)
    #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</file:file>' )
    lXML = ''.join( lXML ) 
    return lXML

def send_to_glsstorage(lXML):
    '''
    <file:file xmlns:file="http://genologics.com/ri/file">
        <content-location>sftp://localhost/local_home/glsftp/Process/2005/6/HDX-FWX-050601-79-2/HDE2A1TP16-10-13.raw</content-location>
        <attached-to>http://localhost:8080/api/v2/artifacts/LUN3A1PA1</attached-to>
        <original-location>/home/glsftp/Testing/results.csv</original-location>
    </file:file>
    
    '''    
    sURI=BASE_URI+'glsstorage'
    #print(sURI+"\n")
    headers = {'Content-Type': 'application/xml'}
    r = api.POST(lXML,sURI) 
    return r

def send_to_files(glsXML):
    sURI = BASE_URI+'files'
    r = api.POST(glsXML,sURI)
    
    return r

def get_file_meta(glsXML):   
    pDOM = parseString( glsXML)
    ## get the individual resultfiles outputs
    nodes=pDOM.getElementsByTagName( "file:file" )
    new_HOSTNAME=HOSTNAME
    if sPROD_bug in new_HOSTNAME:
        new_HOSTNAME="https://bravoprodapp.genome.mcgill.ca"
        
    PROD_URI= new_HOSTNAME+"/lablink/secure/DownloadFile.do?id="#+fLUID.split("-")[1]    
    
    #if len(nodes) > 0:
    for node in nodes:
        fileLUID = node.getAttribute( "limsid" )
        #print(str(len(nodes)),fileLUID)
        #downloadURI = BASE_URI + "files/" + fileLUID + "/download"
        #uploadURI = BASE_URI + "files/" + fileLUID + "/upload"
        '''
        downloadURI changed due to http://localhost:9080 on PROD issue
        
        '''
        
        downloadURI = PROD_URI + fileLUID.split("-")[1]
        uploadURI = BASE_URI + "files/" + fileLUID + "/upload"
        
        #print(str(len(nodes)),fileLUID,downloadURI,uploadURI)
        content_location=node.getElementsByTagName( "content-location" )[0].firstChild.nodeValue
        #print(str(len(nodes)),fileLUID,content_location)
        original_location=node.getElementsByTagName( "original-location" )[0].firstChild.nodeValue


        
    return original_location, content_location,fileLUID,downloadURI,uploadURI

def curl_upload_file(fileFrom, fileTo):
    sCommand="curl -F file=@'"+fileFrom+"' -u "+user+":"+psw+" "+fileTo
    #print(sCommand)
    p = subprocess.Popen(sCommand, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) 
    (out, err) = p.communicate() 
    return out, err

def update_artifact_post(artID, udfName,udfValue, udfType):
    
    sURI=BASE_URI+'artifacts/'+artID
    
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)
  
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    r = api.PUT(DOM.toxml(),sURI)
    return r

def my_setUDF( DOM, udfname, udfvalue,udftype ):
    
    if (udftype ==""):
        udftype="String"

    if DEBUG > 2: print( DOM.toprettyxml() )

        ## are we dealing with batch, or non-batch DOMs?
    if DOM.parentNode is None:
        isBatch = False
    else:
        isBatch = True

    newDOM = xml.dom.minidom.getDOMImplementation()
    newDoc = newDOM.createDocument( None, None, None )

        ## if the node already exists, delete it
    elements = DOM.getElementsByTagName( "udf:field" )
    for element in elements:
        if element.getAttribute( "name" ) == udfname:
            try:
                if isBatch:
                   DOM.removeChild( element )
                else:
                        DOM.childNodes[0].removeChild( element )
            except xml.dom.NotFoundErr, e:
                if DEBUG > 0: print( "Unable to Remove existing UDF node" )

            break

        # now add the new UDF node
    txt = newDoc.createTextNode( str( udfvalue ) )
    newNode = newDoc.createElement( "udf:field" )
    newNode.setAttribute( "name", udfname )
    #newNode.setAttribute( "type", udftype )
    newNode.appendChild( txt )
    if isBatch:
        DOM.appendChild( newNode )
    else:
        DOM.childNodes[0].appendChild( newNode )

    return DOM

def set_visibility(fileXML,bVisible):
    DOM=parseString(fileXML)
    if (bVisible ==""):
        udftype="false"

    if DEBUG > 2: print( DOM.toprettyxml() )

        ## are we dealing with batch, or non-batch DOMs?
    if DOM.parentNode is None:
        isBatch = False
    else:
        isBatch = True

    newDOM = xml.dom.minidom.getDOMImplementation()
    newDoc = newDOM.createDocument( None, None, None )

        ## if the node already exists, delete it
    elements = DOM.getElementsByTagName( "is-published" )
    for element in elements:

        try:
            DOM.childNodes[0].removeChild( element )
        except xml.dom.NotFoundErr, e:
            print( e )

        break

        # now add the new UDF node
    try:    
        txt = newDoc.createTextNode(  bVisible  )
        newNode = newDoc.createElement( "is-published" )
        #newNode.setAttribute( "name", udfname )
        #newNode.setAttribute( "type", udftype )
        newNode.appendChild(txt)
        if isBatch:
            DOM.appendChild( newNode )
        else:
            DOM.childNodes[0].appendChild( newNode )
    except Exception, e:
        print( e )    

    return DOM

def get_welltable_from_zip(sFileLocation, sMask):
    stories_zip = zipfile.ZipFile(sFileLocation)
    sFile=''
    sFile_full=''
    for file in stories_zip.namelist():
        if sMask in stories_zip.getinfo(file).filename:
            sFile_full=stories_zip.getinfo(file).filename
            sFile=stories_zip.getinfo(file).filename.split("/")
            break


    return sFile,sFile_full

def copy_well_file(sSrcPath,sDestPath):
    copyfile (sSrcPath,sDestPath)
        
    


def main():

    global args,DEBUG
    args = setup_arguments()
    
    DEBUG = args.debug
    
    setupGlobalsFromURI( args.stepURI )

    global api, BASE_URI, user, psw,FileReportLUIDs,ArtifactsLUID,Samples_hash
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    
    user=args.username
    psw=args.password
    FileReportLUIDs=args.attachLUIDs
    zipFile=args.zipFile
    BASE_URI=api.getBaseURI()

    ArtifactsLUID={}
    Samples_hash={}
    
    global FH
    FH = glsfileutil.fileHelper()
    FH.setAPIHandler( api )
    FH.setAPIAuthTokens( args.username, args.password )
    sCaliperReport=FileReportLUIDs.split(" ")[-1]
    sWellReportLUID=FileReportLUIDs.split(" ")[2]
    #print(sCaliperReport)
    #exit()
    
    #get_artifacts_array(ProcessID)
    get_artifacts_array(ProcessID, "ResultFile","PerInput","")
    #print(ArtifactsLUID)
    sXML=prepare_artifacts_batch(ArtifactsLUID)
    #print(sXML)
    rXML=retrieve_artifacts(sXML)
    #print(rXML)
    get_meta_from_artifacts(rXML)
    print(Samples_hash)
    if zipFile:
        sFileLocation=zipFile
    else:
        sFileLocation=getFileLocation(sCaliperReport)
    #print(sFileLocation)
    list_files_from_zip(sFileLocation, ".jpeg")
    #print(Samples_hash)
    sTempDir="/tmp"
    extract_files_from_zip(sFileLocation,".jpeg",sTempDir)
    
    extract_files_from_zip(sFileLocation,"_WellTable.csv",sTempDir)
    sWellFile_arr,sWellFile_full=get_welltable_from_zip(sFileLocation, "_WellTable.csv")
    #print(sWellFile_full)
    sWellTableDest=sWellFileTempPath+ProcessID+"_WellTable.csv"
    #copy_well_file(sTempDir+"/"+sWellFile_full,sWellTableDest)
    copy_well_file(sTempDir+"/"+sWellFile_full,sWellReportLUID+"_"+sWellFile_arr[1])
    
       
    
    for key in Samples_hash:
         
        try:
            #if DEBUG=='1':
             
            (sArtifactLUID,sFilePath)=Samples_hash[key].split("xxx")
            
            sFilePath=os.path.expanduser(sTempDir+"/"+sFilePath)
            #print(sArtifactLUID,sFilePath, key)
            if os.path.isfile(sFilePath):
                oXML=prepare_xml_for_glsstorage(sArtifactLUID, sFilePath)
                #print(oXML+"\n")
                glsXML=send_to_glsstorage(oXML)
                #print(glsXML+"\n")
                # Change visibility status
                try:
                    visibleXML=set_visibility(glsXML,"true")
                    #print (dXML.toxml())
                except Exception, e:
                    print (e)                

                fileXML=send_to_files(visibleXML.toxml())
                #print (fileXML+"\n")
                (original_location, content_location,fileLUID,downloadURI,uploadURI)=get_file_meta(fileXML)
                #print(original_location, content_location,fileLUID,downloadURI,uploadURI)
                try:
                    (out, err)=curl_upload_file(original_location, uploadURI)
                    
                    r=update_artifact_post(sArtifactLUID, "FileURI",downloadURI, "")
                    print (r)
                except Exception, e:
                    print (e)
                    
                
            else:
                print("file doesn t exist \t"+sFilePath)
        except:
            pass





if __name__ == "__main__":
    main()