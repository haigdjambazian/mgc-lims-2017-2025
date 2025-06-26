#!/bin/bash


function comment_dontrun {

SRCDIR=/home/bravolims-dev/runprocessing

 file=out.csv && time sh hamming_dist_v5.sh $file $SRCDIR && echo "$file"  | mailx -s "$file" -a "${file%.*}".html -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca &
 file=out2.csv && time sh hamming_dist_v5.sh $file $SRCDIR && echo "$file" | mailx -s "$file" -a "${file%.*}".html -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca &

 file=sampleslist_poolplan_big1pool.csv && time sh hamming_dist_v5.sh $file $SRCDIR && echo "$file" | mailx -s "$file" -a "${file%.*}".html -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca & 
 file=sampleslist_course_short2.csv && time sh hamming_dist_v5.sh $file $SRCDIR && echo "$file" | mailx -s "$file" -a "${file%.*}".html -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca &

 file=sampleslist_course.csv && time sh hamming_dist_v5.sh $file $SRCDIR && echo "$file" | mailx -s "$file" -a "${file%.*}".html -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca &

file=sampleslist_12x48.csv && time sh hamming_dist_v5.sh $file $SRCDIR && echo "$file" | mailx -s "$file" -a "${file%.*}".html -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca &

}

IFS=$'\n'


