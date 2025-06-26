#!/bin/bash

IFS=$'\n'

# ./run_illumcovidanalysis.sh &

#  v=/lb/robot/research/processing/events/system/2022/2022-11-11-T10.50.46-valid; grep -v $v /lb/robot/research/processing/events/system/illumcovidanalysis.seen > tmp; mv tmp  /lb/robot/research/processing/events/system/illumcovidanalysis.seen

SCRATCHDIRROOTCOVIDILLUM=/nb/Research/illumcovidanalysis_scratch;
ROBOTDIRROOT=/lb/robot/research;
RUNDIRROOT=/nb/Research;

FILT="";

RUN_DROP_LIST="$RUNDIRROOT/Miseq,$RUNDIRROOT/hiseqX,$RUNDIRROOT/Novaseq,$RUNDIRROOT/iSeq/RUNS,$RUNDIRROOT/iSeq/RUNS/atlasfs/researchISeq/RUNS,$RUNDIRROOT/MGISeq/seq1/R2130400190016,$RUNDIRROOT/MGISeq/seq2/R2130400190018,$RUNDIRROOT/MGISeq/T7/R1100600200054/upload/workspace,$RUNDIRROOTONT/promethion/*/*,$RUNDIRROOTONT/minion/*/*,$RUNDIRROOTONT/gridion/*/*"

SLEEPTIME=600;

# monitor event files, find the ones with ViruSeq
# ls -d $ROBOTDIRROOT/processing/events/system/*/*valid >  $ROBOTDIRROOT/processing/events/illumcovidanalysis.seen
# 

