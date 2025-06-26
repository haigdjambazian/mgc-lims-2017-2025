# -*- coding: UTF-8 -*-
# ^^^ that needs to be the first line ^^^
#
# __author__ = 'dcrawford'
# Oct 11 2016
# https://genologics.zendesk.com/hc/en-us/articles/215270083
# revised Feb 6 2018
    # added ascii UTF-8 encoding
    # added default -k  default=""

import sys
reload(sys)
sys.setdefaultencoding('utf8')

from optparse import OptionParser
import glsapiutil
from xml.dom.minidom import parseString
import urllib

DEBUG = True

XMLFileName = '/ReagentKitsLotsXML' # The exported data file will be named this

def setupArguments():

    Parser = OptionParser()

    Parser.add_option('-s', "--clarityserver", action='store', dest='clarityserver')    #Clarity API address
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-k', "--reagentkits", action='store', default="", dest='reagentkits')    #optional, by default will export all reagent-kits
    Parser.add_option('-d', "--dir", action='store', default='.', dest='dir')       #optional, by default current working directory

    Parser.add_option('--skipKits', "--skipKits", action="store_true", default=False, dest='skipKits') #optional, if envoked, will not write any reagent kit data to file
    Parser.add_option('--skipLots', "--skipLots", action="store_true", default=False, dest='skipLots') #optional, if envoked, will not write any reagent lot data to file

    return Parser.parse_args()[0]

def main():

    global args
    args = setupArguments()

    global api
    api = glsapiutil.glsapiutil2()
    api.setURI( args.clarityserver )
    api.setup( args.username, args.password )

    lotsearchURI = api.getBaseURI() + "reagentlots"
    kitsearchURI = api.getBaseURI() + "reagentkits"

    if len( args.reagentkits ) > 0:
        print 'Gathering Specific Kits'
        kitnames = [kit.strip() for kit in args.reagentkits.split(",")]  # removes whitespace
        first = True
        for kit in kitnames:
            if first:
                lotsearchURI += "?"
                kitsearchURI += "?"
                first = False
            else:
                lotsearchURI += "&"
                kitsearchURI += "&"
            lotsearchURI += 'kitname=' + urllib.quote( kit )
            kitsearchURI += 'name=' + urllib.quote( kit )

    else: print 'Gathering All Kits'
    if DEBUG: print lotsearchURI, kitsearchURI

    reagentLotXML = api.GET( lotsearchURI )
    reagentKitXML = api.GET( kitsearchURI )

    DatafileName = args.dir + XMLFileName
    if DEBUG: print DatafileName

    f = open(DatafileName,"w")
    f.write( '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Document>' )

    # Write the reagent kit XML to the file
    if not args.skipKits:
        for kit in parseString( reagentKitXML ).getElementsByTagName( "reagent-kit" ):
            kitXML = parseString( api.GET( kit.getAttribute("uri") )).getElementsByTagName( "kit:reagent-kit" )[0].toxml()
            f.write( kitXML )

    # Write the reagent lot XML to the file
    if not args.skipLots:
        for lot in parseString( reagentLotXML ).getElementsByTagName( "reagent-lot" ):
            lotXML = parseString( api.GET( lot.getAttribute("uri") )).getElementsByTagName( "lot:reagent-lot" )[0].toxml()
            f.write( lotXML )

    f.write( '</Document>')
    f.close()

if __name__ == "__main__":
    main()

