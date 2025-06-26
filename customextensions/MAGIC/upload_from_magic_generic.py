'''
Created on April 17, 2019

    The Script designed to upload documents from the MaGiC system into LIMS

    @author: Alexander Mazur, alexander.mazur@gmail.com
    updated:
        2019_06_04:
            - added "Project ID" field on step form
            - added generic input file format - <excel|tab>


Note:

python_version=3.5
 
'''

script_version="2020_02_07"

__author__ = 'Alexander Mazur'

import sys
sys.path.append('/opt/gls/clarity/customextensions/Common')
import getopt
from optparse import OptionParser
import glsapiutil3x
import urllib
import xml.dom.minidom
import datetime
import logging
import socket
import s4.clarity 
from xml.dom.minidom import parseString
from xlrd import open_workbook




def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-t', "--template", action='store', dest='template')     # placement CSV
    Parser.add_option('-o', "--output", action='store', dest='outputLUID')
    Parser.add_option('-a', "--attachLUID", action='store', dest='attachLUID')
    Parser.add_option('-i', "--inputFormat", action='store', dest='inputFormat', default='excel') # <excel|tab>


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


def getToday():

    now = datetime.datetime.now()

    strToday = str(now.year) + "-"
    tmp = str(now.month)
    if len(tmp) == 1:
        tmp = "0" + tmp
    strToday += ( tmp + "-" )
    tmp = str(now.day)
    if len(tmp) == 1:
        tmp = "0" + tmp
    strToday += tmp

    return strToday

def createSampleXML( sName, udfs, pLIMSID, cLIMSID, pDate, wp ):

    sXML = '<smp:samplecreation xmlns:smp="http://genologics.com/ri/sample" xmlns:udf="http://genologics.com/ri/userdefined">'
    sXML += '<name>' + sName + '</name>'
    sXML += '<date-received>' + pDate + '</date-received>'
    sXML += '<project uri="' + BASE_URI + 'projects/' + pLIMSID + '"></project>'
    sXML += '<location>'
    sXML += '<container uri="' + BASE_URI + 'containers/' + cLIMSID + '"></container>'
    sXML += '<value>' + wp + '</value>'
    sXML += '</location>'
    ## add the udfs
    for udfName in udfs.keys():
        sXML += '<udf:field name="' + udfName + '">' + udfs[ udfName ] + '</udf:field>'
    sXML += '</smp:samplecreation>'

    return sXML

def createContainer( cType, cName ):

    response = ""

    qURI = BASE_URI + "containertypes?name=" + urllib.parse.quote( cType )
    qXML = api.GET( qURI )
    qDOM = parseString( qXML )
    nodes = qDOM.getElementsByTagName( "container-type" )
    if len(nodes) == 1:
        ctURI = nodes[0].getAttribute( "uri" )
        xml = '<?xml version="1.0" encoding="UTF-8"?>'
        xml += '<con:container xmlns:con="http://genologics.com/ri/container">'
        if len(cName) > 0:
            xml += ( '<name>' + cName + '</name>' )
        else:
            xml += '<name></name>'
        xml += '<type uri="' + ctURI + '"/>'
        xml += '</con:container>'
        xml.encode( "utf-8" )

        sURI=BASE_URI + "containers" 
        
        rXML = api.POST( xml, sURI)

        rDOM = parseString( rXML )
        nodes = rDOM.getElementsByTagName( "con:container" )
        if len(nodes) > 0:
            tmp = nodes[0].getAttribute( "limsid" )
            response = tmp

    return response

def log( msg ):

    global LOG
    LOG.append( msg )
    logging.info(msg)
    print (msg)

