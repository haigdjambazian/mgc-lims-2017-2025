'''
Created on August 2, 2018

@author: Alexander Mazur, alexander.mazur@gmail.com
    
Note: 

python 2.7
'''


__author__ = 'Alexander Mazur'


import glsapiutil
import xml.dom.minidom
import sys

from xml.dom.minidom import parseString
from optparse import OptionParser

DEBUG = False
api = None
options = None

def checkFilesArePresent():

	missingFiles = []

	## process the -f argument
	fLUIDS = []
	tokens = options.fileLUID.split( "," )
	for token in tokens:
		fLUIDS.append( token.strip() )

	if DEBUG is True:
		print( "Examining ResultFile Placeholders: ", fLUIDS )

	if len( fLUIDS ) > 0:

		baXML = api.getArtifacts( fLUIDS )
		baDOM = parseString( baXML )
		for aDOM in baDOM.getElementsByTagName( "art:artifact" ):
			fNodes = aDOM.getElementsByTagName( "file:file" )
			if len(fNodes) == 0:
				## this file is absent:
				fName = aDOM.getElementsByTagName( "name" )[0].firstChild.data
				missingFiles.append( fName )

	## do we have any missing files?
	missingFileCount = len(missingFiles)
	if missingFileCount > 0:

		if missingFileCount == 1:
			msg = "You must attach files to the following placeholder: %s" % missingFiles[0]
		else:
			msg = "You must attach files to the following placeholders: %s" % ", ".join( missingFiles )

		if DEBUG is True:
			print( msg )
		else:
			#api.reportScriptStatus( options.stepURI, "ERROR", msg )
			print(msg)
			sys.exit(111)

def main():

	global api
	global options

	parser = OptionParser()
	parser.add_option( "-u", "--username", action = "store", dest = "username", type = "string", help = "username of the current user" )
	parser.add_option( "-p", "--password", action = "store", dest = "password", type = "string", help = "password of the current user" )
	parser.add_option( "-s", "--stepURI", action = "store", dest = "stepURI", type = "string", help = "the URI of the step that launched this script" )
	parser.add_option( "-f", "--fileLUID", action = "store", dest = "fileLUID", type = "string", help = "the LUID of the file(s) that is mandatory - if there are multiple then separate them with commas" )

	(options, otherArgs) = parser.parse_args()

	api = glsapiutil.glsapiutil2()
	api.setURI( options.stepURI )
	api.setup( options.username, options.password )

	## at this point, we have the parameters the EPP plugin passed, and we have network plumbing
	## so let's get this show on the road!
	checkFilesArePresent()

if __name__ == "__main__":
	main()