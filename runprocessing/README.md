# run monitoring and event handler code
## McGill Clarity LIMS event monitor steps

### LIMS event file
A file with run details is generated from LIMS when sequencing steps are started. This file contains all releveant information to run the processing pipeline such as sample names, library index, species and reference when applicable as well as other lims information such as sex.
This file is initially generated in this path:
```
/lb/robot/research/processing/events/
```

### Main monitor process
The main monitor runs under the user bravolims.  The main monitor process detects new event files and checks if that are duplicated.  It moves the event file to this example path:
```
/lb/robot/research/processing/events/system/2020/2020-04-01-T13.37.58-valid
```
The main monitor process then start a child process that takes care of a single run.

### Run specific monitor process: Detect rapid response email
If a project is marked as rapid response the child event monitor sends an email for each rapid reponse project to the corresponding user emails to that project.
This configuration is defines in this file in the repository:
```
runprocessing/config_email.csv
```
### Run specific monitor process: Monitor network writing alert email
During a run if the writing to the network slows down too much or stops for too long, the child monitor send alert email to the lab and to IT. If the writing of the run to the network resumes another email is sent alerting the same users of that also.
The timing specific for each instrument is defined in this config file in the repository: 
```
runprocessing/instrument_list.csv
```
### Run specific monitor process: Start run processing
When the RTAcomplete.txt file is detected the run processing is launched under the user bravolims (in production).

### Run specific monitor process: Rapid response fastq ready
When the fastq "done" flags are seen for special projects copy fastq files to rapid response folder and email the lab and the bioinformatics team that fastqs are ready.
This occurs for each lane as they may be ready at different times.
The child monitor copies the yet to be validated fastqs to this path:
```
/lb/robot/research/processing/rapidresponse/
```
The monitor also creates a readset file compatible with genpipes and places it in the same file as well as in the email.

### Run specific monitor process: Run processing complete
When the run processing is finished an email to let lab know. The number of failed jobs is included in the email as well as a plot of the the read yields for each samples and also a table with the same numbers.

# other utilities