def parseFile( filename ):

    global COLS
    global ROWS
    global ExternalCommnads
    global ApplicationCommands

    book = open_workbook( filename, formatting_info=False )
    worksheet = book.sheet_by_index(-1)
    nRows=worksheet.nrows
    cells = worksheet._cell_values

    ## DO WE HAVE THE CORRECT BASIC FORMAT?
    headerStart = -1
    headerStop = -1
    dataStart = -1
    dataStop = -1
        
    rowCount = 0
    for row in cells:
        if headerStart == -1 and row[0] == "<TABLE HEADER>":
            headerStart = rowCount
        elif headerStop == -1 and row[0] == "</TABLE HEADER>":
            headerStop = rowCount
        elif dataStart == -1 and row[0] == "<SAMPLE ENTRIES>":
            dataStart = rowCount
        elif dataStop == -1 and row[0] == "</SAMPLE ENTRIES>":
            dataStop = rowCount
        rowCount += 1
    
    ExternalCommnads = cells[dataStop+1:nRows]
    
       
    if headerStop > headerStart and dataStop > dataStart and dataStart > headerStop:

        cols = cells[ headerStart + 1 ]
        for i in range( 0, len(cols) ):
            COLS[ cols[i] ] = i

        ROWS = cells[ dataStart + 1:dataStop ]
        
        for row in ROWS:
            sName = row[ COLS[ "Sample/Name" ] ].strip()
            sApplicationCMD=row[ COLS[ "UDF/Application" ] ].strip()
            sPosition=row[ COLS[ "Sample/Well Location" ] ].strip()
            if sApplicationCMD:
                ApplicationCommands[sName]=(sApplicationCMD,sPosition)

        return True
    else:
        return False
    
def parse_tab_File( filename ):

    global COLS
    global ROWS
    global header

    raw = open( filename, "r")
    resultsCSV = raw.readlines()
    resultsCSV = [ x.strip("\r\n").split("\t") for x in resultsCSV ]

    headerStart = -1
    headerStop = -1
    dataStart = -1
    dataStop = -1

    rowCount = 0
    #for row in cells:
    status=True
    for i in range(len(resultsCSV)):
        line=resultsCSV[i]
        #print (i,line)
        #exit()
        try:
            if headerStop>0:
                #cc=line[0].split("\t")
                ROWS.append(line)
                            
            if "PI Name" in line:
                #print (i,line)
                headerStop=1
                #cols=line[0]
                for i in range(0,len(line)):
                    
                    COLS[line[i]]=i

            
                        
        except Exception as e:
            print(e)
            status=False

    return status
    
    
def check_researcher(researcherName):
    #print(researcherName)
    firstName,lastName=researcherName.split(" ")
    #print(researcherName,firstName,lastName)
    qURI = BASE_URI + "researchers?firstname=" + firstName+"&lastname="+lastName
    #print(researcherName,firstName,lastName, qURI)
    qXML = api.GET(qURI)
    qDOM = parseString( qXML)

    ## did we get any project nodes?
    nodes = qDOM.getElementsByTagName( "researcher" )
    nodeCount = len(nodes)   
    if nodeCount==1:
        return nodes[0].getAttribute("uri")
    elif nodeCount>1:
        sMsg="There are few users with "+researcherName+" creditials"
        print(sMsg)
        logging.debug( sMsg)
        sys.exit(111)
    elif nodeCount==0:
        sMsg="There is no user with "+researcherName+" creditials. Please create it."
        print(sMsg)
        logging.debug( sMsg)
        sys.exit(111)
        
         
    
    
    

def createProject( pName, researcherName,udfs, pDate ):

    pLIMSID = ""
    
    researchURI=check_researcher(researcherName)
    print (researchURI)
    

    qURI = BASE_URI + "projects?name=" + urllib.parse.quote( pName )
    qXML = api.GET( qURI )
    qDOM = parseString( qXML )
    
    nodes = qDOM.getElementsByTagName( "project" )
    nodeCount = len(nodes)

    if nodeCount == 0:
        ## create a new project

        pXML = '<?xml version="1.0" encoding="utf-8"?>'
        pXML += '<prj:project xmlns:udf="http://genologics.com/ri/userdefined" xmlns:ri="http://genologics.com/ri" xmlns:file="http://genologics.com/ri/file" xmlns:prj="http://genologics.com/ri/project">'
        pXML += '<name>' + pName + '</name>'
        pXML += '<open-date>' + pDate + '</open-date>'
        #pXML += '<researcher uri="' + BASE_URI + 'researchers/1"/>'
        
        pXML += '<researcher uri="' + researchURI+ '"/>'
        ## add the udfs
        for udfName in udfs.keys():
            pXML += '<udf:field name="' + udfName + '">' + udfs[ udfName ] + '</udf:field>'
        pXML += '</prj:project>'
        pXML = pXML.encode( "utf-8" )

        rXML = api.POST( pXML, BASE_URI + "projects" )                        
        
        try:
            rDOM = parseString( rXML )
            nodes = rDOM.getElementsByTagName( "prj:project" )
            if len(nodes) > 0:
                pLIMSID = nodes[0].getAttribute( "limsid" )
                log( "Created Project: " + pLIMSID + " with Name:" + pName )
            else:
                log( "ERROR: Creating Project" )
                log( rXML )
                sys.exit(111)
        except:
            log( "ERROR: Creating Project" )
            log( rXML )
            sys.exit(111)

    elif nodeCount == 1:
        ## we have a project, return the limsid
        log( "Project with name: " + pName + " already in system" )
        pLIMSID = nodes[0].getAttribute( "limsid" )
    else:
        ## this is bad: we have multiple projects with the same name!!!!!
        log( "Multiple Project already exist for: " + pName )
        sys.exit(111)

    return pLIMSID

