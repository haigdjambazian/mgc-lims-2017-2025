__author__ = 'dcrawford' #dcrawford@illumina.com
# JULY 28 2017

# assumptions:
    # The output generated will have the same name as the controls in the excel file.
    # output plates are all of the same type
    # python v.2.7
    
'''
    Alexander Mazur alexander.mazur@gmail.com
    Update:
        2018_04_20:
            - updated to serve both samples and control samples
            - the output generated will have the same name as the controls in the csv file
            - output plates are all of the same type
            - keep the original container name 
            - suffix option
            - outputArtifact -'Analyte'|'ResultFile'

'''    

debug = False
debug_placement_file = "controls_test.csv"   # local file for testing
samples_controls_placement_file= "/opt/gls/clarity/ai/temp/autoplacement_generic_template.csv"
import sys
from optparse import OptionParser
from xml.dom.minidom import parseString
import collections
import urllib

import glsapiutil   # 2106 version , needed for API calls
import glsfileutil  # needed to download file
import xml.etree.ElementTree as ET

def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-u', "--username", action='store', dest='username')
    Parser.add_option('-p', "--password", action='store', dest='password')
    Parser.add_option('-s', "--stepURI", action='store', dest='stepURI')
    Parser.add_option('-t', "--placementtemplate", action='store', dest='template')     # placement CSV
    Parser.add_option('-c', "--containertype", action='store', dest='containertype')    # destination container type
    Parser.add_option('-x', "--suffix", action='store', dest='suffix', default='')    # suffix
    Parser.add_option('-o', "--outputArtifact", action='store', dest='outputArtifact', default='Analyte')    # suffix

    return Parser.parse_args()[0]

def map_io( stepURI ):

    global details,ArtifactsLUID, sampleCounter, CTRLs
    iomap = {}
    ArtifactsLUID=[]
    sampleCounter={}
    CTRLs={}
    details = parse_xml( api.GET( stepURI + "/details" ))
    #print api.GET( stepURI + "/details" )
    for io in details.getElementsByTagName("input-output-map"):
        inputartURI = io.getElementsByTagName("input")[0].getAttribute("uri")
        inputartLUID = io.getElementsByTagName("input")[0].getAttribute("limsid")
        outputnode = io.getElementsByTagName("output")[0]
        outputartURI = outputnode.getAttribute("uri")
        # AM
        outputArtID = outputnode.getAttribute("limsid")

        # only want artifact outputs
        # ORIGINAL used "Analyte"

        if (outputnode.getAttribute("type") == outputArtifact) :    # replicates, therefore multiple outputs per input
#        if outputnode.getAttribute("type") == "ResultFile": 
        
            
            #iomap[ inputartURI ] = outputartURI
            iomap[ outputartURI ] = inputartURI
            if inputartLUID in sampleCounter:
                sampleCounter[inputartLUID] +=1
            else:
                sampleCounter[inputartLUID]=1
                
            if inputartLUID in CTRLs:
                CTRLs[inputartLUID] +=1
            else:
                if is_artifact_control(inputartLUID ):
                    CTRLs[inputartLUID]=1
            if inputartLUID not in ArtifactsLUID:
               ArtifactsLUID.append( inputartLUID )
    return iomap

def is_artifact_control(artifactLUID):
    s=False
    luid_prefix=artifactLUID.split("-")[0][-1]
    #print (luid_prefix, artifactLUID)
    if luid_prefix == "C":
        s=True
        
    return s
    

# Updates the steps placement page
def POSTPlacementValues( placementMap ):

    configNode = details.getElementsByTagName( "configuration" )[0]
    config_uri = configNode.getAttribute( "uri" )
    config_PT = configNode.firstChild.data
    config_PT = urllib.quote( config_PT )
    placeXML = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?><stp:placements xmlns:stp="http://genologics.com/ri/step" uri="' + args.stepURI + '/placements">']
    placeXML.append( '<step uri="' + args.stepURI + '" rel="steps"/>' )
    placeXML.append( '<configuration uri="' + config_uri + '">' + config_PT + '</configuration>' )
    placeXML.append( '<output-placements>' )
    for art, location in placementMap.items():
        placeXML.append( '<output-placement uri="' + art + '"><location><container uri="' + api.getBaseURI() + 'containers/' + location.selContainer + '" limsid="' + location.selContainer + '"/>' )
        placeXML.append( '<value>' + location.well + '</value></location></output-placement>' )
    placeXML.append( '</output-placements></stp:placements>' )
    #print placeXML
    r = api.POST( "".join( placeXML ), args.stepURI + '/placements')
    return r

def downloadfile( file_art_luid ):

    NEW_NAME = 'temp_file.txt'
    try:
        FH.getFile( file_art_luid, NEW_NAME )
    except:
        print 'trouble downloading result file, file luid not found'
        sys.exit(111)
    raw = open( NEW_NAME, "r")
    lines = raw.readlines()
    raw.close
    return lines

