'''
Created on Aug 19, 2016

@author: Alexander Mazur, mazur@ieee.org
'''
__author__ = 'Alexander Mazur'    
import os, argparse, shutil, logging, math, os
from scipy import stats
import numpy as np
import numpy.polynomial.polynomial as poly
import csv,matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from PIL import Image
from sklearn import linear_model
from sklearn.metrics import r2_score
from time import gmtime, strftime
import requests
import re
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET


user=''
psw=''
# BASE_URI='https://bravotestapp.genome.mcgill.ca/api/v2/'




parser = argparse.ArgumentParser(description='Testing a calibration raw data from SPARK')
parser.add_argument('-inputFile', help='input file for SPARK calibration')
#parser.add_argument('-mode', default='c', help='modes - c|q - calibration or quantification')
parser.add_argument('-outliers', default='', help='outliers - 1,2,3...n - 1-100ng; 2 - 50 ng')

parser.add_argument('-replica_outlier', default='', help='*replica as outlier - A,B,C - whole replica or a0 point 0 in replica A ')
parser.add_argument('-df', default='10', help='delution factor, default -10')
parser.add_argument('-fileLuid',default='', help='fileLuid from WebUI')
parser.add_argument('-processURI_v2',default='', help='processURI_v2 from WebUI')
parser.add_argument('-controlLUIDs',default='', help='control LUIDs from WebUI')
parser.add_argument('-user_psw',default='', help='API user and password')



#parser.add_argument('-dataFiles', default='', help='*asc raw data files from SPARK, comma separated ')

args = parser.parse_args()
file_input = args.inputFile
fileLuid=args.fileLuid
outliers = args.outliers
replica_outlier=args.replica_outlier
DF=int(args.df)
processURI_v2=args.processURI_v2
controlLUIDs=args.controlLUIDs
user_psw = args.user_psw
plateID=''
quantFileStart=13
'''
    Add username and password from API
'''
if (user_psw):
    (user,psw)=user_psw.split(':')


script_dir=os.path.dirname(os.path.realpath(__file__))
HOSTNAME = "bravotestapp.genome.mcgill.ca"
VERSION = ""
BASE_URI = ""
DEBUG = False


replica_outlier=replica_outlier.upper()


#print (replica_outlier)
#print (replica_index)
#print (replica_point)
        

if ((not file_input) and (not fileLuid) ):
    parser.print_help()
    exit()
'''
    ###########  create the arrays
'''
raw_data_files=[]    
data_list=[]
arrays=[]

org_high_array=[]
org_low_array=[]
org_high_mean_array=[]

replicas_array=[]
replicas_array_low=[]

replicas_mean_array=[]
replicas_std_array=[]

sample_data_arrays=[]
quant_sample_data_high=[]
quant_sample_data_low=[]
quant_sample_data_mix=[]
quant_sample_data_RANSAC=[]


std_array=[]
mean_array=[]
cv_array=[]
corrected_mean_array=[]

low_std_array=[]
low_mean_array=[]
low_cv_array=[]
low_corrected_mean_array=[]

outliers_array=[]
controlLUIDs_arr=""

high_low_raw_mean_10thr=-1

'''
    ############################
'''

if (outliers):
    outliers_array.append(outliers.split(','))
    
if (controlLUIDs):
    controlLUIDs_arr= controlLUIDs.split(' ')
#    print (controlLUIDs_arr)
#    print (controlLUIDs_arr[0])
    


#logging.basicConfig(format='%(message)s', filename=log_file, filemode='a', level=logging.INFO)
#logging.info('<########### '+strftime("%Y-%m-%d %H:%M:%S")+ '  ########>')
#logging.info('calibration_file\t'+file_input)

def setupGlobalsFromURI( uri ):

    global HOSTNAME
    global VERSION
    global BASE_URI

    tokens = uri.split( "/" )
    HOSTNAME = "/".join(tokens[0:3])
    VERSION = tokens[4]
    BASE_URI = "/".join(tokens[0:5]) + "/"

    if DEBUG is True:
        print (HOSTNAME)
        print (BASE_URI)






def get_local_PG_file(FileLuid):
    global user,psw, BASE_URI
    r = requests.get(BASE_URI+'artifacts/'+FileLuid, auth=(user, psw), verify=True)
    root = ET.fromstring(r.content)
    if DEBUG:
        print (r.content)

    namespaces={'file':'http://genologics.com/ri/file'}
    for sFile in root.findall('file:file', namespaces):
        print (sFile.attrib)
    sURI=sFile.attrib['uri']
    sLocal_file=extract_file_location(sURI)
    return sLocal_file #sFile.attrib['uri']


