import sys,os, socket
from optparse import OptionParser

sys.path.append('/opt/gls/clarity/customextensions/Common') # path to common glsutils files
import glsapiutil
from xml.dom.minidom import parseString
import logging
import datetime
import re

# This script expects the file to have three columns, in the order: Reagent Name,Sequence,Reagent Category
#HOSTNAME = "bravotestapp.genome.mcgill.ca"
newLine = "\r"
DEBUG=True


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

    artif_URI = BASE_URI+ "artifacts/" + file_art_luid
    #artif_URI = limsServer + "/artifacts/" + file_art_luid
    aXML = api.GET( artif_URI )
    if DEBUG is True:
        print (artif_URI,aXML)
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
    if DEBUG is True:
        print (file_loc)
    raw = open ( file_loc, "r")
    IndexList = raw.readlines()
    raw.close
  

    count = 0
    for line in IndexList:

        ReagentName, Sequence, ReagentCategory = line.split("\t")
        ReagentCategory=ReagentCategory.replace("\r\n","")
        ReagentCategory=ReagentCategory.replace("\n","")
        
        #print ReagentName, Sequence, ReagentCategory

        rtpXML = [ '<?xml version="1.0" encoding="UTF-8"?><rtp:reagent-type xmlns:rtp="http://genologics.com/ri/reagenttype"' ]
        rtpXML.append( ' name="' + ReagentName + '"><special-type name="Index">' )
        rtpXML.append( '<attribute value="' + Sequence + '" name="Sequence"/></special-type>' )
        rtpXML.append( '<reagent-category>' + ReagentCategory + '</reagent-category></rtp:reagent-type>' )
        if DEBUG is True:
            print (rtpXML,limsServer + "/reagenttypes")
        try:
            if min( n in 'CTAG-' for n in Sequence ):
                # Checks The sequence is valid nucliotides

                #r = api.POST( ''.join( rtpXML ), api.getBaseURI() + "reagenttypes" )
                r = api.POST( ''.join( rtpXML ), limsServer + "/reagenttypes" )
                if DEBUG is True:
                    print r
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
    
    
        
    
    

def importIndexes():

    csvData = downloadfile( args.fileLUID ).split("\n")[0]
    print (csvData)

    IndexList = csvData.split( newLine )[1:]
    print (str(IndexList))
    IndexList = list( i for i in IndexList if len(i) > 2 )
    logging.info(' Attempting to add ' + str(len(IndexList)) + ' Indexes' )

    count = 0
    for line in IndexList:

        ReagentName, Sequence, ReagentCategory = line.split(",")
        #print ReagentName, Sequence, ReagentCategory

        rtpXML = [ '<?xml version="1.0" encoding="UTF-8"?><rtp:reagent-type xmlns:rtp="http://genologics.com/ri/reagenttype"' ]
        rtpXML.append( ' name="' + ReagentName + '"><special-type name="Index">' )
        rtpXML.append( '<attribute value="' + Sequence + '" name="Sequence"/></special-type>' )
        rtpXML.append( '<reagent-category>' + ReagentCategory + '</reagent-category></rtp:reagent-type>' )
        try:
            if min( n in 'CTAG' for n in Sequence ):
                # Checks The sequence is valid nucliotides

                r = api.POST( ''.join( rtpXML ), limsServer + "/reagenttypes" )
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
    #Parser.add_option('-y', "--clarityServer", action='store', dest='clarityServer', default='https://bravotestapp.genome.mcgill.ca/api/v2')
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

def get_lims_server(stepURI_v2):
    global limsServer
    aXML = api.GET( stepURI_v2+"/details" )
    rDOM = parseString( aXML )
    #r = requests.get(processURI_v2, auth=(user, psw), verify=True)
    #rDOM = parseString(r.content)
    nodes= rDOM.getElementsByTagName("stp:details")
    for input in nodes:
        uriType = input.getAttribute( "uri" )
        limsidType = input.getAttribute( "limsid" )
            
    limsServer=getUDF(rDOM, 'Clarity Server')
   

    return limsServer

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

def getUDF( rDOM, udfname ):
    response = ""
    elements = rDOM.getElementsByTagName( "udf:field" )
    for udf in elements:
        temp = udf.getAttribute( "name" )
        if temp == udfname:
            response = getInnerXml( udf.toxml(), "udf:field" )
            break
    return response

def main():

    global args,  api,limsServer
    args = setupArguments()
    stepURI=args.stepURI

    api = glsapiutil.glsapiutil2()
    api.setURI( stepURI )
    api.setup( args.username, args.password )
        
    setupGlobalsFromURI( stepURI )
    
    limsServer=get_lims_server(stepURI)
    if DEBUG is True:
        print (limsServer)
    #exit()

    

    logging.basicConfig(filename= args.logfileLUID ,level=logging.DEBUG)
    logging.info(' Adding Indexes ' + str( datetime.datetime.now() ))

#    importIndexes()
    myImportIndexes()

if __name__ == "__main__":
    main()