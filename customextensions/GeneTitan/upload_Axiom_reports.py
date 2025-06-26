'''
Created on March 27, 2018


@author: Alexander Mazur, alexander.mazur@gmail.com

    updated:    
        - UDF fields write (Feb. 4, 2018)

python v.2.7
'''
__author__ = 'Alexander Mazur'



DEBUG = False
DEBUG_placement_file = "controls_test_july25.csv"   # local file for testing
samples_controls_placement_file= "/opt/gls/clarity/ai/temp/axiom_template.csv"
temp_dir="/opt/gls/clarity/ai/temp/"
import sys,os, socket

sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files

from optparse import OptionParser
import xml.dom.minidom
from xml.dom.minidom import parseString
import collections
import urllib
#import requests
import glsapiutil   # 2106 version , needed for API calls
import glsfileutil  # needed to download file
import xml.etree.ElementTree as ET

uploads_hash={'ARTIFACT':"artifacts",'PROJECT':"projects",'SAMPLE':"samples",'PROCESS':"processes", 'UDF':"UDF"}
strFind= 'ri/artifact"'
strReplace='ri/artifact" xmlns:udf="http://genologics.com/ri/userdefined" xmlns:file="http://genologics.com/ri/file" '
axiom_QC_udfs=['Sample Filename', 'QC', 'DQC', 'QC Call Rate', 'QC Het Rate', 'QC Computed Gender', 'Affymetrix Plate Barcode', 'Affymetrix Plate Peg Wellposition', 'Average Call Rate Passing Samples', '% of passing samples']
QC_status={'PASS':"PASSED", 'FAIL':"FAILED"}

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
    Parser.add_option('-f', "--file1", action='store', dest='AxiomSummaryQC file ')
    Parser.add_option('-l', "--attachLUIDs", action='store', dest='attachLUIDs')
    Parser.add_option('-a', "--activeStep", action='store', dest='activeStep')
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


def get_axiom_reports_from_file(sReportKind):
    global axiomResultsTab,axiomTabFile,splitResultsCSV
    
    axiomResultsTab=[]
    if DEBUG>2:
        raw = open( DEBUG_placement_file, "r")
        axiomTabFile = raw.readlines()
    else:
        template_from_path = args.template
        if template_from_path:
            raw = open( template_from_path, "r")
            axiomTabFile = raw.readlines()
        else:
            if (sReportKind=='project'):
                axiomTabFile = downloadfile( FileReportLUIDs[1])
            else:
                axiomTabFile = downloadfile( FileReportLUIDs[0] )
    if len( axiomTabFile ) == 1:
        print (axiomTabFile)
        axiomTabFile = axiomTabFile[0].split("\r")

    for x in axiomTabFile:
        if len(x.split("\t"))>1:
            x=x.strip("\r\n")
            #print (x)
            axiomResultsTab.append(x.strip("\n").split("\t"))
    #axiomResultsTab = [ x.strip("\r\n").split("\t") for x in axiomResultsTab ]


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


def map_artifacts_io( stepURI ):
    global ArtifactsLUID
    ArtifactsLUID={}

    details = parse_xml( api.GET( stepURI + "/details" ))
    #print api.GET( stepURI + "/details" )
    for io in details.getElementsByTagName("input-output-map"):
        inputartURI = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        '''
        For activeProcess OUTPUT artifacts have been used
        '''
        
        outputartURI = io.getElementsByTagName("output")[0].getAttribute("uri")
        outputartLUID = io.getElementsByTagName("output")[0].getAttribute("limsid")        
        
        if outputartLUID not in ArtifactsLUID:
            ArtifactsLUID[outputartLUID]=""
    return 

def parse_xml( xml ):
    try:
        dom = parseString( xml )
        return dom
    except:
        print xml
        sys.exit(1)
        
        
def prepare_artifacts_batch(artifactsLUID):
    #global BASE_URI
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in artifactsLUID:
        scURI = BASE_URI+'artifacts/'+art
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        

    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_artifacts(sXML):
    sURI=BASE_URI+'artifacts/batch/retrieve'
    headers = {'Content-Type': 'application/xml'}
    r = api.POST(sXML,sURI) 
    return r
    
def get_info_from_artifacts(sXML): 
    pDOM = parseString( sXML )   
    for artifact in pDOM.getElementsByTagName("art:artifact"):
        artName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        artLUID = artifact.getAttribute( "limsid" )
        if artLUID in ArtifactsLUID:
            ArtifactsLUID[artLUID]=artName

    return


def create_meta(sXML):
    for key in ArtifactsLUID:
        sFileName=ArtifactsLUID[key]+"_"+key+".CEL"
        for line in axiomResultsTab:
            if line[0].upper() == sFileName.upper():
                r=update_QC_flag(key, line[1])
                if DEBUG>2:
                    print(r)                
                print (key+"=\t"+line[1])
                for i in range(1, len(line)):
                        
                    update_artifact_post(key, axiom_QC_udfs[i],line[i], "")
    

