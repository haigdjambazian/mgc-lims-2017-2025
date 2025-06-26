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

QC_status={'PASS':"PASSED", 'FAIL':"FAILED"}
DEBUG=False

def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-f', "--qcfile", action='store', dest='qcfile') #/opt/gls/clarity/ai/temp/json_output.tsv

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

def get_illumina_reports_from_file(sReportKind):
    global jsonStatusDataFileTab
    
    jsonStatusDataFileTab=[]
    jsonStatusDataFileTab = downloadfile( FileReportLUIDs[0] )


    for x in illuminaTabFile:
        if len(x.split("\t"))>1:
            x=x.strip("\r\n")
            #print (x)
            illuminaResultsTab.append(x.strip("\n").split("\t"))
          

    #illuminaResultsTab = [ x.strip("\r\n").split("\t") for x in illuminaResultsTab ]

def downloadfile( file_art_luid ):
    NEW_NAME = 'temp_file.txt'
    try:
        FH.getFile( file_art_luid, NEW_NAME )
    except:
        print ('trouble downloading result file, file luid not found')
        sys.exit(111)
    raw = open( NEW_NAME, "r")
    lines = raw.readlines()
    raw.close
    return lines

def read_qsfile(sFilePath):
    fp = open( sFilePath, "r")
    for i, line in enumerate(fp):
        if i>0:
            (LIMS_ID,Sample_Name,External_Name,Artifact_ID,QC)=line.strip("\n").split("\t")
            
            print (LIMS_ID,Sample_Name,External_Name,Artifact_ID,QC_status[QC.upper()])
            
            r=update_QC_flag(Artifact_ID, QC_status[QC.upper()] )
            filename=Artifact_ID+"_"+LIMS_ID+"_"+Sample_Name+".json"
            if QC_status[QC.upper()]=="PASSED":
                r=update_artifact_post(Artifact_ID, "File",filename, '')
                if DEBUG:
                    print (r)
            #print (r)
            fileURI=get_file_URI(r)
            if fileURI != "N/A":
                filename=Artifact_ID+"_"+LIMS_ID+"_"+Sample_Name+".json"

            
            
    
def get_file_URI(sXML):
    dlURI="N/A"
    aDOM = parseString( sXML )
    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        dlURI = BASE_URI + "files/" + fLUID + "/download"
    return dlURI        
    
def update_QC_flag(artID, qcFlag ):
    headers = {'Content-Type': 'application/xml'}
    sURI=BASE_URI+'artifacts/'+artID
    r = api.GET(sURI)
    DOM = parseString( r)    
    nodeName="qc-flag"

    if DEBUG > 2: print( DOM.toprettyxml() )
    if DOM.parentNode is None:
        isBatch = False
    else:
        isBatch = True

    newDOM = xml.dom.minidom.getDOMImplementation()
    newDoc = newDOM.createDocument( None, None, None )
#   if the node already exists, delete it
    elements = DOM.getElementsByTagName( nodeName)
    for element in elements:
        if element.toxml():
            try:
                if isBatch:
                   DOM.removeChild( element )
                else:
                        DOM.childNodes[0].removeChild( element )
            except (xml.dom.NotFoundErr, e):
                if DEBUG > 0: print( "Unable to Remove existing UDF node" )

            break

        # now add the new UDF node
    txt = newDoc.createTextNode( qcFlag)
    newNode = newDoc.createElement( nodeName)
    #newNode.setAttribute( "name", udfname )
    #newNode.setAttribute( "type", udftype )
    newNode.appendChild( txt )
    if isBatch:
        DOM.appendChild( newNode )
    else:
        DOM.childNodes[0].appendChild( newNode )
           
    r = api.PUT(DOM.toxml(),sURI)
    return r

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
    qcfile=args.qcfile
    
    read_qsfile(qcfile)    

   




if __name__ == "__main__":
    main()

