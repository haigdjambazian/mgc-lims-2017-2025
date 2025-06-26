#!/bin/bash

# run ./Olink_alert_script.sh

SYSDIR=./Olink_alert_script
mkdir -p $SYSDIR
while(true); do
    for f in /nb/Research/Novaseq/*Olink*/CopyComplete.txt /nb/Research/Novaseq/*olink*/CopyComplete.txt /nb/Research/Novaseq/*OLINK*/CopyComplete.txt; do
	if [ -f "$f" ]; then

	    RUNNAME=$(basename $(dirname $f))
	    YEAR=$(echo "20$RUNNAME" | cut -c 1-4);
	    TIMESTAMP=$(date +%FT%H.%M.%S)
	    donefile=$SYSDIR/$RUNNAME.alertdone
	    if [ -f "$donefile" ]; then
		:
	    else

		echo "processing olink run: $RUNNAME"
		
		finaldir=/lb/robot/research/processing/olink/$YEAR/${RUNNAME}-olink; mkdir -p $finaldir/job_output;
		workdir=/lb/scratch/bravolims/processing-olink; mkdir -p $workdir; 
		# /nb/Research/processing-olink/$RUNNAME-olink;
		
		DAYS=1; PROC=2; QUEUE=sw;
		
		COMM=$(cat <<EOF
#!/bin/bash

module use /lb/project/mugqic/analyste_private/modulefiles/;
module load mugqic/bcl2counts/2.5.2;

set -e;

cd ${workdir};
cp -R /nb/Research/Novaseq/${RUNNAME} ${RUNNAME}-olink;
bcl2counts -v --stdout ${RUNNAME}-olink > ${RUNNAME}-olink/bcl2counts.log;

cd ${finaldir};
mkdir transfer_${RUNNAME}-olink;
cp -v ${workdir}/${RUNNAME}-olink/matched_counts_*_sample_001_096.csv transfer_${RUNNAME}-olink/;
cp -v ${workdir}/${RUNNAME}-olink/bcl2counts.log transfer_${RUNNAME}-olink/;
cp -v ${workdir}/${RUNNAME}-olink/run_metadata.json transfer_${RUNNAME}-olink/;

zip -r transfer_${RUNNAME}-olink.zip transfer_${RUNNAME}-olink;

rm -r ${workdir}/${RUNNAME}-olink;

echo "success!"

EOF
);

		JOBLOG=/lb/robot/research/processing/olink/$YEAR/${RUNNAME}-olink/job_output/${RUNNAME}-olink_$TIMESTAMP.o
		
		PID=$(echo "$COMM" | qsub -d $(pwd) -V -l walltime=$DAYS:00:00:0 -q $QUEUE -l nodes=1:ppn=$PROC -l qos=research -j oe -N ${RUNNAME}-olink \
		    -o $JOBLOG | awk -F'.' '{print $1}');
		
		ALLPIDS=$PID
		
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
		

		while(true); do
		    N=$(grep -c 'End PBS Epilogue' $JOBLOG 2>/dev/null);
		    if [ "$N" == "1" ]; then
			break
		    fi
		    sleep 10;
		done

HTML=$(cat <<EOF
<html><head><title>Olink NovaSeq run $RUNNAME was processed (bcl2counts)</title>
</head>
<body>
This is an automated message sent from the olink run processing event monitor.<br>
Olink NovaSeq run $RUNNAME has completed and was processed with bcl2counts.<br>
<br>
Results are in the zip file attached to this email and are also stored here:<br>
/lb/robot/research/processing/olink/$YEAR/${RUNNAME}-olink<br>
<br>
If you encounter any issues with this automated system please contact haig.djambazian@mcgill.ca.<br>
<br>
bcl2counts job log:<br>
$(cat $JOBLOG | awk '{print $0"<br>"}')
EOF
);

		
		EMAILLIST="markus.munter@mcgill.ca,pouria.jandaghi@mcgill.ca,madeleine.arseneault@mcgill.ca,haig.djambazian@mcgill.ca,janick.st-cyr@mcgill.ca,elizabeth.caron2@mcgill.ca"
		# EMAILLIST="haig.djambazian@mcgill.ca"
		(   
		    echo "To: $(echo "$EMAILLIST")"
		    echo "MIME-Version: 1.0"
		    echo "Subject: Olink NovaSeq run $RUNNAME was processed (bcl2counts)"
		    echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
		    echo
		    echo '---q1w2e3r4t5'
		    echo "Content-Type: text/html"
		    echo
		    echo "$HTML"
		    echo
		    echo '---q1w2e3r4t5'
		    echo
		    f=/lb/robot/research/processing/olink/$YEAR/${RUNNAME}-olink/transfer_${RUNNAME}-olink.zip
		    echo "Content-Type: application/zip; name=$(basename $f)"
		    echo 'Content-Transfer-Encoding: base64'
		    echo "Content-Disposition: attachment; filename=$(basename $f)"
		    echo
		    base64 $f
		) | sendmail -t -f bravo.genome@mcgill.ca;
		
		touch $donefile
	    fi
	fi    
    done    
    echo -n "."
    sleep 3600
done
