
# Artifact routing from a template
# VERSION 3.3 - June 27 2017
# https://genologics.zendesk.com/hc/en-us/articles/115002768583
# updated version by Alexander Mazur
#

# Template Headers:
# UDF_NAME,UDF_VALUE,WF_NAME,STAGE_NAME
# Template udfs can be either analyte or processtype level

import sys
sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
from optparse import OptionParser
import logging
import glsapiutil
import xml.dom.minidom
from xml.dom.minidom import parseString



def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI
    global ProcessID

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"
    ProcessID=tokens[-1]

    if DEBUG is True:
        print (HOSTNAME)
        print (BASE_URI)


def parse_xml( xml ):

    try:
        dom = parseString( xml )
        return dom
    except:
        logging.debug( xml )
        sys.exit(3)

def getStageURI( wfName, stageName ):

    response = ""

    wURI = api.getBaseURI() + "configuration/workflows"
    wXML = api.GET( wURI )
    wDOM = parse_xml( wXML )
    workflows = wDOM.getElementsByTagName( "workflow" )
    for wf in workflows:
        name = wf.getAttribute( "name" )
        if name == wfName:
            wfURI = wf.getAttribute( "uri" )
            wfXML = api.GET( wfURI )
            wfDOM = parse_xml( wfXML )
            stages = wfDOM.getElementsByTagName( "stage" )
            for stage in stages:
                stagename = stage.getAttribute( "name" )
                if stagename == stageName:
                    response = stage.getAttribute( "uri" )
                    break
            break
    if response == "":
        msg = "Error: workflow / stage combination not found -- " + str(wfName) + " / " + str(stageName)
        logging.debug( msg )
    return response

def routeAnalytes( stage_options ):

    ## Step 1: Get the step XML
    processURI = args.stepURI + "/details"
    processXML = api.GET( processURI )
    processDOM = parseString( processXML )

    ANALYTES = set()
    for io in processDOM.getElementsByTagName( 'input-output-map' ):
        input_art = io.getElementsByTagName("input")[0].getAttribute("uri")
        if args.use_input_artifact:
            ANALYTES.add( input_art )
        else:
            output_art_type = io.getElementsByTagName("output")[0].getAttribute("type")
            if output_art_type == "Analyte":    # only analytes can be routed to different queues
                output_art = io.getElementsByTagName("output")[0].getAttribute("uri")
                ANALYTES.add( output_art )

    artifacts_to_route = {} # Set up the dictionary of destination stages
    if DEBUG:
        print (ANALYTES)

    ## Step 2: For each artifact, check against the UDF in the template file, add the analytes to the list of ones to be routed.
    artXML=api.getArtifacts( ANALYTES )
#    if DEBUG:
#        print (artXML)
    batch_artDOM = parse_xml(artXML  )
    for artifact in batch_artDOM.getElementsByTagName( "art:artifact" ):
        artifact_URI = artifact.getAttribute("uri").split('?')[0]
        if DEBUG:
            print(artifact_URI)
        #artifact_type = artifact.getElementsByTagName("type")[0].firstChild.data

        for UDF_NAME, template_UDF_VALUE, StageURI in stage_options:    # for the different UDFs & values in the template file:
            artifact_UDF_VALUE = api.getUDF( artifact, UDF_NAME ).lower()       # check if if matches an analyte UDF
            if not artifact_UDF_VALUE:
                artifact_UDF_VALUE='false'
            processtype_UDF_VALUE = api.getUDF( processDOM, UDF_NAME ).lower()  # check if if matcheseta processtype UDF
            template_UDF_VALUE = template_UDF_VALUE.lower()  
            if DEBUG:
                print (UDF_NAME, template_UDF_VALUE, StageURI )
                print (artifact_UDF_VALUE,processtype_UDF_VALUE,template_UDF_VALUE)                   
                # CASE INSENSITIVE

            # If either a step lvl UDF or artifact lvl UDF match a UDF in the template:
            if ( template_UDF_VALUE == artifact_UDF_VALUE ) or ( template_UDF_VALUE == processtype_UDF_VALUE ):
                if StageURI not in artifacts_to_route:
                    artifacts_to_route[ StageURI ] = []
                artifacts_to_route[ StageURI ].append( artifact_URI )

    if len( artifacts_to_route ) == 0:
        msg = "INFO: No derived samples were routed."
        logging.debug( msg )
        sys.exit(0)

    def pack_and_send( stageURI, a_ToGo ):
        ## Build and POST the routing message
        rXML = '<rt:routing xmlns:rt="http://genologics.com/ri/routing">'
        rXML = rXML + '<assign stage-uri="' + stageURI + '">'
        for uri in a_ToGo:
            rXML = rXML + '<artifact uri="' + uri + '"/>'
        rXML = rXML + '</assign>'
        rXML = rXML + '</rt:routing>'
        response = api.POST( rXML, api.getBaseURI() + "route/artifacts/" )
        return response

    # Step 3: Send separate routing messages for each destination stage
    for stage, artifacts in artifacts_to_route.items():
        r = pack_and_send( stage, artifacts )
        if len( parseString( r ).getElementsByTagName( "rt:routing" ) ) > 0:
            msg = str( len(artifacts) ) + " samples were added to the " + stage + " step. "
        else:
            msg = r
        logging.debug( msg )