def processRows():

    ProjectsCreatedCache = {}
    ContainersCreatedCache = {}

    ## let's harvest the UDF names
    udfNames = {}
    for colName in COLS.keys():
        if colName.startswith( "UDF/" ) is True:
            udfName = colName.replace( "UDF/", "" )
            udfNames[ udfName ] = COLS[ colName ]

    bsXML = []
    bsXML.append( '<?xml version="1.0" encoding="UTF-8"?>' )
    bsXML.append( '<smp:details xmlns:smp="http://genologics.com/ri/sample">' )

    for row in ROWS:

        sName = row[ COLS[ "Sample/Name" ] ].strip()
        

        projectName = row[ COLS[ "Project Name" ] ].strip()
        researcherName = row[ COLS[ "PI Name" ] ].strip()
        projectID = row[ COLS[ "Project ID" ] ].strip()
        #print( sName,projectName,researcherName,projectID)

        ## check if the project already exist in LIMS
        if projectName not in ProjectsCreatedCache:
            pLUID = createProject( projectName,researcherName, {}, TODAY )
            ProjectsCreatedCache[ projectName ] = pLUID
        else:
            pLUID = ProjectsCreatedCache[ projectName ]

        ## organize the data elements we need

        ## deal with the container, is it a simple case (Tube), or complex case (multi-sample container)
        try:
            cType = row[ COLS[ "Container/Type" ] ].strip()
            cName = row[ COLS[ "Container/Name" ] ].strip()
        except:
            print("check the delimiter")
        
        if cType == "Tube" or len(cType) == 0:
            cLUID = createContainer( "Tube", cName )
            wp = '1:1'
        else:
            if cName not in ContainersCreatedCache:

                cURI = BASE_URI + "containers?name=" + urllib.parse.quote( cName )
                cXML = api.GET( cURI )
                
                cDOM = parseString( cXML )
                nodes = cDOM.getElementsByTagName( "container" )
                ContainerCount = len(nodes) # how many containers with this name already exist in LIMS

                if ContainerCount == 0:
                    cLUID = createContainer( cType, cName )
                    log( 'Creating container: ' + cName + " limsid: " + cLUID)
                elif ContainerCount == 1:
                    cLUID = nodes[0].getAttribute( "limsid" )
                    log( 'Found container: ' + cName + " limsid: " + cLUID)
                else:
                    log( "ERROR: More then 1 container named: " + cName )
                    sys.exit(2)

                ContainersCreatedCache[ cName ] = cLUID

            else:
                cLUID = ContainersCreatedCache[ cName ]
            wp = row[ COLS[ "Sample/Well Location" ] ].strip()
            print (wp)

        ## now we have the container sorted, let's get the minimum sample metadata

        ## let's harvest udfs
        udfs = {}
        for udfName in udfNames:
            val = str(row[ udfNames[ udfName ] ])
            if len(val) > 0:
                udfs[ udfName ] = val

        ## finally create the sample
        sXML = createSampleXML( sName, udfs, pLUID, cLUID, TODAY, wp )

        bsXML.append( sXML )

    bsXML.append( '</smp:details>' )
    bsXML = "".join( bsXML )

    #print bsXML
    sURI=BASE_URI + "samples/batch/create" 
    headers = {'Content-Type': 'application/xml'}
   
           
    rXML = api.POST( bsXML, BASE_URI + "samples/batch/create" )
    

   
    try:
        rDOM = parseString( rXML )
        nodes = rDOM.getElementsByTagName( "link" )
        if len(nodes) > 0:
            log( str(len(nodes)) + " samples created" )
        else:
            
            errMSG = rDOM.getElementsByTagName( "message" )[0].firstChild.data
            print("Error message:\t"+errMSG+"\n"+bsXML)
            log( "ERROR: Creating samples: " +errMSG+"\n")
            log( rXML )
            sys.exit(111)
    except:
        print( "ERROR: Creating samples" )
        print(rXML)
        log( "ERROR: Creating samples" )
        log( rXML )        
        sys.exit(111)
        
        

