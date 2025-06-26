'''
Created on JAnuary 16, 2016

@author: Alexander Mazur, alexander.mazur@gmail.com

    updated 2018_05_01:
        - file extension for absorbtion file has been changed to  ".abs" from ".asc"


'''
__author__ = 'Alexander Mazur'


import os, argparse, shutil, logging, math, os
import numpy as np
import numpy.polynomial.polynomial as poly
import time
import requests
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET


  

user=''
psw=''
# URI_base='https://bravotestapp.genome.mcgill.ca/api/v2/'
HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False

script_dir=os.path.dirname(os.path.realpath(__file__))
temp_dir="/opt/gls/clarity/ai/temp"

parser = argparse.ArgumentParser(description='Applying quantified concentration values to the WebUI')
parser.add_argument('-stepURI_v2',default='', help='stepURI_v2 from WebUI')
parser.add_argument('-fileLuid',default='', help='fileLuid from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')

'''
{stepURI:v2}
http://localhost:9080/api/v2/steps/24-1297
'''
args = parser.parse_args()
fileLuid=args.fileLuid
stepURI_v2=args.stepURI_v2
user_psw = args.user_psw

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
sDataPath='/data/glsftp/clarity/'
sSubFolderName=sDataPath+time.strftime('%Y/%m/')
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
        if (file.endswith(file_ext)) :
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
        '''    
        for PicoGreen
        '''
        # get_data_quant(input_file)
        get_absorb_data_quant(input_file)
    return

def get_absorb_data_quant(sample_file_input):
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
        i=i+1
    
    i=0
    while i < len(lines):
        s=lines[i].upper()
        s=s.replace('\n','')
        sConcentration="0"
        sMass="0"
        if (s.find('DATE')>=0):
            bStart=-1          
        if (bStart>0):
#            s_split=s.split('\t')
            s_split=s.split(',')
            
            if DEBUG:
                print (plateID+'_'+s_split[0])
                
            if s_split[4]:
                sConcentration=s_split[4]
            if s_split[6]:
                sMass=s_split[6]
                
                    
            data_quant[plateID+'_'+s_split[0]]=sConcentration+'xxx'+sMass   
        if (s.find('CONCENTRATION')>=0):
            bStart=1
  
        i=i+1          
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
     
def get_local_Absorb_folder(stepURI_v2):
    global sSubFolderName
    ss = sSubFolderName+stepURI_v2.split('/')[-1]
    return  ss    
def get_local_Abs_file(FileLuid):
    global user,psw, BASE_URI
    r = requests.get(BASE_URI+'artifacts/'+FileLuid, auth=(user, psw), verify=True)
    root = ET.fromstring(r.content)
    #print (r.content)

    namespaces={'file':'http://genologics.com/ri/file'}
    for sFile in root.findall('file:file', namespaces):
        '''
        '''
        #print (sFile.attrib, sFile.tag)
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
    for node in rDOM.getElementsByTagName('selected-containers'):
        cc=node.getElementsByTagName('container')[0]
        contNode=cc.getAttribute('uri')
        containerID=contNode.split('/')[-1]
        #ss=extract_container_ID (s)
        if (containerID):
#            kk=":".join("{:02x}".format(ord(c)) for c in ss)
            sName=get_container_name(containerID)
            container_barcodes[containerID]=sName
            get_retrieve_and_update_container(containerID)
            print ('containerID:\t'+containerID+'\tbarcodeID:\t'+sName)
        i=i+1
    return
def post_batch_artifacts(xmlFile):
    global BASE_URI, user,psw, script_dir, temp_dir
    sURI=BASE_URI+'artifacts/batch/update'
    sXMLfile=temp_dir +'/'+xmlFile
    XML_STRING = open(sXMLfile).read()
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=XML_STRING, auth=(user, psw), verify=True, headers=headers)
    print (r.content)
    #rDOM = parseString( r.content )    
    return

def extract_container_ID (sXML):
    global BASE_URI
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
    global BASE_URI, user,psw
    sURI=BASE_URI+'containers/'+containerID
#    print('\n')
#    print (sURI)
#    print('\n')
    r = requests.get(sURI, auth=(user, psw), verify=True)
    # print (r.content)
    rDOM = parseString(r.content )
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue

    return ss
def get_retrieve_and_update_container(containerID):
    global BASE_URI, user,psw
    sURI=BASE_URI+'containers/'+containerID
    #print (sURI)
    r = requests.get(sURI, auth=(user, psw), verify=True)    
    sXML = extract_artifacts(r.content)
    
    # print(sXML)
    retXML= retrieve_artifacts(sXML)
    #print (retXML)
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
    global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    #print (r.content)
    #rDOM = parseString( r.content )    
    return r.content