def routeAnalytes_from_containers( stage_options ):
    global artifacts_to_route

    ## Step 1: Get the step XML
    processURI = args.stepURI + "/details"
    processXML = api.GET( processURI )
    processDOM = parseString( processXML )

    #ANALYTES = set()
    

    artifacts_to_route = {} # Set up the dictionary of destination stages
    if DEBUG:
        print (allArtifacts)

    ## Step 2: For each artifact, check against the UDF in the template file, add the analytes to the list of ones to be routed.
    artXML=api.getArtifacts( allArtifacts )
#    if DEBUG:
#        print (artXML)
    batch_artDOM = parse_xml(artXML  )
    for artifact in batch_artDOM.getElementsByTagName( "art:artifact" ):
        artifact_URI = artifact.getAttribute("uri").split('?')[0]
        if DEBUG:
            print(artifact_URI)
        #artifact_type = artifact.getElementsByTagName("type")[0].firstChild.data

        for UDF_NAME, template_UDF_VALUE, StageURI in stage_options:    # for the different UDFs & values in the template file:
            artifact_UDF_VALUE = api.getUDF( artifact, UDF_NAME ).lower()       # check if if matches an analyte UDF
            if not artifact_UDF_VALUE:
                artifact_UDF_VALUE='false'
            processtype_UDF_VALUE = api.getUDF( processDOM, UDF_NAME ).lower()  # check if if matcheseta processtype UDF
            template_UDF_VALUE = template_UDF_VALUE.lower()  
            if DEBUG:
                print (UDF_NAME, template_UDF_VALUE, StageURI )
                print (artifact_UDF_VALUE,processtype_UDF_VALUE,template_UDF_VALUE)                   
                # CASE INSENSITIVE

            # If either a step lvl UDF or artifact lvl UDF match a UDF in the template:
            if ( template_UDF_VALUE == artifact_UDF_VALUE ) or ( template_UDF_VALUE == processtype_UDF_VALUE ):
                if StageURI not in artifacts_to_route:
                    artifacts_to_route[ StageURI ] = []
                artifacts_to_route[ StageURI ].append( artifact_URI )

    if len( artifacts_to_route ) == 0:
        msg = "INFO: No derived samples were routed."
        logging.debug( msg )
        sys.exit(0)

    def pack_and_send( stageURI, a_ToGo ):
        ## Build and POST the routing message
        rXML = '<rt:routing xmlns:rt="http://genologics.com/ri/routing">'
        rXML = rXML + '<assign stage-uri="' + stageURI + '">'
        for uri in a_ToGo:
            rXML = rXML + '<artifact uri="' + uri + '"/>'
        rXML = rXML + '</assign>'
        rXML = rXML + '</rt:routing>'
        response = api.POST( rXML, api.getBaseURI() + "route/artifacts/" )
        return response

    # Step 3: Send separate routing messages for each destination stage
    for stage, artifacts in artifacts_to_route.items():
        r = pack_and_send( stage, artifacts )
        if len( parseString( r ).getElementsByTagName( "rt:routing" ) ) > 0:
            msg = str( len(artifacts) ) + " samples were added to the " + stage + " step. "
        else:
            msg = r
        logging.debug( msg )

