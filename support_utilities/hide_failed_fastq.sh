list="2-961064_2-782862, 2-961064_2-782863, 2-961064_2-782864, 2-961064_2-782865, 2-961077_2-782866, 2-961077_2-782867, 2-961077_2-782868, 2-961077_2-782869, 2-961077_2-782870, 2-961077_2-782871, 2-961069_2-782872, 2-961069_2-782873, 2-961069_2-782874, 2-961069_2-782875, 2-961069_2-782876, 2-961069_2-782877"

run=201204_A00266_0442_AH3CCNDSXY_MRCArun2of2
eventfile=92-963364_24-135071_samples.txt

eventfileabs=$(ls /lb/robot/research/processing/events/system/*/*/$eventfile)


for fastqid in $(echo "$list" | tr -d ' ' | tr ',' '\n'); do

    if [[ "$fastqid" == *_* ]]; then
	tok1=$(echo $fastqid | awk -F'_' '{print $1}')
	tok2=$(echo $fastqid | awk -F'_' '{print $2}')
	LANE=$(cat $eventfileabs | grep $tok1 | grep $tok2 | awk -F'\t' '{print $6}' | sed 's/:1//g')
	SAMPLE=$(cat $eventfileabs | grep $tok1 | grep $tok2 | awk -F'\t' '{print $13}')
	LIBID=$(cat $eventfileabs | grep $tok1 | grep $tok2 | awk -F'\t' '{print $8}')
    else
	tok1=$fastqid
	LANE=$(cat $eventfileabs | grep $tok1 | grep $tok2 | awk -F'\t' '{print $6}' | sed 's/:1//g')
	SAMPLE=$(cat $eventfileabs | grep $tok1 | grep $tok2 | awk -F'\t' '{print $13}')
	LIBID=$(cat $eventfileabs | grep $tok1 | grep $tok2 | awk -F'\t' '{print $8}')
    fi

    echo "# Lane:$LANE, Sample: $SAMPLE, Library ID: $LIBID, LibNorm ID: $tok1"
    for f in /lb/robot/research/processing/*/*/$run*/Unaligned.$LANE/P*/S*/${SAMPLE}_${LIBID}*gz; do
	if [ -f "$f" ]; then
	    echo mv -v $f $f.failed-do-not-use
	fi
    done
    for f in /lb/robot/research/processing/*/*/$run*/Unaligned.$LANE/P*/S*/${SAMPLE}_${LIBID}*md5; do
	if [ -f "$f" ]; then
	    echo mv -v $f $f.failed-do-not-use
	fi
    done

done > faildatasets.sh
