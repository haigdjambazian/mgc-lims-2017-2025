#!/bin/bash

# . ./covid_nanopore_illum_qc_report; runreport COVIDPROCESSINGPATH

function adjust_file_status_filters {

(    
    v=$( find /lb/robot/research/processing/ont/ontcovidseq/RAG936/2022/LSPQ_SARS_QCselect460*  -name "*L00543565001*" -printf "%T@ %Tc %p\n" | sort -n | \
	grep -E -v "\.sh$|\.done$|\.bai$|\.tbi$|\.o$" | grep  -E "\.bam$|\.vcf.gz$|\.fasta$|\.fastq.gz$|\.bed$|\.tsv$|\.pdf$|\.kraken2_report$" | \
	awk -F'/lb/robot/research/processing/ont/ontcovidseq/RAG936/2022/LSPQ_SARS_QCselect460_PAM37357_20221028.20221028_1834_2-E1-H1_PAM37357_da64c3cd.RAG936.ARTIC_v4_1-ontcovidseq/' '{print $2}' | \
	sed 's/L00543565001/PLACEHOLDER/g' |  grep '\.'  | sort ); 
    (echo -n "ont_filelistpersample=\"";
	echo "$v" | grep -v "^report"; echo "$v" | grep "^report" | head -c -1; echo "\"");
    echo
    v=$( find /lb/robot/research/processing/ont/ontcovidseq/RAG936/2022/LSPQ_SARS_QCselect460*  -printf "%T@ %Tc %p\n" | sort -n | \
	grep -E -v "\.sh$|\.done$|\.bai$|\.tbi$|\.o$" | grep  -E "\.bam$|\.vcf.gz$|\.fasta$|\.fastq.gz$|\.bed$|\.tsv$|\.pdf$|\.kraken2_report$" | \
	awk -F'/lb/robot/research/processing/ont/ontcovidseq/RAG936/2022/LSPQ_SARS_QCselect460_PAM37357_20221028.20221028_1834_2-E1-H1_PAM37357_da64c3cd.RAG936.ARTIC_v4_1-ontcovidseq/' '{print$2}' | \
	grep -v -E "L00|Pos|Neg" | sed 's/LSPQ_SARS_QCselect460_PAM37357_20221028.20221028_1834_2-E1-H1_PAM37357_da64c3cd.RAG936.ARTIC_v4_1/*/g' | sed 's/PAM37357_da64c3cd/*/g' | sort );
    (echo -n "ont_filelistperrun=\"";
	echo "$v" | grep -v "^report";echo "$v" | grep "^report" | head -c -1; echo "\"");
    echo
    v=$( find /lb/scratch/hdjambaz/covseq/FAL1701/2022/221021_A01861_0047_AHJF7LDRX2_CentrEAU16.FAL1701.ARTIC_v4_1-illumcovidseq*  -name "*JL_RNA_06*" -printf "%T@ %Tc %p\n" | sort -n | \
	grep -E -v "\.sh$|\.done$|\.bai$|\.tbi$|\.o$" | grep  -E "\.bam$|\.vcf.gz$|\.fasta$|\.fastq.gz$|\.bed$|\.tsv$|\.pdf$|\.kraken2_report$" | \
	awk -F'/lb/scratch/hdjambaz/covseq/FAL1701/2022/221021_A01861_0047_AHJF7LDRX2_CentrEAU16.FAL1701.ARTIC_v4_1-illumcovidseq/' '{print $2}' | \
	sed 's/JL_RNA_06/PLACEHOLDER/g' | sed 's/2-2541557.A01861_0047/*/g'| grep '\.' | sort  );
    (echo -n "illum_filelistpersample=\"";
	echo "$v" | grep -v "^report";echo "$v" | grep "^report" | head -c -1; echo "\"");
    echo
    v=$(find /lb/scratch/hdjambaz/covseq/FAL1701/2022/221021_A01861_0047_AHJF7LDRX2_CentrEAU16.FAL1701.ARTIC_v4_1-illumcovidseq*  -printf "%T@ %Tc %p\n" | sort -n | \
	grep -E -v "\.sh$|\.done$|\.bai$|\.tbi$|\.o$" | grep  -E "\.bam$|\.vcf.gz$|\.fasta$|\.fastq.gz$|\.bed$|\.tsv$|\.pdf$|\.kraken2_report$" | \
	awk -F'/lb/scratch/hdjambaz/covseq/FAL1701/2022/221021_A01861_0047_AHJF7LDRX2_CentrEAU16.FAL1701.ARTIC_v4_1-illumcovidseq/' '{print$2}' | \
	grep -v -E "JL|Pos|Neg" | sed 's|221021_A01861_0047_AHJF7LDRX2_CentrEAU16.FAL1701.ARTIC_v4_1-illumcovidseq|*|g' | grep '\.' | sort ); 
    (echo -n "illum_filelistperrun=\"";
	echo "$v" | grep -v "^report";echo "$v" | grep "^report" | head -c -1; echo "\"");
    echo
) > covid_nanopore_illum_qc_report_file_list.sh;

less -S covid_nanopore_illum_qc_report_file_list.sh

}

. ./covid_nanopore_illum_qc_report_file_list.sh;

