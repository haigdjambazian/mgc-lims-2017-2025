'''
Created on Nov. 27, 2017


@author: Alexander Mazur, alexander.mazur@gmail.com

    updated (Feb. 5, 2018):    
        - support v.4 output format for pipelines
        - UDF fields write 

python v.2.7
'''
__author__ = 'Alexander Mazur'



debug = False
debug_placement_file = "controls_test_july25.csv"   # local file for testing
samples_controls_placement_file= "/opt/gls/clarity/ai/temp/novaseq_template.csv"
temp_dir="/opt/gls/clarity/ai/temp/"
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

uploads_hash={'ARTIFACT':"artifacts",'PROJECT':"projects",'SAMPLE':"samples",'PROCESS':"processes", 'UDF':"UDF"}
strFind= 'ri/artifact"'
strReplace='ri/artifact" xmlns:udf="http://genologics.com/ri/userdefined" xmlns:file="http://genologics.com/ri/file" '

'''
    /lb/robot/research/Novaseq/ =>    /data/glsftp/Novaseq/

'''

file_stores={'novaseq':"/lb/robot/research",'research':"/lb/robot"}

DEBUG=False

def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-t', "--template", action='store', dest='template')     # placement CSV
    Parser.add_option('-o', "--output", action='store', dest='outputLUID')
    Parser.add_option('-l', "--attachLUIDs", action='store', dest='attachLUIDs')


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
                illuminaTabFile = downloadfile( FileReportLUIDs[7])
            else:
                illuminaTabFile = downloadfile( FileReportLUIDs[7] )

    if len( illuminaTabFile ) == 1:
        print (illuminaTabFile)
        illuminaTabFile = illuminaTabFile[0].split("\r")

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

def get_samples_list():
    global SamplesLUID
    SamplesLUID=[]
    sURI=BASE_URI+'artifacts/'+args.outputLUID
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)

    nodes = pDOM.getElementsByTagName( "sample" )
    for node in nodes:
        smplURI = node.getAttribute( "uri" )
        if smplURI not in SamplesLUID:
            SamplesLUID.append(smplURI)

    
    return artXML

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
    
def get_meta_date_from_samples(smplXML): 
    global SamplesMeta
    
    SamplesMeta={}
 
 
    pDOM = parseString( smplXML)

    nodes = pDOM.getElementsByTagName( "smp:sample" )
    for node in nodes:
        sampleLUID= node.getAttribute( "limsid" )
        sampleName=node.getElementsByTagName('name')[0].firstChild.nodeValue 
        projLUID=node.getElementsByTagName('project')[0].getAttribute( "limsid" )
        
        if sampleLUID not in SamplesMeta:
            SamplesMeta[sampleLUID]=sampleName+"__"+projLUID


def get_lablink_status(resultsCSV):
    global lablinkStatus
    lablinkStatus={}

    for line in resultsCSV:
        sampleLUID=line[0]
        if sampleLUID=='Lablink':
            for k in range(1,len(line)):
                status=line[k]
                if status =='1':
                    lablinkStatus[k] =1
            