while(true); do

    instrument_list=$(cat instrument_list.csv)
    if [ "$(ls -d $ROBOTDIRROOT/processing/events/system/*/*valid | wc -l)" -eq "0" ]; then
	sleep $SLEEPTIME
	continue;
    fi
    if [ ! -f "$ROBOTDIRROOT/processing/events/system/illumcovidanalysis.seen" ]; then
	sleep $SLEEPTIME
	continue;
    fi

    for eventdir  in $(comm -23 <( ls -d $ROBOTDIRROOT/processing/events/system/*/*valid | sort ) <(cat $ROBOTDIRROOT/processing/events/system/illumcovidanalysis.seen | sort )); do
	echo "$eventdir" >> $ROBOTDIRROOT/processing/events/system/illumcovidanalysis.seen;
	_EVENTFILE=$(ls $eventdir/*samples*)
	N=$(grep -c 'Viruses:Severe acute respiratory syndrome coronavirus 2 (Taxon ID:2697049)' $_EVENTFILE)
	if [ "$N" -gt "0" ]; then
	    echo $_EVENTFILE;
	    YEAR=$(tail -n +2 $_EVENTFILE | grep -v "^$" | awk -F'\t' '{print $15}' | head -n 1 | cut -c 1-4)
	    FCID_CLARITY=$(tail -n+2 $_EVENTFILE | awk -F '\t' '{print $5}' | grep -v "^$" | sort -u);
	    
	    #######################################
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
	    
	    if [ "$INSTRUMENT_TYPE" == "novaseq" ] || [ "$INSTRUMENT_TYPE" == "miseq" ] || [ "$INSTRUMENT_TYPE" == "iSeq" ]; then
		:
	    else
		continue;
	    fi
	    
	    #######################################
	    RUNNAME=$(basename $FLOWCELLDIR);
	    while(true); do
		PROCESSINGPATH=$(ls -d $RUNDIRROOT/processing/$RUNNAME*);
		if [ -d "$PROCESSINGPATH" ]; then
		    break
		fi
		sleep $SLEEPTIME;
	    done
	    

	    #######################################
	    while(true); do
		foundall=true;
		for LANE in $(ls -d  $FLOWCELLDIR/Data/Intensities/BaseCalls/L00* | rev | cut -c 1); do
		    FASTQDONE=$(ls $PROCESSINGPATH/job_output/fastq/fastq.*.$LANE.done 2>/dev/null);
		    if [ ! -f "$FASTQDONE" ]; then
			foundall=false;
		    fi		    
		done
		if($foundall); then
		    break
		fi
		sleep $SLEEPTIME;
	    done
	    

	    #######################################
	    

	    for PROJECTID in $(grep 'Viruses:Severe acute respiratory syndrome coronavirus 2 (Taxon ID:2697049)' $_EVENTFILE | awk -F'\t' '{print $2}'  | sort -u); do
		
		ANALYSISNAME=$RUNNAME.$PROJECTID.ARTIC_v4_1;
		ANALYSISPATH=$SCRATCHDIRROOTCOVIDILLUM/$ANALYSISNAME-illumcovidseq;
		FINALPATH=$ROBOTDIRROOT/processing/secondary/illumcovidseq/$PROJECTID/$YEAR;
		
		if [ -d "$FINALPATH/$ANALYSISNAME-illumcovidseq" ]; then
		    echo "covseq.py processing already done"
		else
		    mkdir -p $ANALYSISPATH

		    if [ "$(ls /nb/Research/processing/$RUNNAME*/U*/P*/S*/*R1_001.fastq.gz 2>/dev/null | head -n 1 | wc -l)" == "1" ]; then
			echo "Using: /nb/Research/processing";
			FASTQROOT='/nb/Research/processing';
		    else
			echo "Using: /lb/robot/research/processing";
			FASTQROOT='/lb/robot/research/processing/*/*';
		    fi
		    
		    ( printf "Sample\tReadset\tLibraryType\tRunType\tRun\tLane\tAdapter1\tAdapter2\tQualityOffset\tBED\tFASTQ1\tFASTQ2\tBAM\n";
			for f in  $FASTQROOT/$RUNNAME*/Unaligned.*/Project_$PROJECTID/S*/*_R1_001.fastq.gz; do
			    libid=$(echo $(basename $f) | rev | awk -F'_' '{print $5}' | rev);
			    samplename=$(echo $(basename $f) | awk -F"_$libid" '{print $1}');
			    runid=$(echo $f | rev | awk -F'/' '{print $5}' | rev | awk -F'_' '{print $2"_"$3}'); 
			    lane=$(echo $f | rev | awk -F'/' '{print $4}' | cut -c 1);
			    echo -n $samplename; printf "\t"; 
			    echo -n $samplename.$libid.$runid.$lane; printf "\t"; 
			    echo -n "VirusSeq"; printf "\t"; 
			    echo -n "PAIRED_END"; printf "\t";
			    echo -n "$runid"; printf "\t";
			    echo -n "$lane"; printf "\t";
			    echo -n "CTGTCTCTTATACACATCTCCGAGCCCACGAGAC"; printf "\t";
			    echo -n "CTGTCTCTTATACACATCTGACGCTGCCGACGA"; printf "\t";
			    echo -n "33"; printf "\t";
			    echo -n ""; printf "\t"; # bed
			    echo -n $f; printf "\t"; 
			    echo -n $f | sed 's/_R1_001.fastq.gz/_R2_001.fastq.gz/g'; printf "\t"; 
			    echo;
			done ) > $ANALYSISPATH/$ANALYSISNAME-illumcovidseq.readset.txt
		    
		    echo "[prepare_report]" > $ANALYSISPATH/run_name.ini
		    echo "run_name=$ANALYSISNAME" >> $ANALYSISPATH/run_name.ini
		    echo "module_R=mugqic/R_Bioconductor/4.1.0_3.13" >> $ANALYSISPATH/run_name.ini
		    
		    MUGQIC_PIPELINES_HOME=/home/$USER/illumcovidanalysis/genpipes; # $(pwd)/genpipes
		    module load mugqic/python/3.9.1
		    
		    python $MUGQIC_PIPELINES_HOME/pipelines/covseq/covseq.py -c \
			$MUGQIC_PIPELINES_HOME/pipelines/covseq/covseq.base.ini \
			$MUGQIC_PIPELINES_HOME/pipelines/covseq/ARTIC_v4.1.ini \
			/home/$USER/illumcovidanalysis/illumcovidanalysis.base.ini \
			$ANALYSISPATH/run_name.ini \
			-o $ANALYSISPATH --no-json -j pbs -l debug --force_mem_per_cpu 5000 -r \
			$ANALYSISPATH/$ANALYSISNAME-illumcovidseq.readset.txt \
			> $ANALYSISPATH/$ANALYSISNAME-illumcovidseq.readset.txt.jobs.sh \
			2> $ANALYSISPATH/$ANALYSISNAME-illumcovidseq.readset.txt.trace.log;
		    
		    mv $(ls -rt CoVSeq.*.config.trace.ini | tail -n 1) $ANALYSISPATH/$ANALYSISNAME-illumcovidseq.CoVSeq.config.trace.ini
	
		    sh $ANALYSISPATH/$ANALYSISNAME-illumcovidseq.readset.txt.jobs.sh;
		    
		fi
	    done
	    
	    
	    for PROJECTID in $(grep 'Viruses:Severe acute respiratory syndrome coronavirus 2 (Taxon ID:2697049)' $_EVENTFILE | awk -F'\t' '{print $2}'  | sort -u); do
		
		ANALYSISNAME=$RUNNAME.$PROJECTID.ARTIC_v4_1;
		ANALYSISPATH=$SCRATCHDIRROOTCOVIDILLUM/$ANALYSISNAME-illumcovidseq;
		FINALPATH=$ROBOTDIRROOT/processing/secondary/illumcovidseq/$PROJECTID/$YEAR;
		
		if [ -d "$FINALPATH/$ANALYSISNAME-illumcovidseq" ]; then
		    ALLPIDS="";
		else
		    ALLPIDS=$(tail -n +2 $(ls -rt $ANALYSISPATH/job_output/*job_list* | tail -n 1) | awk -F'.' '{print $1}');
		fi
		
		#### WAIT FOR JOBS #### 
		echo -n "Wait for jobs to complete ... "
		if [ "$ALLPIDS" == "" ]; then 
		    echo "no jobs";
		else
		    ALLPIDS=$(echo "$ALLPIDS" | tail -n+2 | sort)
		    # echo -n "ALLPIDS:"; echo "$ALLPIDS" | tr '\n' ' ';
		    sleep 15;
		    while(true); do
			while(true); do 
			    a=$(qstat);
			    if [ $? -eq 0 ]; then 
				break; 
			    fi; 
			    sleep 1; 
			done;
			ALLPIDSACTIVE=$(echo "$a" | tail -n+3 | awk '$5!="C"{print $0}' | awk -F'.' '{print $1}' | sort);
			# echo -n "ALLPIDSACTIVE: "; echo "$ALLPIDSACTIVE" | tr '\n' ' ';
			N=$(comm -12 <(echo "$ALLPIDS") <(echo "$ALLPIDSACTIVE") | wc -l)
			if [ "$N" == "0" ]; then
			    break
			fi
			echo -n "($N)"
			sleep 60
		    done
		    echo " done"
		fi    
		
	    done
	    
	    for PROJECTID in $(grep 'Viruses:Severe acute respiratory syndrome coronavirus 2 (Taxon ID:2697049)' $_EVENTFILE | awk -F'\t' '{print $2}'  | sort -u); do		
		
		RAPID_RESPONSE_EMAILS=$(grep "$PROJECTID" ./email_config.csv | awk -F',' '{print $4}' | tr -d ' ' | tr ';' ',');		
		
		ANALYSISNAME=$RUNNAME.$PROJECTID.ARTIC_v4_1;
		ANALYSISPATH=$SCRATCHDIRROOTCOVIDILLUM/$ANALYSISNAME-illumcovidseq;
		FINALPATH=$ROBOTDIRROOT/processing/secondary/illumcovidseq/$PROJECTID/$YEAR;
		
		if [ -d "$FINALPATH/$ANALYSISNAME-illumcovidseq" ]; then
		    ls $FINALPATH/$ANALYSISNAME-illumcovidseq;		    
		else
		    mkdir -p $FINALPATH
		    mv $ANALYSISPATH $FINALPATH/;
		    
		    for f in $(find -L $FINALPATH/$ANALYSISNAME-illumcovidseq -xtype l); do stat $f | grep '  File: ' | sed 's/’ -> ‘/ /g' | sed 's/  File: //g' | tr -d '‘’' \
			| sed "s|$SCRATCHDIRROOTCOVIDILLUM|$FINALPATH|g" | awk '{print "ln -sf "$2 " " $1}';
		    done | sh
		fi
		
		. ./covid_nanopore_illum_qc_report.sh; runreport $FINALPATH/$ANALYSISNAME-illumcovidseq $FILT;
		
		echo "Send final email."
		( 
		    cat $FINALPATH/$ANALYSISNAME-illumcovidseq/agt_labqc_report/$ANALYSISNAME-illumcovidseq_lab_qc_report.html \
			| sed -n '/<body/q;p';
		    echo "<body>";		    
		    cat $FINALPATH/$ANALYSISNAME-illumcovidseq/agt_labqc_report/$ANALYSISNAME-illumcovidseq_lab_qc_report.html \
			| sed '0,/General information/d' \
			| sed '/General information/,$!d' \
			| sed -n '/Pipeline information/q;p';
    		    echo "</pre>";		    
		    cat $FINALPATH/$ANALYSISNAME-illumcovidseq/agt_labqc_report/$ANALYSISNAME-illumcovidseq_lab_qc_report.html \
			| sed '0,/Status tables/d' \
			| sed '/Status tables/,$!d' \
			| sed -n '/Run validation file/q;p' \
			| sed "s/popBase64('.*'/popBase64(''/";		    
    		    echo "</body></html>";		    
		) > /tmp/$ANALYSISNAME-illumcovidseq_lab_qc_report_onlytables.html
		
		HTML=$(cat /tmp/$ANALYSISNAME-illumcovidseq_lab_qc_report_onlytables.html)
		
		( 
		    echo "To: $(echo "$RAPID_RESPONSE_EMAILS")"
		    # echo "Reply-To: hercules@mcgill.ca"
		    echo "MIME-Version: 1.0"
		    echo "Subject: Secondary analysis complete for illumina run: $ANALYSISNAME-illumcovidseq"
		    echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
		    echo
		    echo '---q1w2e3r4t5'
		    echo "Content-Type: text/html"
		    echo
		    echo "$HTML"
		    echo '---q1w2e3r4t5'
		    echo
		    f=$FINALPATH/$ANALYSISNAME-illumcovidseq/agt_labqc_report/$ANALYSISNAME-illumcovidseq_lab_qc_report_onlycontrols.html
		    echo "Content-Type: text/html; name=$(basename $f)"
		    echo 'Content-Transfer-Encoding: base64'
		    echo "Content-Disposition: attachment; filename=$(basename $f)"
		    echo
		    base64 "$f"
		    
		) | sendmail -t -f bravo.genome@mcgill.ca;
		
		rm  /tmp/$ANALYSISNAME-illumcovidseq_lab_qc_report_onlytables.html
		
	    done
	    	    
	fi
    done
    sleep $SLEEPTIME;
done


