#!/bin/bash

# Run in runprocessing folder
# sh generate_manifest_ranges.sh haig.djambazian@mcgill.ca
# 
# After updating manifest with table send by email put it back in repo
# cd samplesubmissiontemplates; lftp -e "mirror tmp2;  bye" -u 'hdjambaz:         '  sftp://sftp.mcgillgenomecentre.ca; mv tmp2/MGC_Sample_Submission_Template_BLANK.xlsx .; rm -r tmp2/


IFS=$'\n'

rm -rf /tmp/manifestprep
mkdir -p /tmp/manifestprep/columns

i7side=$(awk -F',' '$8!=0 && $5=="i7"{print $7}' adapter_types.txt | tr '|' '\n' | sort -u | awk '{print $0",i7"}' );
awk -F',' '$8!=0 && $5=="i7"{print $7}' adapter_types.txt | tr '|' '\n' | sort -u > /tmp/manifestprep/f1
awk -F',' '$8!=0 && $5=="i5"{print $7}' adapter_types.txt | tr '|' '\n' | sort -u > /tmp/manifestprep/f2
i5side=$( comm -13 /tmp/manifestprep/f1 /tmp/manifestprep/f2 | awk '{print $0",i5"}')

rm /tmp/manifestprep/f1 /tmp/manifestprep/f2

N=$(($(cat library_protocol_list.csv | awk -F',' '$8==1{print $1 " / " $6 " / "  $7}' | wc -l) + 2  ))
( printf "Library Type\n";(set +o histexpand; printf "ranges!U3:U$N\n"); cat library_protocol_list.csv | awk -F',' '$8==1{print $1 " / " $6 " / " $7}' ) > /tmp/manifestprep/columns/manifest_library_column.txt

EXCELCOL=$(for v in "" {A..Z}; do for w in {A..Z}; do echo $v$w; done; done | tail -n +25)

########################################################################################################################################################################

i=1;
for set in $(printf "$i7side\n$i5side\n" | sort | grep -v "Custom index"; printf "$i7side\n$i5side\n" | sort | grep "Custom index" ); do
echo $set

(
    printf "adapt_%03d\n" $i

    SETNAME=$(echo $set | awk -F',' '{print $1}');
    SETTYPE=$(echo $set | awk -F',' '{print $2}');    

    printf "$SETNAME\n"
    
    if [ "$SETTYPE" == "i7" ]; then
	AT=$(grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' );
	if [ "$(echo "$AT" | awk -F',' '{print $3}' | head -n 1)" == "DUALINDEX" ]; then
	    for line in $(echo "$AT"); do
		for i7index in $(echo "$line" | awk -F',' '{print $1}'); do
		    for i5index in $(echo "$line" | awk -F',' '{print $6}' | tr '|' '\n'); do
			echo $i7index-$i5index
		    done
		done
	    done
	else
	    for line in $(echo "$AT"); do
		for i7index in $(echo "$line" | awk -F',' '{print $1}'); do		
			echo $i7index
		done
	    done
	fi
    else
	AT=$(grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' );
	for line in $(echo "$AT"); do
	    for i5index in $(echo "$line" | awk -F',' '{print $1}'); do		
		echo $i5index
	    done
	done		
    fi    
    
)> /tmp/manifestprep/columns/manifest_index_column_n_$(printf "%03d" $i).txt
let i=$i+1
    
done 

########################################################################################################################################################################


MM=$(( $((printf "$i7side\n$i5side\n" | sort | grep -v "Custom index"; printf "$i7side\n$i5side\n" | sort | grep "Custom index") | wc -l) + 4 ))

i=1;
(
    printf "\tAdapter Series\t\n";
  (set +o histexpand;     printf "\tranges!W3:W$MM\tranges!W3:X$MM\n" )

for set in $(printf "$i7side\n$i5side\n" | sort | grep -v "Custom index"; printf "$i7side\n$i5side\n" | sort | grep "Custom index" ); do
    printf "adapt_%03d\t" $i

    SETNAME=$(echo $set | awk -F',' '{print $1}');
    SETTYPE=$(echo $set | awk -F',' '{print $2}');
    
    echo -n "$SETNAME - "
    
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

	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' | head -n 1  | awk -F',' '{print $3 " - "}'
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
	    echo "$v" | awk '{print "("$0"-'$w')"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n';
	else
	    echo "$v" | awk '{print "("$0"-0bp)"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n';
	fi
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i7"{print $0}' | head -n 1  | awk -F',' '{print " - " $2}'
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
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' | head -n 1  | awk -F',' '{print "SINGLEINDEX" " - "}'
	echo "$v" | awk '{print "(0bp-"$0")"}' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's/~/ and /g' | tr -d '\n';
	grep "$SETNAME" adapter_types.txt | awk -F',' '$5=="i5"{print $0}' | head -n 1  | awk -F',' '{print " - " $2}'
	
	
    fi | tr -d "\n"

N=$(cat /tmp/manifestprep/columns/manifest_index_column_n_$(printf "%03d" $i).txt | wc -l)
letter=$(echo "$EXCELCOL" | head -n $i | tail -n 1)
printf "\tranges!${letter}3:${letter}$N\n"

let i=$i+1
    
done

printf "\tCustom indexes\t\n\tNon-listed commercial indexes\t\n"

) > /tmp/manifestprep/columns/manifest_index_column_first.txt

NN=$(wc -l /tmp/manifestprep/columns/*.txt | sort -nrk1 | grep -v total | head -n 1 | awk '{print $1}')
mkdir -p /tmp/manifestprep/columns2

f=/tmp/manifestprep/columns/manifest_library_column.txt;
N=$(cat $f | wc -l); cat $f > /tmp/manifestprep/columns2/$(basename $f); yes '' | head -n $(($NN - $N )) | awk '{printf "\n"}' >> /tmp/manifestprep/columns2/$(basename $f);

f=/tmp/manifestprep/columns/manifest_index_column_first.txt;
N=$(cat $f | wc -l); cat $f > /tmp/manifestprep/columns2/$(basename $f); yes '' | head -n $(($NN - $N )) | awk '{printf "\t\t\n"}' >> /tmp/manifestprep/columns2/$(basename $f);

for f in /tmp/manifestprep/columns/manifest_index_column_n_*; do
    N=$(cat $f | wc -l); cat $f > /tmp/manifestprep/columns2/$(basename $f); yes '' | head -n $(($NN - $N )) | awk '{printf "\n"}' >> /tmp/manifestprep/columns2/$(basename $f);
done


paste /tmp/manifestprep/columns2/manifest_library_column.txt /tmp/manifestprep/columns2/manifest_index_column_first.txt /tmp/manifestprep/columns2/manifest_index_column_n_* > /tmp/manifestprep/finalpaste.txt

file=/tmp/manifestprep/finalpaste.txt
echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" $1 

rm -r /tmp/manifestprep

