'''
    Created on Oct. 15, 2019
    @author: Alexander Mazur, alexander.mazur@gmail.com
    updated 2020_02_13:
        - defaultKapaTagCycle=0 for new project
        
    -a <read> Reading KapaTag Cycle value from Project and update KapaTag filed on the step 
    -a <update> Reading KapaTag Cycle value from KapaTag value on the step and update +1 to the Project KapaTag UDF

    Usage:

python_version=3.5
 
'''


import random
import sys,os
sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
import glsapiutil3x
from optparse import OptionParser
import socket,csv
import logging
import pandas as pd
import xml.dom.minidom
from xml.dom.minidom import parseString

def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-a', "--kapatagDo", action='store', dest='kapatagDo')
    Parser.add_option('-g',"--debug",default='0', action='store', dest='debug')
        
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
    elements = DOM.getElementsByTagName( "udf:field" )
    for element in elements:
        if element.getAttribute( "name" ) == udfname:
            try:
                if isBatch:
                   DOM.removeChild( element )
                else:
                        DOM.childNodes[0].removeChild( element )
            except xml.dom.NotFoundErr as e:
                if DEBUG > 0: print( "Unable to Remove existing UDF node" )
            break

        # now add the new UDF node
    txt = newDoc.createTextNode( str( udfvalue ) )
    newNode = newDoc.createElement( "udf:field" )
    newNode.setAttribute( "name", udfname )
    newNode.appendChild( txt )
    if isBatch:
        DOM.appendChild( newNode )
    else:
        DOM.childNodes[0].appendChild( newNode )
    return DOM

def log( msg ):
    LOG.append( msg )
    logging.info(msg)
    print (msg)
    
def get_process_UDFs(ProcessID):
    processURI=BASE_URI+'processes/'+ProcessID
    r = api.GET(processURI)
    rDOM = parseString(r)
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")
        sudfValue[udfName]=str(key.firstChild.nodeValue)
    return  sudfValue

def get_project_UDFs(ProjectLUID):
    
    projectURI=BASE_URI+'projects/'+ProjectLUID
    
    r = api.GET(projectURI)
    rDOM = parseString(r)
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")
        sudfValue[udfName]=str(key.firstChild.nodeValue)
    return  sudfValue

def get_map_io_by_process(processLuid, artifactType, outputGenerationType):
    ## get the process XML
    map_io={}
    pURI = BASE_URI + "processes/" + processLuid
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
        
        new_key=iLUID+"_"+oLUID
        if oType == artifactType and ogType == outputGenerationType:#"PerInput":
            map_io[new_key]=oLUID
    return map_io

def get_artifacts_meta(artXML):
    rDOM = parseString(artXML)
    temp={}

    for aNode in rDOM.getElementsByTagName("art:artifact"):
        sampleLUID=aNode.getElementsByTagName("sample")[0].getAttribute("limsid")
        artifactName=aNode.getElementsByTagName('name')[0].firstChild.nodeValue
        artifactLUID=aNode.getAttribute('limsid')
        position=aNode.getElementsByTagName("location")[0].getElementsByTagName("value")[0].firstChild.nodeValue
        containerLUID=aNode.getElementsByTagName("location")[0].getElementsByTagName("container")[0].getAttribute("limsid")
        if sampleLUID not in temp:
            
            temp[sampleLUID]=artifactLUID,artifactName,position,containerLUID
        
    return temp

def get_projects_luids(samplesXML):
    rDOM = parseString(samplesXML)
    temp={}

    for aNode in rDOM.getElementsByTagName("smp:sample"):
        sampleLUID=aNode.getAttribute("limsid")

        projectLUID=aNode.getElementsByTagName("project")[0].getAttribute("limsid")
        if projectLUID not in temp:
            temp[projectLUID]=1
        else:
            temp[projectLUID]=temp[projectLUID]+1
    projecLUID = max(temp, key=temp.get)
    return projecLUID    

def update_process_udf(processLUID, udfName,udfValue, udfType):
    sURI=BASE_URI+'processes/'+processLUID
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    r = api.PUT(DOM.toxml(),sURI)
    return r    

def update_project_udf(projectLUID, udfName,udfValue, udfType):
    sURI=BASE_URI+'projects/'+projectLUID
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    r = api.PUT(DOM.toxml(),sURI)
    return r

def get_random_numbers(sSeed):
    random.seed(int(sSeed))
    randomSequence=random.sample(range(1, 97), 96)
    return randomSequence
'''
    START
'''
def main():

    global api,args,ProcessID,DEBUG, samples_hash, Container_array,LOG, processUDFs,defaultKapaTagCycle
    DEBUG=False
    samples_hash={}
    Container_array={}
    LOG=[]
    defaultKapaTagCycle="1"

    args = setup_arguments()
    user=args.username
    psw=args.password
    kapatagDo=args.kapatagDo

    api = glsapiutil3x.glsapiutil3()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password ) 
    setupGlobalsFromURI( args.stepURI )
    processUDFs=get_process_UDFs(ProcessID)
    #print(processUDFs)


    map_io=get_map_io_by_process(ProcessID, 'Analyte', 'PerInput')
    artifactLUIDs=[key for key in map_io.values()]
    artXML=api.getArtifacts(artifactLUIDs)
    samples_hash=get_artifacts_meta(artXML)
    sampleLUIDs=[key for key in samples_hash]
        
    samplesXML=api.getSamples(sampleLUIDs)
    projectLUID=get_projects_luids(samplesXML)
    projectUDFs=get_project_UDFs(projectLUID)
    
    if kapatagDo=='read':
        try:
            iKapaTagCycle=projectUDFs["KapaTag Cycle"]
        except:
            iKapaTagCycle=defaultKapaTagCycle
        log("KapaTag Cycle = "+iKapaTagCycle)    
        r=update_process_udf(ProcessID, "KapaTag Cycle",iKapaTagCycle,'')
    if kapatagDo=='update':
        iNewKapaTagCycle=int(processUDFs["KapaTag Cycle"])+1
        r=update_project_udf(projectLUID, "KapaTag Cycle",str(iNewKapaTagCycle),'')
        log("Updating KapaTag Cycle = " +str(iNewKapaTagCycle) +" for project "+projectLUID)
        
        



if __name__ == "__main__":
    main()
    

    