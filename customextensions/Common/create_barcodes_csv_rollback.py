'''
Created on Feb 22, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
'''
__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os

from time import gmtime, strftime
import requests
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET

user=''
psw=''
#URI_base='https://bravotestapp.genome.mcgill.ca/api/v2/'

HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False

script_dir=os.path.dirname(os.path.realpath(__file__))

def setupArguments():
    parser = argparse.ArgumentParser(description='Create CSV file for barcode printer with roll back')
    parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
    parser.add_argument('-user',default='', help='API user')
    parser.add_argument('-psw',default='', help='API password')
    parser.add_argument('-containerSource',default='output', help='containerSource: {input|output|submitted|io}')
    parser.add_argument('-name1',default='', help='Barcode NAME1')
    parser.add_argument('-name2',default='', help='Barcode NAME2')  
    parser.add_argument('-activeStep', default='XXX', help='activeStep')      
    return parser.parse_args()





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





def get_placed_containers(stepURI):
    global scLUIDs
    sURI = stepURI + "/placements"
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )
    nodes=rDOM.getElementsByTagName( "selected-containers" )
    scNodes = nodes[0].getElementsByTagName( "container")
    scLUIDs=[]
    ss="Plate ID,Name 1,Name 2\n"
    i=1
    for sc in scNodes:
        scURI = sc.getAttribute( "uri")
        scLUID = scURI.split( "/" )[-1]
        scName = get_container_name(scLUID)
        ss +=scLUID+","+scName+"_Dst"+str(i)+","+scLUID+"\n"
        i +=1


    return ss

def get_input_containers(retXML):
    inputContainers=[]
    rDOM = parseString( retXML.content )
    ss="Plate ID,Name 1,Name 2\n"
    i=1
    for artifact in rDOM.getElementsByTagName("art:artifact"):
        artContainer= artifact.getElementsByTagName("container")[0].getAttribute("limsid")
        
        if (artContainer not in inputContainers) and (len( artifact.getElementsByTagName( "control-type" )) ==0) :
            inputContainers.append(artContainer)
            containerName = get_container_name(artContainer)
            if name2:
                listName2=name2.split(',')
                for key in listName2:
 #                   ss +=artContainer+","+containerName+name1+","+key+"\n"
                    ss +=artContainer+","+containerName+","+name1+key+"\n"
            else:
#                ss +=artContainer+","+containerName+","+artContainer+name1+"\n"
                ss +=artContainer+","+containerName+","+name1+"\n"
                 
    return ss

def map_io( stepURI ):
    global iomap
    iomap = {}

    sURI = stepURI + "/details"
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )  
    for io in rDOM.getElementsByTagName("input-output-map"):
        inputartURI = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        outputnode = io.getElementsByTagName("output")[0]
        outputartURI = outputnode.getAttribute("uri")
        # AM
        outputArtID = outputnode.getAttribute("limsid")

        # only want artifact outputs
        # ORIGINAL used "Analyte"
        if (outputnode.getAttribute("type") == "Analyte") and (outputnode.getAttribute("output-generation-type")=="PerInput") :    # replicates, therefore multiple outputs per input
            iomap[ outputartURI ] = inputartURI
    
    return iomap

def prepare_artifacts_batch(iomap):
    #global BASE_URI
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    sURI=""
    for artURI in iomap:
        if (containerSource =="input")  or (containerSource =="io"):
           sURI=iomap[artURI]
#        if containerSource == "output":
#            sURI=artURI 
        #scURI = BASE_URI+'artifacts/'+art
        lXML.append( '<link uri="' + sURI + '" rel="artifacts"/>' )        
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_artifacts(sXML):
    #global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #r = api.POST(sXML,sURI) 
   
    return r

def get_container_name(containerID):
    global BASE_URI, user,psw
    sURI=BASE_URI+'containers/'+containerID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    # print (r.content)
    rDOM = parseString(r.content )
    #print (r.content)
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue
    return ss


def getUDF( rDOM, udfname ):
    response = ""
    elements = rDOM.getElementsByTagName( "udf:field" )
    for udf in elements:
        temp = udf.getAttribute( "name" )
        if temp == udfname:
            response = getInnerXml( udf.toxml(), "udf:field" )
            break
    return response

def getInnerXml(xml, tag):
    """Returns the contents inside of a tag in a given Xml tag string.
        Keyword arguments:
        xml -- The Xml tag string to extract contents from
        tag -- The tag in which to retrieve contents
    """
    tagname = '<' + tag + '.*?>'
    inXml = re.sub(tagname, '', xml)
    tagname = '</' + tag + '>'
    inXml = inXml.replace(tagname, '')
    return inXml

'''
    Roll back 

'''
def get_parent_process(processID,parentProcessID):
    sURI=BASE_URI+'processes/'+processID
    r = requests.get(sURI, auth=(user, psw), verify=True)
    #r=api.GET(sURI)
    rDOM = parseString( r.content )
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
        #print (parentProcessID,ppTYpe)
        if (ppTYpe == processType):
            ss=(key,parentProcessID)
            if key not in activeLUIDs:
                activeLUIDs[key]=parentProcessID            
            if DEBUG:
                print (ss)
        
    return ss



'''
    START

'''


def main():
    global args, user,psw, name1, name2,containerSource,parentProcessLUIDs, activeProcessID, activeStep,activeLUIDs
    args = setupArguments()
    stepURI_v2=args.stepURI_v2
    user = args.user
    psw = args.psw
    name1=args.name1
    name2=args.name2
    activeStep=args.activeStep
    containerSource = args.containerSource
    parentProcessLUIDs={}
    activeLUIDs={}
   
    setupGlobalsFromURI(stepURI_v2)
    '''
         Create list of parent processes
    '''    
    get_parent_process(ProcessID,"")
    '''
    Get an active processID
    '''        
    (activeProcessID,parentProcessID)=get_processID_by_processType(parentProcessLUIDs,activeStep) 
    for activeProcessID in activeLUIDs:   
        activeProcessURI=BASE_URI+'steps/'+activeProcessID        
        if DEBUG:
            print (activeProcessURI)    
        
        ss=""
        if (containerSource =="output")  or (containerSource =="io"):
            ss= get_placed_containers(activeProcessURI)
        if (containerSource =="input") or (containerSource =="io"):
            map_io( activeProcessURI )
            inputXML=prepare_artifacts_batch(iomap)
            ret=retrieve_artifacts(inputXML)
            #print(ret.content)
            ss +=get_input_containers(ret)
                
    print(ss)
        
if __name__ == "__main__":
    main()

