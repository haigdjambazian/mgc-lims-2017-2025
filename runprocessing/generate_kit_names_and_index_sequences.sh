#!/bin/bash

# Run in runprocessing folder
# sh generate_kit_names_and_index_sequences.sh haig.djambazian@mcgill.ca
# 

IFS=$'\n'

rm -rf /tmp/manifestprep
mkdir -p /tmp/manifestprep/columns

tabiter=0
i=1;

OUT1=/tmp/manifestprep/kit_names_and_index_sequences.tab1.txt
OUT2=/tmp/manifestprep/kit_names_and_index_sequences.tab2.txt
rm -f $OUT1 $OUT2

for pub in 1 0; do

i7side=$(awk -F',' '$8=='$pub' && $5=="i7"{print $7}' adapter_types.txt | tr '|' '\n' | sort -u | awk '{print $0",i7"}');
awk -F',' '$8=='$pub' && $5=="i7"{print $7}' adapter_types.txt | tr '|' '\n' | sort -u > /tmp/manifestprep/f1;
awk -F',' '$8=='$pub' && $5=="i5"{print $7}' adapter_types.txt | tr '|' '\n' | sort -u > /tmp/manifestprep/f2;
i5side=$( comm -13 /tmp/manifestprep/f1 /tmp/manifestprep/f2 | awk '{print $0",i5"}');

rm /tmp/manifestprep/f1 /tmp/manifestprep/f2;

########################################################################################################################################################################

if [ "$pub" == "1" ]; then
    printf "Published in manifest:\n" >> $OUT2
    echo >> $OUT2
    printf "Published in manifest:\n" >> $OUT1
    printf "Kit ID\tKit Name\tDual or Single\tIndex Cycles (i7-i5)\tBackbone Type\tIndex Name (eg.)\tIndex Pairing (eg.)\tKit Comment\n" >> $OUT1
else
    printf "Published in manifest:\n" >> $OUT2
    echo >> $OUT2
    printf "Not published in manifest:\n" >> $OUT1
    printf "Kit ID\tKit Name\tDual or Single\tIndex Cycles (i7-i5)\tBackbone Type\tIndex Name (eg.)\tIndex Pairing (eg.)\tKit Comment\n" >> $OUT1
fi


