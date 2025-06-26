'''
 __author__ = 'AlexanderMazur'
September 1, 2018 


python 2.7
'''

import sys,os, socket
from optparse import OptionParser
import glsapiutil
from xml.dom.minidom import parseString
import logging
import datetime

# This script expects the file to have three columns, in the order: Reagent Name,Sequence,Reagent Category
#HOSTNAME = "bravotestapp.genome.mcgill.ca"
newLine = "\r"
DEBUG=False


def downloadfile( file_art_luid ):

    artif_URI = api.getBaseURI() + "artifacts/" + file_art_luid
    aXML = api.GET( artif_URI )
    aDOM = parseString( aXML )
    anodes = aDOM.getElementsByTagName( 'file:file' )
    for child in anodes:
        fileuri = child.getAttribute( 'uri' )
    fXML = api.GET( fileuri )
    fDOM = parseString( fXML )
    f_node = fDOM.getElementsByTagName( 'content-location' )
    f_location = f_node.item(0)
    f_file = str( f_location.firstChild.data.partition( HOSTNAME )[2] )
    raw = open ( f_file, "r")
    r = ''.join(raw.readlines())
    
    raw.close
    print (r)
    return r


def file_location (file_art_luid): 

    artif_URI = api.getBaseURI() + "artifacts/" + file_art_luid
    aXML = api.GET( artif_URI )
    aDOM = parseString( aXML )
    anodes = aDOM.getElementsByTagName( 'file:file' )
    for child in anodes:
        fileuri = child.getAttribute( 'uri' )
    fXML = api.GET( fileuri )
    fDOM = parseString( fXML )
    f_node = fDOM.getElementsByTagName( 'content-location' )
    f_location = f_node.item(0)
    f_file = str( f_location.firstChild.data.partition( sftpHOSTNAME )[2] )

    return f_file


def myImportIndexes():

    file_loc = file_location( args.fileLUID )
    #print (file_loc)
    raw = open ( file_loc, "r")
    IndexList = raw.readlines()
    raw.close
  

    count = 0
    for line in IndexList:

        ReagentName, Sequence, ReagentCategory = line.split("\t")
        ReagentCategory=ReagentCategory.replace("\r\n","")
        #print ReagentName, Sequence, ReagentCategory

        rtpXML = [ '<?xml version="1.0" encoding="UTF-8"?><rtp:reagent-type xmlns:rtp="http://genologics.com/ri/reagenttype"' ]
        rtpXML.append( ' name="' + ReagentName + '"><special-type name="Index">' )
        rtpXML.append( '<attribute value="' + Sequence + '" name="Sequence"/></special-type>' )
        rtpXML.append( '<reagent-category>' + ReagentCategory + '</reagent-category></rtp:reagent-type>' )
        try:
            if min( n in 'CTAG-' for n in Sequence ):
                # Checks The sequence is valid nucliotides

                r = api.POST( ''.join( rtpXML ), api.getBaseURI() + "reagenttypes" )
                #print r
                if len( parseString( r ).getElementsByTagName("exc:exception")) > 0 :
                    logging.warning( str( ReagentName ) + ' could not be added. (code1)' )
                    logging.warning( str( parseString( r ).getElementsByTagName("message")[0].firstChild.data ) )
                else:
                    count += 1
            else:
                logging.warning( str( ReagentName ) + ' does not have a valid nucleotide sequence. This Index was not added.' )
        except:
            logging.warning( str( ReagentName ) + ' could not be added. (code2)' )

    print str( count ) + " new indexes were added to Clarity."
    logging.info( str( count ) + " of " + str(len(IndexList)) + " new indexes were added to Clarity.")
    
    
        
    
    



def setupArguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-f', "--fileLUID", action='store', dest='fileLUID')
    Parser.add_option('-l', "--logfileLUID", action='store', dest='logfileLUID')

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

def main():

    global args
    args = setupArguments()
    setupGlobalsFromURI( args.stepURI )

    global api
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    logging.basicConfig(filename= args.logfileLUID ,level=logging.DEBUG)
    logging.info(' Adding Indexes ' + str( datetime.datetime.now() ))


    myImportIndexes()

if __name__ == "__main__":
    main()