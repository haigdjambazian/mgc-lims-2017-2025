__author__ = 'dcrawford'    # dcrawford@illumina.com
# Artifact routing from a template
# VERSION 3.3 - June 27 2017
# https://genologics.zendesk.com/hc/en-us/articles/115002768583
# updated version by Alexander Mazur
#

# Template Headers:
# UDF_NAME,UDF_VALUE,WF_NAME,STAGE_NAME
# Template udfs can be either analyte or processtype level

import sys
from optparse import OptionParser
import logging
import glsapiutil
import xml.dom.minidom
from xml.dom.minidom import parseString

DEBUG = False

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


def main():
    global args
    args = setupArguments()
    logging.basicConfig(filename=args.log,level=logging.DEBUG)

    global api,sutil, BASE_URI, allArtifacts,leftOverArtifacts
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    BASE_URI=api.getBaseURI()
    allArtifacts=[]
    leftOverArtifacts=[]
    
    get_placed_containers(args.stepURI)
 
    route_from_template()
    '''
     Unassign Left Over Samples from the Queue Extra Plate
    '''
    if DEBUG:
        print (allArtifacts)
        print (cntLeftOvers)
        print (leftOverArtifacts) 
    response=pack_and_unassign( "Go To Next Step","True", leftOverArtifacts)
    if DEBUG:
        print (response)
    
if __name__ == "__main__":
    main()
