'''
Created on December 5, 2016

@author: Alexander Mazur, mazur@ieee.org
'''
__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os
import numpy as np
import numpy.polynomial.polynomial as poly
from time import gmtime, strftime
import requests
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET


  

user=''
psw=''
URI_base='https://bravotestapp.genome.mcgill.ca/api/v2/'
script_dir=os.path.dirname(os.path.realpath(__file__))

parser = argparse.ArgumentParser(description='Applying quantified concentration values to the WebUI')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
parser.add_argument('-fileLuid',default='', help='fileLuid from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')
parser.add_argument('-processURI_v2',default='', help='processURI_v2 from WebUI')

'''
{stepURI:v2}
http://localhost:9080/api/v2/steps/24-1297
'''
args = parser.parse_args()
fileLuid=args.fileLuid
stepURI_v2=args.stepURI_v2
user_psw = args.user_psw
processURI_v2=args.processURI_v2
DEBUG=False

'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')

raw_barcodes={}
quant_barcodes={}
data_quant={}
raw_data_files=[]
container_barcodes={}
calibrationFile=''

strFind= 'ri/artifact"'
strReplace='ri/artifact" xmlns:udf="http://genologics.com/ri/userdefined" xmlns:file="http://genologics.com/ri/file" '

def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"

    if DEBUG is True:
        print (HOSTNAME)
        print (BASE_URI)






def scan_4_files(inputFile,file_ext, barcode_hash):
    "Listing of all files in input directory and moving to the output directory"
#    global raw_data_files
    #print (inputFile)
    inputDir = os.path.dirname(inputFile)
    sorted_files=getfiles_sorted_date(inputDir)
    input_filename = os.path.basename(inputFile)
#    for file in os.listdir(inputDir):    
    for file in sorted_files:
        #print (file)
        if (file.endswith(file_ext)) and (file not in input_filename) :
            input_file = os.path.join(inputDir, file)
            #print (input_file)
            #print (get_barcode_from_raw_file(input_file), input_file)
            sBarcode=get_barcode_from_raw_file(input_file)
            #if (file_ext == '.quant'):
                #get_data_quant(input_file)
            #if not(sBarcode in barcode_hash):
            barcode_hash[sBarcode]= input_file
            #print (file + "\n"+input_file+"\n")
#            raw_data_files.append(input_file)
    return
def getfiles_sorted_date(dirpath):
    a = [s for s in os.listdir(dirpath)
         if os.path.isfile(os.path.join(dirpath, s))]
    a.sort(key=lambda s: os.path.getmtime(os.path.join(dirpath, s)))
    return a
def fill_data_quant_hash(quant_barcodes):
    for key in quant_barcodes:
        input_file =quant_barcodes[key]
        get_data_quant(input_file)
    return

def get_barcode_from_raw_file(sample_file_input):
    plateID=''
    f = open(sample_file_input, 'r', encoding='utf-8', errors='ignore')
    lines = f.readlines()
    i = 0
    while i < len(lines):
        s=lines[i].upper()
        if (s.find('PLATE ID:')>=0):
            plateID=s.replace('PLATE ID:','')
            plateID=plateID.replace(' ', '')
            plateID=plateID.replace('\n', '')
            
        i=i+1    
    return plateID  
def get_data_quant(sample_file_input):
    global data_quant
    
    plateID=''
    f = open(sample_file_input, 'r', encoding='utf-8', errors='ignore')
    lines = f.readlines()
    i = 0
    bStart=-1
    while i < len(lines):
        s=lines[i].upper()
        if (s.find('PLATE ID:')>=0):
            plateID=s.replace('PLATE ID:','')
            plateID=plateID.replace(' ', '')
            plateID=plateID.replace('\n', '')
        if (bStart>0):
            (sPos,QuantValue,Status)=s.split('\t')
            data_quant[plateID+'_'+sPos]=QuantValue   
            
        if (s.find('QUANTVALUE')>=0):
            bStart=1
        i=i+1       
    return         
     
def get_local_PG_file(FileLuid):
    #global user,psw, URI_base
    if DEBUG:
        print (BASE_URI+'artifacts/'+FileLuid)
    r = requests.get(BASE_URI+'artifacts/'+FileLuid, auth=(user, psw), verify=True)
    root = ET.fromstring(r.content)
    #sFile=""
    if DEBUG:
        print (r.content)

    namespaces={'file':'http://genologics.com/ri/file'}
    for sFile in root.findall('file:file', namespaces):
        print (sFile.attrib)
    sURI=sFile.attrib['uri']
    sLocal_file=extract_file_location(sURI)
    return sLocal_file #sFile.attrib['uri']

def extract_file_location(sURI):
    global user,psw
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )
    for node in rDOM.getElementsByTagName('content-location')[0].childNodes:
            if node.nodeType == node.TEXT_NODE:
                s=node.toxml()
                s = s.replace('sftp://bravotestapp.genome.mcgill.ca', '')
                s = s.replace('sftp://bravodevapp.genome.mcgill.ca', '')
                s = s.replace('sftp://bravoprodapp.genome.mcgill.ca', '')
                #print(s)
    return s   

def get_placement_containers(stepURI_v2):
    global user,psw, container_barcodes
    sURI=stepURI_v2 +'/placements'
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )
#    print('\n')    
#    print (r.content)
#    print('\n')
    
    i=0
    
