'''
 __author__ = 'AlexanderMazur'
September 10, 2018 



'''
import sys,os, socket
import os.path
import pprint

import requests
from optparse import OptionParser
from xlrd import open_workbook
from xml.dom.minidom import parseString

DEBUG=False



def setupArguments():
    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-i', "--inputFIleLUID", action='store', dest='inputFIleLUID')    
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


    

def get_workbook_data(sPath):
    #print (sPath)
    wb = open_workbook(sPath)
    worksheet=wb.sheet_by_name("Kits_to_use")
    total_rows=worksheet.nrows
    total_columns=worksheet.ncols
    sHeader="Lot Name\tReagent Name\tCatalog Number\tLot Number\tExpiration date"
    #print (sHeader)
    for row in range(1,total_rows):
        val=worksheet.cell(row,0).value
        
        ss=''
        if val:
            kitName=worksheet.cell(row,1).value
            kitURI=get_reagentkit_uri(kitName)
            if kitURI:
                LotName=worksheet.cell(row,0).value
                LotNumber=str(worksheet.cell(row,3).value)
                ExpirationDate=worksheet.cell(row,4).value
                lotXML=prepare_kit_lot(LotName,kitName,kitURI,LotNumber,ExpirationDate)
                #print (lotXML)
                r=post_kit_lot(lotXML)
                print(r)
                '''
                for col in range(0,total_columns-1):
                    ss +=worksheet.cell(row,col).value+"\t"
                '''    
            else:
                print ("!!Error: lot "+val+" was not added to Clarity. Can't find '"+kitName+"' reagent kit")    
            
            

def get_reagentkit_uri(sKitName):
    sURL=BASE_URI+"reagentkits?name="+sKitName
    #print (sURL)
    r = requests.get(sURL, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    try:
        kitURI= rDOM.getElementsByTagName("reagent-kit")[0].getAttribute('uri')
    except:
        kitURI=''
    return kitURI

def prepare_kit_lot(sLotName,sKitName,sKitURI,sLotNumber,sExpirationDate):
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n' )
    lXML.append('<lot:reagent-lot xmlns:lot="http://genologics.com/ri/reagentlot">\n')
    lXML.append( '<reagent-kit uri="'+sKitURI+'" name="'+sKitName+'"/>\n' )
    lXML.append( '<name>'+sLotName+'</name>\n' )  
    lXML.append( '<lot-number>'+sLotNumber+'</lot-number>\n' )
    lXML.append( '<expiry-date>'+sExpirationDate+'</expiry-date>\n' )
    lXML.append( '<status>ACTIVE</status>\n')
    lXML.append( '</lot:reagent-lot>\n' )

    lXML = ''.join( lXML ) 
    return lXML 

def post_kit_lot(sXML):
    sURL=BASE_URI+"reagentlots"
    headers = {'user-agent': 'py_post','Content-Type':'application/xml'}
    print (sURL,sXML)
    r = requests.post(sURL, sXML,auth=(user, psw),headers=headers, verify=True)    
    
    return r

def getFileLocation(rfLUID ):

    ## get the details from the resultfile artifact
    aURI = BASE_URI + "artifacts/" + rfLUID
    if DEBUG is True:
        print( "Trying to lookup: " + aURI )
    aXML = requests.get( aURI,auth=(user, psw), verify=True )
    if DEBUG is True:
        print (aXML)
    aDOM = parseString( aXML.content )

    ## get the file's details
    nodes = aDOM.getElementsByTagName( "file:file" )
    if len(nodes) > 0:
        fLUID = nodes[0].getAttribute( "limsid" )
        fileURI=nodes[0].getAttribute( "uri" )
        dlURI = BASE_URI  + "files/" + fLUID + "/download"
        fXML = requests.get( fileURI,auth=(user, psw), verify=True )
        if DEBUG is True:
            print(fXML.content )
        fDOM = parseString( fXML.content )
        flocNode = fDOM.getElementsByTagName( "content-location" )[0].firstChild.data
        fileLocation=flocNode.replace(sftpHOSTNAME,'')
        if DEBUG is True:
            print( "file location %s" % flocNode+"\n"+ fileLocation)


    return fileLocation 



def main():

    global args, user,psw
    args = setupArguments()
    stepURI=args.stepURI
    user=args.username
    psw=args.password    
    setupGlobalsFromURI(args.stepURI)


    inputFIleLUID=args.inputFIleLUID
    
    execlFileName=getFileLocation(inputFIleLUID)
    #print (execlFileName)
    
    get_workbook_data(execlFileName)    
    


if __name__ == '__main__':
    main()