def extract_file_location(sURI):
    global user,psw
    s=""
    r = requests.get(sURI, auth=(user, psw), verify=True)
    rDOM = parseString( r.content )
    for node in rDOM.getElementsByTagName('content-location')[0].childNodes:
            if node.nodeType == node.TEXT_NODE:
                s=node.toxml()
                s = s.replace('sftp://bravotestapp.genome.mcgill.ca', '')
                s = s.replace('sftp://bravodevapp.genome.mcgill.ca', '')
                s = s.replace('sftp://bravoprodapp.genome.mcgill.ca', '')
                #print(s)
    return s   





def get_org_arrays(arrays):
    global org_high_array,org_low_array
    i=0
    while i < len(arrays):
        org_value =arrays[i]
        org_high_array.append(org_value[0:3])
        org_low_array.append(org_value[3:6])
        i+=1    
    return

def get_org_high_mean_array(org_high_array):
    global org_high_mean_array
    i=0
    while i < len(org_high_array):
        item = org_high_array[i]
#        print (item[0:3],np.mean(item[0:3],0))
        org_high_mean_array.append(np.mean(item[0:3],0))
        i+=1    
    return

def get_replicas_array(arrays, replica_index, replica_point):
    global replicas_array
    i=0
    '''
    3 replicas
    '''
    while i < len(arrays):
        replica_value =arrays[i]
        replica_value=replica_value[0:3]
        jj=0
        if (replica_index >=0):
            if (i == int(replica_point)) or (int(replica_point)==-1) :
                del replica_value[replica_index]
        elif (replica_index == -1):
            if (i == int(replica_point)):
                del replica_value[0:3]
        if (len(replica_value)>0):
            replicas_array.append(replica_value)
        i+=1    
    return

def get_replicas_mean_array(replicas_array):
    global replicas_mean_array
    i=0
    while i < len(replicas_array):
        item = replicas_array[i]
        #print (item[0:3],np.mean(item[0:3],0))
        replicas_mean_array.append(np.mean(item,0))
        i+=1    
    return
def get_replicas_std_array(replicas_array):
    global replicas_std_array
    i=0
    while i < len(replicas_array):
        item = replicas_array[i]
        replicas_std_array.append(np.std(item,ddof=1))
        i+=1    
    return

def get_low_replicas_array(arrays):
    global replicas_array_low
    i=0
    '''
    3 low replicas
    '''
    while i < len(arrays):
        replica_value =arrays[i]
        replica_value=replica_value[3:6]
        replicas_array_low.append(replica_value)
        
        i+=1        
    return

def get_low_std_array(replicas_array_low):
    global low_std_array
    i=0
    while i < len(replicas_array_low):
        item = replicas_array_low[i]
        low_std_array.append(np.std(item,ddof=1))
        i+=1    
    return

def get_std_array(arrays):
    global std_array
    i=0
    while i < len(arrays):
        item = arrays[i]
        std_array.append(np.std(item[0:3],ddof=1))
        i+=1    
    return

def get_low_mean_array(replicas_array_low):
    global low_mean_array, high_low_raw_mean_10thr
    i=0
    while i < len(replicas_array_low):
        item = replicas_array_low[i]
        if (i ==0):
            high_low_raw_mean_10thr=np.mean(item,0)
        low_mean_array.append(np.mean(item,0))
        i+=1    
    return
def get_mean_array(arrays):
    global mean_array
    i=0
    while i < len(arrays):
        item = arrays[i]
        mean_array.append(np.mean(item[0:3],0))
        i+=1    
    return
def get_low_corr_mean_array(low_mean_array):
    global low_corrected_mean_array
    i=0
    while i < len(low_mean_array):
        low_corr_value=low_mean_array[-1]
        low_corrected_mean_array.append(low_mean_array[i]-low_corr_value)
        i+=1    
    return
def get_corr_mean_array(mean_array):
    global corrected_mean_array
    i=0
    while i < len(mean_array):
        corr_value = mean_array[-1]
        #print (item[0:3],np.mean(item[0:3],0))
        corrected_mean_array.append(mean_array[i]-corr_value)
        i+=1    
    return
def get_low_cv_array(low_corrected_mean_array,low_std_array):
    global low_cv_array 
    i=0
    while i < len(low_mean_array):
        if (low_corrected_mean_array[i]>0):
            low_cv_array.append(100*(low_std_array[i]/low_corrected_mean_array[i]))
        else:
            low_cv_array.append(999)
        i+=1    
    return

def get_cv_array(corrected_mean_array,std_array):
    global cv_array
    i=0
    while i < len(corrected_mean_array):
        if (corrected_mean_array[i]>0):
            cv_array.append(100*(std_array[i]/corrected_mean_array[i]))
        else:
            cv_array.append(999)
        i+=1    
    return