def routeAnalytes_generic( ArtifactsLUID, StageURI ):
    global artifacts_to_route
    
    artifacts_to_route={}

    for artifact, artifact_URI in ArtifactsLUID.items():
        #artifact_URI = artifact.getAttribute("uri").split('?')[0]

        if StageURI not in artifacts_to_route:
            artifacts_to_route[ StageURI ] = []
        artifacts_to_route[ StageURI ].append( artifact_URI )

    if len( artifacts_to_route ) == 0:
        msg = "INFO: No derived samples were routed."
        logging.debug( msg )
        sys.exit(0)

    def pack_and_send( stageURI, a_ToGo ):
        ## Build and POST the routing message
        rXML = '<rt:routing xmlns:rt="http://genologics.com/ri/routing">'
        rXML = rXML + '<assign stage-uri="' + stageURI + '">'
        for uri in a_ToGo:
            rXML = rXML + '<artifact uri="' + uri + '"/>'
        rXML = rXML + '</assign>'
        rXML = rXML + '</rt:routing>'
        response = api.POST( rXML, api.getBaseURI() + "route/artifacts/" )
        return response

    # Step 3: Send separate routing messages for each destination stage
    for stage, artifacts in artifacts_to_route.items():
        r = pack_and_send( stage, artifacts )
        if len( parseString( r ).getElementsByTagName( "rt:routing" ) ) > 0:
            msg = str( len(artifacts) ) + " samples were added to the " + stage + " step. "
        else:
            msg = r
        logging.debug( msg )



def transform_template( templateCSV ):

    # Look up the stage URI for the different destination stages in the template
    stage_options = []
    if DEBUG:
        print (templateCSV )
    for line in templateCSV:
        if 'UDF_NAME' not in line and 'UDF_VALUE' not in line: # ignore the column headers
            if line == "" or line == "\n":
                pass # just has a blank line in the template -- ignore line
            else:
                try:
                    UDF_NAME, UDF_VALUE, WF_NAME, STAGE_NAME = line.strip().split(',')
                    if DEBUG:
                        print (UDF_NAME, UDF_VALUE, WF_NAME, STAGE_NAME)
                except:
                    logging.debug( 'ERROR: Template is not formatted properly. Trying to parse: ' + str( line ) )
                    sys.exit(4)
                StageURI = getStageURI( WF_NAME, STAGE_NAME )   # search for StageURI using API
                logging.debug([ UDF_NAME, UDF_VALUE, StageURI ])
                stage_options.append([ UDF_NAME, UDF_VALUE, StageURI ])
    return stage_options

def route_from_template():
    global stage_options

    # If a --template_string parameter was entered, it will be used, otherwise the script expects a --template limsid to download
    if args.template_string:
        templateCSV = args.template_string.split('\\n') # split -r parameter on newline char
        
    else:
        raw = open( args.template, "r")
        templateCSV = raw.readlines()
        if len( templateCSV ) == 1:
            templateCSV = templateCSV[0].split('\r')
    stage_options = transform_template( templateCSV )
    if DEBUG:
        print (stage_options)

    #routeAnalytes( stage_options )
    routeAnalytes_from_containers( stage_options )

def setupArguments():
    Parser = OptionParser()

    # required parameters:
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-l', "--log", action='store', dest='log')

    Parser.add_option('-t', "--template", action='store', dest='template')
    # or
    Parser.add_option('-r', "--template_string", action='store', dest='template_string', default=False)

    # optional parameters:
    Parser.add_option("-i", "--input", action="store_true", dest="use_input_artifact", default=False, help="uses input artifact UDFs")             # input or output artifact - Default is output
    Parser.add_option('-a', "--action", action='store', dest='action', default='')
    Parser.add_option('-d', "--debug", action='store', dest='debug', default='')

    return Parser.parse_args()[0]

#################
#    A.M.
#
#################
def get_placed_containers(stepURI):
    global scLUIDs
    processURI = stepURI + "/placements"
    processXML = api.GET( processURI )
    rDOM = parseString( processXML )
    nodes=rDOM.getElementsByTagName( "selected-containers" )
    scNodes = nodes[0].getElementsByTagName( "container")
    scLUIDs=[]
    for sc in scNodes:
        scURI = sc.getAttribute( "uri")
        scLUID = scURI.split( "/" )[-1]
        scLUIDs.append( scLUID )
        update_container(scURI)

    return scLUIDs