function runreport {

k=0;
ALLPIDS=""; PID="";

RUNDIR=$1
FILT=$2

if [ "$USER" == "bravolims" ]; then
    RUNDIRROOT=/nb/Research;
    RUNDIRROOTONT=/nb;
    ROBOTDIRROOT=/lb/robot/research;
    _QOSOVERRIDE="-l qos=research"
fi

if [ "$USER" == "bravolims-qc" ]; then
    RUNDIRROOT=/lb/bravo/bravoqc/nb-Research;
    RUNDIRROOTONT=/lb/bravo/bravoqc/nb;
    ROBOTDIRROOT=/lb/bravo/bravoqc/lb-robot-research;
    _QOSOVERRIDE=""
fi

if [ "$USER" == "bravolims-dev" ]; then
    RUNDIRROOT=/lb/bravo/bravodev/nb-Research;
    RUNDIRROOTONT=/lb/bravo/bravodev/nb;
    ROBOTDIRROOT=/lb/bravo/bravodev/lb-robot-research;
    _QOSOVERRIDE=""
fi


if [[ "$RUNDIR" == *ontcovidseq* ]]; then
    ONTFOLDER=$(basename $RUNDIR | awk -F'.' '{print $1}');
    FLOWCELLID=$(basename $RUNDIR | awk -F'.' '{print $2}');
    PROJECTID=$(basename $RUNDIR |  awk -F'.' '{print $3}')    
    ARTIC=$(basename $RUNDIR |  awk -F'.' '{print $4}' | awk -F'-' '{print $1}')
    OUTDIR=$RUNDIR/agt_labqc_report
    RUNID=$(basename $RUNDIR |  awk -F'.' '{print $2}' | awk -F'_' '{print $4 "_" $5}');
else
    ONTFOLDER="";
    FLOWCELLID=$(basename $RUNDIR | awk -F'_' '{print $4}' | cut -c 2-);
    PROJECTID=$(basename $RUNDIR |  awk -F'.' '{print $2}')
    ARTIC=$(basename $RUNDIR |  awk -F'.' '{print $3}' | awk -F'-' '{print $1}')
    OUTDIR=$RUNDIR/agt_labqc_report;
    RUNID=$(basename $RUNDIR |  awk -F'.' '{print $1}' | awk -F'_' '{print $2 "_" $3}');
fi

mkdir -p $OUTDIR $OUTDIR/reads_post_ivar $OUTDIR/job_output $OUTDIR/bed_images $OUTDIR/fastp $OUTDIR/run_python_plot $OUTDIR/kraken_krona;

file_readset=$(ls $RUNDIR/*.readset.txt ); # 2>/dev/null)
file_summary=$(ls $RUNDIR/report/ncov_tools*/qc_reports/*_summary_qc.tsv 2>/dev/null | head -n 1);
file_lineages=$(ls $RUNDIR/report/ncov_tools/lineages/*lineage_report.csv 2>/dev/null );
RAWFASTQDIR=$(ls -d /nb/Research/processing/$(basename $RUNDIR | awk -F'.' '{print $1}')* 2>/dev/null);

_EVENTFILE=$(ls $OUTDIR/eventfile.* 2>/dev/null)
if [ ! -f "$_EVENTFILE" ]; then
    YEAR=$(date +%Y);
    A=$(grep -l $FLOWCELLID $ROBOTDIRROOT/processing/events/system/$YEAR/*-valid/*samples*.txt $ROBOTDIRROOT/processing/events/system/$(($YEAR-1))/*-valid/*samples*.txt 2>/dev/null);
    f=$(echo "$A" | tail -n 1);
    _EVENTFILE=$OUTDIR/eventfile.$(basename $f);
    cp $f $_EVENTFILE
fi

NEG_CTRL_LIST="";
POS_CTRL_LIST="";
SAMPLE_LIST=""
SAMPLECOUNT=0;
if [ -f "$_EVENTFILE" ]; then
    NEG_CTRL_LIST=$(cat $_EVENTFILE | awk -F'\t' '$2=="'$PROJECTID'"{print $13}' | sort -u | grep -E "NegCtrl|blank");
    POS_CTRL_LIST=$(cat $_EVENTFILE | awk -F'\t' '$2=="'$PROJECTID'"{print $13}' | sort -u | grep -E "PosCtrl");
    SAMPLE_LIST=$(cat $_EVENTFILE | awk -F'\t' '$2=="'$PROJECTID'"{print $13}' | sort -u | grep -v -E "NegCtrl|PosCtrl|blank");
    ALLSAMPLE_LIST=$(cat $_EVENTFILE | awk -F'\t' '$2=="'$PROJECTID'"{print $13}' | sort -u);
    SAMPLECOUNT=$(cat $_EVENTFILE | awk -F'\t' '$2=="'$PROJECTID'"{print $13}' | sort -u | wc -l);
fi

echo "STEP: yield plots"

if [[ "$RUNDIR" == *ontcovidseq* ]]; then

for token in $(echo "$NEG_CTRL_LIST"; echo "$POS_CTRL_LIST"; echo "$SAMPLE_LIST"; echo "all_samples"); do
    
    if [ "$token" == "all_samples" ]; then
	_token="barcode*"
    else
	_token=$(cat $_EVENTFILE | awk -F'\t' '$13=="'$token'"{print "barcode"substr($7,length($7)-1,length($7))}');
    fi

COMM=$(cat <<EOF
if [ "\$(ls $ROBOTDIRROOT/promethion/*/$ONTFOLDER/$FLOWCELLID/fastq_pass/$_token/*.fastq.gz | head -n 1 | wc -l)" == "1" ]; then
  zcat $ROBOTDIRROOT/promethion/*/$ONTFOLDER/$FLOWCELLID/fastq_pass/$_token/*fastq.gz > $OUTDIR/run_python_plot/$(basename $RUNDIR).$token.fastq;
else
  cat $ROBOTDIRROOT/promethion/*/$ONTFOLDER/$FLOWCELLID/fastq_pass/$_token/*.fastq > $OUTDIR/run_python_plot/$(basename $RUNDIR).$token.fastq;
fi
. ./covid_nanopore_illum_qc_report.sh;
run_python_plot $OUTDIR/run_python_plot/$(basename $RUNDIR).$token.fastq $OUTDIR/run_python_plot/$(basename $RUNDIR).$token pass 0.003;
rm $OUTDIR/run_python_plot/$(basename $RUNDIR).$token.fastq;
EOF
);

QUEUE=sw; PROC=2; DAYS=1;
if [ ! -f "$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_read_histograms.png" ]; then
    PID=$(echo "$COMM" | qsub -d $(pwd) -V -l walltime=$DAYS:00:00:0 -q $QUEUE -l nodes=1:ppn=$PROC $_QOSOVERRIDE -j oe -N $token.run_python_plot \
	-o ${OUTDIR}/job_output/$token.run_python_plot.o | awk -F'.' '{print $1}');
    ALLPIDS=$(printf "$ALLPIDS\n$PID\n");
fi

done

    TECH="Nanopore";

    QCSelectN=$(echo $(basename $RUNDIR) | awk -F'_' '{print $3}' | sed 's/QCselect//g');

    YIELDDATA=$OUTDIR/yield.tsv;
    
    if [ ! -f "$YIELDDATA" ]; then
	
	ontseqsummary=$(ls $ROBOTDIRROOT/promethion/*/*/$(basename $RUNDIR | awk -F'.' '{print $2}')/sequencing_summary_*.txt)

	index_passes_filtering=$(head -n 1  $ontseqsummary | tr '\t' '\n' | awk '{print NR " " $0}' | grep "passes_filtering" | awk '{print $1}')
	index_alias=$(head -n 1  $ontseqsummary | tr '\t' '\n' | awk '{print NR " " $0}' | grep "alias" | awk '{print $1}')
	index_sequence_length_template=$(head -n 1  $ontseqsummary | tr '\t' '\n' | awk '{print NR " " $0}' | grep "sequence_length_template" | awk '{print $1}')
		
	( printf "Sample name\tRead count\tRead bases\n";
	    cat $ontseqsummary | awk -F'\t' '$'$index_passes_filtering' == "TRUE"{print $'$index_alias' "\t" $'$index_sequence_length_template'}' | \
		awk '{FS="\t";OFS="\t"}{a[$1] += 1; b[$1] += $2} END{for (i in a) print i, a[i], b[i]}' | sort;
	) > $YIELDDATA.tmp;
	( printf "Sample name\tRead count\tRead bases\n";
	    cat $ontseqsummary | awk -F'\t' '$'$index_passes_filtering' == "TRUE"{print $'$index_alias' "\t" $'$index_sequence_length_template'}' | \
		awk '{FS="\t";OFS="\t"}{a += 1; b += $2} END{ printf "Total reads\t%i\t%i\n",  a, b}';
	) > $YIELDDATA.tmp.total;
	
	V=$(cat $_EVENTFILE | awk -F'\t' '{print $13 "\t" "barcode"substr($7,length($7)-1,length($7))}');
	
	(
	    printf "Sample name\tRead count\tRead bases\n"; 
	    for bc in $(seq 1 96 | awk '{printf "%02d\n", $1}'); do
		Vyield=$(grep -w barcode$bc $YIELDDATA.tmp);
		Vevent=$(echo "$V" | grep -w barcode$bc);
		Vreadset=$(grep -w barcode$bc $file_readset);
		
		if [ "$Vreadset" == "" ]; then
		    XTRA="";
		else
		    XTRA="* ";
		fi
		
		if [ "$Vevent" == "" ];then
		    if [ "$Vyield" == "" ]; then
			printf "barcode$bc\t0\t0\n"
		    else
			echo "$Vyield";
		    fi
		else
		    SN=$(echo "$Vevent" | awk -F'\t' '{print $1}')
		    if [ "$Vyield" == "" ]; then
			printf "$XTRA$SN-barcode$bc\t0\t0\n"
		    else
			COUNT=$(echo "$Vyield" | awk -F'\t' '{print $2}');
			BASES=$(echo "$Vyield" | awk -F'\t' '{print $3}');
			printf "$XTRA$SN-barcode$bc\t$COUNT\t$BASES\n"
		    fi	    
		fi
		
	    done | sort -t$'\t' -nrk2
	) >  $YIELDDATA;
	
   fi
    
    COMM=$(cat <<EOF
import itertools
import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter

dat=pd.read_csv("$YIELDDATA", sep='\t');

fig,ax1 = plt.subplots()
fig.set_size_inches(16, 8)
ax1.plot(dat.index,dat["Read count"]/1000,".-", color="#648FFF",markerfacecolor="#648FFF")
ax1.set_xlabel('Sample name (* part of this project)');
ax1.set_ylabel('Read count (K) - blue');
ax1.set_xticks(np.arange(len(dat["Sample name"])))
ax1.set_xticklabels(dat["Sample name"],rotation=90, ha='center', fontsize=8);
ax1.yaxis.set_major_formatter(FormatStrFormatter('%dK'))
ax1.xaxis.grid()
ax1.yaxis.grid()
ax2=ax1.twinx()
ax2.plot(dat.index,dat["Read bases"]/1000000,".-",color="#DC267F", markerfacecolor="#DC267F")
ax2.set_ylabel('Read bases (Mb) - magenta');
ax2.yaxis.set_major_formatter(FormatStrFormatter('%dMb'))
fig.suptitle("$(basename $RUNDIR)", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("$YIELDDATA.png",dpi=100)
plt.close(fig)

EOF
	);
	
	module purge
	module load mugqic/python/3.6.5     
	echo "$COMM" | python3
	
filelistperrun=$ont_filelistperrun;
filelistpersample=$ont_filelistpersample;

else # illumina

for token in $(echo "$NEG_CTRL_LIST"; echo "$POS_CTRL_LIST"; echo "$SAMPLE_LIST"; echo "all_samples"); do

    if [ "$token" == "all_samples" ]; then
	_token="*"
    else
	_token="*$token*";
    fi
    
COMM=$(cat <<EOF
if [ "\$(ls $RUNDIRROOT/processing/$(basename $RUNDIR | awk -F'.' '{print $1}')*/U*/P*/S$_token/*R1_001.fastq.gz | head -n 1 | wc -l)" == "1" ]; then
  zcat $RUNDIRROOT/processing/$(basename $RUNDIR | awk -F'.' '{print $1}')*/U*/P*/S$_token/*R1_001.fastq.gz | head -n 40000000 > $OUTDIR/fastp/$(basename $RUNDIR).$token.R1_001.fastq;
  zcat $RUNDIRROOT/processing/$(basename $RUNDIR | awk -F'.' '{print $1}')*/U*/P*/S$_token/*R2_001.fastq.gz | head -n 40000000 > $OUTDIR/fastp/$(basename $RUNDIR).$token.R2_001.fastq;
else
  zcat $ROBOTDIRROOT/processing/*/*/$(basename $RUNDIR | awk -F'.' '{print $1}')*/U*/P*/S$_token/*R1_001.fastq.gz | head -n 40000000 > $OUTDIR/fastp/$(basename $RUNDIR).$token.R1_001.fastq;
  zcat $ROBOTDIRROOT/processing/*/*/$(basename $RUNDIR | awk -F'.' '{print $1}')*/U*/P*/S$_token/*R2_001.fastq.gz | head -n 40000000 > $OUTDIR/fastp/$(basename $RUNDIR).$token.R2_001.fastq;
fi
module load mugqic/fastp/0.23.2;
rm -f $OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.json $OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
fastp \
  --in1 $OUTDIR/fastp/$(basename $RUNDIR).$token.R1_001.fastq \
  --in2 $OUTDIR/fastp/$(basename $RUNDIR).$token.R2_001.fastq \
  --thread $PROC \
  --json $OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.json \
  --html $OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
rm $OUTDIR/fastp/$(basename $RUNDIR).$token.R1_001.fastq;
rm $OUTDIR/fastp/$(basename $RUNDIR).$token.R2_001.fastq;
EOF
);
if [ ! -f "$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html" ]; then
    QUEUE=sw; PROC=1; DAYS=1;
    PID=$(echo "$COMM" | qsub -d $(pwd) -V -l walltime=$DAYS:00:00:0 -q $QUEUE -l nodes=1:ppn=$PROC $_QOSOVERRIDE -j oe -N $token.fastp \
	-o ${OUTDIR}/job_output/$token.fastp.o | awk -F'.' '{print $1}');
    ALLPIDS=$(printf "$ALLPIDS\n$PID\n");
fi

done

    TECH="Illumina";
    
    YIELDDATA=$OUTDIR/yield.tsv;
    if [ ! -f "$YIELDDATA" ]; then
	printf "Sample name\tRead count\tRead bases\n" >  $YIELDDATA.tmp;
	printf "Sample name\tRead count\tRead bases\n" >  $YIELDDATA.tmp.total;
	ALLLANES="1 2 3 4";
	RAWFASTQDIR=$(ls -d $RUNDIRROOT/processing/$(basename $RUNDIR | awk -F'.' '{print $1}')*)
	for LANE in $(echo $ALLLANES | tr ' ' '\n'); do
	    f=${RAWFASTQDIR}/Unaligned.${LANE}.indexed/Stats/Stats.json;
	    if [ ! -f "$f" ]; then
		f=${RAWFASTQDIR}/Unaligned.${LANE}/Stats/Stats.json;
	    fi
	    if [ -f "$f" ]; then
		cat $f | grep -A11 -E "SampleName|Undetermined" | grep -E "Undetermined|SampleName|NumberReads|Yield" \
		    | sed 's/Undetermined/~/g' |sed 's/SampleName/~/g' |sed 's/NumberReads//g'|sed 's/Yield//g' \
		    | tr -d '\n' | tr '~' '\n' | tr -d '"' | sed 's/{/Undetermined/g' \
		    | tr -d ',' | tr -d ' ' | grep -v "^$" |cut -c 2-  \
		    | awk -F':' '{printf "%s\t%i\t%i\n", $1, $2, $3}' >> $YIELDDATA.tmp;
		cat $f | grep  -E "TotalClustersPF|Yield" | head -n 2 | tr -d ',' | awk -F":" '{print $2}' | awk '{print $1}' | tr '\n' ',' | rev | cut -c 2- | rev \
		    | awk -F',' '{printf "Total PF L00'$LANE'\t%i\t%i\n", $1, $2}' >> $YIELDDATA.tmp.total;
	    fi
	done

	printf "Sample name\tRead count\tRead bases\n" >  $YIELDDATA	
	if [ "$FILT" == "" ]; then
	    tail -n+2 $YIELDDATA.tmp | grep -v "Undetermined" | awk -F'\t' '{ a[$1]+=$2; b[$1]+=$3}END{ for(i in a) print i"\t" a[i]"\t" b[i] }' | sort -t$'\t' -nrk2 >> $YIELDDATA
	else
	    tail -n+2 $YIELDDATA.tmp | grep -v -E "Undetermined|$FILT" | awk -F'\t' '{ a[$1]+=$2; b[$1]+=$3}END{ for(i in a) print i"\t" a[i]"\t" b[i] }' | sort -t$'\t' -nrk2 >> $YIELDDATA
	fi

	
	COMM=$(cat <<EOF
import itertools
import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter

dat=pd.read_csv("$YIELDDATA", sep='\t');

fig,ax1 = plt.subplots()
fig.set_size_inches(20, 8)
ax1.plot(dat.index,dat["Read count"]/1000000,".-", color="#648FFF",markerfacecolor="#648FFF")
ax1.set_xlabel('Sample name');
ax1.set_ylabel('Read count (M) - blue');
ax1.set_xticks(np.arange(len(dat["Sample name"])))
ax1.set_xticklabels(dat["Sample name"],rotation=90, ha='center', fontsize=8);
ax1.yaxis.set_major_formatter(FormatStrFormatter('%dM'))
ax1.xaxis.grid()
ax1.yaxis.grid()
ax2=ax1.twinx()
ax2.plot(dat.index,dat["Read bases"]/1000000000,".-",color="#DC267F", markerfacecolor="#DC267F")
ax2.set_ylabel('Read bases (Gb) - magenta');
ax2.yaxis.set_major_formatter(FormatStrFormatter('%dGb'))
fig.suptitle("$(basename $RUNDIR)", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("$YIELDDATA.png",dpi=100)
plt.close(fig)

EOF
	);
	
	module purge
	module load mugqic/python/3.6.5     
	echo "$COMM" | python3
	
    fi

    filelistperrun=$illum_filelistperrun;
    filelistpersample=$illum_filelistpersample;
    
fi

    PIPELINE=$(cat <<EOF
Covid Sequencing Quality Control Report Version 1.0
Author: Haig Djambazian

This report is compatible with Genpipes Illumina and Nanopore covid pipelines. For this report we run additional steps and create extra figures for laboratory QC purposes. Raw run yields are extracted from either bcl2fastq statistics files (json) for Illumina or from summary QC files for nanopore runs. Either fastp/plot.ly or python is used to display insert size histograms, readlength histograms and quality profiles. The report is aware of positive and negative control samples and displays these types of samples more prominently than other samples in the run. Extra kraken2 jobs are run after primer trimming (post ivar trimming) to observe the presence or absence of sequence for the controls. All kraken results for the controls are visualized with krona (and phantomjs). The report also includes a warning status table as well as table with embedded logs for the jobs run in the pipeline. An additional table shows the presence and absence of files from the pipeline regardless of the status.

This instance of the report used $TECH sequencing and the Genpipes $TECH covid pipeline (version: $(grep '# Version'  $RUNDIR/*.sh 2>/dev/null | sed 's/# Version: //g' | tail -n 1)).

Illumina Covid Pipeline pipeline source code is hosted on bitbucket here:
<a href="https://bitbucket.org/mugqic/genpipes/src/master/pipelines/covseq">https://bitbucket.org/mugqic/genpipes/src/master/pipelines/covseq</a>
Pipeline steps map:
<img src="https://genpipes.readthedocs.io/en/genpipes-v4.3.1/_images/covseq.mmd.png" width="75%">

Nanopore Covid Pipeline pipeline source code is hosted on bitbucket here:
<a href="https://bitbucket.org/mugqic/genpipes/src/master/pipelines/covseq_nanopore">https://bitbucket.org/mugqic/genpipes/src/master/pipelines/covseq_nanopore</a>
Pipeline steps map:
Default:
<img src="https://genpipes.readthedocs.io/en/genpipes-v4.3.1/_images/nanopore_covseq_df.png" width="50%">
Basecalling:
<img src="https://genpipes.readthedocs.io/en/genpipes-v4.3.1/_images/nanopore_covseq_bc.png" width="50%">
 
EOF
);


echo "STEP: job list"

CNT=$(ls $RUNDIR/job_output/*_job_list* | wc -l)
if [ "$CNT" -gt "0" ]; then
    redo=false
    if [ -f "$OUTDIR/$(basename $RUNDIR)-jobstatus.html.CNT" ]; then
	if [ "$CNT" != "$(cat $OUTDIR/$(basename $RUNDIR)-jobstatus.html.CNT)" ]; then
	    redo=true
	fi
    else
	redo=true
    fi

    if($redo); then
	if [[ "$RUNDIR" == *ontcovidseq* ]]; then
	    . ./make_job_output_table_generic.sh; makejobtable $OUTDIR NanoporeCoVSeq_job_list $RUNDIR; # file=$(basename $RUNDIR)-run.html;
	else
	    . ./make_job_output_table_generic.sh; makejobtable $OUTDIR CoVSeq $RUNDIR;
	fi	
	mv $OUTDIR/$(basename $RUNDIR)-run.html  $OUTDIR/$(basename $RUNDIR)-jobstatus.html
	echo $CNT > $OUTDIR/$(basename $RUNDIR)-jobstatus.html.CNT	
    fi
    
fi


echo "STEP: neg warn"

outfile_run_valid=$OUTDIR/run.validation.QC$QCSelectN.csv

file_neg=$(ls $RUNDIR/report/ncov_tools*/qc_reports/*_negative_control_report.tsv 2>/dev/null)

GENERATE_NEGWARN=false;
OKTOKEN="LAB_PASS";
if [ -f "$file_neg" ]; then
    if [ "$(grep -c WARN $file_neg)" -gt "0" ]; then 
	GENERATE_NEGWARN=true;
	OKTOKEN="LAB_PENDING";
    fi
else
    GENERATE_NEGWARN=true;
fi

OKTOKEN="LAB_PASS"; # xxxxx

if [ -f "$_EVENTFILE" ]; then    

    n1=$(echo "$filelistperrun" |  awk '{printf ","}')
    n2=$(echo "$filelistpersample" | awk '{printf ","}')
    
    header1=$(
	echo -n "Sample_Name,";
	for el in $(echo "$filelistperrun"); do
	    echo -n "$el,"
	done | rev | cut -c 2- | rev| tr -d '\n';
	echo "";
    )
    
    # https://www.toptal.com/designers/htmlarrows/symbols/
    
    body1=$(
	echo -n "<td>global_files</td>"
	for el in $(echo "$filelistperrun"); do
	    f=$(ls $RUNDIR/$el 2>/dev/null);
	    if [ -f "$f" ]; then
		echo -n "<td style=\"background-color:#77DD76;\" align=\"center\">&#10004;</td>";
	    else
		echo -n "<td style=\"background-color:#FF6962;\" align=\"center\">&#10006;</td>";
	    fi
	done | rev | cut -c 2- | rev | tr -d '\n';
	echo "";
    );

    header2=$(
	echo -n "Sample_Name,";
	for el in $(echo "$filelistpersample" ); do
	    echo -n "$el,"
	done | rev | cut -c 2- | rev| tr -d '\n';
	echo "";
    )
    
    body2=$(
	for sample in $(echo "$NEG_CTRL_LIST"); do
	    echo -n "<td>$sample</td>"
	    for el in $(echo "$filelistpersample"); do
		f=$(ls $RUNDIR/$(echo "$el" | sed "s/PLACEHOLDER/$sample/g") 2>/dev/null);
		if [ -f "$f" ]; then
	       	    echo -n "<td style=\"background-color:#77DD76;\" align=\"center\">&#10004;</td>";
		else
		    echo -n "<td style=\"background-color:#FF6962;\" align=\"center\">&#10006;</td>";
		fi
	    done | rev | cut -c 2- | rev | tr -d '\n';
	    echo "";
	done
	for sample in $(echo "$POS_CTRL_LIST"); do
	    echo -n "<td>$sample</td>"
	    for el in $(echo "$filelistpersample"); do
		f=$(ls $RUNDIR/$(echo "$el" | sed "s/PLACEHOLDER/$sample/g") 2>/dev/null);
		if [ -f "$f" ]; then
	       	    echo -n "<td style=\"background-color:#77DD76;\" align=\"center\">&#10004;</td>";
		else
		    echo -n "<td style=\"background-color:#FF6962;\" align=\"center\">&#10006;</td>";
		fi
	    done | rev | cut -c 2- | rev | tr -d '\n';
	    echo "";
	done
	for sample in $(echo "$SAMPLE_LIST"); do
	    echo -n "<td>$sample</td>"
	    for el in $(echo "$filelistpersample"); do
		f=$(ls $RUNDIR/$(echo "$el" | sed "s/PLACEHOLDER/$sample/g") 2>/dev/null);
		if [ -f "$f" ]; then
	       	    echo -n "<td style=\"background-color:#77DD76;\" align=\"center\">&#10004;</td>";
		else
		    echo -n "<td style=\"background-color:#FF6962;\" align=\"center\">&#10006;</td>";
		fi
	    done | rev | cut -c 2- | rev | tr -d '\n';
	    echo "";
	done 
    );



# 
# $(echo "$header2" | tr ',' '\n' | awk '{printf NR","}' | rev | cut -c 2- | rev | sed 's|,|</span></div></th><th class="rotate"><div><span>|g' | awk '{print "<tr><th class=\"rotate\"><div><span>"$0"</span></div></th></tr>"}')


    let k=$k+1
    let k2=$k+1
    FILE_STATUS_TABLE=$(cat <<EOF
<table class="table table-header-rotated">
$(echo "$header1" |  sed 's/PLACEHOLDER/*/g' | sed 's|,|</span></div></th><th class="rotate-45"><div><span>|g' | awk '{print "<tr><th class=\"rotate-45\"><div><span>"$0"</span></div></th></tr>"}')
$(echo "$body1" | awk '{print "<tr>"$0"</tr>"}')
</table>
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide table header</button>
<div id="myDIV$k">
$(printf "Sample Name\n$filelistperrun" | awk '{print NR ": " $0 "<br>"}')
</div>
<br>
<br>
<table class="table table-header-rotated">
$(echo "$header2" |  sed 's/PLACEHOLDER/*/g' | sed 's|,|</span></div></th><th class="rotate-45"><div><span>|g' | awk '{print "<tr><th class=\"rotate-45\"><div><span>"$0"</span></div></th></tr>"}')
$(echo "$body2" | awk '{print "<tr>"$0"</tr>"}')
</table>
<button onclick="hideshowsummarytable('myDIV$k2')">Click to show/hide table header</button><br>
<div id="myDIV$k2">
$((echo "Sample Name"; echo "$filelistpersample" | sed 's/PLACEHOLDER/*/g') | awk '{print NR ": " $0 "<br>"}')
</div>
<br>
EOF
    );
    let k=$k2
fi

if [ -f "$file_summary" ]; then
    SAMPLEOUTPUT=$(tail -n+2 $file_summary | wc -l)
else
    SAMPLEOUTPUT=$( ls $RUNDIR/report/ncov_tools_ivar/data/*.consensus.fasta | wc -l)
fi

if [ -f "$file_summary" ]; then

    QC_FLAG_TABLE=$(tail -n+2 $file_summary | awk -F'\t' '{print $16}' | sort | uniq -c | sort -nrk1 |  awk '{print $2"\t"$1}')    
    QC_CALL_TABLE=$(tail -n+2 $file_summary | awk -F'\t' '{print $16"|"$17"|"$20}' | sort | uniq -c |  awk '{print $2"\t"$1}' | tr '|' '\t')

else

    QC_FLAG_TABLE=""
    QC_CALL_TABLE=""
fi


echo "STEP: in/out tables"

NUMBERINCOMPLETE=$(echo "$QC_FLAG_TABLE" | grep -w "INCOMPLETE_GENOME"  | awk -F'\t' '{sum+=$2;} END{print sum;}');
REALNUMBERINCOMPLETE=$(( $NUMBERINCOMPLETE + $SAMPLECOUNT - $SAMPLEOUTPUT ));
REALPCTINCOMPLETE=$(echo " " | awk '{printf "%0.2f", '$REALNUMBERINCOMPLETE'*100/'$SAMPLECOUNT'}');
if (( $(echo "$REALPCTINCOMPLETE > 25" |bc -l) )); then
    GENERATE_INCOMPLETEWARN=true;
else
    GENERATE_INCOMPLETEWARN=false;
fi




a=$ALLSAMPLE_LIST;
if [ -f "$file_summary" ]; then
    b=$(tail -n+2 $file_summary | awk -F'\t' '{print $1}' | sort -u );
else
    b=""
fi

(
    echo  "Sample,Readset,Run,RunValidation_Status"
    for lab_rej in $(comm -23 <(echo "$a") <(echo "$b")); do
	grep $lab_rej $file_readset | awk -F'\t' '{print $1 "," $2 "," $3 "," "LAB_REJ"}'
    done
    
    for lab_ok in $(comm -12 <(echo "$a") <(echo "$b")); do
	grep $lab_ok $file_readset | awk -F'\t' '{print $1 "," $2 "," $3 "," "'$OKTOKEN'"}'
    done
    
) > $outfile_run_valid


echo "STEP: bed plots"
NBED=9

BED_PLOTS_NEG=$(
    echo "<table class=\"style1\">";

    for token2 in amplicon_depth per_base_coverage; do
	echo -n "<tr>"
	for token1 in $(echo "$NEG_CTRL_LIST"); do
	    # for token2 in amplicon_base_coverage amplicon_coverage amplicon_depth per_base_coverage; do
	    echo -n "<td>";
	    onebed=true;
	    for f in $RUNDIR/report/ncov_tools*/qc_sequencing/$token1*.$token2.bed; do
		if [ -f "$f" ]; then
		    # onebed=true;
		    if($onebed); then
			onebed=false;
		    else
			break;
		    fi

		    BedName=$(basename $f)
		    
		    if [ "$token2" == "per_base_coverage" ]; then
			COL="depth";
			XAX="Bases (bp)"
		    fi
		    if [ "$token2" == "amplicon_depth" ]; then
			COL="mean_depth";
			XAX="Amplicon ID"
		    fi
		    
		    COMM=$(cat <<EOF
import itertools
import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

dat=pd.read_csv("$f", sep='\t');

fig,ax1 = plt.subplots()
ax1.step(dat.index,dat["$COL"]+0.5,color="#648FFF")
ax1.set_yscale('log')
ax1.set_xlabel('$XAX');
ax1.set_ylabel('$token2+0.5 - blue');
[y1, y2] = plt.gca().get_ylim()
# 5000
if(y2<5000):
  y2=5000;
plt.ylim([0.4, y2])
# ax1.xaxis.grid()
ax1.yaxis.grid()
fig.suptitle("$BedName", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("$OUTDIR/bed_images/$BedName.png",dpi=100)
plt.close(fig)

EOF
		    );
		    
		    module purge
		    module load mugqic/python/3.6.5
		    if [ ! -f "$OUTDIR/bed_images/$BedName.png" ]; then
			echo "$COMM" | python3
		    fi
		fi
	       
		# echo -n "$(echo $f | rev | cut -d '/' -f 1-4 | rev)<br>";
		
		if [ -f "$f" ]; then
		    echo -n "<table class=\"style4\">";
		    echo -n "<tr><th colspan=\"2\">$(echo $f | rev | cut -d '/' -f 1-4 | rev)</th></tr>"
		    echo -n "<tr>"
		    echo -n "<td>"
		    echo -n "<img src=\"data:image/png;base64,$(base64 $OUTDIR/bed_images/$BedName.png | tr -d ' ' | tr -d '\n')\" width=\"450\">";
		    echo -n "</td>"
		    echo -n "<td>"
		    if [ "$token2" == "per_base_coverage" ]; then
			COV_TABLE=$(
			    head -n 1 $f | awk -F'\t' '{print $4 "\t" $5}';
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk5 | awk -F',' '{print $4 "\t" $5}' | head -n $NBED;
			    printf "Top/Bottom $NBED\t \n";
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk5 | awk -F',' '{print $4 "\t" $5}' | tail -n $NBED;
			);
			echo -n "<table class=\"style6\">";
			echo "$COV_TABLE" | head -n 1 | awk '{print "<tr><th width=\"70\">"$0"</th></tr>"}' | sed 's|\t|</th><th width="70">|g' | tr -d '\n';
			echo "$COV_TABLE" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g' | tr -d '\n';
			echo -n "</table>";
		    else
			COV_TABLE=$(
			    head -n 1 $f | awk -F'\t' '{print $4 "\t" $7}';
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk7 | awk -F',' '{print $4 "\t" $7}' | head -n $NBED;
			    printf "Top/Bottom $NBED\t \n";
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk7 | awk -F',' '{print $4 "\t" $7}' | tail -n $NBED;
			);
			echo -n "<table class=\"style6\">";
			echo "$COV_TABLE" | head -n 1 | awk '{print "<tr><th width=\"70\">"$0"</th></tr>"}' | sed 's|\t|</th><th width="70">|g' | tr -d '\n';
			echo "$COV_TABLE" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g' | tr -d '\n';
			echo -n "</table>";
		    fi
		    echo -n "</td>"
		    echo -n "</tr>"
		    echo -n "</table>";
		    echo -n "<br>";
		else
		    echo -n "<br><br><br>*** bed file missing ***"
		fi
		
	    done
	echo -n "</td>";
	done
	echo "</tr>"
    done
    
    echo "</table>"
    
)


BED_PLOTS_POS=$(
    echo "<table class=\"style1\">";

    for token2 in amplicon_depth per_base_coverage; do
	echo -n "<tr>"
	for token1 in $(echo "$POS_CTRL_LIST"); do
	    # for token2 in amplicon_base_coverage amplicon_coverage amplicon_depth per_base_coverage; do
	    echo -n "<td>";
	    onebed=true;
	    for f in $RUNDIR/report/ncov_tools*/qc_sequencing/$token1*.$token2.bed; do
		if [ -f "$f" ]; then
		    # onebed=true;
		    if($onebed); then
			onebed=false;
		    else
			break;
		    fi

		    BedName=$(basename $f)
		    
		    if [ "$token2" == "per_base_coverage" ]; then
			COL="depth";
			XAX="Bases (bp)"
		    fi
		    if [ "$token2" == "amplicon_depth" ]; then
			COL="mean_depth";
			XAX="Amplicon ID"
		    fi
		    
		    COMM=$(cat <<EOF
import itertools
import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

dat=pd.read_csv("$f", sep='\t');

fig,ax1 = plt.subplots()
ax1.step(dat.index,dat["$COL"]+0.5,color="#648FFF")
ax1.set_yscale('log')
ax1.set_xlabel('$XAX');
ax1.set_ylabel('$token2+0.5 - blue');
[y1, y2] = plt.gca().get_ylim()
# 5000
if(y2<5000):
  y2=5000;
plt.ylim([0.4, y2])
# ax1.xaxis.grid()
ax1.yaxis.grid()
fig.suptitle("$BedName", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("$OUTDIR/bed_images/$BedName.png",dpi=100)
plt.close(fig)

EOF
		    );
		    
		    module purge
		    module load mugqic/python/3.6.5     
		    if [ ! -f "$OUTDIR/bed_images/$BedName.png" ]; then
			echo "$COMM" | python3
		    fi
		fi
		
		# echo -n "$(echo $f | rev | cut -d '/' -f 1-4 | rev)<br>";
		
		if [ -f "$f" ]; then
		    echo -n "<table class=\"style4\">";
		    echo -n "<tr><th colspan=\"2\">$(echo $f | rev | cut -d '/' -f 1-4 | rev)</th></tr>"
		    echo -n "<tr>"
		    echo -n "<td>"
		    echo -n "<img src=\"data:image/png;base64,$(base64 $OUTDIR/bed_images/$BedName.png | tr -d ' ' | tr -d '\n')\" width=\"450\">";		    
		    echo -n "</td>"
		    echo -n "<td>"
		    if [ "$token2" == "per_base_coverage" ]; then
			COV_TABLE=$(
			    head -n 1 $f | awk -F'\t' '{print $4 "\t" $5}';
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk5 | awk -F',' '{print $4 "\t" $5}' | head -n $NBED;
			    printf "Top/Bottom $NBED\t \n";
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk5 | awk -F',' '{print $4 "\t" $5}' | tail -n $NBED;
			);
			echo -n "<table class=\"style6\">";
			echo "$COV_TABLE" | head -n 1 | awk '{print "<tr><th width=\"70\">"$0"</th></tr>"}' | sed 's|\t|</th><th width="70">|g' | tr -d '\n';
			echo "$COV_TABLE" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g' | tr -d '\n';
			echo -n "</table>";
		    else
			COV_TABLE=$(
			    head -n 1 $f | awk -F'\t' '{print $4 "\t" $7}';
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk7 | awk -F',' '{print $4 "\t" $7}' | head -n $NBED;
			    printf "Top/Bottom $NBED\t \n";
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk7 | awk -F',' '{print $4 "\t" $7}' | tail -n $NBED;
			);
			echo -n "<table class=\"style6\">";
			echo "$COV_TABLE" | head -n 1 | awk '{print "<tr><th width=\"70\">"$0"</th></tr>"}' | sed 's|\t|</th><th width="70">|g' | tr -d '\n';
			echo "$COV_TABLE" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g' | tr -d '\n';
			echo -n "</table>";
		    fi
		    echo -n "</td>"
		    echo -n "</tr>"
		    echo -n "</table>";
		    echo -n "<br>";
		else
		    echo -n "<br><br><br>*** bed file missing ***"
		fi
		
	    done
	echo -n "</td>";
	done
	echo "</tr>"
    done
    
    echo "</table>"
    
)



BED_PLOTS2=$(
    echo "<table class=\"style1\">";

    for token2 in amplicon_depth per_base_coverage; do
	echo -n "<tr>"
	for token1 in $(echo "$SAMPLE_LIST"); do
	    # for token2 in amplicon_base_coverage amplicon_coverage amplicon_depth per_base_coverage; do
	    echo -n "<td>";
	    onebed=true;
	    for f in $RUNDIR/report/ncov_tools*/qc_sequencing/$token1*.$token2.bed; do
		if [ -f "$f" ]; then
		    # onebed=true;
		    if($onebed); then
			onebed=false;
		    else
			break;
		    fi

		    BedName=$(basename $f)
		    
		    if [ "$token2" == "per_base_coverage" ]; then
			COL="depth";
			XAX="Bases (bp)"
		    fi
		    if [ "$token2" == "amplicon_depth" ]; then
			COL="mean_depth";
			XAX="Amplicon ID"
		    fi
		    
		    COMM=$(cat <<EOF
import itertools
import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

dat=pd.read_csv("$f", sep='\t');

fig,ax1 = plt.subplots()
ax1.step(dat.index,dat["$COL"]+0.5,color="#648FFF")
ax1.set_yscale('log')
ax1.set_xlabel('$XAX');
ax1.set_ylabel('$token2+0.5 - blue');
[y1, y2] = plt.gca().get_ylim()
# 5000
if(y2<5000):
  y2=5000;
plt.ylim([0.4, y2])
# ax1.xaxis.grid()
ax1.yaxis.grid()
fig.suptitle("$BedName", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("$OUTDIR/bed_images/$BedName.png",dpi=100)
plt.close(fig)

EOF
		    );
		    
		    module purge
		    module load mugqic/python/3.6.5     
		    if [ ! -f "$OUTDIR/bed_images/$BedName.png" ]; then
			echo "$COMM" | python3
		    fi
		fi
		
		# echo -n "$(echo $f | rev | cut -d '/' -f 1-4 | rev)<br>";
		
		if [ -f "$f" ]; then
		    echo -n "<table class=\"style4\">";
		    echo -n "<tr><th colspan=\"2\">$(echo $f | rev | cut -d '/' -f 1-4 | rev)</th></tr>"
		    echo -n "<tr>"
		    echo -n "<td>"
		    echo -n "<img src=\"data:image/png;base64,$(base64 $OUTDIR/bed_images/$BedName.png | tr -d ' ' | tr -d '\n')\" width=\"450\">";		    
		    echo -n "</td>"
		    echo -n "<td>"
		    if [ "$token2" == "per_base_coverage" ]; then
			COV_TABLE=$(
			    head -n 1 $f | awk -F'\t' '{print $4 "\t" $5}';
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk5 | awk -F',' '{print $4 "\t" $5}' | head -n $NBED;
			    printf "Top/Bottom $NBED\t \n";
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk5 | awk -F',' '{print $4 "\t" $5}' | tail -n $NBED;
			);
			echo -n "<table class=\"style6\">";
			echo "$COV_TABLE" | head -n 1 | awk '{print "<tr><th width=\"70\">"$0"</th></tr>"}' | sed 's|\t|</th><th width="70">|g' | tr -d '\n';
			echo "$COV_TABLE" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g' | tr -d '\n';
			echo -n "</table>";
		    else
			COV_TABLE=$(
			    head -n 1 $f | awk -F'\t' '{print $4 "\t" $7}';
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk7 | awk -F',' '{print $4 "\t" $7}' | head -n $NBED;
			    printf "Top/Bottom $NBED\t \n";
			    tail -n+2 $f | tr '\t' ',' | sort -t$',' -nrk7 | awk -F',' '{print $4 "\t" $7}' | tail -n $NBED;
			);
			echo -n "<table class=\"style6\">";
			echo "$COV_TABLE" | head -n 1 | awk '{print "<tr><th width=\"70\">"$0"</th></tr>"}' | sed 's|\t|</th><th width="70">|g' | tr -d '\n';
			echo "$COV_TABLE" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g' | tr -d '\n';
			echo -n "</table>";
		    fi
		    echo -n "</td>"
		    echo -n "</tr>"
		    echo -n "</table>";
		    echo -n "<br>";
		else
		    echo -n "<br><br><br>*** bed file missing ***"
		fi
		
	    done
	echo -n "</td>";
	done
	echo "</tr>"
    done
    
    echo "</table>"
    
)

for token1 in $(echo "$NEG_CTRL_LIST"; echo "$POS_CTRL_LIST"; echo "$SAMPLE_LIST"); do
    f=$RUNDIR/report/ncov_tools_ivar/data/$token1.sorted.filtered.primerTrim.bam    
    if [ ! -f "$f" ]; then
	f=$RUNDIR/alignment/$token1/$token1.sorted.filtered.primerTrim.bam
	if [ ! -f "$f" ]; then
	    continue;
	fi
    fi
    if [ -f "$f" ]; then
	COMM=$(cat <<EOF
module load mugqic/kraken2/2.1.0;
module load mugqic/samtools/1.12;
module load mugqic/bedtools/2.29.2;
ro=$OUTDIR/reads_post_ivar
bam=\$ro/$token1.reads_post_ivar.qsort.bam;
fq=\$ro/$token1.reads_post_ivar.qsort.bam.fq;
samtools sort -n -o \$bam $f;
bedtools bamtofastq -i \$bam -fq \$fq;
db=\$MUGQIC_INSTALL_HOME/software/kraken2/kraken2-2.1.0/db
uncl=\$ro/$token1.reads_post_ivar.unclassified_sequences.fastq
cl=\$ro/$token1.reads_post_ivar.classified_sequences.fastq
o=\$ro/$token1.reads_post_ivar.kraken2_output
r=\$ro/$token1.reads_post_ivar.kraken2_report
kraken2  --quick  --threads $PROC --db \$db  --unclassified-out  \$uncl --classified-out \$cl --output \$o --report \$r \$fq;
EOF
    );
    if [ ! -f "$OUTDIR/reads_post_ivar/$token1.reads_post_ivar.kraken2_report" ]; then
	QUEUE=sw; PROC=1; DAYS=1;
 	PID=$(echo "$COMM" | qsub -d $(pwd) -V -l walltime=$DAYS:00:00:0 -q $QUEUE -l nodes=1:ppn=$PROC $_QOSOVERRIDE -j oe -N $token1.reads_post_ivar_kraken \
	    -o ${OUTDIR}/job_output/$token1.reads_post_ivar_kraken.o | awk -F'.' '{print $1}');
	ALLPIDS=$(printf "$ALLPIDS\n$PID\n");
    fi
fi
    
done
    
#### WAIT FOR JOBS #### 
echo -n "Wait for jobs to complete ... "
if [ "$ALLPIDS" == "" ]; then 
    echo "no jobs";
else
    ALLPIDS=$(echo "$ALLPIDS" | tail -n+2 | sort)
    # echo -n "ALLPIDS:"; echo "$ALLPIDS" | tr '\n' ' ';
    sleep 15;
    while(true); do
        while(true); do 
            a=$(qstat);
            if [ $? -eq 0 ]; then 
                break; 
            fi; 
            sleep 1; 
        done;
        ALLPIDSACTIVE=$(echo "$a" | tail -n+3 | awk '$5!="C"{print $0}' | awk -F'.' '{print $1}' | sort);
        # echo -n "ALLPIDSACTIVE: "; echo "$ALLPIDSACTIVE" | tr '\n' ' ';
	N=$(comm -12 <(echo "$ALLPIDS") <(echo "$ALLPIDSACTIVE") | wc -l);
        if [ "$N" == "0" ]; then
            break
        fi
        echo -n "($N)"
        sleep 60
    done
    echo " done"
fi

MAX_LINES_NEG_TH=1;
MAX_LINES_NEG=0;
GENERATE_NEGKRAKENWARN=false;
for token1 in $(echo "$NEG_CTRL_LIST"); do
    # f=$(ls $RUNDIR/metrics/dna/*/kraken_metrics/${token1}*.kraken2_report | head -n 1 )
    f=$(ls $OUTDIR/reads_post_ivar/${token1}.reads_post_ivar.kraken2_report | head -n 1 )
    if [ -f "$f" ]; then
	KrakenName=$(basename $f)
	if [[ "$KrakenName" == "NegCtrl_"* ]]; then
	    LINES_NEG=$(cat $f | awk '$3!=0&&$1!=0{print $0}' | wc -l)
	    if [ "$LINES_NEG" -gt "$MAX_LINES_NEG" ]; then
		MAX_LINES_NEG=$LINES_NEG;
	    fi
	    if [ "$LINES_NEG" -gt "$MAX_LINES_NEG_TH" ]; then
		GENERATE_NEGKRAKENWARN=true;
	    fi
	fi
    fi
done

echo "STEP: kraken"

NEG_KRAKEN_REPORT=$(
    echo "<table class=\"style1\">";
    echo "<tr>"
    for token1 in $(echo "$NEG_CTRL_LIST"); do
	f=$(ls $RUNDIR/metrics/dna/*/kraken_metrics/${token1}*.kraken2_report | head -n 1 )
	echo "<td>"
	echo "<table class=\"style4\"><tr><th>$(basename $f)</th></tr><tr><td>";
	if [ -f "$f" ]; then

COMM=$(cat << EOF
module purge
source /home/$USER/tools/miniconda3/etc/profile.d/conda.sh
conda activate krona-env
ktImportTaxonomy -t 5 -m 3 -o $OUTDIR/kraken_krona/$(basename $f).krona.html $f 
/home/$USER/tools/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /home/$USER/tools/phantomjs/rasterise.js \
  $OUTDIR/kraken_krona/$(basename $f).krona.html $OUTDIR/kraken_krona/$(basename $f).krona.png
EOF
);
if [ ! -f "$OUTDIR/kraken_krona/$(basename $f).krona.png" ]; then
  echo "$COMM" | sh > $OUTDIR/job_output/kraken_krona.$token1.o 2>&1;
fi
	    w=$(cat <<EOF
<button style="padding: 1px 2px;cursor: pointer;" type="button" onclick="popBase64('data:text/html;base64,$(cat $OUTDIR/kraken_krona/$(basename $f).krona.html | base64 | tr -d '\n' | tr -d ' ')')">Click to open interactive Kraken/Krona Report</button><br>
<img src="data:image/png;base64,$(base64 $OUTDIR/kraken_krona/$(basename $f).krona.png | tr -d ' ' | tr -d '\n')" >
 
EOF
); echo "$w";
	else
	    echo "<br><br>*** kraken file missing ***"
	fi
	echo "</td></tr></table>"
	echo "</td>"
	
    done
    echo "</tr>"
    echo "</table>"
)



NEG_KRAKEN_REPORT_POST_IVAR=$(
    echo "<table class=\"style1\">";
    echo "<tr>"
    for token1 in $(echo "$NEG_CTRL_LIST"); do
	f=$(ls $OUTDIR/reads_post_ivar/$token1.reads_post_ivar.kraken2_report 2>/dev/null)
	echo "<td>"
	echo "<table class=\"style4\"><tr><th>$(basename $f)</th></tr><tr><td>";
	if [ -f "$f" ]; then

COMM=$(cat << EOF
module purge
source /home/$USER/tools/miniconda3/etc/profile.d/conda.sh
conda activate krona-env
ktImportTaxonomy -t 5 -m 3 -o $OUTDIR/kraken_krona/$(basename $f).krona.html $f
/home/$USER/tools/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /home/$USER/tools/phantomjs/rasterise.js \
  $OUTDIR/kraken_krona/$(basename $f).krona.html $OUTDIR/kraken_krona/$(basename $f).krona.png
EOF
);
if [ ! -f "$OUTDIR/kraken_krona/$(basename $f).krona.png" ]; then
  echo "$COMM" | sh > $OUTDIR/job_output/kraken_krona.$token1.o 2>&1;
fi
	    w=$(cat <<EOF
<button style="padding: 1px 2px;cursor: pointer;" type="button" onclick="popBase64('data:text/html;base64,$(cat $OUTDIR/kraken_krona/$(basename $f).krona.html | base64 | tr -d '\n' | tr -d ' ')')">Click to open interactive Kraken/Krona Report</button><br>
<img src="data:image/png;base64,$(base64 $OUTDIR/kraken_krona/$(basename $f).krona.png | tr -d ' ' | tr -d '\n')" >
 
EOF
); echo "$w";

	else
	    echo "<br><br>*** kraken file missing ***"
	fi
	echo "</td></tr></table>"
	echo "</td>"
	
    done
    echo "</tr>"
    echo "</table>"
)



POS_KRAKEN_REPORT=$(
    echo "<table class=\"style1\">";
    echo "<tr>"
    for token1 in $(echo "$POS_CTRL_LIST"); do
	f=$(ls $RUNDIR/metrics/dna/*/kraken_metrics/${token1}*.kraken2_report | head -n 1)
	echo "<td>"
	echo "<table class=\"style4\"><tr><th>$(basename $f)</th></tr><tr><td>";
	if [ -f "$f" ]; then

COMM=$(cat << EOF
module purge
source /home/$USER/tools/miniconda3/etc/profile.d/conda.sh
conda activate krona-env
ktImportTaxonomy -t 5 -m 3 -o $OUTDIR/kraken_krona/$(basename $f).krona.html $f
/home/$USER/tools/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /home/$USER/tools/phantomjs/rasterise.js \
  $OUTDIR/kraken_krona/$(basename $f).krona.html $OUTDIR/kraken_krona/$(basename $f).krona.png
EOF
);
if [ ! -f "$OUTDIR/kraken_krona/$(basename $f).krona.png" ]; then
  echo "$COMM" | sh > $OUTDIR/job_output/kraken_krona.$token1.o 2>&1;
fi
	    w=$(cat <<EOF
<button style="padding: 1px 2px;cursor: pointer;" type="button" onclick="popBase64('data:text/html;base64,$(cat $OUTDIR/kraken_krona/$(basename $f).krona.html | base64 | tr -d '\n' | tr -d ' ')')">Click to open interactive Kraken/Krona Report</button><br>
<img src="data:image/png;base64,$(base64 $OUTDIR/kraken_krona/$(basename $f).krona.png | tr -d ' ' | tr -d '\n')" >
 
EOF
); echo "$w";

	else
	    echo "<br><br>*** kraken file missing ***"
	fi
	echo "</td></tr></table>"
	echo "</td>"
    done
    echo "</tr>"
    echo "</table>"
)

POS_KRAKEN_REPORT_POST_IVAR=$(
    echo "<table class=\"style1\">";
    echo "<tr>"
    for token1 in $(echo "$POS_CTRL_LIST"); do
	f=$(ls $OUTDIR/reads_post_ivar/$token1.reads_post_ivar.kraken2_report)
	echo "<td>"
	echo "<table class=\"style4\"><tr><th>$(basename $f)</th></tr><tr><td>";
	if [ -f "$f" ]; then

COMM=$(cat << EOF
module purge
source /home/$USER/tools/miniconda3/etc/profile.d/conda.sh
conda activate krona-env
ktImportTaxonomy -t 5 -m 3 -o $OUTDIR/kraken_krona/$(basename $f).krona.html $f
/home/$USER/tools/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /home/$USER/tools/phantomjs/rasterise.js \
  $OUTDIR/kraken_krona/$(basename $f).krona.html $OUTDIR/kraken_krona/$(basename $f).krona.png
EOF
);
if [ ! -f "$OUTDIR/kraken_krona/$(basename $f).krona.png" ]; then
  echo "$COMM" | sh > $OUTDIR/job_output/kraken_krona.$token1.o 2>&1;
fi
	    w=$(cat <<EOF
<button style="padding: 1px 2px;cursor: pointer;" type="button" onclick="popBase64('data:text/html;base64,$(cat $OUTDIR/kraken_krona/$(basename $f).krona.html | base64 | tr -d '\n' | tr -d ' ')')">Click to open interactive Kraken/Krona Report</button><br>
<img src="data:image/png;base64,$(base64 $OUTDIR/kraken_krona/$(basename $f).krona.png | tr -d ' ' | tr -d '\n')" >
 
EOF
); echo "$w";

	else
	    echo "<br><br>*** kraken file missing ***"
	fi
	echo "</td></tr></table>"
	echo "</td>"
    done
    echo "</tr>"
    echo "</table>"
)



SAMPLE_KRAKEN_REPORT=$(
    echo "<table class=\"style1\">";
    echo "<tr>"
    for token1 in $(echo "$SAMPLE_LIST"); do
	f=$(ls $RUNDIR/metrics/dna/*/kraken_metrics/${token1}*.kraken2_report | head -n 1)
	echo "<td>"
	echo "<table class=\"style4\"><tr><th>$(basename $f)</th></tr><tr><td>";
	if [ -f "$f" ]; then

COMM=$(cat << EOF
module purge
source /home/$USER/tools/miniconda3/etc/profile.d/conda.sh
conda activate krona-env
ktImportTaxonomy -t 5 -m 3 -o $OUTDIR/kraken_krona/$(basename $f).krona.html $f 
/home/$USER/tools/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /home/$USER/tools/phantomjs/rasterise.js \
  $OUTDIR/kraken_krona/$(basename $f).krona.html $OUTDIR/kraken_krona/$(basename $f).krona.png
EOF
);
if [ ! -f "$OUTDIR/kraken_krona/$(basename $f).krona.png" ]; then
  echo "$COMM" | sh > $OUTDIR/job_output/kraken_krona.$token1.o 2>&1;
fi
	    w=$(cat <<EOF
<button style="padding: 1px 2px;cursor: pointer;" type="button" onclick="popBase64('data:text/html;base64,$(cat $OUTDIR/kraken_krona/$(basename $f).krona.html | base64 | tr -d '\n' | tr -d ' ')')">Click to open interactive Kraken/Krona Report</button><br>
<img src="data:image/png;base64,$(base64 $OUTDIR/kraken_krona/$(basename $f).krona.png | tr -d ' ' | tr -d '\n')" >
 
EOF
); echo "$w";
	else
	    echo "<br><br>*** kraken file missing ***"
	fi
	echo "</td></tr></table>"
	echo "</td>"
    done
    echo "</tr>"
    echo "</table>"
)


SAMPLE_KRAKEN_REPORT_POST_IVAR=$(
    echo "<table class=\"style1\">";
    echo "<tr>"
    for token1 in $(echo "$SAMPLE_LIST"); do
	f=$(ls $OUTDIR/reads_post_ivar/$token1.reads_post_ivar.kraken2_report)
	echo "<td>"
	echo "<table class=\"style4\"><tr><th>$(basename $f)</th></tr><tr><td>";
	if [ -f "$f" ]; then

COMM=$(cat << EOF
module purge
source /home/$USER/tools/miniconda3/etc/profile.d/conda.sh
conda activate krona-env
ktImportTaxonomy -t 5 -m 3 -o $OUTDIR/kraken_krona/$(basename $f).krona.html $f 
/home/$USER/tools/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /home/$USER/tools/phantomjs/rasterise.js \
  $OUTDIR/kraken_krona/$(basename $f).krona.html $OUTDIR/kraken_krona/$(basename $f).krona.png
EOF
);
if [ ! -f "$OUTDIR/kraken_krona/$(basename $f).krona.png" ]; then
  echo "$COMM" | sh > $OUTDIR/job_output/kraken_krona.$token1.o 2>&1;
fi
	    w=$(cat <<EOF
<button style="padding: 1px 2px;cursor: pointer;" type="button" onclick="popBase64('data:text/html;base64,$(cat $OUTDIR/kraken_krona/$(basename $f).krona.html | base64 | tr -d '\n' | tr -d ' ')')">Click to open interactive Kraken/Krona Report</button><br>
<img src="data:image/png;base64,$(base64 $OUTDIR/kraken_krona/$(basename $f).krona.png | tr -d ' ' | tr -d '\n')" >
 
EOF
); echo "$w";

	else
	    echo "<br><br>*** kraken file missing ***"
	fi
	echo "</td></tr></table>"
	echo "</td>"
    done
    echo "</tr>"
    echo "</table>"
)



# name=amplicon_coverage_heatmap;
# file=$(find $RUNDIR/report/ncov_tools* -name "*$name*");
# if [ ! -f $file ]; then
#     echo $file does not exist
#     PDFCONTENTAMPL="";
# else
#     PDFCONTENTAMPL=$(cat <<EOF
# $(echo $name | tr '_' ' ' | sed 's/.pdf//g') pdf figure<br>
# <iframe width="1200" height="500" src="data:application/pdf;base64,$(cat $file | base64 | tr -d '\n' | tr -d ' ')" type="application/pdf"></iframe>
# <br>
# EOF
#     );
# fi

# name=tree_snps
# file=$(find $RUNDIR/report/ncov_tools* -name "*$name*");
# if [ ! -f $file ]; then
#     echo $file does not exist
#     PDFCONTENTTREESNP="";
# else
#     PDFCONTENTTREESNP=$(cat <<EOF
# $(echo $name | tr '_' ' ' | sed 's/.pdf//g') pdf figure<br>
# <iframe width="1200" height="500" src="data:application/pdf;base64,$(cat $file | base64 | tr -d '\n' | tr -d ' ')" type="application/pdf"></iframe>
# <br>
# EOF
#     );
# fi

# name=depth_by_position;

##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################

echo "STEP: make html"

i=0; HTML="";


############################################################################################################
let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. General information</h2>
 
EOF
);

############################################################################################################
let k=$k+1

HTML=$HTML$(cat <<EOF
<pre style="font-family: Arial; font-weight: bold; font-size: large;">
Project Name / ID:       $(grep -v "ProcessLUID" $_EVENTFILE | head -n 1 | awk -F'\t' '{print $3 " / " $2}')
Run name:                   $(basename $RUNDIR)
Pipeline information: <button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide</button>
</pre>
<div id="myDIV$k">
<p>
$(echo "$PIPELINE" | awk '{print $0"<br>"}')
</p>
</div>
 
EOF
);

############################################################################################################

let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. Status tables</h2>
 
EOF
);

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. QC warning table</h3>
<table class="style5">
<tr>$(if($GENERATE_NEGWARN); then echo "<th>Negative Control Report</th><th>Warning Issued $(if [ ! -f "$file_neg" ]; then echo " (report missing)"; fi)</th>"; 
                             else echo "<td>Negative Control Report</td><td>OK</td>"; fi;)</tr>
<tr>$(if($GENERATE_INCOMPLETEWARN); then echo "<th>Incomplete Genome</th><th>Warning Issued ($REALPCTINCOMPLETE%)</th>";
                                    else echo "<td>Incomplete Genome</td><td>OK ($REALPCTINCOMPLETE% incomplete)</td>"; fi;)</tr>
<tr>$(if($GENERATE_NEGKRAKENWARN); then echo "<th>Negative Control kraken (post ivar)</th><th>Warning Issued (all lines: $MAX_LINES_NEG<= $MAX_LINES_NEG_TH)</th>"; 
                                   else echo "<td>Negative Control kraken (post ivar)</td><td>OK (all lines: $MAX_LINES_NEG <= $MAX_LINES_NEG_TH)</td>"; fi;)</tr>
</table>
<br>
- Flag when coverage fraction>0.01, amplicon detected > 0<br>
- Flag when incomplete pct 25pct; incomplete pct = (#incomplete + #input - #output) / #input * 100; (threshold = 25pct)<br>
- Flag when kraken hits (post ivar)>$MAX_LINES_NEG_TH for Pct>0.0 and # frags associated to taxon is non zero.<br>
 
EOF
);


############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Job status</h3>
Only Incomplete, Idle and Hold shown once all jobs are done.<br>
$( tail -n +13 $OUTDIR/$(basename $RUNDIR)-jobstatus.html | head -n -1  | grep -v Successful | grep -v "Processing Status" | sed 's|<a target="_blank" href="data:text/html;base64,|<button style="padding: 0px 2px;cursor: pointer; font-size: 8px; " type="button" onclick="popBase64(\x27data:text/html;base64,|g' | sed 's|" >|\x27)" >|g'| sed 's|</a>|</button>|g')
<br>
 
EOF
);

############################################################################################################
let k=$k+1

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Run validation file
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide</button></h3>
<div id="myDIV$k">
<pre>
# If to be released run these commands:
dst="";
cp $outfile_run_valid \$dst/RunsValidationFiles/0_Reports/;

$(cat $outfile_run_valid)
</pre>
</div>
 
EOF
);



if [[ "$RUNDIR" == *ontcovidseq* ]]; then YIELDIMPCT=1200; else YIELDIMPCT=1400; fi;


############################################################################################################
let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. Primary QC metrics</h2>
 
EOF
);


############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Overall run yield</h3>
Plots use reads from all projects and samples in run.<br>
<table class="style2">
$(head -n 1  $YIELDDATA.tmp | sed 's/Sample name/Global/g' | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|\t|</th><th>|g')
$(tail -n+2 $YIELDDATA.tmp.total | LC_ALL=en_US.UTF-8 awk -F'\t' '{ a[$1]+=$2; b[$1]+=$3}END{ for(i in a) printf "%s\t%'"'"'i\t%'"'"'i\n", i, a[i], b[i] }' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g')
$(cat $YIELDDATA.tmp | grep -E "Undetermined|unclassified" | LC_ALL=en_US.UTF-8 awk -F'\t' '{ a[$1]+=$2; b[$1]+=$3}END{ for(i in a) printf "Undetermined (all lanes)\t%'"'"'i\t%'"'"'i\n", a[i], b[i] }' | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g')
</table><br>
<img src="data:image/png;base64,$(base64 $YIELDDATA.png | tr -d ' ' | tr -d '\n')" width="$YIELDIMPCT" >
 
EOF
);


if [[ "$RUNDIR" == *ontcovidseq* ]]; then


############################################################################################################
token="all_samples";
f1=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_read_histograms.png;
f2=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_quality_histograms.png;
f3=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_2d_histograms.png;

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Read length and quality</h3>
Plots use reads from all projects and samples.<br>
<table class="style1">
<tr>
<th>$token size distribution</th><th>$token read quality</th>
</tr>
<tr>
<td><img src="data:image/png;base64,$(base64 $f1 | tr -d ' ' | tr -d '\n')" width="450"></td>
<td><img src="data:image/png;base64,$(base64 $f2 | tr -d ' ' | tr -d '\n')" width="450"></td>
</tr>
</table>
 
EOF
);

else # ont/ill

############################################################################################################
token="all_samples";
f=$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;

V1=$(cat $f | grep -A20 -E  'Before filtering: read1: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read1__quality/${token}_R1/g" | grep -v "^</div>$")
V2=$(cat $f | grep -A20 -E  'Before filtering: read2: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read2__quality/${token}_R2/g" | grep -v "^</div>$")
V1_dat=$(echo "$V1" | grep 'mean' | cut -c 4- | sed 's/mean/R1 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,0,255,1.0)/g')
V2_dat=$(echo "$V2" | grep 'mean' | cut -c 4- | sed 's/mean/R2 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,255,0,1.0)/g')
V1_code=$(echo "$V1" | grep -v lines | grep -v '},];' | grep -v "^$")
V2_code=$(echo "$V2" | grep -v lines | grep -v '},];' | grep -v "^$")

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Insert size and quality</h3>
Plots use reads from all projects and samples.<br>
<table class="style1">
<th>$token insert size</th><th>$token R1/R2 quality</th>
<tr>
<td>$(cat $f | grep -A20 -E  'Insert size estimation' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_insert_size/${token}_insert_size /g" | sed 's/bar/lines/g' | grep -v "^</div>$")</td>
<td>
$(echo "$V1_code" | head -n 2 | sed 's/${token}_R1/${token}_R1_R2/g')
var data=[{$V1_dat},{$V2_dat},];
$(echo "$V1_code" | tail -n 3 | sed 's/${token}_R1/${token}_R1_R2/g' | sed "s|title:\x27\x27|title:\x27${token} R1/R2 quality\x27|g")
</td>
</table>
 
EOF
);

fi # ont/ill


############################################################################################################
let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. (-) Negative controls</h2>
 
EOF
);

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (-) Negative control Report</h3>
<table class="style2">
$(if [ -f "$file_neg" ]; then 
   head -n 1 $file_neg | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|\t|</th><th>|g';
   tail -n+2 $file_neg | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g';
fi)
</table>
 
EOF
);


if [[ "$RUNDIR" == *ontcovidseq* ]]; then

############################################################################################################
let k=$k+1

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (-) Read length and quality
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide plots</button></h3>
<div id="myDIV$k">
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$NEG_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token size distribution</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$NEG_CTRL_LIST"); do
f=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_read_histograms.png;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td><img src="data:image/png;base64,$(base64 $f | tr -d ' ' | tr -d '\n')" width="450"></td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);

HTML=$HTML$(cat <<EOF
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$NEG_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token read quality</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
 
EOF
);
for token in $(echo "$NEG_CTRL_LIST"); do
f1=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_quality_histograms.png;
f2=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_2d_histograms.png;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td><img src="data:image/png;base64,$(base64 $f1 | tr -d ' ' | tr -d '\n')" width="450"></td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
</div> <!-- from show hide -->
 
EOF
);

else # ont/ill
############################################################################################################
let k=$k+1

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (-) Insert size and quality
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide plots</button></h3>
<div id="myDIV$k">
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$NEG_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token insert size (cap 10M)</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);
for token in $(echo "$NEG_CTRL_LIST"); do
f=$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td>$(cat $f | grep -A20 -E  'Insert size estimation' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_insert_size/${token}_insert_size /g" | sed 's/bar/lines/g' | grep -v "^</div>$")</td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);


HTML=$HTML$(cat <<EOF 
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$NEG_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token R1/R2 quality</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$NEG_CTRL_LIST"); do
f=$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
if [ -f "$f" ]; then

V1=$(cat $f | grep -A20 -E  'Before filtering: read1: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read1__quality/${token}_R1/g" | grep -v "^</div>$")
V2=$(cat $f | grep -A20 -E  'Before filtering: read2: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read2__quality/${token}_R2/g" | grep -v "^</div>$")
V1_dat=$(echo "$V1" | grep 'mean' | cut -c 4- | sed 's/mean/R1 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,0,255,1.0)/g')
V2_dat=$(echo "$V2" | grep 'mean' | cut -c 4- | sed 's/mean/R2 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,255,0,1.0)/g')
V1_code=$(echo "$V1" | grep -v lines | grep -v '},];' | grep -v "^$")
V2_code=$(echo "$V2" | grep -v lines | grep -v '},];' | grep -v "^$")

    HTML=$HTML$(cat <<EOF
<td>
$(echo "$V1_code" | head -n 2 | sed 's/${token}_R1/${token}_R1_R2/g')
var data=[{$V1_dat},{$V2_dat},];
$(echo "$V1_code" | tail -n 3 | sed 's/${token}_R1/${token}_R1_R2/g' | sed "s|title:\x27\x27|title:\x27${token} R1/R2 quality\x27|g")
</td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
</div> <!-- from show hide -->
 
EOF
);



fi # ont/ill

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (-) Coverage plots</h3>
$(echo "$BED_PLOTS_NEG" | grep -v per_base_coverage)
<br>
$(echo "$BED_PLOTS_NEG" | grep -v amplicon_depth)
 
EOF
);
############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (-) Kraken reports</h3>
Pre host read removal:<br>
$NEG_KRAKEN_REPORT
<br>
Post ivar trimming:<br>
$NEG_KRAKEN_REPORT_POST_IVAR
 
EOF
);


############################################################################################################
let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. (+) Positive controls</h2>
 
EOF
);




if [[ "$RUNDIR" == *ontcovidseq* ]]; then

############################################################################################################
let k=$k+1

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (+) Read length and quality
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide plots</button></h3>
<div id="myDIV$k">
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$POS_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token size distribution</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$POS_CTRL_LIST"); do
f=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_read_histograms.png;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td><img src="data:image/png;base64,$(base64 $f | tr -d ' ' | tr -d '\n')" width="450"></td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);

HTML=$HTML$(cat <<EOF
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$POS_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token read quality</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$POS_CTRL_LIST"); do
f=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_quality_histograms.png;
f2=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_2d_histograms.png;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td><img src="data:image/png;base64,$(base64 $f | tr -d ' ' | tr -d '\n')" width="450"></td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
</div> <!-- from show hide -->
 
EOF
);


else # ont/ill
############################################################################################################
let k=$k+1

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (+) Insert size and quality
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide plots</button></h3>
<div id="myDIV$k">
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$POS_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token insert size (cap 10M)</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$POS_CTRL_LIST"); do
f=$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td>$(cat $f | grep -A20 -E  'Insert size estimation' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_insert_size/${token}_insert_size /g" | sed 's/bar/lines/g' | grep -v "^</div>$")</td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);


HTML=$HTML$(cat <<EOF 
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$POS_CTRL_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token R1/R2 quality</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);
for token in $(echo "$POS_CTRL_LIST"); do
f=$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
if [ -f "$f" ]; then

V1=$(cat $f | grep -A20 -E  'Before filtering: read1: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read1__quality/${token}_R1/g" | grep -v "^</div>$")
V2=$(cat $f | grep -A20 -E  'Before filtering: read2: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read2__quality/${token}_R2/g" | grep -v "^</div>$")
V1_dat=$(echo "$V1" | grep 'mean' | cut -c 4- | sed 's/mean/R1 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,0,255,1.0)/g')
V2_dat=$(echo "$V2" | grep 'mean' | cut -c 4- | sed 's/mean/R2 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,255,0,1.0)/g')
V1_code=$(echo "$V1" | grep -v lines | grep -v '},];' | grep -v "^$")
V2_code=$(echo "$V2" | grep -v lines | grep -v '},];' | grep -v "^$")


    HTML=$HTML$(cat <<EOF
<td>
$(echo "$V1_code" | head -n 2 | sed 's/${token}_R1/${token}_R1_R2/g')
var data=[{$V1_dat},{$V2_dat},];
$(echo "$V1_code" | tail -n 3 | sed 's/${token}_R1/${token}_R1_R2/g' | sed "s|title:\x27\x27|title:\x27${token} R1/R2 quality\x27|g")
</td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
</div> <!-- from show hide -->
 
EOF
);


fi # ont/ill

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (+) Coverage plots</h3>
$(echo "$BED_PLOTS_POS" | grep -v per_base_coverage)
<br>
$(echo "$BED_PLOTS_POS" | grep -v amplicon_depth)
 
EOF
);

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. (+) Kraken reports</h3>
Pre host read removal:<br>
$POS_KRAKEN_REPORT
<br>
Post ivar trimming:<br>
$POS_KRAKEN_REPORT_POST_IVAR
 
EOF
);

############################################################################################################
let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. Pipeline results</h2>
 
EOF
);

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. QC status counts</h3>
<table class="style4" style="margin-left: 0"><tr><td>
<table class="style2">
$(printf "Pipeline Samples\tCount\n"| awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|\t|</th><th>|g')
$(printf "Input\t$SAMPLECOUNT\nOutput\t$SAMPLEOUTPUT\n"| awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g')
</table>
</td><td>
<table class="style2">
$(printf "QC Status\tCount\n" | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|\t|</th><th>|g')
$(echo "$QC_FLAG_TABLE" | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g')
</table>
</td></tr></table>
 
EOF
);

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Lineage call counts</h3>
<table class="style2">
$(printf "qc_pass\tlineage\twatch_mutations\tCount\n" | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|\t|</th><th>|g')
$(echo "$QC_CALL_TABLE" | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g')
</table>
 
EOF
);

############################################################################################################
let k=$k+1
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Final summary QC table
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide table</button></h3>
<div id="myDIV$k">
$(basename $file_summary)<br>
<table class="style2">
$(if [ -f "$file_summary" ]; then
head -n 1 $file_summary | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|\t|</th><th>|g'
tail -n+2 $file_summary | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|\t|</td><td>|g'
fi
)
</table>
$(basename $file_lineages)<br>
<table class="style2">
$(if [ -f "$file_lineages" ]; then
head -n 1 $file_lineages | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|,|</th><th>|g'
tail -n+2 $file_lineages | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|,|</td><td>|g'
fi
)
</table>
</div>
 
EOF
);


HTML2=$HTML;

############################################################################################################
let k=$k+1
let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. Sample reports
<button onclick="hideshowsummarytable('myDIV$k')">Click to show/hide plots</button></h2>
<div id="myDIV$k">
 
EOF
);


############################################################################################################

if [[ "$RUNDIR" == *ontcovidseq* ]]; then

############################################################################################################

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Read length and quality</h3>
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$SAMPLE_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token size distribution</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$SAMPLE_LIST"); do
f=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_read_histograms.png;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td><img src="data:image/png;base64,$(base64 $f | tr -d ' ' | tr -d '\n')" width="450"></td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);

HTML=$HTML$(cat <<EOF
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$SAMPLE_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token read quality</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$SAMPLE_LIST"); do
f=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_quality_histograms.png;
f2=$OUTDIR/run_python_plot/$(basename $RUNDIR).${token}_2d_histograms.png;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td><img src="data:image/png;base64,$(base64 $f | tr -d ' ' | tr -d '\n')" width="450"></td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);


else # ont/ill
############################################################################################################

let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Insert size and quality</h3>
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$SAMPLE_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token insert size (cap 10M)</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);

for token in $(echo "$SAMPLE_LIST"); do
f=$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
if [ -f "$f" ]; then
    HTML=$HTML$(cat <<EOF
<td>$(cat $f | grep -A20 -E  'Insert size estimation' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_insert_size/${token}_insert_size /g" | sed 's/bar/lines/g' | grep -v "^</div>$")</td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);


HTML=$HTML$(cat <<EOF 
<table class="style1">
<tr>
 
EOF
);
for token in $(echo "$SAMPLE_LIST"); do
    HTML=$HTML$(cat <<EOF
<th>$token R1/R2 quality</th>
 
EOF
);
done
HTML=$HTML$(cat <<EOF
<tr>
</tr>
EOF
);
for token in $(echo "$SAMPLE_LIST"); do
f=$OUTDIR/fastp/$(basename $RUNDIR).$token.fastp.html;
if [ -f "$f" ]; then

V1=$(cat $f | grep -A20 -E  'Before filtering: read1: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read1__quality/${token}_R1/g" | grep -v "^</div>$")
V2=$(cat $f | grep -A20 -E  'Before filtering: read2: quality' | grep -A20 "<div class='figure'" | grep -B20 '/script' | sed "s/plot_Before_filtering__read2__quality/${token}_R2/g" | grep -v "^</div>$")
V1_dat=$(echo "$V1" | grep 'mean' | cut -c 4- | sed 's/mean/R1 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,0,255,1.0)/g')
V2_dat=$(echo "$V2" | grep 'mean' | cut -c 4- | sed 's/mean/R2 mean/g' | sed 's/rgba(20,20,20,1.0)/rgba(0,255,0,1.0)/g')
V1_code=$(echo "$V1" | grep -v lines | grep -v '},];' | grep -v "^$")
V2_code=$(echo "$V2" | grep -v lines | grep -v '},];' | grep -v "^$")


    HTML=$HTML$(cat <<EOF
<td>
$(echo "$V1_code" | head -n 2 | sed 's/${token}_R1/${token}_R1_R2/g')
var data=[{$V1_dat},{$V2_dat},];
$(echo "$V1_code" | tail -n 3 | sed 's/${token}_R1/${token}_R1_R2/g' | sed "s|title:\x27\x27|title:\x27${token} R1/R2 quality\x27|g")
</td>
 
EOF
);
else
    HTML=$HTML$(cat <<EOF
$(basename $f) missing<br> 
 
EOF
);
fi
done
HTML=$HTML$(cat <<EOF
</tr>
</table>
 
EOF
);


fi # ont/ill


############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Coverage plots</h3>
$(echo "$BED_PLOTS2" | grep -v per_base_coverage)
<br>
$(echo "$BED_PLOTS2" | grep -v amplicon_depth)
 
EOF
);


# 1. Percentage of fragments covered by the clade rooted at this taxon<br>
# 2. Number of fragments covered by the clade rooted at this taxon<br>
# 3. Number of fragments assigned directly to this taxon<br>
# 4. Rank code  Indicating (U)nclassified, (R)oot, (D)omain, (K)ingdom, (P)hylum, (C)lass, (O)rder, (F)amily, (G)enus, or (S)pecies. Taxa that are not at any of these 10 ranks have a rank code that is formed by using the rank code of the closest ancestor rank with a number indicating the distance from that rank. E.g., G2 is a rank code indicating a taxon is between genus and species and the grandparent taxon is at the genus rank.<br>
# 5. NCBI taxonomic ID number<br>
# 6. Indented scientific name<br>

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Kraken reports</h3>
Pre host read removal:<br>
$SAMPLE_KRAKEN_REPORT
<br>
Post ivar trimming:<br>
$SAMPLE_KRAKEN_REPORT_POST_IVAR<br>
</div>
  
EOF
);


############################################################################################################
let k=$k+1
let i=$i+1; j=0;
HTML=$HTML$(cat <<EOF
<hr><!-- ---------------------------- -->
<a id="$i.">
<h2>$i. Pipeline and file status
<button onclick="hideshowsummarytable('myDIV$k'); window.scrollBy({ top: 1500,  left: 0,  behavior: 'smooth'});">Click to show/hide</button></h2>
<div id="myDIV$k">
 
EOF
);

############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. File status table</h3>
&#10004;: File present.<br>
&#10006;: File missing.<br>
$FILE_STATUS_TABLE
 
EOF
);


############################################################################################################
# let j=$j+1
# HTML=$HTML$(cat <<EOF
# <a id="$i.$j.">
# <h3>$i.$j. Amplicon coverage</h3>
# $PDFCONTENTAMPL
# <br>
#  
# EOF
# );

############################################################################################################
# let j=$j+1
# HTML=$HTML$(cat <<EOF
# <a id="$i.$j.">
# <h3>$i.$j. Lineage tree</h3>
# $PDFCONTENTTREESNP 
# <br>
#  
# EOF
# );


############################################################################################################
let j=$j+1
HTML=$HTML$(cat <<EOF
<a id="$i.$j.">
<h3>$i.$j. Processing status table</h3>
$( tail -n +13 $OUTDIR/$(basename $RUNDIR)-jobstatus.html | head -n -1 | grep -v "Processing Status" | sed 's/, /, ~/g' | tr '~' '\n' | sed 's/href=".*"//'  | tr -d '\n')
</div>
 
EOF
);


HTML=$HTML$(cat <<EOF
</div>
</body>
</html>
 
EOF
);

html=$OUTDIR/$(basename $RUNDIR)_lab_qc_report.html  
html2=$OUTDIR/$(basename $RUNDIR)_lab_qc_report_onlycontrols.html  

CONTENT=$(cat <<EOF
<html><head><title>$TECH Covid Sequencing Lab QC report - INTERNAL DO NOT SHARE</title>
<style>

table.style1 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: initial; color: #000000; }
table.style1 th { text-align: center; border: 1px solid black; border-style: solid; background: #D0D0D0; min-width:620px;  }
table.style1 td { text-align: center; border: 1px solid black; border-style: solid; background: #FFFFFF; vertical-align: middle; min-width:620px; }

table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; font-size: 12px;}
table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; white-space: nowrap;max-width:auto; min-width:auto; }
table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; white-space: nowrap;max-width:auto; min-width:auto; }

/* table.style2 tr:nth-child(odd) { background: #dae5f4; } */
/* table.style2 tr:nth-child(even) { background: #FFFFFF; } */

table.style3 { border-collapse: collapse; border: 1px solid black; border-style: solid; }
table.style3 th { text-align: center; border: 1px solid black; border-style: solid; padding: 1px; background: #D0D0D0; font-size:100%;}
table.style3 td { text-align: center; vertical-align: top; border: 1px solid black; border-style: solid; padding: 1px; font-size:100%;}

table.style4 { border-collapse: collapse; border: 1px solid black; border-style: solid; border-spacing: 0;  padding: 0px; table-layout: fixed; color: #000000;  margin-left: auto; margin-right: auto; }
table.style4 th { border: 1px solid black; background: #D0D0D0; max-width:auto; min-width:auto; }
table.style4 td { border: 1px solid black; background: #FFFFFF; vertical-align: top; max-width:auto; min-width:auto; }

table.style5 { border-collapse: collapse; border: 1px solid black; border-style: solid; font-size: 18px;}
table.style5 th { text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #FF6962; color: #000000; }
table.style5 td { text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #77DD76; color: #000000; }

table.style6 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; font-size: 8px;}
table.style6 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; white-space: nowrap;max-width:auto; min-width:auto; }
table.style6 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; white-space: nowrap;max-width:auto; min-width:auto; }

pre { display: inline;    margin: 0; }
body { font-family: Arial; font-size: 14px; }
html { scroll-behavior: smooth; }
table { font-family: Arial; font-size: 10px;   border-collapse: collapse; }


// https://www.jimmybonney.com/articles/column_header_rotation_css/

.table-header-rotated th.row-header{
  width: auto;
}
.table-header-rotated td{
  min-width: 20px;
  border-top: 1px solid #000000;
  border-left: 1px solid #000000;
  border-right: 1px solid #000000;
  border-bottom: 1px solid #000000;
  vertical-align: middle;
  text-align: center;
}
.table-header-rotated th.rotate-45{
  height: 450px;
  min-width: 20px;
  max-width: 40px;
  position: relative;
  vertical-align: bottom;
  padding: 0;
  font-size: 12px;
  line-height: 0.8;

}
.table-header-rotated th.rotate-45 > div{
  position: relative;
  top: 0px;
  left: 225px; /* 80 * tan(45) / 2 = 40 where 80 is the height on the cell and 45 is the transform angle*/
  height: 100%;
  -ms-transform:skew(-45deg,0deg);
  -moz-transform:skew(-45deg,0deg);
  -webkit-transform:skew(-45deg,0deg);
  -o-transform:skew(-45deg,0deg);
  transform:skew(-45deg,0deg);
  overflow: hidden;
  border-left: 1px solid #000000;
  border-right: 1px solid #000000;
  border-top: 1px solid #000000;

}
.table-header-rotated th.rotate-45 span {
  -ms-transform:skew(45deg,0deg) rotate(315deg);
  -moz-transform:skew(45deg,0deg) rotate(315deg);
  -webkit-transform:skew(45deg,0deg) rotate(315deg);
  -o-transform:skew(45deg,0deg) rotate(315deg);
  transform:skew(45deg,0deg) rotate(315deg);
  position: absolute;
  bottom: 14px; /* 40 cos(45) = 28 with an additional 2px margin*/
  left: 0px; /*Because it looked good, but there is probably a mathematical link here as well*/
  display: inline-block;
  // width: 100%;
  width: 20px; /* 80 / cos(45) - 40 cos (45) = 85 where 80 is the height of the cell, 40 the width of the cell and 45 the transform angle*/
  text-align: left;
  white-space: nowrap; /*whether to display in one line or not*/
}


.sidenav {
  width: 215px;
  height: 100%;
  position: fixed;
  z-index: 1;
  top: 0px;
  left: 0px;
  background: #fff;
  overflow-x: hidden;
  padding: 8px 0px 0px 10px;
}

.sidenav a {
  padding: 1px 8px 1px 8px;
  text-decoration: none;
  font-size: 14px;
  color: #2196F3;
  display: block;
}

.sidenav a:hover {
  color: #064579;
}

.main {
  margin-left: 220px; /* Same width as the sidebar + left position in px */
  padding: 0px 10px;
}

@media screen and (max-height: 450px) {
  .sidenav {padding-top: 15px;}
  .sidenav a {font-size: 18px;}
}

</style>


<script src='https://cdn.plot.ly/plotly-latest.min.js'></script>
<script>
function hideshowsummarytable(mydiv) {
  var x = document.getElementById(mydiv);
  if (x.style.display === "none") {
    x.style.display = "block"
    //window.scrollBy({ top: 500,  left: 0,  behavior: 'smooth'});
  } else {
    x.style.display = "none";
  }
}
</script>
<script type="text/javascript"> function popBase64(base64URL) { var win = window.open(); win.document.write('<iframe src="' + base64URL  + '" frameborder="0" style="border:0; top:0px; left:0px; bottom:0px; right:0px; width:100%; height:100%;" allowfullscreen></iframe>'); win.document.close(); } </script>

</head>

<body onload="DIVCOUNTPLACEHOLDER">
<div class="main">
<h1>$TECH Covid Sequencing Lab QC Report</h1>
McGill Genome Centre <a href="https://www.mcgillgenomecentre.ca/">mcgillgenomecentre.ca</a><br>
Advanced Genomics Technologies Platform (AGT) <a href="https://www.agtg.ca/">agtg.ca</a><br>
Canadian Centre for Computational Genomics (C3G Montreal Node) <a href="https://computationalgenomics.ca/">computationalgenomics.ca</a><br>
<br>
This is an internal report for laboratory use. Please do not share outside the organization. Report Date: $(date)<br>
 
EOF
);
echo "$CONTENT" > $html
echo "$CONTENT" > $html2

############################################################################################################
# let k=$k+1
# CONTENT=$(cat <<EOF
# <hr><!-- ---------------------------- -->
# <h2>Table Of Contents
# <button onclick="hideshowsummarytable('myDIV$k');">Click to show/hide TOC</button></h2>
# <div id="myDIV$k">
#  
# EOF
# );
# echo "$CONTENT" >> $html
# echo "$CONTENT" >> $html2
# CONTENT=$(cat <<EOF
# $(echo "$HTML" | grep -E "<h2>|<h3>" | sed 's|<h2>||g' | sed 's|<h3>||g' | sed 's|</h2>||g' | sed 's|</h3>||g' | awk '{print "<a href=\"#"$1"\">"$0"</a><br>"}')
# </div>
#  
# EOF
# );
# echo "$CONTENT" >> $html
# CONTENT=$(cat <<EOF
# $(echo "$HTML2" | grep -E "<h2>|<h3>" | sed 's|<h2>||g' | sed 's|<h3>||g' | sed 's|</h2>||g' | sed 's|</h3>||g' | awk '{print "<a href=\"#"$1"\">"$0"</a><br>"}')
# </div>
#  
# EOF
# );
# echo "$CONTENT" >> $html2

CONTENT=$(cat <<EOF
<div class="sidenav">
<img src="data:image/png;base64,$(base64 MGCLOGO.png | tr -d ' ' | tr -d '\n')" height="75"><br><br>
$(echo "$HTML" | grep -E "<h2>|<h3>" | sed 's|<h2>||g' | sed 's|<h3>||g' | sed 's|</h2>||g' | sed 's|</h3>||g' | awk '{print "<a href=\"#"$1"\">"$0"</a>"}')
</div>
EOF
);
echo "$CONTENT" >> $html
CONTENT=$(cat <<EOF
<div class="sidenav">
<img src="data:image/png;base64,$(base64 MGCLOGO.png | tr -d ' ' | tr -d '\n')" height="75"><br><br>
$(echo "$HTML2" | grep -E "<h2>|<h3>" | sed 's|<h2>||g' | sed 's|<h3>||g' | sed 's|</h2>||g' | sed 's|</h3>||g' | awk '{print "<a href=\"#"$1"\">"$0"</a>"}')
</div>
EOF
);
echo "$CONTENT" >> $html2

echo  "$HTML" >> $html
echo  "$HTML2" >> $html2

DIVCOUNTS=$(grep '<div id="myDIV' $html | sed 's/<div id="myDIV//g' | tr -d '">' | sort | awk '{printf "hideshowsummarytable(\047myDIV" $0 "\047);" }')
DIVCOUNTS2=$(grep '<div id="myDIV' $html2 | sed 's/<div id="myDIV//g' | tr -d '">' | sort | awk '{printf "hideshowsummarytable(\047myDIV" $0 "\047);" }')

cat $html | sed "s/DIVCOUNTPLACEHOLDER/$DIVCOUNTS/g" > $html.tmp && mv $html.tmp $html
cat $html2 | grep -v 'Click to open interactive Kraken/Krona Report' | sed "s/DIVCOUNTPLACEHOLDER/$DIVCOUNTS2/g" > $html2.tmp && mv $html2.tmp $html2

if [[ "$RUNDIR" == *ontcovidseq* ]]; then    
    cp $html $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-ontcovidseq/$(basename $RUNDIR)-run.html
else
    cp $html $ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports-illumcovidseq/$(basename $RUNDIR)-run.html
fi

}


function run_python_plot {
    echo -n "run_python_plot ... ";
    
    _fastqpath=$1;
    _imagestub=$2;
    _tag=$3;
    _genomesize=$4;

    COMM=$(cat <<EOF
import itertools
import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

DOWNSAMPLE=False;

def readfastq(filename):
  file1 = open(filename, 'r') 
  while True:
    readheader = file1.readline()
    if not readheader:
        break
    
    sequence = file1.readline().rstrip('\n')
    plusseparator = file1.readline()
    quality = file1.readline().rstrip('\n')
    
    seqlen=len(sequence)
    avqual=sum([ord(s) for s in quality])/seqlen - 33;
    yield seqlen, sequence.count('N'), avqual;
  
  file1.close()

d = readfastq("$_fastqpath");

seq_dataframe = pd.DataFrame.from_dict(d);
seq_dataframe.columns = ['Length', 'NLength', 'Quality' ];

Totalreads=len(seq_dataframe);
Totalbases=sum(seq_dataframe['Length']);

Averagelength=Totalbases/Totalreads;
MedianLength=np.median(seq_dataframe['Length'])

AverageQuality=sum(seq_dataframe['Quality'])/Totalreads;
MedianQuality=np.median(seq_dataframe['Quality'])
original_stdout = sys.stdout
with open("${_imagestub}_read_stats.txt", 'w') as f:
    sys.stdout = f;
    
    print("Total Bases: ", end='')
    print(f"{Totalbases:,}")
    
    print("Total Reads: ", end='')
    print(f"{Totalreads:,}")
    
    print("Average Length: ", end='')
    print(f"{round(Averagelength,2):,}")
    
    print("Median Length: ", end='')
    print(f"{round(MedianLength,2):,}")
    
    print("Average Quality: ", end='')
    print(f"{round(AverageQuality,2):,}")
    
    print("Median Quality: ", end='')
    print(f"{round(MedianQuality,2):,}")

    print("Genome Coverage: ", end='')
    print(f"{round(Totalbases/($_genomesize*1000000),2):,}", end='')
    print("X")

    sys.stdout = original_stdout # R

max=50000;
step=500;
fig,ax1 = plt.subplots()
a = np.logspace(2.3, 3.3, num=100, endpoint=True, base=10.0, dtype=None, axis=0)
hist, bin_edges = np.histogram(seq_dataframe['Length'],bins=a);
ax1.step(bin_edges[0:len(bin_edges)-1],hist,color="#648FFF")
ax1.set_xscale('log')
ax1.set_xlabel('Read Length (bp)');
ax1.set_ylabel('Count histogram - blue');
ax1.xaxis.grid()
ax1.yaxis.grid()
ax2=ax1.twinx()
hist, bin_edges = np.histogram(seq_dataframe['Length'],bins=a,weights=seq_dataframe['Length']/1000000);
ax2.step(bin_edges[0:len(bin_edges)-1],hist,color="#DC267F");
ax2.set_xscale('log')
ax2.set_xlabel('Read Length (bp)');
ax2.set_ylabel('Yield histogram (Mbp) - magenta');
# ratio = 0.5
# x_left, x_right = ax1.get_xlim()
# y_low, y_high = ax1.get_ylim()
# ax1.set_aspect(abs((x_right-x_left)/(y_low-y_high))*ratio)
fig.suptitle("Length and Yield Histogram" + " ($_tag)", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("${_imagestub}_read_histograms.png",dpi=100)
plt.close(fig)

fig,ax1 = plt.subplots()
hist, bin_edges = np.histogram(seq_dataframe['Quality'],bins=np.arange(40));
ax1.step(bin_edges[0:len(bin_edges)-1],hist,color="#FE6100");
ax1.set_xlabel('Quality Value');
ax1.set_ylabel('Quality histogram - orange');
ax1.xaxis.grid()
ax1.yaxis.grid()
fig.suptitle("Quality histogram" + " ($_tag)", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("${_imagestub}_quality_histograms.png",dpi=100)
plt.close(fig)

fig,ax1 = plt.subplots()
plt.hist2d(np.log10(seq_dataframe['Length']),seq_dataframe['Quality'],[np.arange(2.3,3.3,0.02),np.arange(0,40,1)])
ax1.set_xlabel('Log10 of Read Length (log10 bp)');
ax1.set_ylabel('Quality Histogram');
plt.colorbar()
fig.suptitle("Quality Vs Length hist2d" + " ($_tag)", fontsize=12)
fig.tight_layout(rect=[0, 0.03, 1, 0.95])
fig.savefig("${_imagestub}_2d_histograms.png",dpi=100)
plt.close(fig)

EOF
);

#    if [ ! -f "${_imagestub}_read_histograms.png" ]; then
        module purge
        module load mugqic/python/3.6.5
        echo "$COMM" | python3
#    else
#        echo "${_imagestub}_read_histograms.png already created";
#    fi
    echo "done";

}
