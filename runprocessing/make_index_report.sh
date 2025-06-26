#!/bin/bash

function dnr {
    
    # INSTRUMENT=novaseq; FCID=210806_A00266_0577_AHG5L7DSX2_PratQ003041KhazaeiQ002321LimQ003021JabadoQ003621; LANE=1;
    # INSTRUMENT=novaseq; FCID=210806_A00266_0577_AHG5L7DSX2_PratQ003041KhazaeiQ002321LimQ003021JabadoQ003621; LANE=2;
    # INSTRUMENT=novaseq; FCID=210709_A00266_0569_AHGY23DSX2_JabadoAppleton; LANE=3;

    INSTRUMENT=novaseq; FCID=210709_A00266_0569_AHGY23DSX2_JabadoAppleton; LANE=4;    
    # INSTRUMENT=novaseq; FCID=210709_A00266_0569_AHGY23DSX2_JabadoAppleton; LANE=1;
    metricsfile=$(ls /lb/scratch/hdjambaz/processing/$FCID-$INSTRUMENT/index/*$LANE.metrics);
    csvfile=/lb/scratch/hdjambaz/processing/$FCID-$INSTRUMENT/$FCID.pipelinesamplesheet.split_on_lanes.csv;
    file=$metricsfile.metrics-table.html;
    sh make_index_report.sh $metricsfile $csvfile $LANE;
    echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca;

    INSTRUMENT=novaseq; FCID=210709_A00266_0569_AHGY23DSX2_JabadoAppleton; LANE=3;    
    # INSTRUMENT=novaseq; FCID=210709_A00266_0569_AHGY23DSX2_JabadoAppleton; LANE=1;
    metricsfile=$(ls /lb/scratch/hdjambaz/processing/$FCID-$INSTRUMENT/index/*$LANE.metrics);
    csvfile=/lb/scratch/hdjambaz/processing/$FCID-$INSTRUMENT/$FCID.pipelinesamplesheet.split_on_lanes.csv;
    file=$metricsfile.metrics-table.html;
    sh make_index_report.sh $metricsfile $csvfile $LANE;
    echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca;

}

metricsfile=$1;
csvfile=$2;
LANE=$3;

# str="JAB1322,NJ_10X-multiome_Feb2021_Q003621,JAB1322A8-1,S-9582_MultiOme_scATAQ_HSJ-192manual,JAB1322A8,SI-NA-A40,$LANE,2-1666770,10x Genomics Single Cell ATAC,TruSeqHT,default RNA,Homo_sapiens:GRCh38,N/A,N/A,151-254284,Eukaryota:Homo sapiens (Taxon ID:9606),3257.32,N/A,0.0238095,N/A,N/A,N/A,N/A,N/A,2-1667469,N/A,Truseq Stranded RNA core LP,N/A,N/A,N/A"
# EXPECTED=$((printf "$str\n"; cat $csvfile ) | awk -F',' '$7=='$LANE'{print $6 "\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $7 "\t" $8 "\t" $9 "\t" $19}');

IFS=$'\n'

INDEXFOUND=$(
    cat $metricsfile | tr -d ' ' | grep -v "^#" | grep -v "^$" | awk -F '\t' '{print $3 "\t"$1 "\t"$2}' | head -n 1;
    cat $metricsfile | tr -d ' ' | grep -v "^#" | grep -v "^$" | tail -n +2 | sort -nr -k3 | awk -F '\t' '{print $3 "\t"$1 "\t" $2}' 
);

EXPECTED=$(cat $csvfile | awk -F',' '$7=='$LANE'{print $6 "\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $7 "\t" $8 "\t" $9 "\t" $19}');

TOTALREADS=$(cat $metricsfile | tail -n+8 | awk -F '\t' '{sum += $3} END {print sum}');

v=$(for line in $(echo "$EXPECTED"); do 
    INDEX=$(echo "$line" | awk -F'\t' '{print $1}')
    if [[ "$INDEX" == SI-* ]]; then
	:
    else
	INDEX=$(echo "$INDEX" | awk -F'-' '{print $1}')
    fi
    COUNT=$(cat $metricsfile | tr -d ' ' | grep -v "^#" | grep -v "^$" | tail -n +2 | sort -nr -k3 | awk -F '\t' '{print $3 "\t"$1 "\t" "," $2 ","}' \
	| sed 's/(A)//g' | sed 's/(B)//g' | sed 's/(C)//g' | sed 's/(D)//g' \
	| grep ",$INDEX," | awk -F'\t' 'BEGIN {sum=0 };{sum+=$1} END {print sum}');
    printf "$COUNT\t$line\n"
done | awk -F'\t' '{print $1/'$TOTALREADS'/$11 "\t" $0}' | sort -t $'\t' -nk2
);

w=$(for line in $(echo "$EXPECTED"); do 
    INDEX=$(echo "$line" | awk -F'\t' '{print $1}')
    if [[ "$INDEX" == SI-* ]]; then
	:
    else
	INDEX=$(echo "$INDEX" | awk -F'-' '{print $1}')
    fi
    cat $metricsfile | tr -d ' ' | grep -v "^#" | grep -v "^$" | tail -n +2 | sort -nr -k3 | awk -F '\t' '{print $3 "\t"$1 "\t" "," $2 ","}' \
	| sed 's/(A)/,(A)/g' | sed 's/(B)/,(B)/g' | sed 's/(C)/,(C)/g' | sed 's/(D)/,(D)/g' \
	| grep ",$INDEX," \
	| sed 's/,(A)/(A)/g' | sed 's/,(B)/(B)/g' | sed 's/,(C)/(C)/g' | sed 's/,(D)/(D)/g' | head -n 20; 
done |  awk '{print $1 "\t" $2 "\t" substr($3,2)} '| rev | cut -c 2- | rev;
);

LOWYIELD=$(echo "$v" | awk -F'\t' '($1<0.5){print $0}')
LOWYIELDCOUNT=$(echo "$LOWYIELD" | grep -v "^$" |  wc -l);

(echo "Pct from Expected,Read Count,Index Name,Project ID,Project Name,Library ID,Sample Name,Sample ID,Flowcell lane,Data ID,Library Type,Pool Fraction";
 echo "$LOWYIELD") > $metricsfile.low-or-no-yield

cat $metricsfile | tr -d ' ' | grep -v "^#" | grep -v "^$" | tail -n +2 | sort -nr -k3 | awk -F '\t' '{print $3 "\t"$1 "\t" "," $2 ","}' \
    | sed 's/(A)//g' | sed 's/(B)//g' | sed 's/(C)//g' | sed 's/(D)//g' | awk -F'\t' '$1>5000{print $0}'>  $metricsfile.unexpected

for line in $(echo "$EXPECTED"); do
    INDEX=$(echo "$line" | awk -F'\t' '{print $1}')
    if [[ "$INDEX" == SI-* ]]; then
	:
    else
	INDEX=$(echo "$INDEX" | awk -F'-' '{print $1}')
    fi
    cat $metricsfile.unexpected | grep -v ",$INDEX," >  $metricsfile.unexpected.tmp
    mv  $metricsfile.unexpected.tmp  $metricsfile.unexpected
done
cat $metricsfile.unexpected | awk '{print $1 "\t" $2 "\t" substr($3,2)}' | rev | cut -c 2- | rev | grep -v "\.\.\.\.\.\.\.\."  >  $metricsfile.unexpected.tmp
mv  $metricsfile.unexpected.tmp  $metricsfile.unexpected

(
echo "<"'!'"doctype html><html><head><title>$(basename $metricsfile)</title>";
echo "<style>";
echo "table.style1 { border-collapse: collapse; border: 1px solid black; border-style: solid; }";
echo "table.style1 th { text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }";
echo "table.style1 td { text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }";
echo "table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }";
echo "table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }";
echo "table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }";
echo "table.style3 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }";
echo "table.style3 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; }";
echo "table.style3 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }";
echo ".button {  font: bold 11px Arial;  text-decoration: none;  background-color: #EEEEEE;  color: #333333;  padding: 2px 6px 2px 6px;  border-top: 1px solid #CCCCCC;  border-right: 1px solid #333333; border-bottom: 1px solid #333333; border-left: 1px solid #CCCCCC;}";
echo ".red { background-color: #FF7777;}"
echo ".green { background-color: #77FF77;}"
echo "</style>";
echo "</head>"
echo "<body>"
echo "<a id=\"TOP\"></a>"

echo "<a href=\"#EXPECTLOW\" class=\"button\">Jump to: Expected index with low or no yield.</a><br>"
echo "<br>"
echo "<a href=\"#EXPECTCOUNTS\" class=\"button\">Jump to: Expected index read counts.</a><br>"
echo "<a href=\"#EXPECTBREAKDOWN\" class=\"button\">Jump to: Expected index read counts (breakdown).</a><br>"
echo "<br>"
echo "<a href=\"#UNEXPECTEXPECTBREAKDOWN\" class=\"button\">Jump to: Unexpected index read counts.</a><br>"
echo "<br>"
echo "<br>"

echo "<a id=\"EXPECTLOW\"></a>"
echo "<br>"
echo "<h2>Expected index with low or no yield (yield < 50% of expected)</h2>";
if [ "$LOWYIELDCOUNT" == "0" ]; then
    echo "<span class=\"green\">No samples with low or no yield. Everything is ok.</span><br><br>";
else
    echo "<span class=\"red\">Samples with low or no yield were found. Problem was detected.</span><br><br>";
    echo "<table class=\"style2\">"
    printf "Pct from Expected\tRead Count\tIndex Name\tProject ID\tProject Name\tLibrary ID\tSample Name\tSample ID\tFlowcell lane\tData ID\tLibrary Type\tPool Fraction\n" \
	| sed "s|$(printf '\t')|</th><th>|g" | awk '{print "<tr><th>"$0"</th></tr>"}';
    echo "$LOWYIELD" | LC_ALL=en_US.UTF-8 awk -F'\t' '{OFS="\t"; $2=sprintf("%'"'"'i",$2); print $0}' | sed "s|$(printf '\t')|</td><td>|g" | awk '{print "<tr><td>"$0"</td></tr>"}';
    echo "</table>"
fi
echo "<a href=\"#TOP\" class=\"button\">Back to top of page.</a><br>"

echo "<a id=\"EXPECTCOUNTS\"></a>"
echo "<br>"
echo "<h2>Expected index read counts (including low or no yield)</h2>";
echo "<table class=\"style2\">"
printf "Pct from Expected\tRead Count\tIndex Name\tProject ID\tProject Name\tLibrary ID\tSample Name\tSample ID\tFlowcell lane\tData ID\tLibrary Type\tPool Fraction\n" \
    | sed "s|$(printf '\t')|</th><th>|g" | awk '{print "<tr><th>"$0"</th></tr>"}';
echo "$v" | sort -t $'\t' -nrk1 | LC_ALL=en_US.UTF-8 awk -F'\t' '{OFS="\t"; $2=sprintf("%'"'"'i",$2); print $0}' | sed "s|$(printf '\t')|</td><td>|g" | awk '{print "<tr><td>"$0"</td></tr>"}';
echo "</table>"
echo "The counts from CountIlluminaBarcodes will not exactly match the counts from bcl2fastq because the algorithms differ.<br>";
echo "<a href=\"#TOP\" class=\"button\">Back to top of page.</a><br>"

echo "<a id=\"EXPECTBREAKDOWN\"></a>"
echo "<br>"
echo "<h2>Expected index read counts (CountIlluminaBarcodes breakdown per index, top 20 per index).</h2>";
echo "<table class=\"style2\">"
printf "Read Count\tSequence\tIndex Names\n" | sed "s|$(printf '\t')|</th><th>|g" | awk '{print "<tr><th>"$0"</th></tr>"}';
echo "$w" | LC_ALL=en_US.UTF-8 awk -F'\t' '{OFS="\t"; $1=sprintf("%'"'"'i",$1); print $0}' | sed "s|$(printf '\t')|</td><td>|g" | awk '{print "<tr><td>"$0"</td></tr>"}';
echo "</table>"
echo "<a href=\"#TOP\" class=\"button\">Back to top of page.</a><br>"

echo "<a id=\"UNEXPECTEXPECTBREAKDOWN\"></a>"
echo "<br>"
echo "<h2>Unexpected index read counts (showing counts>5000)</h2>";
echo "<table class=\"style2\">"
printf "Read Count\tSequence\tIndex Names\n" | sed "s|$(printf '\t')|</th><th>|g" | awk '{print "<tr><th>"$0"</th></tr>"}';
cat $metricsfile.unexpected | LC_ALL=en_US.UTF-8 awk -F'\t' '{OFS="\t"; $1=sprintf("%'"'"'i",$1); print $0}' | sed "s|$(printf '\t')|</td><td>|g" | awk '{print "<tr><td>"$0"</td></tr>"}';
echo "</table>"
echo "<a href=\"#TOP\" class=\"button\">Back to top of page.</a><br>"

echo "</body>"
) > $metricsfile-table.html

# LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i",$1}'
# | LC_ALL=en_US.UTF-8 awk -F'\t' '{OFS="\t"; $1=sprintf("%'"'"'i",$1); print $0}'