def update_container(scURI):
    global containerArtifacts,leftOverArtifacts
    result=""
    cntLeftOvers=[]
    
    containerXML = api.GET( scURI )
    rDOM = parseString( containerXML)
    
    
    for node in rDOM.getElementsByTagName("con:container"):
        loContainerLUID = node.getAttribute("limsid")
        loContainerURI = node.getAttribute("uri")
        loContainerName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        loContainerOccupiedWells=node.getElementsByTagName('occupied-wells')[0].firstChild.nodeValue
        containerArtifacts=[] 
        for placement in node.getElementsByTagName("placement"):
            placementLUID=placement.getAttribute("limsid")
            placementURI=placement.getAttribute("uri")
            
            if placementLUID not in containerArtifacts:
                containerArtifacts.append(placementLUID) 
                allArtifacts.append(placementLUID)
        #print ("all",allArtifacts,"container",containerArtifacts)
            
        artsXML=api.getArtifacts(containerArtifacts) 
        
        
        cntLeftOvers=getUDFs( artsXML, "Go To Next Step","True" )
        if DEBUG:
            print (leftOverArtifacts,loContainerLUID,loContainerName,loContainerOccupiedWells)

        if len(cntLeftOvers)>0 and (int(loContainerOccupiedWells)==96):
            leftOverArtifacts=cntLeftOvers
            print (leftOverArtifacts,"Left Over samples detected in container = "+loContainerLUID+"\t"+loContainerName+"\t"+loContainerOccupiedWells+"\t"+loContainerURI)
            

            for artID in cntLeftOvers:
                r=update_artifact_post(artID, "Go To Next Step", "False","Boolean")
                print ("artifact "+artID+" UDF was updated to false")
                if DEBUG:
                    print(r)
                    
 
                            
 

    return 

def my_setUDF( DOM, udfname, udfvalue,udftype ):
    
    if (udftype ==""):
        udftype="String"

    #if DEBUG > 2: print( DOM.toprettyxml() )

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

def getUDFs( sXML, udfname,udfValue ):

    response = []
    DOM=parseString(sXML)
    rDOM=DOM.getElementsByTagName( "art:artifact")
    for node in rDOM:
        artID=node.getAttribute("limsid")
        elements = node.getElementsByTagName( "udf:field" )
        for udf in elements:
            temp = udf.getAttribute( "name" )
            if (temp == udfname) and (udf.firstChild.nodeValue==udfValue.lower()):
                if DEBUG:
                    print (artID,udf.firstChild.nodeValue,udfValue.lower())
                response.append(artID)
            

    return response

def update_artifact_post(artID, udfName,udfValue, udfType):
    
    sURI=BASE_URI+'artifacts/'+artID
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)
    
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    #print(DOM.toxml())
    r = api.PUT(DOM.toxml(),sURI)
    return r

def pack_and_unassign( udfName,udfValue, artToUnassign ):
        ## Build and POST the routing message
    if DEBUG:
        print (stage_options)    
    for UDF_NAME, template_UDF_VALUE, StageURI in stage_options:
        if (UDF_NAME==udfName) and (template_UDF_VALUE.lower()==udfValue.lower()):
            break    
        
    rXML = '<rt:routing xmlns:rt="http://genologics.com/ri/routing">'
    rXML = rXML + '<unassign stage-uri="' + StageURI + '">'
    for artID in artToUnassign:
        sURI=BASE_URI+'artifacts/'+artID
        rXML = rXML + '<artifact uri="' + sURI+ '"/>'
    rXML = rXML + '</unassign>'
    rXML = rXML + '</rt:routing>'
    if DEBUG:
        print (rXML)
    response = api.POST( rXML, api.getBaseURI() + "route/artifacts/" )
    return response
def unassign( artToUnassign ):
    uq={}
    for key in artToUnassign:
        if artToUnassign[key] not in uq:
            uq[artToUnassign[key]]=1
            

    for node in uq:
        StageURI=node    
        rXML = '<rt:routing xmlns:rt="http://genologics.com/ri/routing">'
        rXML = rXML + '<unassign stage-uri="' + StageURI + '">'
        for artID, stageURI in artToUnassign.items():
            if stageURI==StageURI:
                sURI=BASE_URI+'artifacts/'+artID
                rXML = rXML + '<artifact uri="' + sURI+ '"/>'
        rXML = rXML + '</unassign>'
        rXML = rXML + '</rt:routing>'
        if DEBUG=='1':
            print (rXML)
        response = api.POST( rXML, api.getBaseURI() + "route/artifacts/" )
    return response


def get_settings_from_stepUDF(processID):
    sURI=BASE_URI+'processes/'+processID
    r = api.GET(sURI)
    rDOM = parseString( r )
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")
        #print (udfName)
        try:
            udfValue=str(key.firstChild.nodeValue)
        except:
            udfValue=""
        sudfValue[udfName]=udfValue
    return sudfValue


