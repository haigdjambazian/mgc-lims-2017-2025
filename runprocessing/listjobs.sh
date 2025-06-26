#!/usr/bin/bash

JOBS=$( showq -v | grep "$USER "| awk -F'/' '{ print $1 }' | sort -nr )
JOBSLENGTH=$(echo $JOBS | wc --words)

PBAR='##############################'
FILL='------------------------------'
barLen=30

count=0
for JOB in $JOBS; do
    CHECKJOB=$(checkjob -v $JOB)
    JOBNAME=$( echo $CHECKJOB | grep AName | tr -d \"\\n\" | sed 's/AName: //' | sed 's/ //' )
    STATE=$( echo $CHECKJOB | grep -m 1 State | sed 's/State: //' | sed 's/ //' )
    if [ "$STATE" = "Idle"  ]; then
        echo "Jobid: "$JOB" State: "$STATE",    Node: none"",     Jobname: "$JOBNAME
    else NODENAME=$( echo $CHECKJOB | grep '\[' | grep -v '\[0\]'| sed 's/\[//' | sed 's/\]//' | grep -v '[ALL]')
        MEM=$( echo $CHECKJOB | grep 'Utilized Resources Per Task' | awk '{print $6"/"$8"/"$10}')
        echo "Jobid: "$JOB" State: "$STATE", Node: "$NODENAME", PROC/MEM/SWAP: "$MEM", Jobname: "$JOBNAME
    fi
    count=$(($count + 1))
    percent=$((($count * 100 / $JOBSLENGTH * 100) / 100))
    i=$(($percent * $barLen / 100))
    >&2 echo -ne "\r[${PBAR:0:$i}${FILL:$i:barLen}] $count/$JOBSLENGTH ($percent%)"
done
>&2 echo -ne "\r"