def get_artifacts_io_output(riXML):
    global art_smpl_io_map
    riXML=riXML.decode(encoding='UTF-8')
    sURI=BASE_URI+"samples/batch/retrieve"
    smplXML=api.POST(riXML,sURI)
    rDOM = parseString( smplXML )
    try:
        for node in rDOM.getElementsByTagName( "smp:sample" ):
            sSampleName=node.getElementsByTagName("name")[0].firstChild.data
            sArtifactLUID=node.getElementsByTagName("artifact")[0].getAttribute("limsid")
            udfs_hash={}
            #print(sSampleName,sArtifactLUID)
            for key in node.getElementsByTagName("udf:field"):
                udf = key.getAttribute( "name")
                udfs_hash[udf]=key.firstChild.nodeValue
            sApplication=""
            try:
                sApplication=udfs_hash["Application"]
                art_smpl_io_map[sArtifactLUID]=(sSampleName,udfs_hash["Sample Group"],sApplication)                
            except:
                pass
            
    except Exception as e:
        log(e)
        print(e)
        exit(111)

    
def processRows_generic(pLUID):

    ProjectsCreatedCache = {}
    ContainersCreatedCache = {}

    ## let's harvest the UDF names
    udfNames = {}
    for colName in COLS.keys():
        if colName.startswith( "UDF/" ) is True:
            udfName = colName.replace( "UDF/", "" )
            udfNames[ udfName ] = COLS[ colName ]

    bsXML = []
    bsXML.append( '<?xml version="1.0" encoding="UTF-8"?>' )
    bsXML.append( '<smp:details xmlns:smp="http://genologics.com/ri/sample">' )

    for row in ROWS:

        sName = row[ COLS[ "Sample/Name" ] ].strip()
        ## organize the data elements we need

        ## deal with the container, is it a simple case (Tube), or complex case (multi-sample container)
        try:
            cType = row[ COLS[ "Container/Type" ] ].strip()
            cName = row[ COLS[ "Container/Name" ] ].strip()
        except:
            print("check the delimiter")
        
        if cType == "Tube" or len(cType) == 0:
            cLUID = createContainer( "Tube", cName )
            wp = '1:1'
        else:
            if cName not in ContainersCreatedCache:

                cURI = BASE_URI + "containers?name=" + urllib.parse.quote( cName )
                cXML = api.GET( cURI )
                
                cDOM = parseString( cXML)
                nodes = cDOM.getElementsByTagName( "container" )
                ContainerCount = len(nodes) # how many containers with this name already exist in LIMS

                if ContainerCount == 0:
                    cLUID = createContainer( cType, cName )
                    log( 'Creating container: ' + cName + " limsid: " + cLUID)
                elif ContainerCount == 1:
                    cLUID = nodes[0].getAttribute( "limsid" )
                    log( 'Found container: ' + cName + " limsid: " + cLUID)
                else:
                    log( "ERROR: More then 1 container named: " + cName )
                    sys.exit(2)

                ContainersCreatedCache[ cName ] = cLUID

            else:
                cLUID = ContainersCreatedCache[ cName ]
            wp = row[ COLS[ "Sample/Well Location" ] ].strip()
            print (wp)

        ## now we have the container sorted, let's get the minimum sample metadata

        ## let's harvest udfs
        udfs = {}
        for udfName in udfNames:
            val = str(row[ udfNames[ udfName ] ])
            if len(val) > 0:
                udfs[ udfName ] = val

        ## finally create the sample
        sXML = createSampleXML( sName, udfs, pLUID, cLUID, TODAY, wp )

        bsXML.append( sXML )

    bsXML.append( '</smp:details>' )
    bsXML = "".join( bsXML )

 
    rXML = api.POST( bsXML, BASE_URI + "samples/batch/create" )

    # create art_smpl_io_map for routing
    get_artifacts_io_output(rXML)
    
        
   
    try:
        rDOM = parseString( rXML)
        nodes = rDOM.getElementsByTagName( "link" )
        if len(nodes) > 0:
            log( str(len(nodes)) + " samples created" )
        else:
            
            errMSG = rDOM.getElementsByTagName( "message" )[0].firstChild.data
            log(errMSG)
            sys.exit(2)
        
    except:
        #errMSG = rDOM.getElementsByTagName( "message" )[0].firstChild.data
        print(rXML)
        log(rXML)
        sys.exit(2)