def parse_file(file_input):
    global arrays
    f = open(file_input, 'r', encoding='utf-8', errors='ignore')
    lines = f.readlines()
    i = 0
    while i < len(lines):
        if (i>1) and (i<10):
            ln = lines[i].split(',')
            #print (ln)
            ln1=np.delete(ln, 0, 0)
            ln1=np.delete(ln1, -1, 0)
            #print (ln1)
            new_array = np.array((np.array.float(i) for i in ln1))
            new_list = [float(jj) for jj in ln1]
            arrays.append(new_list)
        i += 1
    return

def parse_sample_file(sample_file_input):
    global sample_data_arrays
    f = open(sample_file_input, 'r' , encoding='utf-8', errors='ignore')
    lines = f.readlines()
#    print (lines[1].split(',') )
    i = 0
    while i < len(lines):
        if (i>1) and (i<10):
            ln = lines[i].split(',')
            ln1=np.delete(ln, 0, 0)
            ln1=np.delete(ln1, -1, 0)
            new_array = np.array((np.array.float(i) for i in ln1))
            new_list = [float(jj) for jj in ln1]
            sample_data_arrays.append(new_list)
        i += 1
    return

def quant_sample_file(sample_data_arrays, intersept,slope,rsq, mean_blank):
    
    return
 
def write_stats():
    global x,arrays,std_array,mean_array,cv_array,corrected_mean_array,low_std_array,low_mean_array,low_cv_array,low_corrected_mean_array, x,y,x_low,y_low
    i=0
    sHeader='Conc(ng/ul)\tOD\tOD\tOD\tmean\tstd_dev\tcorr_mean\tcv'
#    logging.info(sHeader)
    # print (sHeader)
    while i < len(arrays):
        item = arrays[i]
        sHigh='%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f'%(x[i],item[0],item[1],item[2],mean_array[i],std_array[i],corrected_mean_array[i],cv_array[i])
        # print (sHigh)
#        logging.info(sHigh)
        i+=1
    i=0    
    while i < len(arrays):
        item = arrays[i]
        sLow='%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f'%(x_low[i],item[3],item[4],item[5],low_mean_array[i],low_std_array[i],low_corrected_mean_array[i],low_cv_array[i])
        # print (sLow)
#        logging.info(sLow)
        
        i+=1    
    
            
    return


def remove_outliers(outliers_array):
    global x1,y1
    x1= np.delete(x,outliers_array)
    y1= np.delete(y,outliers_array)

    return

def func_log2(x, a, b, c, d):
    return a*np.log2(c*(x-b))+d



def scan_4_files(inputFile,file_ext):
    "Listing of all files in input directory and moving to the output directory"
    global raw_data_files, x,y
#    print (inputFile)
    inputDir = os.path.dirname(inputFile)
    input_filename = os.path.basename(inputFile)
    for file in os.listdir(inputDir):
 
        if (file.endswith(file_ext)) and (file not in input_filename) :
            input_file = os.path.join(inputDir, file)
            #print (file + "\n"+input_file+"\n")
            raw_data_files.append(input_file)
            parse_data_file(input_file)
    return

def parse_data_file(sample_file_input):
    global sample_data_arrays, x,y, x1,y1, x_low, y_low, Y_org, DF, replica_outlier, file_input, plateID, sFitMethod
    f = open(sample_file_input, 'r', encoding='utf-8', errors='ignore')
    lines = f.readlines()
    i = 0
    sample_data_arrays=[]
    while i < len(lines):
        if (i>1) and (i<10):
            ln = lines[i].split(',')
            ln1=np.delete(ln, 0, 0)
            ln1=np.delete(ln1, -1, 0)
            new_array = np.array((np.array.float(i) for i in ln1))
            new_list = [float(jj) for jj in ln1]
            sample_data_arrays.append(new_list)
        else:
            s=lines[i]
            s_up=s.upper()
            if (s_up.find('PLATE ID:')>=0):
                plateID=s_up.replace('PLATE ID:','')
                plateID=plateID.replace(' ', '')
                plateID=plateID.replace('\n', '')                
            
            
        i += 1

    slope, intercept, r_value, p_value, std_err =func_linReg(x1, y1)
    slope_low, intercept_low, r_value_low, p_value_low, std_err_low =func_linReg(x_low, y_low)
    
    quant_sample_data_linReg (sample_data_arrays,intercept, slope, r_value, 'h')
    quant_sample_data_linReg (sample_data_arrays,intercept_low, slope_low, r_value_low, 'l')

    (lin_slope, lin_intercept,lin_r_value, lin_slope_low, lin_intercept_low,lin_r_value_low, org_mean_blank, org_mean_blank_low )=quant_sample_data_mix_linReg (sample_data_arrays,x1,y1,x_low,y_low, high_low_raw_mean_10thr)
    sLin=('\nPlate ID:'+plateID+'\nreplica_outlier=\t'+str(replica_outlier)+'\nslope_linReg=\t'+str(lin_slope)+'\nintercept_linReg=\t'+str(lin_intercept)+'\nslope_linReg_low=\t'+str(lin_slope_low)+'\nintercept_linReg_low=\t'+str(lin_intercept_low)+'\nDF=\t'+str(DF)+'\n')
