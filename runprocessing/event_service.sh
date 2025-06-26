#!/bin/bash

#title           : event_service.sh
#description     : This script offers multiple services such as: run writing to network monitoring, run processing starting, end of processing email and rapid response emails.
#author          : Haig Djambazian
#date            : 20200617
#version         : 2.0
#usage           : cd /home/$USER/runprocessing
#usage           : bash event_service.sh start
#usage           : bash event_service.sh stop

if [ "$USER" == "bravolims" ]; then
    RUNDIRROOT=/nb/Research;
    RUNDIRROOTONT=/nb;
    SCRATCHDIRROOT=/nb/Research;
    SCRATCHDIRROOTMGI=/nb/Research/processingmgiscratch;
    SCRATCHDIRROOTCOVIDONT=/nb/Research/processingontscratch;
    ROBOTDIRROOT=/lb/robot/research;
    TESTMSG="";
    OVERRIDEEMAIL="";
    EXTRA_INI="/home/$USER/mgirunprocessing/mgi_run_processing.base.ini"
    EXTRA_INI_COVIDONT="/home/$USER/ontcovidrunprocessing/nanopore_covseq.base.ini"
    QOSOVERRIDE="cluster_other_arg=-W umask=0002 -l qos=research"
    mkdir -p  $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-dnbseqg400;
    mkdir -p  $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-ontcovidseq;
fi

if [ "$USER" == "bravolims-qc" ]; then
    RUNDIRROOT=/lb/bravo/bravoqc/nb-Research;
    RUNDIRROOTONT=/lb/bravo/bravoqc/nb;
    SCRATCHDIRROOT=/lb/bravo/bravoqc/nb-Research;
    SCRATCHDIRROOTMGI=/lb/bravo/bravoqc/nb-Research/processingmgiscratch;
    SCRATCHDIRROOTCOVIDONT=/lb/bravo/bravoqc/nb-Research/processingontscratch;
    ROBOTDIRROOT=/lb/bravo/bravoqc/lb-robot-research;
    TESTMSG="SENT FROM QC ENVIRONMENT - NOT A REAL RUN - ";
    OVERRIDEEMAIL="";
    EXTRA_INI="/home/$USER/mgirunprocessing/mgi_run_processing.base-qc.ini"
    EXTRA_INI_COVIDONT="/home/$USER/ontcovidrunprocessing/nanopore_covseq.base.ini"
    QOSOVERRIDE="cluster_other_arg=-W umask=0002"
    mkdir -p  $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-dnbseqg400;
    mkdir -p  $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-ontcovidseq;
fi

