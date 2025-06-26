__author__ = 'dcrawford' #dcrawford@illumina.com
# JULY 28 2017

# template for easy placement of controls based off of a given csv template.

# The template will have every control on it, multiple rows if the control is used multiple times
# The step will need to be started with the exact number of replicates, the script can't control how many replicates of the controls are added.

# assumptions:
    # The output generated will have the same name as the controls in the excel file.
    # output plates are all of the same type
    #

debug = False
debug_placement_file = "/opt/gls/clarity/ai/temp/norm_template.csv"   # local file for testing
samples_controls_placement_file= "/opt/gls/clarity/ai/temp/norm_template.csv"
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
    Parser.add_option('-c', "--containertype", action='store', dest='containertype', default='96 well plate')    # destination container type

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
        if (outputnode.getAttribute("type") == "Analyte") :    # replicates, therefore multiple outputs per input
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
    if debug:
        print placeXML
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
    if debug:
        print (cType, cName)
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
            # print ("delete :\t"+conURI)
            # print api.deleteObject( "", conURI ) # this is pretty safe since clarity won't delete a container unless its empty
        except:
            pass
    if dest_container_identifier not in con_indexes:
        if debug:
            print (dest_container_identifier)
        if (dest_container_identifier =="0"):
            (loContainer_LUID,loContainer_name,loContainerOccupiedWells,loContainerURI)=leftOver_container[0].split("xxx")
            conURI=loContainerURI
        else:
            conURI = createContainer( containertype, "Norm " + str( dest_container_identifier ) )
        con_indexes[ dest_container_identifier ] = conURI
    return con_indexes[ dest_container_identifier ]

def auto_place():

    print "Begin autoplacing"
    iomap = map_io( args.stepURI ) # outputArt : inputArt
    

    if debug:
        print "io map:"
        for i in iomap:
           print i, iomap[i]
    
    

    output_artifacts_batch = parseString( api.getArtifacts( iomap.keys() ) )

    global con_indexes,placementMap 
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

            # find an instance of this name in the csv file

            for c in range( len( resultsCSV )):
                container_index, placement_value, control_name = resultsCSV[ c ]
                
                if control_name.strip() == artName:
                    dest_containerURI = containerURIfromindex( container_index , args.containertype )
                    output_art = output_artURI.split( "?" )[0]  # remove state
                    placementMap[ output_art ] = artifactLocation( dest_containerURI, placement_value )
                    print "contIndex=\t"+container_index+' = '+placement_value +" = "+control_name +" artName="+artName+" desdURI="+dest_containerURI+" outArt="+output_art
                    resultsCSV.pop( c ) # remove from list of placements
                    break

    r = POSTPlacementValues( placementMap )
    print r

def get_control_locations_from_file():
    global resultsCSV

    if debug:
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
        
def get_left_over_container(stepURI):
    global leftOver_container
    leftOver_container=[]
    try: # there might not be an on the fly container
        conURI = parseString( api.GET( args.stepURI + "/placements") ).getElementsByTagName("selected-containers")[0].getElementsByTagName("container")[0].getAttribute("uri")
        print ("delete :\t"+conURI)
        print api.deleteObject( "", conURI ) # this is pretty safe since clarity won't delete a container unless its empty
    except:
        pass    
    dResponse=api.GET( stepURI + "/placements" )
    sPlacements = parse_xml( dResponse)
    if debug:
        print ("####### placements ######")
        print (dResponse)
        print ("####### ------------ ######")

    for node in sPlacements.getElementsByTagName("selected-containers"):
        if node is not None:
            try:
                LOURI = node.getElementsByTagName("container")[0].getAttribute("uri")
                get_left_over_start_well(LOURI)
            except:
                pass
            
    
    return

def get_left_over_start_well(LOURI):
    loContainer = parse_xml( api.GET(LOURI))
    for node in loContainer.getElementsByTagName("con:container"):
        loContainerLUID = node.getAttribute("limsid")
        loContainerURI = node.getAttribute("uri")
        loContainerName=node.getElementsByTagName('name')[0].firstChild.nodeValue
        loContainerOccupiedWells=node.getElementsByTagName('occupied-wells')[0].firstChild.nodeValue
        if loContainerLUID not in leftOver_container:
            leftOver_container.append(loContainerLUID+"xxx"+loContainerName+"xxx"+loContainerOccupiedWells+"xxx"+loContainerURI)
        if debug:
            print ("##  leftOver Container debug")
            print (loContainerLUID,loContainerName,loContainerOccupiedWells,loContainerURI)
    
    
    return
        
def prepare_artifacts_batch(ArtifactsLUID):
    #global BASE_URI
    lXML = []
    lXML.append( '<?xml version="1.0" encoding="utf-8"?><ri:links xmlns:ri="http://genologics.com/ri">' )
    
    for art in ArtifactsLUID:
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