def getFileLocation(rfLUID ):

    ## get the details from the resultfile artifact
    fileLocation=""
    aURI = BASE_URI + "artifacts/" + rfLUID
    if DEBUG is True:
        print( "Trying to lookup: " + aURI )
    aXML = api.GET( aURI )
    
    

    aDOM = parseString( aXML)

    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        fileURI=nodes[0].getAttribute( "uri" )
        dlURI = BASE_URI  + "files/" + fLUID + "/download"
        fXML = api.GET( fileURI )
        
        if DEBUG is True:
            print(fXML)
        fDOM = parseString( fXML)
        flocNode = fDOM.getElementsByTagName( "content-location" )[0].firstChild.data
        fileLocation=flocNode.replace(sftpHOSTNAME,'')
        fileLocation=fileLocation.replace('sftp://bravoprodapp.genome.mcgill.ca','')
        if DEBUG is True:
            print( "file location %s" % flocNode+"\n"+ fileLocation)

    return fileLocation

def get_process_UDFs(ProcessID):
    
    processURI=BASE_URI+'processes/'+ProcessID
    
    r = api.GET(processURI)
    rDOM = parseString(r)
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")
        #print(udfName,key.firstChild.nodeValue)
        sudfValue[udfName]=str(key.firstChild.nodeValue)

          
    return  sudfValue

def update_SD(ExternalCommnads):
    global art_smpl_io_map
    smpl_fix='<smp:sample xmlns:udf="http://genologics.com/ri/userdefined" xmlns:ri="http://genologics.com/ri" xmlns:file="http://genologics.com/ri/file" xmlns:smp="http://genologics.com/ri/sample"'
    artifacts=[]
    submittedSamples=[]
    art_smpl_io_map={}
    
    
    for num, row in enumerate(ExternalCommnads):
        artifacts.append(row[1])
        if row[1] not in art_smpl_io_map:
            art_smpl_io_map[row[1]]=(row[0],row[2],row[3])
    #
    # Get artifacts from Excel
    #    
    artifactsXML=api.getArtifacts(artifacts)
    pDOM=parseString(artifactsXML)
    for node in pDOM.getElementsByTagName("art:artifact"): #artifacts
        artifactLUID=node.getAttribute("limsid")
        submittedSamples=[]
        submittedSamplesLUID=node.getElementsByTagName("sample")[0].getAttribute("limsid")
        submittedSamples.append(submittedSamplesLUID)
        samplesXML=api.getSamples(submittedSamples)
        sDOM=parseString(samplesXML)
        for node in sDOM.getElementsByTagName("smp:sample"):
            submSampleLUID=node.getAttribute("limsid")
            sudfValue={}
            udfNodes= node.getElementsByTagName("udf:field")        
            for key in udfNodes:
                udfName = key.getAttribute( "name")
                sudfValue[udfName]=str(key.firstChild.nodeValue)

            (sSDMsg,sSDCMD,sSDRoute)=art_smpl_io_map[artifactLUID]
            try:
               sampleGroup=sudfValue["Sample Group"]
               if sSDCMD not in sampleGroup:
                   print(sampleGroup,sSDCMD)
                   new_value=sampleGroup+","+sSDCMD
                   smplXML=my_setUDF(node,"Sample Group",new_value,'')
                   sURI=BASE_URI+"samples/"+submSampleLUID
                   upXML='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                   fXML=smplXML.toxml().replace("<smp:sample",smpl_fix)
                   upXML+=fXML
                   #print(upXML)
                   r=api.PUT( upXML, sURI)
                   print(r)
            except Exception as e:
                log(e)
                sys.exit(111)
                
                