def get_containerID_by_name(sContainerName, sURI):
    if not sURI:
        sURI=BASE_URI+'containers'
    r = api.GET(sURI)
    rDOM = parseString( r )
    
    #print (sContainerName)     
     
    for key in rDOM.getElementsByTagName("container"):
        containerLUID = key.getAttribute( "limsid")
        containerURI = key.getAttribute( "uri")
        containerName= key.getElementsByTagName("name")[0].firstChild.data
        #print (sContainerName,containerName)
        if sContainerName.upper() in containerName.upper():
            containersList[containerLUID]=containerName
    if rDOM.getElementsByTagName("next-page"):
        nextPage=rDOM.getElementsByTagName("next-page")[0].getAttribute( "uri")
        get_containerID_by_name(sContainerName, nextPage)
        
    
    return #containerValue
def get_samples_by_carrier_barcode(sCarrierBarcode, sURI):
    if not sURI:
        sURI=BASE_URI+'samples?udf.Carrier%20Barcode='+sCarrierBarcode
    sXML = api.GET(sURI)
    #print (sXML)
    '''
    Get samples 
    '''
    sampleURIs=get_samples_array(sXML)
    #print(sampleURIs)
    bXML=prepare_samples_batch(sampleURIs)
    r=retrieve_samples(bXML)
    #print (r)
    
    

    
    
    
    rDOM = parseString( r )
    
    #print (sContainerName)     
    sudfValue={} 
    for key in rDOM.getElementsByTagName("smp:sample"):
        sampleLUID = key.getAttribute( "limsid")
        sampleURI = key.getAttribute( "uri")
        sampleName= key.getElementsByTagName("name")[0].firstChild.data
        rootArtifactURI=key.getElementsByTagName("artifact")[0].getAttribute('uri').split('?')[0]
        rootArtifactLUID=key.getElementsByTagName("artifact")[0].getAttribute('limsid')
        udfNodes= key.getElementsByTagName("udf:field")
        
        if rootArtifactLUID not in ArtifactsLUID:
            ArtifactsLUID[rootArtifactLUID]=rootArtifactURI
            
             
               
        for node in udfNodes:
            udfName = node.getAttribute( "name")
            #print (udfName)
            try:
                udfValue=str(node.firstChild.nodeValue)
            except:
                udfValue=""
            sudfValue[udfName]=udfValue
        
        #print (sContainerName,containerName)
        sBarcode=sudfValue["Barcode"]
        if sBarcode not in SamplesList:
            SamplesList[sBarcode]=(sampleLUID,sampleName,rootArtifactURI)
            
    if rDOM.getElementsByTagName("next-page"):
        nextPage=rDOM.getElementsByTagName("next-page")[0].getAttribute( "uri")
        get_samples_by_carrier_barcode(sCarrierBarcode, nextPage)
        
    
    return #containerValue

def get_samples_array(sXML):
    #global sampleURIs

    sampleURIs=[]
    rDOM = parseString(sXML )
    print(len(rDOM.getElementsByTagName('sample')))
    for key in rDOM.getElementsByTagName('sample'):
        sampleLUID = key.getAttribute( "limsid")
        sampleURI = key.getAttribute( "uri")
        #print(sampleLUID)
        if sampleURI not in sampleURIs:
           sampleURIs.append( sampleURI)
        
    return sampleURIs


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
    #r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    response = api.POST( sXML, sURI )
    #print (r.content)
    #rDOM = parseString( r.content )    
    return response


def update_process_udf(processLUID, udfName,udfValue, udfType):
    sURI=BASE_URI+'processes/'+processLUID
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    r = api.PUT(DOM.toxml(),sURI)
    return r

def get_artifacts_from_container(containerLUID):
        ## Step 1: Get the step XML
    containerURI = BASE_URI + "containers/"+containerLUID
    containerXML = api.GET( containerURI )
    containerDOM = parseString( containerXML )

    ArtifactsLUID={}
    for artifact in containerDOM.getElementsByTagName( 'placement' ):
        artURI = artifact.getAttribute("uri")
        artLUID = artifact.getAttribute("limsid")
        if artLUID not in ArtifactsLUID:
            ArtifactsLUID[artLUID]=artURI 
        #print (artLUID,artURI)
    return ArtifactsLUID    

