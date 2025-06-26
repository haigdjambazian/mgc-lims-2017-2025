# sh restartevent.sh 200219_A00266_0334_AHKJWLDRXX_JabadoHiC10XHamed fast

echo $1

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


    YEAR=$(date +%Y)
    FLOWCELLID=$( echo "$1" | sed 's/000000000//g' | awk -F'_' '{print $4}' | cut -c 2-);
    RUNID=$( echo "$1" | awk -F'_' '{print $2 "_" $3}');

    if [ "$2" == "fast" ]; then
	echo skip bash listjobs.sh 
    else
	bash listjobs.sh | awk '{print "canceljob " $2 "; # " $0}' | grep $RUNID  > $RUNID.listjobs
	wc -l $RUNID.listjobs
    fi

    A=$(grep -l $FLOWCELLID $ROBOTDIRROOT/processing/events/system/$YEAR/*-valid/*.txt)
    f=$(echo "$A" | tail -n 1)
    origf=$(echo "$A" | head -n 1)
    N=$(echo "$A" | wc -l)
    g=$ROBOTDIRROOT/processing/events/$(basename ${origf%.txt})_redo$N.txt

    head -n 10 $f | column -s $'\t' -t | cut -c 1-200

    echo "$A"
    for line in $(echo "$A"); do
        V=$( grep -A1 $(basename $line) $ROBOTDIRROOT/processing/events/system/event.log | paste - -)
        echo -n "$V monitor job found: "
        LASTPID=$(echo "$V" | tail -n 1 | awk -F":" '{print $3}');
        R=$(ps aux | grep "$LASTPID" | grep -v grep)
        if [ -z "$R" ];then
            echo "NO"
        else
            echo "YES:"
            echo "($R)"
	    echo
            echo "  kill -9 $LASTPID"
        fi
    done

    echo

    d=$(ls -d $SCRATCHDIRROOT/processing/$1* 2>/dev/null);
    if [ -d "$d" ]; then
	echo "rm -r $d";
    fi
    d=$(ls -d $ROBOTDIRROOT/processing/*/*/$1* 2>/dev/null);
    if [ -d "$d" ]; then
	echo "rm -r $d";
    fi

    for d in $(ls -d $ROBOTDIRROOT/processing/rapidresponse/*/*$RUNID* 2>/dev/null); do
	if [ -d "$d" ]; then
	    echo "rm -r $d";
	fi
    done
    
    echo

    echo sh $RUNID.listjobs
    echo rm $RUNID.listjobs
    echo

    echo cp $f $g
    echo
