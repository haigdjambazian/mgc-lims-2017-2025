'''
Created on Nov. 12, 2018


@author: Alexander Mazur, alexander.mazur@gmail.com


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
import collections,datetime
import urllib,glob

import glsapiutil   # 2106 version , needed for API calls
import glsfileutil  # needed to download file
import xml.etree.ElementTree as ET

uploads_hash={'ARTIFACT':"artifacts",'PROJECT':"projects",'SAMPLE':"samples",'PROCESS':"processes", 'UDF':"UDF",'UDF_PFURI':"processes"}
steps_map_hash={'novaseq':"NovaSeq",'hiseq':"HiSeq X"}
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
    Parser.add_option('-g', "--technology", action='store', dest='technology') # hiseqx, novaseq, hiseq4000, iSeq, hiseq2500


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
    global illuminaResultsTab,illuminaTabFile,splitResultsCSV
    
    illuminaResultsTab=[]

    if debug:
        raw = open( debug_placement_file, "r")
        illuminaTabFile = raw.readlines()
    else:
        #template_from_path = args.template
        if args.template:
            print("Template")
            raw = open( args.template, "r")
            illuminaTabFile = raw.readlines()
        else:
            if (sReportKind=='inputFIleLUID'):
                illuminaTabFile = downloadfile( inputFIleLUID)
            else:
                if technology:
                    print("Technology")
                    if (sReportKind =='sUDFinit_file'):
                        raw = open( sUDFinit_file, "r")
                    elif (sReportKind =='sUDF_file'):
                        raw = open( sUDF_file, "r")
                    illuminaTabFile = raw.readlines()
                    
                    

    if len( illuminaTabFile ) == 1:
        print (illuminaTabFile)
        illuminaTabFile = illuminaTabFile[0].split("\r")

    for x in illuminaTabFile:
        if len(x.split("\t"))>1:
            x=x.strip("\r\n")
            #print (x.strip("\n").split("\t"))
            illuminaResultsTab.append(x.strip("\n").split("\t"))
          

    #illuminaResultsTab = [ x.strip("\r\n").split("\t") for x in illuminaResultsTab ]


def downloadfile( file_art_luid ):

    NEW_NAME = 'temp_file.txt'
    try:
        FH.getFile( file_art_luid, NEW_NAME )
        #my_getFile(file_art_luid, NEW_NAME )
    except:
        print ('trouble downloading result file, file luid not found')
        sys.exit(111)
    raw = open( NEW_NAME, "r")
    lines = raw.readlines()
    raw.close
    return lines

def my_getFile(rfLUID, filePath ):

    ## get the details from the resultfile artifact
    aURI = BASE_URI + "artifacts/" + rfLUID
    if DEBUG is True:
        print( "Trying to lookup:" + aURI )
    aXML = api.GET( aURI )
    #print aXML
    aDOM = parseString( aXML )

    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        dlURI = api.getBaseURI() + "files/" + fLUID + "/download"
        if DEBUG is True:
            print( "Trying to download:" + dlURI )

        dlFile = api.GET( dlURI )

        ## write it to disk
        try:
            f = open( "./" + filePath, "w" )
            
            f.write( dlFile )
            f.close()
        except:
            if DEBUG is True:
                print( "Unable to write downloaded file to %s" % filePath )



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

    sContentLocation=sftpHOSTNAME+"/data/glsftp"
    
    sOriginalLocation=''
    
    for line in illuminaResultsTab:
        # post one record from TAB file        
        lXML = []
        
        if line[1] in uploads_hash:
            attType=uploads_hash[line[1]]
            labLinkStat=line[0]
            if labLinkStat=="0":
                bPublish="false"
            elif labLinkStat=="1":
                bPublish="true"    
                
            if (line[1] !="UDF") and (line[1] !="UDF_PFURI"):
                #print (attType)
                udfCheckName="Run Processing Status"
                if (udfCheckName not in udfs_hash) or (udfs_hash[udfCheckName]!="Complete"):
                    sAttachedTo=BASE_URI+uploads_hash[line[1]]
                    sampleLUID=line[2]
                    #bPublish="true"
                    lXML = []
                    sfile=line[4]
                    sFileStore = replace_path_to_filestore(sfile, "research")
                    lXML.append( '<?xml version="1.0" encoding="utf-8"?><file:file xmlns:file="http://genologics.com/ri/file">' )            
                    lXML.append( '<content-location>' + sContentLocation +sFileStore+ '</content-location>' )        
                    lXML.append( '<attached-to>' + sAttachedTo +'/'+sampleLUID+ '</attached-to>' )
                    lXML.append( '<original-location>' +sfile+ '</original-location>' )
                    lXML.append( '<is-published>'+bPublish+'</is-published>' )
                    lXML.append( '</file:file>' )
                
                    if len(lXML)>0:
                        lXML = ''.join(lXML)
                        #print lXML+"\n\n"
                        r = api.POST(lXML,sURI)
                        print (r)
                else:
                    print(line[4]+ " already attached to "+BASE_URI+uploads_hash[line[1]] +'/'+line[2])
                                
            if (line[1] =="UDF") and (line[2][0:3]!='24-') :
                #bPublish="true"
                artID=line[2]
                udfName=line[3]
                udfValue=line[4]
                udfType="String"
                rr=update_artifact_post(artID, udfName,udfValue, udfType)
                #print (rr)
            if (line[1] =="UDF") and (line[2][0:3]=='24-') :
                #bPublish="true"
                processID=line[2]
                udfName=line[3]
                udfValue=line[4]
                udfType="String"
                rr=update_process_udf(processID, udfName,udfValue, udfType)
                #print (rr)
            if (line[1] =="UDF_PFURI") and (line[2][0:3]=='24-') :
                udfCheckName="Report File"
                if udfCheckName not in udfs_hash:
                    sAttachedTo=BASE_URI+uploads_hash[line[1]]
                    sampleLUID=line[2]
                    lXML = []
                    sfile=line[4]
                    sFileStore = replace_path_to_filestore(sfile, "research")
                    lXML.append( '<?xml version="1.0" encoding="utf-8"?><file:file xmlns:file="http://genologics.com/ri/file">' )            
                    lXML.append( '<content-location>' + sContentLocation +sFileStore+ '</content-location>' )        
                    lXML.append( '<attached-to>' + sAttachedTo +'/'+sampleLUID+ '</attached-to>' )
                    lXML.append( '<original-location>' +sfile+ '</original-location>' )
                    lXML.append( '<is-published>'+bPublish+'</is-published>' )
                    lXML.append( '</file:file>' )
                    if len(lXML)>0:
                        lXML = ''.join(lXML)
                        # fake upload file to LIMS
                        #print (lXML)
                        r = api.POST(lXML,sURI)
                        print (r)  
                        aDOM = parseString(r)
                            ## get the file's details
                        nodes = aDOM.getElementsByTagName( "file:file" )
                        dlURI=""
                        if len(nodes) > 0:
                            fLUID = nodes[0].getAttribute( "limsid" )
                            # https://bravotestapp.genome.mcgill.ca/lablink/secure/DownloadFile.do?id=
                            dlURI= HOSTNAME+"/lablink/secure/DownloadFile.do?id="+fLUID.split("-")[1]
                            #dlURI = BASE_URI + "files/" + fLUID + "/download"
                    processID=line[2]
                    udfName=line[3]
                    udfValue=dlURI #line[4]
                    udfType="URI"
                    rr=update_process_udf(processID, udfName,udfValue, udfType)
                    #print (rr)
                    
                else:
                    print("Report file was already attached")
                
                
                
                pass 
    
    return lXML 

def update_artifact_post(artID, udfName,udfValue, udfType):
    sURI=BASE_URI+'artifacts/'+artID
    artXML=api.GET(sURI)
    pDOM = parseString( artXML)
    DOM=my_setUDF(pDOM, udfName, udfValue,udfType) 
    r = api.PUT(DOM.toxml(),sURI)
    return r

def update_process_udf(processLUID, udfName,udfValue, udfType):
    sURI=BASE_URI+'processes/'+processLUID
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

def get_meta_data_from_process(processLUID):
    sURI=BASE_URI+'processes/'+processLUID
    processXML=api.GET(sURI)
    rDOM = parseString( processXML)
    udfs_hash={}
    for key in rDOM.getElementsByTagName("udf:field"):
        udf = key.getAttribute( "name")
        udfs_hash[udf]=key.firstChild.nodeValue
    return udfs_hash 

def get_meta_data_from_step(stepURI):
    sURI=stepURI+'/details'
    processXML=api.GET(sURI)
    rDOM = parseString( processXML)
    udfs_hash={}
    for key in rDOM.getElementsByTagName("udf:field"):
        udf = key.getAttribute( "name")
        udfs_hash[udf]=key.firstChild.nodeValue
    return udfs_hash
 
def get_base_dir_meta(udfs_hash):
    sRootDir="/lb/robot/research/processing/"
    #sYear=str(datetime.datetime.now().year)
    sYear=sStartDate.split("-")[0]
    sRunID=udfs_hash['Run ID']
    sBaseDir=sRunID+'-'+technology
    sFullPath=sRootDir+technology+'/'+sYear +'/'+sBaseDir
    sUDF_file=sFullPath+'/'+sBaseDir+'-run.db_upload.udfs.txt'
    sUDFinit_file=sFullPath+'/'+sBaseDir+'-run.db_upload_init.udfs.txt'
    
    return sRootDir,technology,sYear,sRunID,sBaseDir,sFullPath,sUDF_file,sUDFinit_file

def get_isfile_attached(fileLUID):

    ## get the details from the resultfile artifact
    aURI = BASE_URI + "artifacts/" + fileLUID
    if DEBUG is True:
        print( "Trying to lookup:" + aURI )
    aXML = api.GET( aURI )
    #print aXML
    aDOM = parseString( aXML )
    fileLocation=""

    ## get the file's details
    try:
        nodes = aDOM.getElementsByTagName( "file:file" )
        if len(nodes) > 0:
            fLUID = nodes[0].getAttribute( "limsid" )
            dlURI = api.getBaseURI() + "files/" + fLUID 
            fileXML = api.GET( dlURI )
            fDOM = parseString( fileXML )
            key = fDOM.getElementsByTagName( "content-location" )
            fileLocation=key[0].firstChild.nodeValue.replace(sftpHOSTNAME,"")
    except:
        fileLocation=""
                
    
    return fileLocation

def get_parent_process(processID,parentProcessID):
    sURI=BASE_URI+'processes/'+processID
    #r = requests.get(sURI, auth=(user, psw), verify=True)
    #rDOM = parseString( r.content )
    r= api.GET( sURI )
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

def get_rb_parentProcess_UDF(parentProcessLUIDs,ppName,udfName):
    udfs_hash={}
    for key in parentProcessLUIDs:
        if parentProcessLUIDs[key].split(",")[1] == ppName:
            pURI = BASE_URI + "processes/" + key
            #pXML= requests.get(pURI, auth=(user, psw), verify=True)
            #pDOM = parseString( pXML.content )
            pXML=api.GET(pURI)
            pDOM=parseString(pXML)

            for key in pDOM.getElementsByTagName("udf:field"):
                udf = key.getAttribute( "name")
                udfs_hash[udf]=key.firstChild.nodeValue
    return udfs_hash

def get_processID_by_processType(parentProcessLUIDs,processType):
    ss="N/A"
    for key in parentProcessLUIDs:
        (parentProcessID,ppTYpe)=parentProcessLUIDs[key].split(",")
        if (ppTYpe == processType):
            ss=(key,parentProcessID)
        
    return ss

def get_container_info_from_step(stepLUID):
    sURI=BASE_URI+'steps/'+stepLUID+"/placements"
    pXML=api.GET(sURI)
    pDOM=parseString(pXML)
    
    for node in pDOM.getElementsByTagName( "container"):
        #key = node.getElementsByTagName( "container")
        cURI= node.getAttribute("uri")

    #cURI=BASE_URI+'containers/'+container_ID
    r = api.GET(cURI)
    rDOM = parseString(r )
    node =rDOM.getElementsByTagName('name')
    containerName = node[0].firstChild.nodeValue
    
    return containerName
            

def main():

    global args
    args = setup_arguments()
    setupGlobalsFromURI(args.stepURI)
    
    
    
    global api, user, psw,inputFIleLUID, technology, fileTemplate #,HOST, BASE_URI
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    user=args.username
    psw=args.password

    technology = args.technology

    
    global FileReportLUIDs,parentProcessLUIDs,ppUDFValue,sStartDate
    global udfs_hash,sRootDir,sYear,sRunID,sBaseDir,sFullPath,sUDF_file,sUDFinit_file,bFileAttached, bInit, bFull
    

    global FH
    
    parentProcessLUIDs={}
    ppUDFValue={}
    udfs_hash={}
    
    udfs_hash=get_meta_data_from_step(args.stepURI)
    try:
        sFailedIDs=udfs_hash["Failed Data IDs (csv)"].split(",")
        #sFailedIDs=sFailedIDs.replace(" ","")
        for artID in sFailedIDs:
            artID=artID.replace(" ","")
            #print (artID)  
            r=update_artifact_post(artID, "Data Release","2", "String")
            print (r)
    except:
        pass
    




if __name__ == "__main__":
    main()