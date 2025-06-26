# coding: UTF-8
'''
Created on Aug. 22, 2018


@author: Alexander Mazur, alexander.mazur@gmail.com

python v.3.5
'''
__author__ = 'Alexander Mazur'

import requests
import warnings
warnings.filterwarnings("ignore", message="numpy.dtype size changed")
warnings.filterwarnings("ignore", message="numpy.ufunc size changed")





DEBUG = False

temp_dir="/opt/gls/clarity/ai/temp/"
import sys,os, socket
sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files


from optparse import OptionParser
import xml.dom.minidom
from xml.dom.minidom import parseString
import collections
import urllib
#import pandas as pd
from xlrd import open_workbook
from pandas import ExcelWriter
from pandas import ExcelFile


#import glsapiutil   # 2106 version , needed for API calls
#import glsfileutil  # needed to download file

uploads_hash={'ARTIFACT':"artifacts",'PROJECT':"projects",'SAMPLE':"samples",'PROCESS':"processes", 'UDF':"UDF"}
strFind= 'ri/artifact"'
strReplace='ri/artifact" xmlns:udf="http://genologics.com/ri/userdefined" xmlns:file="http://genologics.com/ri/file" '

'''
    /lb/robot/research/Novaseq/ =>    /data/glsftp/Novaseq/

'''

file_stores={'novaseq':"/lb/robot/research",'research':"/lb/robot"}



def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-t', "--template", action='store', dest='template')     # placement CSV
    Parser.add_option('-o', "--output", action='store', dest='outputLUID')
    Parser.add_option('-l', "--attachLUIDs", action='store', dest='attachLUIDs')
    Parser.add_option('-i', "--inputFIleLUID", action='store', dest='inputFIleLUID')


    return Parser.parse_args()[0]

def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI
    global sftpHOSTNAME
    global systemHOST

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"
    systemHOST = socket.gethostname()
    sftpHOSTNAME="sftp://"+systemHOST

    if DEBUG is True:
        print (HOSTNAME)
        print (BASE_URI)
        print (sftpHOSTNAME)
        print (systemHOST)


def get_illumina_reports_from_file(sReportKind):
    global illuminaResultsTab,illuminaTabFile,splitResultsCSV
    
    illuminaResultsTab=[]

    if debug:
        raw = open( debug_placement_file, "r")
        illuminaTabFile = raw.readlines()
    else:
        template_from_path = args.template
        if template_from_path:
            raw = open( template_from_path, "r")
            illuminaTabFile = raw.readlines()
        else:
            if (sReportKind=='project'):
                illuminaTabFile = downloadfile( inputFIleLUID,'')
            else:
                illuminaTabFile = downloadfile( inputFIleLUID,'' )

    if len( illuminaTabFile ) == 1:
        print (illuminaTabFile)
        illuminaTabFile = illuminaTabFile[0].split("\r")

    for x in illuminaTabFile:
        if len(x.split("\t"))>1:
            x=x.strip("\r\n")
            #print (x)
            illuminaResultsTab.append(x.strip("\n").split("\t"))
          

    #illuminaResultsTab = [ x.strip("\r\n").split("\t") for x in illuminaResultsTab ]



def downloadfile( file_art_luid, newFileName ):
    if not newFileName:
        newFileName = 'temp_excel_file.txt'
    try:
        #getFile( file_art_luid, newFileName )
        getFileLocation(file_art_luid)
    except:
        print ('trouble downloading result file, file luid not found')
        sys.exit(111)

    return newFileName

def getFile(rfLUID, filePath ):

    ## get the details from the resultfile artifact
    aURI = BASE_URI + "artifacts/" + rfLUID
    if DEBUG is True:
        print( "Trying to lookup: " + aURI )
    aXML = requests.get( aURI,auth=(user, psw), verify=True )
    if DEBUG is True:
        print (aXML)
    aDOM = parseString( aXML.content )

    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        dlURI = BASE_URI  + "files/" + fLUID + "/download"
        if DEBUG is True:
            print( "Trying to download:" + dlURI )

        dlFile = requests.get( dlURI,auth=(user, psw), verify=True )

        ## write it to disk
        try:
            f = open(temp_dir+ filePath, "w" )
            
            f.write( dlFile )
            f.close()
        except:
            if DEBUG is True:
                print( "Unable to write downloaded file to %s" % filePath )

def getFileLocation(rfLUID ):

    ## get the details from the resultfile artifact
    aURI = BASE_URI + "artifacts/" + rfLUID
    if DEBUG is True:
        print( "Trying to lookup: " + aURI )
    aXML = requests.get( aURI,auth=(user, psw), verify=True )
    if DEBUG is True:
        print (aXML)
    aDOM = parseString( aXML.content )

    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        fileURI=nodes[0].getAttribute( "uri" )
        dlURI = BASE_URI  + "files/" + fLUID + "/download"
        fXML = requests.get( fileURI,auth=(user, psw), verify=True )
        if DEBUG is True:
            print(fXML.content )
        fDOM = parseString( fXML.content )
        flocNode = fDOM.getElementsByTagName( "content-location" )[0].firstChild.data
        fileLocation=flocNode.replace(sftpHOSTNAME,'')
        if DEBUG is True:
            print( "file location %s" % flocNode+"\n"+ fileLocation)


    return fileLocation 


