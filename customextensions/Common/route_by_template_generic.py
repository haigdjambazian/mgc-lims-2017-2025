'''
 Root artifact routing from a template
 https://genologics.zendesk.com/hc/en-us/articles/115002768583

    Alexander MAzur    e-mail: alexander.mazur@gmail.com
    update 2019_05_01:
        - added -o file attachemnt places LUID
        - unassign function to remove root artifact from last step to avoid duplication
    update 2019_03_22:
        - template file format ==> Sample_Name,Project_Name,WF_NAME,STAGE_NAME

'''
__author__ = "Alexander MAzur"    # alexander.mazur@gmail.com
import sys,os, socket
sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
from optparse import OptionParser
import logging
import glsapiutil
from xml.dom.minidom import parseString



def parse_xml( xml ):

    try:
        dom = parseString( xml )
        return dom
    except:
        logging.debug( xml )
        print(xml)
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
        print (msg)
        sys.exit(3)
    return response

def routeRootArtifacts( artifacts_to_route ):


    if len( artifacts_to_route ) == 0:
        msg = "INFO: No derived samples were routed."
        logging.debug( msg )
        print(msg)
        sys.exit(0)

    def pack_and_send( stageURI, a_ToGo ):
        ## Build and POST the routing message
        rXML = '<rt:routing xmlns:rt="http://genologics.com/ri/routing">'
        rXML = rXML + '<assign stage-uri="' + stageURI + '">'
        for uri in a_ToGo:
            #print(uri[0])
            rXML = rXML + '<artifact uri="' + uri[0] + '"/>'
        rXML = rXML + '</assign>'
        rXML = rXML + '</rt:routing>'
        #print(rXML)
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
        print(msg)


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

    ## Step 2: For each artifact, check against the UDF in the template file, add the analytes to the list of ones to be routed.
    batch_artDOM = parse_xml( api.getArtifacts( ANALYTES ) )
    for artifact in batch_artDOM.getElementsByTagName( "art:artifact" ):
        artifact_URI = artifact.getAttribute("uri").split('?')[0]
        #artifact_type = artifact.getElementsByTagName("type")[0].firstChild.data

        for UDF_NAME, template_UDF_VALUE, StageURI in stage_options:    # for the different UDFs & values in the template file:
            artifact_UDF_VALUE = api.getUDF( artifact, UDF_NAME ).lower()       # check if if matches an analyte UDF
            processtype_UDF_VALUE = api.getUDF( processDOM, UDF_NAME ).lower()  # check if if matcheseta processtype UDF
            template_UDF_VALUE = template_UDF_VALUE.lower()                     # CASE INSENSITIVE

            # If either a step lvl UDF or artifact lvl UDF match a UDF in the template:
            if ( template_UDF_VALUE == artifact_UDF_VALUE ) or ( template_UDF_VALUE == processtype_UDF_VALUE ):
                if StageURI not in artifacts_to_route:
                    artifacts_to_route[ StageURI ] = []
                artifacts_to_route[ StageURI ].append( artifact_URI )

    if len( artifacts_to_route ) == 0:
        msg = "INFO: No derived samples were routed."
        logging.debug( msg )
        print(msg)
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
        print(msg)

def my_transform_template( templateCSV ):

    # Look up the stage URI for the different destination stages in the template
    # Sample Name,Well pos,gDNA RackID,DstPlate,DstCoord,Workflow Name,Step Name
    #
    stage_options = []
    artifacts_to_route={}
    for line in templateCSV:
        if 'Sample Name' not in line and 'Workflow Name' not in line: # ignore the column headers
            if line == "" or line == "\n":
                pass # just has a blank line in the template -- ignore line
            else:
                try:
                    #UDF_NAME, UDF_VALUE, WF_NAME, STAGE_NAME = line.strip().split(',')
                    #Sample_Name,Well_pos,gDNA_RackID,DstPlate,DstCoord,WF_NAME,STAGE_NAME=line.strip().split(',')
                    # 2019_03_22
                    
                    Sample_Name,Project_Name,WF_NAME,STAGE_NAME=line.strip().split(',')
                except:
                    logging.debug( 'ERROR: Template is not formatted properly. Trying to parse: ' + str( line ) )
                    print('ERROR: Template is not formatted properly. Trying to parse: ' + str( line ) )
                    sys.exit(4)
                StageURI = getStageURI( WF_NAME, STAGE_NAME )   # search for StageURI using API
                
                (projectLUID,projectURI)=get_project_luid(Project_Name)
                arts_hash=get_root_artifact(Sample_Name,projectLUID)
                if DEBUG:
                    print(Sample_Name,arts_hash,Project_Name,projectLUID,projectURI,WF_NAME,STAGE_NAME,StageURI)
                if len(arts_hash)>1:
                    print ("Error: multiple root artifacts detected for:\t"+Sample_Name)
                elif len(arts_hash)==0 :
                    print ("Error: cant find in the LIMS:\t"+Sample_Name)
                else:
                    #print(arts_hash.keys(),arts_hash.values())
                    #logging.debug([ Sample_Name, arts_hash, StageURI ])
                    stage_options.append([ Sample_Name, arts_hash, StageURI ])
                    if StageURI not in artifacts_to_route:
                        artifacts_to_route[ StageURI ] = []
                    artifacts_to_route[ StageURI ].append(arts_hash.values() )
    return stage_options,artifacts_to_route

