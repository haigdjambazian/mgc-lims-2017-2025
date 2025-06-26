''' 

update 2018_09_05:

original name NovaSeq_run_status.py has been changed to IlluminaSeq_run_status.py
    


'''

from interop import py_interop_run_metrics
from interop import py_interop_summary
from interop import py_interop_run
import sys,hashlib,os, time, argparse, logging, shutil,csv
from optparse import OptionParser 
import warnings
warnings.filterwarnings("ignore", message="numpy.dtype size changed")
warnings.filterwarnings("ignore", message="numpy.ufunc size changed")
import pandas as pd
import numpy as np
from shutil import copyfile


import os
import sys
import glob
import csv



def setup_arguments():

    Parser = OptionParser()
    Parser.add_option('-d', "--IlluminaSeqDir", action='store', dest='IlluminaSeqDir')
    Parser.add_option('-o', "--output", action='store', dest='outputLUID')
    Parser.add_option('-i', "--inputFile", action='store', dest='inputFile')
    Parser.add_option('-f', "--outputFile", action='store', dest='outputFile')
    
    return Parser.parse_args()[0]

global args

args=setup_arguments()
rootpath=args.IlluminaSeqDir
outputLUID=args.outputLUID
settingsfile=args.inputFile
outputFile=args.outputFile

#rootpath="$1";
#rootpath='/Research/Novaseq'
#settingsfile="$2";
#settingsfile='/tmp/92-446254_H7TWNDMXX_status_request.txt'


if not os.path.exists(rootpath):
    print(rootpath + " does not exist! exit.");
    sys.exit(1)

settingsdata=[]

with open(settingsfile, 'r') as csvfile:
    reader = csv.DictReader(csvfile, delimiter='\t')
    for row in reader:
        settingsdata.append(row)

for i in range(0,len(settingsdata)):
    settingsdata[i]['Lane'] = int(settingsdata[i]['Lane'].split(':')[0])

flowcellid = settingsdata[0]['ContainerName']
processid = settingsdata[0]['ProcessLUID']

try:
    tmprun_folder_path = glob.glob(rootpath + "/" + "*" + flowcellid + "*")[0]
except:
    print ("Run status files are not ready for "+ flowcellid )  
    sys.exit()  

if len(tmprun_folder_path) == 0:
    print(rootpath + "/" + "*" + flowcellid + "*" + " does not exist! exit.");
    sys.exit()

#run_folder_path = tmprun_folder_path[0]
run_folder_path = tmprun_folder_path


#print(run_folder_path,tmprun_folder_path)

run_folder=run_folder_path.split('/')[-1]

#file = open(processid + "_" +flowcellid + ".dbupload.txt","w")


file = open(outputLUID + "_" +flowcellid + ".dbupload.txt","w")
file.write("Pub\tLUID Type\tLUID\tUDF Name\tPath/Value\n");

if os.path.exists(run_folder_path + "/" + "RTAComplete.txt"):
   a=file.write("1\tUDF\t" + processid + "\tStatus\t" + "Complete" + "\n");
   a=file.write("1\tUDF\t" + processid + "\tRun ID\t" + run_folder + "\n");
   a=file.write("1\tUDF\t" + processid + "\tFlow Cell ID\t" + flowcellid + "\n");
   a=file.close()
   
else:
   a=file.write("1\tUDF\t" + processid + "\tStatus\t" + "Running" + "\n");
   a=file.write("1\tUDF\t" + processid + "\tRun ID\t" + run_folder + "\n");
   a=file.write("1\tUDF\t" + processid + "\tFlow Cell ID\t" + flowcellid + "\n");
   a=file.close()
   copyfile (outputLUID + "_" + flowcellid + ".dbupload.txt",outputFile)
   sys.exit() 


run_metrics = py_interop_run_metrics.run_metrics()
summary = py_interop_summary.run_summary()
valid_to_load = py_interop_run.uchar_vector(py_interop_run.MetricCount, 0)
py_interop_run_metrics.list_summary_metrics_to_load(valid_to_load)

