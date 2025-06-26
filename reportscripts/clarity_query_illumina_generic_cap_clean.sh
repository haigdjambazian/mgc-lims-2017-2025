#!/bin/bash

#title           : clarity_query_illumina_generic_cap_clean.sh
#description     : This script extract run processing metrics metadata from Clarity and generated reports in html per project
#author          : Haig Djambazian
#date            : 20200812
#version         : 1.0
#usage           : cd /lb/robot/GeneTitan/bravoprocess/system/illuminareports/
#usage           : . clarity_query_illumina_generic_cap_clean.sh; runtimestamp

#DATABASECRED=postgresql://hdjambaz:$PASSWORD@127.0.0.1/ClarityLIMS
DATABASECRED=ClarityLIMS

function runtimestamp {

TIMESTAMP_BOOTSTRAP=$(date +%FT%H.%M.%S).tmp; mkdir -p $TIMESTAMP_BOOTSTRAP
touch $TIMESTAMP_BOOTSTRAP/$(echo $TIMESTAMP_BOOTSTRAP | sed 's/.tmp//g').missing.txt
time ( run "HiSeq X" $TIMESTAMP_BOOTSTRAP; run "NovaSeq" $TIMESTAMP_BOOTSTRAP; run "MiSeq" $TIMESTAMP_BOOTSTRAP; run "iSeq" $TIMESTAMP_BOOTSTRAP ) > $TIMESTAMP_BOOTSTRAP/log_hiseqx_novaseq_miseq_iseq.txt 2>&1 && \
tail  $TIMESTAMP_BOOTSTRAP/log_hiseqx_novaseq_miseq_iseq.txt && \
(withheaderfilt $TIMESTAMP_BOOTSTRAP) && \
cat $TIMESTAMP_BOOTSTRAP/illumina_report_HiSeqX.txt $TIMESTAMP_BOOTSTRAP/illumina_report_NovaSeq.txt $TIMESTAMP_BOOTSTRAP/illumina_report_MiSeq.txt $TIMESTAMP_BOOTSTRAP/illumina_report_iSeq.txt \
  | awk -F'\t' '$135==1{print $91 "\t"$19 "\t" $13 "\t" $0 }' | awk '$2=="\\N"{print $0}'| awk -F'\t' '{print $1"\t"$3}' >  $TIMESTAMP_BOOTSTRAP/$TIMESTAMP_BOOTSTRAP.missing.txt && \
( wc -l $TIMESTAMP_BOOTSTRAP.missing.txt || true ) && \
sh /robot/GeneTitan/bravoprocess/system/illuminareports/runvalidtable.sh $TIMESTAMP_BOOTSTRAP && \
echo $TIMESTAMP_BOOTSTRAP && mv $TIMESTAMP_BOOTSTRAP $(echo $TIMESTAMP_BOOTSTRAP | sed 's/.tmp//g') &

}

function keepcols {

awk -v cols="$1" 'BEGIN {
    FS=OFS="\t";
    nc=split(cols, a, "\t")
}
NR==1 {
    for (i=1; i<=NF; i++)
        hdr[$i]=i
}
{
   for (i=1; i<=nc; i++)
       if (a[i] in hdr)
           printf "%s%s", $hdr[a[i]], (i<nc?OFS:ORS)
   printf "\n"
}' "$2"

}


function keepcols2 {

FILT=$(echo "$v" | awk '{print NR"\t"$0}' | grep -E "$(echo "$w" | tr '\n' '|' | rev | cut -c  2- | rev)" | awk '{print "$"$1}' | tr '\n' ',' | rev | cut -c  2- | rev| sed 's/,/"\\t"/g')
cat "$1" | awk -F'\t' '{print '$FILT'}'

}



