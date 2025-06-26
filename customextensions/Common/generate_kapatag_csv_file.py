'''
    Created on Oct. 8, 2019
    @author: Alexander Mazur, alexander.mazur@gmail.com
        
    generating the csv file for random or cycle shift KapaTag placement 

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
    Parser.add_option('-t', "--kapatagFile", action='store', dest='kapatagFile')
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


def get_random_numbers(sSeed):
    random.seed(int(sSeed))
    randomSequence=random.sample(range(1, 97), 96)
    return randomSequence

def get_shufled_numbers(sSeed):
    from numpy.random import seed
    from numpy.random import shuffle
    sequence = [i for i in range(1,97)]
    seed(int(sSeed))
    shuffle(sequence)
    
    return sequence
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

def prepare_generic_artifacts_batch(map_io,IOkey):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in map_io:
        if IOkey=='input':
            iArt=art.split('_')[0]
        if IOkey=='output':
            iArt=art.split('_')[1]
        scURI = BASE_URI+'artifacts/'+iArt
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 
    return lXML

def retrieve_artifacts(sXML):
    global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    r=api.POST(sXML, sURI)
    return r

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

def sort_destination_by_column(samples_hash):
    temp={}
    for key in samples_hash:
        artifactLUID,artifactName,position,containerLUID=samples_hash[key]
        physPosition=get_physical_position(position)
        temp[physPosition]=artifactLUID,artifactName,position,containerLUID,key
        
    return temp
        

def create_random_kapatag_csv_file(sSeed,sorted_samples_hash,kapaTag_hash):
    sOUT="Src ID,Src Coord,Dst ID,Dst Coord,Diluent Vol,Sample Vol,Coord,Sample Name\n"
    randomNumbers=get_random_numbers(sSeed.split('-')[1])
    #print(randomNumbers)
    for key in sorted(sorted_samples_hash):
        kapaTag_pos=randomNumbers[key-1]
        artifactLUID,artifactName,position,containerLUID,sampleLUID=sorted_samples_hash[key]
        sOUT +="Src1,"+str(kapaTag_pos)+",Dst1,"+str(key)+",0,1,"+position+","+sampleLUID+"_"+kapaTag_meta[kapaTag_pos]+"\n"
        r=update_artifact_post(artifactLUID, "Sample Tag",kapaTag_meta[kapaTag_pos], '')
        #log(r)
    return sOUT
    
def create_cycle_kapatag_csv_file(cycle_shift_hash,sorted_samples_hash,kapaTag_hash):
    sOUT="Src ID,Src Coord,Dst ID,Dst Coord,Diluent Vol,Sample Vol,Coord,Sample Name\n"
    for key in sorted(sorted_samples_hash):
        kapaTag_pos=cycle_shift_hash[key]
        artifactLUID,artifactName,position,containerLUID,sampleLUID=sorted_samples_hash[key]
        sOUT +="Src1,"+str(kapaTag_pos)+",Dst1,"+str(key)+",0,1,"+position+","+sampleLUID+"_"+kapaTag_meta[kapaTag_pos]+"\n"
        r=update_artifact_post(artifactLUID, "Sample Tag",kapaTag_meta[kapaTag_pos], '')
        #log(r)
    return sOUT    


def get_physical_position(sAlphaNumPosition):
    
    s=sAlphaNumPosition[0].upper()
    sASCII= ord(s)
    sDigit=sAlphaNumPosition[1:].upper()
    sDigit=sDigit.replace(':0','')
    sDigit=sDigit.replace(':','') 
    
    sPhPos=(int(sASCII)-64)+(int(sDigit)-1)*8
    
    return sPhPos
def get_AlphaNumPosition(iPhysPos):
    alpha=['H','A','B','C','D','E','F','G','H']
    iAlphaInt=iPhysPos // 8
    iAlphaRem=iPhysPos%8
    sSep=":"
    
    if iAlphaRem >0:
        if iAlphaInt+1<10:
            sSep=":"
        s= alpha[iAlphaRem] +sSep+str(iAlphaInt+1)
    else:
        if iAlphaInt<10:
            sSep=":"
        s= alpha[iAlphaRem] +sSep+str(iAlphaInt)
    return s
    
def get_container_names(Container_array):
    for container_ID in Container_array:
        sURI=BASE_URI+'containers/'+container_ID
        r= api.GET(sURI)
        rDOM = parseString(r )
        node =rDOM.getElementsByTagName('name')
        contName = node[0].firstChild.nodeValue
        contPosition=rDOM.getElementsByTagName('value')[0].firstChild.nodeValue
        if container_ID not in Container_array:
            Container_array[container_ID]=contPosition+'xxx'+contName


def read_kapatag_file(sFilePath):
    kapatag_meta={}
    aHeaders={}
    with open(sFilePath) as csvfile:
        readCSV = csv.reader(csvfile, delimiter=',')
        headers = next(readCSV, None)
        for num, value in enumerate(headers):
            aHeaders[value]=num
        for line in readCSV:
            try:
                kapaTagPosition=int(line[aHeaders["Tube Position Number"]])
                kapaTagName=line[aHeaders["KapaTag_Name"]]
                kapatag_meta[kapaTagPosition]=kapaTagName
            except Exception as e:
                log( e)
                sys.exit(111)            
    return kapatag_meta   

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

def get_cycle_shift(iCycle):
    new_sequence={}
    sequence = [i for i in range(1,97)]
    for num, k in enumerate(sequence):
        new_k=k+iCycle
        if new_k>96:
            new_k=new_k-96
        #new_sequence[num+1]=new_k
        new_sequence[new_k]=num+1
        
    return new_sequence
    

'''
    START
'''
def main():

    global api,args,ProcessID,DEBUG, samples_hash, Container_array,LOG
    DEBUG=False
    samples_hash={}
    Container_array={}
    LOG=[]

    args = setup_arguments()
    user=args.username
    psw=args.password
    kapatagFile=args.kapatagFile
    if not kapatagFile:
        log("Can't find KapaTag template file!")
        sys.exit(111)
    api = glsapiutil3x.glsapiutil3()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password ) 
    setupGlobalsFromURI( args.stepURI )
    processUDFs=get_process_UDFs(ProcessID)

    map_io=get_map_io_by_process(ProcessID, 'Analyte', 'PerInput')
    artifactLUIDs=[key for key in map_io.values()]
    artXML=api.getArtifacts(artifactLUIDs)

    samples_hash=get_artifacts_meta(artXML)
    sorted_samples_hash=sort_destination_by_column(samples_hash)
    global kapaTag_meta
    kapaTag_meta=read_kapatag_file(kapatagFile)
    sOUT=""
    try:
        iKapaTagCycle=processUDFs["KapaTag Cycle"]
    except:
        log("Error: KapaTag Cycle number can't be empty")
        sys.exit(111)
    cycle_shift_hash=get_cycle_shift(int(iKapaTagCycle))
    sOUT=create_cycle_kapatag_csv_file(cycle_shift_hash,sorted_samples_hash,kapaTag_meta)

    print(sOUT)

if __name__ == "__main__":
    main()
    

    