#    print ('quantified data MIX ----------------------------> ')
     
#    print (print_sample_plate(quant_sample_data_mix)) 
    sLin =sLin + 'sample_file: '+sample_file_input + '\ncalibration_file: '+file_input +'\nPos\tQuantValue\tStatus\n'
#    write_sample_file(sample_file_input,'mixlinReg', 'sample_file: '+sample_file_input, "w")
#    write_sample_file(sample_file_input,'mixlinReg', '\ncalibration_file: '+file_input, "a")    
    
#    write_sample_file(sample_file_input,'mixlinReg',sLin, "a")
#    write_sample_file(sample_file_input,'mixlinReg','Pos\tQuantValue\tStatus\n', "a")
    sPlateList=print_sample_plate_list(quant_sample_data_mix)
    sLin=sLin+sPlateList
#    write_sample_file(sample_file_input,'mixlinReg', print_sample_plate_list(quant_sample_data_mix),"a")

    if (sFitMethod == "Linear Regression (manual)"):
        write_sample_file(sample_file_input,'mixlinReg',sLin, "w")
    
    
#    print ('quantified data MIX RANSAC ----------------------------> ')
    (slope_ransac, intercept_ransac, slope_ransac_low, intercept_ransac_low, mean_blank, mean_blank_low)=quant_sample_data_mix_RANSAC (sample_data_arrays,x,Y_org,x_low,y_low, high_low_raw_mean_10thr)
    sRANSAC=('\nPlate ID:'+plateID+'\nslope_ransac=\t'+str(slope_ransac[0])+'\nintercept_ransac=\t'+str(intercept_ransac[0])+'\nslope_ransac_low=\t'+str(slope_ransac_low[0])+'\nintercept_ransac_low=\t'+str(intercept_ransac_low[0])+'\nDF=\t'+str(DF)+'\n')
    sRANSAC=sRANSAC+'\nsample_file: '+sample_file_input+'\ncalibration_file: '+file_input+'\nPos\tQuantValue\tStatus\n'
#    write_sample_file(sample_file_input,'mixRANSAC', 'sample_file: '+sample_file_input, "w")
#    write_sample_file(sample_file_input,'mixRANSAC', '\ncalibration_file: '+file_input, "a")
    
#    write_sample_file(sample_file_input,'mixRANSAC',sRANSAC, "a")
#    write_sample_file(sample_file_input,'mixRANSAC','Pos\tQuantValue\tStatus\n', "a")
    sPlateList = print_sample_plate_list(quant_sample_data_RANSAC)
    sRANSAC = sRANSAC + sPlateList
    if (sFitMethod=="RANSAC (auto)"): 
        write_sample_file(sample_file_input,'mixRANSAC',sRANSAC ,"w")

        
    
 #   print (str(len(quant_sample_data_mix)))
 #   print ('quantified data plate MIX ----------------------------> ')  
 #   print (quant_sample_data_mix[0])      
#    print (print_sample_plate(quant_sample_data_mix)) 
    
    return


def quant_sample_data_linReg (sample_data_arrays,intercept, slope, rsq, high_low_mode):
    global quant_sample_data_high,quant_sample_data_low, mean_array, low_mean_array, DF
    '''
    (((OD-ave. blank)-Intercept)/slope)*DF
    '''
    i=0
    if (high_low_mode=='h'):
        quant_sample_data_high=[]
        mean_blank=mean_array[-1]
    if (high_low_mode=='l'):
        quant_sample_data_low=[]
        mean_blank=low_mean_array[-1]    
    while i < len(sample_data_arrays):
        val=0
        val=((sample_data_arrays[i]-mean_blank-intercept)/slope)*DF   
        #print (val)     
        if (high_low_mode=='h'):
            s=1
            quant_sample_data_high.extend(val)
        else:
            quant_sample_data_low.extend(val)
        i +=1   
    return

def quant_sample_data_mix_linReg (sample_data_arrays,x1,y1,x_low,y_low, high_low_raw_mean_10thr):
    global quant_sample_data_mix,mean_array, low_mean_array, DF
    '''
    (((OD-ave. blank)-Intercept)/slope)*DF
    '''
    slope, intercept, r_value, p_value, std_err =func_linReg(x1, y1)
    slope_low, intercept_low, r_value_low, p_value_low, std_err_low =func_linReg(x_low, y_low)
    i=0
    quant_sample_data_mix=[]
    mean_blank=mean_array[-1]
    mean_blank_low=low_mean_array[-1]
   
    while i < len(sample_data_arrays):
