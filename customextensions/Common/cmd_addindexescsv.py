from optparse import OptionParser
import glsapiutil
from xml.dom.minidom import parseString
import logging
import datetime

# This script expects the file to have three columns, in the order: Reagent Name,Sequence,Reagent Category
HOSTNAME = "bravotestapp.genome.mcgill.ca"
newLine = "\r"



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
    f_file = str( f_location.firstChild.data.partition( HOSTNAME )[2] )

    return f_file


def cmdImportIndexes():

    file_loc = indexFile
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
    Parser.add_option('-s', "--clarityserver", action='store', dest='clarityserver')
    Parser.add_option('-f', "--file", action='store', dest='file')
    

    return Parser.parse_args()[0]

def main():

    global args
    args = setupArguments()

    global api, indexFile
    api = glsapiutil.glsapiutil2()
    api.setURI( args.clarityserver )
    api.setup( args.username, args.password )
    indexFile=args.file
    print (api.getBaseURI())
    


    exit()
    cmdImportIndexes()
    

if __name__ == "__main__":
    main()