def get_root_artifact(Sample_Name,projectLUID):
    sURI=api.getBaseURI() + "artifacts?sample-name=" +Sample_Name
    artsXML=api.GET( sURI)
    artDOM = parseString( artsXML )
    artifacts={}
    for node in artDOM.getElementsByTagName('artifact'):
        artLUID=node.getAttribute('limsid')
        artURI=node.getAttribute('uri')
        '''
        added projectLUID
        
        '''
        if ('PA1' in artLUID) and (artLUID not in artifacts) and (projectLUID in artLUID):
            artifacts[artLUID]=artURI
            
    return artifacts

def get_project_luid(Project_Name):
    sURI=api.getBaseURI() + "projects?name=" +Project_Name
    artsXML=api.GET( sURI)
    artDOM = parseString( artsXML )
    projects={}
    for node in artDOM.getElementsByTagName('project'):
        projectLUID=node.getAttribute('limsid')
        projectURI=node.getAttribute('uri')
           
    return projectLUID,projectURI



def multi_pack_and_send( stageURI, artifacts ):
    ## Build and POST the routing message
    rXML = '<rt:routing xmlns:rt="http://genologics.com/ri/routing">'
    rXML = rXML + '<assign stage-uri="' + stageURI + '">'
    for key in artifacts:
        uri=artifacts[key]
        rXML = rXML + '<artifact uri="' + uri + '"/>'
    rXML = rXML + '</assign>'
    rXML = rXML + '</rt:routing>'
    print(rXML)
    #response = api.POST( rXML, api.getBaseURI() + "route/artifacts/" )
    return #response        
    

def route_from_template(sExcelFile):

    raw = open( sExcelFile, "r")
    templateCSV = raw.readlines()
    if len( templateCSV ) == 1:
        templateCSV = templateCSV[0].split('\r')
    stage_options,artifacts_to_route = my_transform_template( templateCSV )
    #print(artifacts_to_route)
    
    
    #routeAnalytes( stage_options )
    
    return stage_options,artifacts_to_route

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
    Parser.add_option('-o', "--outputLUIDs", action='store', dest='outputLUIDs', default=False)
    

    # optional parameters:
    Parser.add_option("-i", "--input", action="store_true", dest="use_input_artifact", default=False, help="uses input artifact UDFs")             # input or output artifact - Default is output

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
    
    fileLocation=''

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

def prepare_artifacts_batch(rootArtifactsURI):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    for key in rootArtifactsURI:
        for node in rootArtifactsURI[key]:
            scURI = node[0]
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


def main():

    global args,DEBUG,outputLUIDs,conditions
    conditions = ["REMOVED", "FAILED", "COMPLETE", "SKIPPED"]
    DEBUG = False
    args = setupArguments()
    
    setupGlobalsFromURI(args.stepURI)
    global api,artifacts_to_route 
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )  
    logging.basicConfig(filename=args.log,level=logging.DEBUG)      

    outputLUIDs=args.outputLUIDs
    rfLUIDs=outputLUIDs.split(" ")
    
    sExcelFile=getFileLocation(rfLUIDs[0])
    if not sExcelFile:
        print("Error: The CSV file is not attached")
        logging.debug( "Error: The CSV file is not attached")
        exit(111)
    else:
        if DEBUG is True:
            print("CSV file location:\t"+sExcelFile)
        
    


    stage_options,artifacts_to_route=route_from_template(sExcelFile)
    riXML=prepare_artifacts_batch(artifacts_to_route)
    artXML=retrieve_artifacts(riXML)

    artWF_hash=parse_artifact_status(artXML)

    ArtifactsToUnassign=check_artifacts_status(artWF_hash)

    if len(ArtifactsToUnassign)>0:
        unassign( ArtifactsToUnassign)     
    

    routeRootArtifacts( artifacts_to_route )

if __name__ == "__main__":
    main()