def routing_artifacts(art_smpl_io_map):
    routerLIMS=s4.clarity.routing.Router(LIMS)
    for artifactLUID in art_smpl_io_map:
        (sSDMsg,sSDCMD,sSDRoute)=art_smpl_io_map[artifactLUID]
        sSDRouting_WF=sSDRoute.split(":")[0]
        sSDRouting_PR=sSDRoute.split(":")[2]
        sSDRouting_Occurance=sSDRoute.split(":")[3]
        if "Aggregate" in sSDRouting_PR:
            sSDRouting_PR=sSDRoute.split(":")[1]
        
    
        routeStage=getStageURI( sSDRouting_WF, sSDRouting_PR, sSDRouting_Occurance)
        artifactLIMS=LIMS.artifact(artifactLUID)
        try:
            routerLIMS.assign(routeStage,artifactLIMS)
            sOUT=routerLIMS.commit()
            routerLIMS.clear()
            print("Routed ",artifactLUID,routeStage,sSDRouting_WF, sSDRouting_PR)
        except Exception as e:
            log(e)
            print(e)
            sys.exit(111) 
    
                
def getStageURI( wfName, stageName,sOccurance ):
    response = ""
    wURI = BASE_URI + "configuration/workflows"
    wXML = api.GET( wURI )
    wDOM = parseString( wXML)
    workflows = wDOM.getElementsByTagName( "workflow" )
    i=1
    for wf in workflows:
        name = wf.getAttribute( "name" )
        if name == wfName:
            wfURI = wf.getAttribute( "uri" )
            
            wfXML = api.GET( wfURI )
            
            wfDOM = parseString( wfXML)
            stages = wfDOM.getElementsByTagName( "stage" )
            for stage in stages:
                stagename = stage.getAttribute( "name" )
                #print(stagename,stageName,sOccurance, i)
                if (stagename == stageName):
                    if (int(sOccurance)==i):
                        response = stage.getAttribute( "uri" )
                    i+=1
    if response == "":
        msg = "Error: workflow / stage combination not found -- " + str(wfName) + " / " + str(stageName)+" step-occurance="+sOccurance
        logging.debug( msg )
        print (msg)
        sys.exit(3)
    return response

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
            except xml.dom.NotFoundErr as e:
                print( e )

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



'''

    START
    
'''



def main():

    global api
    global ARGS
    global TODAY, LOG,COLS,ROWS,DEBUG,args,user, psw, ExternalCommnads,LIMS,ApplicationCommands,art_smpl_io_map
    
    DEBUG = False

    LOG = []
    
    COLS = {}
    ROWS = []
    header={}
    ExternalCommnads={}
    ApplicationCommands={}
    art_smpl_io_map={}
    TODAY = ""


    
    args = setup_arguments()
    api = glsapiutil3x.glsapiutil3()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )  
    logging.basicConfig(level=logging.DEBUG)        
    user=args.username
    psw=args.password
    fileTemplate=args.template
    fileAttachmentPlace=args.attachLUID
    
    inputFormat=args.inputFormat
        
    setupGlobalsFromURI( args.stepURI )
    
    LIMS = s4.clarity.LIMS(BASE_URI, user, psw)  
    processUDFs=get_process_UDFs(ProcessID)
    try: 
        pLUID=processUDFs['Project ID']
        #print(pLUID)
    except:
        print("Error: Please provide the Project ID")
        logging.debug( "Error: Please provide the Project ID")
        sys.exit(111)
    
    
      


    TODAY = getToday()
    attFileLocation=getFileLocation(fileAttachmentPlace)
    #print (attFileLocation)
    status=False
    if  attFileLocation:
        fileTemplate=attFileLocation 
    if inputFormat=='excel':
        status = parseFile( fileTemplate )
    if inputFormat=='tab':
        status=parse_tab_File( fileTemplate )
    



    if len(ExternalCommnads):
        updateStatus=update_SD(ExternalCommnads)
        routing_artifacts(art_smpl_io_map)
        
    
    

    if status:
        if len(ROWS):
            processRows_generic(pLUID)
            if len(art_smpl_io_map):
                routing_artifacts(art_smpl_io_map)
                
    else:
        print( "The script was unable to parse the file: " + fileTemplate )

if __name__ == "__main__":
    main()