for set in $(printf "$i7side\n$i5side\n" | sort | grep -v "Custom index"; printf "$i7side\n$i5side\n" | sort | grep "Custom index" ); do

    SETNAME=$(echo $set | awk -F',' '{print $1}');
    SETTYPE=$(echo $set | awk -F',' '{print $2}');
    
    printf "Kit ID:\tadapt_%03d\n" $i >> $OUT2
    printf "Index Kit Name:\t$SETNAME\n" >> $OUT2


    printf "adapt_%03d\t" $i >> $OUT1
    printf "$SETNAME\t" >> $OUT1
	
    if [ "$SETTYPE" == "i7" ]; then

	AT=$(grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' )
	v=$(for line in $(echo "$AT" | head -n 30); do
	    index=$(echo "$line" | cut -d ','  -f 1)
	    u=$(cat adapter_settings_format.txt | awk -F',' '"'$index'"==$1{print $0}' | cut -d ','  -f 2- | tr ',' '\n' | awk '{print length($0)}') #  | tr '\n' '/' | rev | cut -c 2- | rev
	    L=$(echo "$u" | wc -l)
	    if [ "$L" == "1" ]; then
		echo "$(echo "$u" | head -n 1)bp"
	    else
		echo "balanced ${L}plex $(echo "$u" | head -n 1)bp"
	    fi
	done | sort -u)

	printf "Dual or Single:\t" >> $OUT2
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' | head -n 1  | awk -F',' '{print $3}' >> $OUT2

	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' | head -n 1  | awk -F',' '{print $3}' | tr -d '\n' >> $OUT1
	printf "\t" >> $OUT1

	printf "Index Cycles (i7-i5):\t" >> $OUT2
	if [ "$(echo "$AT" | awk -F',' '{print $3}' | head -n 1)" == "DUALINDEX" ]; then
	    w=$(for line in $(echo "$AT" | head -n 30); do
		index=$(echo "$line" | cut -d ','  -f 6 | awk -F'|' '{print $1}')
		u=$(cat adapter_settings_format.txt | awk -F',' '"'$index'"==$1{print $0}' | cut -d ','  -f 2- | tr ',' '\n' | awk '{print length($0)}') #  | tr '\n' '/' | rev | cut -c 2- | rev
		L=$(echo "$u" | wc -l)
		if [ "$L" == "1" ]; then
		    echo "$(echo "$u" | head -n 1)bp"
		else
		    echo "balanced ${L}plex $(echo "$u" | head -n 1)bp"
		fi
	    done | sort -u)
	    echo "$v" | awk '{print "("$0"-'$w')"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n' >> $OUT2
	    echo >> $OUT2

	    echo "$v" | awk '{print "("$0"-'$w')"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n' >> $OUT1
	    printf "\t" >> $OUT1


	else
	    echo "$v" | awk '{print "("$0"-0bp)"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n' >> $OUT2
	    echo >> $OUT2

	    echo "$v" | awk '{print "("$0"-0bp)"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n' >> $OUT1
	    printf "\t" >> $OUT1

	fi

	printf "Backbone Type:\t" >> $OUT2
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' | head -n 1  | awk -F',' '{print $2}' >> $OUT2
	
	printf "Comments:\t" >> $OUT2
	if [ "$pub" == "1" ]; then
	    grep "^$SETNAME," index_set_names.csv | awk -F',' '{print $4}' >> $OUT2
	else
	    echo -n "Set not in manifest. " >> $OUT2
	    grep "^$SETNAME," index_set_names.csv | awk -F',' '{print $4}' >> $OUT2
	fi

	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' | head -n 1  | awk -F',' '{print $2}' | tr -d '\n' >> $OUT1
	printf "\t" >> $OUT1

	printf "Index sequences:\n" >> $OUT2
	if [ "$(echo "$AT" | awk -F',' '{print $3}' | head -n 1)" == "DUALINDEX" ]; then
	   printf "i7_name-i5_name\ti7_sequence-i5sequence\n" >> $OUT2
	   for line in $(echo "$AT"); do
		indexlist=$(echo "$line" | cut -d ','  -f 6 | awk -F'|' '{print $1}');
		index1=$(echo "$line" | cut -d ','  -f 1);
		if [ "$indexlist" == "" ]; then
		    echo  "$index1-" | tr '\n' '\t' >> $OUT2
		    cat adapter_settings_format.txt | awk -F',' '"'$index1'"==$1{print $0}' | cut -d ','  -f 2- | tr '\n' '-' >> $OUT2
		    echo >> $OUT2
		else
		    for index2 in "$(echo $indexlist)"; do		    
			echo  "$index1-$index2" | tr '\n' '\t' >> $OUT2
			cat adapter_settings_format.txt | awk -F',' '"'$index1'"==$1{print $0}' | cut -d ','  -f 2- | tr '\n' '-' >> $OUT2
			cat adapter_settings_format.txt | awk -F',' '"'$index2'"==$1{print $0}' | cut -d ','  -f 2-  >> $OUT2
		    done
		fi
	   done
	else
	    printf "i7_name\ti7_sequence(s)\n" >> $OUT2
	    for line in $(echo "$AT"); do
		index1=$(echo "$line" | cut -d ','  -f 1);
		echo  "$index1" | tr '\n' '\t' >> $OUT2
		cat adapter_settings_format.txt | awk -F',' '"'$index1'"==$1{print $0}' | cut -d ','  -f 2- | tr ',' '\t' >> $OUT2
	    done
	fi

    else
	AT=$(grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' )
	v=$(for line in $(echo "$AT" | head -n 30); do
            index=$(echo "$line" | cut -d ','  -f 1)
	    u=$(cat adapter_settings_format.txt | awk -F',' '"'$index'"==$1{print $0}' | cut -d ','  -f 2- | tr ',' '\n' | awk '{print length($0)}') #  | tr '\n' '/' | rev | cut -c 2- | rev
	    L=$(echo "$u" | wc -l)
	    if [ "$L" == "1" ]; then
		echo "$(echo "$u" | head -n 1)bp"
	    else
		echo "balanced ${L}plex $(echo "$u" | head -n 1)bp"
	    fi
	done | sort -u)

	printf "Dual or Single:\t" >> $OUT2
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' | head -n 1  | awk -F',' '{print "SINGLEINDEX"}' >> $OUT2

	printf "Index Cycles (i7-i5):\t" >> $OUT2
	echo "$v" | awk '{print "(0bp-"$0")"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n' >> $OUT2
	printf "\n" >> $OUT2
	printf "Backbone Type:\t" >> $OUT2
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' | head -n 1  | awk -F',' '{print $2}' >> $OUT2

	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' | head -n 1  | awk -F',' '{print "SINGLEINDEX"}' | tr -d '\n' >> $OUT1
	printf "\t" >> $OUT1
	echo "$v" | awk '{print "(0bp-"$0")"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n' >> $OUT1
	printf "\t" >> $OUT1
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' | head -n 1  | awk -F',' '{print $2}' | tr -d '\n' >> $OUT1
	printf "\t" >> $OUT1

	printf "Comments:\t" >> $OUT2
	if [ "$pub" == "1" ]; then
	    grep "^$SETNAME," index_set_names.csv | awk -F',' '{print $4}' >> $OUT2
	else
	    echo -n "Set not in manifest. " >> $OUT2
	    grep "^$SETNAME," index_set_names.csv | awk -F',' '{print $4}' >> $OUT2
	fi
	printf "Index sequences:\n" >> $OUT2
	printf "i5_name\ti5_sequence(s)\n" >> $OUT2
	for line in $(echo "$AT"); do
	    index1=$(echo "$line" | cut -d ','  -f 1);
	    echo  "$index1" | tr '\n' '\t' >> $OUT2
	    cat adapter_settings_format.txt | awk -F',' '"'$index1'"==$1{print $0}' | cut -d ','  -f 2- | tr ',' '\t' >> $OUT2
	done
	
    fi
    
    
    grep "^$SETNAME," index_set_names.csv | awk -F',' '{print $2"\t"$3"\t"$4}' >> $OUT1
    
    echo >> $OUT2
    
    let i=$i+1 

done
echo >> $OUT1

done


echo "Index Set Sequences" | mailx -s "Index Set Sequences" \
    -a "$OUT1" \
    -a "$OUT2" \
    -r "abacus.genome@mail.mcgill.ca" $1

rm -r /tmp/manifestprep