#        print(sample_data_arrays[i])
        jj=0
        while jj < len(sample_data_arrays[i]):
            val=0
            if (np.array(sample_data_arrays)[i,jj] >=high_low_raw_mean_10thr):
                val=((np.array(sample_data_arrays)[i,jj]-mean_blank-intercept)/slope)*DF
            else:
                val=((np.array(sample_data_arrays)[i,jj]-mean_blank_low-intercept_low)/slope_low)*DF
        #print (val)     
            quant_sample_data_mix.append(val)
            jj +=1
        i +=1   
    return slope, intercept,r_value, slope_low, intercept_low,r_value_low, mean_blank, mean_blank_low

def quant_sample_data_mix_RANSAC (sample_data_arrays,x_org,y_org,x_low,y_low, high_low_raw_mean_10thr):
    global quant_sample_data_RANSAC, mean_array, low_mean_array, DF
    '''
    (((OD-ave. blank)-Intercept)/slope)*DF
    '''
    '''
     ############   RANSAC algorithm implementation for HIGH level
    '''
    
    model_ransac = linear_model.RANSACRegressor(linear_model.LinearRegression())
    x_ransac = np.array(x_org).reshape((-1, 1))
    y_ransac = np.array(y_org).reshape((-1, 1))
    model_ransac.fit(x_ransac, y_ransac)
    inlier_mask = model_ransac.inlier_mask_ #inlier_mask
    outlier_mask = np.logical_not(inlier_mask)
    line_X = np.arange(0, 100)
    line_y_ransac = model_ransac.predict(line_X[:, np.newaxis])
    slope_ransac=((line_y_ransac[99] - line_y_ransac[0])/99)
    intercept_ransac=line_y_ransac[0]
#    print ('RANSAC slope=\t'+str(slope_ransac))
#    print ('RANSACintersept=\t'+str(intercept_ransac))
#    print ('DF=\t'+str(DF))
    
    '''
     ############   RANSAC algorithm implementation for LOW level
    '''
        
    model_ransac_low = linear_model.RANSACRegressor(linear_model.LinearRegression())
    x_ransac_low = np.array(x_low).reshape((-1, 1))
    y_ransac_low = np.array(y_low).reshape((-1, 1))
    model_ransac_low.fit(x_ransac_low, y_ransac_low)
    inlier_mask_low = model_ransac_low.inlier_mask_
    outlier_mask_low = np.logical_not(inlier_mask_low)
    
    line_X_low = np.arange(0, 10)
    line_y_ransac_low = model_ransac_low.predict(line_X_low[:, np.newaxis])
    
    slope_ransac_low=((line_y_ransac_low[9]- line_y_ransac_low[0])/9)
    intercept_ransac_low=line_y_ransac_low[0]


    
    i=0
    quant_sample_data_RANSAC=[]
    mean_blank=mean_array[-1]
    mean_blank_low=low_mean_array[-1]
    
   
    while i < len(sample_data_arrays):
#        print(sample_data_arrays[i])
        jj=0
        while jj < len(sample_data_arrays[i]):
            val=0
            if (np.array(sample_data_arrays)[i,jj] >=high_low_raw_mean_10thr):
                val=((np.array(sample_data_arrays)[i,jj]-mean_blank-intercept_ransac)/slope_ransac)*DF
            else:
                val=((np.array(sample_data_arrays)[i,jj]-mean_blank_low-intercept_ransac_low)/slope_ransac_low)*DF
        #print (val)     
            quant_sample_data_RANSAC.append(val)
            jj +=1
        i +=1   
           
    return slope_ransac, intercept_ransac, slope_ransac_low, intercept_ransac_low, mean_blank, mean_blank_low


def print_sample_plate_list(sample_data_quantified):
    global sample_data_arrays
    i=0
    s=''
    col=-1
    jj=1
    abc=['A','B','C','D',"E",'F','G','H']
    
    while i<len(sample_data_quantified):
        status='0'
        if (i % 12 ==0):
            col +=1 
            jj=1
        if (sample_data_quantified[i]>800):
            status='99'
        #s +=abc[col]+str(jj).zfill(2)+'\t'+'%.2f'%(sample_data_quantified[i]) +'\t'+status +'\n'
        s +=abc[col]+':'+str(jj)+'\t'+'%.2f'%(sample_data_quantified[i]) +'\t'+status +'\n'
        i+=1
        jj +=1
    return s

def print_sample_plate(sample_data_quantified):
    i=0
    s=''
    while i<len(sample_data_quantified):
        if (i % 12 ==0):
            s +='\n'
        s +='\t'+'%.2f'%(sample_data_quantified[i])
        i+=1
    return s