run_metrics.read(run_folder_path, valid_to_load)
py_interop_summary.summarize_run_metrics(run_metrics, summary)
summary = py_interop_summary.run_summary()
py_interop_summary.summarize_run_metrics(run_metrics, summary)

columns = (('Yield PF (Gb)', 'yield_g'), ('% Bases >=Q30', 'percent_gt_q30'),('Cluster Density (K/mm^2)', 'density'), ('Intensity Cycle 1','first_cycle_intensity'),  ('% Aligned', 'percent_aligned'),('% Error Rate','error_rate'))
rows = [summary.at(read).at(lane) for lane in range(summary.lane_count()) for read in range(summary.size()) ]


d = []
d.append(('Lane',[ lane+1 for lane in range(summary.lane_count()) for read in range(summary.size())]))

f=[]
for lane in range(summary.lane_count()):
    readcounter=0
    indexcounter=0
    for i in range(summary.size()):
        if summary.at(i).read().is_index():
            indexcounter=indexcounter+1
            f.append('I'+str(indexcounter))
            
        else:
            readcounter=readcounter+1
            f.append('R'+str(readcounter))

d.append(('Read',f))

def format_value(val):
    if hasattr(val, 'mean'):
        return val.mean()
    
    else:
        return val

for label, func in columns:
    d.append( (label, pd.Series([format_value(getattr(r, func)()) for r in rows])))


df = pd.DataFrame.from_items(d)

df = df[np.logical_and(df['Read'] != 'I1', df['Read'] != 'I2') ]

dfpiv = df.pivot(index='Lane', columns='Read')

dfpiv.columns = [' '.join(col).strip().split(' <lambda>')[0] for col in dfpiv.columns.values]
dfpiv = dfpiv.reset_index()


settingsdf = pd.DataFrame.from_dict(settingsdata)

#exit()
tmpfinal = pd.merge(settingsdf,dfpiv,on='Lane',how='outer')

# "Pub\tLUID Type\tLUID\tUDF Name\tPath/Value\n"
finaldf = pd.DataFrame()

'''
# removed 2018_09_05 
 
for name, group in tmpfinal.groupby('ArtifactLUID'):
    finalgroup = group[['Yield PF (Gb) R1','Yield PF (Gb) R2','% Bases >=Q30 R1','% Bases >=Q30 R2', 'Cluster Density (K/mm^2) R1','Cluster Density (K/mm^2) R2','Intensity Cycle 1 R1','Intensity Cycle 1 R2','% Aligned R1','% Aligned R2','% Error Rate R1','% Error Rate R2']].T.reset_index()
    finalgroup['LUID']=name
    finalgroup['Pub']=1
    finalgroup['LUID Type']='UDF'
    finalgroup.columns = ['UDF Name','Path/Value','LUID','Pub','LUID Type']
    finalgroup=finalgroup[['Pub','LUID Type','LUID','UDF Name','Path/Value']]
    finaldf = finaldf.append(finalgroup)
'''
for name, group in tmpfinal.groupby('ArtifactLUID'):                                                                                                                                                                
    finalgroup = group.T.reset_index()                                                                                                                                                                              
    finalgroup['LUID']=name                                                                                                                                                                                         
    finalgroup['Pub']=1                                                                                                                                                                                             
    finalgroup['LUID Type']='UDF'                                                                                                                                                                                   
    finalgroup.columns = ['UDF Name','Path/Value','LUID','Pub','LUID Type']                                                                                                                                         
    finalgroup=finalgroup[['Pub','LUID Type','LUID','UDF Name','Path/Value']]                                                                                                                                       
    finaldf = finaldf.append(finalgroup)  



finaldf = finaldf.reset_index(drop=True)
#print(finaldf)

finaldf.to_csv(outputLUID + "_" + flowcellid + ".dbupload.txt", sep='\t', index=False, float_format='%.3f', mode='a', header=False)
copyfile (outputLUID + "_" + flowcellid + ".dbupload.txt",outputFile)
#print (outputLUID + "_" + flowcellid + ".dbupload.txt "+" file has been copied to "+outputFile)