def prepare_illumina_files_post_2_samples(SamplesMeta): 
  
  
    sURI = BASE_URI+'files'

    #sContentLocation="sftp://bravotestapp.genome.mcgill.ca/data/glsftp"
    #sAttachedTo=BASE_URI+'samples'
    sContentLocation=sftpHOSTNAME+"/data/glsftp"
    
    sOriginalLocation=''
    
    for line in illuminaResultsTab:
        lXML = []
        if line[1] in uploads_hash:
            sAttachedTo=BASE_URI+uploads_hash[line[1]]
            sampleLUID=line[2]
            #print sampleLUID
            if sampleLUID in SamplesMeta:
                
                (sampleName,projLUID)=SamplesMeta[sampleLUID].split('__')
                #print sampleLUID, sampleName, projLUID, line[11]
            labLinkStat=line[0]
            bPublish="false"
            if (labLinkStat=="1"):
                bPublish="true"
                lXML = []
                sfile=line[4]
                sFileStore = replace_path_to_filestore(sfile, "research")
                lXML.append( '<?xml version="1.0" encoding="utf-8"?><file:file xmlns:file="http://genologics.com/ri/file">' )            
                lXML.append( '<content-location>' + sContentLocation +sFileStore+ '</content-location>' )        
                lXML.append( '<attached-to>' + sAttachedTo +'/'+sampleLUID+ '</attached-to>' )
                lXML.append( '<original-location>' +sfile+ '</original-location>' )
                lXML.append( '<is-published>true</is-published>' )
                lXML.append( '</file:file>' )
            
                if len(lXML)>0:
                    lXML = ''.join(lXML)
                    # print lXML+"\n\n"
                    r = api.POST(lXML,sURI)
                    print (r)
             
    
    return lXML 

def post_results_data_2_lims(): 
  
  
    sURI = BASE_URI+'files'

    #sContentLocation="sftp://bravotestapp.genome.mcgill.ca/data/glsftp"
    #sAttachedTo=BASE_URI+'samples'
    sContentLocation=sftpHOSTNAME+"/data/glsftp"
    
    sOriginalLocation=''
    
    for line in illuminaResultsTab:
        # post one record from TAB file        
        lXML = []
        
        if line[1] in uploads_hash:
            attType=uploads_hash[line[1]]
            if (attType !="UDF"):
                sAttachedTo=BASE_URI+uploads_hash[line[1]]
                sampleLUID=line[2]
    
                labLinkStat=line[0]
                bPublish="false"
                if (labLinkStat=="1"):
                    bPublish="true"
                    lXML = []
                    sfile=line[4]
                    sFileStore = replace_path_to_filestore(sfile, "research")
                    lXML.append( '<?xml version="1.0" encoding="utf-8"?><file:file xmlns:file="http://genologics.com/ri/file">' )            
                    lXML.append( '<content-location>' + sContentLocation +sFileStore+ '</content-location>' )        
                    lXML.append( '<attached-to>' + sAttachedTo +'/'+sampleLUID+ '</attached-to>' )
                    lXML.append( '<original-location>' +sfile+ '</original-location>' )
                    lXML.append( '<is-published>true</is-published>' )
                    lXML.append( '</file:file>' )
                
                    if len(lXML)>0:
                        lXML = ''.join(lXML)
                        # print lXML+"\n\n"
                        r = api.POST(lXML,sURI)
                        print (r)
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


def my_setUDF( DOM, udfname, udfvalue,udftype ):
    
    if (udftype ==""):
        udftype="String"

    if debug > 2: print( DOM.toprettyxml() )

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

def find_replace_in_file_file(sample_file_input):
    if debug:
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
 

def replace_path_to_filestore(sFilePath, sFileStore):
    s=''
    if sFileStore in file_stores:
        sOrg_path=file_stores[sFileStore]
        s = sFilePath.replace(sOrg_path,"")
    
    
    return s
       

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
    
    global FileReportLUIDs
    FileReportLUIDs=args.attachLUIDs.split(' ')
    global FH
    FH = glsfileutil.fileHelper()
    FH.setAPIHandler( api )
    FH.setAPIAuthTokens( args.username, args.password )
    

    #get_novaseq_reports_from_file()
    get_illumina_reports_from_file('')
    #print (illuminaResultsTab)
    #get_lablink_status(resultsCSV)
    '''
    aXML=get_samples_list()
    
    iXML=prepare_samples_batch(SamplesLUID)
    oXML=retrieve_samples(iXML)
    
    get_meta_date_from_samples(oXML)
    '''
    #print (illuminaResultsTab)
    #xxXML=prepare_illumina_files_post_2_samples(SamplesMeta)
    post_results_data_2_lims()
   
    
    




if __name__ == "__main__":
    main()