def get_workbook_data(sPath):
    global Samples_hash
    #print (sPath)
    Samples_hash={}
    wb = open_workbook(sPath)
    worksheet=wb.sheet_by_name("Cluster")
    total_rows=worksheet.nrows
    total_columns=worksheet.ncols
    bStart=-1
    columnHeaders={}
    for row in range(0,total_rows):
        val=worksheet.cell(row,0).value
         
        if bStart>0:    
            ll=""
            if str(worksheet.cell(row,columnHeaders["Sample"]).value):
                Samples_hash[str(worksheet.cell(row,columnHeaders["Sample"]).value)]=(str(worksheet.cell(row,columnHeaders["Volume of sample for 1 nM (µl)"]).value) ,str(worksheet.cell(row,columnHeaders["Volume of sample (µl)"]).value))
            if (str(worksheet.cell(row,columnHeaders["Volume of sample for 1 nM (µl)"]).value) !="-"):
                ll +=str(worksheet.cell(row,columnHeaders["Volume of sample for 1 nM (µl)"]).value) +"\t"+str(worksheet.cell(row,columnHeaders["Volume of sample (µl)"]).value)
            #print (ll+"\n")            

        if val =="Lane":
            bStart=1
            
            for col in range(0, total_columns):
                columnHeaders[worksheet.cell(row,col).value]=col
                #print (worksheet.cell(row,col).value)   
                
        if bStart>0 and (not val):
            bStart=-1
            break        
        
def prepare_artifacts_batch(Samples_hash):

    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    scURI=""
    for key in Samples_hash:
        #(artName,artLUID)=key.split("_")
        artifactMeta=key.split("_")
        #print (key)
        scURI = BASE_URI+'artifacts/'+artifactMeta[-1]
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML  

def retrieve_artifacts(sXML):
    #global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    
    return r

def get_meta_data_from_artifacts(retXML):
    global inputLibVolume
    inputLibVolume={}
    rDOM = parseString( retXML.content )
    udfs_hash={}
    udfName="Library Volume (ul)"
    
    for artifact in rDOM.getElementsByTagName("art:artifact"):
            nodes= artifact.getElementsByTagName("udf:field")
            artifactLUID=artifact.getAttribute( "limsid" )
            ss="N/A"
            for key in nodes:
                udf = key.getAttribute( "name")
                udfs_hash[udf]=key.firstChild.nodeValue

                    
            
            if artifactLUID not in inputLibVolume:
                inputLibVolume[artifactLUID]=udfs_hash[udfName]
             
    return 
           
def update_LibVolume():
    sHeader="Sample\tLibrary Volume (ul)\tVolume of sample for 1 nM (µl)\tVolume of sample (µl)\tNew Library Volume\tLIMS output\n"
    ss=sHeader
    for labLib in Samples_hash:
        #(artName,artLUID)=labLib.split("_")
        artifactMeta=labLib.split("_")
        artLUID=artifactMeta[-1]
        (vol1nM,sampleVolume)=Samples_hash[labLib]
        inVolume=inputLibVolume[artLUID]
        if vol1nM !="-":
            rr = float(inVolume) - float(vol1nM)
        else:
            rr = float(inVolume) - float(sampleVolume)
        if rr<0:    
            r="new Library volume is "+str(rr)+" and can't be updated"
        else:
            r=update_artifact_post(artLUID, "Library Volume (ul)",str(rr), "")
            
        ss += labLib +"\t"+inVolume +"\t"+vol1nM+"\t"+sampleVolume +"\t" +str(rr)+"\t"+str(r)+"\n"
    print (ss)
        

def update_artifact_post(artID, udfName,udfValue, udfType):
    headers = {'Content-Type': 'application/xml'}
    sURI=BASE_URI+'artifacts/'+artID
    artXML=requests.get( sURI,auth=(user, psw), verify=True )
    pDOM = parseString( artXML.content)
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    #r = api.PUT(DOM.toxml(),sURI)
    r = requests.put(sURI, data=DOM.toxml(), auth=(user, psw), verify=True, headers=headers)
    
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
            except (xml.dom.NotFoundErr, e):
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

    global args,user, psw,inputFIleLUID
    args = setup_arguments()
    setupGlobalsFromURI(args.stepURI)

    user=args.username
    psw=args.password
    inputFIleLUID=args.inputFIleLUID
    
    global FileReportLUIDs
    FileReportLUIDs=args.attachLUIDs.split(' ')

    
    execlFileName=getFileLocation(inputFIleLUID)
    get_workbook_data(execlFileName)
    #print(Samples_hash)
    #exit()
    artLiXML=prepare_artifacts_batch(Samples_hash)
    
    oXML=retrieve_artifacts(artLiXML)

    get_meta_data_from_artifacts(oXML)
    if DEBUG is True:
        print (inputLibVolume)
    update_LibVolume()




if __name__ == "__main__":
    main()