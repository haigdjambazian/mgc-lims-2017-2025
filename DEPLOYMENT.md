## [5.0.13-uc1] deployed from [5.0.12] - 2025-03-13
## Deployment Instructions for branch:tag release_5.0:5.0.13-uc1
### Get the files from the repository
To get the files define LOCALREPO and run the following commands:
```
ssh bravoqcapp.genome.mcgill.ca
LOCALREPO="";
cd $LOCALREPO;
git clone -b release_5.0 https://itgenome@bitbucket.org/mugqic/clarity.git;
cd $LOCALREPO/clarity;
git checkout 5.0.13-uc1;
```
### LIMS Workflow Configuration
Up to date.
### LIMS Workflow Scripts
Update these files
```
sudo su - glsai
cp $LOCALREPO/clarity/runprocessing/adapter_settings_format.txt /opt/gls/clarity/customextensions/Common/adapter_settings_format.txt;
cp $LOCALREPO/clarity/runprocessing/adapter_types.txt /opt/gls/clarity/customextensions/Common/adapter_types.txt;
```
### LIMS stand alone reporting scripts
Up to date.
### LIMS application and Python Configuration
Up to date.
### Sample Manifest
Update these files and lims properties:
```
sudo su - glsjboss;
cp $LOCALREPO/clarity/samplesubmissiontemplates/MGC_Sample_Submission_Template_BLANK.xlsx /opt/gls/clarity/glscontents/lablink/downloads/MGC_Sample_Submission_Template_BLANK_v5.0.13.xlsx;
java -jar /opt/gls/clarity/tools/propertytool/omxprops-ConfigTool.jar set clarity.exampleSampleSheet.uri '/glsstatic/lablink/downloads/MGC_Sample_Submission_Template_BLANK_v5.0.13.xlsx';
```
### Run processing
```
LIMSUSER=bravolims-qc; # LIMSUSER=bravolims # for prod
ssh $LIMSUSER@abacus3.genome.mcgill.ca;
LOCALREPO="";
cd $LOCALREPO;
git clone -b release_5.0 https://itgenome@bitbucket.org/mugqic/clarity.git;
cd $LOCALREPO/clarity;
git checkout 5.0.13-uc1;
cp $LOCALREPO/clarity/runprocessing/adapter_settings_format.txt /home/$LIMSUSER/runprocessing/adapter_settings_format.txt;
cp $LOCALREPO/clarity/runprocessing/adapter_types.txt /home/$LIMSUSER/runprocessing/adapter_types.txt;
cd /home/$LIMSUSER/runprocessing;
ruby update_merged_barcode_table.rb;
```
###
[see changes](https://bitbucket.org/mugqic/clarity/branches/compare/5.0.13-uc1%0D5.0.12#diff)