def prepare_artifacts_batch(ArtifactsLUID):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for key in ArtifactsLUID:
        art=ArtifactsLUID[key]
        scURI = BASE_URI+'artifacts/'+key
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

def parse_artifact_status(artXML):
    ArtifactWF={}
    #print(artXML)
    containerDOM = parseString( artXML)
    
    for num, artifact in enumerate(containerDOM.getElementsByTagName( "art:artifact" )):
        artLUID=artifact.getAttribute("limsid")
        artName=artifact.getElementsByTagName("name")[0].firstChild.data
        
        wfList=[]
        try:
            workFlowStages= artifact.getElementsByTagName( "workflow-stage" )
            for num,wfStage in enumerate(workFlowStages):
                wfStatus = wfStage.getAttribute("status")
                wfName = wfStage.getAttribute("name")
                wfURI = wfStage.getAttribute("uri")
                #print(num,wfStatus,wfName,wfURI)
                wfList.append([wfStatus,wfName,wfURI])
            

        except Exception,e:
            print(e)    
        if artLUID not in ArtifactWF:
            ArtifactWF[artLUID]=wfList            
    return ArtifactWF

def check_artifacts_status(artWF_hash):
    uq={}
    removeArtifacts={}
    for key in sorted(artWF_hash):
        node =artWF_hash[key]
        uq={}
        for wfStatus,wfName,wfURI in node:
            uq[wfURI]=wfStatus
        #print (key)
        for kk in uq:
            if uq[kk] not in conditions:
                removeArtifacts[key]=kk
                #print(kk,uq[kk])        
            
    
    return removeArtifacts

'''

START

'''

def main():
    global args
    args = setupArguments()
    logging.basicConfig(filename=args.log,level=logging.DEBUG)


    global api,sutil,  allArtifacts,leftOverArtifacts, action, DEBUG,conditions,containersList,SamplesList,ArtifactsLUID
    conditions = ["REMOVED", "FAILED", "COMPLETE", "SKIPPED"]
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    DEBUG = args.debug
    DEBUG=False
    setupGlobalsFromURI( args.stepURI )
    
    action=args.action
    allArtifacts=[]
    leftOverArtifacts=[]
    containersList={}
    SamplesList={}
    ArtifactsLUID={}
    
    stepUDFs=get_settings_from_stepUDF(ProcessID)
    #print(stepUDFs)
    if stepUDFs['Carrier Barcode']:
        #get_containerID_by_name(stepUDFs['Container Name'],'')
        
        get_samples_by_carrier_barcode(stepUDFs['Carrier Barcode'], '')
        #print (SamplesList)
        
        #print(containersList)
        ss=''
        #if action!="route":
        if len(SamplesList)>0:
            ss="Barcode\tSample Name\n"
        for key in sorted(SamplesList):
            (sampleLUID,sampleName,rootArtifactURI)=SamplesList[key]
            ss +=key +"\t"+sampleName+"\n"
        
        rr=update_process_udf(ProcessID, "Comments",ss, '')
        print ("Done:\t"+str(len(SamplesList)) +" results found")    
        
    #exit()
    if action=="route":
        try:
            #containerLUID=stepUDFs['Container ID']
            routingWorkflow,routingStage= stepUDFs['Routing To Workflow:Stage'].split(':')
            routingStageURI=  getStageURI( routingWorkflow, routingStage )
            #print (routingStageURI)
            
            
            
            
            #ArtifactsLUID=get_artifacts_from_container(containerLUID)
            
            if DEBUG =='1':
                print (routingStageURI,routingWorkflow, routingStage)
                print(ArtifactsLUID)
            riArtXML=prepare_artifacts_batch(ArtifactsLUID)
            #print(riArtXML)
            artXML=retrieve_artifacts(riArtXML)
            #print(artXML)
            artWF_hash=parse_artifact_status(artXML)
            #print(artWF_hash)
            #exit()
            ArtifactsToUnassign=check_artifacts_status(artWF_hash)
            if len(ArtifactsToUnassign)>0:
                unassign( ArtifactsToUnassign)
            
            if DEBUG=='1':
                for key in sorted(artWF_hash):
                    print(key,artWF_hash[key])
                
                
                for key in removeArtifacts:
                    print(key,removeArtifacts[key])
                
            
            routeAnalytes_generic( ArtifactsLUID, routingStageURI )

        except Exception, e:
            print(e)
                    
if __name__ == "__main__":
    main()