function getindex {

#  INDEX1CYCLES=8;INDEX2CYCLES=8;INDEX_TYPE=DUAL_INDEX;SEQ_TYPE=novaseq; LIB_STRUCTURE='TruSeqHT'; SAMPLE_NAME=sample1; LIB_ID=AAA; INDEX_NAME=NS_Adaptor_4; getindex

if [[ "$INDEX_NAME" == SI-* ]] && [ "$LIB_STRUCTURE" == "tenX_sc_RNA_v1" ]; then
    INDEX1=""; INDEX1SEQ="";
    INDEX2=$INDEX_NAME
    INDEX2SEQ=$(awk -F, -v key=$INDEX2 '$1 == key {print $2; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_A
    INDEX2SEQ=$(awk -F, -v key=$INDEX2 '$1 == key {print $3; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_B
    INDEX2SEQ=$(awk -F, -v key=$INDEX2 '$1 == key {print $4; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_C
    INDEX2SEQ=$(awk -F, -v key=$INDEX2 '$1 == key {print $5; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_D
elif [[ "$INDEX_NAME" == SI-* ]]; then
    INDEX1=$INDEX_NAME
    INDEX2=""; INDEX2SEQ=""
    INDEX1SEQ=$(awk -F, -v key=$INDEX1 '$1 == key {print $2; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_A
    INDEX1SEQ=$(awk -F, -v key=$INDEX1 '$1 == key {print $3; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_B
    INDEX1SEQ=$(awk -F, -v key=$INDEX1 '$1 == key {print $4; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_C
    INDEX1SEQ=$(awk -F, -v key=$INDEX1 '$1 == key {print $5; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}_D
elif [[ "$INDEX_NAME" == *-* ]]; then
    INDEX1=$(echo $INDEX_NAME | awk -F'-' '{print $1}')
    INDEX2=$(echo $INDEX_NAME | awk -F'-' '{print $2}')
    INDEX1SEQ=$(awk -F, -v key=$INDEX1 '$1 == key {print $2; exit}' $INDEX_DEF_FILE)
    INDEX2SEQ=$(awk -F, -v key=$INDEX2 '$1 == key {print $2; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}
else
    INDEX1=$INDEX_NAME
    INDEX2=""; INDEX2SEQ=""
    INDEX1SEQ=$(awk -F, -v key=$INDEX1 '$1 == key {print $2; exit}' $INDEX_DEF_FILE)
    subgetindex ${SAMPLE_NAME}_${LIB_ID}
fi

}



function subgetindex {

BCL2FASTQ_SAMPLE_NAME=$1

ACTUALINDEX1SEQ='';
ACTUALINDEX2SEQ='';

INDEX1PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
INDEX1PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
INDEX2PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
INDEX2PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')

INDEXN1PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
INDEXN1PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
INDEXN2PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
INDEXN2PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')


PRESENT_1_truseq=$(grep -A4 "^$LIB_STRUCTURE:" $INDEX_DEF_FILE  | grep -E "^3'|^5'" | sed "s/5'//g"  | sed "s/3'//g" | tr -d " '\-" | grep -c $INDEX1PRIMER )
PRESENT_2_truseq=$(grep -A4 "^$LIB_STRUCTURE:" $INDEX_DEF_FILE  | grep -E "^3'|^5'" | sed "s/5'//g"  | sed "s/3'//g" | tr -d " '\-" | grep -c $INDEX2PRIMER )

if [ "$PRESENT_1_truseq" != "0" ]; then
    INDEX1PRIMER_USE=$INDEX1PRIMER;
    INDEX1PRIMEROFFSET_USE=$INDEX1PRIMEROFFSET;
else
    INDEX1PRIMER_USE=$INDEXN1PRIMER;
    INDEX1PRIMEROFFSET_USE=$INDEXN1PRIMEROFFSET;
fi

if [ "$PRESENT_2_truseq" != "0" ]; then
    INDEX2PRIMER_USE=$INDEX2PRIMER;
    INDEX2PRIMEROFFSET_USE=$INDEX2PRIMEROFFSET;
else
    INDEX2PRIMER_USE=$INDEXN2PRIMER;
    INDEX2PRIMEROFFSET_USE=$INDEXN2PRIMEROFFSET;
fi


MAINSEQ=$(grep -A4 "^$LIB_STRUCTURE:" $INDEX_DEF_FILE  | grep -E "^3'|^5'" | head -n 1 | sed "s/5'//g"  | sed "s/3'//g" | tr -d " '\-" | grep $INDEX1PRIMER_USE )

ACTUALINDEX1SEQ=$(echo $MAINSEQ | awk -F"$INDEX1PRIMER_USE" '{print $2}' | sed "s/\[i7\]/$INDEX1SEQ/g" | \
    cut -c $(($INDEX1PRIMEROFFSET_USE+1))-$(($INDEX1PRIMEROFFSET_USE+$INDEX1CYCLES)));

if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
    if [ "$SEQ_TYPE" == "hiseqx" ] || [ "$SEQ_TYPE" == "hiseq4000" ] || [ "$SEQ_TYPE" == "iSeq" ] || ( [ "$SEQ_TYPE" == "novaseq" ] && [ "$SBS_CONSUMABLE_VERSION" == "3" ] ); then
        MAINSEQ=$(grep -A4 "^$LIB_STRUCTURE:" $INDEX_DEF_FILE  | grep -E "^3'|^5'" | sed "s/5'//g"  | sed "s/3'//g" | tr -d " '\-" | grep $INDEX2PRIMER_USE)
        ACTUALINDEX2SEQ=$(echo $MAINSEQ | awk -F"$INDEX2PRIMER_USE" '{print $1}' |  sed "s/\[i5c\]/$(echo $INDEX2SEQ | tr 'ATGC' 'TACG' )/g" | rev | \
            cut -c $(($INDEX2PRIMEROFFSET_USE+1))-$(($INDEX2PRIMEROFFSET_USE+$INDEX2CYCLES)));
    else
        MAINSEQ=$(grep -A4 "^$LIB_STRUCTURE:" $INDEX_DEF_FILE  | grep -E "^3'|^5'" | sed "s/5'//g"  | sed "s/3'//g" | tr -d " '\-" | grep $INDEX2PRIMER_USE)
        ACTUALINDEX2SEQ=$(echo $MAINSEQ | awk -F"$INDEX2PRIMER_USE" '{print $2}' | sed "s/\[i5\]/$INDEX2SEQ/g" | \
            cut -c $(($INDEX2PRIMEROFFSET_USE+1))-$(($INDEX2PRIMEROFFSET_USE+$INDEX2CYCLES)));
    fi
fi

MAINSEQ=$(grep -A4 "^$LIB_STRUCTURE:" $INDEX_DEF_FILE  | grep -E "^3'|^5'" | head -n 1 | sed "s/5'//g"  | sed "s/3'//g" | tr -d " '\-" | grep "\[i7\]" )
ADAPTERi7=$(echo "$MAINSEQ" | awk -F "\\\[i7\\\]" '{print $1}' | awk -F "\\\]" '{print $NF}')
MAINSEQ=$(grep -A4 "^$LIB_STRUCTURE:" $INDEX_DEF_FILE  | grep -E "^3'|^5'" | sed "s/5'//g"  | sed "s/3'//g" | tr -d " '\-" | grep "\[i5c\]")
ADAPTERi5=$(echo "$MAINSEQ" | awk -F "\\\[i5c\\\]" '{print $2}' | awk -F "\\\[" '{print $1}' | rev )

echo ${BCL2FASTQ_SAMPLE_NAME},$ACTUALINDEX1SEQ,$ACTUALINDEX2SEQ,$ADAPTERi7,$ADAPTERi5

}



function hammingDist { 
    str1=$1
    str2=$2
    len=$3
    count=0;
    for i in $(seq 1 $len); do
        let j=$i-1
        if [ "${str1:$j:1}" != "${str2:$j:1}" ]; then
          let count=$count+1
        fi
    done
    echo $count;
} 
 

function htmltable {
    a="$(cat - )";
    echo "<table border=\"1\" class=\"$1\">"
    echo "$a" | head -n 1 | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|,|</th><th>|g'
    echo "$a" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|,|</td><td>|g'
    echo "</table>"
}


function plotplates {

IFS=$'\n'

PoolList="$(echo "$listdetailed" | tail -n+2 | awk -F',' '{print $2}' | sort -u)"
echo "<table border=\"1\" class=\"style1\" >" # outer table
echo "<tr><th>Pool Name</th>" # outer table
PlateList="$(echo "$listdetailed" | tail -n+2 | awk -F',' '{print $5}' | sort -u)"
for plate in $(echo "$PlateList"); do
    echo "<th>$plate</th>" # outer table
done
echo "</tr>" # outer table

for pool in $(echo "$PoolList"); do
  echo "<tr><th>$pool</th>" # outer table

  for plate in $(echo "$PlateList"); do

    U=$(echo "$listdetailed" | grep ",$pool," | grep ",$plate," )
    if [ -z "$U" ]; then
      echo "<td></td>"
      continue;
    fi

    echo "<td>" # outer table
    echo "<table border=\"1\" class=\"style2\">"
    echo -n "<tr><th></th>"
    for col in 01 02 03 04 05 06 07 08 09 10 11 12; do
      echo -n "<th>$(echo "$col" | sed 's/10/1x/g' | tr -d '0' | sed 's/1x/10/g')</th>"
    done
    echo "</tr>"
    
    for row in A B C D E F G H; do
      echo -n "<tr>"
      echo -n "<th>$row</th>"
      for col in 01 02 03 04 05 06 07 08 09 10 11 12; do
        color=' bgcolor="#F0F0F0"'
        content=""
        V=$(echo "$listdetailed" | grep ",$pool," | grep ",$plate," | grep ",$row$col,")
        if [ ! -z "$V" ]; then
          content="$row$col"
          W=$(echo "$listfailed" | grep "^$pool," | grep ",$plate," | grep ",$row$col,")
          if [ ! -z "$W" ]; then
            color=' bgcolor="#FF7777"'
          else
            color=' bgcolor="#'${sea[100]}'"'
          fi
        fi
        echo -n "<td$color>$content</td>"
      done
      echo "</tr>"
    done
    echo "</table>"
    echo "</td>" # outer table
  done
  echo "</tr>" # outer table
done
echo "</table>" # outer table

IFS=$'\n'

}



function collision_matrix { 

UDF=$1

declare -A matrix

listlen=$(echo "$list" | wc -l)
for i in $(seq 1 $listlen); do
    for j in $(seq 1 $listlen); do
        matrix[$i,$j]=""
    done
done

maxlen1=$(echo "$list" | awk -F',' '{print length($7)}' | sort -nr -k1 | head -n 1)
maxlen2=$(echo "$list" | awk -F',' '{print length($8)}' | sort -nr -k1 | head -n 1)

if [ -z "$maxlen1" ]; then maxlen1=0; fi
if [ -z "$maxlen2" ]; then maxlen2=0; fi

rm -f "${filein%.*}".tmp

listfailed=""
first=true
i=0
for ALINE in $(echo "$list"); do
    let i=$i+1;

    IFS=, read  APN AP APL APW AS AL AI1 AI2 AIN <<<$(echo "$ALINE")

#    APN=$(echo "$ALINE" | awk -F',' '{print $1}')
#      AP=$(echo "$ALINE" | awk -F',' '{print $2}')
#      APL=$(echo "$ALINE" | awk -F',' '{print $3}')
#      APW=$(echo "$ALINE" | awk -F',' '{print $4}')
#      AS=$(echo "$ALINE" | awk -F',' '{print $5}')
#      AL=$(echo "$ALINE" | awk -F',' '{print $6}')
#    AI1=$(echo "$ALINE" | awk -F',' '{print $7}')
#    AI2=$(echo "$ALINE" | awk -F',' '{print $8}')
#    AIN=$(echo "$ALINE" | awk -F',' '{print $9}')
    len1=${#AI1}
    len2=${#AI2}
    
    j=0
    for BLINE in $(echo "$list"); do
        let j=$j+1;

    IFS=, read BPN BP BPL BPW BS BL BI1 BI2 BIN <<<$(echo "$BLINE")

#        BPN=$(echo "$BLINE" | awk -F',' '{print $1}')
#          BP=$(echo "$BLINE" | awk -F',' '{print $2}')
#          BPL=$(echo "$BLINE" | awk -F',' '{print $3}')
#          BPW=$(echo "$BLINE" | awk -F',' '{print $4}')
#          BS=$(echo "$BLINE" | awk -F',' '{print $5}')
#          BL=$(echo "$BLINE" | awk -F',' '{print $6}')
#        BI1=$(echo "$BLINE" | awk -F',' '{print $7}')
#        BI2=$(echo "$BLINE" | awk -F',' '{print $8}')
#        BIN=$(echo "$BLINE" | awk -F',' '{print $9}')

        if [ "$j" -lt "$i" ] && [ "$APN" == "$BPN" ]; then
            D1=$(hammingDist $AI1 $BI1 $len1)
            if [ "$len2" != "0" ]; then
                D2=$(hammingDist $AI2 $BI2 $len2)
                if [ "$D1" -lt "3" ] && [ "$D2" -lt "3" ]; then
                    matrix[$i,$j]="$D1-$D2|x";
                else
                    matrix[$i,$j]="$D1-$D2";
                fi
                  if [ "$D1" -lt "3" ] && [ "$D2" -lt "3" ]; then
                    if($first); then
                        first=false;
                        printf "Pool Name,Pool Cycles,Row (A),Sample ID (A),Sample Name (A),Plate Name (A),Well (A),Index Name (A),Index1 (A),Index2 (A),Row (B),Sample ID (B),Sample Name (B),Plate Name (B),Well (B),Index Name (B),Index1 (B),Index2 (B),hamming distance\n" > "${filein%.*}".tmp
                    fi
                    printf "$APN,$len1-$len2,$i,$AP,$AS,$APL,$APW,$AIN,$AI1,$AI2,$j,$BP,$BS,$BPL,$BPW,$BIN,$BI1,$BI2,$D1-$D2\n" >> "${filein%.*}".tmp
                  fi
            else
                if [ "$D1" -lt "3" ]; then
                    matrix[$i,$j]="$D1|x";
                else
                    matrix[$i,$j]="$D1";
                fi
                  if [ "$D1" -lt "3" ]; then
                    if($first); then
                        first=false;
                        printf "Pool Name,Pool Cycles,Row (A),Sample ID (A),Sample Name (A),Plate Name (A),Well (A),Index Name (A),Index1 (A),Row (B),Sample Name (B),Sample Name (B),Plate Name (B),Well (B),Index Name (B),Index1 (B),hamming distance\n" > "${filein%.*}".tmp
                    fi
                    printf "$APN,$len1-$len2,$i,$AP,$AS,$APL,$APW,$AIN,$AI1,$j,$BP,$BS,$BPL,$BPW,$BIN,$BI1,$D1\n" >> "${filein%.*}".tmp
                  fi
            fi
        fi
    done
done

listfailed=$(cat "${filein%.*}".tmp)
rm "${filein%.*}".tmp

if($UDF); then

    udf=$(printf "Pub\tLUID Type\tLUID\tUDF Name\tPath/Value\n")

    foundfailure=false
    for ARTIFACTID in $(echo "$list"  | awk -F',' '{print $2}' | sort -u); do
        if [ -z "$(echo "$listfailed" | grep $ARTIFACTID)" ]; then
            udf=$(printf "$udf\n1\tUDF\t$ARTIFACTID\tPooling QC\tPass\n")
        else
            foundfailure=true            
            udf=$(printf "$udf\n1\tUDF\t$ARTIFACTID\tQC\tFail\n")
            udf=$(printf "$udf\n1\tUDF\t$ARTIFACTID\tPooling QC\tFail\n")
        fi
        
        # udf=$(printf "$udf\n1\tUDF\t$ARTIFACTID\tIndex Cycles\t$(echo "$list" | grep ",$ARTIFACTID," | awk -F ',' '{print $7}' | head -n 1 | tr -d '\n' | wc -c)-$(echo "$list" | grep ",$ARTIFACTID," | awk -F ',' '{print $8}' | head -n 1 | tr -d '\n' | wc -c)\n")
    done
    
    
    if ($foundfailure); then
       if [ "$NSTART" == "$NEND" ]; then
           udf=$(printf "$udf\n1\tUDF\t$PROCESSID\tPooling Status\tIndex:ERROR | Name:OK\n")
       else
           if [ -z "$POOLROOT" ]; then
               udf=$(printf "$udf\n1\tUDF\t$PROCESSID\tPooling Status\tIndex:ERROR | Name:FIXED\n")
           else
               udf=$(printf "$udf\n1\tUDF\t$PROCESSID\tPooling Status\tIndex:ERROR | Name:AUTO\n")
           fi
       fi
    else
       if [ "$NSTART" == "$NEND" ]; then
           udf=$(printf "$udf\n1\tUDF\t$PROCESSID\tPooling Status\tIndex:OK | Name:OK\n")
       else
           if [ -z "$POOLROOT" ]; then
               udf=$(printf "$udf\n1\tUDF\t$PROCESSID\tPooling Status\tIndex:OK | Name:FIXED\n")
           else
               udf=$(printf "$udf\n1\tUDF\t$PROCESSID\tPooling Status\tIndex:OK | Name:AUTO\n")
           fi
       fi
    fi
    
    udf=$(printf "$udf\n1\tUDF\t$PROCESSID\tPooling Count\t$NEND\n")

    for line in $(echo "$list" | awk -F',' '{print $1","$2}' | sort -u ); do
        POOLNAME=$(echo "$line" | awk -F',' '{print $1}' )
        ARTIFACTID=$(echo "$line" | awk -F',' '{print $2}' ) 
        udf=$(printf "$udf\n1\tUDF\t$ARTIFACTID\tPooling Group\t$POOLNAME\n")
    done

    # list="$POOLNAME,$POOLID,$PLATENAME,$WELL,$SAMPLE_NAME,$LIB_ID,$BCL2FASTQ_INDEX1,$BCL2FASTQ_INDEX2,$INDEX_NAME";

    declare -A poolfractionhash
    for POOLNAME in $(echo "$list" | awk -F',' '{print $1}' | sort -u); do
       POOLCOUNT=$(echo "$list" | grep "^$POOLNAME," | wc -l);
       poolfractionhash[$POOLNAME]=$(echo "scale=7;1/$POOLCOUNT" | bc -l | awk '{printf "%f", $0}')
    done

    for line in $(echo "$list" | awk -F',' '{print $1","$2}' | sort -u ); do
        POOLNAME=$(echo "$line" | awk -F',' '{print $1}' )
        ARTIFACTID=$(echo "$line" | awk -F',' '{print $2}' ) 
        FRAC=${poolfractionhash[$POOLNAME]}
        udf=$(printf "$udf\n1\tUDF\t$ARTIFACTID\tPooling Fraction\t$FRAC\n")
        # udf=$(printf "$udf\n1\tUDF\t$ARTIFACTID\tLane Fraction\t$FRAC\n")
    done

    echo "$udf" > "${filein%.*}".udfs.txt

fi


if [ -z "$listfailed" ]; then
    echo "<h3>No collisions found</h3>"
else
    coll_cnt=$(echo "$listfailed" | tail -n+2 | wc -l)
    if [ "$coll_cnt" == "1" ]; then
      S=""
    else
      S="s"
    fi
    echo "<h3>$coll_cnt collision$S found</h3>"
    echo "$listfailed" | htmltable style5
    echo "  By default bcl2fastq assumes that up to one mismatch is possible in each index (--mismatches 1), this is equivalent to a hamming distance of 2.<br>"
fi

# echo "<h3>Collision Matrix</h3>"

function dnr {
echo "<table border="0"><tr><td>"
echo "<div class='my-legend'>"
echo "<div class='legend-title'>Legend</div>"
echo "<div class='legend-scale'>"
echo "  <ul class='legend-labels'>"
echo "    <li><span style='background:#FF7777;'></span>ERROR: Index sequence are too close.</li>"
echo "    <li><span style='background:#"${sea[100]}";'></span>VALID: Index sequences are close but valid.</li>"
echo "    <li><span style='background:#"${sea[200]}";'></span>VALID: Index sequences are far appart.</li>"
echo "    <li><span style='background:#FFFFFF;'></span>VALID: Index sequences are compeletely different.</li>"
echo "    <li>Table contains Hamming distance (I1-I2 or I1).</li>"
echo "    <li>Table column and row numbers are defined in Library Details section below.</li>"
echo "  </ul>"
echo "</div>"
echo "</div>"
echo "</td></tr>"

echo "<tr><td>"

num_rows=$listlen
num_columns=$listlen

echo "<table border=\"1\" class=\"style3\">"
echo -n "<tr><th></th>"
for ((i=1;i<=num_columns;i++)) do
    echo -n "<th>$i</th>"
done
echo "</tr>"
for ((j=1;j<=num_rows;j++)) do
    echo -n "<tr>"
    echo -n "<th>$j</th>"
    for ((i=1;i<=num_columns;i++)) do
        a=$(echo "${matrix[$i,$j]}" | awk -F'|' '{print $1}')
        b=$(echo "${matrix[$i,$j]}" | awk -F'|' '{print $2}')
        D1=$(echo "$a" | awk -F'-' '{print $1}')
        D2=$(echo "$a" | awk -F'-' '{print $2}')
        color=' bgcolor="#F0F0F0"'
        if [ ! -z "${matrix[$i,$j]}" ]; then
          if [ "$b" == "x" ]; then
            color=' bgcolor="#FF7777"'
          else
            if [ -z "$D2" ]; then D2=0; fi
            color=' bgcolor="#'${sea[ $(( $(($D1+$D2)) * 255 / $(($maxlen1+$maxlen2)) ))]}'"'
          fi
        fi
        echo -n "<td$color>$a</td>"
    done
    echo "</tr>"
done
echo "</table>"

echo "</td></tr>"
echo "</table>"
}


# dnr

echo "<h3>Pooling Instructions</h3>"

plotplates

}



##########################################################################################




function get_collisions {

FILE=$1
SEQ_TYPE=$2
_INDEX1CYCLES=$3
_INDEX2CYCLES=$4


listin_fix0=$(tail -n +2 $FILE | grep -v "^$")

PROCESSID=$(echo "$listin_fix0" | awk -F ',' '{print $10}' | head -n 1)

declare -A poolcycleshash

NSTART=$(echo "$listin_fix0" |  awk -F',' '{print $1}' | sort -u | wc -l)
NPOOLSEP=$(echo "$listin_fix0" | awk -F ',' '{print $1}' | sort -u | grep -v "^$" | grep -c ':')

POOLROOT=""

if  [ "$NPOOLSEP" != "0" ]; then
  MASTERPOOLNAME=$(echo "$listin_fix0" | awk -F ',' '{print $1}' | sort -u | grep -v "^$" | grep ":" | head -n 1)
  POOLROOT=$(echo "$MASTERPOOLNAME" | awk -F':' '{print $1}')
  POOLINDEXSTART=$(echo "$MASTERPOOLNAME" |  awk -F':' '{print $2}' | sed 's/^0*//')
  POOLSIZE=$(echo "$MASTERPOOLNAME" | awk -F':' '{print $3}')

listin_tmp=$( for line in $(echo "$listin_fix0"); do
    POOLNAME=$(echo "$line" | awk -F',' '{print $1}')
    POOLID=$(echo "$line" | awk -F',' '{print $2}');
    POOLCYCLES=$(echo "$line" | awk -F',' '{print $3}');
    PLATENAME=$(echo "$line" | awk -F',' '{print $4}');
    WELL=$(echo "$line" | awk -F',' '{print $5}' )
    WELL2=$(echo "$line" | awk -F',' '{print $5}' | sed 's/:/0/g' | sed 's/010/10/g' | sed 's/011/11/g' | sed 's/012/12/g');
    SAMPLE_NAME=$(echo "$line" | awk -F',' '{print $6}');
    LIB_ID=$(echo "$line" | awk -F',' '{print $7}');
    LIBRARY_TYPE=$(echo "$line" | awk -F',' '{print $8}');
    INDEX_NAME=$(echo "$line" | awk -F',' '{print $9}');
    KEY=$(echo $PLATENAME | tr ' ' '_')_$(echo "$WELL2" | cut -c 2-)_$(echo "$WELL2" | cut -c 1)
    echo "$KEY,$POOLNAME,$POOLID,$POOLCYCLES,$PLATENAME,$WELL,$SAMPLE_NAME,$LIB_ID,$LIBRARY_TYPE,$INDEX_NAME"
done | sort -t ',' -k1 | awk -F',' '{print $2","$3","$4","$5","$6","$7","$8","$9","$10}')

cnt=0;
listin_fix1=$( for line in $(echo "$listin_tmp"); do    
    if [ "$cnt" == "$POOLSIZE" ]; then
       cnt=0;
       let POOLINDEXSTART=$POOLINDEXSTART+1;
    fi
    let cnt=$cnt+1;
    POOLNAME=${POOLROOT}$(printf "%03d" $POOLINDEXSTART);
    POOLID=$(echo "$line" | awk -F',' '{print $2}');
    POOLCYCLES=$(echo "$line" | awk -F',' '{print $3}');
    PLATENAME=$(echo "$line" | awk -F',' '{print $4}');
    WELL=$(echo "$line" | awk -F',' '{print $5}' );
    SAMPLE_NAME=$(echo "$line" | awk -F',' '{print $6}');
    LIB_ID=$(echo "$line" | awk -F',' '{print $7}');
    LIBRARY_TYPE=$(echo "$line" | awk -F',' '{print $8}');
    INDEX_NAME=$(echo "$line" | awk -F',' '{print $9}');
    echo "$POOLNAME,$POOLID,$POOLCYCLES,$PLATENAME,$WELL,$SAMPLE_NAME,$LIB_ID,$LIBRARY_TYPE,$INDEX_NAME"
done)
  
else
  listin_fix1=$listin_fix0;

  NEMPTY=$(echo "$listin_fix0" | awk -F ',' '{print $1}' | sort -u | grep -c "^$")
  if [ "$NEMPTY" == "0" ]; then
    :
  else
    return 1
  fi

fi


listin_fix=$( for line in $(echo "$listin_fix1"); do
    # POOLNAME=$(echo "$line" | awk -F',' '{print $1}');
    POOLNAME=$(echo "$line" | awk -F',' '{print $1}' | awk -F"\t" '{print $1}' | tr -s '[:space:]' |  sed 's/ /_/g' | tr -cd '[[:alnum:]]_')
    POOLID=$(echo "$line" | awk -F',' '{print $2}');
    POOLCYCLES=$(echo "$line" | awk -F',' '{print $3}');
    PLATENAME=$(echo "$line" | awk -F',' '{print $4}');
    WELL=$(echo "$line" | awk -F',' '{print $5}' | sed 's/:/0/g' | sed 's/010/10/g' | sed 's/011/11/g' | sed 's/012/12/g');
    SAMPLE_NAME=$(echo "$line" | awk -F',' '{print $6}');
    LIB_ID=$(echo "$line" | awk -F',' '{print $7}');
    LIBRARY_TYPE=$(echo "$line" | awk -F',' '{print $8}');
    INDEX_NAME=$(echo "$line" | awk -F',' '{print $9}');
    echo "$POOLNAME,$POOLID,$POOLCYCLES,$PLATENAME,$WELL,$SAMPLE_NAME,$LIB_ID,$LIBRARY_TYPE,$INDEX_NAME"
done | sort -t ',' -k1,1 -k4,4 -k5,5)

NEND=$(echo "$listin_fix" | grep -v "^$" |  awk -F',' '{print $1}' | sort -u | wc -l)

for POOLNAME in $(echo "$listin_fix" | awk -F',' '{print $1}' | sort -u); do
    POOLCYCLES=$(echo "$listin_fix" | grep "^$POOLNAME," | awk -F ',' '{print $3}' | sort -s '-' -nr -k1,1 -k2,2 | head -n 1)
    if [ -z "$POOLCYCLES" ]; then
        poolcycleshash[$POOLNAME]="8-8"
    else
        poolcycleshash[$POOLNAME]=$POOLCYCLES
    fi
done

listin=$( for line in $(echo "$listin_fix" ); do
    POOLNAME=$(echo "$line" | awk -F',' '{print $1}');
    POOLID=$(echo "$line" | awk -F',' '{print $2}');
    POOLCYCLES=${poolcycleshash[$POOLNAME]}
    PLATENAME=$(echo "$line" | awk -F',' '{print $4}');
    WELL=$(echo "$line" | awk -F',' '{print $5}' | sed 's/:/0/g' | sed 's/010/10/g' | sed 's/011/11/g' | sed 's/012/12/g');
    SAMPLE_NAME=$(echo "$line" | awk -F',' '{print $6}');
    LIB_ID=$(echo "$line" | awk -F',' '{print $7}');
    LIBRARY_TYPE=$(echo "$line" | awk -F',' '{print $8}');
    INDEX_NAME=$(echo "$line" | awk -F',' '{print $9}');
    echo "$POOLNAME,$POOLID,$POOLCYCLES,$PLATENAME,$WELL,$SAMPLE_NAME,$LIB_ID,$LIBRARY_TYPE,$INDEX_NAME"
done | sort -t ',' -k1,1 -k4,4 -k5,5)

list=""
listdetailed="Row,Pool Name,Artifact ID,Pool Cycles,Plate Name,Well,Sample Name,Library Type,Library ID,Index Name,Index1,Index2"
first=true
count=0
for line in $(echo "$listin" | grep -v "^$"); do

POOLNAME=$(echo "$line" | awk -F',' '{print $1}');
POOLID=$(echo "$line" | awk -F',' '{print $2}');
POOLCYCLES=$(echo "$line" | awk -F',' '{print $3}');
PLATENAME=$(echo "$line" | awk -F',' '{print $4}');
WELL=$(echo "$line" | awk -F',' '{print $5}');
SAMPLE_NAME=$(echo "$line" | awk -F',' '{print $6}');
LIB_ID=$(echo "$line" | awk -F',' '{print $7}');
LIBRARY_TYPE=$(echo "$line" | awk -F',' '{print $8}');
INDEX_NAME=$(echo "$line" | awk -F',' '{print $9}');


UDF=false
if [ "$_INDEX1CYCLES" == "0" ] && [ "$_INDEX2CYCLES" == "0" ]; then
    UDF=true
    INDEX1CYCLES=$(echo "$POOLCYCLES" | awk -F'-' '{print $1}');
    INDEX2CYCLES=$(echo "$POOLCYCLES" | awk -F'-' '{print $2}');
else
    INDEX1CYCLES=$_INDEX1CYCLES
    INDEX2CYCLES=$_INDEX2CYCLES
fi

if [ "$INDEX2CYCLES" == "0" ]; then
    INDEX_TYPE=SINGLE_INDEX;
else
    INDEX_TYPE=DUAL_INDEX;
fi

LIB_STRUCTURE=$(grep "^$LIBRARY_TYPE," $LIBRARY_PROTOCOL_LIST | awk -F',' '{print $3}')

if [ -z "$LIB_STRUCTURE" ]; then
    if [[ "$INDEX_NAME" == SI-* ]]; then
        KEY=$INDEX_NAME;
    else
        KEY=$(echo "$INDEX_NAME" | awk -F'-' '{print $1}');
    fi
    LIB_STRUCTURE=$( grep "$KEY," $ADAPTER_TYPES_FILE | awk -F',' '{print $2}' | head -n 1);
fi

for VAL in $(getindex); do
let count=$count+1
    BCL2FASTQ_SAMPLE_NAME=$(echo $VAL | awk -F, '{print $1}');
    BCL2FASTQ_INDEX1=$(echo $VAL | awk -F, '{print $2}');
    BCL2FASTQ_INDEX2=$(echo $VAL | awk -F, '{print $3}');
    if($first); then
        first=false;
        list="$POOLNAME,$POOLID,$PLATENAME,$WELL,$SAMPLE_NAME,$LIB_ID,$BCL2FASTQ_INDEX1,$BCL2FASTQ_INDEX2,$INDEX_NAME";
    else
        list=$(printf "$list\n$POOLNAME,$POOLID,$PLATENAME,$WELL,$SAMPLE_NAME,$LIB_ID,$BCL2FASTQ_INDEX1,$BCL2FASTQ_INDEX2,$INDEX_NAME");
    fi
    listdetailed=$(printf "$listdetailed\n$count,$POOLNAME,$POOLID,$POOLCYCLES,$PLATENAME,$WELL,$SAMPLE_NAME,$LIBRARY_TYPE,$LIB_ID,$INDEX_NAME,$BCL2FASTQ_INDEX1,$BCL2FASTQ_INDEX2");
done

done

collision_matrix $UDF


echo "<h3>Library Details</h3>"
echo "$listdetailed" | htmltable style4
 
}




function makematrix {

CODE=$(cat <<EOF
<!doctype html><html><head><title>Collision Matrix</title>

<meta name="viewport" content="width=device-width, initial-scale=1">

<style>

table.style1 { border-collapse: collapse; border: 1px solid black; border-style: solid; }
table.style1 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }
table.style1 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }

table.style2 { border: 1px solid #A0A0A0; border-style: solid; font-size: 12px;}
table.style2 th { text-align: center; border: 1px solid #A0A0A0; width: 20px; height: 20px; padding: 1px; }
table.style2 td { text-align: center; border: 1px solid #A0A0A0; width: 20px; height: 20px; padding: 1px; }

table.style3 { border-collapse: collapse; border: 1px solid black; border-style: solid; font-size: 10px;}
table.style3 th { text-align: center; border: 1px solid black; border-style: solid; padding: 1px; background: #C0C0C0; width: 15px; }
table.style3 td { text-align: center; border: 1px solid black; border-style: solid; padding: 1px; width: 15px; }

table.style4 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }
table.style4 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; background: #C0C0C0;}
table.style4 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }

table.style5 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }
table.style5 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; background: #C0C0C0;}
table.style5 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; background: #FF7777; }

body {font-family: Arial;}

/* Style the tab */
.tab {
    overflow: hidden;
    border: 1px solid #ccc;
    background-color: #f1f1f1;
}

/* Style the buttons inside the tab */
.tab button {
    background-color: inherit;
    float: left;
    border: none;
    outline: none;
    cursor: pointer;
    padding: 14px 16px;
    transition: 0.3s;
    font-size: 17px;
}

/* Change background color of buttons on hover */
.tab button:hover {
    background-color: #ddd;
}

/* Create an active/current tablink class */
.tab button.active {
    background-color: #ccc;
}

/* Style the tab content */
.tabcontent {
    display: none;
    padding: 6px 12px;
    border: 1px solid #ccc;
    border-top: none;
}

/* Style the legend */

  .my-legend .legend-title {
    text-align: left;
    margin-bottom: 5px;
    font-weight: bold;
    font-size: 90%;
    }
  .my-legend .legend-scale ul {
    margin: 0;
    margin-bottom: 5px;
    padding: 0;
    float: left;
    list-style: none;
    }
  .my-legend .legend-scale ul li {
    font-size: 80%;
    list-style: none;
    margin-left: 0;
    line-height: 18px;
    margin-bottom: 2px;
    }
  .my-legend ul.legend-labels li span {
    display: block;
    float: left;
    height: 16px;
    width: 30px;
    margin-right: 5px;
    margin-left: 0;
    border: 1px solid #999;
    }
  .my-legend .legend-source {
    font-size: 70%;
    color: #999;
    clear: both;
    }
  .my-legend {
    clear: both;
    }


</style>
</head>
<body>

<div class="tab">
EOF
);


#####################################################
SEQ_TYPE=novaseq; INDEX1CYCLES="0"; INDEX2CYCLES="0"; TABSTR="Collision Report"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
CODE="$CODE"$(cat <<EOF
  <button class="tablinks" onclick="openCity(event, '$TABSTR')" id="defaultOpen">$TABSTR</button>
EOF
);


#####################################################
# SEQ_TYPE=novaseq; INDEX1CYCLES=8; INDEX2CYCLES=8; TABSTR="I1:${INDEX1CYCLES} I2:${INDEX2CYCLES}"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
# CODE="$CODE"$(cat <<EOF
#   <button class="tablinks" onclick="openCity(event, '$TABSTR')" >$TABSTR</button>
# EOF
# );

#####################################################
# SEQ_TYPE=novaseq; INDEX1CYCLES=8; INDEX2CYCLES=0; TABSTR="I1:${INDEX1CYCLES} I2:${INDEX2CYCLES}"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
# CODE="$CODE"$(cat <<EOF
#   <button class="tablinks" onclick="openCity(event, '$TABSTR')" >$TABSTR</button>
# EOF
# );

#####################################################
# SEQ_TYPE=novaseq; INDEX1CYCLES=10; INDEX2CYCLES=8; TABSTR="I1:${INDEX1CYCLES} I2:${INDEX2CYCLES}"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
# CODE="$CODE"$(cat <<EOF
#  <button class="tablinks" onclick="openCity(event, '$TABSTR')" >$TABSTR</button>
# EOF
# );


######################################################
#TABSTR="Library Structure + Index";
#CODE="$CODE"$(cat <<EOF
#  <button class="tablinks" onclick="openCity(event, '$TABSTR')" >$TABSTR</button>
#EOF
#);

#####################################################
TABSTR="UDF File";
CODE="$CODE"$(cat <<EOF
  <button class="tablinks" onclick="openCity(event, '$TABSTR')" >$TABSTR</button>
EOF
);

#####################################################
TABSTR="Input File";
CODE="$CODE"$(cat <<EOF
  <button class="tablinks" onclick="openCity(event, '$TABSTR')" >$TABSTR</button>
EOF
);

CODE="$CODE"$(cat <<EOF
</div>
EOF
);


#####################################################
SEQ_TYPE=novaseq; INDEX1CYCLES="0"; INDEX2CYCLES="0"; TABSTR="Collision Report"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
CODE="$CODE"$(cat <<EOF
<div id="$TABSTR" class="tabcontent">
  <h3>$TABSTR</h3>
  $(get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES)
</div>
EOF
);

#####################################################
# SEQ_TYPE=novaseq; INDEX1CYCLES=8; INDEX2CYCLES=8; TABSTR="I1:${INDEX1CYCLES} I2:${INDEX2CYCLES}"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
# CODE="$CODE"$(cat <<EOF
# <div id="$TABSTR" class="tabcontent">
# <h3>Index cycles used: $TABSTR</h3>
#   $(get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES)
# </div>
# EOF
# );

#####################################################
# SEQ_TYPE=novaseq; INDEX1CYCLES=8; INDEX2CYCLES=0; TABSTR="I1:${INDEX1CYCLES} I2:${INDEX2CYCLES}"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
# CODE="$CODE"$(cat <<EOF
# <h3>Index cycles used: $TABSTR</h3>
# <div id="$TABSTR" class="tabcontent">
#   $(get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES)
# </div>
# EOF
# );

#####################################################
# SEQ_TYPE=novaseq; INDEX1CYCLES=10; INDEX2CYCLES=8; TABSTR="I1:${INDEX1CYCLES} I2:${INDEX2CYCLES}"; # get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES
# CODE="$CODE"$(cat <<EOF
# <div id="$TABSTR" class="tabcontent">
#  <h3>Index cycles used: $TABSTR</h3>
#   $(get_collisions $filein $SEQ_TYPE $INDEX1CYCLES $INDEX2CYCLES)
# </div>
# EOF
# );


######################################################
#TABSTR="Library Structure + Index";
#CODE="$CODE"$(cat <<EOF
#<div id="$TABSTR" class="tabcontent">
#  <h3>$TABSTR</h3>
#   <h4>$INSTRUMENT_LIST</h4>
#   $(cat $INSTRUMENT_LIST | grep -v "^$" | htmltable style4)
#   <h4>$INDEX_DEF_FILE</h4>
#   <pre>$(cat $INDEX_DEF_FILE)</pre>
#   <h4>$LIBRARY_PROTOCOL_LIST</h4>
#   $(cat $LIBRARY_PROTOCOL_LIST | htmltable style4)
#   <h4>$ADAPTER_TYPES_FILE</h4>
#   <pre>$(cat $ADAPTER_TYPES_FILE )</pre>
# </div>
#EOF
#);

#####################################################
TABSTR="UDF File";
CODE="$CODE"$(cat <<EOF
<div id="$TABSTR" class="tabcontent">
  <h3>$TABSTR</h3>
  <pre>$(cat "${filein%.*}".udfs.txt | tr '\t' ',' | htmltable style4)</pre>
</div>
EOF
);



#####################################################
TABSTR="Input File";
CODE="$CODE"$(cat <<EOF
<div id="$TABSTR" class="tabcontent">
  <h3>$TABSTR</h3>
  <pre>$(cat "$filein" | htmltable style4)</pre>
</div>
EOF
);




CODE="$CODE"$(cat <<EOF
<script>
function openCity(evt, cityName) {
    var i, tabcontent, tablinks;
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }
    document.getElementById(cityName).style.display = "block";
    evt.currentTarget.className += " active";
}

// Get the element with id="defaultOpen" and click on it
document.getElementById("defaultOpen").click();
</script>
     
</body>
</html> 
EOF
);


echo "$CODE" > "${filein%.*}".html

}


if [ -z "$1" ]; then
    echo "Please specify input file."
else

filein=$1
SRCDIR=$2

. $SRCDIR/col2.sh

INDEX_DEF_FILE=$SRCDIR/adapter_settings_format.txt
ADAPTER_TYPES_FILE=$SRCDIR/adapter_types.txt
INSTRUMENT_LIST=$SRCDIR/instrument_list.csv
LIBRARY_PROTOCOL_LIST=$SRCDIR/library_protocol_list.csv

    makematrix

fi