#    for node in rDOM.getElementsByTagName('selected-containers')[0].childNodes:
    for node in rDOM.getElementsByTagName('selected-containers'):
        s=node.getElementsByTagName('container')
        sContainerURI=s[0].getAttribute("uri")
        #print (sContainerURI)
        ss=extract_new_container_ID (sContainerURI)
        if (ss):
#            kk=":".join("{:02x}".format(ord(c)) for c in ss)
            sName=get_container_name(ss)
            '''
             use
            container_barcodes[ss]=sName
            
            '''
            container_barcodes[ss]=ss
            get_retrieve_and_update_container(ss)
            print ('containerID:\t'+ss+'\ncontainerName:\t'+sName)
        i=i+1
    return
def post_batch_artifacts(xmlFile):
    #global URI_base, user,psw, script_dir
    sURI=BASE_URI+'artifacts/batch/update'
    sXMLfile=script_dir +'/'+xmlFile
    XML_STRING = open(sXMLfile).read()
    if DEBUG:
        print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=XML_STRING, auth=(user, psw), verify=True, headers=headers)
    if DEBUG:
        print (r.content)
    #rDOM = parseString( r.content )    
    return
def extract_new_container_ID (sXML):
    print (sXML)
    s=sXML.split("containers")
    ss=s[1].replace("/","")
    #print (ss)
    return ss

def extract_container_ID (sXML):
    s=''
    sLocalBaseURI="http://localhost:9080/api/v2/"
    s=sXML.replace('<container uri="'+BASE_URI+'containers/','')
    s=sXML.replace('<container uri="'+sLocalBaseURI+'containers/','')
    s=s.replace('"/>', '')
    s="".join(s.split())
    
    return s
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

def get_container_name(containerID):
    #global URI_base, user,psw
    sURI=BASE_URI+'containers/'+containerID
#    print('\n')
#    print (sURI)
    #print('\n')
    r = requests.get(sURI, auth=(user, psw), verify=True)
    #print (r.content)
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue

    return ss
def get_retrieve_and_update_container(containerID):
    #global URI_base, user,psw
    sURI=BASE_URI+'containers/'+containerID
    #print (sURI)
    r = requests.get(sURI, auth=(user, psw), verify=True)    
    sXML = extract_artifacts(r.content)
    #print(r.content)
    retXML= retrieve_artifacts(sXML)
    
    update_artifact(retXML, containerID)
    return

def extract_artifacts(sXML):
    s=""
    rDOM = parseString( sXML )
    scNodes =rDOM.getElementsByTagName('placement')
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for sc in scNodes:
        scURI = sc.getAttribute( "uri")
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML )    
    return lXML

def retrieve_artifacts(sXML):
    #global URI_base, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content

def update_artifact(sXML,containerID):
    global data_quant, container_barcodes, script_dir
    bNames=-1

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact"}
    root = ET.fromstring(sXML)
    
    #apps = root.getchildren()
    ss="H:12"
    s=""
    i=0
    
    for appt in root.findall('art:artifact', nss):
        #print ("%s=%s" % (appt[7].tag, appt[7].text))
        udf_child = appt.findall('udf:field',nss)

        #print (len(udf_child))
        appt_child = appt.find('location')
        position= appt_child.find('value')
        barcode=container_barcodes[containerID]
        quant_value=data_quant[barcode+'_'+position.text]        
        bNames=-1
        for udf_node in udf_child:
            if (udf_node.attrib['name'] == 'Concentration'):
                udf_node.text=quant_value
                print (len(appt),position.text,udf_node.attrib['name'],udf_node.text, quant_value)
                bNames=1
        if (bNames <0):
            new_element=ET.Element('udf:field', {'name': 'Concentration',  'type':'Numeric'})
            new_element.text=str(quant_value)
            new_element.tail="\n"
            appt.insert(len(appt)-2,new_element)              

    i=i+1
    tree =ET.ElementTree(root)
    xmlns_udf="http://genologics.com/ri/userdefined"
    xmlns_file="http://genologics.com/ri/file" 
    xmlns_art="http://genologics.com/ri/artifact"
    ns = {"xmlns:udf": xmlns_udf, "xmlns:file": xmlns_file, 'xmlns:art':xmlns_art}    
    for attr, uri in ns.items():
        ET.register_namespace(attr.split(":")[1], uri)
    tree.write(script_dir+'/quant_tmp.xml', 
           xml_declaration = True,
           encoding = 'utf-8',
           method = 'xml')
    
    if (bNames <0):
        find_replace_in_file_file(script_dir+'/quant_tmp.xml')
    post_batch_artifacts('quant_tmp.xml')
    return 


def find_replace_in_file_file(sample_file_input):
    global strFind, strReplace
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
  

'''
    Start
    
'''
setupGlobalsFromURI(processURI_v2)

calibrationFile= get_local_PG_file(fileLuid)
print (calibrationFile)


scan_4_files(calibrationFile,'.asc', raw_barcodes)
scan_4_files(calibrationFile,'.quant', quant_barcodes)
print ("ASC barcodes:")
print (raw_barcodes)
print ("Quant barcodes:")
print (quant_barcodes)
fill_data_quant_hash(quant_barcodes)
get_placement_containers(stepURI_v2)

print (container_barcodes)


#print (data_quant)


