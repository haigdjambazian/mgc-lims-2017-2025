'''
Created on Feb 22, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
'''
__author__ = 'Alexander Mazur'

import sys
from optparse import OptionParser
from xml.dom.minidom import parseString
import datetime
import glsapiutil

def setupArguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    return Parser.parse_args()[0]

def parse_xml( xml ):

    try:
        dom = parseString( xml )
        return dom
    except:
        sys.exit(3)

def buildGroupPoolXML( poolName, alist ):

    pXML = '<pool name="' + poolName +'">'
    for aURI in alist:
        pXML = pXML + '<input uri="' + aURI + '"/>'
    pXML = pXML + '</pool>'
    return pXML

def autoPool():

    pooling_groupUDFname = "Pooling Group"

    pGROUPS = {}    # pooling groups

    # what artifacts are being pooled
    # what are their pooling groups?

    poolsURI = args.stepURI + "/pools"
    poolDOM = parse_xml( api.GET( poolsURI ) )
    stepConfigurationNode = poolDOM.getElementsByTagName("configuration")[0].toxml()
    input_artifacts = [ x.getAttribute("uri") for x in poolDOM.getElementsByTagName("input")]
    input_artsDOM = parse_xml( api.getArtifacts( input_artifacts ) )

    # sort the inputs into their pooling groups
    i=1

    for art in input_artsDOM.getElementsByTagName("art:artifact"):
        pooling_group = api.getUDF( art, pooling_groupUDFname )
        artURI = art.getAttribute("uri").split("?")[0]
        if pooling_group=="":
            pooling_group="Pool #"+str(i)
            i+=1
            
        if pooling_group not in pGROUPS:
            pGROUPS[ pooling_group ] = [ artURI ]
        else:
            pGROUPS[ pooling_group ].append( artURI )

    ## let's build the pooling XML based upon the groups
    pXML = '<?xml version="1.0" encoding="UTF-8"?>'
    pXML = pXML + '<stp:pools xmlns:stp="http://genologics.com/ri/step" uri="' + args.stepURI +  '/pools">'
    pXML = pXML + '<step uri="' + args.stepURI + '"/>'
    pXML = pXML + stepConfigurationNode
    pXML = pXML + '<pooled-inputs>'

    for key in pGROUPS.keys():
        groupContents = pGROUPS[ key ]
        pXML = pXML + buildGroupPoolXML( key, groupContents )

    pXML = pXML + '</pooled-inputs>'
    pXML = pXML + '<available-inputs/>'
    pXML = pXML + '</stp:pools>'

    print pXML
    print  args.stepURI + "/pools"
    response = api.PUT( pXML, args.stepURI + "/pools" )
    print response


def main():

    global args
    args = setupArguments()

    global api
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )

    autoPool()

if __name__ == "__main__":
    main()