def parse_xml( xml ):
    try:
        dom = parseString( xml )
        return dom
    except:
        print xml
        sys.exit(1)

def get_dom( uri ):
    dom = parse_xml( api.GET( uri ) )
    return dom

def createContainer( cType, cName ):

    response = ""
    qURI = api.getBaseURI() + "containertypes?name=" + urllib.quote( cType )
    qXML = api.GET( qURI )  # recommend container type cache if many cons are being created
    qDOM = parseString( qXML )
    nodes = qDOM.getElementsByTagName( "container-type" )
    if len(nodes) == 1:
        ctURI = nodes[0].getAttribute( "uri" )
        xml = '<?xml version="1.0" encoding="UTF-8"?>'
        xml += '<con:container xmlns:con="http://genologics.com/ri/container">'
        if len(cName) > 0:
            xml += ( '<name>' + cName + '</name>' )
        else:
            xml += '<name></name>'
        xml += '<type uri="' + ctURI + '"/>'
        xml += '</con:container>'
        rXML = api.POST( xml, api.getBaseURI() + "containers" )
        rDOM = parseString( rXML )
        nodes = rDOM.getElementsByTagName( "con:container" )
        if len(nodes) > 0:
            tmp = nodes[0].getAttribute( "uri" )
            response = tmp
    elif len(nodes) == 0:
        print "This is not a valid container type."
        sys.exit(97)
    return response

def containerURIfromindex( dest_container_identifier, containertype ):

    # Creation of multiple plates, we will take the "Plate 1" naming convention from the helper script.
    global con_indexes
    if len( con_indexes.keys() ) == 0:
        #get rid of the on-the-fly selected container since the order of the limsids are wicky wack
        try: # there might not be an on the fly container
            conURI = parseString( api.GET( args.stepURI + "/placements") ).getElementsByTagName("selected-containers")[0].getElementsByTagName("container")[0].getAttribute("uri")
            print api.deleteObject( "", conURI ) # this is pretty safe since clarity won't delete a container unless its empty
        except:
            pass
    if dest_container_identifier not in con_indexes:
        #conURI = createContainer( containertype, "Norm " + str( dest_container_identifier ) )
        
        conURI = createContainer( containertype, "Plate"+str( dest_container_identifier ) +suffix)
        print (str( dest_container_identifier )+" container created\t"+conURI)
        con_indexes[ dest_container_identifier ] = conURI
    return con_indexes[ dest_container_identifier ]

def auto_place():

    print "Begin autoplacing"
    iomap = map_io( args.stepURI ) # outputArt : inputArt

    #print "io map:"
#    for i in iomap:
#       print i, iomap[i]
    
    

    output_artifacts_batch = parseString( api.getArtifacts( iomap.keys() ) )

    global con_indexes
    con_indexes = {}
    placementMap = {} # the dictionary that will ulimately pass all placement information to the POSTplacementMap function
    artifactLocation = collections.namedtuple( 'artifactLocation', 'selContainer well') # stores all the data for that artifacts container location

    for artifact in output_artifacts_batch.getElementsByTagName("art:artifact"):
        '''
        it's a control only len(...) >0
        ctrl+sample => len(...) >=0
        '''
        if len( artifact.getElementsByTagName( "control-type" )) >= 0 :
            
            artName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
            output_artURI = artifact.getAttribute( "uri" )
            if debug:
                print(artName, output_artURI)

            # find an instance of this name in the csv file

            for c in range( len( resultsCSV )):
                container_index, placement_value, control_name,  = resultsCSV[ c ]
                if debug:
                    print "test=\t"+container_index+' = '+placement_value +" = "+control_name +" conteiner type="+args.containertype+" artName="+artName
                if control_name.strip() == artName:
                    dest_containerURI = containerURIfromindex( container_index , args.containertype )
                    output_art = output_artURI.split( "?" )[0]  # remove state
                    placementMap[ output_art ] = artifactLocation( dest_containerURI, placement_value )
                    resultsCSV.pop( c ) # remove from list of placements
                    break

    r = POSTPlacementValues( placementMap )
    #print r





def get_control_locations_from_file():
    global resultsCSV

    if debug >2:
        raw = open( debug_placement_file, "r")
        resultsCSV = raw.readlines()
    else:
        template_from_path = args.template
        if template_from_path:
            raw = open( template_from_path, "r")
            resultsCSV = raw.readlines()
        else:
            resultsCSV = downloadfile( args.outputLUID )

    if len( resultsCSV ) == 1:
        print resultsCSV

        resultsCSV = resultsCSV[0].split("\r")

    resultsCSV = [ x.strip("\r\n").split(",") for x in resultsCSV ]