def post_results_data_2_lims(): 
    sURI = BASE_URI+'files'

    #sContentLocation="sftp://bravotestapp.genome.mcgill.ca/data/glsftp"
    #sAttachedTo=BASE_URI+'samples'
    sContentLocation=sftpHOSTNAME+"/data/glsftp"
    sOriginalLocation=''
    for line in axiomResultsTab:
        # post one record from TAB file        
        lXML = []
        if line[1] in uploads_hash:
            attType=uploads_hash[line[1]]
            if (attType =="UDF"):
                labLinkStat=line[0]
                bPublish="false"
                if (labLinkStat=="1"):
                    bPublish="true"
                    artID=line[2]
                    udfName=line[3]
                    udfValue=line[4]
                    udfType="String"
                    rr=update_artifact_post(artID, udfName,udfValue, udfType)
                    if DEBUG:
                        print (rr)
                pass 
    return lXML 



def update_artifact_post(artID, udfName,udfValue, udfType):
    sURI=BASE_URI+'artifacts/'+artID
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    r = api.PUT(DOM.toxml(),sURI)
    return r

def update_QC_flag(artID, qcFlag ):
    sURI=BASE_URI+'artifacts/'+artID
    artXML=api.GET(sURI)
    DOM = parseString( artXML)    
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
            except xml.dom.NotFoundErr, e:
                if DEBUG > 0: print( "Unable to Remove existing UDF node" )

            break

        # now add the new UDF node
    txt = newDoc.createTextNode( QC_status[qcFlag.upper()] )
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

def find_replace_in_file_file(sample_file_input):
    if DEBUG:
        print (sample_file_input)
    with open(sample_file_input, 'r', encoding='utf-8', errors='ignore') as file :
        filedata = file.read()
    if filedata.find('xmlns:udf') <0:
        filedata = filedata.replace(strFind, strReplace)
    
    (fileName, fileExt)=os.path.splitext(sample_file_input)
    sample_file_output=fileName+'.xml'
    
    with open(sample_file_output, 'w', encoding='utf-8', errors='ignore') as file:
        file.write(filedata)    
    return
 
def get_parent_process(processID,parentProcessID):
    sURI=BASE_URI+'processes/'+processID
    #r = requests.get(sURI, auth=(user, psw), verify=True)
    r=api.GET(sURI)
    rDOM = parseString( r )
    #print (r.content)
    ppTYpe=rDOM.getElementsByTagName( "type" )[0].firstChild.nodeValue
    if processID not in parentProcessLUIDs:
       parentProcessLUIDs[processID]=parentProcessID+","+ppTYpe
       if DEBUG:
           print (processID+","+parentProcessLUIDs[processID])    
    for node in rDOM.getElementsByTagName( "parent-process" ):
        pProcessLUID=node.getAttribute('limsid')
        if pProcessLUID not in parentProcessLUIDs:
            get_parent_process(pProcessLUID,processID)

def get_processID_by_processType(parentProcessLUIDs,processType):

    ss="N/A"
    for key in parentProcessLUIDs:
        (parentProcessID,ppTYpe)=parentProcessLUIDs[key].split(",")
        if (ppTYpe == processType):
            ss=(key,parentProcessID)
            if key not in activeLUIDs:
                activeLUIDs[key]=parentProcessID
                
        
    return ss
  


      

def main():

    global args
    args = setup_arguments()
    setupGlobalsFromURI(args.stepURI)
    
    global api, user, psw,parentProcessLUIDs, activeProcessID, activeLUIDs#,HOST, BASE_URI
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    
    user=args.username
    psw=args.password
    activeStep=args.activeStep
    
    parentProcessLUIDs={}
    activeLUIDs={}
    #BASE_URI=api.getBaseURI()
    global FileReportLUIDs
     
    FileReportLUIDs=args.attachLUIDs.split(' ')
    
    global FH
    FH = glsfileutil.fileHelper()
    FH.setAPIHandler( api )
    FH.setAPIAuthTokens( args.username, args.password )
    get_axiom_reports_from_file('')
       
    '''
     Create list of parent processes
    '''    
    get_parent_process(ProcessID,"")
    '''
     Get an active processID
    '''        
    (activeProcessID,parentProcessID)=get_processID_by_processType(parentProcessLUIDs,activeStep)  
    for activeProcessID in activeLUIDs:
        #print (key, activeLUIDs[key])  
    
        activeProcessURI=BASE_URI+'steps/'+activeProcessID
        print (activeProcessURI)
         
        
        #map_artifacts_io( args.stepURI )
        map_artifacts_io( activeProcessURI )
        sXML=prepare_artifacts_batch(ArtifactsLUID)
        if DEBUG>2:
            print(sXML)
        retXML=retrieve_artifacts(sXML)
        if DEBUG>2:
            print(retXML)    
        get_info_from_artifacts(retXML)
        
    #    for artLUID in ArtifactsLUID:
    #        print (artLUID, ArtifactsLUID[artLUID])
        create_meta(retXML)

if __name__ == "__main__":
    main()