def print_org_sample_plate(sample_data_org):
    i=0
    s=''
    while i < len(sample_data_org):
        jj=0
        while jj < len(sample_data_org[i]):
            val=(np.array(sample_data_arrays)[i,jj])
            s += '\t'+'%.2f'%(val)
            jj +=1
        s +='\n'
        i +=1
    return s

def write_sample_file(sample_filename,sQuantMethod, sText, sMode):
    global controlLUIDs_arr, quantFileStart
    dir_path =os.path.dirname(os.path.realpath(__file__))
    basename=os.path.basename(sample_filename)
    quantFileName=controlLUIDs_arr[quantFileStart]
#    new_name=dir_path+'/qq_'+basename
    new_name=quantFileName+'_'+basename
    sample_file = new_name+'.'+sQuantMethod+'.quant'
    # print (sample_file)
    '''
    sMode - a- appent, w -write
    '''
#    f = open(sample_file, sMode, encoding='utf-8', errors='ignore')
    f = open(sample_file, sMode, encoding='utf-8', errors='ignore')
    f.write(sText)
    f.close() 
    quantFileStart=quantFileStart+1
    return


def get_PG_calibration_params(processURI_v2):
    global user,psw
    r = requests.get(processURI_v2, auth=(user, psw), verify=True)
    rDOM = parseString(r.content)
    sDF=getUDF(rDOM, 'DF')
    sRep_outlier=getUDF(rDOM, 'Replica outlier')
    sFitMethod=getUDF(rDOM, 'Fitting Method')    

    return int(sDF), sRep_outlier,sFitMethod

def getUDF( rDOM, udfname ):
    response = ""
    elements = rDOM.getElementsByTagName( "udf:field" )
    for udf in elements:
        temp = udf.getAttribute( "name" )
        if temp == udfname:
            response = getInnerXml( udf.toxml(), "udf:field" )
            break
    return response

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




def func_linReg(x,y):
    return stats.linregress(x,y)



setupGlobalsFromURI(processURI_v2)
#print (BASE_URI, HOSTNAME)

if ((fileLuid) and (processURI_v2)) :
    file_input= get_local_PG_file(fileLuid)
    (DF,replica_outlier, sFitMethod)=get_PG_calibration_params(processURI_v2)
    replica_outlier=replica_outlier.upper()
    

'''

    ################################ START  #################
'''
#print (processURI_v2)
#print (DF)
#print (replica_outlier)
#exit()
replica_index=-1
replica_point=-1
if (replica_outlier):
    if (bool(re.search(r'\d', replica_outlier))):
        replica_point=replica_outlier[-1]
    if (replica_outlier.find('A')>=0):
        replica_index = 0
    elif (replica_outlier.find('B')>=0):
        replica_index = 1
    elif (replica_outlier.find('C')>=0):
        replica_index = 2
      

 

   
#exit()

parse_file(file_input)

get_org_arrays(arrays)
get_org_high_mean_array(org_high_array)

get_replicas_array(arrays, replica_index, replica_point)
#print (replicas_array)
get_replicas_mean_array(replicas_array)
#print (replicas_mean_array)
get_replicas_std_array(replicas_array)
#print (replicas_std_array)
#exit()

# arrays
get_std_array(arrays)
# arrays
get_mean_array(arrays)
get_corr_mean_array(replicas_mean_array)
get_cv_array(corrected_mean_array,replicas_std_array)


get_low_replicas_array(arrays)
get_low_mean_array(replicas_array_low)
get_low_std_array(replicas_array_low)
get_low_corr_mean_array(low_mean_array)
get_low_cv_array(low_corrected_mean_array, low_std_array)



# print ('***** Calibration values **************')
#print (arrays)
# print ('****** High Std array *************')
#print (std_array)
# print ('****** High maen array *************')
# print (mean_array)
# print (org_high_mean_array)
# print(org_high_array)
# print ('****** High Correctred mean array *************')
#print (corrected_mean_array)
#print ('****** High C.V. array *************')
#print (cv_array)
#print ('*******Low std array ************')
#print (low_std_array)
#print ('*******Low mean array ************')
#print (low_mean_array)
#print ('*******Low corrected mean  array ************')
#print (low_corrected_mean_array)
#print ('*******Low C.V. array ************')
#print (low_cv_array)
#print ('*******************')




# 25797
x = np.array([100,50,25,12.5,6.25,3.125,1.5625,0])
#y = np.array([25797.67,22608.67,11219.67,5876.00,2803.00,1413.67,695.67,0.00])
y= corrected_mean_array

x_low=np.array([10,5,2.5,1.25,0.625,0.3125,0.15625,0])
y_low=low_corrected_mean_array

# write_stats()

'''
    Remove 100ng/ul value 
'''
#x1= np.delete(x,0,0)
#y1= np.delete(y,0,0)



'''
    Plot triplicates

'''