def create_csv_file(stepURI):
    #print "Begin CSV file "
    iomap = map_io( args.stepURI ) # outputArt : inputArt
    api_output=api.getArtifacts( iomap.keys() ) 
    output_artifacts_batch = parseString( api_output)
    #print api.getArtifacts( iomap.keys() )
    #for i in ArtifactsLUID:
        #print i 
def prepare_artifacts_batch(ArtifactsLUID):
    #global BASE_URI
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in sorted(ArtifactsLUID):
        scURI = BASE_URI+'artifacts/'+art
        lXML.append( '<link uri="' + scURI + '" rel="artifacts"/>' )        
        #print (scURI)
        #scLUID = scURI.split( "/" )[-1:]
    lXML.append( '</ri:links>' )
    lXML = ''.join( lXML ) 

    return lXML 

def retrieve_artifacts(sXML):
    #global BASE_URI, user,psw
    sURI=BASE_URI+'artifacts/batch/retrieve'
    #print (sURI)
    headers = {'Content-Type': 'application/xml'}
    #r = requests.post(sURI, data=sXML, auth=(user, psw), verify=True, headers=headers)
    r = api.POST(sXML,sURI) 
   
    return r


def get_all_well_position_from_artifacts(sXML):    
    global ctrlSamples,sampleID_Position, containersCount
    nss ={'udf':"http://genologics.com/ri/userdefined", 'art':"http://genologics.com/ri/artifact", 'prj':"http://genologics.com/ri/project"}
    pDOM = parseString( sXML )
    
    sHeader='Src ID\tCoord\tSample Name'
    #print(sHeader)
    proj="XXX"
    i=1
    ctrlSamples={}
    sampleID_Position={}
    zipSampleID_Position={}
    containersCount={}
    iContainers=1
    newContainer=1
    newPositionCounter=1
    for artifact in pDOM.getElementsByTagName("art:artifact"):
        #print (child)
        artName = artifact.getElementsByTagName("name")[0].firstChild.data  # output artifact name
        artLUID = artifact.getAttribute( "limsid" )
        artLocation = artifact.getElementsByTagName("value")[0].firstChild.data  # output artifact name
        
        
        artContainer= artifact.getElementsByTagName("container")[0].getAttribute("limsid")
        containerURI= artifact.getElementsByTagName("container")[0].getAttribute('uri')
        containerName=get_container_name(containerURI)
                

        #sampleID_Position[artLocation+"_"+artContainer]=artName
        #sampleID_Position[str(get_phisical_position(artLocation))+"_"+artContainer]=artName +"xxx"+containerName
        ssPosition=get_phisical_position(artLocation)
        if ssPosition <0:
            ssPosition=96           
        sampleID_Position[artContainer+"_"+str(ssPosition)]=artName +"xxx"+containerName
        print(artContainer+"_"+str(ssPosition)+"\t"+artName +"xxx"+containerName)
     
                  
        if artContainer not in containersCount:
            containersCount[artContainer]=iContainers
            iContainers +=1

            # print(artName+'\t'+artLocation+'\t'+artLUID+'\t'+artContainer)
    return
def get_container_name(containerURI):
    global BASE_URI, user,psw
    #r = requests.get(containerURI, auth=(user, psw), verify=True)
    r = api.GET(containerURI)
    rDOM = parseString(r )
    node =rDOM.getElementsByTagName('name')
    ss = node[0].firstChild.nodeValue
    return ss


def create_meta_file():
    rows=['A','B','C','D','E','F','G','H']
    iCont=1
    iDestSmpl=1
    iDestCont=1
    iMix=1
    iMixContainer=1
    f_out=open(samples_controls_placement_file,"w")
#    for jj in CTRLs:
#        print jj, CTRLs[jj]
    
    for k in sorted(containersCount):
        #iCont=  containersCount[k]
        '''  
        for i in rows:
            for j in range (1,13):
                sKey=i+":"+str(j)+"_"+str(k)
                print (str(iCont)+"\t"+i+":"+str(j)+"\t"+sampleID_Position[sKey])
        '''
        for iPos in range(1,97):
            #sKey=str(iPos)+"_"+str(k)
            sKey=str(k)+"_"+str(iPos)

            
            if sKey in sorted(sampleID_Position):
                (artName ,containerName)=sampleID_Position[sKey].split('xxx')
                #print (str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+sampleID_Position[sKey]+","+get_AlphaNumPosition(iMix)+","+str(iMixContainer))
                print (str(iMixContainer)+","+get_AlphaNumPosition(iMix)+","+artName)
                #f_out.write(str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+sampleID_Position[sKey]+"\n")
                f_out.write(str(iMixContainer)+","+get_AlphaNumPosition(iMix)+","+artName+"\n")
                iMix +=1
             #   print (containerName+","+get_AlphaNumPosition(iDestSmpl)+","+artName)
             #   f_out.write(containerName+","+get_AlphaNumPosition(iDestSmpl)+","+artName+"\n")


            if iDestSmpl > 95:
                iDestCont +=1
                iDestSmpl =0
            if iMix>96:
                iMixContainer +=1
                iMix=1
            iDestSmpl +=1                                            
        iCont +=1
        
        
        
    f_out.close()   

