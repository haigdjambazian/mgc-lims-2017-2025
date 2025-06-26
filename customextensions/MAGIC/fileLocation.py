#!/bin/sh
'''
Created on June 4, 2019

    The Script designed to provide local path of the attached file

    @author: Alexander Mazur, alexander.mazur@gmail.com
    updated:
        2019_06_07:
            - added "Project ID" field on step form
            - added generic input file format - <excel|tab>
            - added comples project info - ProjectID+ProjectName+ResearcherName


Note:

python_version=3.5
 
'''
script_version="2019_06_07"

__author__ = 'Alexander Mazur'

import getopt,sys
from optparse import OptionParser
import xml.dom.minidom
import urllib
import datetime
import logging
import requests,socket
from xml.dom.minidom import parseString
import subprocess


def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-a', "--attachLUID", action='store', dest='attachLUID')



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

def get_project_meta(projectLUID):
    qURI = BASE_URI + "projects/" + projectLUID
    qXML = requests.get(qURI, auth=(user, psw), verify=True)
    qDOM = parseString( qXML.content )

    nodes=qDOM.getElementsByTagName( "prj:project" )
    if len(nodes)>0:
    
        for node in nodes:
            projectName = node.getElementsByTagName( "name" )[0].firstChild.data
            researcherURI=node.getElementsByTagName( "researcher" )[0].getAttribute('uri')  
            firstName, lastName = get_research_meta(researcherURI)
            
    else:
        print("Error_there_is_no_project_LUID___"+projectLUID)
        sys.exit(111)
    return projectName, firstName, lastName
    
       

def get_research_meta(researcherURI):
    
    qXML = requests.get(researcherURI, auth=(user, psw), verify=True)
    qDOM = parseString( qXML.content )

    for node in qDOM.getElementsByTagName( "res:researcher" ): 
    
        firstName = node.getElementsByTagName( "first-name" )[0].firstChild.data
        lastName = node.getElementsByTagName( "last-name" )[0].firstChild.data
    
    return firstName, lastName        

def getFileLocation(rfLUID ):
    fileLocation=""
    aURI = BASE_URI + "artifacts/" + rfLUID
    if DEBUG is True:
        print( "Trying to lookup: " + aURI )

    aXML = requests.get(aURI, auth=(user, psw), verify=True)
    

    aDOM = parseString( aXML.content )

    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        fileURI=nodes[0].getAttribute( "uri" )
        dlURI = BASE_URI  + "files/" + fLUID + "/download"
        #fXML = api.GET( fileURI )
        fXML = requests.get(fileURI, auth=(user, psw), verify=True)
        if DEBUG is True:
            print(fXML.content )
        fDOM = parseString( fXML.content )
        flocNode = fDOM.getElementsByTagName( "content-location" )[0].firstChild.data
        fileLocation=flocNode.replace(sftpHOSTNAME,'')
        fileLocation=fileLocation.replace('sftp://bravoprodapp.genome.mcgill.ca','')
        if DEBUG is True:
            print( "file location %s" % flocNode+"\n"+ fileLocation)

    return fileLocation

def get_process_UDFs(ProcessID):
    
    processURI=BASE_URI+'processes/'+ProcessID
    
    r = requests.get(processURI, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    sudfValue={}
    udfNodes= rDOM.getElementsByTagName("udf:field")        
    for key in udfNodes:
        udfName = key.getAttribute( "name")

        sudfValue[udfName]=str(key.firstChild.nodeValue)

          
    return  sudfValue

'''

    START
    
'''



def main():

    global api
    global ARGS
    global TODAY, LOG,COLS,ROWS,DEBUG,args,user, psw
    DEBUG=False

    args = setup_arguments()
    user=args.username
    psw=args.password
    tempDir=" /opt/gls/clarity/ai/temp/submission "
    

    fileAttachmentPlace=args.attachLUID
    
        
    setupGlobalsFromURI( args.stepURI )
    projectUDF=get_process_UDFs(ProcessID)
    projectLUID=projectUDF['Project ID']
    #studyDesignID=projectUDF['Study Design ID']
    
    (projectName, firstName, lastName)=get_project_meta(projectLUID)
    
    #combinedProjectName=projectLUID+"_"+projectName.replace(" ","_")+"_"+firstName.replace(" ","_")+"_"+lastName.replace(" ","_")
    combinedProjectName=projectLUID+"_"+projectName+"_"+firstName+"_"+lastName

    fileLocation = getFileLocation(fileAttachmentPlace )
    new_process=ProcessID#+":"+studyDesignID
    sOUT=tempDir+new_process+"  "+ combinedProjectName.replace(" ","_") +"  "+fileLocation
    
    sys.stdout.flush()
    sys.stdout.write(sOUT)
        
    

if __name__ == "__main__":
    main()
    