# exit()
# dir_path =os.path.dirname(os.path.realpath(file_input))
#dir_path ='/opt/gls/clarity/ai/temp/'   
dir_path=os.path.dirname(os.path.realpath(__file__))


A_replica=np.array(org_high_array)[:,[0]]
B_replica=np.array(org_high_array)[:,[1]]
C_replica=np.array(org_high_array)[:,[2]]



plt.plot(x,A_replica,marker='o', linestyle='--', color='b', label='A replica')
plt.plot(x,B_replica,marker='o', linestyle='--', color='g', label='B replica')
plt.plot(x,C_replica,marker='o', linestyle='--', color='r', label='C replica')

#plt.plot(x,arrays[:,1],marker='o', linestyle='', color='b', label='')
plt.title('High range Std. curve -All replicates')
plt.xlabel('Concentration, ng/ul')
plt.ylabel('Intensity')
plt.legend(loc='upper left')
fig1=plt.gcf()
sLUID=""
if controlLUIDs_arr:
    sLUID=controlLUIDs_arr[9]
sFig1=sLUID+'_fig1_replicas_all.png'
fig1.savefig(sFig1)
plt.gcf().clear()


  
'''
    Get linear regression coefficients and create a plot
'''
x1= x
y1= y
if (int(replica_index) ==-1) and (int(replica_point)>=0):
    x1=np.delete(x,int(replica_point))

if (outliers):
    remove_outliers(outliers_array)
#    print (outliers_array)


        
Y_org=org_high_mean_array



scan_4_files(file_input,'.asc')

'''
 ############   RANSAC algorithm implementation for High level
'''
model_ransac = linear_model.RANSACRegressor(linear_model.LinearRegression())
x_ransac = np.array(x).reshape((-1, 1))
y_ransac = np.array(Y_org).reshape((-1, 1))
model_ransac.fit(x_ransac, y_ransac)
inlier_mask = model_ransac.inlier_mask_ #inlier_mask
outlier_mask = np.logical_not(inlier_mask)

line_X = np.arange(0, 100)
line_y_ransac = model_ransac.predict(line_X[:, np.newaxis])
#print ('line_X='+str(line_X))
#print ('line_y_ransac='+str(line_y_ransac))
slope_ransac=((line_y_ransac[99] - line_y_ransac[0])/99)
intercept_ransac=line_y_ransac[0]

# print ('intercept_ransac='+str(intercept_ransac)+'\t slope_ransac='+str(slope_ransac))

'''
    ########### end RNASAC
'''





slope, intercept, r_value, p_value, std_err = stats.linregress(x,Y_org)
line_y = intercept + slope*x
plt.plot(x,Y_org,marker='o', linestyle='', color='r', label='Data') 
plt.plot(x,line_y,'k-', linestyle='--', color='b', label='LinRegress')
plt.plot(line_X, line_y_ransac, '-b', color='g', label='RANSAC regressor')
plt.title('High range Std. curve -All points')
s="y(x)= %.2f +%.2f*x \n R2=%.5f"%(intercept,slope,r_value**2)
s_ransac="y_ransac(x)=%.2f +%.2f*x"%(intercept_ransac,slope_ransac)
# logging.info('RANSAC\t'+s_ransac)
y_max = np.max(Y_org) + 500
x_max = 0.5*np.max(x)
y_max_ransac = np.max(line_y_ransac) - 2000

plt.text(x_max, y_max_ransac, s_ransac, color='g')
plt.text(x_max, y_max, s, color='b')
plt.xlabel('Concentration, ng/ul')
plt.ylabel('Intensity')
k=0
for i,j in zip(x,y):
    plt.annotate(str(k),xy=(i+5,j))
    k +=1

plt.legend(loc='upper left')
sLUID=""
if controlLUIDs_arr:
    sLUID=controlLUIDs_arr[10]
sFig2=sLUID+'_fig2_linear_all.png' 
plt.savefig(sFig2)

plt.gcf().clear()


'''
    Get linear regression coefficients without outliers point and create a plot
'''
slope1, intercept1, r_value1, p_value1, std_err1 = stats.linregress(x1,y1)
line_y1 = intercept1 + slope1*x1
# print (line_y)
plt.plot(x1,y1,marker='o', linestyle='', color='r', label='Data') 
plt.plot(x1,line_y1,'k-', linestyle='--', color='b', label='LinRegress')
plt.title('High range Std. curve w/o outliers: #'+replica_outlier)
s1="y(x)= %.2f +%.2f*x \n R2=%.5f"%(intercept1,slope1,r_value1**2)
y_max1 = np.max(y1) - 500
x_max1 = 0.5*np.max(x1)
plt.text(x_max1, y_max1, s1)
plt.xlabel('Concentration, ng/ul')
plt.ylabel('Intensity')
#plt.legend(['data', 'line-regression'], 'best')
plt.legend(loc='upper left')
sLUID=""
if controlLUIDs_arr:
    sLUID=controlLUIDs_arr[11]