function withheaderfilt {

DATEFLDR="$1"

v="PROJECT_ID
PROJECT_NAME
SAMPLENAME
LIBRARY_TYPE
thisinputprocess
LIBRARY_ID
Date
reagentlabel
Library Volume (ul)
Sample Tag
thisprocessname1
thisprocess1
thisoutputanalyte1
CONTAINER1_CAPTURE
WELL1
Run Count
Run Folder Name
Run ID
Data Directory
Processing Folder Name
Flowcell Lane
Clusters
Bases
Avg. Qual
Dup. Rate (%)
R1 Top Blast Hit Name
R1 Top Blast Hit Rate (%)
R2 Top Blast Hit Name
R2 Top Blast Hit Rate (%)
Top Sample Tag Name
Top Sample Tag Rate from Total (%)
Top Sample Tag Rate from All Detected (%)
Expected Sample Tag Name
Top Sample Tag Name Match
Clusters on Index in Lane (%)
Clusters on Index in Lane from Target (%)
Reference
Bed
PF Reads Aligned All
PF Reads Aligned All (%)
PF Reads Aligned R1 (%)
PF Reads Aligned R2 (%)
Chimeras (%)
Adapter (%)
Mapped Insert Size (median)
Mapped Insert Size (mean)
Mapped Insert Size (std. dev.)
Aligned Dup. Rate (%)
Mean Coverage
Bases Covered at 10x (%)
Bases Covered at 25x (%)
Bases Covered at 50x (%)
Bases Covered at 75x (%)
Bases Covered at 100x (%)
Aligned Bases On Target (%)
On Bait Bases from On Target Bases (%)
Freemix Number of SNP
Freemix Value
chr1 Normalized Coverage
chr2 Normalized Coverage
chr3 Normalized Coverage
chr4 Normalized Coverage
chr5 Normalized Coverage
chr6 Normalized Coverage
chr7 Normalized Coverage
chr8 Normalized Coverage
chr9 Normalized Coverage
chr10 Normalized Coverage
chr11 Normalized Coverage
chr12 Normalized Coverage
chr13 Normalized Coverage
chr14 Normalized Coverage
chr15 Normalized Coverage
chr16 Normalized Coverage
chr17 Normalized Coverage
chr18 Normalized Coverage
chr19 Normalized Coverage
chr20 Normalized Coverage
chr21 Normalized Coverage
chr22 Normalized Coverage
chrX Normalized Coverage
chrY Normalized Coverage
chrM Normalized Coverage
Data Release
thisprocessname2
thisprocess2
PLATENAME2
WELL2
thisprocessname3
thisprocess3
FLOWCELL_ID
FLOWCELL_LANE
Start Date
Experiment Name
HiSeq Used
cBot Used
Flowcell ID
Flowcell Lot
PhiX v3
NaOH 2N
cBot Cartridge
cBot Reagent Kit ID
PE Clusters Kit
Manifold
SBS Kit (Box Room Temp.)
SBS Kit (Box -20C)
ExAmp Box Lot
Yield PF (Gb) R1
Yield PF (Gb) R2
% Bases >=Q30 R1
% Bases >=Q30 R2
Cluster Density (K/mm^2) R1
Cluster Density (K/mm^2) R2
Clusters Raw R1
Clusters Raw R2
Clusters PF R1
Clusters PF R2
%PF R1
%PF R2
Intensity Cycle 1 R1
Intensity Cycle 1 R2
% Intensity Cycle 20 R1
% Intensity Cycle 20 R2
% Phasing R1
% Phasing R2
% Prephasing R1
% Prephasing R2
% Aligned R1
% Aligned R2
% Error Rate R1
% Error Rate R2
thisprocessname4
thisprocess4
tmpthisoutputanalyte4
QC
workstatus
Comments"


w="PROJECT_ID
PROJECT_NAME
Processing Folder Name
Run ID
SAMPLENAME
LIBRARY_TYPE
LIBRARY_ID
reagentlabel
CONTAINER1_CAPTURE
Clusters
Bases
Avg. Qual
Dup. Rate (%)
Aligned Dup. Rate (%)
Mean Coverage
FLOWCELL_ID
FLOWCELL_LANE
workstatus
Data Directory"


ww="PROJECT_ID
PROJECT_NAME
SAMPLENAME
LIBRARY_ID
Aligned Dup. Rate (%)
Mean Coverage
SAMPLENAME.LIBRARY_ID.Run ID.FLOWCELL_LANE"


# paste <(echo "$v") <(grep $PROJECTNAME illumina_report_HiSeqX.txt | rev | awk '$1==1{print $0}' | awk '$2!=2{print $0}' | rev | tail -n 1 | tr '\t' '\n') | column -s$'\t' -t | less -S


HTMLFILE=$DATEFLDR/projects/project-index.html
rm -r $DATEFLDR/projects
rm -f $HTMLFILE
mkdir $DATEFLDR/projects
touch $DATEFLDR/projects/index.html

STYLE=$(cat <<EOF
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table.style1 { border-collapse: collapse; border: 1px solid black; border-style: solid; }
table.style1 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }
table.style1 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }
table.style2 { border-collapse: collapse; border: 1px solid #A0A0A0; border-style: solid; font-size: 12px;}
table.style2 th { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
table.style2 td { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
body {font-family: Arial;}
</style>
EOF
);



echo "<html><head><title></title>" >> $HTMLFILE
echo "$STYLE" >> $HTMLFILE
echo "</head><body>" >> $HTMLFILE

echo "$(date)<br>" >> $HTMLFILE
echo "<h1>project list (Illumina Runs)</h1>" >> $HTMLFILE

TAB="$(printf '\t')"

echo "<table class=\"style2\">" >> $HTMLFILE

echo "<tr><th>Project name</th><th>ProjectID</th><th>Basic DataSet Table</th><th>Full DataSet Table</th><th>Coverage Table (Human)</th></tr>" >> $HTMLFILE

    echo '<tr style="height: 15px;"/><td  colspan="5">&nbsp;</td></tr>' >> $HTMLFILE;
    PROJECTNAME="ALL_PROJECTS"
    PROJECTID="Validated"
    echo ${PROJECTNAME}_${PROJECTID}
    mkdir -p $DATEFLDR/projects/${PROJECTNAME}_${PROJECTID};
    FULL=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.full;
    BASIC=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.basic;
    OUTFULL=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.txt;
    OUTBASIC=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.txt;
    rm -f $OUTFULL $OUTBASIC;
    OUTFULLHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.html; 
    OUTBASICHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.html;
    rm -f $OUTFULLHTML $OUTBASICHTML;
    ###
    echo "$v" | tr '\n' '\t' | rev | cut -c 2- | rev >> $OUTFULL;
    cat $DATEFLDR/illumina_report_HiSeqX.txt $DATEFLDR/illumina_report_NovaSeq.txt $DATEFLDR/illumina_report_iSeq.txt $DATEFLDR/illumina_report_MiSeq.txt  | awk -F'\t' '$135==1{print $0}' | awk -F'\t' '$84!~2{print $0}'>> $OUTFULL;
    keepcols "$(echo "$w" | tr '\n' '\t' | rev | cut -c 2- | rev)" $OUTFULL > $OUTBASIC;

    mv $OUTBASIC $OUTBASIC.tmp; mv $OUTFULL $OUTFULL.tmp;
    cat $OUTBASIC.tmp | grep -v '^$' | awk -F$'\t' '{print $0"\t"$5"."$7"."$4"."$17}' > $OUTBASIC;
    cat $OUTFULL.tmp | awk -F$'\t' '{print $0"\t"$3"."$6"."$18"."$92}' > $OUTFULL;
    rm $OUTFULL.tmp $OUTBASIC.tmp;

    ####
    echo '<tr><td>'$PROJECTNAME'</td><td>'$PROJECTID'</td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$BASIC'.html">basic</a></td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$FULL'.html">full</a></td></tr>' >> $HTMLFILE;
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTFULLHTML;
    echo "$STYLE" >> $OUTFULLHTML;
    echo "</head><body>" >> $OUTFULLHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTFULLHTML;
    echo '<a href="'$FULL.txt'">'$(basename $OUTFULL)' (tsv)</a>' >> $OUTFULLHTML;
    echo "<table class=\"style2\">" >> $OUTFULLHTML;
    head -n 1 $OUTFULL | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTFULLHTML;
    tail -n +2 $OUTFULL | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTFULLHTML;
    echo "</table>" >> $OUTFULLHTML;
    echo "</body></html>" >> $OUTFULLHTML;
    ####
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTBASICHTML;
    echo "$STYLE" >> $OUTBASICHTML;
    echo "</head><body>" >> $OUTBASICHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTBASICHTML;
    echo '<a href="'$BASIC'.txt">'$(basename $OUTBASIC)' (tsv)</a>' >> $OUTBASICHTML;
    echo "<table class=\"style2\">" >> $OUTBASICHTML;
    head -n 1 $OUTBASIC | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTBASICHTML;
    tail -n +2 $OUTBASIC | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTBASICHTML;
    echo "</table>" >> $OUTBASICHTML;
    echo "</body></html>" >> $OUTBASICHTML;


    echo '<tr style="height: 15px;"/><td  colspan="5">&nbsp;</td></tr>' >> $HTMLFILE;
    PROJECTNAME="ALL_PROJECTS"
    PROJECTID="Unvalidated"
    echo ${PROJECTNAME}_${PROJECTID}
    mkdir -p $DATEFLDR/projects/${PROJECTNAME}_${PROJECTID};
    FULL=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.full;
    BASIC=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.basic;
    OUTFULL=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.txt;
    OUTBASIC=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.txt;
    rm -f $OUTFULL $OUTBASIC;
    OUTFULLHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.html; 
    OUTBASICHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.html;
    rm -f $OUTFULLHTML $OUTBASICHTML;
    ###
    echo "$v" | tr '\n' '\t' | rev | cut -c 2- | rev >> $OUTFULL;
    cat $DATEFLDR/illumina_report_HiSeqX.txt $DATEFLDR/illumina_report_NovaSeq.txt  $DATEFLDR/illumina_report_iSeq.txt $DATEFLDR/illumina_report_MiSeq.txt >> $OUTFULL;
    keepcols "$(echo "$w" | tr '\n' '\t' | rev | cut -c 2- | rev)" $OUTFULL > $OUTBASIC;

    mv $OUTBASIC $OUTBASIC.tmp; mv $OUTFULL $OUTFULL.tmp;
    cat $OUTBASIC.tmp | grep -v '^$' | awk -F$'\t' '{print $0"\t"$5"."$7"."$4"."$17}' > $OUTBASIC;
    cat $OUTFULL.tmp | awk -F$'\t' '{print $0"\t"$3"."$6"."$18"."$92}' > $OUTFULL;
    rm $OUTFULL.tmp $OUTBASIC.tmp;

    ####
    echo '<tr><td>'$PROJECTNAME'</td><td>'$PROJECTID'</td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$BASIC'.html">basic</a></td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$FULL'.html">full</a></td></tr>' >> $HTMLFILE;
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTFULLHTML;
    echo "$STYLE" >> $OUTFULLHTML;
    echo "</head><body>" >> $OUTFULLHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTFULLHTML;
    echo '<a href="'$FULL.txt'">'$(basename $OUTFULL)' (tsv)</a>' >> $OUTFULLHTML;
    echo "<table class=\"style2\">" >> $OUTFULLHTML;
    head -n 1 $OUTFULL | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTFULLHTML;
    tail -n +2 $OUTFULL | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTFULLHTML;
    echo "</table>" >> $OUTFULLHTML;
    echo "</body></html>" >> $OUTFULLHTML;
    ####
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTBASICHTML;
    echo "$STYLE" >> $OUTBASICHTML;
    echo "</head><body>" >> $OUTBASICHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTBASICHTML;
    echo '<a href="'$BASIC'.txt">'$(basename $OUTBASIC)' (tsv)</a>' >> $OUTBASICHTML;
    echo "<table class=\"style2\">" >> $OUTBASICHTML;
    head -n 1 $OUTBASIC | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTBASICHTML;
    tail -n +2 $OUTBASIC | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTBASICHTML;
    echo "</table>" >> $OUTBASICHTML;
    echo "</body></html>" >> $OUTBASICHTML;


    echo '<tr style="height: 15px;"/><td  colspan="5">&nbsp;</td></tr>' >> $HTMLFILE;
    PROJECTNAME="BRIDGET_MCC"
    PROJECTID="ALL_COUNTRIES"
    MULTICOHORFILTER="AUL601$TAB|AUL602$TAB|AUL651$TAB|AUL665$TAB|AUL707$TAB"
    echo ${PROJECTNAME}_${PROJECTID}
    mkdir -p $DATEFLDR/projects/${PROJECTNAME}_${PROJECTID};
    FULL=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.full;
    BASIC=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.basic;
    OUTFULL=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.txt;
    OUTBASIC=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.txt;
    rm -f $OUTFULL $OUTBASIC;
    OUTFULLHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.html; 
    OUTBASICHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.html;
    rm -f $OUTFULLHTML $OUTBASICHTML;
    ###
    echo "$v" | tr '\n' '\t' | rev | cut -c 2- | rev >> $OUTFULL;
    cat $DATEFLDR/illumina_report_HiSeqX.txt $DATEFLDR/illumina_report_NovaSeq.txt  $DATEFLDR/illumina_report_iSeq.txt $DATEFLDR/illumina_report_MiSeq.txt | grep -E "$MULTICOHORFILTER" |  awk -F'\t' '$135==1{print $0}' | awk -F'\t' '$84!~2{print $0}'>> $OUTFULL;
    keepcols "$(echo "$w" | tr '\n' '\t' | rev | cut -c 2- | rev)" $OUTFULL > $OUTBASIC;

    mv $OUTBASIC $OUTBASIC.tmp; mv $OUTFULL $OUTFULL.tmp;
    cat $OUTBASIC.tmp | grep -v '^$' | awk -F$'\t' '{print $0"\t"$5"."$7"."$4"."$17}' > $OUTBASIC;
    cat $OUTFULL.tmp | awk -F$'\t' '{print $0"\t"$3"."$6"."$18"."$92}' > $OUTFULL;
    rm $OUTFULL.tmp $OUTBASIC.tmp;

    ####
    echo '<tr><td>'$PROJECTNAME'</td><td>'$PROJECTID'</td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$BASIC'.html">basic</a></td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$FULL'.html">full</a></td></tr>' >> $HTMLFILE;
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTFULLHTML;
    echo "$STYLE" >> $OUTFULLHTML;
    echo "</head><body>" >> $OUTFULLHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTFULLHTML;
    echo '<a href="'$FULL.txt'">'$(basename $OUTFULL)' (tsv)</a>' >> $OUTFULLHTML;
    echo "<table class=\"style2\">" >> $OUTFULLHTML;
    head -n 1 $OUTFULL | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTFULLHTML;
    tail -n +2 $OUTFULL | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTFULLHTML;
    echo "</table>" >> $OUTFULLHTML;
    echo "</body></html>" >> $OUTFULLHTML;
    ####
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTBASICHTML;
    echo "$STYLE" >> $OUTBASICHTML;
    echo "</head><body>" >> $OUTBASICHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTBASICHTML;
    echo '<a href="'$BASIC'.txt">'$(basename $OUTBASIC)' (tsv)</a>' >> $OUTBASICHTML;
    echo "<table class=\"style2\">" >> $OUTBASICHTML;
    head -n 1 $OUTBASIC | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTBASICHTML;
    tail -n +2 $OUTBASIC | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTBASICHTML;
    echo "</table>" >> $OUTBASICHTML;
    echo "</body></html>" >> $OUTBASICHTML;

    echo '<tr style="height: 15px;"/><td  colspan="5">&nbsp;</td></tr>' >> $HTMLFILE;

for PROJECTID_NAME in $( cat $DATEFLDR/illumina_report_HiSeqX.txt $DATEFLDR/illumina_report_NovaSeq.txt  $DATEFLDR/illumina_report_MiSeq.txt  $DATEFLDR/illumina_report_iSeq.txt | awk -F'\t' '{print $1"_"$2}' | tr ' ' '_' | sort -t'_' -k2 -u | grep -v "0_0"); do

    PROJECTID=$(echo "$PROJECTID_NAME" | awk -F'_' '{print $1}'); PROJECTNAME=$(echo "$PROJECTID_NAME" | sed "s/${PROJECTID}_//g");
    echo ${PROJECTNAME}_${PROJECTID}
    mkdir -p $DATEFLDR/projects/${PROJECTNAME}_${PROJECTID};
    FULL=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.full;
    BASIC=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.basic;
    COVERAGE=illumina_report_filt_${PROJECTNAME}_${PROJECTID}.coverage;
    OUTFULL=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.txt;
    OUTBASIC=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.txt;
    OUTCOVERAGE=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$COVERAGE.txt;

    rm -f $OUTFULL $OUTBASIC $OUTCOVERAGE;
    OUTFULLHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$FULL.html; 
    OUTBASICHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$BASIC.html;
    OUTCOVERAGEHTML=$DATEFLDR/projects/${PROJECTNAME}_${PROJECTID}/$COVERAGE.html;
    rm -f $OUTFULLHTML $OUTBASICHTML $OUTCOVERAGEHTML;
    ###
    echo "$v" | tr '\n' '\t' | rev | cut -c 2- | rev >> $OUTFULL;
    cat $DATEFLDR/illumina_report_HiSeqX.txt $DATEFLDR/illumina_report_NovaSeq.txt  $DATEFLDR/illumina_report_iSeq.txt $DATEFLDR/illumina_report_MiSeq.txt  | grep "$PROJECTID$TAB"  |  awk -F'\t' '$135==1{print $0}' | awk -F'\t' '$84!~2{print $0}'>> $OUTFULL;
    keepcols "$(echo "$w" | tr '\n' '\t' | rev | cut -c 2- | rev)" $OUTFULL > $OUTBASIC;

    mv $OUTBASIC $OUTBASIC.tmp; mv $OUTFULL $OUTFULL.tmp;
    cat $OUTBASIC.tmp | grep -v '^$' | awk -F$'\t' '{print $0"\t"$5"."$7"."$4"."$17}' > $OUTBASIC;
    cat $OUTFULL.tmp | awk -F$'\t' '{print $0"\t"$3"."$6"."$18"."$92}' > $OUTFULL;
    rm $OUTFULL.tmp $OUTBASIC.tmp;

    keepcols "$(echo "$ww" | tr '\n' '\t' | rev | cut -c 2- | rev)" $OUTFULL > $OUTCOVERAGE;

    (printf "PROJECT_ID\tPROJECT_NAME\tSAMPLENAME\tNumber of Libraries\tLIBRARY_ID(s)\tTotal Raw Mean Coverage\tTotal Deduplicated Mean Coverage\tAll Valid Fastq\n";
    for samplename in $(tail -n+2 $OUTCOVERAGE | awk -F'\t' '{print $3}' | sort -u); do
        projid=$(cat $OUTCOVERAGE | awk -F'\t' -v samplename=$samplename '$3==samplename{print $0}' | head -n 1  | awk -F'\t' '{print $1}');
        projname=$(cat $OUTCOVERAGE | awk -F'\t' -v samplename=$samplename '$3==samplename{print $0}'| head -n 1  | awk -F'\t' '{print $2}');
        nlib=$(cat $OUTCOVERAGE | awk -F'\t' -v samplename=$samplename '$3==samplename{print $0}'| awk -F'\t' '{print $4}' |  sort -u | wc -l);
        libs=$(cat $OUTCOVERAGE | awk -F'\t' -v samplename=$samplename '$3==samplename{print $0}'| awk -F'\t' '{print $4}' |  sort -u | tr '\n' ',' | rev | cut -c 2- | rev);
        cov=$(cat $OUTCOVERAGE | awk -F'\t' -v samplename=$samplename '$3==samplename{print $0}'| awk -F'\t' '{sum+=$6}END{print sum;}');
        covdedup=$(cat $OUTCOVERAGE | awk -F'\t' -v samplename=$samplename '$3==samplename{print $0}'| awk -F'\t' '{sum+=((1-$5/100)*$6)}END{print sum;}');
        alldatasets=$(cat $OUTCOVERAGE | awk -F'\t' -v samplename=$samplename '$3==samplename{print $0}'| awk -F'\t' '{print $7}' |  sort -u | tr '\n' ',' | rev | cut -c 2- | rev);
        printf "$projid\t$projname\t$samplename\t$nlib\t$libs\t$cov\t$covdedup\t$alldatasets\n";
    done) > $OUTCOVERAGE.tmp
    mv $OUTCOVERAGE.tmp $OUTCOVERAGE

    echo '<tr><td>'$PROJECTNAME'</td><td>'$PROJECTID'</td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$BASIC'.html">basic</a></td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$FULL'.html">full</a></td><td><a href="'${PROJECTNAME}'_'${PROJECTID}'/'$COVERAGE'.html">sample coverage</a></td></tr>' >> $HTMLFILE;
    ####
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTFULLHTML;
    echo "$STYLE" >> $OUTFULLHTML;
    echo "</head><body>" >> $OUTFULLHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTFULLHTML;
    echo '<a href="'$FULL.txt'">'$(basename $OUTFULL)' (tsv)</a>' >> $OUTFULLHTML;
    echo "<table class=\"style2\">" >> $OUTFULLHTML;
    head -n 1 $OUTFULL | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTFULLHTML;
    tail -n +2 $OUTFULL | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTFULLHTML;
    echo "</table>" >> $OUTFULLHTML;
    echo "</body></html>" >> $OUTFULLHTML;
    ####
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTBASICHTML;
    echo "$STYLE" >> $OUTBASICHTML;
    echo "</head><body>" >> $OUTBASICHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTBASICHTML;
    echo '<a href="'$BASIC'.txt">'$(basename $OUTBASIC)' (tsv)</a>' >> $OUTBASICHTML;
    echo "<table class=\"style2\">" >> $OUTBASICHTML;
    head -n 1 $OUTBASIC | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTBASICHTML;
    tail -n +2 $OUTBASIC | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTBASICHTML;
    echo "</table>" >> $OUTBASICHTML;
    echo "</body></html>" >> $OUTBASICHTML;
    ###
    echo "<html><head><title>$PROJECTNAME $PROJECTID (Illumina Runs)</title>" >> $OUTCOVERAGEHTML;
    echo "$STYLE" >> $OUTCOVERAGEHTML;
    echo "</head><body>" >> $OUTCOVERAGEHTML;
    echo "$PROJECTID $PROJECTNAME (Illumina Runs)<br>" >> $OUTCOVERAGEHTML;
    echo '<a href="'$COVERAGE'.txt">'$(basename $OUTCOVERAGE)' (tsv)</a>' >> $OUTCOVERAGEHTML;
    echo "<table class=\"style2\">" >> $OUTCOVERAGEHTML;
    head -n 1 $OUTCOVERAGE | grep -v '^$' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed "s|$TAB|</th><th>|g" >> $OUTCOVERAGEHTML;
    tail -n +2 $OUTCOVERAGE | grep -v '^$' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed "s|$TAB|</td><td>|g" >> $OUTCOVERAGEHTML;
    echo "</table>" >> $OUTCOVERAGEHTML;
    echo "</body></html>" >> $OUTCOVERAGEHTML;

#  1 PROJECT_ID
#  2 PROJECT_NAME
#  3 Processing Folder Name
#  4 Run ID
#  5 SAMPLENAME
#  6 LIBRARY_TYPE
#  7 LIBRARY_ID
#  8 reagentlabel
#  9 CONTAINER1_CAPTURE
# 10 Clusters
# 11 Bases
# 12 Avg. Qual
# 13 Dup. Rate (%)
# 14 Aligned Dup. Rate (%)
# 15 Mean Coverage
# 16 FLOWCELL_ID
# 17 FLOWCELL_LANE
# 18 workstatus
# 19 Data Directory

#    mkdir -p $DATEFLDR/projects/httpstage/${PROJECTID};
#
#    for line in $(tail -n +2 $OUTBASIC | grep -v "^$"); do
#        RUNID=$(echo "$line" | awk -F'\t' '{print $4}');
#        FLOWCELL_LANE=$(echo "$line" | awk -F'\t' '{print $17}');
#        MAPFILE=$DATEFLDR/projects/httpstage/${PROJECTID}/${PROJECTID}_${RUNID}_${FLOWCELL_LANE}.mapping.txt;
#        rm -f $MAPFILE;
#    done
#
#    for line in $(tail -n +2 $OUTBASIC | grep -v "^$"); do
#        SAMPLENAME=$(echo "$line" | awk -F'\t' '{print $5}');
#        LIBRARYID=$(echo "$line" | awk -F'\t' '{print $7}');
#        RUNID=$(echo "$line" | awk -F'\t' '{print $4}');
#        FLOWCELL_LANE=$(echo "$line" | awk -F'\t' '{print $17}');
#        datadir=$(echo "$line" | awk -F'\t' '{print $19}' | awk -F',' '{print $1}');
#        fastq1name=$(echo "$line" | awk -F'\t' '{print $19}' | awk -F',' '{print $2}');
#        fastq2name=$(echo "$line" | awk -F'\t' '{print $19}' | awk -F',' '{print $3}');
#        bamname=$(echo "$line" | awk -F'\t' '{print $19}' | awk -F',' '{print $4}');
#
#        MAPFILE=$DATEFLDR/projects/httpstage/${PROJECTID}/${PROJECTID}_${RUNID}_${FLOWCELL_LANE}.mapping.txt;
#        
#        if [ -z "$bamname" ]; then
#            newfastq1name=${SAMPLENAME}_${LIBRARYID}_${RUNID}_${FLOWCELL_LANE}_$(echo $fastq1name | sed "s/$SAMPLENAME//g" | cut -c 2- | sed "s/$LIBRARYID//g" | cut -c 2-)
#            newfastq2name=${SAMPLENAME}_${LIBRARYID}_${RUNID}_${FLOWCELL_LANE}_$(echo $fastq2name | sed "s/$SAMPLENAME//g" | cut -c 2- | sed "s/$LIBRARYID//g" | cut -c 2-)
#            echo $datadir/$fastq1name /data/httpstage/projects/${PROJECTID}/${PROJECTID}_${RUNID}_${FLOWCELL_LANE}/$newfastq1name >> $MAPFILE
#            echo $datadir/$fastq1name.md5 /data/projects/${PROJECTID}/${PROJECTID}_${RUNID}_${FLOWCELL_LANE}/$newfastq1name.md5 >> $MAPFILE
#            echo $datadir/$fastq2name /data/projects/${PROJECTID}/${PROJECTID}_${RUNID}_${FLOWCELL_LANE}/$newfastq2name >> $MAPFILE
#            echo $datadir/$fastq2name.md5 /data/projects/${PROJECTID}/${PROJECTID}_${RUNID}_${FLOWCELL_LANE}/$newfastq2name.md5 >> $MAPFILE
#        else
#            newbamname=${SAMPLENAME}_${LIBRARYID}_${RUNID}_${FLOWCELL_LANE}_$(echo $bamname | sed "s/$SAMPLENAME//g" | cut -c 2- | sed "s/$LIBRARYID//g" | cut -c 2-)
#            echo $datadir/$bamname /data/projects/${PROJECTID}/${PROJECTID}_${RUNID}_${FLOWCELL_LANE}/$newbamname >> $MAPFILE
#        fi
#
#    done
#


done


echo "</table>" >> $HTMLFILE;

echo "</body></html>" >> $HTMLFILE;

}

function summary {

PROJECT=$1
FILTER=$2

 cat illumina_report_hiseqx.txt | sort -t $'\t' -nk76 | tr '\t' '~' | column -s'~' -t | grep $PROJECT | rev | grep -v "^2" | rev | wc -l
 a=$( cat illumina_report_hiseqx.txt | sort -t $'\t' -nk76 | tr '\t' '~' | column -s'~' -t | grep $PROJECT | rev | grep -v "^2" | rev \
     | awk '{print $2}' | sort | uniq -c | sort -nrk1 | awk '$1==2{print $2}')
for s in $(echo "$a"); do grep $s illumina_report_hiseqx.txt | rev | grep -v "^2" | rev ; done | wc -l
for s in $(echo "$a"); do grep $s illumina_report_hiseqx.txt | rev | grep  "^2" | rev ; done | wc -l

( printf "project name\tsample name\tlibrary id\tdataset id\texperiment name\trun id\tlane\tflowcell barcode\tcoverage\tbam path\n"; (seq 1 1 131 | tr '\n' '\t' | awk '{print $0}';  for s in $(echo "$a"); do grep $s illumina_report_hiseqx.txt | rev | grep -v "^2" | rev ; done | sort -t $'\t' -k2) | awk -F'\t' '{print $1 "\t" $2 "\t" $5 "\t" $12 "\t" $83 "\t" $17 "\t" $88 "\t" $87 "\t" $49 "\t" $18 }' | sed 's|,,,|/|g' )
( printf "project name\tsample name\tlibrary id\tdataset id\texperiment name\trun id\tlane\tflowcell barcode\tcoverage\tbam path\n"; (seq 1 1 131 | tr '\n' '\t' | awk '{print $0}';  for s in $(echo "$a"); do grep $s illumina_report_hiseqx.txt | rev | grep "^2" | rev ; done | sort -t $'\t' -k2) | awk -F'\t' '{print $1 "\t" $2 "\t" $5 "\t" $12 "\t" $83 "\t" $17 "\t" $88 "\t" $87 "\t" $49 "\t" $18 }' | sed 's|,,,|/|g' )

 cat illumina_report_hiseqx.txt | rev | grep -v "^2" | rev | grep -v -E "$(echo "$FILTER" | tr ' ' '|')" | wc -l

}

TAB="$(printf '\t')"
IFS=$'\n'

function run {

SEQUENCER_CATEGORY=$1
DATE=$2

mkdir -p $DATE

REPORTOUT=$DATE/illumina_report_$(echo "$SEQUENCER_CATEGORY" | tr -d ' ').txt

rm -f $REPORTOUT

KEYL="Run Count
Run Folder Name
Run ID
Data Directory
Processing Folder Name
Flowcell Lane
Clusters
Bases
Avg. Qual
Dup. Rate (%)
R1 Top Blast Hit Name
R1 Top Blast Hit Rate (%)
R2 Top Blast Hit Name
R2 Top Blast Hit Rate (%)
Top Sample Tag Name
Top Sample Tag Rate from Total (%)
Top Sample Tag Rate from All Detected (%)
Expected Sample Tag Name
Top Sample Tag Name Match
Clusters on Index in Lane (%)
Clusters on Index in Lane from Target (%)
Reference
Bed
PF Reads Aligned All
PF Reads Aligned All (%)
PF Reads Aligned R1 (%)
PF Reads Aligned R2 (%)
Chimeras (%)
Adapter (%)
Mapped Insert Size (median)
Mapped Insert Size (mean)
Mapped Insert Size (std. dev.)
Aligned Dup. Rate (%)
Mean Coverage
Bases Covered at 10x (%)
Bases Covered at 25x (%)
Bases Covered at 50x (%)
Bases Covered at 75x (%)
Bases Covered at 100x (%)
Aligned Bases On Target (%)
On Bait Bases from On Target Bases (%)
Freemix Number of SNP
Freemix Value
chr1 Normalized Coverage
chr2 Normalized Coverage
chr3 Normalized Coverage
chr4 Normalized Coverage
chr5 Normalized Coverage
chr6 Normalized Coverage
chr7 Normalized Coverage
chr8 Normalized Coverage
chr9 Normalized Coverage
chr10 Normalized Coverage
chr11 Normalized Coverage
chr12 Normalized Coverage
chr13 Normalized Coverage
chr14 Normalized Coverage
chr15 Normalized Coverage
chr16 Normalized Coverage
chr17 Normalized Coverage
chr18 Normalized Coverage
chr19 Normalized Coverage
chr20 Normalized Coverage
chr21 Normalized Coverage
chr22 Normalized Coverage
chrX Normalized Coverage
chrY Normalized Coverage
chrM Normalized Coverage
Data Release
BASE64METADATA"

echo "$KEYL" | awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/xkeys1

KEYL="Yield PF (Gb) R1
Yield PF (Gb) R2
% Bases >=Q30 R1
% Bases >=Q30 R2
Cluster Density (K/mm^2) R1
Cluster Density (K/mm^2) R2
Clusters Raw R1
Clusters Raw R2
Clusters PF R1
Clusters PF R2
%PF R1
%PF R2
Intensity Cycle 1 R1
Intensity Cycle 1 R2
% Intensity Cycle 20 R1
% Intensity Cycle 20 R2
% Phasing R1
% Phasing R2
% Prephasing R1
% Prephasing R2
% Aligned R1
% Aligned R2
% Error Rate R1
% Error Rate R2"

echo "$KEYL" | awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/xkeys2

KEYL="Start Date
Experiment Name
HiSeq Used
cBot Used
Flowcell ID
Flowcell Lot
PhiX v3
NaOH 2N
cBot Cartridge
cBot Reagent Kit ID
PE Clusters Kit
Manifold
SBS Kit (Box Room Temp.)
SBS Kit (Box -20C)
ExAmp Box Lot"
echo "$KEYL" | awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/xkeys3

KEYL="Date"
echo "$KEYL" | awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/xkeys4

KEYL="Library Volume (ul)
Sample Tag"
echo "$KEYL" | awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/xkeys5

KEYL="Comments"
echo "$KEYL" | awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/xkeys6

# startstep='Library Normalization (HiSeq X) 1.0 McGill 1.4';
startstep="Library Normalization (${SEQUENCER_CATEGORY}) 1.0%";


function init_stack {
  stack=""
}
function push_stack {
  stack=$(printf "$1\n$stack")
}
function head_stack {
  echo "$stack" | head -n 1;
}
function pop_stack {
  stack=$(echo "$stack" | tail -n+2)
}
function print_stack {
echo "#####################################################"
if [ -z "$stack" ]; then 
  echo "# empty stack"
else
  echo "$stack" | awk '{print "# "$0}'
fi
echo "#####################################################"
}


function wellcoord {

map1=$(printf "0\tA\n1\tB\n2\tC\n3\tD\n4\tE\n5\tF\n6\tG\n7\tH\n8\tI\n9\tJ\n10\tK\n11\tL\n12\tM\n13\tN\n14\tO\n15\tP")
map2=$(printf "0\t01\n1\t02\n2\t03\n3\t04\n4\t05\n5\t06\n6\t07\n7\t08\n8\t09\n9\t10\n10\t11\n11\t12\n12\t13\n13\t14\n14\t15\n15\t16")

platetype=$1
y=$2
x=$3

if [ "$platetype" == "96 well plate" ]; then
  P1=$(echo "$map1" | awk  -F'\t' -v y=$y 'y==$1{print $2}');
  P2=$(echo "$map2" | awk  -F'\t' -v x=$x 'x==$1{print $2}');
else
  let P1=$y+1;
  P2="";
fi

echo $P1$P2

}


# thisrootprocessoverride=24-12728
# thisrootprocessoverride=24-61628 # CAGEKID
# thisrootprocessoverride=24-60883
# thisrootprocessoverride=24-58643
#  thisrootprocessoverride=24-63428 # Sample Pool
# thisrootprocessoverride=24-63426 # % sign in comment


a=$(
psql  $DATABASECRED << EOF
COPY (select p.luid, p.workstatus, pt.displayname from process p
join processtype pt on p.typeid = pt.typeid
where pt.displayname like '$startstep' order by 1 DESC ) TO STDOUT with delimiter '$TAB';
EOF
);

# echo "$a"


# for thisrootprocess in $( echo "$a" | awk '{print $1}' | grep "$thisrootprocessoverride"); do

for thisrootprocess in $( echo "$a" | awk '{print $1}'); do

b=$(
psql  $DATABASECRED << EOF
COPY (select p.luid, io.inputartifactid, outputart.luid, p.workstatus, t.displayname, pt.displayname from processiotracker io
join artifact a on a.artifactid = io.inputartifactid
join outputmapping om on om.trackerid = io.trackerid
join artifact outputart on om.outputartifactid = outputart.artifactid
join process p on p.processid = io.processid
join processtype pt on p.typeid = pt.typeid
join artifacttype t on t.typeid = outputart.artifacttypeid
where pt.displayname like '$startstep' and t.displayname = 'Analyte' and p.luid = '$thisrootprocess' order by 1 DESC ) TO STDOUT with delimiter '$TAB';
EOF
);


# echo "$b" | tr '\t' '~' | column -s '~' -t


thisprocess=$thisrootprocess;

for thisrootline in $( echo "$b"); do

# echo $thisrootline

init_stack

thisinputanalyte=$(echo "$thisrootline" | awk '{print $2}');
thisoutputanalyte=$(echo "$thisrootline" | awk '{print $3}');

printf "\n"

c=$thisrootline;

push_stack "2-$thisinputanalyte|$(echo "$c" | grep $thisoutputanalyte)||||"

seen=false;

while(true); do

line=$(head_stack)

# print_stack
pop_stack

thisinputanalyte=$(echo "$line" | awk -F'|' '{print $1}');
nextline=$(echo "$line" | awk -F'|' '{print $2}');
LIBVAL1=$(echo "$line" | awk -F'|' '{print $3}');
LIBVAL11=$(echo "$line" | awk -F'|' '{print $4}');
LIBVAL2=$(echo "$line" | awk -F'|' '{print $5}');
LIBVAL3=$(echo "$line" | awk -F'|' '{print $6}');

thisprocess=$(echo "$nextline" | awk '{print $1}');
thisoutputanalyte=$(echo "$nextline" | awk '{print $3}');
thisprocessname=$(echo "$nextline" | awk -F'\t' '{print $6}' | head -n 1);
tmpthisprocess=$(echo "$thisprocess" | awk -F'-' '{print $2}')

csuba=$(psql  $DATABASECRED <<EOF
COPY (select a.luid, s.name, p.luid, p.name as "Project name:" from sample s
join project p using (projectid)
join artifact_sample_map asm using (processid)
join artifact a using (artifactid)
where a.luid = '$thisoutputanalyte' ) TO STDOUT with delimiter '$TAB';
EOF
);


if [[ "$thisprocessname" == "Library Normalization (${SEQUENCER_CATEGORY}) 1.0"* ]]; then
  CNT=$(echo "$csuba" | wc -l)
  if [ "$CNT" != "1" ]; then
     csuba=$(printf "$thisoutputanalyte\t0\t0\t0\n")
  fi
  #  echo "$csuba"  
fi

echo "$nextline"

if [ "$(echo "nextline" | grep -v Analyte | wc -l)" != "0" ]; then
    tmpthisoutputanalyte=$(echo "$thisoutputanalyte" | sed 's/2-//g')

###########################################################################
if [[ "$thisprocessname" == "Library Normalization (${SEQUENCER_CATEGORY}) 1.0"* ]]; then
    
    csub0=$(
psql  $DATABASECRED << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, cp.wellxposition from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
# echo "$csub0"

    csub1=$(
psql  $DATABASECRED << EOF
COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisoutputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);

# echo "$csub1"

    csub2=$(
psql  $DATABASECRED <<EOF
COPY (select outputart.luid, io.inputartifactid, io.processid, pt.displayname from processiotracker io
join outputmapping om on om.trackerid = io.trackerid
join artifact outputart on om.outputartifactid = outputart.artifactid
join process p on p.processid = io.processid
join processtype pt on p.typeid = pt.typeid
where outputart.luid = '$thisoutputanalyte') TO STDOUT with delimiter '$TAB';
EOF
);

tmpthisinputanalyte=$(echo "$csub2" | awk -F'\t' '{print $2}');
thisinputanalyte="2-"$tmpthisinputanalyte;

    csub3=$(
psql  $DATABASECRED <<EOF
COPY (select outputart.luid, io.inputartifactid, io.processid, pt.displayname from processiotracker io
join outputmapping om on om.trackerid = io.trackerid
join artifact outputart on om.outputartifactid = outputart.artifactid
join process p on p.processid = io.processid
join processtype pt on p.typeid = pt.typeid
where outputart.luid = '$thisinputanalyte') TO STDOUT with delimiter '$TAB';
EOF
);

# echo "$csub3"
thistmpinputprocess=$(echo "$csub3" | awk -F'\t' '{print $3}');
thisinputprocessname=$(echo "$csub3" | awk -F'\t' '{print $4}' | sed 's/Add Multiple Reagents/KAPA Hyper Plus/g')

if [ "$thisinputprocessname" == "" ]; then
  thistmpinputprocess=""
  thisinputprocessname=""

csub4=$(printf "\t")
csub5=$(printf "\t")
csub6=""

else

  if [ "$thisinputprocessname" == "Library Batch" ]; then
    tmpthisinputanalyte=$(echo "$csub3" | awk -F'\t' '{print $2}');
    thisinputanalyte="2-"$tmpthisinputanalyte;
    csub3=$(
psql  $DATABASECRED <<EOF
COPY (select outputart.luid, io.inputartifactid, io.processid, pt.displayname from processiotracker io
join outputmapping om on om.trackerid = io.trackerid
join artifact outputart on om.outputartifactid = outputart.artifactid
join process p on p.processid = io.processid
join processtype pt on p.typeid = pt.typeid
where outputart.luid = '$thisinputanalyte') TO STDOUT with delimiter '$TAB';
EOF
);
    # echo "$csub3"
    CNT=$(echo "$csub3" | wc -l)
    if [ "$CNT" != "1" ]; then
       outputart_luid=$(echo "$csub3" | head -n 1 | awk -F'\t' '{print $1}')
       io_processid=$(echo "$csub3" | head -n 1 | awk -F'\t' '{print $3}')
       pt_displayname=$(echo "$csub3" | head -n 1 | awk -F'\t' '{print $4}')
       csub3=$(printf "$outputart_luid\t-\t$io_processid\t$pt_displayname\n");
    fi
    thistmpinputprocess=$(echo "$csub3" | awk -F'\t' '{print $3}');
    thisinputprocessname=$(echo "$csub3" | awk -F'\t' '{print $4}' | sed 's/Add Multiple Reagents/KAPA Hyper Plus/g')
  fi # if [ "$thisinputprocessname" == "Library Batch" ]; then

  if [ -z "$thistmpinputprocess" ]; then
    csub4=""
  else
    csub4=$(
psql  $DATABASECRED <<EOF
COPY (SELECT * FROM process_udf_view WHERE processid = $thistmpinputprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);
  fi

# echo $thistmpinputprocess
# echo "$csub4"

    csub5=$(
psql  $DATABASECRED << EOF
COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisinputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);

csub6=$(
psql  $DATABASECRED <<EOF
COPY (SELECT r.name
 FROM reagentlabel r
 JOIN artifact_label_map alm ON alm.labelid = r.labelid
 WHERE alm.artifactid = $tmpthisinputanalyte ) TO STDOUT with delimiter '$TAB';
EOF
);

  CNT=$(echo "$csub6" | wc -l)
  if [ "$CNT" != "1" ]; then
    csub6="0"
  fi

fi # if [ "$thisinputprocessname" == "" ]; then

#  echo "$csub5"

   # echo "$csub1" | grep -v "^$"| awk -F'\t' '{print ".\t.\t.\t.\t.\t"$4"\t"$6}'
   VALS=$(echo "$csub1" | awk -F'\t' '{print $4"\t"$6}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/xtmp2
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}')
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $5}'))
   SAMPLENAME=$(echo "$csuba" | awk -F'\t' '{print $2}')
   PROJECTLUID=$(echo "$csuba" | awk -F'\t' '{print $3}')
   PROJECTNAME=$(echo "$csuba" | awk -F'\t' '{print $4}')

   VALS=$(echo "$csub4" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/xtmp4

   VALS=$(echo "$csub5" | awk -F'\t' '{print $4"\t"$6}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/xtmp5

   LIBVAL1=$(printf "$PROJECTLUID\t$PROJECTNAME\t$SAMPLENAME\t")\
$(printf "$thisinputprocessname\t$thistmpinputprocess\t$thisinputanalyte\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys4 /dev/shm/xtmp4 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')\
$(printf "\t")\
$(printf "$csub6\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys5 /dev/shm/xtmp5 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')\
$(printf "\t")\
$(printf "$thisprocessname\t$thisprocess\t$thisoutputanalyte\t$PLATENAME\t$WELL\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys1 /dev/shm/xtmp2 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g');

   # echo "$LIBVAL1"
# echo "$csub1"

fi



#######################################################################
if [[ "$thisprocessname" == "Create Strip Tube (${SEQUENCER_CATEGORY}) 1.0"* ]]; then

    csub0=$(
psql  $DATABASECRED << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
# echo "$csub0"

   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}')
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $5}'))
   LIBVAL11=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL")
   # echo "$LIBVAL11"

fi


########################################################################
if [[ "$thisprocessname" == "Cluster Generation (${SEQUENCER_CATEGORY}) 1.0"* ]]; then

    csub0=$(
psql  $DATABASECRED << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
# echo "$csub0"

    csub1=$(
psql  $DATABASECRED << EOF
COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisoutputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);
# echo "$csub1" 

    csub2=$(
psql  $DATABASECRED <<EOF
COPY (SELECT * FROM process_udf_view WHERE processid = $tmpthisprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);

   VALS=$(echo "$csub1" | awk -F'\t' '{print $4"\t"$6}'  | sed 's/%/Percent/g' | sort -t $'\t' -k1);
   echo "$VALS" > /dev/shm/xtmp2

   VALS=$(echo "$csub2" | awk -F'\t' '{print $5"\t"$7}'  | sed 's/%/Percent/g' | sort -t $'\t' -k1);
   echo "$VALS" > /dev/shm/xtmp3

   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}')
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $5}'))
   LIBVAL2=\
$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys3 /dev/shm/xtmp3 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')\
$(printf "\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys2 /dev/shm/xtmp2 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g' );
   # echo "$LIBVAL2"

fi

fi

c=$(
psql  $DATABASECRED << EOF
COPY (select p.luid, io.inputartifactid, outputart.luid, p.workstatus,t.displayname,  pt.displayname from processiotracker io
     join artifact a on a.artifactid = io.inputartifactid
left join outputmapping om on om.trackerid = io.trackerid
left join artifact outputart on om.outputartifactid = outputart.artifactid
     join process p on p.processid = io.processid
     join processtype pt on p.typeid = pt.typeid
left join artifacttype t on t.typeid = outputart.artifacttypeid
where a.luid = '$thisoutputanalyte' order by 1 ASC) TO STDOUT with delimiter '$TAB';
EOF
);

# echo "$c"

str="$(echo "$c" | grep Analyte | awk '{print $1}' | sort -u | tr '\n' '|' | rev | cut -c 2- | rev)"

if [ -z "$str" ]; then
  str=9999999-2
fi

for process in $(echo "$c" | grep -v Analyte | grep -v -E "$str" | grep -v "$thisprocess" | awk '{print $1}' | sort -u); do

  # echo "process with no outputs:"
  cc=$(echo "$c" | grep $process)

  if [ ! -z "$cc" ]; then
    echo "$cc" | head -n 1 | awk '{printf $0"\t"}'; 
    echo "(-)"; 
  fi;
  
  for tmpthisoutputanalyte in $(echo "$c" | grep -v "$thisprocess" | awk '{print $3}' | grep -v '\N' | sed 's/92-//g'); do 
    if [ ! -z "$tmpthisoutputanalyte" ]; then
      ccprocessname=$(echo "$cc" | grep $process | awk -F'\t' '{print $6}' | head -n 1);
      cc_complete=$(echo "$cc" | grep $process | awk -F'\t' '{print $4}'| head -n 1)
      
      #######################################################################
      if [[ "$ccprocessname" == "Illumina Sequencing (${SEQUENCER_CATEGORY}) 1.0"* ]]; then
        seen=true
        csub2=$(
psql  $DATABASECRED << EOF
COPY (select ast.qcflag, atp.displayname as type
from artifact a
join artifactstate ast ON a.currentstateid = ast.stateid
join artifacttype atp ON atp.typeid = a.artifacttypeid
where a.artifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);

tmpprocess=$(echo "$process" | awk -F'-' '{print $2}')
    csub3=$(
psql  $DATABASECRED <<EOF
COPY (SELECT * FROM process_udf_view WHERE processid = $tmpprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);

# echo "$csub3"

   VALS=$(echo "$csub3" | sed 's/\\n/ /g' | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Pct/g' | sort -t $'\t' -k1);
   echo "$VALS" > /dev/shm/xtmp1;
   COMMENTS=$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys6 /dev/shm/xtmp1 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev );

        # echo "$csub2" | grep -v "^$" | awk -F'\t' '$1!=0{print " \t \t \t \t \tQC\t"$0}'
        VAL=$(echo "$csub2" | grep -v "^$" | awk -F'\t' '{print $1}')
        if [ -z "$LIBVAL3" ] || [ "$VAL" != "0" ]; then
          LIBVAL3=$(printf "$ccprocessname\t$process\t$tmpthisoutputanalyte\t")$VAL$TAB$cc_complete$TAB$COMMENTS;
        fi
      fi
    fi
  done ### for tmpthisoutputanalyte in $(echo "$c"

done ### for process in $(echo "$c"


if ($seen); then

   if [ "$LIBVAL11" == "" ]; then
       LIBVAL11=$(printf "\t\t\t");
   fi

   # echo "$LIBVAL1" | tr '\t' '\n'  | awk -F'\t' '{print NR " "$1}' | cut -c 1-200

   B64=$(echo "$LIBVAL1" | awk -F'\t' '{print $85}')

# thisinputanalyte=$(echo "$LIBVAL1" | awk -F'\t' '{print $6}');
# tmpthisinputanalyte=$(echo "$thisinputanalyte" | cut -c 3-)
# csub6=$(
# psql  $DATABASECRED <<EOF
# COPY (SELECT r.name
#   FROM reagentlabel r
#   JOIN artifact_label_map alm ON alm.labelid = r.labelid
#   WHERE alm.artifactid = $tmpthisinputanalyte ) TO STDOUT with delimiter '$TAB';
# EOF
# );


  # CNT=$(echo "$csub6" | wc -l)
  # if [ "$CNT" -gt "1" ]; then
  if [ "$B64" == "\N" ]; then
       LIBVAL1tmp=$(echo "$LIBVAL1" | awk 'BEGIN {FS="\t";OFS="\t"} NF{--NF};1');
       LIBVAL=$(printf "$LIBVAL1tmp\t$LIBVAL11\t$LIBVAL2\t$LIBVAL3\n")
       echo "$LIBVAL" >> $REPORTOUT
   else
       # echo "$B64" | cut -c 22- | base64 -d | head -n 1  | tr '\t' '\n'  |awk -F'\t' '{print NR " "$1}' 

       for line in $(echo "$B64" | cut -c 22- | base64 -d | tail -n +2); do

PROJECTLUID=$(echo "$line" | awk -F'\t' '{print $6}');
PROJECTNAME=$(echo "$line" | awk -F'\t' '{print $5}');
SAMPLENAME=$(echo "$line" | awk -F'\t' '{print $7}');
thisinputanalyte=$(echo "$line" | awk -F'\t' '{print $10}'); # LIBID
tmpthisinputanalyte=$(echo "$thisinputanalyte" | cut -c 3-)

    csub3=$(
psql  $DATABASECRED <<EOF
COPY (select outputart.luid, io.inputartifactid, io.processid, pt.displayname from processiotracker io
join outputmapping om on om.trackerid = io.trackerid
join artifact outputart on om.outputartifactid = outputart.artifactid
join process p on p.processid = io.processid
join processtype pt on p.typeid = pt.typeid
where outputart.luid = '$thisinputanalyte') TO STDOUT with delimiter '$TAB';
EOF
);

thistmpinputprocess=$(echo "$csub3" | awk -F'\t' '{print $3}')
thisinputprocessname=$(echo "$csub3" | awk -F'\t' '{print $4}')

thisprocessname=$(echo "$LIBVAL1" | awk -F'\t' '{print $11}')
thisprocess=$(echo "$LIBVAL1" | awk -F'\t' '{print $12}')
thisoutputanalyte=$(echo "$LIBVAL1" | awk -F'\t' '{print $13}')
PLATENAME=$(echo "$LIBVAL1" | awk -F'\t' '{print $14}')
WELL=$(echo "$LIBVAL1" | awk -F'\t' '{print $15}')
DATARELEASE=$(echo "$LIBVAL1" | awk -F'\t' '{print $84}')
PROCFLDR=$(echo "$LIBVAL1" | awk -F'\t' '{print $17}')

           tmp=$(echo "$line" | awk -F'\t' -v PROCFLDR=$PROCFLDR -v DATARELEASE=$DATARELEASE '{print $30"\t"PROCFLDR"\t"$28"\t"$23"\t"$31"\t"$29"\t"$36"\t"$37"\t"$38"\t"$39"\t"$41"\t"$42"\t"$43"\t"$44"\t"$47"\t"$48"\t"$49"\t"$50"\t"$51"\t"$52"\t"$53"\t"$68"\t"$69"\t"$70"\t"$71"\t"$72"\t"$73"\t"$74"\t"$75"\t"$76"\t"$77"\t"$78"\t"$79"\t"$80"\t"$81"\t"$82"\t"$83"\t"$84"\t"$85"\t"$86"\t"$87"\t"$88"\t"$89"\t"$90"\t"$91"\t"$92"\t"$93"\t"$94"\t"$95"\t"$96"\t"$97"\t"$98"\t"$99"\t"$100"\t"$101"\t"$102"\t"$103"\t"$104"\t"$105"\t"$106"\t"$107"\t"$108"\t"$109"\t"$110"\t"$111"\t"$112"\t"$113"\t"$114"\t"DATARELEASE}');

    csub4=$(
psql  $DATABASECRED <<EOF
COPY (SELECT * FROM process_udf_view WHERE processid = $thistmpinputprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);

    csub5=$(
psql  $DATABASECRED << EOF
COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisinputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);

csub6=$(
psql  $DATABASECRED <<EOF
COPY (SELECT r.name
 FROM reagentlabel r
 JOIN artifact_label_map alm ON alm.labelid = r.labelid
 WHERE alm.artifactid = $tmpthisinputanalyte ) TO STDOUT with delimiter '$TAB';
EOF
);

   VALS=$(echo "$csub4" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/xtmp4

   VALS=$(echo "$csub5" | awk -F'\t' '{print $4"\t"$6}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/xtmp5

    LIBVAL1=$(printf "$PROJECTLUID\t$PROJECTNAME\t$SAMPLENAME\t")\
$(printf "$thisinputprocessname\t$thistmpinputprocess\t$thisinputanalyte\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys4 /dev/shm/xtmp4 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')\
$(printf "\t")\
$(printf "$csub6\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/xkeys5 /dev/shm/xtmp5 | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' | tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')\
$(printf "\t")\
$(printf "$thisprocessname\t$thisprocess\t$thisoutputanalyte\t$PLATENAME\t$WELL\t")\
$tmp;

           LIBVAL=$(printf "$LIBVAL1\t$LIBVAL11\t$LIBVAL2\t$LIBVAL3\n");
           echo "$LIBVAL" >> $REPORTOUT
       done
   fi

#   echo "$LIBVAL1"
#   echo "$LIBVAL11"
#   echo "$LIBVAL2"
#   echo "$LIBVAL3"

fi


if [ "$(echo "$c" | grep Analyte | grep -v $thisoutputanalyte | wc -l)" != "0" ]; then
  thisinputanalyte=$thisoutputanalyte;
  for line in $( echo "$c" | grep Analyte | grep -v $thisoutputanalyte  ); do
      push_stack "$thisinputanalyte|$line|$LIBVAL1|$LIBVAL11|$LIBVAL2|$LIBVAL3"
  done
else
  if [ -z "$stack" ]; then
    break;
  fi
fi

done ### while(true); do

done ### for thisrootline in $( echo "$b"); do

done ### for thisrootprocess in $( echo "$a" 



}