def get_well_position_from_artifacts(sXML):    
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
                
        if len( artifact.getElementsByTagName( "control-type" )) > 0 :
            if artLUID in CTRLs:
                ctrlSamples[artName] =CTRLs[artLUID]

            while (artLUID in sampleCounter) and (sampleCounter[artLUID]>0):
                #print(artName+'\t'+artLocation+'\t'+artLUID+'\t'+artContainer)
                sampleCounter[artLUID] -=1
        else:
            #sampleID_Position[artLocation+"_"+artContainer]=artName
            sampleID_Position[str(get_phisical_position(artLocation))+"_"+artContainer]=artName            
            #sampleID_Position[str(get_phisical_position(artLocation))+"_"+str(iContainers)]=artName     
                   
            if artContainer not in containersCount:
                containersCount[artContainer]=iContainers
                iContainers +=1

            # print(artName+'\t'+artLocation+'\t'+artLUID+'\t'+artContainer)
    return

def create_meta_file():
    rows=['A','B','C','D','E','F','G','H']

    iCont=1
    iDestSmpl=1
    iDestCont=1
    

        
            
    f_out=open(samples_controls_placement_file,"w")
#    for jj in CTRLs:
#        print jj, CTRLs[jj]
    
    for k in containersCount:
        #iCont=  containersCount[k]
        '''  
        for i in rows:
            for j in range (1,13):
                sKey=i+":"+str(j)+"_"+str(k)
                print (str(iCont)+"\t"+i+":"+str(j)+"\t"+sampleID_Position[sKey])
        '''
        for iPos in range(1,97):
            sKey=str(iPos)+"_"+str(k)
            #sKey=str(iPos)+"_"+str(containersCount[k])
            #print (sKey)
            if iDestSmpl in ctrl_Ppos:
                if (ctrl_Ppos[iDestSmpl] in ctrlSamples) and (ctrlSamples[ctrl_Ppos[iDestSmpl]] >0):
                    print (str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+ctrl_Ppos[iDestSmpl])
                    f_out.write(str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+ctrl_Ppos[iDestSmpl]+"\n")
                    ctrlSamples[ctrl_Ppos[iDestSmpl]] -=1
                    iDestSmpl +=1
                

            #print (str(iDestCont)+"\t"+str(iDestSmpl)+"\t"+sampleID_Position[sKey]+"\t"+get_AlphaNumPosition(iDestSmpl))


            
            if sKey in sampleID_Position:
                print (str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+sampleID_Position[sKey])
                f_out.write(str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+sampleID_Position[sKey]+"\n")


            if iDestSmpl > 95:
                iDestCont +=1
                iDestSmpl =0
            
            iDestSmpl +=1                                            
        iCont +=1
        
        
        
    f_out.close()   

def create_meta_file_from_zip():
    rows=['A','B','C','D','E','F','G','H']
    iCont=1
    iDestSmpl=1
    iDestCont=1
    if len(leftOver_container)>0:

        (loContainer_LUID,loContainer_name,loContainerOccupiedWells,loContainerURI)=leftOver_container[0].split("xxx")
        iDestCont=0
        iDestSmpl=int(loContainerOccupiedWells)+1
    f_out=open(samples_controls_placement_file,"w")
#    for jj in CTRLs:
#        print jj, CTRLs[jj]
    
    for k in range(1, len(containersCount)+1):
        #iCont=  containersCount[k]

        for iPos in range(1,97):
            sKey=str(iPos)+"_"+str(k)
            #sKey=str(iPos)+"_"+str(containersCount[k])
            #print (sKey)
            if iDestSmpl in ctrl_Ppos:
                if (ctrl_Ppos[iDestSmpl] in ctrlSamples) and (ctrlSamples[ctrl_Ppos[iDestSmpl]] >0):
                    print (str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+ctrl_Ppos[iDestSmpl])
                    f_out.write(str(iDestCont)+","+get_AlphaNumPosition(iDestSmpl)+","+ctrl_Ppos[iDestSmpl]+"\n")
                    ctrlSamples[ctrl_Ppos[iDestSmpl]] -=1
                    iDestSmpl +=1
                

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
#    ctrl_Apos=["A:1","D:0","G:11", "H:10"]
    ctrl_Apos=["A:1","D:6","G:11", "H:10"]    
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

    global api, BASE_URI, user, psw
    api = glsapiutil.glsapiutil2()
    api.setURI( args.stepURI )
    api.setup( args.username, args.password )
    
    user=args.username
    psw=args.password
    BASE_URI=api.getBaseURI()
    
    get_left_over_container(args.stepURI)

    #exit()

    create_csv_file(args.stepURI)

    sXML=prepare_artifacts_batch(ArtifactsLUID)
    aXML=retrieve_artifacts(sXML)
    #print sXML
    get_well_position_from_artifacts(aXML)
#    for i in sampleID_Position:
#        print i, sampleID_Position[i]
#    for i in containersCount:
#        print i, containersCount[i]  
    remove_empty_wells(sampleID_Position)
#    for i in sorted(zipSampleID_Position):
#       print i, zipSampleID_Position[i]
    get_ctrl_samples_pos()
    
    #exit()    
      
    #create_meta_file()  
    create_meta_file_from_zip()      
#    exit()
    
    global FH
    FH = glsfileutil.fileHelper()
    FH.setAPIHandler( api )
    FH.setAPIAuthTokens( args.username, args.password )
    

    get_control_locations_from_file()

    auto_place( )
    if debug:
        for i in placementMap:
            print (i, placementMap[i])

if __name__ == "__main__":
    main()