def update_artifact(sXML,containerID):
    global data_quant, container_barcodes, script_dir, temp_dir
    bNames=-1

    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact"}
    xmlns_udf="http://genologics.com/ri/userdefined"
    xmlns_file="http://genologics.com/ri/file" 
    xmlns_art="http://genologics.com/ri/artifact"
    ns = {"xmlns:udf": xmlns_udf, "xmlns:file": xmlns_file, 'xmlns:art':xmlns_art}    
    for attr, uri in ns.items():
        #print (attr, uri)
        ET.register_namespace(attr, uri)
    
    root = ET.fromstring(sXML)
    
    apps = root.getchildren()
    ss="H:12"
    s=""
    i=0
    
    for appt in apps:
        #print ("%s=%s" % (appt[7].tag, appt[7].text))
        udf_child = appt.findall('udf:field', nss)
        appt_children = appt.find('location')
       
        for appt_child in appt_children:
            #print ("%s=%s" % (appt_child.tag, appt_child.text))
            s=appt_child.text
            stag=appt_child.tag
            if (stag=='value'):
                #print ("%s=%s" % (appt_child.tag, appt_child.text))
                barcode=container_barcodes[containerID]
                '''
                containerID
                '''
                new_position=appt_child.text.replace(":","")
                #quant_value=data_quant[containerID+'_'+appt_child.text]
                quant_value=data_quant[containerID+'_'+new_position]
                if (len(udf_child)>0):
                    bNames=1
                    for udf_item in udf_child:
                        if udf_item.attrib['name'] == 'Mass':
                            udf_item.text=quant_value.split('xxx')[1]
                        if udf_item.attrib['name'] == 'Concentration':
                            udf_item.text=quant_value.split('xxx')[0]                    
                    #print (udf_item.attrib['name']+'\t'+udf_item.text+'\t'+quant_value.split('xxx')[0]+'\t'+quant_value.split('xxx')[1]) 
                    
                    
                if not any("Mass" in s.attrib['name'] for s in udf_child):
                    #print ('Mass didnt find')
                    new_element=ET.Element('udf:field', {'name': 'Mass',  'type':'Numeric'})
                    new_element.text=quant_value.split('xxx')[1]
                    new_element.tail="\n"
                    appt.insert(6,new_element)                                
                if not any("Concentration" in s.attrib['name'] for s in udf_child):
                    #print ('Concentration  didnt find')                        
                    new_element=ET.Element('udf:field', {'name': 'Concentration',  'type':'Numeric'})
                    new_element.text=quant_value.split('xxx')[0]
                    new_element.tail="\n"
                    appt.insert(6,new_element)                                
                                                
                        

 
                    
                    #udf_child[0].text=quant_value
                
                
    i=i+1
    # tree =ET.ElementTree(root)
    xmlns_udf="http://genologics.com/ri/userdefined"
    xmlns_file="http://genologics.com/ri/file" 
    xmlns_art="http://genologics.com/ri/artifact"
    ns = {"xmlns:udf": xmlns_udf, "xmlns:file": xmlns_file, 'xmlns:art':xmlns_art}    
    for attr, uri in ns.items():
        ET.register_namespace(attr.split(":")[1], uri)
#    for pref, uri in nss.items():
#        ET.register_namespace(pref, uri)
    
    tree =ET.ElementTree(root)

    tree.write(temp_dir+'/quant_tmp.xml', 
           xml_declaration = True,
           encoding = 'utf-8',
           method = 'xml')
    
    
    '''
    Patch for XML file namespaces
    '''
    if (bNames <0):
        find_replace_in_file_file(temp_dir+'/quant_tmp.xml')
    post_batch_artifacts('quant_tmp.xml')
    return 


def find_replace_in_file_file(sample_file_input):
    global strFind, strReplace
    print (sample_file_input)
    with open(sample_file_input, 'r', encoding='utf-8', errors='ignore') as file :
        filedata = file.read()
    filedata = filedata.replace(strFind, strReplace)
    
    (fileName, fileExt)=os.path.splitext(sample_file_input)
    sample_file_output=fileName+'.xml'
    
    with open(sample_file_output, 'w', encoding='utf-8', errors='ignore') as file:
        file.write(filedata)    
    return
       
    
'''
    Start
    
'''

setupGlobalsFromURI(stepURI_v2)

calibrationFile= get_local_Abs_file(fileLuid)
print (calibrationFile)

#absobFolder= get_local_Absorb_folder(stepURI_v2)
#calibrationFile = absobFolder+'/t.t'




#scan_4_files(calibrationFile,'.asc', quant_barcodes)
scan_4_files(calibrationFile,'.asc', quant_barcodes)

print ("Quant barcodes:")
print (quant_barcodes)
fill_data_quant_hash(quant_barcodes)
#print (data_quant)
get_placement_containers(stepURI_v2)

print (container_barcodes)