def create_meta_file_from_zip():
    rows=['A','B','C','D','E','F','G','H']
    iCont=1
    iDestSmpl=1
    iDestCont=1
    f_out=open(samples_controls_placement_file,"w")
#    for jj in CTRLs:
#        print jj, CTRLs[jj]
    
    for k in range(1, len(containersCount)+1):
        #iCont=  containersCount[k]

        for iPos in range(1,97):
            sKey=str(iPos)+"_"+str(k)
            #sKey=str(iPos)+"_"+str(containersCount[k])
            #print (sKey)
            
            '''
            # Disable Control samples check
            
            if iDestSmpl in ctrl_Ppos:
                if (ctrl_Ppos[iDestSmpl] in ctrlSamples) and (ctrlSamples[ctrl_Ppos[iDestSmpl]] >0):
                    print (str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+ctrl_Ppos[iDestSmpl])
                    f_out.write(str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+ctrl_Ppos[iDestSmpl]+"\n")
                    ctrlSamples[ctrl_Ppos[iDestSmpl]] -=1
                    iDestSmpl +=1
                
            '''
            
            #print (str(iDestCont)+"\t"+str(iDestSmpl)+"\t"+sampleID_Position[sKey]+"\t"+get_AlphaNumPosition(iDestSmpl))


            
            if sKey in zipSampleID_Position:
                print (str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+zipSampleID_Position[sKey])
                f_out.write(str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+zipSampleID_Position[sKey]+"\n")


            if iDestSmpl > 95:
                iDestCont +=1
                iDestSmpl =0
            
            iDestSmpl +=1                                            
        iCont +=1
        
        
        
    f_out.close()   


def remove_empty_wells(sampleID_Position):
    global zipSampleID_Position

    zipSampleID_Position={}
    newContainer=1
    newPositionCounter=1
    for k in sorted(containersCount):
        for iPos in range(1,97):
            sKey=str(iPos)+"_"+str(k)
            if sKey in sampleID_Position:
                artName=sampleID_Position[sKey]
                zipSampleID_Position[str(newPositionCounter)+"_"+str(newContainer)]=artName
                newPositionCounter +=1
            if newPositionCounter >96:
                newPositionCounter = 1
                newContainer +=1
    
    
    return
        
def get_ctrl_samples_pos():
    global ctrl_Apos, ctrl_Ppos
    ctrl_Apos=["A:1","D:0","G:11", "H:10"]
    ctrl_Ppos={1:"Axiom gDNA103",44:"CEPH1463-02",87:"Negative Control",80:"CEPH1463-02"}        
    
    return 
        
def get_phisical_position(sAlphaNumPosition):
    
    s=sAlphaNumPosition[0].upper()
    sASCII= ord(s)
    sDigit=sAlphaNumPosition[1:].upper()
    sDigit=sDigit.replace(':0','')
    sDigit=sDigit.replace(':','') 
    
    sPhPos=(int(sASCII)-64)+(int(sDigit)-1)*8
    
    return sPhPos
def get_AlphaNumPosition(iPhysPos):
    alpha=['H','A','B','C','D','E','F','G','H']
    iAlphaInt=iPhysPos // 8
    iAlphaRem=iPhysPos%8
    sSep=":"
    
    if iAlphaRem >0:
        if iAlphaInt+1<10:
            sSep=":"
        s= alpha[iAlphaRem] +sSep+str(iAlphaInt+1)
    else:
        if iAlphaInt<10:
            sSep=":"
        s= alpha[iAlphaRem] +sSep+str(iAlphaInt)
    return s


def main():

    global args
    args = setup_arguments()

    global api, BASE_URI, user, psw,suffix,outputArtifact
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    
    user=args.username
    psw=args.password
    suffix=args.suffix
    outputArtifact=args.outputArtifact
    BASE_URI=api.getBaseURI()

    create_csv_file(args.stepURI)
    
    sXML=prepare_artifacts_batch(ArtifactsLUID)
    aXML=retrieve_artifacts(sXML)
    #print sXML
    #print aXML
    get_all_well_position_from_artifacts(aXML)
      
    create_meta_file()
      
    #exit()
    
    global FH
    FH = glsfileutil.fileHelper()
    FH.setAPIHandler( api )
    FH.setAPIAuthTokens( args.username, args.password )
    
    get_control_locations_from_file()
    auto_place( )

if __name__ == "__main__":
    main()