sFig3=sLUID+'_fig3_linear_No_outliers.png'
plt.savefig(sFig3) 

#logging.info('outliers\t'+str(replica_outlier))
#logging.info('high_outliers_linear\t'+s1.replace('\n',';'))

plt.gcf().clear()

'''
    Get polynomial  coefficients and greate a plot
'''
# coefs = poly.polyfit(x, y, 3)
coefs = poly.polyfit(x, Y_org, 2)
# print (coefs)
y_new = np.linspace(x[0], x[-1], 50)
ffit = poly.polyval(y_new, coefs)
plt.plot(x,Y_org,marker='o', linestyle='', color='r', label='Data')
plt.plot(y_new, ffit, linestyle='--', color='b', label='PolyRegress')
plt.title('Polynomial fit Std. curve')
plt.xlabel('Concentration, ng/ul')
plt.ylabel('Intensity')
#plt.legend(['data', 'poly-regression'], 'best')
plt.legend(loc='upper left')
# s_poly="y(x)= %.2f +%.2f*x +%.2f*x2 +%.2f*x3  \n"%(coefs[0],coefs[1],coefs[2],coefs[3])
s_poly="y(x)= %.2f +%.2f*x +%.2f*x2 \n"%(coefs[0],coefs[1],coefs[2])
y_max1 =  500
x_max1 = 0.5*np.max(x1)
plt.text(x_max1, y_max1, s_poly)
sFig4='fig4_polu_all.png'
# plt.savefig(sFig4)
#logging.info('high_all_poly\t'+s_poly.replace('\n',';'))

plt.gcf().clear()


'''
 ############   RANSAC algorithm implementation for LOW level
'''
model_ransac_low = linear_model.RANSACRegressor(linear_model.LinearRegression())
x_ransac_low = np.array(x_low).reshape((-1, 1))
y_ransac_low = np.array(y_low).reshape((-1, 1))
model_ransac_low.fit(x_ransac_low, y_ransac_low)
inlier_mask_low = model_ransac_low.inlier_mask_
outlier_mask_low = np.logical_not(inlier_mask_low)

line_X_low = np.arange(0, 10)
line_y_ransac_low = model_ransac_low.predict(line_X_low[:, np.newaxis])

slope_ransac_low=((line_y_ransac_low[9]- line_y_ransac_low[0])/9)
intercept_ransac_low=line_y_ransac_low[0]

# print ('intercept_ransac_low='+str(intercept_ransac_low)+'\t slope_ransac_low='+str(slope_ransac_low))


'''
    ########### end RNASAC
'''






'''
    Get linear regression coefficients for Low concentration and create a plot
'''
slope_low, intercept_low, r_value_low, p_value_low, std_err_low = stats.linregress(x_low,y_low)
line_y_low = intercept_low + slope_low*x_low

plt.plot(x_low,y_low,marker='o', linestyle='', color='r', label='Data') 
plt.plot(x_low,line_y_low,'k-', linestyle='--', color='b', label='LinRegress')
plt.plot(line_X_low,line_y_ransac_low, linestyle='dotted', color='g', label='RANSAC regressor')

plt.title('Low range Std. curve')
s_low="y_low(x)= %.2f +%.2f*x \n R2=%.5f"%(intercept_low,slope_low,r_value_low**2)
s_low_ransac="y_ransac_low(x)=%.2f +%.2f*x"%(intercept_ransac_low,slope_ransac_low)
#logging.info('RANSAC_low\t'+s_low_ransac)
y_max_low = np.max(y_low)# + 500
x_max_low = 0.5*np.max(x_low)
plt.text(x_max_low, y_max_low, s_low, color='b')
plt.text(x_max_low, y_max_low-200, s_low_ransac, color='g')
plt.xlabel('Concentration, ng/ul')
plt.ylabel('Intensity')
#plt.legend(['data', 'line-regression'], 'best')
plt.legend(loc='upper left')
sLUID=""
if controlLUIDs_arr:
    sLUID=controlLUIDs_arr[12]
sFig5=sLUID+'_fig5_linear_all_low.png'
plt.savefig(sFig5)
#logging.info('low_all_linear\t'+s_low.replace('\n',';'))

plt.gcf().clear()


#f1 = Image.open("fig_replicas_all.png").show()
#f3 = Image.open("fig_linear_all.png").show()
#f2 = Image.open("fig_linear_No_outliers.png").show()
#f = Image.open("fig_linear_all_low.png").show()

# scan_4_files(file_input,'.asc')

#write_sample_file("92-1048_mytest1.txt","", "Test test test", 'w') 
#write_sample_file("92-1049_mytest2.png","", "############\n#############\n", 'w')


'''
    Get logarithmic regression and create a plot
'''