if [ "$USER" == "bravolims-dev" ]; then
    RUNDIRROOT=/lb/bravo/bravodev/nb-Research;
    RUNDIRROOTONT=/lb/bravo/bravodev/nb;
    SCRATCHDIRROOT=/lb/bravo/bravodev/nb-Research;
    SCRATCHDIRROOTMGI=/lb/bravo/bravodev/nb-Research/processingmgiscratch;
    SCRATCHDIRROOTCOVIDONT=/lb/bravo/bravodev/nb-Research/processingontscratch;
    ROBOTDIRROOT=/lb/bravo/bravodev/lb-robot-research;
    TESTMSG="SENT FROM DEV ENVIRONMENT - NOT A REAL RUN - ";
    OVERRIDEEMAIL=$(grep ^DEV_EMAIL_LIST ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');
    EXTRA_INI="/home/$USER/mgirunprocessing/mgi_run_processing.base-dev.ini"
    EXTRA_INI_COVIDONT="/home/$USER/ontcovidrunprocessing/nanopore_covseq.base.ini"
    QOSOVERRIDE="cluster_other_arg=-W umask=0002"
    mkdir -p  $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-dnbseqg400;
    mkdir -p  $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-ontcovidseq;
fi

RUN_DROP_LIST="$RUNDIRROOT/Miseq,$RUNDIRROOT/hiseqX,$RUNDIRROOT/Novaseq,$RUNDIRROOT/NovaseqX,$RUNDIRROOT/iSeq/RUNS,$RUNDIRROOT/iSeq/RUNS/atlasfs/researchISeq/RUNS,$RUNDIRROOT/MGISeq/seq1/R2130400190016,$RUNDIRROOT/MGISeq/seq2/R2130400190018,$RUNDIRROOT/MGISeq/T7/R1100600200054/upload/workspace,$RUNDIRROOTONT/promethion/*/*,$RUNDIRROOTONT/minion/*/*,$RUNDIRROOTONT/gridion/*/*"

EVENTSDIR=$ROBOTDIRROOT/processing/events

SLEEPTIME=600;

EVENTDELAY=$SLEEPTIME
QUEUE=sw; PROC=1; DAYS=14; QOS="-l qos=research";

function run_processing {
  
  EMAIL_LIST_ALERT=$(grep ^RUN_NETWORK_ALERT ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');
  EMAIL_LIST_UPDATE=$(grep ^PROCESSING_COMPLETE ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');
  
  if [ "$OVERRIDEEMAIL" != "" ]; then
   EMAIL_LIST_ALERT="$OVERRIDEEMAIL";
  fi
  if [ "$OVERRIDEEMAIL" != "" ]; then
    EMAIL_LIST_UPDATE="$OVERRIDEEMAIL";
  fi
  
  # Instrument ID,Instrument ID,Instrument type,Instrument name,write delay
  instrument_list=$(cat instrument_list.csv)
    
  EVENTFILE=$1;
  
  IFS=$'\n';
  if [ "$(tail -n+2 "$EVENTFILE" | awk -F '\t' '{print $5}' | grep -v "^$" | sort -u | wc -l)" != "1" ]; then
    echo "More than one FCID found in $LIMS_INPUT_TSV_CLARITY, exit";
    return;
  fi
  
  FCID_CLARITY=$(tail -n+2 $EVENTFILE | awk -F '\t' '{print $5}' | grep -v "^$" | sort -u);

  ############################################  
  # find folder using FCID from event file
  # if folder not present wait
  set -o noglob
  while(true); do    
    IFS=',';
    found=false;
    for RUN_DROP in $RUN_DROP_LIST; do
      set +o noglob
      FLOWCELLDIR=$(ls -rtd $RUN_DROP/*${FCID_CLARITY}* 2>/dev/null | tail -n 1);
      set -o noglob
      if [ -d "$FLOWCELLDIR" ]; then
        echo "Found run: "$FLOWCELLDIR;
        found=true;
        break;
      fi;
    done;
    IFS=$'\n';    
    if($found); then
        break;
    fi
    sleep $SLEEPTIME;
  done  
  set +o noglob

  for line in $(echo "$instrument_list"); do
    instrument=$(echo "$line" | awk -F',' '{print $2}');
    if echo "$FLOWCELLDIR" | grep -q $instrument; then
      break;
    fi;
  done

  INSTRUMENT_IDLAB=$(echo "$line" | awk -F',' '{print $1}');
  INSTRUMENT_ID=$(echo "$line" | awk -F',' '{print $2}');
  INSTRUMENT_TYPE=$(echo "$line" | awk -F',' '{print $3}');
  INSTRUMENT_NAME=$(echo "$line" | awk -F',' '{print $4}');
  NETCOPYTIME=$(echo "$line" | awk -F',' '{print $5}');

  ############################################
  # Detect if FASTQREADY project are present
  # send email
  #
  PROJECT_LANE_PRESENT=$(tail -n+2 $EVENTFILE | grep -v "^$" | awk -F'\t' '{print $2 "\t" $3 "\t" $6}' | sed 's/:1//g' | sort -u | \
      grep -E "$(grep ^RAPID_RESPONSE ./email_config.csv | awk -F',' '{print $2}' | tr '\n' '|' | rev | cut -c 2- | rev)");
  
  for PROJECTIDNAME in $(printf "$PROJECT_LANE_PRESENT"| awk -F'\t' '{print $1","$2}' | sort -u); do
      PROJECTID=$(echo "$PROJECTIDNAME" | awk -F',' '{print $1}');
      PROJECTNAME=$(echo "$PROJECTIDNAME" | awk -F',' '{print $2}');
      RAPID_RESPONSE_EMAILS=$(grep "$PROJECTID" ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');
      ONTCOVID_EMAILS=$(grep "ONTCOVID" ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');
      if [ "$OVERRIDEEMAIL" != "" ]; then
          RAPID_RESPONSE_EMAILS=$OVERRIDEEMAIL;
   	      ONTCOVID_EMAILS=$OVERRIDEEMAIL;
      fi
      if [ "$instrument" == "promethion" ]; then
  	      MSG=$(printf "${TESTMSG}This is an automated message sent from the run processing event monitor.\n$INSTRUMENT_TYPE run $(basename $(dirname $FLOWCELLDIR))/$(basename $FLOWCELLDIR) contains $INSTRUMENT_TYPE rapid response datasets.\n\n*** Run is ongoing. ***\n*** Run processing (with basecalling if needed) will start automatically as run completes. ***\n\nProject present in run:\nProject ID - Project Name - Lane\n$(echo "$PROJECT_LANE_PRESENT" | grep $PROJECTID | tr '\t' ',' | sed 's/,/ - /g')\n\nSample Names:\n$(cat $EVENTFILE | grep $PROJECTID | awk -F'\t' '{print $13}')\n");
	      echo "$MSG" | mailx -s "${TESTMSG}RAPID REPONSE $INSTRUMENT_TYPE Run detected, $(basename $(dirname $FLOWCELLDIR))/$(basename $FLOWCELLDIR) Project ID: $PROJECTID, Project Name: $PROJECTNAME."  -r "bravo.genome@mcgill.ca" $ONTCOVID_EMAILS;
      else
	      MSG=$(printf "${TESTMSG}This is an automated message sent from the run processing event monitor.\nRun $(basename $FLOWCELLDIR) contains $INSTRUMENT_TYPE rapid response datasets.\n\n*** Run is ongoing. ***\n*** Expect one email per lane for this project as run completes and fastqs are generated. ***\n\nProject present in run:\nProject ID - Project Name - Lane\n$(echo "$PROJECT_LANE_PRESENT" | grep $PROJECTID | tr '\t' ',' | sed 's/,/ - /g')\n\nSample Names:\n$(cat $EVENTFILE | grep $PROJECTID | awk -F'\t' '{print $13}')\n");
	      echo "$MSG" | mailx -s "${TESTMSG}RAPID REPONSE $INSTRUMENT_TYPE Run detected, $(basename $FLOWCELLDIR) Project ID: $PROJECTID, Project Name: $PROJECTNAME."  -r "bravo.genome@mcgill.ca" $RAPID_RESPONSE_EMAILS;
      fi
  done


if [ "$INSTRUMENT_TYPE" == "dnbseqg400" ]; then

  #######################################################
  #######################################################
  ##  __  __  _____ _____    _____ _  _    ___   ___   ##
  ## |  \/  |/ ____|_   _|  / ____| || |  / _ \ / _ \  ##
  ## | \  / | |  __  | |   | |  __| || |_| | | | | | | ##
  ## | |\/| | | |_ | | |   | | |_ |__   _| | | | | | | ##
  ## | |  | | |__| |_| |_  | |__| |  | | | |_| | |_| | ##
  ## |_|  |_|\_____|_____|  \_____|  |_|  \___/ \___/  ##
  ##                                                   ##
  ##MGI G400#############################################
  #######################################################
  
  ############################################
  # Now wait for *_Success.txt  
  # when present startjob
  while(true); do
    
    runtransferredfile=$(ls $FLOWCELLDIR/*_Success.txt)
    if [ -f "$runtransferredfile" ]; then
      echo "$runtransferredfile was found, continue.";
      break;
    fi
    
    sleep $SLEEPTIME;
    
  done;

  ############################################
  # create output run directory
  # 
  # get lab run id
  LAB_RUNID=$(grep 'DNB ID' $FLOWCELLDIR/L01/BioInfo.csv | awk -F',' '{print $2}' | awk -F'_' '{print $1}')
  LAB_RUNCOUNT=$(printf "1%04d" $(echo "$LAB_RUNID" | awk -F'MG' '{print $1}' | cut -c 2-| sed 's/^0*//'))
  FLOWCELLSIDE=$(grep 'Flowcell Pos' $FLOWCELLDIR/L01/BioInfo.csv | awk -F',' '{print $2}' );
  # SEQUENCEDATE=$(grep 'Sequence Date' $FLOWCELLDIR/L01/BioInfo.csv | awk -F',' '{print $2}' | tr -d '-' | cut -c 3-)
  SEQUENCEDATE=$(tail -n +2 $EVENTFILE | grep -v "^$" | awk -F'\t' '{print $15}' | head -n 1 | tr -d '-' | cut -c 3-);
  STARTDATE=$(tail -n+2 $EVENTFILE | grep -v "^$" | awk -F'\t' '{print $15}' | head -n 1 | awk -F'-' '{print $1}');  

  RUNDIR="${SEQUENCEDATE}_${INSTRUMENT_ID}_${LAB_RUNCOUNT}_${FLOWCELLSIDE}${FCID_CLARITY}_${LAB_RUNID}-${INSTRUMENT_TYPE}"  
  PROCESSINGPATH=$SCRATCHDIRROOTMGI/processing/$RUNDIR;

  ############################################
  # start pipeline
  #
  
  # make sure that all "monitor" done files are removed.
  for file in $PROCESSINGPATH/*.done; do
      if [ -f "$file" ]; then
	  rm $file;
      fi
  done

  SAMPLESHEETMGI=$(dirname $EVENTFILE)/$RUNDIR.csv

  printf "Sample_Name,Readset,Library,Project,Project_ID,Protocol,Library_Source,Index,Pool_ID,RUN_ID,Flowcell_ID,Lane,Run_Date,Sequencer,SequencerID\n" > $SAMPLESHEETMGI;

  # tail -n+2 $EVENTFILE | grep -v "^$" | awk -F'\t' '{print $13 "," $13"."$8".'${INSTRUMENT_ID}_${LAB_RUNCOUNT}'."$6 "," $8 "," $3 "," $2 "," $9 "," "librarysource"$9 "," $7 "," "Lane_"$6 "," "'$LAB_RUNID'" "," $5 "," $6 "," $15 "," "'$INSTRUMENT_IDLAB'" "," "'$INSTRUMENT_NAME'"}' | sed 's/:1//g' >> $SAMPLESHEETMGI

  tail -n+2 $EVENTFILE | grep -v "^$" | awk -F'\t' '{print $13 "," $13"."$8".'${INSTRUMENT_ID}_${LAB_RUNCOUNT}'."$6 "," $8 "," $3 "," $2 "," $9 "," "librarysource"$9 "," $7 "," "Lane_"$6 "," "'${INSTRUMENT_ID}_${LAB_RUNCOUNT}'" "," $5 "," $6 "," $15 "," "'$INSTRUMENT_IDLAB'" "," "'$INSTRUMENT_NAME'"}' | sed 's/:1//g' >> $SAMPLESHEETMGI

  for libtype in $(tail -n +2 $EVENTFILE | awk -F'\t' '{print $9}' | sort -u); do
    libsource=$(grep "$libtype," library_protocol_list.csv | awk -F',' '{print $2}' | sed 's/default //g')
    cat $SAMPLESHEETMGI | sed "s/librarysource$libtype/$libsource/g" > $SAMPLESHEETMGI.tmp
    mv $SAMPLESHEETMGI.tmp $SAMPLESHEETMGI
  done

  MUGQIC_PIPELINES_HOME=/home/$USER/mgirunprocessing/genpipes;
  
  if [[ $(basename $FLOWCELLDIR) == *_* ]]; then
      PREFIX=${FCID_CLARITY}_${LAB_RUNID}
  else
      PREFIX=${FCID_CLARITY};
  fi
  
  # call genpipes
  module load mugqic/python/3.9.1 && \
    mkdir -p $PROCESSINGPATH && \
    python $MUGQIC_PIPELINES_HOME/pipelines/run_processing/run_processing.py \
    -c /home/$USER/mgirunprocessing/genpipes/pipelines/run_processing/run_processing.base.ini \
     $EXTRA_INI \
    -t mgig400 \
    -l debug \
    -j pbs \
    -d $FLOWCELLDIR \
    -r $EVENTFILE \
    -o $PROCESSINGPATH \
    > $(dirname $EVENTFILE)/$RUNDIR.sh \
    2> $(dirname $EVENTFILE)/$RUNDIR.trace.log

  mv RunProcessing.config.trace.ini $(dirname $EVENTFILE)/
  
  if [ "$(cat $(dirname $EVENTFILE)/$RUNDIR.sh | wc -l)" == "0" ]; then
TRACE=$(dirname $EVENTFILE)/$RUNDIR.trace.log
HTML=$(cat <<EOF
<html><head><title>Run processing has FAILED TO START for MGI G400 run: $RUNDIR</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table.style2 { border-collapse: collapse; border: 1px solid #A0A0A0; border-style: solid; font-size: 12px;}
table.style2 th { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
table.style2 td { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
body {font-family: Arial;}
div {white-space: pre-wrap;white-space:nowrap;}
</style>
</head>
<body>
${TESTMSG}This is an automated message sent from the run processing event monitor.<br>
Run processing has FAILED TO START for MGI G400 run: $RUNDIR.<br>
Event file used is attached.<br>
<h3>Content of trace:</h3>
$(cat $TRACE | awk '{print "<div>"$0"</div>"}' )
EOF
);

(echo "To: $(echo "$EMAIL_LIST_UPDATE")"
echo "Reply-To: hercules@mcgill.ca"
echo "MIME-Version: 1.0"
echo "Subject: ${TESTMSG}Run processing has FAILED TO START for MGI G400 run: $RUNDIR"
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
echo '---q1w2e3r4t5'
f=$EVENTFILE
echo "Content-Type: text; name=$(basename $f)"
echo 'Content-Transfer-Encoding: base64'
echo "Content-Disposition: attachment; filename=$(basename $f)"
echo
base64 "$f"
echo '---q1w2e3r4t5--'
) | sendmail -t -f bravo.genome@mcgill.ca;
  else
    
    # call shell script generated
    sh $(dirname $EVENTFILE)/$RUNDIR.sh

HTML=$(cat <<EOF
<html><head><title>Run processing has started for MGI G400 run: $RUNDIR</title>
</head>
<body>
${TESTMSG}This is an automated message sent from the run processing event monitor.<br>
Run processing has started for  MGI G400 run: $RUNDIR.<br>
Event file used is attached.<br>
EOF
);
(echo "To: $(echo "$EMAIL_LIST_UPDATE")"
echo "Reply-To: hercules@mcgill.ca"
echo "MIME-Version: 1.0"
echo "Subject: ${TESTMSG}Run processing has started for MGI G400 run: $RUNDIR"
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
echo '---q1w2e3r4t5'
f=$EVENTFILE
echo "Content-Type: text; name=$(basename $f)"
echo 'Content-Transfer-Encoding: base64'
echo "Content-Disposition: attachment; filename=$(basename $f)"
echo
base64 "$f"
echo '---q1w2e3r4t5--'
) | sendmail -t -f bravo.genome@mcgill.ca;

  fi

  ############################################
  # wait for monitor job complete
  # email lab
  #
  
  # RUNDIR=$(basename $FLOWCELLDIR);
  
  if [ "$(cat $(dirname $EVENTFILE)/$RUNDIR.sh | wc -l)" == "0" ]; then
     # just exit since the pipeline could not be launched
     echo "Processing has failed for $RUNDIR, don't send final email.";  
  else
 
  while(true); do
      JOBDATE=$(ls $PROCESSINGPATH/job_output/*_job_list_* 2>/dev/null | awk -F'_job_list_' '{print $2}' | tail -n 1);
      qstat | tail -n+3 | awk '$5!="C"{print $1}' | awk -F'.' '{print $1}' | sort > $(dirname $EVENTFILE)/inscheduler.txt;
      cat $PROCESSINGPATH/job_output/*_job_list_$JOBDATE | awk -F'.' '{print $1}' | sort > $(dirname $EVENTFILE)/inpipeline.txt;
      JOBDONECOUNT=$(comm -12 $(dirname $EVENTFILE)/inscheduler.txt $(dirname $EVENTFILE)/inpipeline.txt | wc -l);
      
      . ./make_job_output_table_generic.sh; makejobtable $PROCESSINGPATH RunProcessing_job_list $PROCESSINGPATH  
      cp -v $PROCESSINGPATH/$RUNDIR-run.html $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-$INSTRUMENT_TYPE/;
      
      if [ "$JOBDONECOUNT" == "0" ]; then
          echo "All jobs done, email lab.";
          break;
      else
	  sleep $SLEEPTIME;
      fi
  done

  
  JOBCOUNT=$(cat $PROCESSINGPATH/job_output/RunProcessing_job_list_* | awk '{print $2}' | sort -u | wc -l);
  DONECOUNT=$(ls $PROCESSINGPATH/job_output/*/*.done | grep -v -E '1.done|2.done|3.done|4.done'  2>/dev/null | wc -l);
  
  # . ./make_job_output_table_generic.sh; makejobtable $PROCESSINGPATH RunProcessing_job_list $PROCESSINGPATH  
  cp -v $PROCESSINGPATH/$RUNDIR-run.html $ROBOTDIRROOT/processing/$INSTRUMENT_TYPE/$STARTDATE/$RUNDIR/;
  
  mkdir -p $ROBOTDIRROOT/processing/hiseq/runtracking/multiqcrunreports-$INSTRUMENT_TYPE/
  
  module load mugqic_dev/MultiQC_C3G/1.12_beta;
  multiqc $PROCESSINGPATH --template c3g --runprocessing --interactive --title $RUNDIR;
  cp ${RUNDIR}_multiqc_report.html $PROCESSINGPATH/;
  cp ${RUNDIR}_multiqc_report.html $ROBOTDIRROOT/processing/hiseq/runtracking/multiqcrunreports-$INSTRUMENT_TYPE/;
  mv ${RUNDIR}_multiqc_report.html $ROBOTDIRROOT/processing/$INSTRUMENT_TYPE/$STARTDATE/$RUNDIR/;  
  mv ${RUNDIR}_multiqc_report_data $ROBOTDIRROOT/processing/$INSTRUMENT_TYPE/$STARTDATE/$RUNDIR/;  
  
  METRICSCSV=$(
  for lane in 1 2 3 4; do
    for jsonstats in $PROCESSINGPATH/report/*.$lane.run_validation_report.json; do
	  cat $jsonstats | grep -E "project|sample\"|Barcode\"|pct_of_the_lane|\"pf_clusters|avg_qual|duplicate_rate|nb_bases|1st_hit" \
        | sed -e 's/^ *//' | tr -d ' ",' | sed 's/project:/project: |/g' | awk -F':' '{print $2","}' \
        | tr -d '\n' | tr '|' '\n' | awk -F',' '{print "'$lane',"$0}' | tail -n+2;
    done | rev | cut -c 2- | rev;
  done | sort );
  METRICSCSVHEADER=$(for lane in 1; do
  for jsonstats in $PROCESSINGPATH/report/*.$lane.run_validation_report.json; do
    cat $jsonstats | grep -E "project|sample\"|Barcode\"|pct_of_the_lane|\"pf_clusters|avg_qual|duplicate_rate|nb_bases|1st_hit" \
      | sed -e 's/^ *//' | tr -d ' ",' | sed 's/project:/|project: /g'| awk -F':' '{print $1","}' \
      | tr -d '\n' | tr '|' '\n' | tail -n+2 | head -n 1 | awk -F',' '{print "Lane,"$0}';
    done | rev | cut -c 2- | rev;
  done);
  
HTML=$(cat <<EOF
<html><head><title>$RUNDIR</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }
table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }
table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }
body {font-family: Arial;}
</style>
</head>
<body>
<h2>$RUNDIR</h2>
${TESTMSG}This is an automated message sent from the run processing event monitor.<br>
Run processing has completed for run $RUNDIR.<br>
Run processing job details are in the job_status file attached.<br>
<table border="1" class="style2">
$(echo "$METRICSCSVHEADER" | tr '_' ' ' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|,|</th><th>|g')
$(echo "$METRICSCSV" | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%i\t%s\t%s\t%s\t%0.2f\t%'"'"'i\t%0.2f\t%0.2f\t%'"'"'i\t%s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' | \
                      awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g')
</table>
EOF
);

( 
echo "To: $(echo "$EMAIL_LIST_UPDATE")"
echo "Reply-To: hercules@mcgill.ca"
echo "MIME-Version: 1.0"
echo "Subject: ${TESTMSG}Run processing complete for $RUNDIR with $DONECOUNT/$JOBCOUNT jobs complete."
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
echo '---q1w2e3r4t5'
for lane in 1 2 3 4; do
  f=$(ls $PROCESSINGPATH/Unaligned.$lane/raw_fastq/*.summaryReport.html)
  echo "Content-Type: text/html; name=$(basename $f)"
  echo 'Content-Transfer-Encoding: base64'
  echo "Content-Disposition: attachment; filename=$(basename $f)"
  echo
  base64 "$f"
  echo '---q1w2e3r4t5'
done
f=$PROCESSINGPATH/$RUNDIR-run.html
echo "Content-Type: text/html; name=job-status_$(basename $f)"
echo 'Content-Transfer-Encoding: base64'
echo "Content-Disposition: attachment; filename=job-status_$(basename $f)"
echo
base64 "$f"
echo '---q1w2e3r4t5--'
) | sendmail -t -f bravo.genome@mcgill.ca

  fi # processing failed

elif [ "$INSTRUMENT_TYPE" == "dnbseqt7" ]; then

  ############################################
  ############################################
  ##  __  __  _____ _____   _______ ______  ##
  ## |  \/  |/ ____|_   _| |__   __|____  | ##
  ## | \  / | |  __  | |      | |      / /  ##
  ## | |\/| | | |_ | | |      | |     / /   ##
  ## | |  | | |__| |_| |_     | |    / /    ##
  ## |_|  |_|\_____|_____|    |_|   /_/     ##
  ##                                        ##
  ##MGI T7####################################
  ############################################
  
  :
  
  
  
  
  
  
  
  

elif [ "$INSTRUMENT_TYPE" == "iSeq" ] || [ "$INSTRUMENT_TYPE" == "miseq" ] || [ "$INSTRUMENT_TYPE" == "hiseqx" ] || [[ "$INSTRUMENT_TYPE" == novaseq* ]];  then

  ###############################################
  ###############################################
  ##  _____ _ _                 _              ##
  ## |_   _| | |               (_)             ##
  ##   | | | | |_   _ _ __ ___  _ _ __   __ _  ##
  ##   | | | | | | | | '_ ` _ \| | '_ \ / _` | ##
  ##  _| |_| | | |_| | | | | | | | | | | (_| | ##
  ## |_____|_|_|\__,_|_| |_| |_|_|_| |_|\__,_| ##
  ##                                           ##
  ##ILLUMINA#####################################
  ###############################################
  
  ############################################
  # Now wait for RTAComplete.txt
  # when present startjob
  # otherwise check if sequencer is writing to network
  while(true); do
    
    if [ -f "$FLOWCELLDIR/RTAComplete.txt" ]; then
      echo "$FLOWCELLDIR/RTAComplete.txt was found, continue.";
      break;
    elif [ -f "$FLOWCELLDIR/CopyComplete.txt" ]; then
      echo "$FLOWCELLDIR/CopyComplete.txt was found, continue.";
      break;   
    else
      CURRENT_TIME=$(date +%s);
      LASTLOG=$(ls -rt $FLOWCELLDIR/Logs/*.log 2> /dev/null | tail -n 1);
      if [ -f "$LASTLOG" ]; then
        LASTLOG_TIME=$(stat --printf="%X" $LASTLOG);
        value=$(($CURRENT_TIME-$LASTLOG_TIME))
        abs_value=${value#-};
        if [ "$abs_value" -gt "$NETCOPYTIME" ]; then
            # problem: sequencer taking too long to update
            if [ ! -f "$(dirname $EVENTFILE)/network_issue_detected.flag" ]; then
               touch $(dirname $EVENTFILE)/network_issue_detected.flag
               MSG=$(printf "${TESTMSG}Issue with $INSTRUMENT_TYPE $INSTRUMENT_NAME with run $(basename $FLOWCELLDIR), please check instrument.\n\nFull path: $FLOWCELLDIR\n\nit.genome@mail.mcgill.ca has been contacted.\n\nThis is an automated message sent from the run processing monitor. Another email will be sent if writing resumes.");
               # email and alert of issue
               echo "$MSG" | mailx -s "${TESTMSG}Issue with $INSTRUMENT_TYPE $INSTRUMENT_NAME with run $(basename $FLOWCELLDIR), please check instrument."  -r "bravo.genome@mcgill.ca" $EMAIL_LIST_ALERT;
            fi
            echo "Time since netcopy update (seconds>$NETCOPYTIME: delay too long): $abs_value" >> $(dirname $EVENTFILE)/network_issue_detected.log
        else
            if [ -f "$(dirname $EVENTFILE)/network_issue_detected.flag" ]; then
              # problem seems to have resolved
              rm $(dirname $EVENTFILE)/network_issue_detected.flag
              MSG=$(printf "${TESTMSG}Issue is resolved for $INSTRUMENT_TYPE $INSTRUMENT_NAME with run $(basename $FLOWCELLDIR).\n\nFull path: $FLOWCELLDIR\n\nit.genome@mail.mcgill.ca has been updated.\n\nThis is an automated message sent from the run processing monitor.");
              # email that issue seems resolved
              echo "$MSG" | mailx -s "${TESTMSG}Issue is resolved for $INSTRUMENT_TYPE $INSTRUMENT_NAME with run $(basename $FLOWCELLDIR)"  -r "bravo.genome@mcgill.ca" $EMAIL_LIST_ALERT;
              echo "Time since netcopy update (seconds<=$NETCOPYTIME: delay ok): $abs_value" >> $(dirname $EVENTFILE)/network_issue_detected.log
            fi
        fi
      fi
    fi
    
    sleep $SLEEPTIME;
    
  done;

  ############################################
  # start pipeline
  #
  . ./processingpipeline.v5.sh prod;
  bootstrap $EVENTFILE;
  
  ############################################
  # Detect if RAPID_RESPONSE project are present
  # Monitor, copy and send email
  #  
  RUNDIR=$(basename $FLOWCELLDIR);
  PROJECT_LANE_PRESENT=$(tail -n+2 $EVENTFILE | grep -v "^$" | awk -F'\t' '{print $2 "\t" $3 "\t" $6}' | sed 's/:1//g' | sort -u | \
      grep -E "$(grep ^RAPID_RESPONSE ./email_config.csv | awk -F',' '{print $2}' | tr '\n' '|' | rev | cut -c 2- | rev)");
  
  PROCESSINGPATH=$(ls -d $SCRATCHDIRROOT/processing/$RUNDIR*);

  while(true); do
      BREAKOUT=true;
      for PROJ_LINE in $(echo "$PROJECT_LANE_PRESENT"); do
          PROJECTID=$(echo "$PROJ_LINE" | awk -F'\t' '{print $1}');
          PROJECTNAME=$(echo "$PROJ_LINE" | awk -F'\t' '{print $2}');
          LANE=$(echo "$PROJ_LINE" | awk -F'\t' '{print $3}');
          RAPID_RESPONSE_EMAILS=$(grep "$PROJECTID" ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');
          if [ "$OVERRIDEEMAIL" != "" ]; then
              RAPID_RESPONSE_EMAILS="$OVERRIDEEMAIL";
          fi
          FASTQDONE=$(ls $PROCESSINGPATH/job_output/fastq/fastq.*.$LANE.done 2>/dev/null);
          if [ -f "$FASTQDONE" ]; then
              d=$ROBOTDIRROOT/processing/rapidresponse/$PROJECTID/$(echo $RUNDIR | awk -F'_' '{print $2 "_" $3}')_$LANE;
              if [ ! -d "$d" ]; then
                  mkdir -p $d;
                  cp $PROCESSINGPATH/Unaligned.$LANE/Project_$PROJECTID/Sample*/*R[12]_001.fastq.gz $d/
                  
                  printf "Sample\tReadset\tLibraryType\tRunType\tRun\tLane\tAdapter1\tAdapter2\tQualityOffset\tBED\tFASTQ1\tFASTQ2\tBAM\n" > $d/$(echo $RUNDIR | awk -F'_' '{print $2 "_" $3}')_$LANE.readset.txt

		  while(true); do
		      f="$PROCESSINGPATH/$RUNDIR*-run.csv";
		      if [ -f $f ]; then 
			  break; 
		      fi;
                      sleep 1; 
		  done
		  sleep 1; 
		  
                  for line in $(cat $PROCESSINGPATH/$RUNDIR*-run.csv | grep "$PROJECTID" | awk -F',' '$3=='$LANE'{print $0}'); do
                      _SAMPLE_NAME=$(echo $line | awk -F, '{print $7}');
                      _LIB_TYPE=$(echo $line | awk -F, '{print $9}');
                      _LIB_ID=$(echo $line | awk -F, '{print $10}');
                      _LANE=$(echo $line | awk -F, '{print $3}');
                      _ADAPTER_1=$(echo $line | awk -F, '{print $28}');
                      _ADAPTER_2=$(echo $line | awk -F, '{print $29}');
                      _RUN_ID=$(echo $line | awk -F, '{print $2}');
                      _RUN_TYPE=$(echo $line | awk -F, '{print $4}');
                      _FQ1=$(ls $d/${_SAMPLE_NAME}_${_LIB_ID}_S*_L00${_LANE}_R1_001.fastq.gz)
                      _FQ2=$(ls $d/${_SAMPLE_NAME}_${_LIB_ID}_S*_L00${_LANE}_R2_001.fastq.gz)
                      # if [ -f "${_FQ1}" ] && [ -f "${_FQ2}" ]; then
                          printf "${_SAMPLE_NAME}\t${_SAMPLE_NAME}.${_LIB_ID}.${_RUN_ID}.${_LANE}\t${_LIB_TYPE}\t${_RUN_TYPE}\t${_RUN_ID}\t${_LANE}\t${_ADAPTER_1}\t${_ADAPTER_2}\t33\t\t${_FQ1}\t${_FQ2}\t\n" >> $d/$(echo $RUNDIR | awk -F'_' '{print $2 "_" $3}')_$LANE.readset.txt;
                      # fi
                  done
                  
                  # chmod 755 $ROBOTDIRROOT/processing/rapidresponse/$PROJECTID
                  # find $d -type d -exec chmod 755 {} \;
                  # find $d -type f -exec chmod 644 {} \;
                  b=$(echo "$PROJECT_LANE_PRESENT" | grep $PROJECTID | awk -F'\t' '$3!="'$LANE'"{print $1 " - "$2 " - " $3}');
                  if [ "$b" == "" ]; then b="None."; fi
                  c=$(ls -lh $d/*.gz | awk '{print $9 " (" $5")"}' | sed "s|$d/||g");
                  MSG=$(printf "${TESTMSG}This is an automated message sent from the run processing event monitor.\n\nRun $(basename $FLOWCELLDIR) contains rapid response datasets.\nProject ID: $PROJECTID, Project Name: $PROJECTNAME, Lane: $LANE.\n\n*** Fastq files are ready. ***\n*** Note that this data is not validated, wait for validation before releasing to clients. ***\n*** Expect one email per lane for this project as run completes and fastqs are generated. ***\n\nOther rapid response project lanes expected in this run:\nProject ID - Project Name - Lane\n$b\n\nData has been placed in this location:\n$d\nA readset file is attached to this email and is available here:\n$d/$(echo $RUNDIR | awk -F'_' '{print $2 "_" $3}')_$LANE.readset.txt\n\nFile sizes:\n$c");
                  echo "$MSG" | mailx -s "${TESTMSG}RAPID REPONSE Run $(basename $FLOWCELLDIR) Project ID: $PROJECTID, Project Name: $PROJECTNAME, Lane: $LANE." -a $d/$(echo $RUNDIR | awk -F'_' '{print $2 "_" $3}')_$LANE.readset.txt -r "bravo.genome@mcgill.ca" $RAPID_RESPONSE_EMAILS;
		          
              fi
          else
              BREAKOUT=false;
          fi
      done
      if($BREAKOUT); then
          break;
      fi
  done
  
  ############################################
  # wait for monitor job complete, email lab
  #
  RUNDIR=$(basename $FLOWCELLDIR);
  while(true); do
      PROCESSINGPATH=$(ls -d $SCRATCHDIRROOT/processing/$RUNDIR*);
      MONITORDONE=$(ls $PROCESSINGPATH/job_output/monitor/*.done 2>/dev/null);
      if [ -f "$MONITORDONE" ]; then
          echo "$MONITORDONE was found, email lab.";
      
          PNGPATH=$(ls $PROCESSINGPATH/*per_sample_read_yield.png 2>/dev/null)
          METRICSCSV=$(ls $PROCESSINGPATH/*-run.csv);
      
          JOBCOUNT=$(ls $PROCESSINGPATH/job_output/*/*.o 2>/dev/null | rev | cut -c 23- | rev | sort -u |  wc -l)
          DONECOUNT=$(ls $PROCESSINGPATH/job_output/*/*.done 2>/dev/null | wc -l)
      
HTML=$(cat <<EOF
<html><head><title>$RUNDIR</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table.style2 { border-collapse: collapse; border: 1px solid #A0A0A0; border-style: solid; font-size: 12px;}
table.style2 th { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
table.style2 td { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
body {font-family: Arial;}
</style>
</head>
<body>
<h2>$RUNDIR</h2>
${TESTMSG}This is an automated message sent from the run processing event monitor.<br>
Run processing has completed for run $RUNDIR with $DONECOUNT/$JOBCOUNT jobs complete.<br>
<h2>Read count per sample</h2>
<img src="data:image/png;base64,$(base64 $PNGPATH)">
<h2>Run Metrics</h2>
<table border="1" class="style2">
$(cat $METRICSCSV | cut -d "," -f 2-20 | head -n 1 | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|,|</th><th>|g')
$(cat $METRICSCSV | cut -d "," -f 2-20 | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|,|</td><td>|g')
</table>
EOF
);

      SILENCEEMAIL=$(ls $PROCESSINGPATH/silence.email);
      if [ -f "$SILENCEEMAIL" ]; then
          EMAIL_LIST_UPDATE=$(cat <<EOF
"Haig Hugo Vrej Djambazian, Mr" <haig.djambazian@mcgill.ca>
EOF
);
      fi

(  
echo "To: $(echo "$EMAIL_LIST_UPDATE")"
echo "Reply-To: hercules@mcgill.ca"
echo "MIME-Version: 1.0"
echo "Subject: ${TESTMSG}Run processing complete for $RUNDIR with $DONECOUNT/$JOBCOUNT jobs complete"
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
echo
) | sendmail -t -f bravo.genome@mcgill.ca

          break;
      fi

  done

else

  ##############################
  ##############################
  ##    ____  _   _ _______   ## 
  ##   / __ \| \ | |__   __|  ##
  ##  | |  | |  \| |  | |     ##
  ##  | |  | | . ` |  | |     ##
  ##  | |__| | |\  |  | |     ##
  ##   \____/|_| \_|  |_|     ##
  ##                          ##
  ##ONT#########################
  ##############################
  
  ############################################
  # Detect that the run demultiplexing has completed
  #

  FLOWCELLDIRSECONDARY=$(echo "$FLOWCELLDIR" | sed "s|$RUNDIRROOTONT|$ROBOTDIRROOT|g")

  while(true); do
      FINALSUMMARYPATH=$(ls $FLOWCELLDIRSECONDARY/final_summary_*.txt 2>/dev/null )
      if [ -f "$FINALSUMMARYPATH" ]; then
          echo "$FINALSUMMARYPATH was found, continue.";
	  break;
      fi
      sleep $SLEEPTIME;
  done
  
  while(true); do
      SEQSUMMARYPATH=$(ls $FLOWCELLDIRSECONDARY/sequencing_summary_*.txt 2>/dev/null )
      if [ -f "$SEQSUMMARYPATH" ]; then
          echo "$SEQSUMMARYPATH was found, continue.";
	  break
      fi
      sleep $SLEEPTIME;
  done;
  
  ############################################
  # Start the covseq pipeline
  #
  
  ONTCOVID_EMAILS=$(grep "ONTCOVID" ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');
  if [ "$OVERRIDEEMAIL" != "" ]; then
      ONTCOVID_EMAILS="$OVERRIDEEMAIL";
  fi
  
  RUNNAME=$(basename $(dirname $(ls -d $FLOWCELLDIR)));
  FCVERSION=$(grep 'protocol=sequencing' $FINALSUMMARYPATH);  
  ISBASECALLON=$(grep -c 'basecalling_enabled=1' $FINALSUMMARYPATH)
  echo "$FINALSUMMARYPATH"; grep 'basecalling_enabled=1' $FINALSUMMARYPATH;
  FASTQPATH=$(ls -d $FLOWCELLDIRSECONDARY/fastq_pass 2>/dev/null);
  if [ "$ISBASECALLON" == "0" ]; then
      FASTQPATH="";
      SEQSUMMARYPATH="";
  fi
  FAST5PATH=$(ls -d $FLOWCELLDIR/fast5  2>/dev/null);
  if [ ! -d "$FAST5PATH" ]; then
      FAST5PATH=$(ls -d $FLOWCELLDIR/fast5_pass);
  fi
  
  READSETMAIN=$(dirname $EVENTFILE)/$FCID_CLARITY.readset.txt
  
  # Build the readset file
#  ( printf "Sample\tReadset\tRun\tFlowcell\tLibrary\tSummary\tFASTQ\tFAST5\tBarcode\tAnalysisName\n";
#    tail -n+2 $EVENTFILE | \
#      grep "Viruses:Severe acute respiratory syndrome coronavirus 2 (Taxon ID:2697049)" | \
#      awk -F '\t' '{ if ($30 == "N/A") $30="Native Barcoding 1-96 (EXP-NBD196)/Ligation Sequencing kit (SQK-LSK109)"; split($5,FCID,"_"); gsub(/ /,"_",$9); gsub(/ /,"_",$30); print $13 "\t" $13 "." $8 "." FCID[4] "_" FCID[5] "\t" FCID[4] "_" FCID[5] "\t" "\"'$FCVERSION'\"" "\t" "\""$9":"$30"\"" "\t" "'$SEQSUMMARYPATH'" "\t" "'$FASTQPATH'" "\t" "'$FAST5PATH'" "\t" "barcode" substr($7,length($7)-1,length($7)) "\t" "'$RUNNAME'."$5 "." $2}';
#  ) > $READSETMAIN

  ( printf "Sample\tReadset\tRun\tFlowcell\tLibrary\tSummary\tFASTQ\tFAST5\tBarcode\tAnalysisName\n";
    tail -n+2 $EVENTFILE | \
      grep "Viruses:Severe acute respiratory syndrome coronavirus 2 (Taxon ID:2697049)" | \
      awk -F '\t' '{ $30="Native Barcoding 1-96 (EXP-NBD196)/Ligation Sequencing kit (SQK-LSK109)"; split($5,FCID,"_"); gsub(/ /,"_",$9); gsub(/ /,"_",$30); print $13 "\t" $13 "." $8 "." FCID[4] "_" FCID[5] "\t" FCID[4] "_" FCID[5] "\t" "\"'$FCVERSION'\"" "\t" "\"" $9 ":" $30 "\"" "\t" "'$SEQSUMMARYPATH'" "\t" "'$FASTQPATH'" "\t" "'$FAST5PATH'" "\t" "barcode" substr($7,length($7)-1,length($7)) "\t" "'$RUNNAME'."$5 "." $2 "." $37}';
  ) > $READSETMAIN
   
  for line in $(tail -n+2 pcr_kit_name_lookup.txt | tac); do
    PCRKITNAME=$(echo $line | awk -F'\t' '{print $1}');
    PRIMERNAMECLEAN=$(echo $line | awk -F'\t' '{print $2}');
    PRIMERINI=$(echo $line | awk -F'\t' '{print $3}');    
    cat $READSETMAIN | sed "s|$PCRKITNAME|$PRIMERNAMECLEAN|g" > $READSETMAIN.tmp;
    mv $READSETMAIN.tmp $READSETMAIN;
  done

  NUMBATCH=$(tail -n +2 $READSETMAIN | awk -F'\t' '{print $10}' | sort -u | wc -l);
  
  if [ "$NUMBATCH" == "0" ]; then
      echo "No samples left to run in event file."
      return;
  fi
  
  for ANALYSISNAME in $(tail -n +2 $READSETMAIN | awk -F'\t' '{print $10}' | sort -u); do
      FLOWCELLNAME=$(echo "$ANALYSISNAME" | awk -F'.' '{print $1}')
      PROJECTID=$(echo "$ANALYSISNAME" | awk -F'.' '{print $3}')
      # PRIMERVERSION=$(echo "$ANALYSISNAME" | awk -F'.' '{print $3}')
      PRIMERVERSION=$(echo "$ANALYSISNAME" | awk -F'.' '{OFS="."; $1=""; $2=""; $3=""; print $0}' | cut -c 4-);
      # (head -n 1 $READSETMAIN; grep $ANALYSISNAME $READSETMAIN) > $(dirname $EVENTFILE)/$ANALYSISNAME.readset.txt
      (head -n 1 $READSETMAIN; awk -F'\t' '$10=="'$ANALYSISNAME'"{print $0}' $READSETMAIN) > $(dirname $EVENTFILE)/$ANALYSISNAME.readset.txt
      
      if [ "$USER" == "bravolims" ]; then
          RAPID_RESPONSE_QOS=$(grep "$PROJECTID" ./email_config.csv | awk -F',' '{print $5}');
          if [ "$RAPID_RESPONSE_QOS" != "" ]; then   
              QOSOVERRIDE="cluster_other_arg=-W umask=0002 -l qos=$RAPID_RESPONSE_QOS";
          else
              QOSOVERRIDE="cluster_other_arg=-W umask=0002 -l qos=research";
          fi
      fi
      
      MUGQIC_PIPELINES_HOME=/home/$USER/ontcovidrunprocessing/genpipes;
      
      export MUGQIC_INSTALL_HOME_DEV=/lb/project/mugqic/analyste_dev
      module use $MUGQIC_INSTALL_HOME_DEV/modulefiles
      
      PROCESSINGPATH=$SCRATCHDIRROOTCOVIDONT/$ANALYSISNAME-ontcovidseq

      if [ "$ISBASECALLON" == "1" ]; then
	  # WITH NO basecalling since DONE on the sequencer
	  BASECALLING="default"
      else
	  # WITH basecalling since NOT DONE on the sequencer
	  BASECALLING="basecalling"
      fi
      
      echo -e "[DEFAULT]" > $(dirname $EVENTFILE)/$ANALYSISNAME.run_name.ini
      echo -e "run_name=\"$ANALYSISNAME\"" >> $(dirname $EVENTFILE)/$ANALYSISNAME.run_name.ini
      echo -e "$QOSOVERRIDE" >> $(dirname $EVENTFILE)/$ANALYSISNAME.run_name.ini
      
      if [ "$PRIMERVERSION" == "ARTIC_v3" ]; then
          PRIMER_INI="";
      else
          PRIMER_INI=$MUGQIC_PIPELINES_HOME/pipelines/nanopore_covseq/$(awk -F'\t' '$2=="'$PRIMERVERSION'"{print $3}' pcr_kit_name_lookup.txt | head -n 1);
      fi
      
      echo "calling nanopore_covseq.py with -t $BASECALLING"

      # call genpipes
      module load mugqic/python/3.9.1 && \
      mkdir -p $PROCESSINGPATH && \
      python $MUGQIC_PIPELINES_HOME/pipelines/nanopore_covseq/nanopore_covseq.py \
        -c $MUGQIC_PIPELINES_HOME/pipelines/nanopore_covseq/nanopore_covseq.base.ini $EXTRA_INI_COVIDONT $(dirname $EVENTFILE)/$ANALYSISNAME.run_name.ini $PRIMER_INI \
        --force_mem_per_cpu 5000 \
        --no-json \
        -j pbs \
        -r $(dirname $EVENTFILE)/$ANALYSISNAME.readset.txt \
        -t $BASECALLING \
        -o $PROCESSINGPATH \
	  > $(dirname $EVENTFILE)/$ANALYSISNAME.sh \
	  2> $(dirname $EVENTFILE)/$ANALYSISNAME.trace.log
      
      mv $(ls -rt NanoporeCoVSeq.*.config.trace.ini | tail -n 1) $(dirname $EVENTFILE)/$ANALYSISNAME.NanoporeCoVSeq.config.trace.ini
      
      cp $(dirname $EVENTFILE)/$ANALYSISNAME.sh $PROCESSINGPATH/
      cp $(dirname $EVENTFILE)/$ANALYSISNAME.NanoporeCoVSeq.config.trace.ini $PROCESSINGPATH/
      
      # call shell script generated
      if [ "$(cat $(dirname $EVENTFILE)/$ANALYSISNAME.sh | wc -l)" == "0" ]; then
TRACE=$(dirname $EVENTFILE)/$ANALYSISNAME.trace.log
HTML=$(cat <<EOF
<html><head><title>Run processing has FAILED TO START for ONT run: $ANALYSISNAME</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table.style2 { border-collapse: collapse; border: 1px solid #A0A0A0; border-style: solid; font-size: 12px;}
table.style2 th { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
table.style2 td { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
body {font-family: Arial;}
div {white-space: pre-wrap;white-space:nowrap;}
</style>
</head>
<body>
${TESTMSG}This is an automated message sent from the run processing event monitor.<br>
Run processing has FAILED TO START for ONT run: $ANALYSISNAME.<br>
<h3>Content of trace:</h3>
$(cat $TRACE | awk '{print "<div>"$0"</div>"}' )
EOF
);

(echo "To: $(echo "$ONTCOVID_EMAILS")"
echo "Reply-To: hercules@mcgill.ca"
echo "MIME-Version: 1.0"
echo "Subject: ${TESTMSG}Run processing has FAILED TO START for ONT run: $ANALYSISNAME"
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
echo '---q1w2e3r4t5'
f=$(dirname $EVENTFILE)/$ANALYSISNAME.readset.txt
echo "Content-Type: text; name=$(basename $f)"
echo 'Content-Transfer-Encoding: base64'
echo "Content-Disposition: attachment; filename=$(basename $f)"
echo
base64 "$f"
echo '---q1w2e3r4t5--'
) | sendmail -t -f bravo.genome@mcgill.ca;
      else
          sh $(dirname $EVENTFILE)/$ANALYSISNAME.sh

HTML=$(cat <<EOF
<html><head><title>Run processing has started for ONT run: $ANALYSISNAME</title>
</head>
<body>
${TESTMSG}This is an automated message sent from the run processing event monitor.<br>
Run processing has started for ONT run: $ANALYSISNAME. The readset used is attached (use with option -t $BASECALLING).<br>
EOF
);
(echo "To: $(echo "$ONTCOVID_EMAILS")"
echo "Reply-To: hercules@mcgill.ca"
echo "MIME-Version: 1.0"
echo "Subject: ${TESTMSG}Run processing has started for ONT run: $ANALYSISNAME"
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
echo '---q1w2e3r4t5'
f=$(dirname $EVENTFILE)/$ANALYSISNAME.readset.txt
echo "Content-Type: text; name=$(basename $f)"
echo 'Content-Transfer-Encoding: base64'
echo "Content-Disposition: attachment; filename=$(basename $f)"
echo
base64 "$f"
echo '---q1w2e3r4t5--'
) | sendmail -t -f bravo.genome@mcgill.ca;

      fi
  done
  
  #################################################
  # wait for ont-covseq pipeline to complete
  #
  while(true); do
    CNT=0;
    for ANALYSISNAME in $(tail -n +2 $READSETMAIN | awk -F'\t' '{print $10}' | sort -u); do
      if [ "$(cat $(dirname $EVENTFILE)/$ANALYSISNAME.sh | wc -l)" == "0" ]; then
        let CNT=$CNT+1;
        continue;
      fi
      FLOWCELLNAME=$(echo "$ANALYSISNAME" | awk -F'.' '{print $1}');
      PROCESSINGPATH=$SCRATCHDIRROOTCOVIDONT/$ANALYSISNAME-ontcovidseq;
      JOBDATE=$(ls $PROCESSINGPATH/job_output/*_job_list_* 2>/dev/null | awk -F'_job_list_' '{print $2}' | tail -n 1);
      qstat | tail -n+3 | awk '$5!="C"{print $1}' | awk -F'.' '{print $1}' | sort > $(dirname $EVENTFILE)/inscheduler.txt;
      cat $PROCESSINGPATH/job_output/*_job_list_$JOBDATE | awk -F'.' '{print $1}' | sort > $(dirname $EVENTFILE)/inpipeline.txt;
      JOBDONECOUNT=$(comm -12 $(dirname $EVENTFILE)/inscheduler.txt $(dirname $EVENTFILE)/inpipeline.txt | wc -l);
      if [ "$JOBDONECOUNT" == "0" ]; then
        let CNT=$CNT+1;
      fi
      
      . ./make_job_output_table_generic.sh; makejobtable $PROCESSINGPATH NanoporeCoVSeq_job_list $PROCESSINGPATH;
      cp -v $PROCESSINGPATH/$ANALYSISNAME-ontcovidseq-run.html $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-ontcovidseq/;

    done
    if [ "$CNT" == "$NUMBATCH" ]; then
      echo "All batches have completed."
      break;
    fi
    sleep $SLEEPTIME;
  done
  
  ##############################
  # Email Rapid Response team
  #
  for ANALYSISNAME in $(tail -n +2 $READSETMAIN | awk -F'\t' '{print $10}' | sort -u); do
    if [ "$(cat $(dirname $EVENTFILE)/$ANALYSISNAME.sh | wc -l)" == "0" ]; then
      echo "Processing has failed for $ANALYSISNAME, don't send final email.";
      continue;
    fi
    
    FLOWCELLNAME=$(echo "$ANALYSISNAME" | awk -F'.' '{print $1}');
    PROJECTID=$(echo "$ANALYSISNAME" | awk -F'.' '{print $3}' | awk -F'-' '{print $1}');
    PROCESSINGPATH=$SCRATCHDIRROOTCOVIDONT/$ANALYSISNAME-ontcovidseq;
    FINALPATH=$ROBOTDIRROOT/processing/ont/ontcovidseq/$PROJECTID/$(echo "$FCID_CLARITY" | cut -c 1-4)/;
    
    JOBCOUNT=$(cat $PROCESSINGPATH/job_output/NanoporeCoVSeq_job_list_* | awk '{print $2}' | sort -u | wc -l);
    DONECOUNT=$(ls $PROCESSINGPATH/job_output/*/*.done 2>/dev/null | wc -l);
    
    # . ./make_job_output_table_generic.sh; makejobtable $PROCESSINGPATH Nanopore_job_list $PROCESSINGPATH;
    
    echo -n "Making final copy ... "
    mkdir -p $FINALPATH
    cp $(dirname $EVENTFILE)/$ANALYSISNAME.readset.txt $PROCESSINGPATH/;
    mv $PROCESSINGPATH $FINALPATH/;
    
    echo "done."
    
    for f in $(find -L $FINALPATH/$ANALYSISNAME-ontcovidseq -xtype l); do stat $f | grep '  File: ' | sed 's/’ -> ‘/ /g' | sed 's/  File: //g' | tr -d '‘’' \
	| sed "s|$SCRATCHDIRROOTCOVIDONT|$FINALPATH|g" | awk '{print "ln -sf "$2 " " $1}';
    done | sh

    . ./covid_nanopore_illum_qc_report.sh; runreport $FINALPATH/$ANALYSISNAME-ontcovidseq;
    
    REPORTTSV="$FINALPATH/$ANALYSISNAME-ontcovidseq/report/ncov_tools/qc_reports/${ANALYSISNAME}_summary_qc.tsv"

    echo "Send final email."
    
    ( 
        cat $FINALPATH/$ANALYSISNAME-ontcovidseq/agt_labqc_report/$ANALYSISNAME-ontcovidseq_lab_qc_report.html \
            | sed -n '/<body/q;p';
        echo "<body>";
	echo "${TESTMSG}This is an automated message sent from the run processing event monitor.<br>"
        cat $FINALPATH/$ANALYSISNAME-ontcovidseq/agt_labqc_report/$ANALYSISNAME-ontcovidseq_lab_qc_report.html \
            | sed '0,/General information/d' \
            | sed '/General information/,$!d' \
            | sed -n '/Pipeline information/q;p';
	echo "</pre>"
        cat $FINALPATH/$ANALYSISNAME-ontcovidseq/agt_labqc_report/$ANALYSISNAME-ontcovidseq_lab_qc_report.html \
            | sed '0,/Status tables/d' \
            | sed '/Status tables/,$!d' \
            | sed -n '/Run validation file/q;p' \
            | sed "s/popBase64('.*'/popBase64(''/";
        echo "</body></html>";
    ) > /tmp/$ANALYSISNAME-ontcovidseq_lab_qc_report_onlytables.html
    
    HTML=$(cat /tmp/$ANALYSISNAME-ontcovidseq_lab_qc_report_onlytables.html)
    
    ( 
        echo "To: $(echo "$ONTCOVID_EMAILS")"
        # echo "Reply-To: hercules@mcgill.ca"
        echo "MIME-Version: 1.0"
        echo "Subject: Secondary analysis complete for Nanopore run: $ANALYSISNAME-ontcovidseq"
        echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
        echo
        echo '---q1w2e3r4t5'
        echo "Content-Type: text/html"
        echo
        echo "$HTML"
        echo '---q1w2e3r4t5'
        echo
        f=$FINALPATH/$ANALYSISNAME-ontcovidseq/agt_labqc_report/$ANALYSISNAME-ontcovidseq_lab_qc_report_onlycontrols.html
        echo "Content-Type: text/html; name=$(basename $f)"
        echo 'Content-Transfer-Encoding: base64'
        echo "Content-Disposition: attachment; filename=$(basename $f)"
        echo
        base64 "$f"
        
    ) | sendmail -t -f bravo.genome@mcgill.ca;
                
    rm  /tmp/$ANALYSISNAME-ontcovidseq_lab_qc_report_onlytables.html
    
    
  done

fi
  
}



function event_service {

mkdir -p $EVENTSDIR/system;

LOG=$EVENTSDIR/system/event.log;

echo "event_service started - $(date)" >> $LOG

MASTERLIST=$EVENTSDIR/system/masterlist.txt;

touch $MASTERLIST;

while (true); do

  for EVENT in $EVENTSDIR/*.txt; do
    
    if [ ! -f "$EVENT" ]; then
        break;
    fi
    
    echo -n "found event: $(basename $EVENT)... " >> $LOG
    
    sleep $EVENTDELAY
    
    YEAR=$(date +"%Y");
    DATESTAMP=$(date +%F-T%H.%M.%S);
    
    # check if already present in masterlist
    if grep "$(basename $EVENT)" $MASTERLIST > /dev/null; then
      echo "Old event -> ignore." >> $LOG
      mkdir -p $EVENTSDIR/system/$YEAR/$DATESTAMP-invalid
      INVALID_EVENT=$EVENTSDIR/system/$YEAR/$DATESTAMP-invalid/$(basename $EVENT);
      mv $EVENT $INVALID_EVENT;
      
    else
      echo "New event -> start job." >> $LOG
      mkdir -p $EVENTSDIR/system/$YEAR/$DATESTAMP-valid
      VALID_EVENT=$EVENTSDIR/system/$YEAR/$DATESTAMP-valid/$(basename $EVENT);
      mv $EVENT $VALID_EVENT;
      
      # record event
      echo "$(basename $EVENT)" >> $MASTERLIST;
      
      # startjob
      JOB_OUTPUT=$EVENTSDIR/system/$YEAR/$DATESTAMP-valid/$DATESTAMP.run_processing.o;
      
      run_processing $VALID_EVENT > $JOB_OUTPUT &
      echo "Run end monitor process ID: "$! >> $LOG
      
    fi
    
  done
  
  ############################
  # secondary analysis events
  
  # ...

  sleep $SLEEPTIME;

done

}


if [ "$1" == "start" ]; then
  PIDPRESENT="1"
  if [ -f "event-monitor.lock" ]; then
     kill -0 $(cat event-monitor.lock);
     PIDPRESENT="$?"; # Killable
  fi
  if [ "$PIDPRESENT" == "0" ]; then
      echo "Cannot start event monitor, already running (PID:$(cat event-monitor.lock | tr -d '\n'))"
  else
      screen -S event-monitor -dm bash -c "$(printf "bash event_service.sh run &\n echo \$!> event-monitor.lock;\n exec sh;\n")"
      sleep 1
      echo "Started event monitor, created event-monitor.lock (PID:$(cat event-monitor.lock | tr -d '\n'))"     
  fi
fi

if [ "$1" == "stop" ]; then
  PIDPRESENT="1"
  if [ -f "event-monitor.lock" ]; then
     kill -0 $(cat event-monitor.lock);
     PIDPRESENT="$?"; # Killable
  fi
  if [ "$PIDPRESENT" == "0" ]; then
      kill -9 $(cat event-monitor.lock);
      screen -X -S event-monitor quit
      echo "Stopped event monitor (PID:$(cat event-monitor.lock | tr -d '\n'))"
      rm event-monitor.lock
  else
      echo "Cannot stop event monitor, already stopped (PID:$(cat event-monitor.lock | tr -d '\n'))"
  fi
fi

if [ "$1" == "run" ]; then
    event_service
fi

