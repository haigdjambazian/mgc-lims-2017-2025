# usage: sh bclcount.sh "220321_A01433_0141_BH7JY2DMXY_DoVEEredoQ009522|220321_A00266_0641_AHWV5JDSX2_SchurrQ009442"

# file=report.html; for f in /nb/Research/processing/220321_A*/Unaligned.*/Reports/html/*/all/all/all/laneBarcode.html; do echo "$f"; cat $f; done> $file;  echo $file | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca;


runs="$1";

TMPsub1=""
# TMPsub1=tmp/*
TMPsub2=""
# TMPsub2=tmp/*

for rundir in $( echo "$runs" | tr '|' ' '); do
    echo $rundir
    CYCLES=$(grep "Read Number" /nb/Research/Novaseq/$TMPsub1/$rundir/RunInfo.xml  | awk -F'"' '{print $4}' | paste -sd+  | bc)
    echo "cycles:$CYCLES"
    for d in $(ls -d /nb/Research/Novaseq/$TMPsub2/$rundir 2>/dev/null); do 
	echo $d; 
	for i in 1 2 3 4; do 
	    if [ -d "$d/Data/Intensities/BaseCalls/L00$i" ]; then
		echo -n "L00$i ";   
		for j in $(seq 1 1 $CYCLES ); do
	            echo -n " C$j.1 "; 
		    ls -l $d/Data/Intensities/BaseCalls/L00$i/C$j.1 2>/dev/null;
		done  | wc -l;
	    fi
	done;
    done;
done
echo "#########################################"
echo "showing missing bcl number"
for rundir in $( echo "$runs" | tr '|' ' '); do
    CYCLES=$(grep "Read Number" /nb/Research/Novaseq/$TMPsub1/$rundir/RunInfo.xml  | awk -F'"' '{print $4}' | paste -sd+  | bc)
    for d in $(ls -d /nb/Research/Novaseq/$TMPsub2/$rundir 2>/dev/null); do 
	echo $d; 
	for i in 1 2 3 4; do
	    if [ -d "$d/Data/Intensities/BaseCalls/L00$i" ]; then
		echo "L00$i missing:";
		for j in $(seq 1 1 $CYCLES ); do
		    if [ -d "$d/Data/Intensities/BaseCalls/L00$i/C$j.1" ]; then
			:
		    else
			echo L00$i/C$j.1
		    fi
		done | wc -l
	    fi
	done;
    done;
done

#echo "showing smallest bcls sizes"
#for rundir in $( echo "$runs" | tr '|' ' '); do
#    for d in $(ls -d /nb/Research/Novaseq/$TMPsub1/$rundir 2>/dev/null); do 
#	CYCLES=$(grep "Read Number" /nb/Research/Novaseq/$TMPsub2/$rundir/RunInfo.xml  | awk -F'"' '{print $4}' | paste -sd+  | bc)
#	echo $d; 
#	for i in 1 2 3 4; do
#	    if [ -d "$d/Data/Intensities/BaseCalls/L00$i" ]; then
#		echo "L00$i ";
#		for j in $(seq 1 1 $CYCLES ); do
#		    ls -l $d/Data/Intensities/BaseCalls/L00$i/C$j.1 2>/dev/null | awk '{print $5}';
#		done | grep -v "^$" | sort -n | head -n 20;
#	    fi
#	done;
#   done;
#done
