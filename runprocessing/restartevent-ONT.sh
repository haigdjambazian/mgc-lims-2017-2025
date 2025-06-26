#!/usr/bin/bash

# usage to test: sh restartevent-ONT.sh 20211115_1506_2-E3-H3_PAH65645_c0e04990
# usage to run:  sh restartevent-ONT.sh 20211115_1506_2-E3-H3_PAH65645_c0e04990 | sh

# Flowcell Name represents the unique run name produced by the sequencer.

FLOWCELL_NAME=$1

# clear


SCRATCHDIRROOT=/nb/Research;
ROBOTDIRROOT=/lb/robot/research;

if [ "$USER" == "bravolims-qc" ]; then
    SCRATCHDIRROOT=/lb/bravo/bravoqc/nb-Research;
    ROBOTDIRROOT=/lb/bravo/bravoqc/lb-robot-research;
fi

if [ "$USER" == "bravolims-dev" ]; then
    SCRATCHDIRROOT=/lb/bravo/bravodev/nb-Research;
    ROBOTDIRROOT=/lb/bravo/bravodev/lb-robot-research;
fi



echo "################################"
echo "# Step 1: Stop child run monitor"
echo "#"
sh stopchildmonitor.sh $FLOWCELL_NAME
echo

echo "#######################################"
echo "# Step 2a: make sure no jobs are running (from robot)"
echo "#"
FOUND=false
for d in $ROBOTDIRROOT/processing/ont/ontcovidseq/*/*/*$FLOWCELL_NAME*; do
    if [ -d "$d" ]; then
        pids=$(ls $d/job_output/*_job_list_* | tail -n 1);
        if [ -f "$pids" ]; then
            FOUND=true
            COMM=$(cat <<EOF
echo "killing jobs still running"
for pid in \$(awk -F'\t' '{print \$1}' $pids); do canceljob \$pid > /dev/null 2>&1; done
EOF
	    );
            echo "$COMM";
        fi
    fi
done
echo

echo "#######################################"
echo "# Step 2b: make sure no jobs are running (from scratch)"
echo "#"
if ($FOUND); then
    echo "# Found the job IDs using list from robot. Skip."
    echo
else
    for d in $SCRATCHDIRROOT/processingontscratch/*$FLOWCELL_NAME*; do
        if [ -d "$d" ]; then
            pids=$(ls $d/job_output/*_job_list_* | tail -n 1);
            if [ -f "$pids" ]; then
		COMM=$(cat <<EOF
echo "killing jobs still running"
for pid in \$(awk -F'\t' '{print \$1}' $pids); do canceljob \$pid > /dev/null 2>&1; done
EOF
		);
		echo "$COMM";
            fi
        fi
    done
    echo
fi

echo "####################################################"
echo "# Step 3: Put run processing folder back in scratch"
echo "#"
for d in $ROBOTDIRROOT/processing/ont/ontcovidseq/*/*/*$FLOWCELL_NAME*; do
    if [ -d "$d" ]; then
        echo mv -v $d $SCRATCHDIRROOT/processingontscratch/;
    fi
done
echo

echo "############################################"
echo "# Step 4: Find the last event file from lims"
echo "#"
echo "# The last one listed here:"
YEAR=$(date +%Y)
A=$(grep -l $FLOWCELL_NAME $ROBOTDIRROOT/processing/events/system/$YEAR/*-valid/*samples*.txt $ROBOTDIRROOT/processing/events/system/$(($YEAR-1))/*-valid/*samples*.txt )
f=$(echo "$A" | tail -n 1)
origf=$(echo "$A" | head -n 1)
N=$(echo "$A" | wc -l)
g=$ROBOTDIRROOT/processing/events/$(basename ${origf%.txt})_redo$N.txt
echo "$A" | awk '{print "# " $0}'
echo

echo "############################################################"
echo "# Step 5: Restart the pipeline with a newly named event file"
echo "#"
echo cp -v $f $g
echo
