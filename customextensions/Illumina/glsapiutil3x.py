#
# 
#     version of glsapiutil.py from Clarity  for Python 3.x
#         Alexander Mazur, alexander.mazur@gmail.com
#
#


import sys
_py_version_ = sys.version_info
import re

if _py_version_ >= (3, 0):
    import urllib.request as py_sys_urllib  # partially supersedes Python 2's py_sys_urllib
    import urllib
    from urllib.error import HTTPError, URLError
else:
    import py_sys_urllib as py_sys_urllib
    from py_sys_urllib import HTTPError, URLError

from xml.dom.minidom import parseString
from xml.sax.saxutils import escape


DEBUG = 0

class glsapiutil3:

	def __init__(self):
		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))
		self.hostname = ""
		self.auth_handler = None
		self.version = "v2"
		self.uri = ""
		self.base_uri = ""

	def setHostname(self, hostname):
		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))
		self.hostname = hostname

	def setVersion(self, version):
		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))
		self.version = version

	def setURI(self, uri):
		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))
		self.uri = uri

	def getBaseURI(self):
		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))
		return self.base_uri

	def setup(self, user, password):

		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))

		if len(self.uri) > 0:
			tokens = self.uri.split("/")
			self.hostname = "/".join(tokens[0:3])
			self.version = tokens[4]
			self.base_uri = "/".join(tokens[0:5]) + "/"
		else:
			self.base_uri = self.hostname + '/api/' + self.version

		# # setup up API plumbing
		password_manager = py_sys_urllib.HTTPPasswordMgrWithDefaultRealm()
		password_manager.add_password(None, self.base_uri, user, password)
		self.auth_handler = py_sys_urllib.HTTPBasicAuthHandler(password_manager)
		opener = py_sys_urllib.build_opener(self.auth_handler)
		py_sys_urllib.install_opener(opener)

	# # REST Methods

	def GET(self, url):

		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))

		responseText = ""
		thisXML = ""

		try:
			thisXML = py_sys_urllib.urlopen(url).read()
		except py_sys_urllib.HTTPError as e:
			responseText = e.msg
		except py_sys_urllib.URLError as e:
			if e.strerror is not None:
				responseText = e.strerror
			elif e.reason is not None:
				responseText = str(e.reason)
			else:
				responseText = e.message
		except Exception as ee:
			responseText = ee

		if len(responseText) > 0:
			print("Error trying to access " + url)
			print(responseText)

		return thisXML

	def PUT(self, xmlObject, url):

		if DEBUG > 0: print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))

		opener = py_sys_urllib.build_opener(self.auth_handler)

		req = py_sys_urllib.Request(url)
		data=xmlObject.encode('utf-8')
		req.data=data
		req.get_method = lambda: 'PUT'
		req.add_header('Accept', 'application/xml')
		req.add_header('Content-Type', 'application/xml')
		req.add_header('User-Agent', 'Python-py_sys_urllib/2.6')

		try:
			response = opener.open(req)
			responseText = response.read()
		except py_sys_urllib.HTTPError as e:
			responseText = e.read()
		except Exception as ee:
			responseText = ee

		return responseText

	def POST(self, xmlObject, url):
		if DEBUG > 0:
				print("%s:%s called" % (self.__module__, sys._getframe().f_code.co_name))
        
		opener = py_sys_urllib.build_opener(self.auth_handler)
		req = py_sys_urllib.Request(url)
		
		data = xmlObject.encode('utf-8')
		req.data = data
		req.get_method = lambda: 'POST'
		req.add_header('Accept', 'application/xml')
		req.add_header('Content-Type', 'application/xml')
		req.add_header('User-Agent', 'Python-py_sys_urllib/2.6')
		try:
			response = opener.open(req)
			responseText = response.read()
		except py_sys_urllib.HTTPError as e:
				responseText = e.read()
		except Exception as ee:
			responseText = ee
        
		return responseText

	# # API Helper methods

	@staticmethod
	def getUDF(DOM, udfname):

		response = ""

		elements = DOM.getElementsByTagName("udf:field")
		for udf in elements:
			temp = udf.getAttribute("name")
			if temp == udfname:
				response = udf.firstChild.data
				break

		return response

	@staticmethod
	def setUDF(DOM, udfname, udfvalue):

		if DEBUG > 2: print(DOM.toprettyxml())

		# # are we dealing with batch, or non-batch DOMs?
		if DOM.parentNode is None:
			isBatch = False
		else:
			isBatch = True

		newDOM = xml.dom.minidom.getDOMImplementation()
		newDoc = newDOM.createDocument(None, None, None)

		# # if the node already exists, delete it
		elements = DOM.getElementsByTagName("udf:field")
		for element in elements:
			if element.getAttribute("name") == udfname:
				try:
					if isBatch:
						DOM.removeChild(element)
					else:
						DOM.childNodes[0].removeChild(element)
				except xml.dom.NotFoundErr as e:
					if DEBUG > 0: print("Unable to Remove existing UDF node")

				break

		# now add the new UDF node
		txt = newDoc.createTextNode(str(udfvalue))
		newNode = newDoc.createElement("udf:field")
		newNode.setAttribute("name", udfname)
		newNode.appendChild(txt)

		if isBatch:
			DOM.appendChild(newNode)
		else:
			DOM.childNodes[0].appendChild(newNode)

		return DOM

	def reportScriptStatus(self, uri, status, message):

		newuri = uri + "/programstatus"

		XML = self.GET(newuri)
		newXML = re.sub('(.*<status>)(.*)(<\/status>.*)', '\\1' + status + '\\3', XML)
		newXML = re.sub('(.*<\/status>)(.*)', '\\1' + '<message>' + message + '</message>' + '\\2', newXML)

		try:
			self.PUT(newXML, newuri)
		except:
			print (message)

	def getArtifacts(self, LUIDs):

		"""
		This function will be passed a list of artifacts LUIDS, and return those artifacts represented as XML
		The artifacts will be collected in a single batch transaction, and the function will return the XML
		for the entire transactional list
		"""

		response = self.__getBatchObjects(LUIDs, "artifact")
		if response is None:
			return ""
		else:
			return response

	def getContainers(self, LUIDs):

		"""
		This function will be passed a list of container LUIDS, and return those containers represented as XML
		The containers will be collected in a single batch transaction, and the function will return the XML
		for the entire transactional list
		"""

		response = self.__getBatchObjects(LUIDs, "container")
		if response is None:
			return ""
		else:
			return response

	def getSamples(self, LUIDs):

		"""
		This function will be passed a list of sample LUIDS, and return those sample represented as XML
		The samples will be collected in a single batch transaction, and the function will return the XML
		for the entire transactional list
		"""

		response = self.__getBatchObjects(LUIDs, "sample")
		if response is None:
			return ""
		else:
			return response

	def getFiles(self, LUIDs):

		"""
		This function will be passed a list of file LUIDS, and return those sample represented as XML
		The samples will be collected in a single batch transaction, and the function will return the XML
		for the entire transactional list
		"""

		response = self.__getBatchObjects(LUIDs, "file")
		if response is None:
			return ""
		else:
			return response

	def __getBatchObjects(self, LUIDs, objectType):

		if objectType == "artifact":
			batchNoun = "artifacts"
			nodeNoun = "art:artifact"
		elif objectType == "sample":
			batchNoun = "samples"
			nodeNoun = "smp:sample"
		elif objectType == "container":
			batchNoun = "containers"
			nodeNoun = "con:container"
		elif objectType == "file":
			batchNoun = "files"
			nodeNoun = "file:file"
		else:
			return None

		lXML = []
		lXML.append('<ri:links xmlns:ri="http://genologics.com/ri">')
		for limsid in set(LUIDs):
			lXML.append('<link uri="%s%s/%s"/>' % (self.getBaseURI(), batchNoun, limsid))
		lXML.append('</ri:links>')
		lXML = ''.join(lXML)

		mXML = self.POST(lXML, "%s%s/batch/retrieve" % (self.getBaseURI(), batchNoun))

		# # did we get back anything useful?
		try:
			mDOM = parseString(mXML)
			nodes = mDOM.getElementsByTagName(nodeNoun)
			if len(nodes) > 0:
				response = mXML
			else:
				response = ""
		except:
			response = ""

		return response


