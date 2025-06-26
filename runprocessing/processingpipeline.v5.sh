#!/bin/bash

# non production usage:
# Copy the runprocessing folder to your home directory in this location /home/$USER/runprocessing
# . processingpipeline.v5.sh testscratch; bootstrap /lb/robot/research/processing/events/system/2021/2021-08-08-T20.33.43-valid/92-1660554_24-261930_samples_redo1.txt
# . processingpipeline.v5.sh pseudoprod; bootstrap /lb/robot/research/processing/events/system/2021/2021-08-08-T20.33.43-valid/92-1660554_24-261930_samples_redo1.txt

MODE=$1

LANE_FRAC=1;

OVERMASKMAIN=""
OVERINDEX1MAIN="";
OVERINDEX2MAIN="";

COPYJOB_DEPEND=true

SCRATCHDIRROOT=/nb/Research;
ROBOTDIRROOT=/lb/robot/research;

if [ "$USER" == "bravolims" ]; then
    SCRATCHDIRROOT=/nb/Research;
    ROBOTDIRROOT=/lb/robot/research;
    QOSOVERRIDE="-l qos=research";
fi

if [ "$USER" == "bravolims-qc" ]; then
    SCRATCHDIRROOT=/lb/bravo/bravoqc/nb-Research;
    ROBOTDIRROOT=/lb/bravo/bravoqc/lb-robot-research;
    QOSOVERRIDE="";
fi

if [ "$USER" == "bravolims-dev" ]; then
    SCRATCHDIRROOT=/lb/bravo/bravodev/nb-Research;
    ROBOTDIRROOT=/lb/bravo/bravodev/lb-robot-research;
    QOSOVERRIDE="";
fi

RUN_DROP_LIST="$SCRATCHDIRROOT/Miseq,$SCRATCHDIRROOT/hiseqX,$SCRATCHDIRROOT/Novaseq,$SCRATCHDIRROOT/NovaseqX,$SCRATCHDIRROOT/iSeq/RUNS,$SCRATCHDIRROOT/iSeq/RUNS/atlasfs/researchISeq/RUNS"

JOB_MAIL=haig.djambazian@mcgill.ca; # -M $JOB_MAIL

PIPELINE_VERSION="MGC processing pipeline v5.0"
# Author Haig Djambazian

# BCLCOMM="module load mugqic/bcl2fastq2/2.20.0.422 mugqic/gcc/4.9.3 && bcl2fastq";
BCLCOMM="/usr/local/bin/bcl2fastq";

JAVA_VERSION="mugqic/java/openjdk-jdk1.8.0_72"; # mugqic/java/openjdk-jdk1.7.0_60
PICARD_VERSION="mugqic/picard/2.17.3"; # mugqic/picard/1.123
BIOCONDUCTOR_VERSION="mugqic/R_Bioconductor/3.5.3_3.8"; # mugqic/R_Bioconductor/3.1.2_3.0

JAVA_VERSION_OLD="mugqic/java/openjdk-jdk1.7.0_60"
PICARD_VERSION_OLD="mugqic/picard/1.123"
BIOCONDUCTOR_VERSION_OLD="mugqic/R_Bioconductor/3.1.2_3.0"

if [ "$MODE" == "prod" ]; then
  # for prod
  FINAL_ROOT=$ROBOTDIRROOT/processing;
  HISEQ_RUNS_PROJ=AUL202;
  SCRATCH_DIR=$SCRATCHDIRROOT/processing;
  # SCRATCH_DIR=/sb/Research/processing;
  FINAL_ROOT_CLARITY=$FINAL_ROOT;
  QUEUE=sw;
  # QUEUE=centos7;
  # QOS="-l qos=research"; # "-l qos=hiseq" uses special queue priority
  QOS="$QOSOVERRIDE";
  QUICKBCL=false;
  NORM_FASTQ=0; # 0 does not normalize
  CYCLE_OVERRIDE=0; # 0 does all cycles
  MONITOR_LOOP_DELAY=1800;
  # OVERMASKMAIN="Y*,I8n*,n*,Y*"; OVERINDEX1=8; OVERINDEX2=0; # for low complexity on I2
  NUM_MISMATCH=1;
  QUEUE_BCL2FASTQ=$QUEUE;
  # QUEUE_BCL2FASTQ=sw;
  # BCL2FASTQEXTRAOPTION=""
  # BCL2FASTQEXTRAOPTION="--ignore-missing-bcl"
  TEXTONLY=false;
  ALLRUNREPORTS=$ROBOTDIRROOT/processing/hiseq/runtracking/allrunreports
  FORCE_DEMULTIPLEX_PATH=$ROBOTDIRROOT/processing/events/system/forcedemux
  FORCE_MM_PATH=$ROBOTDIRROOT/processing/events/system/forcemm/
fi

if [ "$MODE" == "pseudoprod" ]; then
  # for prod
  FINAL_ROOT=/lb/robot/research/external/processing
  HISEQ_RUNS_PROJ=AUL202;
  SCRATCH_DIR=/lb/scratch/$USER/processing;
  # SCRATCH_DIR=/nb/Research/processing/testprocessing;
  # SCRATCH_DIR=/sb/Research/processing/testprocessing;
  FINAL_ROOT_CLARITY=/lb/robot/research/processing;
  QUEUE=sw;
  # QUEUE=centos7;
  QOS="-l qos=research"; # QOS="";
  QUICKBCL=false;
  NORM_FASTQ=0; # NORM_FASTQ=1000000;
  CYCLE_OVERRIDE=0; # CYCLE_OVERRIDE=5;
  MONITOR_LOOP_DELAY=1800;
  NUM_MISMATCH=1;
  QUEUE_BCL2FASTQ=$QUEUE;
  # QUEUE_BCL2FASTQ=sw;
  # BCL2FASTQEXTRAOPTION="--ignore-missing-bcl"
  # BCL2FASTQEXTRAOPTION=""
  # OVERMASKMAIN="Y151,I8,Y8,Y151"; OVERINDEX1=8; OVERINDEX2=0;
  COPYJOB_DEPEND=true;
  # OVERMASKMAIN="Y101,I8,I8,Y45n*";
  # OVERMASKMAIN="Y151,I8,n8,Y151"; OVERINDEX1=8; OVERINDEX2=0;
  # OVERMASKMAIN="Y101,I8,n8,Y101"; OVERINDEX1=8; OVERINDEX2=0;
  # OVERMASKMAIN="Y245,I8n*,I8,Y245"; OVERINDEX1=8; OVERINDEX2=8;
  # OVERMASKMAIN="Y101,I8n*,Y24,Y101"; OVERINDEX1=8; OVERINDEX2=0; # for multiome atac mixed with GEX
  TEXTONLY=false;
  ALLRUNREPORTS=/lb/robot/research/processing/hiseq/runtracking/allrunreportstest
  FORCE_DEMULTIPLEX_PATH=/lb/robot/research/external/processing/events/system/forcedemux
  FORCE_MM_PATH=/lb/robot/research/external/processing/events/system/forcemm/
fi

if [ "$MODE" == "testtext" ]; then
  # for test
  FINAL_ROOT=/lb/scratch/hdjambaz/processing/robot; # manually move from here to /lb/robot/research/test
  HISEQ_RUNS_PROJ=AUL609;
  SCRATCH_DIR=/lb/scratch/hdjambaz/processing;
  FINAL_ROOT_CLARITY=/lb/robot/research/processing; # mapped to /lb/robot/research/test on server, will be correct in files to move
  QUEUE=sw;
  QOS="-l qos=research"; # QOS="";
  QUICKBCL=false;
  NORM_FASTQ=0;
  CYCLE_OVERRIDE=0;
  MONITOR_LOOP_DELAY=900;
  NUM_MISMATCH=1;
  QUEUE_BCL2FASTQ=$QUEUE;
  # OVERMASKMAIN="Y151,I8,Y8,Y151"; OVERINDEX1=8; OVERINDEX2=0;
  BCL2FASTQEXTRAOPTION=""
  TEXTONLY=true;
  ALLRUNREPORTS=/lb/robot/research/processing/hiseq/runtracking/allrunreportstest
  FORCE_DEMULTIPLEX_PATH=/lb/scratch/hdjambaz/processing/events/system/forcedemux
  FORCE_MM_PATH=/lb/scratch/hdjambaz/processing/events/system/forcemm/
fi

if [ "$MODE" == "testscratch" ]; then
  # for test
  FINAL_ROOT=/lb/scratch/$USER/processing/testscratch/robot; # manually move from here to /lb/robot/research/test for lims
  HISEQ_RUNS_PROJ=AUL609;
  SCRATCH_DIR=/lb/scratch/$USER/processing/testscratch;
  FINAL_ROOT_CLARITY=/lb/robot/research/processing; # mapped to /lb/robot/research/test on server, will be correct in files to move
  QUEUE=sw;
  QOS="-l qos=research"; # QOS="";
  QUICKBCL=false;
  NORM_FASTQ=0;
  CYCLE_OVERRIDE=0;
  MONITOR_LOOP_DELAY=900;
  NUM_MISMATCH=1;
  QUEUE_BCL2FASTQ=$QUEUE;
  BCL2FASTQEXTRAOPTION=""
  # OVERMASKMAIN="Y245,I8n*,I8,Y245"; OVERINDEX1=8; OVERINDEX2=8;
  TEXTONLY=false;
  ALLRUNREPORTS=/lb/scratch/$USER/processing/testscratch/allrunreportstest
  FORCE_DEMULTIPLEX_PATH=/lb/scratch/$USER/processing/testscratch/events/system/forcedemux
  FORCE_MM_PATH=/lb/scratch/$USER/processing/testscratch/events/system/forcemm/
  # mkdir -p /lb/scratch/$USER/processing/testscratch/robot /lb/scratch/$USER/processing/testscratch /lb/scratch/$USER/processing/testscratch/allrunreportstest /lb/scratch/$USER/processing/testscratch/events/system/forcedemux /lb/scratch/$USER/processing/testscratch/events/system/forcemm/

fi

CODE_DIR=/home/$USER/runprocessing

REFERENCE_FILE=${CODE_DIR}/reference_list.txt
INDEX_DEF_FILE=${CODE_DIR}/adapter_settings_format.txt
ADAPTER_TYPES_FILE=${CODE_DIR}/adapter_types.txt
INSTRUMENT_LIST=${CODE_DIR}/instrument_list.csv
LIBRARY_PROTOCOL_LIST=${CODE_DIR}/library_protocol_list.csv
INDEX_SEARCH_FILE=${CODE_DIR}/barcode.mergedup.txt
BED_PATH=${CODE_DIR}/bed

function cleandepend {
    echo $1 | tr ':' '\n' | grep -v "^$" | awk -F'.' '{print $1}'| tr '\n' ':'  |sed 's/:$//';
}

function readsamplesheet {
    cat $SAMPLE_SHEET | grep -v '^$' | grep -v '^# ' | tail -n+2;
}

function getreferencefiles {

PATH1=""
PATH2=""
PATH3=""

IFS=$'\n'
for count in $(grep $REF $REFERENCE_FILE | grep -v "^#" | grep $STEP | awk -F',' '{print $3}'); do

case "$count" in
1) PATH1=$(grep "^$REF,$STEP,$count," $REFERENCE_FILE | awk -F',' '{print $4}');
   ;;
2) PATH2=$(grep "^$REF,$STEP,$count," $REFERENCE_FILE | awk -F',' '{print $4}');
   ;;
3) PATH3=$(grep "^$REF,$STEP,$count," $REFERENCE_FILE | awk -F',' '{print $4}');
   ;;
esac

done

}

function parse_run_info_parameters {

    RUN_PARAMETERS=$(ls $1/*unParameters.xml)

    FCID=$(grep '<Flowcell>' $1/RunInfo.xml | awk -F'<Flowcell>' '{print $2}' | awk -F'</Flowcell>' '{print $1}')
    EXPERIMENT_NAME=$(grep '<ExperimentName>' $RUN_PARAMETERS | awk -F'<ExperimentName>' '{print $2}' | awk -F'</ExperimentName>' '{print $1}')
    FC_POSITION=$(grep '<FCPosition>' $RUN_PARAMETERS | awk -F'<FCPosition>' '{print $2}' | awk -F'</FCPosition>' '{print $1}')
    FC_MODE=$(grep '<FlowCellMode>' $RUN_PARAMETERS | awk -F'<FlowCellMode>' '{print $2}' | awk -F'</FlowCellMode>' '{print $1}')
    SBS_CONSUMABLE_VERSION=$(grep '<SbsConsumableVersion>' $RUN_PARAMETERS | awk -F'<SbsConsumableVersion>' '{print $2}' | awk -F'</SbsConsumableVersion>' '{print $1}')
    INSTRUMENT_TYPE=$(grep '<InstrumentType>' $RUN_PARAMETERS | awk -F'<InstrumentType>' '{print $2}' | awk -F'</InstrumentType>' '{print $1}')

    if [ "$INSTRUMENT_TYPE" == "NovaSeqXPlus" ]; then
        SBS_CONSUMABLE_VERSION=3;
    fi

    # echo $EXPERIMENT_NAME | awk -F'HS' '{print $1}' | awk -F'NS' '{print $1}'
    INSTRUMENT=$(grep '<Instrument>' $1/RunInfo.xml | awk -F'<Instrument>' '{print $2}' | awk -F'</Instrument>' '{print $1}')
    RUN_NUMBER=$( printf "%04d" $(grep '<Run Id=' $1/RunInfo.xml | awk -F'Number="' '{print $2}' | awk -F'"' '{print $1}'))
    RUN_DATE=$(grep '<Date>' $1/RunInfo.xml | awk -F'<Date>' '{print $2}' | awk -F'</Date>' '{print $1}')

#    if [ "$(echo $EXPERIMENT_NAME | grep -c -E 'HS')" == "1" ]; then
#        OUT_RUN_ROOT=${RUN_DATE}_${INSTRUMENT}_${RUN_NUMBER}_${FC_POSITION}${FCID}_${EXPERIMENT_NAME}
#    else
        OUT_RUN_ROOT=$(basename $1)
#    fi

}

function stepaccumulator {

    if [ "$FINAL_MAIN" == "" ]; then
        FINAL_MAIN=$1;
    else
        FINAL_MAIN=$FINAL_MAIN":"$1;
    fi

}

function getmask {
    #       <Read Number="1" NumCycles="100" IsIndexedRead="N" />
    #       <Read NumCycles="250" Number="1" IsIndexedRead="N" />
    local runinfoxml="$1";
    local mask='';
    local old_IFS=$IFS
    Nreads=$(grep -c '<Read ' $runinfoxml);
    IFS=$'\n';
    for line in $(grep '<Read Num' $runinfoxml); do
        local Read_Number=$(echo "$line" | awk -F'Number="' '{print $2}' | awk -F'"' '{print $1}');
        local NumCycles=$(echo "$line" | awk -F'NumCycles="' '{print $2}' | awk -F'"' '{print $1}' );
        local IsIndexedRead=$(echo "$line" | awk -F'IsIndexedRead="' '{print $2}' | awk -F'"' '{print $1}');
        if [ "$IsIndexedRead" == "N" ]; then
            mask=$mask"Y"$NumCycles;
        fi
        if [ "$IsIndexedRead" == "Y" ]; then
            mask=$mask"I"$NumCycles;
        fi
        if [ "$Read_Number" != "$Nreads" ]; then
            mask=$mask",";
        fi
    done;
    IFS=$old_IFS
    echo $mask
}

function getcycles {
    local runinfoxml="$1";
    local old_IFS=$IFS
    READ1CYCLES=0;
    READ2CYCLES=0;
    INDEX1CYCLES=0;
    INDEX2CYCLES=0;
    IFS=$'\n';
    for line in $(grep '<Read Num' $runinfoxml); do
        local Read_Number=$(echo "$line" | awk -F'Number="' '{print $2}' | awk -F'"' '{print $1}');
        local NumCycles=$(echo "$line" | awk -F'NumCycles="' '{print $2}' | awk -F'"' '{print $1}' );
        local IsIndexedRead=$(echo "$line" | awk -F'IsIndexedRead="' '{print $2}' | awk -F'"' '{print $1}');
        case "$Read_Number" in
        1) if [ "$IsIndexedRead" == "N" ]; then READ1CYCLES=$NumCycles;
           else INDEX1CYCLES=$NumCycles;
           fi;
           ;;
        2) if [ "$IsIndexedRead" == "N" ]; then READ2CYCLES=$NumCycles;
           else INDEX1CYCLES=$NumCycles;
           fi;
           ;;
        3) if [ "$IsIndexedRead" == "N" ]; then READ2CYCLES=$NumCycles;
           else INDEX2CYCLES=$NumCycles;
           fi;
           ;;
        4) if [ "$IsIndexedRead" == "N" ]; then READ2CYCLES=$NumCycles;
           else INDEX2CYCLES=$NumCycles;
           fi;
           ;;
        esac
    done;
    IFS=$old_IFS


    if [ "$OVERINDEX1" == "" ]; then
        :
    else
        INDEX1CYCLES=$OVERINDEX1;
    fi

    if [ "$OVERINDEX2" == "" ]; then
        :
    else
        INDEX2CYCLES=$OVERINDEX2;
    fi

}


function getindex {

# . processingpipeline.v5.sh testing; INDEX1CYCLES=8; INDEX2CYCLES=8; INDEX_TYPE=DUAL_INDEX; SEQ_TYPE=novaseq; LIB_STRUCTURE='tenX_DNA_v2'; SAMPLE_NAME=sample1; LIB_ID=AAA; INDEX_NAME=SI-GA-A1; getindex
# . processingpipeline.v5.sh testing; INDEX1CYCLES=8; INDEX2CYCLES=8; INDEX_TYPE=DUAL_INDEX; SEQ_TYPE=novaseq; LIB_STRUCTURE='TruSeqHT'; SAMPLE_NAME=sample1; LIB_ID=AAA; INDEX_NAME=N720-S505; getindex
# . processingpipeline.v5.sh testing; INDEX1CYCLES=8; INDEX2CYCLES=8; INDEX_TYPE=DUAL_INDEX; SEQ_TYPE=novaseq; LIB_STRUCTURE='TruSeqHT'; SAMPLE_NAME=sample1; LIB_ID=AAA; INDEX_NAME=NS_Adaptor_4; getindex

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
elif [ "$LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ]; then
    INDEX1=""; INDEX1SEQ="";
    INDEX2=$INDEX_NAME;
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

if [[ "$SEQ_TYPE" == novaseq* ]] && [ "$SBS_CONSUMABLE_VERSION" == "3" ]; then
    # Make NovaSeq behave like HiSeqX when Consumable Version is 3
    INDEX1PRIMER=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index 1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEX1PRIMEROFFSET=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index 1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
    INDEX2PRIMER=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index 2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEX2PRIMEROFFSET=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index 2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')

    INDEXN1PRIMER=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index N1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEXN1PRIMEROFFSET=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index N1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
    INDEXN2PRIMER=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index N2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEXN2PRIMEROFFSET=$(grep -A8 hiseqx $INDEX_DEF_FILE | grep 'Index N2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
else
    INDEX1PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEX1PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
    INDEX2PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEX2PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index 2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')

    INDEXN1PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEXN1PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N1' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
    INDEXN2PRIMER=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $1}')
    INDEXN2PRIMEROFFSET=$(grep -A8 $SEQ_TYPE $INDEX_DEF_FILE | grep 'Index N2' | awk -F':' '{print $2}' | tr -d "35'\- " | awk -F',' '{print $2}')
fi

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

if [ "$LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ]; then
    ACTUALINDEX1SEQ="";
else
    ACTUALINDEX1SEQ=$(echo $MAINSEQ | awk -F"$INDEX1PRIMER_USE" '{print $2}' | sed "s/\[i7\]/$INDEX1SEQ/g" | \
	cut -c $(($INDEX1PRIMEROFFSET_USE+1))-$(($INDEX1PRIMEROFFSET_USE+$INDEX1CYCLES)));
fi

if [ "$INDEX_TYPE" == "DUAL_INDEX" ] || [ "$LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ]; then
    if [ "$SEQ_TYPE" == "hiseqx" ] || [ "$SEQ_TYPE" == "hiseq4000" ] || [ "$SEQ_TYPE" == "iSeq" ] || ( [[ "$SEQ_TYPE" == novaseq* ]] && [ "$SBS_CONSUMABLE_VERSION" == "3" ] ); then
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

function index {

# CountIlluminaBarcodes-1.0-jar-with-dependencies.jar
# module load mugqic/java/openjdk-jdk1.7.0_60
# /nb/programs/analyste/software/java-tools/CountIlluminaBarcodes-1.0-jar-with-dependencies.jar old
# /nb/programs/analyste/software/java-tools/CountIlluminaBarcodes-2.0-jar-with-dependencies.jar new

if [ "$SEQ_TYPE" == "hiseqx" ] || [ "$SEQ_TYPE" == "hiseq4000" ] || [ "$SEQ_TYPE" == "iSeq" ] || ( [[ "$SEQ_TYPE" == novaseq* ]] && [ "$SBS_CONSUMABLE_VERSION" == "3" ] ); then
    INDEX_SEARCH_FILE=${CODE_DIR}/barcodes_by_sequence.i5rev.txt
else
    INDEX_SEARCH_FILE=${CODE_DIR}/barcodes_by_sequence.i5fwd.txt
fi

rm -f ${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics.done

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; index_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=${STEP}/${JOB_NAME}_${TIMESTAMP}.o
JOB_OUTPUT=${JOB_OUTPUT_DIR}/${JOB_OUTPUT_RELATIVE_PATH}
COMMAND=$(cat <<EOF
mkdir -p ${OUTPUT_DIR}/index && \
mkdir -p ${OUTPUT_DIR}/index/BaseCalls && \
if [ ! -L "${OUTPUT_DIR}/index/BaseCalls/L00${LANE}" ]; then \
    ln -sf ${RUN_DIR}/Data/Intensities/BaseCalls/L00${LANE} ${OUTPUT_DIR}/index/BaseCalls/L00${LANE}; \
fi && \
if [ ! -L "${OUTPUT_DIR}/index/s.locs" ]; then \
    ln -sf ${RUN_DIR}/Data/Intensities/s.locs ${OUTPUT_DIR}/index/s.locs; \
fi && \
module load mugqic/java/openjdk-jdk1.8.0_72 && \
java -Djava.io.TMP_DIR=${TMP_DIR}\
 -Dsamjdk.buffer_size=10485760 -XX:ParallelGCThreads=6\
 -Xmx30G\
 -jar /nb/programs/analyste/software/java-tools/CountIlluminaBarcodes-2.0-jar-with-dependencies.jar\
 MAX_MISMATCHES=1\
 NUM_PROCESSORS=3\
 BARCODE_FILE=$INDEX_SEARCH_FILE\
 BASECALLS_DIR=${OUTPUT_DIR}/index/BaseCalls\
 LANE=${LANE}\
 READ_STRUCTURE=${READ1CYCLES}T${MAX_INDEX1_CYCLES}B\
 METRICS_FILE=${OUTPUT_DIR}/index/${RUN_ID}_${LANE}.metrics\
 TMP_DIR=${TMP_DIR}
EOF
);
#  READ_STRUCTURE=${READ1CYCLES}T$(($INDEX1CYCLES+$INDEX2CYCLES))B\


echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
index_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} && rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=12:00:0 -q $QUEUE -l nodes=1:ppn=16 $DEP | grep "[0-9]") # ppn=12
echo -e "$index_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $index_JOB_ID

}


function thumb_anim {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; thumb_anim_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=${STEP}/${JOB_NAME}_${TIMESTAMP}.o
JOB_OUTPUT=${JOB_OUTPUT_DIR}/${JOB_OUTPUT_RELATIVE_PATH}

COMMAND=$(cat <<EOF
. ${CODE_DIR}/thumbnail_animation_script.sh && \
make_animation $RUN_DIR $LANE $CYCLE_OVERRIDE $SEQ_TYPE $OUTPUT_DIR
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
thumb_anim_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=12:00:0 -q $QUEUE -l nodes=1:ppn=6 $DEP | grep "[0-9]")
echo -e "$thumb_anim_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $thumb_anim_JOB_ID

}


function fastq {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; fastq_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

if [ "$OVERMASK" == "" ]; then
    FINALMASK="$MASK"
else
    FINALMASK="$OVERMASK"
fi

if [[ "$USE_DEMULTIPLEX" == "0" || "$GENERATE_UMI9" == "1" ]]; then

if [ "$USE_DEMULTIPLEX" == "0" ]; then
  d1="Unaligned.${LANE}.indexed";
  d2="Unaligned.${LANE}"; # all the UMI info is in here, unless one library per lane
  f1="casavasheet.$LANE.indexed.csv";
  f2="casavasheet.$LANE.noindex.csv";
fi

if [ "$USE_DEMULTIPLEX" == "1" ]; then
  d1="Unaligned.${LANE}";
  d2="Unaligned.${LANE}.noindex"; # need to get the UMI from here
  f1="casavasheet.$LANE.indexed.csv";
  f2="casavasheet.$LANE.noindex.csv";
fi

COMMAND=$(cat <<EOF
$BCLCOMM \
 --runfolder-dir ${RUN_DIR}\
 --output-dir ${OUTPUT_DIR}/$d1\
 --tiles s_${LANE}\
 --sample-sheet ${OUTPUT_DIR}/$f1\
 --create-fastq-for-index-reads\
 -r 1 -p 5 -w 1\
 $BCL2FASTQEXTRAOPTION\
 --barcode-mismatches $NUM_MISMATCH --use-bases-mask $FINALMASK\
  && \
$BCLCOMM \
 --runfolder-dir ${RUN_DIR}\
 --output-dir ${OUTPUT_DIR}/$d2\
 --tiles s_${LANE}\
 --sample-sheet ${OUTPUT_DIR}/$f2\
 --create-fastq-for-index-reads\
 -r 1 -p 5 -w 1\
 $BCL2FASTQEXTRAOPTION
EOF
);
else
COMMAND=$(cat <<EOF
$BCLCOMM \
 --runfolder-dir ${RUN_DIR}\
 --output-dir ${OUTPUT_DIR}/Unaligned.${LANE}\
 --tiles s_${LANE}\
 --sample-sheet ${OUTPUT_DIR}/casavasheet.$LANE.indexed.csv\
 --create-fastq-for-index-reads\
 -r 1 -p 5 -w 1\
 $BCL2FASTQEXTRAOPTION\
 --barcode-mismatches $NUM_MISMATCH --use-bases-mask $FINALMASK
EOF
);
fi


IFS=$'\n'
LIBPERLANE=$(for line in $(readsamplesheet); do
  LIB_ID=$(echo $line | awk -F, '{print $3}');
  LANES=$(echo $line | awk -F, '{print $7}');
  LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
  if [ "$(echo $LANES | grep -c $LANE)" == "0" ]; then
     continue
  fi
  echo "${LANE}_${LIB_ID}";
done | sort -u | wc -l )


COUNT=0
for line in $(readsamplesheet); do

	PROJECT_ID=$(echo $line | awk -F, '{print $1}');
	PROJECT_NAME=$(echo $line | awk -F, '{print $2}');
	LIB_ID=$(echo $line | awk -F, '{print $3}');
	SAMPLE_NAME=$(echo $line | awk -F, '{print $4}');
	SAMPLE_ID=$(echo $line | awk -F, '{print $5}');
	INDEX_NAME=$(echo $line | awk -F, '{print $6}');
	LANES=$(echo $line | awk -F, '{print $7}');
	ARTIFACT_IDS=$(echo $line | awk -F, '{print $8}');
	LIB_TYPE=$(echo $line | awk -F, '{print $9}');
	LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
	PROCESSING_TYPE=$(echo $line | awk -F, '{print $11}');
	REF_and_BED=$(echo $line | awk -F, '{print $12}');
	EXPECTED_SAMPLE_TAG=$(echo $line | awk -F, '{print $13}');

        TARGET_CELLS=$(echo $line | awk -F, '{print $14}');
        LIBRARY_METADATA_ID=$(echo $line | awk -F, '{print $15}');
        SPECIES=$(echo $line | awk -F, '{print $16}');
        GENOME_SIZE_MB=$(echo $line | awk -F, '{print $17}');
        SEX=$(echo $line | awk -F, '{print $18}');
        POOL_FRACTIONS=$(echo $line | awk -F, '{print $19}');
        POOLING_TYPES=$(echo $line | awk -F, '{print $20}');
        POOLING_IDS=$(echo $line | awk -F, '{print $21}');
        CAPTURE_NAMES=$(echo $line | awk -F, '{print $22}');
        CAPTURE_REF_BEDS=$(echo $line | awk -F, '{print $23}');
        CAPTURE_METADATA_IDS=$(echo $line | awk -F, '{print $24}');
        ARTIFACTLUIDCLUSTERINGS=$(echo $line | awk -F, '{print $25}');
        LIBRARY_SIZE=$(echo $line | awk -F, '{print $26}');
        LIBRARY_KIT_NAME=$(echo $line | awk -F, '{print $27}');
        CAPTURE_KIT_TYPES=$(echo $line | awk -F, '{print $28}');
        CAPTURE_BAIT_VERSIONS=$(echo $line | awk -F, '{print $29}');
        CHIPSEQMARKS=$(echo $line | awk -F, '{print $30}');



  REF=$(echo "$REF_and_BED" | awk -F';' '{print $1}' | tr ':' '.')
  BED_FILES=$(echo "$REF_and_BED" | awk -F';' '{$1=""; print $0}' | tr ' ' ';' | sed "s|;|;${BED_PATH}/|g" | cut -c 2-)

  if [ "$(echo $LANES | grep -c $LANE)" == "0" ]; then
     continue
  fi

  let COUNT=$COUNT+1;

  if [[ "$INDEX_NAME" == SI-* ]] && [ "$USE_DEMULTIPLEX" == "1" ]; then

COMMAND="$COMMAND"$(cat <<EOF
  && \
mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID} && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_R1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_R1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_R1_001.fastq.gz > \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_I1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_I1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_I1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_I1_001.fastq.gz > \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
EOF
);

      if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_R2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_R2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_R2_001.fastq.gz > \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
); fi;
      if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_I2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_I2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_I2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_I2_001.fastq.gz > \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
EOF
); fi
      if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,I,Y,Y" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_R3_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_R3_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_R3_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_R3_001.fastq.gz > \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz
EOF
);
      fi

fi # PROCESSING_TYPE

if [[ "$LIBPERLANE" == "1" && "$FORCE_DEMULTIPLEX" == "0" ]]; then
    if [[ "$USE_DEMULTIPLEX" == "0" || "$GENERATE_UMI9" == "1" ]]; then
        if [[ "$INDEX_NAME" == SI-* ]]; then
            if [ "$USE_DEMULTIPLEX" == "0" ]; then

COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_R1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_R1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_R1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_R1_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz\
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_I1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_I1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_I1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_I1_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_I1_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
EOF
);
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_R2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_R2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_R2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_R2_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
);
                fi;
                if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_I2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_I2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_I2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_I2_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_I2_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
EOF
);
                fi
                if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,I,Y,Y" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_A/${SAMPLE_NAME}_${LIB_ID}_A_S${COUNT}_L00${LANE}_R3_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_B/${SAMPLE_NAME}_${LIB_ID}_B_S$(($COUNT+1))_L00${LANE}_R3_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_C/${SAMPLE_NAME}_${LIB_ID}_C_S$(($COUNT+2))_L00${LANE}_R3_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}_D/${SAMPLE_NAME}_${LIB_ID}_D_S$(($COUNT+3))_L00${LANE}_R3_001.fastq.gz \
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_R3_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz
EOF
);

                fi
            else # not USE_DEMULTIPLEX=0
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R1_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_I1_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
EOF
);
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R2_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
);
                fi;
                if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_I2_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
EOF
);
                fi
                if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,I,Y,Y" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R3_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz
EOF
);
                fi
                if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,Y,I,Y" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R3_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz
EOF
);
                fi
            fi # USE_DEMULTIPLEX=0
        else # not LIB_STRUCTURE=tenX
            if [ "$USE_DEMULTIPLEX" == "0" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
( cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz\
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_R1_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz || true ) \
  && \
( cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz\
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_I1_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz || true )
EOF
);
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
( cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz\
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_R2_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz || true )
EOF
);
                fi;
#                if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
( ( [ -f ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz ] \
 && [ -f ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_I2_001.fastq.gz ] \
 && cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz\
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_I2_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz) || true )
EOF
);
#                fi
COMMAND="$COMMAND"$(cat <<EOF
 && \
( ( [ -f ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz ] \
 && [ -f ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_R3_001.fastq.gz ] \
 && cat ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz\
    ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Undetermined_S0_L00${LANE}_R3_001.fastq.gz \
  > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz) || true )
EOF
);
            else # not USE_DEMULTIPLEX=0
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R1_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_I1_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
EOF
);
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R2_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
);
                fi;
                if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_I2_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
EOF
);
                fi
                if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,I,Y,Y" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R3_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz
EOF
);
                fi
                if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,Y,I,Y" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R3_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz
EOF
);
                fi
            fi # USE_DEMULTIPLEX=
        fi # LIB_STRUCTURE
    else # not (USE_DEMULTIPLEX=0 or GENERATE_UMI9=1) -> USE_DEMULTIPLEX=1 and GENERATE_UMI9=0
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R1_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_I1_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
EOF
);
        if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R2_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
);
        fi;
        if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_I2_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
EOF
);
        fi
        if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,I,Y,Y" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
cat ${OUTPUT_DIR}/Unaligned.${LANE}/Undetermined_S0_L00${LANE}_R3_001.fastq.gz \
  >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz
EOF
);
        fi
    fi # USE_DEMULTIPLEX=1 and GENERATE_UMI9=0
fi # LIBPERLANE=1 and FORCE_DEMULTIPLEX=0


if [ "$NORM_FASTQ" != "0" ]; then
    COMMAND="$COMMAND"$(cat <<EOF
  && \
mv ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz.orig \
&& ( zcat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz.orig 2> /dev/null || true) \
  | head -n $((4*$NORM_FASTQ)) | gzip > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
EOF
);
 COMMAND="$COMMAND"$(cat <<EOF
  && \
mv ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz.orig \
&& ( zcat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz.orig 2> /dev/null || true) \
  | head -n $((4*$NORM_FASTQ)) | gzip > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
EOF
);

if [ "$RUN_TYPE" == "PAIRED_END" ]; then
    COMMAND="$COMMAND"$(cat <<EOF
  && \
mv ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz.orig \
&& ( zcat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz.orig 2> /dev/null || true) \
  | head -n $((4*$NORM_FASTQ)) | gzip > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
); fi

if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
    COMMAND="$COMMAND"$(cat <<EOF
  && \
mv  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz.orig \
&& ( zcat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz.orig 2> /dev/null || true) \
  | head -n $((4*$NORM_FASTQ)) | gzip > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
EOF
); fi
fi # NORM_FASTQ

if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,I,Y,Y" ]; then
      # in case of i5 as UMI
      # rename R2(UMI)->I2, R3->R2. (I2 not generated)
      COMMAND="$COMMAND"$(cat <<EOF
 && ( ( [ -f ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz ] \
 && [ -f ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz ] \
 && mv -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz \
 && mv -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz \
 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
 ) || true )
EOF
);
fi

if [ "$(echo "$FINALMASK" | tr -d '0123456789n*')" == "Y,Y,I,Y" ]; then
      # in case of i7 as UMI
      # I1(index)->I2, R2(UMI)->I1, R3->R2. (I2 not generated)
      COMMAND="$COMMAND"$(cat <<EOF
 && ( ( [ -f ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz ] \
 && [ -f ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz ] \
 && mv -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz \
 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz \
 && mv -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz \
 && mv -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R3_001.fastq.gz \
 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
 ) || true )
EOF
);
fi

  if [[ "$INDEX_NAME" == SI-* ]]; then
      let COUNT=$COUNT+3;
  fi;

done

COMMAND="$COMMAND"$(cat <<EOF
  && \
(rm -vf ${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Project_*/Sample_*/*.fastq.gz || true)
EOF
);


echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
fastq_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE_BCL2FASTQ -l nodes=1:ppn=8 $DEP | grep "[0-9]")
echo -e "$fastq_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $fastq_JOB_ID

}

function fastqc_babraham {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$fastq_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; fastqc_babraham_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH
# --nogroup
# module load mugqic/fastqc/0.11.5
# module load mugqic/fastqc/0.11.6.devel
COMMAND=$(cat <<EOF
module load mugqic/fastqc/0.11.6.devel && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1 && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1.tmp && \
  fastqc --extract --nogroup ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz \
    --outdir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1 \
    --dir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001_fastqc.zip \
  && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1 && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1.tmp && \
  fastqc --extract --nogroup ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz \
    --outdir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1 \
    --dir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001_fastqc.zip
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2 && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2.tmp && \
  fastqc --extract --nogroup ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz \
    --outdir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2 \
    --dir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001_fastqc.zip
EOF
);
fi
if [ "$INDEX_TYPE" == "DUAL_INDEX" ] || [ "$I1_AS_READ2" == true ]|| [ "$I2_AS_READ2" == true ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2 && \
  mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2.tmp && \
  fastqc --extract --nogroup ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz \
    --outdir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2 \
    --dir ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2.tmp && \
  rm -r ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001_fastqc.zip
EOF
);
fi

echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
fastqc_babraham_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=48:00:0 -q $QUEUE -l nodes=1:ppn=10 $DEP | grep "[0-9]")
echo -e "$fastqc_babraham_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $fastqc_babraham_JOB_ID

}


function sample_tag {

READ=$1

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$fastq_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; fastqc_babraham_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH
# --nogroup
NREADS_SAMPLE_TAG=5000000;
COMMAND=$(cat <<EOF
mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.${READ} && \
IN=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.${READ}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_${READ}_001.fastq.gz.subSampled_${NREADS_SAMPLE_TAG}.blast.tsv.30bp_1MM_75id.tsv.summary.tsv && \
OUT=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.${READ}/${SAMPLE_NAME}_${LIB_ID}.sample_tag_stats.csv && \
sh ${CODE_DIR}/SampleTagTools/estimateSpikeInCount.sh \
    $NREADS_SAMPLE_TAG \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.${READ} \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_${READ}_001.fastq.gz \
    ${CODE_DIR}/SampleTagTools/96_kapa_spikein_tag_sequences.fasta \
    30 1 0.75 \
    ${CODE_DIR} && \
echo "Sample Name,Library ID,Top Sample Tag Name,Top Sample Tag Rate from Total (%),Top Sample Tag Rate from All Detected (%),Expected Sample Tag Name,Top Sample Tag Name Match" > \$OUT && \
SUM_DETECT=\$(tail -n+2 \$IN | awk '{sum+=\$2} END {print sum}') && \
if [ "\$SUM_DETECT" == "0" ]; then PERC_FROM_DETECT=0; else PERC_FROM_DETECT=\$(tail -n+2 \$IN | head -n 1 | awk -v SUM_DETECT=\$SUM_DETECT '{printf "%0.1f",\$2/SUM_DETECT*100}'); fi && \
TOP_DETECT=\$(tail -n+2 \$IN | awk '{print \$1}' | head -n 1) && \
TOP_RATE=\$(tail -n+2 \$IN | awk '{print \$3}' | head -n 1) && \
if [ "$(echo $EXPECTED_SAMPLE_TAG  | sed 's/[A-Za-z]*//g'  | sed 's/^_*//' | tr -d ' ' | sed 's/^0*//' | awk -F'_' '{print $1}')" == "\$(echo \$TOP_DETECT | sed 's/[A-Za-z]*//g'  | sed 's/^_*//' | tr -d ' ' | sed 's/^0*//' | awk -F'_' '{print \$1}')" ]; then MATCH=True; else MATCH=False; fi && \
if [ "$EXPECTED_SAMPLE_TAG" == "N/A" ]; then MATCH=Ignore; fi && \
echo "$SAMPLE_NAME,$LIB_ID,\$TOP_DETECT,\$TOP_RATE,\$PERC_FROM_DETECT,$EXPECTED_SAMPLE_TAG,\$MATCH" >> \$OUT && \
rm -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.${READ}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_${READ}_001.fastq.gz.subSampled_$NREADS_SAMPLE_TAG.fastq && \
rm -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.${READ}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_${READ}_001.fastq.gz.subSampled_$NREADS_SAMPLE_TAG.fasta && \
rm -v ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.${READ}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_${READ}_001.fastq.gz.subSampled_$NREADS_SAMPLE_TAG.qual
EOF
);

echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
sample_tag_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE_BCL2FASTQ -l nodes=1:ppn=10 $DEP | grep "[0-9]")
echo -e "$sample_tag_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $sample_tag_JOB_ID

}


function align_bwa_mem {
STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$fastq_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; align_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load mugqic/bwa/0.7.17 $JAVA_VERSION_OLD $PICARD_VERSION_OLD && \
mkdir -p ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE} && \
bwa mem  \
  -Y -K 100000000 -t 16 \
  -R '@RG\tID:${LIB_ID}_${RUN_ID}_${LANE}\tSM:${SAMPLE_NAME}\tLB:${LIB_ID}\tPU:run${RUN_ID}_${LANE}\tCN:McGill Genome Centre\tPL:Illumina' \
$PATH1 \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
);
fi
COMMAND="$COMMAND"$(cat <<EOF
  | \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=16 -Xmx64G -jar \$PICARD_HOME/SortSam.jar \
  VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true \
  TMP_DIR=${TMP_DIR} \
  INPUT=/dev/stdin \
  OUTPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
  SORT_ORDER=coordinate \
  MAX_RECORDS_IN_RAM=13500000
EOF
);

echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
align_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=192:00:0 -q $QUEUE -l nodes=1:ppn=16 $DEP | grep "[0-9]")
echo -e "$align_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $align_JOB_ID

}

function align_star {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

# --genomeDir /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.hg19/genome/star_index/UCSC2009-03-08.sjdbOverhang124

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$fastq_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; align_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load mugqic/star/2.5.1b $JAVA_VERSION_OLD $PICARD_VERSION_OLD && \
mkdir -p ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/staralign_${SAMPLE_NAME}_${LIB_ID} && \
STAR --runMode alignReads \
  --genomeDir $PATH1 \
  --readFilesIn \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  \
  ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
);
fi
COMMAND="$COMMAND"$(cat <<EOF
  \
  --runThreadN 14 \
  --readFilesCommand zcat \
  --outStd Log \
  --outSAMunmapped Within \
  --outSAMtype BAM SortedByCoordinate \
  --outFileNamePrefix ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/staralign_${SAMPLE_NAME}_${LIB_ID}/ \
  --outSAMattrRGline $(printf "ID:\"${LIB_ID}_${RUN_ID}_${LANE}\"\tPL:\"Illumina\"\tPU:\"${RUN_ID}_${LANE}\"\tLB:\"${LIB_ID}\"\tSM:\"${SAMPLE_NAME}\"\tCN:\"McGill University and Genome Quebec Innovation Centre\"") \
  --limitGenomeGenerateRAM 140000000000 \
  --limitBAMsortRAM 140000000000 \
  --limitIObufferSize 1000000000 && \
mv ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/staralign_${SAMPLE_NAME}_${LIB_ID}/Aligned.sortedByCoord.out.bam ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam && \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=1 -Dsamjdk.buffer_size=4194304 -Xmx4G -jar \$PICARD_HOME/BuildBamIndex.jar \
  VALIDATION_STRINGENCY=SILENT \
  INPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
  OUTPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bai
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
align_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=14 $DEP | grep "[0-9]")
echo -e "$align_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $align_JOB_ID

}

function picard_mark_dup {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$align_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; picard_mark_dup_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

COMMAND=$(cat <<EOF
module load $JAVA_VERSION_OLD $PICARD_VERSION_OLD && \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=1 -Dsamjdk.buffer_size=4194304 -Xmx20G -jar \$PICARD_HOME/MarkDuplicates.jar \
  REMOVE_DUPLICATES=false VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true \
  TMP_DIR=${TMP_DIR} \
  INPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
  OUTPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bam \
  METRICS_FILE=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics \
  MAX_RECORDS_IN_RAM=3500000
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
picard_mark_dup_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=144:00:0 -q $QUEUE -l nodes=1:ppn=4 $DEP | grep "[0-9]")
echo -e "$picard_mark_dup_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $picard_mark_dup_JOB_ID

}

function bvatools_covdepth {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$align_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; bvatools_covdepth_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load $JAVA_VERSION_OLD mugqic/bvatools/1.6 && \
java -XX:ParallelGCThreads=10 -Xmx50G -jar \$BVATOOLS_JAR \
  depthofcoverage --gc --maxDepth 1001 --summaryCoverageThresholds 10,25,50,75,100,500,1000 --minMappingQuality 15 --minBaseQuality 15 --ommitN --simpleChrName \
  --threads 10 \
  --ref $PATH1 \
  --bam ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
  > ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.targetCoverage.txt
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
bvatools_covdepth_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=12:00:0 -q $QUEUE -l nodes=1:ppn=10 $DEP | grep "[0-9]")
echo -e "$bvatools_covdepth_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $bvatools_covdepth_JOB_ID

}

function picard_collect_metrics {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$align_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; picard_collect_metrics_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load $JAVA_VERSION $PICARD_VERSION $BIOCONDUCTOR_VERSION && \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=1 -Dsamjdk.buffer_size=4194304 -Xmx10G -jar \$PICARD_HOME/picard.jar CollectMultipleMetrics\
  PROGRAM=CollectAlignmentSummaryMetrics PROGRAM=CollectInsertSizeMetrics VALIDATION_STRINGENCY=SILENT \
  TMP_DIR=${TMP_DIR} \
  REFERENCE_SEQUENCE=$PATH1 \
  INPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
  OUTPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics \
  MAX_RECORDS_IN_RAM=1000000
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
picard_collect_metrics_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=48:00:0 -q $QUEUE -l nodes=1:ppn=2 $DEP | grep "[0-9]")
echo -e "$picard_collect_metrics_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $picard_collect_metrics_JOB_ID

}

function interval_list {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
# JOB_DEPENDENCIES=$picard_collect_metrics_JOB_ID
JOB_DEPENDENCIES=$align_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; interval_list_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load mugqic/mugqic_tools/2.1.1 mugqic/perl/5.22.1 && \
bed2IntervalList.pl \
  --dict $PATH1 \
  --bed $BED_FILES \
  > ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/interval_list
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
interval_list_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=1 $DEP | grep "[0-9]")
echo -e "$interval_list_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $interval_list_JOB_ID

}

function picard_hs_metrics {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
# JOB_DEPENDENCIES=$(cleandepend $align_JOB_ID:$picard_collect_metrics_JOB_ID:$interval_list_JOB_ID)
JOB_DEPENDENCIES=$(cleandepend $align_JOB_ID:$interval_list_JOB_ID)
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; picard_hs_metrics_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load $JAVA_VERSION_OLD $PICARD_VERSION_OLD && \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=1 -Dsamjdk.buffer_size=4194304 -Xmx5G -jar \$PICARD_HOME/CalculateHsMetrics.jar \
  TMP_DIR=${TMP_DIR} \
  INPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
  OUTPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.onTarget.txt \
  BAIT_INTERVALS=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/interval_list \
  TARGET_INTERVALS=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/interval_list \
  REFERENCE_SEQUENCE=$PATH1
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
picard_hs_metrics_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=1 $DEP | grep "[0-9]")
echo -e "$picard_hs_metrics_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $picard_hs_metrics_JOB_ID

}

function rnaseq_qc {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

# -r /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.hg19/genome/Homo_sapiens.hg19.fa
# -t /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.hg19/annotations/Homo_sapiens.hg19.UCSC2009-03-08.transcript_id.gtf

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$picard_mark_dup_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; rnaseq_qc_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load $JAVA_VERSION_OLD mugqic/bwa/0.7.10 mugqic/rnaseqc/1.1.8 && \
mkdir -p ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/rnaseqc_${SAMPLE_NAME}_${LIB_ID} && \
touch ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/rnaseqc_${SAMPLE_NAME}_${LIB_ID}/empty.list && \
printf "Sample\tBamFile\tNote\n${SAMPLE_NAME}\t${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bam\tRNAseq\n" \
 > ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bam.sample_file && \
touch dummy_rRNA.fa && \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=3 -Xmx15G -jar \$RNASEQC_JAR \
  -n 1000 \
  -o ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/rnaseqc_${SAMPLE_NAME}_${LIB_ID} \
  -r $PATH1 \
  -s ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bam.sample_file \
  -t $PATH2 \
  -ttype 2
EOF
);
if [ "$RUN_TYPE" == "SINGLE_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  \
  -singleEnd
EOF
);
fi
COMMAND="$COMMAND"$(cat <<EOF
  \
  -rRNA ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/rnaseqc_${SAMPLE_NAME}_${LIB_ID}/empty.list && \
cp ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/rnaseqc_${SAMPLE_NAME}_${LIB_ID}/metrics.tsv \
   ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics.tsv
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
rnaseq_qc_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=3 $DEP | grep "[0-9]")
echo -e "$rnaseq_qc_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $rnaseq_qc_JOB_ID

}

function picard_rna_metrics {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

# REF_FLAT=/cvmfs/soft.mugqic/CentOS6/genomes/species//Homo_sapiens.GRCh37/annotations/Homo_sapiens.GRCh37.Ensembl75.ref_flat.tsv
# REFERENCE_SEQUENCE=/cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.hg19/genome/Homo_sapiens.hg19.fa

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$align_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; picard_rna_metrics_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load $JAVA_VERSION_OLD $PICARD_VERSION_OLD $BIOCONDUCTOR_VERSION_OLD && \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=4 -Xmx15G -jar \$PICARD_HOME/CollectRnaSeqMetrics.jar \
  VALIDATION_STRINGENCY=SILENT  \
  TMP_DIR=${TMP_DIR} \
  INPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
  OUTPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID} \
  REF_FLAT=$PATH1 \
  STRAND_SPECIFICITY=SECOND_READ_TRANSCRIPTION_STRAND \
  MINIMUM_LENGTH=200 \
  REFERENCE_SEQUENCE=$PATH2 \
  MAX_RECORDS_IN_RAM=5750000
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
picard_rna_metrics_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=10:00:0 -q $QUEUE -l nodes=1:ppn=3 $DEP | grep "[0-9]")
echo -e "$picard_rna_metrics_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $picard_rna_metrics_JOB_ID

}

function bwa_mem_r_rna {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

# /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.hg19/annotations/rrna_bwa_index/Homo_sapiens.hg19.UCSC2009-03-08.rrna.fa
# -g /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.hg19/annotations/Homo_sapiens.hg19.UCSC2009-03-08.transcript_id.gtf

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$align_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; bwa_mem_r_rna_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

COMMAND=$(cat <<EOF
module load $JAVA_VERSION_OLD mugqic/bvatools/1.6 mugqic/bwa/0.7.10 $PICARD_VERSION_OLD mugqic/mugqic_tools/2.1.1 mugqic/python/2.7.11 && \
java -XX:ParallelGCThreads=1 -Dsamjdk.buffer_size=4194304 -Xmx10G -jar \$BVATOOLS_JAR \
  bam2fq --mapped ONLY \
  --bam ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam | \
bwa mem  \
  -M -t 12 \
  -R $(printf "\'@RG\tID:${LIB_ID}_${RUN_ID}_${LANE}\tSM:${SAMPLE_NAME}\tLB:${LIB_ID}\tPU:run${RUN_ID}_${LANE}\tCN:McGill University and Genome Quebec Innovation Centre\tPL:Illumina\'") \
  $PATH1 \
  /dev/stdin | \
java -Djava.io.TMP_DIR=${TMP_DIR} -XX:ParallelGCThreads=1 -Xmx7G -jar \$PICARD_HOME/SortSam.jar \
  VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true \
  TMP_DIR=${TMP_DIR} \
  INPUT=/dev/stdin \
  OUTPUT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.rRNA.bam \
  SORT_ORDER=coordinate \
  MAX_RECORDS_IN_RAM=1750000 && \
python \$PYTHON_TOOLS/rrnaBAMcounter.py \
  -i ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.rRNA.bam \
  -g $PATH2 \
  -o ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.rRNA.tsv \
  -t transcript && \
rm -v ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.rRNA.bam \
      ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.rRNA.bai
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
bwa_mem_r_rna_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=12 $DEP | grep "[0-9]")
echo -e "$bwa_mem_r_rna_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $bwa_mem_r_rna_JOB_ID

}

function metrics_verify_bam_id {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

# -vcf /cvmfs/soft.mugqic/CentOS6/genomes/species//Homo_sapiens.GRCh37/annotations/Homo_sapiens.GRCh37.dbSNP142_1000Gp1_EUR_AF.vcf

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$align_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; metrics_verify_bam_id_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

getreferencefiles

# If no VCF file is specified, skip verifyBamID
if [ -z "$PATH1" ] ; then return; fi

COMMAND=$(cat <<EOF
module load mugqic/verifyBamID/devMaster_20151216 && \
verifyBamID  \
--vcf $PATH1 \
--bam ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam \
--out ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.verifyBamId \
--verbose --ignoreRG --noPhoneHome && \
cut -f2- ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.verifyBamId.selfSM > \
   ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.verifyBamId.tsv
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
metrics_verify_bam_id_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=1 $DEP | grep "[0-9]")
echo -e "$metrics_verify_bam_id_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $metrics_verify_bam_id_JOB_ID

}


function qc_graphs {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$fastq_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; qc_graphs_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH
COMMAND=$(cat <<EOF
module load $JAVA_VERSION_OLD mugqic/bvatools/1.6 && \
mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc && \
java -XX:ParallelGCThreads=12 -Djava.awt.headless=true -Xmx120G -jar \$BVATOOLS_JAR \
  readsqc  \
  --regionName ${SAMPLE_NAME}_${LIB_ID}_L00${LANE}
EOF
);
COMMAND="$COMMAND"$(cat <<EOF
  \
  --type FASTQ \
  --output ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc \
  --read1 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  \
  --read2 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
EOF
);
fi

# atcgnPercentageForEachCycle

COMMAND="$COMMAND"$(cat <<EOF
  && \
  nbReads=\$(cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc/mpsQC_${SAMPLE_NAME}_${LIB_ID}_L00${LANE}_stats.xml \
    | awk -F'nbReads="' '{print \$2}' | awk -F'"' '{print \$1}') && \
  nbBases=\$(cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc/mpsQC_${SAMPLE_NAME}_${LIB_ID}_L00${LANE}_stats.xml \
    | awk -F'nbBases="' '{print \$2}' | awk -F'"' '{print \$1}') && \
  avgQual=\$(cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc/mpsQC_${SAMPLE_NAME}_${LIB_ID}_L00${LANE}_stats.xml \
    | awk -F'avgQual="' '{print \$2}' | awk -F'"' '{print \$1}') && \
  duplicateRate=\$(cat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc/mpsQC_${SAMPLE_NAME}_${LIB_ID}_L00${LANE}_stats.xml \
    | awk -F'duplicateRate="' '{print \$2}' | awk -F'"' '{print \$1}') && \
  echo nbReads,nbBases,avgQual,duplicateRate > ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc/mpsQC_${SAMPLE_NAME}_${LIB_ID}_L00${LANE}_stats.csv && \
  echo \$nbReads,\$nbBases,\$avgQual,\$duplicateRate >> ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc/mpsQC_${SAMPLE_NAME}_${LIB_ID}_L00${LANE}_stats.csv
EOF
);


echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
qc_graphs_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=96:00:0 -q $QUEUE -l nodes=1:ppn=24 $DEP | grep "[0-9]")
echo -e "$qc_graphs_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $qc_graphs_JOB_ID

}

function blast {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$fastq_JOB_ID
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; blast_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH
COMMAND=$(cat <<EOF
module load mugqic/samtools/0.1.19 mugqic/blast/2.10.0+ && \
mkdir -p ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample && \
TotalReads=\$(zcat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz | paste - - - - | wc -l) && \
Nreads=\$(( 50000*TotalReads/400000000 )) && \
Nreads=\$((Nreads<5000?5000:Nreads)) && \
Nreads=\$((Nreads>TotalReads?TotalReads:Nreads))
EOF
);
COMMAND="$COMMAND"$(cat <<EOF
  && \
zcat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz  2> /dev/null | \
  paste - - - -  2> /dev/null | head -n \$Nreads \
  | awk -F'\t' '{print ">"substr(\$1,2) "\n" \$2}' > ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.fasta || true && \
  blastn -query ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.fasta -db nt \
  -out ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.blastres -perc_identity 80 -num_descriptions 1 -num_alignments 1 && \
grep ">" ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.blastres \
   | sed 's/PREDICTED: //g' | awk '{ print \$2 "_" \$3}' | sort | uniq -c | sort -n -r \
   > ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.RDP.blastHit_20MF_species.txt
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
zcat ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz  2> /dev/null | \
  paste - - - -  2> /dev/null | head -n \$Nreads \
  | awk -F'\t' '{print ">"substr(\$1,2) "\n" \$2}' > ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.fasta || true && \
  blastn -query ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.fasta -db nt \
  -out ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.blastres -perc_identity 80 -num_descriptions 1 -num_alignments 1 && \
grep ">" ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.blastres \
   | sed 's/PREDICTED: //g'  | awk ' { print \$2 "_" \$3} ' | sort | uniq -c | sort -n -r \
   > ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.RDP.blastHit_20MF_species.txt
EOF
);
fi
if [ "$PROCESSING_TYPE" == "default RNA" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
blastn -query ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.fasta -db silva_r119_Parc \
   -out ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.blastresRrna -perc_identity 80 -num_descriptions 1 -num_alignments 1 && \
echo 'silva_r119_Parc' > ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.rrna && \
grep ">" ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.blastresRrna | wc -l >> \
   ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.rrna && \
grep ">" ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.fasta | wc -l >> \
   ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.rrna
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
blastn -query ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.fasta -db silva_r119_Parc \
   -out ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.blastresRrna -perc_identity 80 -num_descriptions 1 -num_alignments 1 && \
echo 'silva_r119_Parc' > ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.rrna && \
grep ">" ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.blastresRrna | wc -l >> \
   ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.rrna && \
grep ">" ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.fasta | wc -l >> \
   ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.rrna
EOF
);
fi
fi
COMMAND="$COMMAND"$(cat <<EOF
 && \
rm -v ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_\${Nreads}.fasta
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
 && \
rm -v ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_\${Nreads}.fasta
EOF
);
fi

echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
blast_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=4 $DEP | grep "[0-9]")

echo -e "$blast_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $blast_JOB_ID

}

function md5 {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$(cleandepend $fastq_JOB_ID:$align_JOB_ID)
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; md5_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH
COMMAND=$(cat <<EOF
md5sum -b ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz > \
 ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz.md5
EOF
);
if [ "$RUN_TYPE" == "PAIRED_END" ]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
md5sum -b ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz > \
    ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz.md5
EOF
);
fi
if [ "$REF" != "" ] && [[ "$PROCESSING_TYPE" == default* ]]; then
COMMAND="$COMMAND"$(cat <<EOF
  && \
md5sum -b ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam > \
  ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam.md5 \
  && \
md5sum -b ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bai > \
  ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bai.md5
EOF
);
fi

echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
md5_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=1 $DEP | grep "[0-9]")

echo -e "$md5_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $md5_JOB_ID

}

function cleandupbam {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}
JOB_DEPENDENCIES=$(cleandepend $picard_mark_dup_JOB_ID:$rnaseq_qc_JOB_ID)
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; cleandupbam_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH
COMMAND=$(cat <<EOF
if [ -f "${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bam" ]; then
    rm -v ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bam \
          ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bai;
fi
EOF
);
echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
cleandupbam_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=24:00:0 -q $QUEUE -l nodes=1:ppn=1 $DEP | grep "[0-9]")

echo -e "$cleandupbam_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

stepaccumulator $cleandupbam_JOB_ID

}

function addimage {
  f=$1
  if [ -f "$f" ]; then
      if [ "${f##*.}" == "jpg" ]; then
          echo '<img src="data:image/jpeg;base64,'$(base64 $f)'"  alt="'$(basename $f)'">';
      fi
      if [ "${f##*.}" == "gif" ]; then
          echo '<img src="data:image/gif;base64,'$(base64 $f)'"  alt="'$(basename $f)'">';
      fi
      if [ "${f##*.}" == "png" ]; then
          echo '<img src="data:image/png;base64,'$(base64 $f)'"  alt="'$(basename $f)'">';
      fi
  fi
}

function addimagebase64QUALpngfromfastqc {
  f=$1
  if [ -f "$f" ]; then
      str=$(cat $f | sed 's/<img/~<img/g' | tr '~' '\n' | grep 'Per base quality graph' 2> /dev/null | head -n 1 | awk -F'base64,' '{print $2}' | awk -F '"' '{print $1}')
      echo '<img src="data:image/png;base64,'$str'" height="75">';
  fi
}

function addlinkedfile {
  f=$1
  if [ -f "$f" ]; then
      if [ "${f##*.}" == "html" ]; then
          echo "<button style=\"padding: 1px 2px;cursor: pointer;\" type=\"button\" onclick=\"popBase64('data:text/html;base64,"$(base64 $f)"')\">"$(basename $f)"</button>";
          # echo '<a href="data:text/html;base64,'$(base64 $f)'">'$(basename $f)'</a>';
      else
          if [ "${f##*.}" == "pdf" ]; then
              echo "<button style=\"padding: 1px 2px;cursor: pointer;\" type=\"button\" onclick=\"popBase64('data:application/pdf;base64,"$(base64 $f)"')\">"$(basename $f)"</button>";
              # echo '<a href="data:application/pdf;base64,'$(base64 $f)'">'$(basename $f)'</a>';
          else
              if [ "${f##*.}" == "txt" ]; then
                  echo "<button style=\"padding: 1px 2px;cursor: pointer;\" type=\"button\" onclick=\"popBase64('data:text/txt;base64,"$(base64 $f)"')\">"$(basename $f)"</button>";
                  # echo '<a href="data:text/txt;base64,'$(base64 $f)'">'$(basename $f)'</a>';
              else
                  echo "<button style=\"padding: 1px 2px;cursor: pointer;\" type=\"button\" onclick=\"popBase64('data:text/txt;base64,"$(base64 $f)"')\">"$(basename $f).txt"</button>";
                  # echo '<a href="data:text/txt;base64,'$(base64 $f)'">'$(basename $f)'.txt</a>';
              fi
          fi
      fi
  fi
}

function addhtmlfilelabel {
  f=$1
  label=$2
  if [ -f "$f" ]; then
      if [ "${f##*.}" == "html" ]; then
          echo '<a href="data:text/html;base64,'$(base64 $f)'">'$label'</a>';
      fi
  fi
}

function addbuttonfilelabel {
  f=$1
  label=$2
  if [ -f "$f" ]; then
      if [ "${f##*.}" == "html" ]; then
          echo "<button style=\"padding: 1px 2px;cursor: pointer;\" type=\"button\" onclick=\"popBase64('data:text/html;base64,"$(base64 $f)"')\">"$label"</button>";
      fi
  fi
}

function addgiffilelabel {
  f=$1
  label=$2
  if [ -f "$f" ]; then
      if [ "${f##*.}" == "gif" ]; then
           echo '<a href="data:image/gif;base64,'$(base64 $f)'">'$label'</a>';
      fi
  fi
}

function addblasttable {
  f=$1
  if [ -f "$f" ]; then
     BLASTREADCOUNT=$(ls $(echo $f | sed 's/.RDP.blastHit_20MF_species.txt/.subSampled_*.blastres/g') | awk -F'subSampled_' '{print $2}' | awk -F'.' '{print $1}' )
     BLASTREALREADCOUNT=$(cat $(ls $(echo $f | sed 's/.RDP.blastHit_20MF_species.txt/.subSampled_*.blastres/g')) | grep -c '^>')
     READ_TYPE=$(echo $f | awk -F'.RDP.blastHit_20MF' '{print $1}' | awk -F'_L00' '{print $2}' | awk -F'.' '{print $2}')
     echo "$READ_TYPE: $BLASTREADCOUNT reads blasted. $BLASTREALREADCOUNT hits.<br>"
     echo "<table border=\"1\"><tr><th align=\"center\">Read Hits</th><th align=\"center\">Species</th></tr>"
     cat $f | awk  '{print "<tr><td align=\"right\">"$1"</td><td>"$2"</td></tr>" }'
     echo "</table>"
  fi
}

function getblastpercent {
    f=$1
    TOP_HIT=""
    PERCENT_HIT=""
    if [ -f "$f" ]; then
    if [ "$(wc -l $f | awk '{print $1}')" -ge "1" ]; then
        BLASTREADCOUNT=$(ls $(echo $f | sed 's/.RDP.blastHit_20MF_species.txt/.subSampled_*.blastres/g') | awk -F'subSampled_' '{print $2}' | awk -F'.' '{print $1}' )
        BLASTREALREADCOUNT=$(cat $(ls $(echo $f | sed 's/.RDP.blastHit_20MF_species.txt/.subSampled_*.blastres/g')) | grep -c '^>')
        if [ "$(head -n 1 $f | grep -c -E 'homo sapiens|Homo sapiens|Human DNA')" == "1" ]; then
            TOP_HIT="Homo_Sapiens"
            HIT_COUNT=$(cat $f | grep -E 'homo sapiens|Homo sapiens|Human DNA' | awk  '{sum+=$1} END {print sum}')
        else
            TOP_HIT=$(head -n 1 $f | awk '{print $2}' | tr -d ',' | tr -d '.')
            HIT_COUNT=$(head -n 1 $f | awk '{print $1}')
        fi
        PERCENT_HIT=$(echo "$HIT_COUNT $BLASTREADCOUNT" | awk '{printf "%0.1f",$1/$2*100}');
    fi
    fi
}


function addindextable {
  f=$1
  if [ -f "$f" ]; then
     echo "<table border=\"1\">"
     head -n 1 $f | awk -F'\t' '{print "<tr><th align=\"center\">"$1"</th><th align=\"center\">"$2"</th><th align=\"center\">"$3"</th><th align=\"center\">"$4"</th></tr>" }'
     tail -n+2 $f | awk -F'\t' '{print "<tr><td align=\"left\">"$1"</td><td align=\"center\">"$2"</td><td align=\"right\">"$3"</td><td align=\"right\">"$4"</td></tr>" }'
     echo "</table>"
  fi
}

function clarityhelper {
    echo $1 | sed "s|$SCRATCH_DIR|$FINAL_ROOT_CLARITY/$SEQ_CATEGORY/$YEAR|g"
}


function clip200 {
    f=$1
    nlines=$(wc -l $f | awk '{print $1}')
    if [ "$nlines" -le "200" ]; then
        printf "# This log file was cut to 500 characters in length per line.\n";
        printf "# The original log file is here:\n";
        printf "# $f\n";
        cat $f | cut -c 1-500;
    else
        nskip=$(($nlines-200))
        printf "##############################################################################";
        printf "##############################################################################\n";
        printf "# This log file has $nlines lines skipped in the middle of the file. The first and last 100 lines are kept and cut to 500 characters in length per line.\n";
        printf "# The original log file is here:\n";
        printf "# $f\n";
        printf "##############################################################################";
        printf "##############################################################################\n";
        head -n 100 $f | cut -c 1-500;
        printf "##############################################################################";
        printf "##############################################################################\n";
        printf "# Skipped: $nlines lines from:\n";
        printf "# $f\n";
        printf "##############################################################################";
        printf "##############################################################################\n";
        tail -n 100 $f | cut -c 1-500;
    fi
}

function aggregate_reports_sub {

PROCESS_ID=$1
RUN_DIR=$2
OUTPUT_DIR=$3
SAMPLE_SHEET=$4
FINAL_DIR=$5
TIMESTAMP=$6
YEAR=$7

ALLPROJECTS=$(readsamplesheet | awk -F, '{print $1}' | sort -u | grep -v '^$' )
ALLLANES=$(readsamplesheet | awk -F, '{print $7}'  | tr '-' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

NUMBER_LEFT_COPY=-1;

IFS=$'\n'
for PROJECT_ID_FILTER in $(printf "MAIN\n$ALLPROJECTS"); do

MASK=$(getmask $RUN_DIR/RunInfo.xml)

OVERINDEX1="";OVERINDEX2="";
getcycles $RUN_DIR/RunInfo.xml
parse_run_info_parameters $RUN_DIR

RUN_ID=${INSTRUMENT}_${RUN_NUMBER}

SEQ_TYPE=$(grep "$INSTRUMENT" $INSTRUMENT_LIST | awk -F, '{print $3}')
SEQ_CATEGORY=$(echo $SEQ_TYPE | sed 's/4000//g' | sed 's/2500//g' | sed 's/x//g')

INDEX1CYCLESORIG=$INDEX1CYCLES;
INDEX2CYCLESORIG=$INDEX2CYCLES;

if [ "$READ2CYCLES" == "0" ]; then
    RUN_TYPE=SINGLE_END;
else
    RUN_TYPE=PAIRED_END;
fi

if [ "$INDEX2CYCLES" == "0" ] || [ "$INDEX1CYCLES" == "0" ]; then
    INDEX_TYPE=SINGLE_INDEX;
else
    INDEX_TYPE=DUAL_INDEX;
fi

MASTER_RUN_COUNT="";
if [ "$(echo $EXPERIMENT_NAME | grep -c 'HS')" == "1" ]; then
    MASTER_RUN_COUNT=$(echo $EXPERIMENT_NAME | awk -F'HS' '{print $1}')
fi

if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then

STEP_LIST="monitor copyjob index fastq fastqc_babraham blast align_bwa_mem align_star picard_mark_dup bvatools_covdepth picard_collect_metrics rnaseq_qc picard_rna_metrics bwa_mem_r_rna metrics_verify_bam_id cleandupbam interval_list picard_hs_metrics  md5" # thumb_anim, qc_graphs, sample_tag

FILE=$( echo "Step Name,Date,Job Name,Job ID,Exit Status,Job Epilog,Job State" ;

for THIS_STEP in $(echo $STEP_LIST | tr ' ' '\n'); do

for job in $(cat $OUTPUT_DIR/job_output/IlluminaRunProcessing_job_list_*[0-9] | grep "$THIS_STEP\." | tr '\t' ',' | awk -F',' '{print $2}' | sort -u  2>/dev/null ); do

      # last job
      line=$(cat $OUTPUT_DIR/job_output/IlluminaRunProcessing_job_list_*[0-9] | grep "$THIS_STEP\." | grep $job | tr '\t' ',' | sort -t ',' -k4 | tail -n 1);

      JOB_ID=$(echo $line | awk -F',' '{print $1}' | awk -F'.' '{print $1}')
      JOB_NAME=$(echo $line | awk -F ',' '{print $2}')
      JOB_DEP=$(echo $line | awk -F ',' '{print $3}')
      JOB_REL_DIR=$(echo $line | awk -F ',' '{print $4}')
      DATE=$(echo "$JOB_REL_DIR" | awk -F'_' '{print $NF}' | sed 's/\.o//g')
      echo -n $THIS_STEP; echo -n ","$DATE;  echo -n ","$(echo $JOB_NAME | cut -d"." -f2-);

      fj=$OUTPUT_DIR/job_output/$JOB_REL_DIR

      echo -n ","$JOB_ID

      STR=""
      for line2 in $(cat $OUTPUT_DIR/job_output/IlluminaRunProcessing_job_list_*[0-9] | grep "$THIS_STEP\." | grep $job | tr '\t' ',' | sort -t ',' -k4 | tail -n 2 ); do
          JOB_REL_DIR2=$(echo $line2 | awk -F ',' '{print $4}')
          fj2=$OUTPUT_DIR/job_output/$JOB_REL_DIR2
          V=""
          if [ -f "$fj2" ]; then
              V=$(grep MUGQICexitStatus $fj2)
          fi
          if [ "$V" == "" ]; then
              if [ "$STR" == "" ]; then STR="-|$fj2"; else STR="$STR -|$fj2"; fi;
          else
              if [ "$STR" == "" ]; then STR="$(echo $V | sed 's/MUGQICexitStatus://g')|$fj2"; else STR="$STR $(echo $V | sed 's/MUGQICexitStatus://g')|$fj2"; fi;
          fi
      done
      echo -n ",$STR"

      if [ -f "$fj" ]; then
        D="0"
        if [[ "$(grep -c Epilogue $fj)" -gt "0" ]]; then
            D="1";
        fi
        V=$(grep MUGQICexitStatus $fj)
        if [ "$V" == "" ]; then
            V="-";
        fi

        echo -n ","$D

        if [ "$D" == "0" ]; then # no Epilog
            echo -n ",Running"
        else # have Epilog
            if [ "$V" ==  "-" ]; then
                echo -n ",Incomplete";
            elif [ "$V" ==  "MUGQICexitStatus:0" ]; then
                echo -n ",Successful"
            else
                echo -n ",Incomplete";
            fi
        fi
      else
          echo -n ",0"
          echo -n ",Idle/Hold"
      fi
      echo ""

    done

done);

  RUNNING_JOBS=$(qstat | tail -n +3 |awk '{print $1}' | sed 's/.scheduler//g')

  # NUMBER_LEFT=$(echo "$FILE" | grep -v monitor | grep -c -E 'Running|Idle/Hold')
  NUMBER_LEFT=0
  IFS=$'\n';
  for line in $(echo "$RUNNING_JOBS"); do
    a=$(echo "$FILE" | grep -v monitor | awk -F',' '{print ","$4","}' | grep -c ",$line,")
    if [ "$a" -gt "0" ]; then
        let NUMBER_LEFT=$NUMBER_LEFT+1;
    fi
  done;

  if [ "$NUMBER_LEFT" == "0" ]; then
    touch $OUTPUT_DIR/job_output/monitor/stop;
  fi

fi


if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then

  HTML_REPORT=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.html
  # HTML_REPORT_LABLINK=${OUTPUT_DIR}/${OUT_RUN_ROOT}-html-${SEQ_TYPE}.$(echo $SEQ_TYPE | sed 's/4000//g' | sed 's/2500//g' | sed 's/x//g')-run
  # ln -snf $(basename $HTML_REPORT) $HTML_REPORT_LABLINK

  if [ ! -f "$OUTPUT_DIR/job_output/copyjob/start" ]; then

    CLARITY_FILES=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.db_upload_init.udfs.txt
    CLARITY_UDFS=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.db_upload.udfs.txt
    CLARITY_POOLDATA=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.db_upload_allpool.txt
    FTP_FILES=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.copylist.txt
    MAIN_CSV=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.csv
    ALIGN_BWAMEM_CSV=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.align_bwa_mem.csv

    rm -f $CLARITY_FILES.t0
    rm -f $CLARITY_UDFS.t0
    rm -f $CLARITY_POOLDATA.t0
    rm -f $FTP_FILES.t0
    rm -f $MAIN_CSV.t0
    rm -f $ALIGN_BWAMEM_CSV.t0

printf "Artifact ID\tData ID\tData Release\tPooling Type\t\
Project Name\tProject ID\tSample Name\tSample ID\tLibrary Type\tLibrary ID\tChIP-Seq Mark\tLibrary Kit Name\tLibrary Strandedness\t\
Original Run Cycles\tDemultiplexing Cycles\tMismatch Setting\t\
Pool ID\tPool Name\tCapture Type\tCapture Bait\t\
Pool on Fraction\tRead Set ID\tData Directory\tMD5\tFile Sizes\tRead Set Size\t\
Flowcell ID\tRun ID\tFlowcell Lane\tRun Count\tProcessing Folder Name\tFlowcell Type\t\
RunType\tIndex Type\tQualityOffset\t\
Clusters\tBases\tAvg. Qual\tDup. Rate (%%)\t\
Submitted Species\tR1 Top Blast Hit Name\tR1 Top Blast Hit Rate (%%)\tR2 Top Blast Hit Name\tR2 Top Blast Hit Rate (%%)\tSpecies Match R1\tSpecies Match R2\t\
Top Sample Tag Name\tTop Sample Tag Rate from Total (%%)\tTop Sample Tag Rate from All Detected (%%)\tExpected Sample Tag Name\tTop Sample Tag Name Match\t\
Clusters on Index in Lane (%%)\tClusters on Index in Lane from Target (%%)\tExpected Lane Fraction\tSample On Fraction\t\
Sex\tDetected Sex\tSubmitted Sex Match\t\
rRNA BLAST Database\tR1 rRNA BLAST Hits\tR1 rRNA BLAST Total\tR1 rRNA BLAST Ratio\tR2 rRNA BLAST Hits\tR2 rRNA BLAST Total\tR2 rRNA BLAST Ratio\t\
i7 Adapter\ti5 Adapter\t\
Reference\tBed\tPF Reads Aligned All\tPF Reads Aligned All (%%)\tPF Reads Aligned R1 (%%)\tPF Reads Aligned R2 (%%)\t\
Chimeras (%%)\tAdapter (%%)\tMapped Insert Size (median)\tMapped Insert Size (mean)\tMapped Insert Size (std. dev.)\tAligned Dup. Rate (%%)\t\
Mean Coverage\tBases Covered at 10x (%%)\tBases Covered at 25x (%%)\tBases Covered at 50x (%%)\tBases Covered at 75x (%%)\tBases Covered at 100x (%%)\t\
Aligned Bases On Target (%%)\tOn Bait Bases from On Target Bases (%%)\t\
Freemix Number of SNP\tFreemix Value\t\
chr1 Normalized Coverage\tchr2 Normalized Coverage\tchr3 Normalized Coverage\tchr4 Normalized Coverage\tchr5 Normalized Coverage\tchr6 Normalized Coverage\t\
chr7 Normalized Coverage\tchr8 Normalized Coverage\tchr9 Normalized Coverage\tchr10 Normalized Coverage\tchr11 Normalized Coverage\tchr12 Normalized Coverage\t\
chr13 Normalized Coverage\tchr14 Normalized Coverage\tchr15 Normalized Coverage\tchr16 Normalized Coverage\tchr17 Normalized Coverage\tchr18 Normalized Coverage\t\
chr19 Normalized Coverage\tchr20 Normalized Coverage\tchr21 Normalized Coverage\tchr22 Normalized Coverage\t\
chrX Normalized Coverage\tchrY Normalized Coverage\tchrM Normalized Coverage\t\
Intragenic Rate\tUnique Rate of Mapped\tIntergenic Rate\tTranscripts Detected\tIntronic Rate\tMapped Unique Rate of Total\t\
Duplication Rate of Mapped\tExpression Profiling Efficiency\tEnd 1 %% Sense\tEnd 2 %% Sense\tEstimated Library Size\trRNA rate\t\
Comments\tExternal Project Code\tBilling String\tInvoice Fraction\tProcessing version\n" > $CLARITY_POOLDATA.t0

    echo "Processing Folder Name,Run ID,Lane,Run Type,Project ID,Project Name,Sample Name,Sample ID,Library Type,Library ID,Library Index,Data ID,Clusters,Bases,Avg. Qual,Dup. Rate (%),R1 Top Blast Hit Name,R1 Top Blast Hit Rate (%),R2 Top Blast Hit Name,R2 Top Blast Hit Rate (%),Top Sample Tag Name,Top Sample Tag Rate from Total (%),Top Sample Tag Rate from All Detected (%),Expected Sample Tag Name,Top Sample Tag Name Match,Clusters on Index in Lane (%),Clusters on Index in Lane from Target (%),i7 Adapter Sequence,i5 Adapter Sequence" > $MAIN_CSV.t0
    # R1 PhiX Rate from Total (%),R2 PhiX Rate from Total (%)
    echo "Processing Folder Name,Run ID,Lane,Run Type,Project ID,Project Name,Sample Name,Sample ID,Library Type,Library ID,Library Index,Data ID,Clusters,Bases,Avg. Qual,Dup. Rate (%),R1 Top Blast Hit Name,R1 Top Blast Hit Rate (%),R2 Top Blast Hit Name,R2 Top Blast Hit Rate (%),Top Sample Tag Name,Top Sample Tag Rate from Total (%),Top Sample Tag Rate from All Detected (%),Expected Sample Tag Name,Top Sample Tag Name Match,Clusters on Index in Lane (%),Clusters on Index in Lane from Target (%),i7 Adapter Sequence,i5 Adapter Sequence,Reference,Bed,PF Reads Aligned All,PF Reads Aligned All (%),PF Reads Aligned R1 (%),PF Reads Aligned R2 (%),Chimeras (%),Adapter (%),Mapped Insert Size (median),Mapped Insert Size (mean),Mapped Insert Size (std. dev.),Aligned Dup. Rate (%),Mean Coverage,Bases Covered At 10x (%),Bases Covered At 25x (%),Bases Covered At 50x (%),Bases Covered At 75x (%),Bases Covered At 100x (%),Aligned Bases On Target (%),On Bait Bases from On Target Bases (%),Freemix Number of SNP,Freemix Value,chr1 Normalized Coverage,chr2 Normalized Coverage,chr3 Normalized Coverage,chr4 Normalized Coverage,chr5 Normalized Coverage,chr6 Normalized Coverage,chr7 Normalized Coverage,chr8 Normalized Coverage,chr9 Normalized Coverage,chr10 Normalized Coverage,chr11 Normalized Coverage,chr12 Normalized Coverage,chr13 Normalized Coverage,chr14 Normalized Coverage,chr15 Normalized Coverage,chr16 Normalized Coverage,chr17 Normalized Coverage,chr18 Normalized Coverage,chr19 Normalized Coverage,chr20 Normalized Coverage,chr21 Normalized Coverage,chr22 Normalized Coverage,chrX Normalized Coverage,chrY Normalized Coverage,chrM Normalized Coverage" > $ALIGN_BWAMEM_CSV.t0

    printf "Pub\tLUID Type\tLUID\tUDF Name\tPath/Value\n" > $CLARITY_FILES.t0
    printf "Pub\tLUID Type\tLUID\tUDF Name\tPath/Value\n" > $CLARITY_UDFS.t0

    # printf "1\tPROJECT\t$HISEQ_RUNS_PROJ\t-\t$(clarityhelper $HTML_REPORT_LABLINK)\n" >> $CLARITY_FILES.t0 # attach to master project

    # REMOVE REMOVE REMOVE REMOVE REMOVE REMOVE
    # printf "1\tPROJECT\t$HISEQ_RUNS_PROJ\t-\t$(clarityhelper $HTML_REPORT)\n" >> $CLARITY_UDFS.t0 # attach to master project
    # REMOVE REMOVE REMOVE REMOVE REMOVE REMOVE

    # IFS=$'\n'
    # for LANE in $(echo $ALLLANES | tr ' ' '\n'); do
    #     thumbnails
    #     THUMBNAILS=${OUTPUT_DIR}/thumb_anim/$SEQ_TYPE-movie-${OUT_RUN_ROOT}-L00${LANE}.gif
    #     THUMBNAILS_LABLINK=${OUTPUT_DIR}/thumb_anim/${OUT_RUN_ROOT}-L00${LANE}-gif.$SEQ_TYPE-movie
    #     ln -snf $(basename $THUMBNAILS) $THUMBNAILS_LABLINK
    #     printf "1\tPROJECT\t$HISEQ_RUNS_PROJ\t-\t$(clarityhelper $THUMBNAILS_LABLINK)\n" >> $CLARITY_FILES.t0 # attach to master project
    # done

    printf "0\tUDF_PFURI\t$PROCESS_ID\tReport File\t$(clarityhelper $HTML_REPORT)\n" >> $CLARITY_FILES.t0 # attach to process (only one, so only once)

  fi

else

  HTML_REPORT=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$PROJECT_ID_FILTER-$SEQ_TYPE-run.html

  # HTML_REPORT_LABLINK=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$PROJECT_ID_FILTER-html.$SEQ_TYPE-run
  # ln -snf $(basename $HTML_REPORT) $HTML_REPORT_LABLINK

  if [ ! -f "$OUTPUT_DIR/job_output/copyjob/start" ]; then

    #if [ "$(echo "$ALLPROJECTS" | wc -l)" == "1" ]; then
    #    printf "1\tPROCESS\t$PROCESS_ID\t-\t$(clarityhelper $HTML_REPORT)\n" >> $CLARITY_UDFS.t0 # attach to process (only one, so only once)
    #else
    #    printf "1\tPROJECT\t$PROJECT_ID_FILTER\t-\t$(clarityhelper $HTML_REPORT)\n" >> $CLARITY_UDFS.t0 # attach to each project
    #fi

    printf "$RUN_ID,$PROJECT_ID_FILTER,,$(clarityhelper $HTML_REPORT)\n" >> $FTP_FILES.t0

  fi

fi

rm -f $HTML_REPORT.t0

echo "<"'!'"doctype html><html><head><title>${OUT_RUN_ROOT}</title>" >> $HTML_REPORT.t0;
echo "<style>" >> $HTML_REPORT.t0;
echo "table.style1 { border-collapse: collapse; border: 1px solid black; border-style: solid; }" >> $HTML_REPORT.t0;
echo "table.style1 th { text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }" >> $HTML_REPORT.t0;
echo "table.style1 td { text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }" >> $HTML_REPORT.t0;
echo "table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }" >> $HTML_REPORT.t0;
echo "table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }" >> $HTML_REPORT.t0;
echo "table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }" >> $HTML_REPORT.t0;
# echo "table.style2 tr:nth-child(odd) { background: #dae5f4; }" >> $HTML_REPORT.t0;
# echo "table.style2 tr:nth-child(even) { background: #FFFFFF; }" >> $HTML_REPORT.t0;
echo "table.style3 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }" >> $HTML_REPORT.t0;
echo "table.style3 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; }" >> $HTML_REPORT.t0;
echo "table.style3 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }" >> $HTML_REPORT.t0;

# font-size: 16px; font-family: Courier;
#  tr:nth-child(even) {background-color: #f2f2f2;}
echo "</style>" >> $HTML_REPORT.t0;

echo "<script type=\"text/javascript\">" >> $HTML_REPORT.t0;
echo "function popBase64(base64URL){" >> $HTML_REPORT.t0;
echo "    var win = window.open();" >> $HTML_REPORT.t0;
echo "    win.document.write('<iframe src=\"' + base64URL  + '\" frameborder=\"0\" style=\"border:0; top:0px; left:0px; bottom:0px; right:0px; width:100%; height:100%;\" allowfullscreen></iframe>');" >> $HTML_REPORT.t0;
echo "    win.document.close();" >> $HTML_REPORT.t0;
echo "}" >> $HTML_REPORT.t0;
echo "</script>" >> $HTML_REPORT.t0;

echo "</head><body>" >> $HTML_REPORT.t0;
# echo "<h1>Process ID</h1>" >> $HTML_REPORT.t0;
if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
    echo "<a href="https://bravoprodapp.genome.mcgill.ca/clarity/work-details/$(echo "$PROCESS_ID" | awk -F'-' '{print $2}')">$PROCESS_ID</a><br>" >> $HTML_REPORT.t0;
fi
echo "<h1>Run Info</h1>" >> $HTML_REPORT.t0;
echo "<table class=\"style1\">" >> $HTML_REPORT.t0;
echo "<tr><th>Instrument Type</th><td>"$SEQ_TYPE"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Run Dir.</th><td>"${OUT_RUN_ROOT}"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Experiment Name</th><td>"$EXPERIMENT_NAME"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Flowcell Barcode (FCID)</th><td>"$FCID"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Original Run Cycles</th><td>"$MASK"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Instrument ID</th><td>"$INSTRUMENT"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Instrument Run Number</th><td>"$RUN_NUMBER"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Run Type</th><td>"$RUN_TYPE"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Index Type</th><td>"$INDEX_TYPE"</td></tr>" >> $HTML_REPORT.t0;
echo "<tr><th>Sbs Consumable Version</th><td>"${SBS_CONSUMABLE_VERSION:-Consumable Version Unset}"</td></tr>" >> $HTML_REPORT.t0;
echo "</table>" >> $HTML_REPORT.t0;

echo "<br>" >> $HTML_REPORT.t0;


############################
############################
# RUN METRICS
############################
############################


if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
    echo "<h1>Lane Index Metrics</h1>" >> $HTML_REPORT.t0;
    IFS=$'\n'
    echo "<table class=\"style2\">" >> $HTML_REPORT.t0
    echo "<tr><th align=\"center\">Lane</th><th align=\"center\">Count Illumina Barcodes</th><th align=\"center\">bcl2fastq no index</th><th>bcl2fastq indexed</th></tr>" >> $HTML_REPORT.t0

    for LANE in $(echo $ALLLANES | tr ' ' '\n'); do

        FORCE_MM_FLAG=$(ls $FORCE_MM_PATH/*${FCID}* 2>/dev/null)
        if [ -f "$FORCE_MM_FLAG" ]; then
           NUM_MISMATCH=$(cat $FORCE_MM_FLAG | grep "$LANE:" | awk -F ':' '{print $2}')
           if [ -z "$NUM_MISMATCH" ]; then
               NUM_MISMATCH=1;
           fi
        fi

        echo "<tr>" >> $HTML_REPORT.t0

        echo "<td align=\"center\">"$LANE"</td>" >> $HTML_REPORT.t0
        # index
        INDEX1=${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics-table
        INDEX2=${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics-table.html
        if [ -f "${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics" ]; then
	    if [ ! -f  "${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics.done" ]; then
		sh ${CODE_DIR}/make_index_report.sh ${OUTPUT_DIR}/index/${RUN_ID}_${LANE}.metrics $(echo "$SAMPLE_SHEET" | sed 's|collapsed_lanes|split_on_lanes|g') ${LANE};
		touch ${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics.done
	    fi
#          rm -f $INDEX1
#          rm -f $INDEX2
#          cat ${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics 2> /dev/null | grep -v "^#"  2> /dev/null | grep -v "^$" 2> /dev/null | head -n 1 >> $INDEX1
#          cat ${OUTPUT_DIR}/index/${INSTRUMENT}_${RUN_NUMBER}_${LANE}.metrics              | grep -v "^#" | grep -v "^$" | tail -n +2 | sort -nr -k3 2> /dev/null | head -n 100 >> $INDEX1
#          echo "<"'!'"doctype html><html><head><title>${OUT_RUN_ROOT} Lane:${LANE} index (CountIlluminaBarcodes)</title></head><body>" >> $INDEX2
#          echo "<h1>index (CountIlluminaBarcodes)</h1>" >> $INDEX2
#          echo "${OUT_RUN_ROOT} Lane:${LANE}<br>" >> $INDEX2
#          addindextable $INDEX1 >> $INDEX2
#          echo "</body></html>" >> $INDEX2
        fi

        echo "<td align=\"center\">" >> $HTML_REPORT.t0
        addbuttonfilelabel $INDEX2 "raw index found" >> $HTML_REPORT.t0
        echo "</td>" >> $HTML_REPORT.t0

        if [ -f "${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Reports/html/${FCID}/all/all/all/laneBarcode.html" ]; then
            INDEX3=${OUTPUT_DIR}/Unaligned.${LANE}/Reports/html/${FCID}/all/all/all/laneBarcode.html
            echo "<td align=\"center\">" >> $HTML_REPORT.t0
            addbuttonfilelabel $INDEX3 "summary no index" >> $HTML_REPORT.t0
            echo "</td>" >> $HTML_REPORT.t0
            INDEX4=${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Reports/html/${FCID}/all/all/all/laneBarcode.html
            echo "<td align=\"center\">" >> $HTML_REPORT.t0
            addbuttonfilelabel $INDEX4 "summary indexed (MM=$NUM_MISMATCH)" >> $HTML_REPORT.t0
            echo "</td>" >> $HTML_REPORT.t0

        else
            if [ -f "${OUTPUT_DIR}/Unaligned.${LANE}.noindex/Reports/html/${FCID}/all/all/all/laneBarcode.html" ]; then
                # runs 10015-10024
                INDEX3=${OUTPUT_DIR}/Unaligned.${LANE}.noindex/Reports/html/${FCID}/all/all/all/laneBarcode.html
                echo "<td align=\"center\">" >> $HTML_REPORT.t0
                addbuttonfilelabel $INDEX3 "summary no index" >> $HTML_REPORT.t0
                echo "</td>" >> $HTML_REPORT.t0
                INDEX4=${OUTPUT_DIR}/Unaligned.${LANE}/Reports/html/${FCID}/all/all/all/laneBarcode.html
                echo "<td align=\"center\">" >> $HTML_REPORT.t0
                addbuttonfilelabel $INDEX4 "summary indexed (MM=$NUM_MISMATCH)" >> $HTML_REPORT.t0
                echo "</td>" >> $HTML_REPORT.t0
            else
                # only one bcl2fastq output so assume it was demultiplexed
                echo "<td align=\"center\">" >> $HTML_REPORT.t0
                echo "</td>" >> $HTML_REPORT.t0
                INDEX4=${OUTPUT_DIR}/Unaligned.${LANE}/Reports/html/${FCID}/all/all/all/laneBarcode.html
                echo "<td align=\"center\">" >> $HTML_REPORT.t0
                addbuttonfilelabel $INDEX4 "summary indexed (MM=$NUM_MISMATCH)" >> $HTML_REPORT.t0
                echo "</td>" >> $HTML_REPORT.t0
            fi
        fi

        echo "</tr>" >> $HTML_REPORT.t0

        # thumbnails
        # THUMBNAILS=${OUTPUT_DIR}/thumb_anim/$SEQ_TYPE-movie-${OUT_RUN_ROOT}-L00${LANE}.gif
        # addgiffilelabel ${THUMBNAILS} "thumbnails" >> $HTML_REPORT.t0

    done
    echo "</table>" >> $HTML_REPORT.t0
    echo "<br>" >> $HTML_REPORT.t0

GNUPLOTDAT=${OUTPUT_DIR}/${OUT_RUN_ROOT}-${SEQ_TYPE}-per_sample_read_yield.txt;
rm -f  $GNUPLOTDAT.t0;
for LANE in $(echo $ALLLANES | tr ' ' '\n'); do
  f=${OUTPUT_DIR}/Unaligned.${LANE}.indexed/Stats/Stats.json;
  if [ ! -f "$f" ]; then
    f=${OUTPUT_DIR}/Unaligned.${LANE}/Stats/Stats.json;
  fi
  if [ -f "$f" ]; then
    cat $f | grep -A11 "SampleName" | grep -E "SampleName|NumberReads|Yield" |sed 's/SampleName/~/g' |sed 's/NumberReads//g'|sed 's/Yield//g'| tr -d '\n' | tr '~' '\n' | tr -d '"' \
      | tr -d ',' | tr -d ' ' | grep -v "^$" |cut -c 2-  | awk -F':' '{print $1 "\t"$2 "\t"$3"\t'$LANE'"}' >> $GNUPLOTDAT.t0
  fi
done

if [ -f "$GNUPLOTDAT.t0" ]; then

cat $GNUPLOTDAT.t0 | tr '\t' ',' | sed 's/_A,/,/g' | sed 's/_B,/,/g' | sed 's/_C,/,/g' | sed 's/_D,/,/g' | awk -F',' '{print $4"_"$1","$0}' | \
awk -F',' '{ a[$1]+=$3; b[$1]+=$4}END{ for(i in a) print i"," a[i]"," b[i] }' |  sort -t ',' -k1,1 > $GNUPLOTDAT.t1
cat $(echo $SAMPLE_SHEET | sed 's/collapsed_lanes/split_on_lanes/g') | grep -v "^#" | tail -n+2 | sort -t ',' -k7,7 -k22,22 -k21,21 -k3,3 \
   | awk -F',' '{print NR "," $7"_"$4"_"$3}' | sort -t ',' -k2,2 > $GNUPLOTDAT.t2;
join -1 1 -2 2 -a1 -t "," -o '2.1,1.1,1.2' -e 'NULL' $GNUPLOTDAT.t1 $GNUPLOTDAT.t2 | sort -t ',' -nk1 | awk -F',' '{print $2 ","$3}'| tr ',' '\t' > $GNUPLOTDAT;
rm $GNUPLOTDAT.t0 $GNUPLOTDAT.t1 $GNUPLOTDAT.t2;

GNUPLOT=$(cat <<EOF
#!/usr/bin/gnuplot
reset
set terminal png enhanced size 1200,400
# remove border on top and right and set color to gray
set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set tics nomirror
# define grid
set style line 12 lc rgb '#808080' lt 0 lw 1
set grid back ls 12
# color definitions
set style line 1 lc rgb '#8b1a0e' pt 7 ps 1 lt 1 lw 2 # --- red
set style line 2 lc rgb '#5e9c36' pt 6 ps 1 lt 1 lw 2 # --- green
set key off
# define axis
set format y "%.0s%c"
set xlabel 'Independent fastqs produced by bcl2fastq (from all lanes). Note: All reads in the lane are kept in the final fastq if one library per lane.'
set ylabel 'Clusters Per Sample'
set autoscale fix
set xrange [0:];
set yrange [0:];
set title '${OUT_RUN_ROOT}-${SEQ_TYPE}' noenhanced;
show title
set output '${OUTPUT_DIR}/${OUT_RUN_ROOT}-${SEQ_TYPE}-per_sample_read_yield.png';
plot '$GNUPLOTDAT' u 2 t 'Reads' w lp ls 1
EOF
);

  echo "$GNUPLOT" | gnuplot > /dev/null 2>&1
  addimage ${OUTPUT_DIR}/${OUT_RUN_ROOT}-${SEQ_TYPE}-per_sample_read_yield.png >> $HTML_REPORT.t0
  echo "<br>" >> $HTML_REPORT.t0

else
  echo "${OUT_RUN_ROOT}-${SEQ_TYPE}-per_sample_read_yield.png not ready yet.">> $HTML_REPORT.t0
  echo "<br>" >> $HTML_REPORT.t0
fi # no dat to plot

fi


############################
############################
# READ TABLE
############################
############################

echo "<h1>Read Set Metrics</h1>" > $HTML_REPORT.t0.t1
echo "<table class=\"style2\">" >> $HTML_REPORT.t0.t1
echo "<tr>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Lane</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Project Name</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Sample Name</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\" nowrap>Library Type</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\" nowrap>Library Index</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Clusters</th><th>Bases</th>" >> $HTML_REPORT.t0.t1
echo "<th width=\"60\">Avg. Qual</th><th width=\"60\">Dup. Rate (%)</th>" >> $HTML_REPORT.t0.t1
if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
    echo "<th align=\"center\">R1</th>" >> $HTML_REPORT.t0.t1
    echo "<th align=\"center\">I1</th>" >> $HTML_REPORT.t0.t1
    echo "<th align=\"center\">I2</th>" >> $HTML_REPORT.t0.t1
    echo "<th align=\"center\">R2</th>" >> $HTML_REPORT.t0.t1
fi
echo "<th>Species Match R1</th>" >> $HTML_REPORT.t0.t1
echo "<th>Species Match R2</th>" >> $HTML_REPORT.t0.t1
echo "<th>Top Sample Tag Name Match</th>" >> $HTML_REPORT.t0.t1
echo "<th>Submitted Sex Match</th>" >> $HTML_REPORT.t0.t1
echo "<th>Sample On Fraction</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Data ID</th>" >> $HTML_REPORT.t0.t1

echo "<th align=\"center\">Project ID</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Sample ID</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Library ID</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">ChIP-Seq Mark</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Pooling Type</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Pooling ID</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Capture Type</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Capture Name</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">Submitted Species</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">R1 Top Blast Hit Name</th>" >> $HTML_REPORT.t0.t1
echo "<th width=\"100\" align=\"center\">R1 Top Blast Hit Rate (%)</th>" >> $HTML_REPORT.t0.t1
echo "<th align=\"center\">R2 Top Blast Hit Name</th>" >> $HTML_REPORT.t0.t1
echo "<th width=\"100\" align=\"center\">R2 Top Blast Hit Rate (%)</th>" >> $HTML_REPORT.t0.t1

echo "<th>Top Sample Tag Name</th>" >> $HTML_REPORT.t0.t1
echo "<th>Top Sample Tag Rate from Total (%)</th>" >> $HTML_REPORT.t0.t1
echo "<th>Top Sample Tag Rate from All Detected (%)</th>" >> $HTML_REPORT.t0.t1
echo "<th>Expected Sample Tag Name</th>" >> $HTML_REPORT.t0.t1

echo "<th>Clusters on Index in Lane (%)</th>" >> $HTML_REPORT.t0.t1
echo "<th>Expected Lane Fraction</th>" >> $HTML_REPORT.t0.t1
echo "<th>Clusters on Index in Lane from Target (%)</th>" >> $HTML_REPORT.t0.t1

echo "<th>Submitted Sex</th>" >> $HTML_REPORT.t0.t1
echo "<th>Detected Sex</th>" >> $HTML_REPORT.t0.t1

echo "<th>rRNA BLAST Database</th>" >> $HTML_REPORT.t0.t1
echo "<th>R1 rRNA BLAST Hits</th>" >> $HTML_REPORT.t0.t1
echo "<th>R1 rRNA BLAST Total</th>" >> $HTML_REPORT.t0.t1
echo "<th>R1 rRNA BLAST Ratio</th>" >> $HTML_REPORT.t0.t1
echo "<th>R2 rRNA BLAST Hits</th>" >> $HTML_REPORT.t0.t1
echo "<th>R2 rRNA BLAST Total</th>" >> $HTML_REPORT.t0.t1
echo "<th>R2 rRNA BLAST Ratio</th>" >> $HTML_REPORT.t0.t1

# echo "<th>R1 PhiX Rate from Total (%)</th>" >> $HTML_REPORT.t0.t1
# echo "<th>R2 PhiX Rate from Total (%)</th>" >> $HTML_REPORT.t0.t1

echo "<th width=\"80\" align=\"center\">blast</th>" >> $HTML_REPORT.t0.t1
echo "<th width=\"80\" align=\"center\">QC graphs</th>" >> $HTML_REPORT.t0.t1
if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
    echo "<th width=\"80\" align=\"center\">fastqc</th>" >> $HTML_REPORT.t0.t1
fi
echo "</tr>" >> $HTML_REPORT.t0.t1

############################
############################
# ALIGN TABLE
############################
############################

echo "<h1>Alignment Metrics</h1>" > $HTML_REPORT.t0.t2;
echo "<table class=\"style2\">" >> $HTML_REPORT.t0.t2
echo "<tr>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Lane</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Project Name</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Project ID</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Sample Name</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Sample ID</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Library Type</th>" >> $HTML_REPORT.t0.t2

echo "<th align=\"center\">Pooling Type</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Pooling ID</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Capture Type</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Capture Name</th>" >> $HTML_REPORT.t0.t2

echo "<th align=\"center\">Library ID</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Library Index</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Reference</th>" >> $HTML_REPORT.t0.t2
echo "<th align=\"center\">Bed</th>" >> $HTML_REPORT.t0.t2
echo "<th>PF Reads Aligned All</th><th>PF Reads Aligned All (%)</th><th>PF Reads Aligned R1 (%)</th><th>PF Reads Aligned R2 (%)</th><th>Chimeras (%)</th><th>Adapter (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\">Mapped Insert Size (median)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\">Mapped Insert Size (mean)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\">Mapped Insert Size (std. dev.)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\">Aligned Dup. Rate (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Mean Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Bases Covered At 10x (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Bases Covered At 25x (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Bases Covered At 50x (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Bases Covered At 75x (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Bases Covered At 100x (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Aligned Bases On Target (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">On Bait Bases from On Target Bases (%)</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Freemix Number of SNP</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Freemix Value</th>" >> $HTML_REPORT.t0.t2

echo "<th width=\"80\" align=\"center\">chr1 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr2 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr3 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr4 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr5 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr6 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr7 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr8 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr9 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr10 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr11 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr12 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr13 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr14 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr15 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr16 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr17 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr18 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr19 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr20 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr21 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chr22 Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chrX Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chrY Normalized Coverage</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">chrM Normalized Coverage</th>" >> $HTML_REPORT.t0.t2

echo "<th width=\"80\" align=\"center\">Intragenic Rate</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Unique Rate of Mapped</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Intergenic Rate</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Transcripts Detected</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Intronic Rate</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Mapped Unique Rate of Total</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Duplication Rate of Mapped</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Expression Profiling Efficiency</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">End 1 % Sense</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">End 2 % Sense</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">Estimated Library Size</th>" >> $HTML_REPORT.t0.t2
echo "<th width=\"80\" align=\"center\">rRNA rate</th>" >> $HTML_REPORT.t0.t2

if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
    echo "<th width=\"80\" align=\"center\">align. metrics</th>" >> $HTML_REPORT.t0.t2
fi
echo "</tr>" >> $HTML_REPORT.t0.t2

IFS=$'\n'
for LANE in $(echo $ALLLANES | tr ' ' '\n'); do

    local COUNT=0
    local NOSKIPCOUNT=0
    IFS=$'\n'
    NSAMPLES=$(readsamplesheet | awk -F, '$7=='$LANE'{print $0}' | wc -l);

    for line in $(readsamplesheet); do

	PROJECT_ID=$(echo $line | awk -F, '{print $1}');
	PROJECT_NAME=$(echo $line | awk -F, '{print $2}');
	LIB_ID=$(echo $line | awk -F, '{print $3}');
	SAMPLE_NAME=$(echo $line | awk -F, '{print $4}');
	SAMPLE_ID=$(echo $line | awk -F, '{print $5}');
	INDEX_NAME=$(echo $line | awk -F, '{print $6}');
	LANES=$(echo $line | awk -F, '{print $7}');
	ARTIFACT_IDS=$(echo $line | awk -F, '{print $8}');
	LIB_TYPE=$(echo $line | awk -F, '{print $9}');
	LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
	PROCESSING_TYPE=$(echo $line | awk -F, '{print $11}');
	REF_and_BED=$(echo $line | awk -F, '{print $12}');
	EXPECTED_SAMPLE_TAG=$(echo $line | awk -F, '{print $13}');

        TARGET_CELLS=$(echo $line | awk -F, '{print $14}');
        LIBRARY_METADATA_ID=$(echo $line | awk -F, '{print $15}');
        SPECIES=$(echo $line | awk -F, '{print $16}');
        GENOME_SIZE_MB=$(echo $line | awk -F, '{print $17}');
        SEX=$(echo $line | awk -F, '{print $18}');
        POOL_FRACTIONS=$(echo $line | awk -F, '{print $19}');
        POOLING_TYPES=$(echo $line | awk -F, '{print $20}');
        POOLING_IDS=$(echo $line | awk -F, '{print $21}');
        CAPTURE_NAMES=$(echo $line | awk -F, '{print $22}');
        CAPTURE_REF_BEDS=$(echo $line | awk -F, '{print $23}');
        CAPTURE_METADATA_IDS=$(echo $line | awk -F, '{print $24}');
        ARTIFACTLUIDCLUSTERINGS=$(echo $line | awk -F, '{print $25}');
        LIBRARY_SIZE=$(echo $line | awk -F, '{print $26}');
        LIBRARY_KIT_NAME=$(echo $line | awk -F, '{print $27}');
        CAPTURE_KIT_TYPES=$(echo $line | awk -F, '{print $28}');
        CAPTURE_BAIT_VERSIONS=$(echo $line | awk -F, '{print $29}');
        CHIPSEQMARKS=$(echo $line | awk -F, '{print $30}');

        REF=$(echo "$REF_and_BED" | awk -F';' '{print $1}' | tr ':' '.')
        BED_FILES=$(echo "$REF_and_BED" | awk -F';' '{$1=""; print $0}' | tr ' ' ';' | sed "s|;|;${BED_PATH}/|g" | cut -c 2-)

        DATA_TO_KEEP=$(grep "^$LIB_TYPE," $LIBRARY_PROTOCOL_LIST | awk -F',' '{print $4}')

        if [ "$(echo $LANES | grep -c $LANE)" == "0" ]; then
            continue
        fi

        LANEPOS=$(echo "$LANES" | tr '-' '\n' | grep "$LANE" -n | awk -F':' '{print $1}');
        ARTIFACT_ID=$(echo "$ARTIFACT_IDS" | cut -d "|" -f $LANEPOS);
        POOL_FRACTION=$(echo "$POOL_FRACTIONS" | cut -d "|" -f $LANEPOS);
        POOLING_TYPE=$(echo "$POOLING_TYPES" | cut -d "|" -f $LANEPOS);
        POOLING_ID=$(echo "$POOLING_IDS" | cut -d "|" -f $LANEPOS);
        CAPTURE_NAME=$(echo "$CAPTURE_NAMES" | cut -d "|" -f $LANEPOS);
        CAPTURE_REF_BED=$(echo "$CAPTURE_REF_BEDS" | cut -d "|" -f $LANEPOS);
        CAPTURE_METADATA_ID=$(echo "$CAPTURE_METADATA_IDS" | cut -d "|" -f $LANEPOS);
        ARTIFACTLUIDCLUSTERING=$(echo "$ARTIFACTLUIDCLUSTERINGS" | cut -d "|" -f $LANEPOS);
        CAPTURE_KIT_TYPE=$(echo "$CAPTURE_KIT_TYPES" | cut -d "|" -f $LANEPOS);
        CAPTURE_BAIT_VERSION=$(echo "$CAPTURE_BAIT_VERSIONS" | cut -d "|" -f $LANEPOS);
        CHIPSEQMARK=$(echo "$CHIPSEQMARKS" | cut -d "|" -f $LANEPOS);

        CAPTUREREF=$(echo "$CAPTURE_REF_BED" | awk -F';' '{print $1}' | tr ':' '.')
        CAPTUREBED_FILES=$(echo "$CAPTURE_REF_BED" | awk -F';' '{$1=""; print $0}' | tr ' ' ';' | sed "s|;|;${BED_PATH}/|g" | cut -c 2-)

        let COUNT=${COUNT}+1
        let NOSKIPCOUNT=$NOSKIPCOUNT+1

        if  [ "$PROJECT_ID_FILTER" != "MAIN" ] && [ "$PROJECT_ID_FILTER" != "$PROJECT_ID" ]; then
            continue; # ID present/not main and not equal, so skip
        fi

        POOL_ON_FRACTION="";
        DATASET_SIZE_PER_PROJECT="";
        DATASET_SIZE_PER_EXTERNAL_PROJECT="";

        if [ "$LIB_TYPE" == "RNASeq" ] || [ "$CAPTURE_KIT_TYPE" == "MCC" ]; then
            if [[ "$INDEX_NAME" == IDT* ]] || [[ "$INDEX_NAME" == ILLUDI* ]]; then
                LIBRARY_STRANDEDNESS="stranded-antisense";
            else
                LIBRARY_STRANDEDNESS="stranded-sense";
            fi
        else
            LIBRARY_STRANDEDNESS="non-stranded";
        fi

        if [ "$OVERMASK" == "" ]; then
            FINALMASK="$MASK";
        else
            FINALMASK="$OVERMASK";
        fi

        DETECTEDSEX="";
        SEXMATCH="";
        SPECIES_MATCH_R1="";
        SPECIES_MATCH_R2="";
        SAMPLE_ON_FRACTION="";
        COMMENT="";

        EXTERNAL_PROJECT_CODE=$PROJECT_ID;
        BILLING_STRING="0"
        INVOICE_FRACTION="0"

        QCSTATS=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc/mpsQC_${SAMPLE_NAME}_${LIB_ID}_L00${LANE}_stats.csv
        NB_READS=""; NB_BASES=""; NB_READS_format=""; NB_BASES_format=""; AVG_QUAL=""; DUPLICATE_RATE="";
        if [ -f "$QCSTATS" ]; then
            NB_READS=$(cat $QCSTATS | tail -n+2 | awk -F',' '{printf "%i",$1}')
            NB_BASES=$(cat $QCSTATS | tail -n+2 | awk -F',' '{printf "%i",$2}')
            NB_READS_format=$(cat $QCSTATS | tail -n+2 | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i",$1}')
            NB_BASES_format=$(cat $QCSTATS | tail -n+2 | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i",$2}')
            AVG_QUAL=$(cat $QCSTATS | tail -n+2 | awk -F',' '{printf "%0.1f",$3}')
            DUPLICATE_RATE=$(cat $QCSTATS | tail -n+2 | awk -F',' '{printf "%0.1f",$4}')
        fi
	
        # XXX
	FQ1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
	FQ2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
        FASTQCSTATS1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001_fastqc/fastqc_data.txt
        FASTQCSTATS2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001_fastqc/fastqc_data.txt
        if [ -f $FQ1 ] && [ -f $FQ2 ]; then
            if [ -f "$FASTQCSTATS1" ] && [ -f "$FASTQCSTATS2" ]; then
                NB_READS=$( grep "Total Sequences" $FASTQCSTATS1 | awk '{print $3}' );
                TOTALLENGTH=$( (
			grep "Sequence length" $FASTQCSTATS1;
			grep "Sequence length" $FASTQCSTATS2;
                    ) | awk '{ total += $3; count++ } END { print total }'
		);
                NB_BASES=$(( $NB_READS * $TOTALLENGTH ));
                NB_READS_format=$( echo $NB_READS | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i", $1}' );
                NB_BASES_format=$( echo $NB_BASES | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i", $1}' );
                AVG_QUAL=$( (
			cat $FASTQCSTATS1 | sed -n '/>>Per base sequence quality/,/>>END_MODULE/p' | grep -v -E "^#|^>";
			cat $FASTQCSTATS2 | sed -n '/>>Per base sequence quality/,/>>END_MODULE/p' | grep -v -E "^#|^>";
                    ) | awk '{ total += $2; count++ } END { printf "%0.1f", total/count }'
		);
                DUPLICATE_RATE=$( (
			grep "Total Deduplicated Percentage" $FASTQCSTATS1 | awk '{print $4}';
			grep "Total Deduplicated Percentage" $FASTQCSTATS2 | awk '{print $4}';
		    ) | awk '{ total += $1; count++ } END { printf "%0.1f", 100-total/count }';
		);
            fi
        elif [ -f $FQ1 ]; then
            if [ -f "$FASTQCSTATS1" ]; then
                NB_READS=$(grep "Total Sequences" $FASTQCSTATS1 | awk '{print $3}')
                TOTALLENGTH=$((
			grep "Sequence length" $FASTQCSTATS1;                
                    ) | awk '{ total += $3; count++ } END { print total }'
		);
                NB_BASES=$(( $NB_READS * $TOTALLENGTH ));
                NB_READS_format=$(echo $NB_READS | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i",$1}');
                NB_BASES_format=$(echo $NB_BASES | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i",$1}');
                AVG_QUAL=$( (
			cat $FASTQCSTATS1 | sed -n '/>>Per base sequence quality/,/>>END_MODULE/p' | grep -v -E "^#|^>";
                    ) | awk '{ total += $2; count++ } END { printf "%0.1f", total/count }'
		);
                DUPLICATE_RATE=$( (
			grep "Total Deduplicated Percentage" $FASTQCSTATS1 | awk '{print $4}';
		    ) | awk '{ total += $1; count++ } END { printf "%0.1f", 100-total/count }';
		);
            fi
	else
	    NB_BASES=0;
	    NB_READS=0;
            NB_READS_format=$(echo $NB_READS | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i",$1}');
            NB_BASES_format=$(echo $NB_BASES | LC_ALL=en_US.UTF-8 awk -F',' '{printf "%'"'"'i",$1}');
        fi      
        
        BLASTR1=${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.RDP.blastHit_20MF_species.txt
        BLASTR2=${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.RDP.blastHit_20MF_species.txt
        getblastpercent $BLASTR1
        TOP_HIT_R1=$TOP_HIT;
        PERCENT_HIT_R1=$PERCENT_HIT;
        getblastpercent $BLASTR2
        TOP_HIT_R2=$TOP_HIT;
        PERCENT_HIT_R2=$PERCENT_HIT;
	
        if [ "$SPECIES" != "N/A" ]; then
            TOP_HIT_R1_TMP=$(echo $TOP_HIT_R1 | tr '[:upper:]' '[:lower:]' | tr ' ' '_' )
            TOP_HIT_R2_TMP=$(echo $TOP_HIT_R2 | tr '[:upper:]' '[:lower:]' | tr ' ' '_' )

            if [[ "$SPECIES" == *":"* ]]; then
                TMPSUBSPECIES=$(echo $SPECIES | awk -F':' '{print $2}' | sed 's/ (/(/g'| awk -F"(" '{print $1}' | tr '[:upper:]' '[:lower:]' | tr -d ',' | tr -d '.' | awk -F' ' '{print $1 "_" $2}');
            else
                TMPSUBSPECIES=$(echo $SPECIES | tr '[:upper:]' '[:lower:]' | tr -d ',' | tr -d '.' | tr ' ' '_');
            fi


           if [ ! -z "$TMPSUBSPECIES" ] ; then

           if [ ! -z "$TOP_HIT_R1_TMP" ] ; then
            if [ "$TOP_HIT_R1_TMP" == "$TMPSUBSPECIES" ]; then
                SPECIES_MATCH_R1=True
            else
                SPECIES_MATCH_R1=False
            fi
           fi

           if [ ! -z "$TOP_HIT_R2_TMP" ] ; then
            if [ "$TOP_HIT_R2_TMP" == "$TMPSUBSPECIES" ]; then
                SPECIES_MATCH_R2=True
            else
                SPECIES_MATCH_R2=False
            fi
           fi

           fi

        fi

        BLASTRRNAR1=$(ls ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R1.subSampled_*.rrna 2>/dev/null)
        BLASTRRNAR2=$(ls ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_L00${LANE}.R2.subSampled_*.rrna 2>/dev/null)
        RRNA_BLAST_DATABASE_R1=""; RRNA_BLAST_HITS_R1=""; RRNA_BLAST_TOTAL_R1=""; RRNA_BLAST_RATIO_R1="";
        RRNA_BLAST_DATABASE_R2=""; RRNA_BLAST_HITS_R2=""; RRNA_BLAST_TOTAL_R2=""; RRNA_BLAST_RATIO_R2="";
        if [ -f "$BLASTRRNAR1" ]; then
            IFS='|' read RRNA_BLAST_DATABASE_R1 RRNA_BLAST_HITS_R1 RRNA_BLAST_TOTAL_R1 <<<$(cat $BLASTRRNAR1 | tr '\n' '|');
            RRNA_BLAST_RATIO_R1=$(echo "" | awk '{printf "%0.3f",'$RRNA_BLAST_HITS_R1'/'$RRNA_BLAST_TOTAL_R1'}' 2> /dev/null );
        fi
        if [ -f "$BLASTRRNAR2" ]; then
            IFS='|' read RRNA_BLAST_DATABASE_R2 RRNA_BLAST_HITS_R2 RRNA_BLAST_TOTAL_R2 <<<$(cat $BLASTRRNAR2 | tr '\n' '|');
            RRNA_BLAST_RATIO_R2=$(echo "" | awk '{printf "%0.3f",'$RRNA_BLAST_HITS_R2'/'$RRNA_BLAST_TOTAL_R2'}' 2> /dev/null );
        fi

        SAMPLE_TAG_CSV=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.R1/${SAMPLE_NAME}_${LIB_ID}.sample_tag_stats.csv;
        TOP_DETECT=""; TOP_RATE=""; PERC_FROM_DETECT=""; MATCH="";
        if [ -f "$SAMPLE_TAG_CSV" ]; then
          TOP_DETECT=$(tail -n+2 $SAMPLE_TAG_CSV | awk -F, '{print $3}');
          TOP_RATE=$(tail -n+2 $SAMPLE_TAG_CSV | awk -F, '{print $4}');
          PERC_FROM_DETECT=$(tail -n+2 $SAMPLE_TAG_CSV | awk -F, '{print $5}');
          # MATCH=$(tail -n+2 $SAMPLE_TAG_CSV | awk -F, '{print $7}');

          if [ "$EXPECTED_SAMPLE_TAG" == "" ] || [ "$EXPECTED_SAMPLE_TAG" == "N/A" ]; then
              :
          else
              if [ "$(echo $EXPECTED_SAMPLE_TAG  | sed 's/[A-Za-z]*//g'  | sed 's/^_*//' | tr -d ' ' | sed 's/^0*//' | awk -F'_' '{print $1}')" == "$(echo $TOP_DETECT | sed 's/[A-Za-z]*//g'  | sed 's/^_*//' | tr -d ' ' | sed 's/^0*//' | awk -F'_' '{print $1}')" ]; then
                  MATCH=True;
              else
                  MATCH=False;
              fi
          fi

        fi

        found=false
        BARCODECOUNT=0;
        ALLCOUNT=1;
        if [ -d "${OUTPUT_DIR}/Unaligned.$LANE.indexed" ]; then
            TMPD=${OUTPUT_DIR}/Unaligned.$LANE.indexed;
        else
            TMPD=${OUTPUT_DIR}/Unaligned.$LANE;
        fi

        f=$TMPD/Stats/DemultiplexingStats.xml;

        GENERATE_UMI9=0;
        if($(echo "$MASK" | grep -q -E ',I17,')); then
          GENERATE_UMI9=1;
          OVERMASK=$(echo "$MASK" | sed 's/,I17,/,I8n*,/g')
          OVERINDEX1=8; OVERINDEX2=8;
        fi

        LIBRARY_PER_LANE=0
        INDEX_COUNT_1OR2_ACCU=""
        INDEX1_LENGTH_ACCU=""
        INDEX2_LENGTH_ACCU=""
        for line in $(readsamplesheet); do
            _INDEX_NAME=$(echo $line | awk -F, '{print $6}');
            _LANES=$(echo $line | awk -F, '{print $7}');
            if [[ "$_LANES" == *$LANE* ]]; then
		_LIB_TYPE=$(echo $line | awk -F, '{print $9}');
		_LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
                let LIBRARY_PER_LANE=$LIBRARY_PER_LANE+1;
		if [[ "$_INDEX_NAME" == *-* ]] && [[ "$_INDEX_NAME" != SI-* ]]; then
                    KEY=$(echo "$_INDEX_NAME" | awk -F'-' '{print $1}');
                    KEY2=$(echo "$_INDEX_NAME" | awk -F'-' '{print $2}');
		    INDEX1_LENGTH=$(awk -F',' -v key=$KEY '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX1_LENGTH_ACCU="$INDEX1_LENGTH_ACCU,$INDEX1_LENGTH"
		    INDEX2_LENGTH=$(awk -F',' -v key=$KEY2 '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX2_LENGTH_ACCU="$INDEX2_LENGTH_ACCU,$INDEX2_LENGTH"
		elif [ "$_LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$_LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ]; then
                    KEY=$_INDEX_NAME;
		    INDEX2_LENGTH=$(awk -F',' -v key=$KEY '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX2_LENGTH_ACCU="$INDEX2_LENGTH_ACCU,$INDEX2_LENGTH"
		else
                    KEY=$_INDEX_NAME;
		    INDEX1_LENGTH=$(awk -F',' -v key=$KEY '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX1_LENGTH_ACCU="$INDEX1_LENGTH_ACCU,$INDEX1_LENGTH"
                fi
                INDEX_COUNT_1OR2=$( grep "^$KEY," $ADAPTER_TYPES_FILE | awk -F',' '{print $3}' | head -n 1);
                INDEX_COUNT_1OR2_ACCU="$INDEX_COUNT_1OR2_ACCU,$INDEX_COUNT_1OR2"
            fi
        done

	MAX_INDEX1_CYCLES=$(echo "$INDEX1_LENGTH_ACCU" | tr ',' '\n' | grep -v "^$" | sort -nr | head -n 1)
	MAX_INDEX2_CYCLES=$(echo "$INDEX2_LENGTH_ACCU" | tr ',' '\n' | grep -v "^$" | sort -nr | head -n 1)

	if [ "$MAX_INDEX1_CYCLES" != "" ]; then
	    if [ "$INDEX1CYCLESORIG" -lt "$MAX_INDEX1_CYCLES" ]; then
		MAX_INDEX1_CYCLES=$INDEX1CYCLESORIG;
	    fi
	fi
	if [ "$MAX_INDEX2_CYCLES" != "" ]; then
	    if [ "$INDEX2CYCLESORIG" -lt "$MAX_INDEX2_CYCLES" ]; then
		MAX_INDEX2_CYCLES=$INDEX2CYCLESORIG;
	    fi
	fi
	
	# only single index in lane
	I2_AS_READ2=false;
	I1_AS_READ2=false;
        if [ "$(echo "$INDEX_COUNT_1OR2_ACCU" | tr ',' '\n' | grep -v "^$" | sort -u)" == "SINGLEINDEX" ] || ( [ "$LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ] ); then
            if [ "$(echo "$MASK" | awk -F',' '{print $2}' | tr -d '0123456789')" == "I" ] && ( [ "$_LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$_LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ] ); then # R2 is I1
		PAD2=""; if [ "$INDEX2CYCLESORIG" != "$MAX_INDEX2_CYCLES" ]; then PAD2='n*'; fi
		# always output index 2 as read when unused
                OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",Y'$INDEX1CYCLESORIG',I'$MAX_INDEX2_CYCLES$PAD2',"$4}' | sed 's/,$//');
                OVERINDEX1=0; OVERINDEX2=$MAX_INDEX2_CYCLES;
		BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 8"
		I1_AS_READ2=true;	    
	    elif [ "$(echo "$MASK" | awk -F',' '{print $3}' | tr -d '0123456789')" == "I" ]; then # R2 is I2
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
		# always output index 2 as read when unused
                OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',Y'$INDEX2CYCLESORIG',"$4}' | sed 's/,$//');
                OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=0;
		BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 8"
		I2_AS_READ2=true;
	    else # read 3 is not index
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
                OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',"$3}' | sed 's/,$//');
                OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=0;
            fi
	else
	    # only dual index in lane or MIX
	    if [ "$(echo "$MASK" | awk -F',' '{print $3}' | tr -d '0123456789')" == "I" ]; then # read 3 is sequenced as index
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
		PAD2=""; if [ "$INDEX2CYCLESORIG" != "$MAX_INDEX2_CYCLES" ]; then PAD2='n*'; fi
		OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',I'$MAX_INDEX2_CYCLES$PAD2',"$4}' | sed 's/,$//');
		OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=$MAX_INDEX2_CYCLES;
	    else # read 3 is not index
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
		OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',"$3}' | sed 's/,$//');
		OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=0;
	    fi
	fi

#        if [ "$(readsamplesheet | awk -F, -v l=$LANE '$7==l&&$9=="HaloPlex"{print $0}' | wc -l)" != "0" ]; then
#           OVERMASK=$(echo "$MASK" | sed 's/,I8,I10,/,I8,Y10,/g' | sed 's/,I8,I8,/,I8,Y8,/g')
#           OVERINDEX1=8; OVERINDEX2=0;
#           # BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 10"
#           BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 8"
#        fi

        if [ "$OVERMASKMAIN" == "" ]; then
	    :
        else
            OVERMASK=$OVERMASKMAIN
            OVERINDEX1=$OVERINDEX1MAIN; OVERINDEX2=$OVERINDEX2MAIN;
        fi

        getcycles $RUN_DIR/RunInfo.xml

        if [ "$READ2CYCLES" == "0" ]; then
            RUN_TYPE=SINGLE_END;
        else
            RUN_TYPE=PAIRED_END;
        fi

        if [ "$INDEX2CYCLES" == "0" ] || [ "$INDEX1CYCLES" == "0" ]; then
            INDEX_TYPE=SINGLE_INDEX;
        else
            INDEX_TYPE=DUAL_INDEX;
        fi

        for VAL in $(getindex); do
            ADAPTERi7=$(echo $VAL | awk -F, '{print $4}');
            ADAPTERi5=$(echo $VAL | awk -F, '{print $5}');
            break;
        done
	
        if [ -f "$f" ]; then

            if [ "$(cat $f | tr -d '\n' | sed 's/arcode>/arcode>~/g' | tr '~' '\n' | tr -d ' ' | grep -v '^$' | awk -F'<Barcodename=' '{print $2}' \
                       | grep -v '^$' | grep -v -E 'all|unknown' | wc -l )" -gt "0" ]; then
                Lst1=$(cat $f | tr -d '\n' | sed 's/arcode>/arcode>~/g' | tr '~' '\n' | tr -d ' ' | grep -v '^$' | awk -F'<Barcodename=' '{print $2}' \
                         | grep -v '^$' | grep 'all' | tail -n 1);
                ALLCOUNT=$(echo "$Lst1" | awk -F'<BarcodeCount>' '{print $2}'| awk -F'</BarcodeCount>' '{print $1}');
                TARGET="";
                for VAL in $(getindex); do
                    BCL2FASTQ_INDEX1=$(echo $VAL | awk -F, '{print $2}');
                    BCL2FASTQ_INDEX2=$(echo $VAL | awk -F, '{print $3}');
                    if [ "$BCL2FASTQ_INDEX2" == "" ]; then
                        if [ "$TARGET" == "" ]; then TARGET="$BCL2FASTQ_INDEX1";
                        else TARGET="$TARGET|$BCL2FASTQ_INDEX1";
                        fi
                    else
                        if [ "$TARGET" == "" ]; then  TARGET="$BCL2FASTQ_INDEX1$BCL2FASTQ_INDEX2";
                        else TARGET="$TARGET|$BCL2FASTQ_INDEX1$BCL2FASTQ_INDEX2";
                        fi
                    fi
                done
                Lst2=$(cat $f | tr -d '\n' | sed 's/arcode>/arcode>~/g' | tr '~' '\n' | tr -d ' ' | grep -v '^$' | awk -F'<Barcodename=' '{print $2}' \
                           | grep -v '^$' | grep -v -E 'all|unknown' | tr -d '+');
                BARCODECOUNT=$(echo "$Lst2"  | grep -E "$TARGET" | awk -F'<BarcodeCount>' '{print $2}' | awk -F'</BarcodeCount>' '{print $1}' | awk '{sum+=$1} END {print sum}');
                if [ "$BARCODECOUNT" == "" ]; then
                    BARCODECOUNT=0;
                else
                    found=true;
                fi;
            fi;
        fi;
        INDEX_PERCENT="";
        INDEX_PERCENT_NORM="";
        if ($found); then
            INDEX_PERCENT=$(echo "" | awk '{printf "%0.5f",'$BARCODECOUNT'/'$ALLCOUNT'*100}');
            INDEX_PERCENT_NORM=$(echo "" | awk '{printf "%0.1f",'$BARCODECOUNT'/'$ALLCOUNT'/'$POOL_FRACTION'*100}');
            if [ "$(echo $INDEX_PERCENT_NORM'>='80 | bc -l)" == "1" ] && [ "$(echo $INDEX_PERCENT_NORM'<='120 | bc -l)" == "1" ]; then
                SAMPLE_ON_FRACTION=True;
            else
                SAMPLE_ON_FRACTION=False;
            fi
        fi

        if [ "$REF" != "" ]; then

            ALIGNMETRICS=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.alignment_summary_metrics
            PF_Reads_Aligned_All=""; PF_Reads_Aligned_All_PCT=""; PF_Reads_Aligned_R1_PCT=""; PF_Reads_Aligned_R2_PCT=""; Chimeras_PCT=""; Adapter_PCT="";
            PF_Reads_Aligned_All_format="";

            if [ -f "$ALIGNMETRICS" ]; then
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                    PF_Reads_Aligned_All=$(cat $ALIGNMETRICS | grep "^PAIR" | awk '{printf "%i",$6}');
                    PF_Reads_Aligned_All_format=$(cat $ALIGNMETRICS | grep "^PAIR" | LC_ALL=en_US.UTF-8 awk '{printf "%'"'"'i",$6}')
                    PF_Reads_Aligned_All_PCT=$(cat $ALIGNMETRICS | grep "^PAIR" | awk '{printf "%0.1f",$7*100}');
                    PF_Reads_Aligned_R1_PCT=$(cat $ALIGNMETRICS | grep "^FIRST_OF_PAIR" | awk '{printf "%0.1f",$7*100}');
                    PF_Reads_Aligned_R2_PCT=$(cat $ALIGNMETRICS | grep "^SECOND_OF_PAIR" | awk '{printf "%0.1f",$7*100}');
                    Chimeras_PCT=$(cat $ALIGNMETRICS | grep "FIRST_OF_PAIR" | awk '{printf "%0.3f",$23*100}');
                    Adapter_PCT=$(cat $ALIGNMETRICS | grep "FIRST_OF_PAIR" | awk '{printf "%0.3f",$24*100}');
                else
                    PF_Reads_Aligned_All=$(cat $ALIGNMETRICS | grep "^UNPAIRED" | awk '{printf "%i",$6}');
                    PF_Reads_Aligned_All_format=$(cat $ALIGNMETRICS | grep "^UNPAIRED" | LC_ALL=en_US.UTF-8 awk '{printf "%'"'"'i",$6}')
                    PF_Reads_Aligned_All_PCT=$(cat $ALIGNMETRICS | grep "^UNPAIRED" | awk '{printf "%0.1f",$7*100}');
                    PF_Reads_Aligned_R1_PCT=$(cat $ALIGNMETRICS | grep "^UNPAIRED" | awk '{printf "%0.1f",$7*100}');
                    PF_Reads_Aligned_R2_PCT="";
                    Chimeras_PCT=$(cat $ALIGNMETRICS | grep "UNPAIRED" | awk '{printf "%0.3f",$23*100}');
                    Adapter_PCT=$(cat $ALIGNMETRICS | grep "UNPAIRED" | awk '{printf "%0.3f",$24*100}');
                fi
            fi
            INSERTMETRICS=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.insert_size_metrics
            MEAN_INSERT_SIZE=""; MEDIAN_INSERT_SIZE=""; STDDEV_INSERT_SIZE="";
            if [ -f "$INSERTMETRICS" ]; then
              MEDIAN_INSERT_SIZE=$(cat $INSERTMETRICS | grep -v '^#' | grep -A1 MEAN_INSERT_SIZE | tail -n +2 | awk '{printf "%i",$1}');
              MEAN_INSERT_SIZE=$(cat $INSERTMETRICS | grep -v '^#' | grep -A1 MEAN_INSERT_SIZE | tail -n +2 | awk '{printf "%0.1f",$6}');
              STDDEV_INSERT_SIZE=$(cat $INSERTMETRICS | grep -v '^#' | grep -A1 MEAN_INSERT_SIZE | tail -n +2 | awk '{printf "%0.1f",$7}');
            fi
            DUPMETRICS=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics
            PERCENT_DUPLICATION="";
            if [ -f "$DUPMETRICS" ]; then
              PERCENT_DUPLICATION=$(cat $DUPMETRICS | grep -v '^#' | grep -A1 LIBRARY | tail -n+2 | awk '{printf "%0.1f",$8*100}');
            fi
            TARGETCOVERAGE=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.targetCoverage.txt
            MEAN_COVERAGE="";
            Bases_Covered_At_10x_PCT="";
            Bases_Covered_At_25x_PCT="";
            Bases_Covered_At_50x_PCT="";
            Bases_Covered_At_75x_PCT="";
            Bases_Covered_At_100x_PCT="";

            chr1_Norm_Cov=""; chr2_Norm_Cov=""; chr3_Norm_Cov=""; chr4_Norm_Cov=""; chr5_Norm_Cov="";
            chr6_Norm_Cov=""; chr7_Norm_Cov=""; chr8_Norm_Cov=""; chr9_Norm_Cov=""; chr10_Norm_Cov="";
            chr11_Norm_Cov=""; chr12_Norm_Cov=""; chr13_Norm_Cov=""; chr14_Norm_Cov=""; chr15_Norm_Cov="";
            chr16_Norm_Cov=""; chr17_Norm_Cov=""; chr18_Norm_Cov=""; chr19_Norm_Cov=""; chr20_Norm_Cov="";
            chr21_Norm_Cov=""; chr22_Norm_Cov=""; chrX_Norm_Cov=""; chrY_Norm_Cov=""; chrM_Norm_Cov="";

            if [ -f "$TARGETCOVERAGE" ]; then

              MEAN_COVERAGE=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="Total"{print $0}' | awk -F'\t' '{printf "%0.1f",$9}');

              Bases_Covered_At_10x_PCT=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="Total"{print $0}' | awk -F'\t' '{printf "%0.1f",$14}');
              Bases_Covered_At_25x_PCT=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="Total"{print $0}' | awk -F'\t' '{printf "%0.1f",$16}');
              Bases_Covered_At_50x_PCT=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="Total"{print $0}' | awk -F'\t' '{printf "%0.1f",$17}');
              Bases_Covered_At_75x_PCT=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="Total"{print $0}' | awk -F'\t' '{printf "%0.2f",$18}');
              Bases_Covered_At_100x_PCT=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="Total"{print $0}' | awk -F'\t' '{printf "%0.2f",$19}');

              if [ "$MEAN_COVERAGE" != "0.0" ]; then

                if [ "$REF" == "Homo_sapiens.GRCh38" ] || [ "$REF" == "Homo_sapiens.hg19" ] ; then

                  chr1_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr1"{print $0}' | awk -F'\t'  -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr2_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr2"{print $0}' | awk -F'\t'  -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr3_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr3"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr4_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr4"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr5_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr5"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr6_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr6"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr7_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr7"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr8_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr8"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr9_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr9"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr10_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr10"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr11_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr11"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr12_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr12"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr13_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr13"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr14_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr14"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr15_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr15"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr16_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr16"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr17_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr17"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr18_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr18"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr19_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr19"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr20_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr20"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr21_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr21"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr22_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chr22"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chrX_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chrX"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chrY_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chrY"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chrM_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="chrM"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
            else
                  chr1_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="1"{print $0}' | awk -F'\t'  -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr2_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="2"{print $0}' | awk -F'\t'  -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr3_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="3"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr4_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="4"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr5_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="5"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr6_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="6"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr7_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="7"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr8_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="8"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr9_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="9"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr10_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="10"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr11_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="11"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr12_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="12"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr13_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="13"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr14_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="14"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr15_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="15"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr16_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="16"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr17_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="17"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr18_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="18"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr19_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="19"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr20_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="20"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr21_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="21"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chr22_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="22"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chrX_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="X"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chrY_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="Y"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');
                  chrM_Norm_Cov=$(cat $TARGETCOVERAGE | awk -F'\t' '$1=="MT"{print $0}' | awk -F'\t' -v meancov=$MEAN_COVERAGE '{printf "%0.2f",$9/meancov}');

              fi

              if [[ "$LIB_TYPE" == "PCR-free" || "$LIB_TYPE" == "PCR-enriched" || "$LIB_TYPE" == "WGBS" || "$LIB_TYPE" == "10x Genomics Linked Reads gDNA" ]] && [ "$POOLING_TYPE" != "Capture" ]; then
                if [ "$(echo $chrX_Norm_Cov'>'0.8 | bc -l)" == "1" ]; then
                  DETECTEDSEX="F";
                else
                  if [ "$(echo $chrY_Norm_Cov'>'0.25 | bc -l)" == "1" ]; then
                      DETECTEDSEX="M";
                  fi
                fi
                if [ "$SEX" == "" ] || [ "$SEX" == "N/A" ]; then
                  :
                else
                  if [ "$DETECTEDSEX" == "$(echo "$SEX" | cut -c 1)" ]; then
                      SEXMATCH=True
                  else
                      SEXMATCH=False
                  fi
                fi
              fi
            fi

            fi
            ONBAIT=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.onTarget.txt
            Aligned_Bases_On_Target_PCT="";
            On_Bait_Bases_from_On_Target_Bases="";
            if [ -f "$ONBAIT" ]; then
                Aligned_Bases_On_Target_PCT=$(cat $ONBAIT | grep -v '^#' | grep -A1 BAIT_SET | tail -n+2 | awk '{printf "%0.3f",$18*100}');
                On_Bait_Bases_from_On_Target_Bases=$(cat $ONBAIT | grep -v '^#' | grep -A1 BAIT_SET | tail -n+2 | awk '{printf "%0.3f",$20*100}');
            fi
            BAMID=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.verifyBamId.tsv
            FREEMIX_SNP="";
            FREEMIX_VALUE="";
            if [ -f "$BAMID" ]; then
                FREEMIX_SNP=$(cat $BAMID | grep -v '^#' | grep -A1 FREEMIX | tail -n+2 | awk '{printf "%i",$3}');
                FREEMIX_VALUE=$(cat $BAMID | grep -v '^#' | grep -A1 FREEMIX | tail -n+2 | awk '{printf "%0.5f",$6}');
            fi

            ALIGNMETRICSTSV=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics.tsv

            # head -n 1 $ALIGNMETRICSTSV | tr '\t' '\n' | tr ' ' '_' | sed "s/5'/fiveprime/g" | sed "s/3'/threeprime/g" | tr -d '.' | sed 's/%/pct/g' | tr '\n' '~' | sed 's/~/ RNA_/g' | tr '[:lower:]' '[:upper:]' | tr ' ' '\n'

            RNA_SAMPLE=""; RNA_NOTE=""; RNA_END_2_MAPPING_RATE=""; RNA_CHIMERIC_PAIRS=""; RNA_INTRAGENIC_RATE=""; RNA_NUM_GAPS=""; RNA_EXONIC_RATE=""; RNA_MAPPING_RATE=""; RNA_FIVEPRIME_NORM=""; RNA_GENES_DETECTED=""; RNA_UNIQUE_RATE_OF_MAPPED=""; RNA_THREEPRIME_NORM=""; RNA_READ_LENGTH=""; RNA_MEAN_PER_BASE_COV=""; RNA_END_1_MISMATCH_RATE=""; RNA_FRAGMENT_LENGTH_STDDEV=""; RNA_ESTIMATED_LIBRARY_SIZE=""; RNA_MAPPED=""; RNA_INTERGENIC_RATE=""; RNA_TOTAL_PURITY_FILTERED_READS_SEQUENCED=""; RNA_RRNA=""; RNA_FAILED_VENDOR_QC_CHECK=""; RNA_MEAN_CV=""; RNA_TRANSCRIPTS_DETECTED=""; RNA_MAPPED_PAIRS=""; RNA_CUMUL_GAP_LENGTH=""; RNA_GAP_PCT=""; RNA_UNPAIRED_READS=""; RNA_INTRONIC_RATE=""; RNA_MAPPED_UNIQUE_RATE_OF_TOTAL=""; RNA_EXPRESSION_PROFILING_EFFICIENCY=""; RNA_MAPPED_UNIQUE=""; RNA_END_2_MISMATCH_RATE=""; RNA_END_2_ANTISENSE=""; RNA_ALTERNATIVE_ALIGMENTS=""; RNA_END_2_SENSE=""; RNA_FRAGMENT_LENGTH_MEAN=""; RNA_END_1_ANTISENSE=""; RNA_SPLIT_READS=""; RNA_BASE_MISMATCH_RATE=""; RNA_END_1_SENSE=""; RNA_END_1_PCT_SENSE=""; RNA_RRNA_RATE=""; RNA_END_1_MAPPING_RATE=""; RNA_NO_COVERED_FIVEPRIME=""; RNA_DUPLICATION_RATE_OF_MAPPED=""; RNA_END_2_PCT_SENSE="";

            if [ -f "$ALIGNMETRICSTSV" ]; then
                 IFS='|' read RNA_SAMPLE RNA_NOTE RNA_END_2_MAPPING_RATE RNA_CHIMERIC_PAIRS RNA_INTRAGENIC_RATE RNA_NUM_GAPS RNA_EXONIC_RATE RNA_MAPPING_RATE RNA_FIVEPRIME_NORM RNA_GENES_DETECTED RNA_UNIQUE_RATE_OF_MAPPED RNA_THREEPRIME_NORM RNA_READ_LENGTH RNA_MEAN_PER_BASE_COV RNA_END_1_MISMATCH_RATE RNA_FRAGMENT_LENGTH_STDDEV RNA_ESTIMATED_LIBRARY_SIZE RNA_MAPPED RNA_INTERGENIC_RATE RNA_TOTAL_PURITY_FILTERED_READS_SEQUENCED RNA_RRNA RNA_FAILED_VENDOR_QC_CHECK RNA_MEAN_CV RNA_TRANSCRIPTS_DETECTED RNA_MAPPED_PAIRS RNA_CUMUL_GAP_LENGTH RNA_GAP_PCT RNA_UNPAIRED_READS RNA_INTRONIC_RATE RNA_MAPPED_UNIQUE_RATE_OF_TOTAL RNA_EXPRESSION_PROFILING_EFFICIENCY RNA_MAPPED_UNIQUE RNA_END_2_MISMATCH_RATE RNA_END_2_ANTISENSE RNA_ALTERNATIVE_ALIGMENTS RNA_END_2_SENSE RNA_FRAGMENT_LENGTH_MEAN RNA_END_1_ANTISENSE RNA_SPLIT_READS RNA_BASE_MISMATCH_RATE RNA_END_1_SENSE RNA_END_1_PCT_SENSE RNA_RRNA_RATE RNA_END_1_MAPPING_RATE RNA_NO_COVERED_FIVEPRIME RNA_DUPLICATION_RATE_OF_MAPPED RNA_END_2_PCT_SENSE <<<$(tail -n+2 "$ALIGNMETRICSTSV" | tr '\t' '|');
            fi

        else

            PF_Reads_Aligned_All=""; PF_Reads_Aligned_All_PCT=""; PF_Reads_Aligned_R1_PCT=""; PF_Reads_Aligned_R2_PCT=""; Chimeras_PCT=""; Adapter_PCT="";
            PF_Reads_Aligned_All_format=""; PF_Reads_Aligned_R2_PCT="";
            MEAN_INSERT_SIZE=""; MEDIAN_INSERT_SIZE=""; STDDEV_INSERT_SIZE="";
            PERCENT_DUPLICATION="";
            MEAN_COVERAGE="";
            Bases_Covered_At_10x_PCT="";
            Bases_Covered_At_25x_PCT="";
            Bases_Covered_At_50x_PCT="";
            Bases_Covered_At_75x_PCT="";
            Bases_Covered_At_100x_PCT="";
            chr1_Norm_Cov=""; chr2_Norm_Cov=""; chr3_Norm_Cov=""; chr4_Norm_Cov=""; chr5_Norm_Cov="";
            chr6_Norm_Cov=""; chr7_Norm_Cov=""; chr8_Norm_Cov=""; chr9_Norm_Cov=""; chr10_Norm_Cov="";
            chr11_Norm_Cov=""; chr12_Norm_Cov=""; chr13_Norm_Cov=""; chr14_Norm_Cov=""; chr15_Norm_Cov="";
            chr16_Norm_Cov=""; chr17_Norm_Cov=""; chr18_Norm_Cov=""; chr19_Norm_Cov=""; chr20_Norm_Cov="";
            chr21_Norm_Cov=""; chr22_Norm_Cov=""; chrX_Norm_Cov=""; chrY_Norm_Cov=""; chrM_Norm_Cov="";
            Aligned_Bases_On_Target_PCT="";
            On_Bait_Bases_from_On_Target_Bases="";
            FREEMIX_SNP="";
            FREEMIX_VALUE="";
            RNA_SAMPLE=""; RNA_NOTE=""; RNA_END_2_MAPPING_RATE=""; RNA_CHIMERIC_PAIRS=""; RNA_INTRAGENIC_RATE=""; RNA_NUM_GAPS=""; RNA_EXONIC_RATE=""; RNA_MAPPING_RATE="";
            RNA_FIVEPRIME_NORM=""; RNA_GENES_DETECTED=""; RNA_UNIQUE_RATE_OF_MAPPED=""; RNA_THREEPRIME_NORM=""; RNA_READ_LENGTH=""; RNA_MEAN_PER_BASE_COV="";
            RNA_END_1_MISMATCH_RATE=""; RNA_FRAGMENT_LENGTH_STDDEV=""; RNA_ESTIMATED_LIBRARY_SIZE=""; RNA_MAPPED=""; RNA_INTERGENIC_RATE="";
            RNA_TOTAL_PURITY_FILTERED_READS_SEQUENCED=""; RNA_RRNA=""; RNA_FAILED_VENDOR_QC_CHECK=""; RNA_MEAN_CV=""; RNA_TRANSCRIPTS_DETECTED=""; RNA_MAPPED_PAIRS="";
            RNA_CUMUL_GAP_LENGTH=""; RNA_GAP_PCT=""; RNA_UNPAIRED_READS=""; RNA_INTRONIC_RATE=""; RNA_MAPPED_UNIQUE_RATE_OF_TOTAL=""; RNA_EXPRESSION_PROFILING_EFFICIENCY="";
            RNA_MAPPED_UNIQUE=""; RNA_END_2_MISMATCH_RATE=""; RNA_END_2_ANTISENSE=""; RNA_ALTERNATIVE_ALIGMENTS=""; RNA_END_2_SENSE=""; RNA_FRAGMENT_LENGTH_MEAN="";
            RNA_END_1_ANTISENSE=""; RNA_SPLIT_READS=""; RNA_BASE_MISMATCH_RATE=""; RNA_END_1_SENSE=""; RNA_END_1_PCT_SENSE=""; RNA_RRNA_RATE=""; RNA_END_1_MAPPING_RATE="";
            RNA_NO_COVERED_FIVEPRIME=""; RNA_DUPLICATION_RATE_OF_MAPPED=""; RNA_END_2_PCT_SENSE="";

        fi

        echo "<tr><td align=\"center\">$LANE</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\">$PROJECT_NAME</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\" nowrap>$SAMPLE_NAME</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\" >$LIB_TYPE</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\" >$INDEX_NAME</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"right\">"$NB_READS_format"</td><td align=\"right\">"$NB_BASES_format"</td>" >> $HTML_REPORT.t0.t1;
        echo "<td align=\"right\">"$AVG_QUAL"</td><td align=\"right\">"$DUPLICATE_RATE"</td>" >> $HTML_REPORT.t0.t1;

        if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
            # fastqc PNG image
            if [ "$NOSKIPCOUNT" -lt "26" ]; then
                FASQCR1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001_fastqc.html
                FASQCR2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001_fastqc.html
                FASQCR3=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001_fastqc.html
                FASQCR4=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001_fastqc.html
                echo "<td>" >> $HTML_REPORT.t0.t1
                addimagebase64QUALpngfromfastqc $FASQCR1 >> $HTML_REPORT.t0.t1
                echo "</td>" >> $HTML_REPORT.t0.t1
                echo "<td>" >> $HTML_REPORT.t0.t1
                addimagebase64QUALpngfromfastqc $FASQCR3 >> $HTML_REPORT.t0.t1
                echo "</td>" >> $HTML_REPORT.t0.t1
                echo "<td>" >> $HTML_REPORT.t0.t1
                addimagebase64QUALpngfromfastqc $FASQCR4 >> $HTML_REPORT.t0.t1
                echo "</td>" >> $HTML_REPORT.t0.t1
                echo "<td>" >> $HTML_REPORT.t0.t1
                addimagebase64QUALpngfromfastqc $FASQCR2 >> $HTML_REPORT.t0.t1
                echo "</td>" >> $HTML_REPORT.t0.t1
            else
                echo "<td></td>" >> $HTML_REPORT.t0.t1
                echo "<td></td>" >> $HTML_REPORT.t0.t1
                echo "<td></td>" >> $HTML_REPORT.t0.t1
                echo "<td></td>" >> $HTML_REPORT.t0.t1
            fi
        fi # PROJECT_ID_FILTER

        str=''
        if [ "$SPECIES_MATCH_R1" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        if [ "$SPECIES_MATCH_R1" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$SPECIES_MATCH_R1</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$SPECIES_MATCH_R2" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        if [ "$SPECIES_MATCH_R2" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$SPECIES_MATCH_R2</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$MATCH" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        if [ "$MATCH" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$MATCH</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$SEXMATCH" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        if [ "$SEXMATCH" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$SEXMATCH</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$SAMPLE_ON_FRACTION" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        if [ "$SAMPLE_ON_FRACTION" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$SAMPLE_ON_FRACTION</td>" >> $HTML_REPORT.t0.t1;

        if [ "$POOLING_TYPE" == "Capture" ] || [ "$POOLING_TYPE" == "Library Pool" ]; then
            echo "<td align=\"center\" nowrap>${ARTIFACT_ID}_${LIB_ID}</td>" >> $HTML_REPORT.t0.t1
        else
            echo "<td align=\"center\" nowrap>$ARTIFACT_ID</td>" >> $HTML_REPORT.t0.t1
        fi

        echo "<td align=\"center\">$PROJECT_ID</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\">$SAMPLE_ID</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\" nowrap>$LIB_ID</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\" nowrap>$CHIPSEQMARK</td>" >> $HTML_REPORT.t0.t1
        echo "<td align=\"center\" nowrap>$POOLING_TYPE</td><td align=\"center\" nowrap>$POOLING_ID</td><td align=\"center\" nowrap>$CAPTURE_KIT_TYPE</td><td align=\"center\">$CAPTURE_NAME</td>" >> $HTML_REPORT.t0.t1

        echo "<td align=\"center\">$SPECIES</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$SPECIES_MATCH_R1" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        #if [ "$SPECIES_MATCH_R1" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$TOP_HIT_R1</td><td align=\"right\">$PERCENT_HIT_R1</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$SPECIES_MATCH_R2" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        #if [ "$SPECIES_MATCH_R2" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$TOP_HIT_R2</td><td align=\"right\">$PERCENT_HIT_R2</td>" >> $HTML_REPORT.t0.t1;

        str=''
        if [ "$MATCH" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        #if [ "$MATCH" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$TOP_DETECT</td><td $str align=\"right\">$TOP_RATE</td><td $str align=\"right\">$PERC_FROM_DETECT</td><td $str align=\"center\">$EXPECTED_SAMPLE_TAG</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$SAMPLE_ON_FRACTION" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        #if [ "$SAMPLE_ON_FRACTION" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"right\">$INDEX_PERCENT</td><td $str align=\"right\"> $POOL_FRACTION</td><td $str align=\"right\">$INDEX_PERCENT_NORM</td>" >> $HTML_REPORT.t0.t1;
        str=''
        if [ "$SEXMATCH" == "False" ]; then str='style="background-color:#ffAAAA;" '; fi
        #if [ "$SEXMATCH" == "True" ]; then str='style="background-color:#66ff66;" '; fi
        echo "<td $str align=\"center\">$SEX</td><td $str align=\"center\">$DETECTEDSEX</td>" >> $HTML_REPORT.t0.t1;

        echo "<td align=\"right\">$RRNA_BLAST_DATABASE_R1</td><td align=\"right\">$RRNA_BLAST_HITS_R1</td><td align=\"right\">$RRNA_BLAST_TOTAL_R1</td><td align=\"right\">$RRNA_BLAST_RATIO_R1</td>" >> $HTML_REPORT.t0.t1;
        echo "<td align=\"right\">$RRNA_BLAST_HITS_R2</td><td align=\"right\">$RRNA_BLAST_TOTAL_R2</td><td align=\"right\">$RRNA_BLAST_RATIO_R2</td>" >> $HTML_REPORT.t0.t1;

        # PhiX # echo "<td></td><td></td>" >> $HTML_REPORT.t0.t1;

        # blast table
        BLAST=${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample/${SAMPLE_NAME}_${LIB_ID}_${LANE}.blast.html
        rm -f $BLAST
        if [ -f "$BLASTR1" ] || [ -f "$BLASTR2" ]; then
          echo "<"'!'"doctype html><html><head><title>${OUT_RUN_ROOT} Lane:${LANE} Project:${PROJECT_ID} Sample:${SAMPLE_NAME} Lib:${LIB_ID} blast</title></head><body>" >> $BLAST
          echo "<h1>blast</h1>" >> $BLAST
          echo "${OUT_RUN_ROOT} Lane:${LANE} Project:${PROJECT_ID} Sample:${SAMPLE_NAME} Lib:${LIB_ID}<br>" >>  $BLAST
          echo "<table><tr>" >> $BLAST
          echo "<td valign=\"top\">" >> $BLAST
          addblasttable $BLASTR1 >> $BLAST
          echo "</td><td valign=\"top\">" >> $BLAST
          addblasttable $BLASTR2 >> $BLAST
          echo "</td>" >> $BLAST
          echo "</tr></table>" >> $BLAST
          echo "</body></html>" >> $BLAST
        fi
        echo "<td align=\"center\">" >> $HTML_REPORT.t0.t1
        if [ "$NOSKIPCOUNT" -lt "26" ]; then
            addbuttonfilelabel $BLAST tables >> $HTML_REPORT.t0.t1
        fi
        echo "</td>" >> $HTML_REPORT.t0.t1
        QCGRAPHDIR=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc

        # qcgraph
        QCGRAPH=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_${LANE}.qc_graph.html
        rm -f  $QCGRAPH
        first=true
        for f in $QCGRAPHDIR/*.png; do
            if [ ! -f "$f" ]; then
                break
            fi
            if ($first); then
                first=false
                echo "<"'!'"doctype html><html><head><title>${OUT_RUN_ROOT} Lane:${LANE} Project:${PROJECT_ID} Sample:${SAMPLE_NAME} Lib:${LIB_ID}</title></head><body>" >> $QCGRAPH
                echo "<h1>qcgraph</h1>" >> $QCGRAPH
                echo "${OUT_RUN_ROOT} Lane:${LANE} Project:${PROJECT_ID} Sample:${SAMPLE_NAME} Lib:${LIB_ID}<br>" >> $QCGRAPH
            fi
            addimage $f >> $QCGRAPH;
        done;
        if [ "$first" == "false" ]; then
            echo "</body></html>" >> $QCGRAPH
        fi
        echo "<td align=\"center\">" >> $HTML_REPORT.t0.t1
        if [ "$NOSKIPCOUNT" -lt "26" ]; then
           addbuttonfilelabel $QCGRAPH "QC" >> $HTML_REPORT.t0.t1
        fi
        echo "</td>" >> $HTML_REPORT.t0.t1
        if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
            # fastqc
            echo "<td align=\"center\" nowrap>" >> $HTML_REPORT.t0.t1
            if [ "$NOSKIPCOUNT" -lt "26" ]; then
                FASQCR1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001_fastqc.html
                addbuttonfilelabel $FASQCR1 "R1" >> $HTML_REPORT.t0.t1
                echo " " >> $HTML_REPORT.t0.t1
                FASQCR2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001_fastqc.html
                addbuttonfilelabel $FASQCR2 "R2" >> $HTML_REPORT.t0.t1
                echo " " >> $HTML_REPORT.t0.t1
                FASQCR3=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001_fastqc.html
                addbuttonfilelabel $FASQCR3 "I1" >> $HTML_REPORT.t0.t1
                echo " " >> $HTML_REPORT.t0.t1
                FASQCR4=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001_fastqc.html
                addbuttonfilelabel $FASQCR4 "I2" >> $HTML_REPORT.t0.t1
                echo " " >> $HTML_REPORT.t0.t1
            fi
            echo "</td>" >> $HTML_REPORT.t0.t1
        fi # PROJECT_ID_FILTER
        echo "</tr>" >> $HTML_REPORT.t0.t1

        if [ "$REF" != "" ]; then

            echo "<tr><td align=\"center\">$LANE</td>" >> $HTML_REPORT.t0.t2
            echo "<td align=\"center\" nowrap>$PROJECT_NAME</td>" >> $HTML_REPORT.t0.t2
            echo "<td align=\"center\">$PROJECT_ID</td>" >> $HTML_REPORT.t0.t2
            echo "<td align=\"left\" nowrap>$SAMPLE_NAME</td><td align=\"left\" nowrap>$SAMPLE_ID</td><td align=\"center\" nowrap>$LIB_TYPE</td>" >> $HTML_REPORT.t0.t2
            echo "<td align=\"center\" nowrap>$POOLING_TYPE</td><td align=\"center\" nowrap>$POOLING_ID</td><td align=\"left\" nowrap>$CAPTURE_KIT_TYPE</td><td align=\"left\">$CAPTURE_NAME</td>" >> $HTML_REPORT.t0.t2
            echo "<td align=\"center\" nowrap>$LIB_ID</td><td align=\"center\" nowrap>$INDEX_NAME</td>" >> $HTML_REPORT.t0.t2
            echo "<td>$(echo $REF | tr '.' ':' )</td>" >> $HTML_REPORT.t0.t2;
            if [ -f "$BED_FILES" ]; then
                echo "<td>"$(basename "$BED_FILES")"</td>" >> $HTML_REPORT.t0.t2;
            else
                echo "<td></td>" >> $HTML_REPORT.t0.t2;
            fi
            echo "<td align=\"right\">$PF_Reads_Aligned_All_format</td><td align=\"right\">$PF_Reads_Aligned_All_PCT</td><td align=\"right\">$PF_Reads_Aligned_R1_PCT</td><td align=\"right\">$PF_Reads_Aligned_R2_PCT</td><td align=\"right\">$Chimeras_PCT</td><td align=\"right\">$Adapter_PCT</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$MEDIAN_INSERT_SIZE</td><td align=\"right\">$MEAN_INSERT_SIZE</td><td align=\"right\">$STDDEV_INSERT_SIZE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$PERCENT_DUPLICATION</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$MEAN_COVERAGE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$Bases_Covered_At_10x_PCT</td><td align=\"right\">$Bases_Covered_At_25x_PCT</td><td align=\"right\">$Bases_Covered_At_50x_PCT</td><td align=\"right\">$Bases_Covered_At_75x_PCT</td><td align=\"right\">$Bases_Covered_At_100x_PCT</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$Aligned_Bases_On_Target_PCT</td><td align=\"right\">$On_Bait_Bases_from_On_Target_Bases</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$FREEMIX_SNP</td><td align=\"right\">$FREEMIX_VALUE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr1_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr2_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr3_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr4_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr5_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr6_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr7_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr8_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr9_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr10_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr11_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr12_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr13_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr14_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr15_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr16_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr17_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr18_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr19_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr20_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr21_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chr22_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chrX_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chrY_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$chrM_Norm_Cov</td>" >> $HTML_REPORT.t0.t2;

            echo "<td align=\"right\">$RNA_INTRAGENIC_RATE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_UNIQUE_RATE_OF_MAPPED</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_INTERGENIC_RATE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_TRANSCRIPTS_DETECTED</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_INTRONIC_RATE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_MAPPED_UNIQUE_RATE_OF_TOTAL</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_DUPLICATION_RATE_OF_MAPPED</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_EXPRESSION_PROFILING_EFFICIENCY</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_END_1_PCT_SENSE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_END_2_PCT_SENSE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_ESTIMATED_LIBRARY_SIZE</td>" >> $HTML_REPORT.t0.t2;
            echo "<td align=\"right\">$RNA_RRNA_RATE</td>" >> $HTML_REPORT.t0.t2;

            if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then
                # alignmetrics
                ALIGNMETRICSDIR=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}
                ALIGNMETRICSHTML=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.align_metrics.html
                rm -f $ALIGNMETRICSHTML
                first=true
                for f in $(ls $ALIGNMETRICSDIR/*sorted.metrics* $ALIGNMETRICSDIR/*sorted.dup.metrics* 2> /dev/null); do
                    if [ ! -f "$f" ]; then
                        break
                    fi
                    if ($first); then
                       first=false
                       echo "<"'!'"doctype html><html><head><title>${OUT_RUN_ROOT} Lane:${LANE} Project:${PROJECT_ID} Sample:${SAMPLE_NAME} Lib:${LIB_ID} align metrics</title>" >> $ALIGNMETRICSHTML
                       echo "<script type=\"text/javascript\">" >> $ALIGNMETRICSHTML
                       echo "function popBase64(base64URL){" >> $ALIGNMETRICSHTML
                       echo "    var win = window.open();" >> $ALIGNMETRICSHTML
                       echo "    win.document.write('<iframe src=\"' + base64URL  + '\" frameborder=\"0\" style=\"border:0; top:0px; left:0px; bottom:0px; right:0px; width:100%; height:100%;\" allowfullscreen></iframe>');"  >> $ALIGNMETRICSHTML
                       echo "    win.document.close();" >> $ALIGNMETRICSHTML
                       echo "}" >> $ALIGNMETRICSHTML
                       echo "</script>" >> $ALIGNMETRICSHTML
                       echo "</head><body>" >> $ALIGNMETRICSHTML
                       echo "<h1>align metrics</h1>" >> $ALIGNMETRICSHTML
                       echo "${OUT_RUN_ROOT} Lane:${LANE} Project:${PROJECT_ID} Sample:${SAMPLE_NAME} Lib:${LIB_ID} align metrics<br>" >> $ALIGNMETRICSHTML
                    fi
                    addlinkedfile $f >> $ALIGNMETRICSHTML;
                    echo "<br>" >> $ALIGNMETRICSHTML;
                done;
                if [ "$first" == "false" ]; then
                  echo "</body></html>" >> $ALIGNMETRICSHTML
                fi
                echo "<td align=\"center\">" >> $HTML_REPORT.t0.t2
                if [ "$NOSKIPCOUNT" -lt "26" ]; then
                    addbuttonfilelabel $ALIGNMETRICSHTML "files" >> $HTML_REPORT.t0.t2
                fi
                echo "</td>" >> $HTML_REPORT.t0.t2

            fi # PROJECT_ID_FILTER

            echo "</tr>" >> $HTML_REPORT.t0.t2

        fi

        if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then

            if [ "$DATA_TO_KEEP" == "fastq" ] || [ "$REF" == "" ] || [ "$POOLING_TYPE" == "Capture" ]; then
                READ_DIR=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID};
                READ1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz;
                READ2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz;
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                    DATA_DIRECTORY="$(clarityhelper $READ_DIR),${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz,${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz,";
                    MD5=",$(cat $READ1.md5 2>/dev/null | awk '{print $1}' | tr -d '\n'),$(cat $READ2.md5 2>/dev/null |  awk '{print $1}' | tr -d '\n'),"
                    FILE_SIZES=",$(ls -l $READ1 2>/dev/null | cut -d ' ' -f5),$(ls -l $READ2 2>/dev/null |  cut -d ' ' -f5),"
                else
                    DATA_DIRECTORY="$(clarityhelper $READ_DIR),${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz,,";
                    MD5=",$(cat $READ1.md5 2>/dev/null |  awk '{print $1}' | tr -d '\n'),,"
                    FILE_SIZES=",$(ls -l $READ1 2>/dev/null | cut -d ' ' -f5),,"
                fi
            else
                BAM_DIR=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE};
                BAM=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam;
                BAI=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bai;
                DATA_DIRECTORY="$(clarityhelper $BAM_DIR),,,${SAMPLE_NAME}_${LIB_ID}.sorted.bam";
                MD5=",,,$(cat $BAM.md5 2>/dev/null |  awk '{print $1}' | tr -d '\n')"
                FILE_SIZES=",,,$(ls -l $BAM 2>/dev/null | cut -d ' ' -f5)"
            fi

            READSETSIZE=$(echo "$FILE_SIZES" | tr ',' '\n'  | grep -v "^$" | awk '{sum+=$1} END {print sum}');

            if [ ! -f "$OUTPUT_DIR/job_output/copyjob/start" ]; then


                if [ -f "$BED_FILES" ]; then
                    VAL=$(basename "$BED_FILES")
                else
                    VAL=""
                fi

                printf "${ARTIFACT_ID}\t${ARTIFACT_ID}_${LIB_ID}\t0\t$POOLING_TYPE\t\
$PROJECT_NAME\t$PROJECT_ID\t$SAMPLE_NAME\t$SAMPLE_ID\t$LIB_TYPE\t$LIB_ID\t$CHIPSEQMARK\t$LIBRARY_KIT_NAME\t$LIBRARY_STRANDEDNESS\t\
$MASK\t$FINALMASK\t$NUM_MISMATCH\t$POOLING_ID\t$CAPTURE_NAME\t$CAPTURE_KIT_TYPE\t$CAPTURE_BAIT_VERSION\t\
$POOL_ON_FRACTION\t$SAMPLE_NAME.$LIB_ID.$RUN_ID.$LANE\t\
$DATA_DIRECTORY\t$MD5\t$FILE_SIZES\t$READSETSIZE\t\
$FCID\t$RUN_ID\t$LANE\t$MASTER_RUN_COUNT\t$OUT_RUN_ROOT-$SEQ_TYPE\t$FC_MODE\t\
$RUN_TYPE\t$INDEX_TYPE\t33\t$NB_READS\t$NB_BASES\t$AVG_QUAL\t$DUPLICATE_RATE\t\
$SPECIES\t$TOP_HIT_R1\t$PERCENT_HIT_R1\t$TOP_HIT_R2\t$PERCENT_HIT_R2\t$SPECIES_MATCH_R1\t$SPECIES_MATCH_R2\t\
$TOP_DETECT\t$TOP_RATE\t$PERC_FROM_DETECT\t$EXPECTED_SAMPLE_TAG\t$MATCH\t\
$INDEX_PERCENT\t$INDEX_PERCENT_NORM\t$POOL_FRACTION\t$SAMPLE_ON_FRACTION\t\
$SEX\t$DETECTEDSEX\t$SEXMATCH\t\
$RRNA_BLAST_DATABASE_R1\t$RRNA_BLAST_HITS_R1\t$RRNA_BLAST_TOTAL_R1\t$RRNA_BLAST_RATIO_R1\t$RRNA_BLAST_HITS_R2\t$RRNA_BLAST_TOTAL_R2\t$RRNA_BLAST_RATIO_R2\t\
$ADAPTERi7\t$ADAPTERi5\t\
$(echo $REF | tr '.' ':' )\t$VAL\t\
$PF_Reads_Aligned_All\t$PF_Reads_Aligned_All_PCT\t$PF_Reads_Aligned_R1_PCT\t$PF_Reads_Aligned_R2_PCT\t$Chimeras_PCT\t$Adapter_PCT\t\
$MEDIAN_INSERT_SIZE\t$MEAN_INSERT_SIZE\t$STDDEV_INSERT_SIZE\t$PERCENT_DUPLICATION\t$MEAN_COVERAGE\t\
$Bases_Covered_At_10x_PCT\t$Bases_Covered_At_25x_PCT\t$Bases_Covered_At_50x_PCT\t$Bases_Covered_At_75x_PCT\t$Bases_Covered_At_100x_PCT\t\
$Aligned_Bases_On_Target_PCT\t$On_Bait_Bases_from_On_Target_Bases\t$FREEMIX_SNP\t$FREEMIX_VALUE\t\
$chr1_Norm_Cov\t$chr2_Norm_Cov\t$chr3_Norm_Cov\t$chr4_Norm_Cov\t$chr5_Norm_Cov\t$chr6_Norm_Cov\t\
$chr7_Norm_Cov\t$chr8_Norm_Cov\t$chr9_Norm_Cov\t$chr10_Norm_Cov\t$chr11_Norm_Cov\t\
$chr12_Norm_Cov\t$chr13_Norm_Cov\t$chr14_Norm_Cov\t$chr15_Norm_Cov\t$chr16_Norm_Cov\t$chr17_Norm_Cov\t\
$chr18_Norm_Cov\t$chr19_Norm_Cov\t$chr20_Norm_Cov\t$chr21_Norm_Cov\t$chr22_Norm_Cov\t$chrX_Norm_Cov\t$chrY_Norm_Cov\t$chrM_Norm_Cov\t\
$RNA_INTRAGENIC_RATE\t$RNA_UNIQUE_RATE_OF_MAPPED\t$RNA_INTERGENIC_RATE\t$RNA_TRANSCRIPTS_DETECTED\t$RNA_INTRONIC_RATE\t$RNA_MAPPED_UNIQUE_RATE_OF_TOTAL\t\
$RNA_DUPLICATION_RATE_OF_MAPPED\t$RNA_EXPRESSION_PROFILING_EFFICIENCY\t$RNA_END_1_PCT_SENSE\t$RNA_END_2_PCT_SENSE\t$RNA_ESTIMATED_LIBRARY_SIZE\t$RNA_RRNA_RATE\t\
$COMMENT\t$EXTERNAL_PROJECT_CODE\t$BILLING_STRING\t$INVOICE_FRACTION\t$PIPELINE_VERSION\n" >> $CLARITY_POOLDATA.t0

                printf "$OUT_RUN_ROOT-$SEQ_TYPE,$RUN_ID,$LANE,$RUN_TYPE,$PROJECT_ID,$PROJECT_NAME,$SAMPLE_NAME,$SAMPLE_ID,$LIB_TYPE,$LIB_ID,$INDEX_NAME,$ARTIFACT_ID," >> $MAIN_CSV.t0
                printf "$NB_READS,$NB_BASES,$AVG_QUAL,$DUPLICATE_RATE," >> $MAIN_CSV.t0
                printf "$TOP_HIT_R1,$PERCENT_HIT_R1," >> $MAIN_CSV.t0;
                printf "$TOP_HIT_R2,$PERCENT_HIT_R2," >> $MAIN_CSV.t0;
                printf "$TOP_DETECT,$TOP_RATE,$PERC_FROM_DETECT,$EXPECTED_SAMPLE_TAG,$MATCH," >> $MAIN_CSV.t0;
                printf "$INDEX_PERCENT,$INDEX_PERCENT_NORM," >> $MAIN_CSV.t0;
                printf "$ADAPTERi7,$ADAPTERi5" >> $MAIN_CSV.t0; # last data don't use comma
                printf "\n" >> $MAIN_CSV.t0; # last data add newline

                printf "1\tUDF\t$ARTIFACT_ID\tFlowcell ID\t$FCID\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tRun ID\t$RUN_ID\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tRunType\t$RUN_TYPE\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tIndex Type\t$INDEX_TYPE\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tQualityOffset\t33\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tRun Count\t$MASTER_RUN_COUNT\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tRun Folder Name\t$RUN_DIR\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tProcessing Folder Name\t$OUT_RUN_ROOT-$SEQ_TYPE\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tFlowcell Lane\t$LANE\n" >> $CLARITY_UDFS.t0;
                printf "1\tUDF\t$ARTIFACT_ID\tProcessing version\t$PIPELINE_VERSION\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" != "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPooling Type\t$POOLING_TYPE\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tLibrary Type\t$LIB_TYPE\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tLibrary ID\t$LIB_ID\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tLibrary Kit Name\t$LIBRARY_KIT_NAME\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tLibrary Strandedness\t$LIBRARY_STRANDEDNESS\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tOriginal Run Cycles\t$MASK\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tDemultiplexing Cycles\t$FINALMASK\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tMismatch Setting\t$NUM_MISMATCH\n" >> $CLARITY_UDFS.t0;

                # [ "$POOLING_TYPE" != "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPool ID\t$POOLING_ID\n" >> $CLARITY_UDFS.t0;
                # [ "$POOLING_TYPE" != "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPool Name\t$CAPTURE_NAME\n" >> $CLARITY_UDFS.t0;
                # [ "$POOLING_TYPE" != "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tCapture Type\t$CAPTURE_KIT_TYPE\n" >> $CLARITY_UDFS.t0;
                # [ "$POOLING_TYPE" != "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tCapture Bait\t$CAPTURE_BAIT_VERSION\n" >> $CLARITY_UDFS.t0;
                # [ "$POOLING_TYPE" != "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPool on Fraction\t\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tRead Set ID\t$SAMPLE_NAME.$LIB_ID.$RUN_ID.$LANE\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tMD5\t$MD5\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tFile Sizes\t$FILE_SIZES\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tRead Set Size\t$READSETSIZE\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tFlowcell Type\t$FC_MODE\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tClusters\t$NB_READS\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tBases\t$NB_BASES\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tAvg. Qual\t$AVG_QUAL\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tDup. Rate (%%)\t$DUPLICATE_RATE\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tSubmitted Species\t$SPECIES\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR1 Top Blast Hit Name\t$TOP_HIT_R1\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR1 Top Blast Hit Rate (%%)\t$PERCENT_HIT_R1\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR2 Top Blast Hit Name\t$TOP_HIT_R2\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR2 Top Blast Hit Rate (%%)\t$PERCENT_HIT_R2\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tSpecies Match R1\t$SPECIES_MATCH_R1\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tSpecies Match R2\t$SPECIES_MATCH_R2\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tTop Sample Tag Name\t$TOP_DETECT\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tTop Sample Tag Rate from Total (%%)\t$TOP_RATE\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tTop Sample Tag Rate from All Detected (%%)\t$PERC_FROM_DETECT\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tExpected Sample Tag Name\t$EXPECTED_SAMPLE_TAG\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tTop Sample Tag Name Match\t$MATCH\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tClusters on Index in Lane (%%)\t$INDEX_PERCENT\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tClusters on Index in Lane from Target (%%)\t$INDEX_PERCENT_NORM\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tExpected Lane Fraction\t$POOL_FRACTION\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tSample On Fraction\t$SAMPLE_ON_FRACTION\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tSex\t$SEX\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tDetected Sex\t$DETECTEDSEX\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tSubmitted Sex Match\t$SEXMATCH\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\ti7 Adapter\t$ADAPTERi7\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\ti5 Adapter\t$ADAPTERi5\n" >> $CLARITY_UDFS.t0;

                # [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR1 PhiX Rate from Total (%%)\t$\n" >> $CLARITY_UDFS.t0;
                # [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR2 PhiX Rate from Total (%%)\t$\n" >> $CLARITY_UDFS.t0;

                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\trRNA BLAST Database\t$RRNA_BLAST_DATABASE_R1\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR1 rRNA BLAST Hits\t$RRNA_BLAST_HITS_R1\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR1 rRNA BLAST Total\t$RRNA_BLAST_TOTAL_R1\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR1 rRNA BLAST Ratio\t$RRNA_BLAST_RATIO_R1\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR2 rRNA BLAST Hits\t$RRNA_BLAST_HITS_R2\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR2 rRNA BLAST Total\t$RRNA_BLAST_TOTAL_R2\n" >> $CLARITY_UDFS.t0;
                [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tR2 rRNA BLAST Ratio\t$RRNA_BLAST_RATIO_R2\n" >> $CLARITY_UDFS.t0;


                if [ "$REF" != "" ]; then
                    printf "$OUT_RUN_ROOT-$SEQ_TYPE,$RUN_ID,$LANE,$RUN_TYPE,$PROJECT_ID,$PROJECT_NAME,$SAMPLE_NAME,$SAMPLE_ID,$LIB_TYPE,$LIB_ID,$INDEX_NAME,$ARTIFACT_ID," >> $ALIGN_BWAMEM_CSV.t0
                    printf "$NB_READS,$NB_BASES,$AVG_QUAL,$DUPLICATE_RATE," >> $ALIGN_BWAMEM_CSV.t0
                    printf "$TOP_HIT_R1,$PERCENT_HIT_R1," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$TOP_HIT_R2,$PERCENT_HIT_R2," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$TOP_DETECT,$TOP_RATE,$PERC_FROM_DETECT,$EXPECTED_SAMPLE_TAG,$MATCH," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$INDEX_PERCENT,$INDEX_PERCENT_NORM," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$ADAPTERi7,$ADAPTERi5," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$(echo $REF | tr '.' ':' )," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$BED_FILES," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$PF_Reads_Aligned_All,$PF_Reads_Aligned_All_PCT,$PF_Reads_Aligned_R1_PCT,$PF_Reads_Aligned_R2_PCT,$Chimeras_PCT,$Adapter_PCT," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$MEDIAN_INSERT_SIZE,$MEAN_INSERT_SIZE,$STDDEV_INSERT_SIZE," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$PERCENT_DUPLICATION," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$MEAN_COVERAGE," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$Bases_Covered_At_10x_PCT,$Bases_Covered_At_25x_PCT,$Bases_Covered_At_50x_PCT,$Bases_Covered_At_75x_PCT,$Bases_Covered_At_100x_PCT," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$Aligned_Bases_On_Target_PCT,$On_Bait_Bases_from_On_Target_Bases," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$FREEMIX_SNP,$FREEMIX_VALUE," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr1_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr2_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr3_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr4_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr5_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr6_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr7_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr8_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr9_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr10_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr11_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr12_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr13_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr14_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr15_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr16_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr17_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr18_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr19_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr20_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr21_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chr22_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chrX_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chrY_Norm_Cov," >> $ALIGN_BWAMEM_CSV.t0;
                    printf "$chrM_Norm_Cov" >> $ALIGN_BWAMEM_CSV.t0; # last data don't use comma
                    printf "\n" >> $ALIGN_BWAMEM_CSV.t0; # last data add newline

                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tReference\t$(echo $REF | tr '.' ':' )\n" >> $CLARITY_UDFS.t0;
                    if [ -f "$BED_FILES" ]; then
                        [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tBed\t"$(basename "$BED_FILES")"\n" >> $CLARITY_UDFS.t0;
                    fi
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPF Reads Aligned All\t$PF_Reads_Aligned_All\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPF Reads Aligned All (%%)\t$PF_Reads_Aligned_All_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPF Reads Aligned R1 (%%)\t$PF_Reads_Aligned_R1_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tPF Reads Aligned R2 (%%)\t$PF_Reads_Aligned_R2_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tChimeras (%%)\t$Chimeras_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tAdapter (%%)\t$Adapter_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tMapped Insert Size (median)\t$MEDIAN_INSERT_SIZE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tMapped Insert Size (mean)\t$MEAN_INSERT_SIZE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tMapped Insert Size (std. dev.)\t$STDDEV_INSERT_SIZE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tAligned Dup. Rate (%%)\t$PERCENT_DUPLICATION\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tMean Coverage\t$MEAN_COVERAGE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tBases Covered at 10x (%%)\t$Bases_Covered_At_10x_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tBases Covered at 25x (%%)\t$Bases_Covered_At_25x_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tBases Covered at 50x (%%)\t$Bases_Covered_At_50x_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tBases Covered at 75x (%%)\t$Bases_Covered_At_75x_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tBases Covered at 100x (%%)\t$Bases_Covered_At_100x_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tAligned Bases On Target (%%)\t$Aligned_Bases_On_Target_PCT\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tOn Bait Bases from On Target Bases (%%)\t$On_Bait_Bases_from_On_Target_Bases\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tFreemix Number of SNP\t$FREEMIX_SNP\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tFreemix Value\t$FREEMIX_VALUE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr1 Normalized Coverage\t$chr1_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr2 Normalized Coverage\t$chr2_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr3 Normalized Coverage\t$chr3_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr4 Normalized Coverage\t$chr4_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr5 Normalized Coverage\t$chr5_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr6 Normalized Coverage\t$chr6_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr7 Normalized Coverage\t$chr7_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr8 Normalized Coverage\t$chr8_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr9 Normalized Coverage\t$chr9_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr10 Normalized Coverage\t$chr10_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr11 Normalized Coverage\t$chr11_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr12 Normalized Coverage\t$chr12_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr13 Normalized Coverage\t$chr13_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr14 Normalized Coverage\t$chr14_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr15 Normalized Coverage\t$chr15_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr16 Normalized Coverage\t$chr16_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr17 Normalized Coverage\t$chr17_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr18 Normalized Coverage\t$chr18_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr19 Normalized Coverage\t$chr19_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr20 Normalized Coverage\t$chr20_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr21 Normalized Coverage\t$chr21_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchr22 Normalized Coverage\t$chr22_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchrX Normalized Coverage\t$chrX_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchrY Normalized Coverage\t$chrY_Norm_Cov\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tchrM Normalized Coverage\t$chrM_Norm_Cov\n" >> $CLARITY_UDFS.t0;

                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tIntragenic Rate\t$RNA_INTRAGENIC_RATE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tUnique Rate of Mapped\t$RNA_UNIQUE_RATE_OF_MAPPED\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tIntergenic Rate\t$RNA_INTERGENIC_RATE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tTranscripts Detected\t$RNA_TRANSCRIPTS_DETECTED\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tIntronic Rate\t$RNA_INTRONIC_RATE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tMapped Unique Rate of Total\t$RNA_MAPPED_UNIQUE_RATE_OF_TOTAL\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tDuplication Rate of Mapped\t$RNA_DUPLICATION_RATE_OF_MAPPED\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tExpression Profiling Efficiency\t$RNA_EXPRESSION_PROFILING_EFFICIENCY\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tEnd 1 %% Sense\t$RNA_END_1_PCT_SENSE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tEnd 2 %% Sense\t$RNA_END_2_PCT_SENSE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tEstimated Library Size\t$RNA_ESTIMATED_LIBRARY_SIZE\n" >> $CLARITY_UDFS.t0;
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\trRNA rate\t$RNA_RRNA_RATE\n" >> $CLARITY_UDFS.t0;

                fi

                if [ "$DATA_TO_KEEP" == "fastq" ] || [ "$REF" == "" ] || [ "$POOLING_TYPE" == "Capture" ]; then
                    READ_DIR=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}
                    READ1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
                    READ2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
                    if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                        [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tData Directory\t$(clarityhelper $READ_DIR),${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz,${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz,\n" >> $CLARITY_UDFS.t0;
                    else
                        [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tData Directory\t$(clarityhelper $READ_DIR),${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz,,\n" >> $CLARITY_UDFS.t0;
                    fi
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $READ_DIR)\n" >> $FTP_FILES.t0
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $READ1)\n" >> $FTP_FILES.t0
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $READ1.md5)\n" >> $FTP_FILES.t0
                    if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                        printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $READ2)\n" >> $FTP_FILES.t0
                        printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $READ2.md5)\n" >> $FTP_FILES.t0
                    fi
                else
                    BAM_DIR=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}
                    BAM=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam
                    BAI=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bai
                    [ "$POOLING_TYPE" == "N/A" ] && printf "1\tUDF\t$ARTIFACT_ID\tData Directory\t$(clarityhelper $BAM_DIR),,,${SAMPLE_NAME}_${LIB_ID}.sorted.bam\n" >> $CLARITY_UDFS.t0;
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $BAM_DIR)\n" >> $FTP_FILES.t0
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $BAM)\n" >> $FTP_FILES.t0
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $BAM.md5)\n" >> $FTP_FILES.t0
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $BAI)\n" >> $FTP_FILES.t0
                    printf "$RUN_ID,$PROJECT_ID,$SAMPLE_ID,$(clarityhelper $BAI.md5)\n" >> $FTP_FILES.t0
                fi #  if [ "$DATA_TO_KEEP" == "fastq" ] || [ "$REF" == "" ] || [ "$POOLING_TYPE" == "Capture" ]; then
            fi # if [ ! -f "$OUTPUT_DIR/job_output/copyjob/start" ]; then
        fi # MAIN


        # special counter, leave here
        if [[ "$INDEX_NAME" == SI-* ]]; then
           let COUNT=${COUNT}+3
        fi

    done

done


echo "</table>" >> $HTML_REPORT.t0.t1
echo "</table>" >> $HTML_REPORT.t0.t2

cat $HTML_REPORT.t0.t1 >> $HTML_REPORT.t0;
cat $HTML_REPORT.t0.t2 >> $HTML_REPORT.t0;

rm $HTML_REPORT.t0.t1 $HTML_REPORT.t0.t2

############################
############################
# processing table
############################
############################

if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then

echo "<h1>Processing Status</h1>" >> $HTML_REPORT.t0;

first=true
TABLE=$(

echo "<table class=\"style3\">";

for line in $(echo "$FILE"); do
    if ($first); then
        first=false;
        echo -n "<tr>"
        echo "$line" | awk -F',' '{print "<th>"$1"</th>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<th>"$2"</th>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<th>"$3"</th>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<th>"$4"</th>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<th>"$5"</th>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<th>"$6"</th>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<th>"$7"</th>"}' | tr -d '\n'
        echo -n "</tr>"
    else

        THIS_STEP=$(echo "$line" | awk -F',' '{print $1}')
        DATE=$(echo "$line" | awk -F',' '{print $2}')
        STATUS=$(echo "$line" | awk -F',' '{print $7}')

        if [ -f "$OUTPUT_DIR/job_output/monitor/stop" ]; then
            if [ "$THIS_STEP" == "monitor" ]; then
                STATUS="Successful"; # set to Success since it will exit and not have a chance to update itself
            fi
        fi

        case $STATUS in
        "Idle/Hold")
            # echo -n "<tr bgcolor=\"#20425a\" style=\"color:#ffffff\">"
            echo -n "<tr bgcolor=\"#20425a\">"
            ;;
        "Running")
            echo -n "<tr bgcolor=\"#377ba1\">"
            ;;
        "Successful")
            echo -n "<tr bgcolor=\"#e8d3a6\">"
            ;;
        "Incomplete")
            echo -n "<tr bgcolor=\"#dd3928\">"
            ;;
        esac

        echo "$line" | awk -F',' '{print "<td nowrap>"$1"</td>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<td nowrap>"$2"</td>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<td nowrap>"$3"</td>"}' | tr -d '\n'
        echo "$line" | awk -F',' '{print "<td nowrap>"$4"</td>"}' | tr -d '\n'

        echo -n '<td nowrap>'
        spacer=""
        for line2 in $( echo "$line" | awk -F',' '{print $5}' | tr ' ' '\n'); do
            f1=$( echo "$line2" | awk -F'|' '{print $1}' );
            f2=$( echo "$line2" | awk -F'|' '{print $2}' );
            if [ "$f1" == "-" ]; then f1='&minus;'; fi;
            if [ "$THIS_STEP" == "monitor" ]; then f1='&minus;'; fi;
            if [ -f "$f2" ]; then
                echo -n "$spacer"'<a href="data:text/html;base64,'$(clip200 $f2 | awk '{print $0 "<br>"}' | base64)'" >'"$f1"'</a>';
            else
                echo -n "$spacer$f1";
            fi;
            spacer=', ';
        done
        echo -n '</td>'

        if [ -f "$OUTPUT_DIR/job_output/monitor/stop" ]; then
            if [ "$THIS_STEP" == "monitor" ]; then
                echo "<td nowrap>&minus;</td>" | tr -d '\n';
            else
                echo "$line" | awk -F',' '{print "<td nowrap>"$6"</td>"}' | tr -d '\n';
            fi;
        else
            echo "$line" | awk -F',' '{print "<td nowrap>"$6"</td>"}' | tr -d '\n';
        fi;

        echo -n "<td nowrap>$STATUS</td>"

        echo -n "</tr>"
    fi
    echo ""
done;

echo "</table>";

)

# target="_blank"

echo "$TABLE" >> $HTML_REPORT.t0;

fi

echo "</body></html>" >> $HTML_REPORT.t0

mv $HTML_REPORT.t0 $HTML_REPORT

if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then

    cp $HTML_REPORT $ALLRUNREPORTS;
    cp $HTML_REPORT $FINAL_DIR/;

    cat $CLARITY_FILES.t0 | awk -F'\t' 'length($5)!=0{print $0}' > $CLARITY_FILES.t0.t;
    mv $CLARITY_FILES.t0.t $CLARITY_FILES.t0;
    mv $CLARITY_FILES.t0 $CLARITY_FILES;
    cp $CLARITY_FILES $FINAL_DIR/

fi

if [ "$PROJECT_ID_FILTER" == "MAIN" ]; then

  # NUMBER_LEFT=$(echo "$FILE" | grep -v monitor | grep -v copyjob | grep -c -E 'Running|Idle/Hold')
  NUMBER_LEFT_COPY=0
  IFS=$'\n';
  for line in $(echo "$RUNNING_JOBS"); do
  a=$(echo "$FILE" | grep -v monitor | grep -v copyjob | awk -F',' '{print ","$4","}' | grep -c ",$line,")
    if [ "$a" -gt "0" ]; then
        let NUMBER_LEFT_COPY=$NUMBER_LEFT_COPY+1;
    fi
  done;

fi


done # all projects


if [ ! -f "$OUTPUT_DIR/job_output/copyjob/start" ]; then

    mv $CLARITY_POOLDATA.t0 $CLARITY_POOLDATA

    for ARTIFACT_ID in $(tail -n +2 $CLARITY_POOLDATA | awk -F'\t' '$4!="N/A"{print $1}' | sort -u); do
        head -n 1 $CLARITY_POOLDATA > $CLARITY_POOLDATA.$ARTIFACT_ID;
        cat $CLARITY_POOLDATA | awk -F '\t' '$1=="'$ARTIFACT_ID'"{print $0}' >> $CLARITY_POOLDATA.$ARTIFACT_ID;
        BASE64METADATASTR="data:text/txt;base64,"$(cat $CLARITY_POOLDATA.$ARTIFACT_ID | base64 | tr -d '\n' | tr -d ' ' );
        printf "1\tUDF\t$ARTIFACT_ID\tBASE64METADATA\t$BASE64METADATASTR\n" >> $CLARITY_UDFS.t0;
    done

    cat $CLARITY_UDFS.t0 | awk -F'\t' 'length($5)!=0{print $0}' > $CLARITY_UDFS.t0.t;
    mv $CLARITY_UDFS.t0.t $CLARITY_UDFS.t0;

    head -n 1 $CLARITY_UDFS.t0 > $CLARITY_UDFS
    tail -n +2 $CLARITY_UDFS.t0 | sort -u >> $CLARITY_UDFS;
    rm $CLARITY_UDFS.t0

    mv $FTP_FILES.t0 $FTP_FILES;
    mv $MAIN_CSV.t0 $MAIN_CSV;
    mv $ALIGN_BWAMEM_CSV.t0 $ALIGN_BWAMEM_CSV;

fi

if [ "$NUMBER_LEFT_COPY" == "0" ]; then
  touch $OUTPUT_DIR/job_output/copyjob/start;
fi

}

function aggregate_reports {

# STEP=${FUNCNAME[0]};
# mkdir -p $JOB_OUTPUT_DIR/$STEP
# JOB_NAME=${STEP}.${RUN_ID}
# JOB_DEPENDENCIES=$1
# JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
# JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
# if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; aggregate_reports_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
# JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
# JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

COMMAND=$(cat <<EOF
. ${CODE_DIR}/$(basename $BASH_SOURCE) $MODE && \
aggregate_reports_sub $PROCESS_ID $RUN_DIR $OUTPUT_DIR $SAMPLE_SHEET $FINAL_DIR $TIMESTAMP $YEAR
EOF
)

# echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
# echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;

echo "$COMMAND" | sh

# if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
# else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
# fi
# aggregate_reports_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
# MUGQIC_STATE=\$PIPESTATUS;
# echo MUGQICexitStatus:\$MUGQIC_STATE;
# if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
# exit \$MUGQIC_STATE" | \
# qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=1:00:0 -q $QUEUE -l nodes=1:ppn=1 $DEP | grep "[0-9]")
# echo -e "$aggregate_reports_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST
# stepaccumulator $aggregate_reports_JOB_ID

}

function copyhelper {
    f=$1
    if [ -f "$f" ] || [ -d "$f" ]; then
      echo $f | sed "s|$OUTPUT_DIR/||g" >> ${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist1.${TIMESTAMP}.txt
    else
      echo "$f not found"
    fi
}

function copyhelper_fromrun {
    echo $1 | sed "s|$RUN_DIR/||g" >> ${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist2.${TIMESTAMP}.txt
}

function copysetup {

PROCESS_ID=$1
RUN_DIR=$2
OUTPUT_DIR=$3
SAMPLE_SHEET=$4
FINAL_DIR=$5
TIMESTAMP=$6
YEAR=$7

while(true); do
  if [ -f "$OUTPUT_DIR/job_output/copyjob/start" ]; then
    echo "$OUTPUT_DIR/job_output/copyjob/start exists, start copy job"
    break
  fi
  echo "wait for monitor to give final go"
  sleep 600;
done

ALLPROJECTS=$(readsamplesheet | awk -F, '{print $1}' | sort -u | grep -v '^$' )
ALLLANES=$(readsamplesheet | awk -F, '{print $7}'  | tr '-' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

OVERINDEX1="";OVERINDEX2="";
getcycles $RUN_DIR/RunInfo.xml
parse_run_info_parameters $RUN_DIR
RUN_ID=${INSTRUMENT}_${RUN_NUMBER}
SEQ_TYPE=$(grep "$INSTRUMENT" $INSTRUMENT_LIST | awk -F, '{print $3}')
SEQ_CATEGORY=$(echo $SEQ_TYPE | sed 's/4000//g' | sed 's/2500//g' | sed 's/x//g')
if [ "$READ2CYCLES" == "0" ]; then
    RUN_TYPE=SINGLE_END;
else
    RUN_TYPE=PAIRED_END;
fi
if [ "$INDEX2CYCLES" == "0" ] || [ "$INDEX1CYCLES" == "0" ]; then
    INDEX_TYPE=SINGLE_INDEX;
else
    INDEX_TYPE=DUAL_INDEX;
fi
MASTER_RUN_COUNT="";
if [ "$(echo $EXPERIMENT_NAME | grep -c 'HS')" == "1" ]; then
    MASTER_RUN_COUNT=$(echo $EXPERIMENT_NAME | awk -F'HS' '{print $1}')
fi


rm -f ${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist1.${TIMESTAMP}.txt
rm -f ${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist2.${TIMESTAMP}.txt

copyhelper_fromrun $(ls $RUN_DIR/*unParameters.xml);
copyhelper_fromrun $RUN_DIR/RunInfo.xml;
copyhelper_fromrun $RUN_DIR/InterOp;

if [ "$SEQ_TYPE" == "novaseqx" ]; then
    copyhelper_fromrun $RUN_DIR/RTA.cfg
fi
if [ "$SEQ_TYPE" == "novaseq" ]; then
    copyhelper_fromrun $RUN_DIR/RTA3.cfg
    copyhelper_fromrun $RUN_DIR/Config;
    copyhelper_fromrun $RUN_DIR/Recipe;
fi
if [ "$SEQ_TYPE" == "hiseqx" ]; then
    copyhelper_fromrun $RUN_DIR/RTAConfiguration.xml;
    # copyhelper_fromrun $RUN_DIR/Thumbnail_Images;
    # copyhelper_fromrun $RUN_DIR/Logs;
    copyhelper_fromrun $RUN_DIR/Config;
    copyhelper_fromrun $RUN_DIR/Recipe;
fi
if [ "$SEQ_TYPE" == "hiseq2500" ]; then
    copyhelper_fromrun $RUN_DIR/Config;
    copyhelper_fromrun $RUN_DIR/Recipe;
fi
if [ "$SEQ_TYPE" == "miseq" ]; then
    copyhelper_fromrun $RUN_DIR/Config;
    copyhelper_fromrun $RUN_DIR/Recipe;
fi
if [ "$SEQ_TYPE" == "iSeq" ]; then
    copyhelper_fromrun $RUN_DIR/Config;
    copyhelper_fromrun $RUN_DIR/Recipe;
fi




HTML_REPORT=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.html
# copyhelper $HTML_REPORT

# HTML_REPORT_LABLINK=${OUTPUT_DIR}/${OUT_RUN_ROOT}-html-${SEQ_TYPE}.$(echo $SEQ_TYPE | sed 's/4000//g' | sed 's/2500//g' | sed 's/x//g')-run
# copyhelper $HTML_REPORT_LABLINK

ALLPROJECTS=$(readsamplesheet | awk -F, '{print $1}' | sort -u | grep -v '^$' )
IFS=$'\n'
for PROJECT_ID_FILTER in $ALLPROJECTS; do

    # if [ "$(echo $EXPERIMENT_NAME | grep -c 'HS')" == "1" ]; then
    #     MASTER_RUN_COUNT=$(echo $EXPERIMENT_NAME | awk -F'HS' '{print $1}')
    # fi

    HTML_REPORT=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$PROJECT_ID_FILTER-$SEQ_TYPE-run.html
    copyhelper $HTML_REPORT

    # HTML_REPORT_LABLINK=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$PROJECT_ID_FILTER-html.$SEQ_TYPE-run
    # copyhelper $HTML_REPORT_LABLINK

done

# jobstuff
copyhelper ${OUTPUT_DIR}/job_output

IFS=$'\n'
for LANE in $(echo $ALLLANES | tr ' ' '\n'); do
    # thumbnails
    # if [ -f "$OUTPUT_DIR/job_output/thumb_anim/thumb_anim.${RUN_ID}.${LANE}.done" ]; then
    #   copyhelper ${OUTPUT_DIR}/thumb_anim/L00${LANE}.cycles
    #   copyhelper ${OUTPUT_DIR}/thumb_anim/$SEQ_TYPE-movie-${OUT_RUN_ROOT}-$SEQ_TYPE-L00${LANE}.gif
    # fi
    copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Blast_sample
    copyhelper ${OUTPUT_DIR}/casavasheet.${LANE}.csv
done

IFS=$'\n'
# for PROJECT_ID_FILTER in $ALLPROJECTS; do

for LANE in $(echo $ALLLANES | tr ' ' '\n'); do
    local COUNT=0
    IFS=$'\n'
    for line in $(readsamplesheet); do

	PROJECT_ID=$(echo $line | awk -F, '{print $1}');
	PROJECT_NAME=$(echo $line | awk -F, '{print $2}');
	LIB_ID=$(echo $line | awk -F, '{print $3}');
	SAMPLE_NAME=$(echo $line | awk -F, '{print $4}');
	SAMPLE_ID=$(echo $line | awk -F, '{print $5}');
	INDEX_NAME=$(echo $line | awk -F, '{print $6}');
	LANES=$(echo $line | awk -F, '{print $7}');
	ARTIFACT_IDS=$(echo $line | awk -F, '{print $8}');
	LIB_TYPE=$(echo $line | awk -F, '{print $9}');
	LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
	PROCESSING_TYPE=$(echo $line | awk -F, '{print $11}');
	REF_and_BED=$(echo $line | awk -F, '{print $12}');
	EXPECTED_SAMPLE_TAG=$(echo $line | awk -F, '{print $13}');

        TARGET_CELLS=$(echo $line | awk -F, '{print $14}');
        LIBRARY_METADATA_ID=$(echo $line | awk -F, '{print $15}');
        SPECIES=$(echo $line | awk -F, '{print $16}');
        GENOME_SIZE_MB=$(echo $line | awk -F, '{print $17}');
        SEX=$(echo $line | awk -F, '{print $18}');
        POOL_FRACTIONS=$(echo $line | awk -F, '{print $19}');
        POOLING_TYPES=$(echo $line | awk -F, '{print $20}');
        POOLING_IDS=$(echo $line | awk -F, '{print $21}');
        CAPTURE_NAMES=$(echo $line | awk -F, '{print $22}');
        CAPTURE_REF_BEDS=$(echo $line | awk -F, '{print $23}');
        CAPTURE_METADATA_IDS=$(echo $line | awk -F, '{print $24}');
        ARTIFACTLUIDCLUSTERINGS=$(echo $line | awk -F, '{print $25}');
        LIBRARY_SIZE=$(echo $line | awk -F, '{print $26}');
        LIBRARY_KIT_NAME=$(echo $line | awk -F, '{print $27}');
        CAPTURE_KIT_TYPES=$(echo $line | awk -F, '{print $28}');
        CAPTURE_BAIT_VERSIONS=$(echo $line | awk -F, '{print $29}');
        CHIPSEQMARKS=$(echo $line | awk -F, '{print $30}');

        REF=$(echo "$REF_and_BED" | awk -F';' '{print $1}' | tr ':' '.')
        BED_FILES=$(echo "$REF_and_BED" | awk -F';' '{$1=""; print $0}' | tr ' ' ';' | sed "s|;|;${BED_PATH}/|g" | cut -c 2-)

        LANEPOS=$(echo "$LANES" | tr '-' '\n' | grep "$LANE" -n | awk -F':' '{print $1}');
        ARTIFACT_ID=$(echo "$ARTIFACT_IDS" | cut -d "|" -f $LANEPOS);
        POOL_FRACTION=$(echo "$POOL_FRACTIONS" | cut -d "|" -f $LANEPOS);
        POOLING_TYPE=$(echo "$POOLING_TYPES" | cut -d "|" -f $LANEPOS);
        POOLING_ID=$(echo "$POOLING_IDS" | cut -d "|" -f $LANEPOS);
        CAPTURE_NAME=$(echo "$CAPTURE_NAMES" | cut -d "|" -f $LANEPOS);
        CAPTURE_REF_BED=$(echo "$CAPTURE_REF_BEDS" | cut -d "|" -f $LANEPOS);
        CAPTURE_METADATA_ID=$(echo "$CAPTURE_METADATA_IDS" | cut -d "|" -f $LANEPOS);
        ARTIFACTLUIDCLUSTERING=$(echo "$ARTIFACTLUIDCLUSTERINGS" | cut -d "|" -f $LANEPOS);
        CAPTURE_KIT_TYPE=$(echo "$CAPTURE_KIT_TYPES" | cut -d "|" -f $LANEPOS);
        CAPTURE_BAIT_VERSION=$(echo "$CAPTURE_BAIT_VERSIONS" | cut -d "|" -f $LANEPOS);
        CHIPSEQMARK=$(echo "$CHIPSEQMARKS" | cut -d "|" -f $LANEPOS);

        CAPTUREREF=$(echo "$CAPTURE_REF_BED" | awk -F';' '{print $1}' | tr ':' '.')
        CAPTUREBED_FILES=$(echo "$CAPTURE_REF_BED" | awk -F';' '{$1=""; print $0}' | tr ' ' ';' | sed "s|;|;${BED_PATH}/|g" | cut -c 2-)

        DATA_TO_KEEP=$(grep "^$LIB_TYPE," $LIBRARY_PROTOCOL_LIST | awk -F',' '{print $4}')

        if [ "$(echo $LANES | grep -c $LANE)" == "0" ]; then
            continue
        fi

        let COUNT=${COUNT}+1

        if [[ "$PROCESSING_TYPE" == "default DNA"* ]]; then

                if [ "$DATA_TO_KEEP" == "fastq" ] || [ "$REF" == "" ] || [ "$POOLING_TYPE" == "Capture" ]; then
                   if [ -f "$OUTPUT_DIR/job_output/fastq/fastq.${RUN_ID}.${LANE}.done" ]; then
                      READ1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
                      copyhelper $READ1
                      copyhelper $READ1.md5
                      I1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
                      copyhelper $I1
                      if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                          READ2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
                          copyhelper $READ2
                          copyhelper $READ2.md5
                      fi
                      # if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
                      if [ -f "${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz" ]; then
                        I2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
                        copyhelper $I2
                      fi
                   fi
                fi

                QCGRAPH=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_${LANE}.qc_graph.html
                copyhelper $QCGRAPH

                if [ -f "$OUTPUT_DIR/job_output/align_bwa_mem/align_bwa_mem.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}.done" ]; then
                    if [ "$DATA_TO_KEEP" == "bam" ] && [ "$REF" != "" ] && [ "$POOLING_TYPE" != "Capture" ]; then
                        BAM=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam
                        BAI=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bai
                        copyhelper $BAM
                        copyhelper $BAM.md5
                        copyhelper $BAI
                        copyhelper $BAI.md5
                    fi
                    ALIGNMETRICSDIR=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics.tsv
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.alignment_summary_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.base_distribution_by_cycle_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.base_distribution_by_cycle.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.insert_size_Histogram.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.insert_size_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_by_cycle_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_by_cycle.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_distribution_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_distribution.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.rRNA.tsv
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.rRNA.tsv_short.tsv
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.targetCoverage.txt
                    copyhelper ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.align_metrics.html
                fi

                copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc
                copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                    copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2
                fi
                copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1
                # if [ "$INDEX_TYPE" == "DUAL_INDEX" ] || [ "$LIB_TYPE" == "HaloPlex"]; then
                    copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2
                # fi
                for file in ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.R*/*.pdf \
                            ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.R*/*.summary.tsv \
                            ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/sample_tag.R*/*.sample_tag_stats.csv; do
                    copyhelper $file;
                done

        fi

        if [[ "$PROCESSING_TYPE" == "default RNA"* ]]; then

                if [ "$DATA_TO_KEEP" == "fastq" ] || [ "$REF" == "" ] || [ "$POOLING_TYPE" == "Capture" ]; then
                   if [ -f "$OUTPUT_DIR/job_output/fastq/fastq.${RUN_ID}.${LANE}.done" ]; then
                      READ1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R1_001.fastq.gz
                      copyhelper $READ1
                      copyhelper $READ1.md5
                      I1=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I1_001.fastq.gz
                      copyhelper $I1
                      if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                          READ2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_R2_001.fastq.gz
                          copyhelper $READ2
                          copyhelper $READ2.md5
                      fi
                      # if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
                      if [ -f "${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz" ]; then
                        I2=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_S${COUNT}_L00${LANE}_I2_001.fastq.gz
                        copyhelper $I2
                      fi
                   fi
                fi

                if [ -f "$OUTPUT_DIR/job_output/align_star/align_star.${SAMPLE_NAME}.${LIB_ID}.${RUN_ID}.${LANE}.done" ]; then
                    if [ "$DATA_TO_KEEP" == "bam" ] && [ "$REF" != "" ] && [ "$POOLING_TYPE" != "Capture" ]; then
                        BAM=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bam
                        BAI=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.sorted.bai
                        copyhelper $BAM
                        copyhelper $BAM.md5
                        copyhelper $BAI
                        copyhelper $BAI.md5
                    fi
                    ALIGNMETRICSDIR=${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID} # its a text file
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.bam.sample_file
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.dup.metrics.tsv
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.alignment_summary_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.base_distribution_by_cycle_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.base_distribution_by_cycle.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.insert_size_Histogram.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.insert_size_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_by_cycle_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_by_cycle.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_distribution_metrics
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.quality_distribution.pdf
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.rRNA.tsv
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.rRNA.tsv_short.tsv
                    copyhelper $ALIGNMETRICSDIR/${SAMPLE_NAME}_${LIB_ID}.sorted.metrics.targetCoverage.txt
                    copyhelper $ALIGNMETRICSDIR/rnaseqc_${SAMPLE_NAME}_${LIB_ID} # folder
                    copyhelper $ALIGNMETRICSDIR/staralign_${SAMPLE_NAME}_${LIB_ID} # folder
                    copyhelper ${OUTPUT_DIR}/Aligned.${LANE}/alignment/${SAMPLE_NAME}/run${RUN_ID}_${LANE}/${SAMPLE_NAME}_${LIB_ID}.align_metrics.html
                fi

                QCGRAPH=${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/${SAMPLE_NAME}_${LIB_ID}_${LANE}.qc_graph.html
                copyhelper $QCGRAPH

                copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/qc
                copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R1
                if [ "$RUN_TYPE" == "PAIRED_END" ]; then
                    copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.R2
                fi
                copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I1
                # if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
                # if [ "$INDEX_TYPE" == "DUAL_INDEX" ] || [ "$LIB_TYPE" == "HaloPlex"]; then
                    copyhelper ${OUTPUT_DIR}/Unaligned.${LANE}/Project_${PROJECT_ID}/Sample_${SAMPLE_NAME}_${LIB_ID}/fastqc.I2
                # fi

        fi

        # special counter, leave here
        if [[ "$INDEX_NAME" == SI-* ]]; then
            let COUNT=${COUNT}+3
        fi

    done

done

# done

copyhelper $SAMPLE_SHEET

copyhelper $(echo $SAMPLE_SHEET | sed 's/collapsed_lanes/split_on_lanes/g')

# CLARITY_FILES=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.db_upload.files.txt
# copyhelper $CLARITY_FILES

CLARITY_POOLDATA=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.db_upload_allpool.txt
copyhelper $CLARITY_POOLDATA

for ARTIFACT_ID in $(tail -n +2 $CLARITY_POOLDATA | awk -F'\t' '$4!="N/A"{print $1}' | sort -u); do
   copyhelper $CLARITY_POOLDATA.$ARTIFACT_ID;
done

CLARITY_UDFS=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.db_upload.udfs.txt
copyhelper $CLARITY_UDFS

FTP_FILES=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.copylist.txt
copyhelper $FTP_FILES

MAIN_CSV=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.csv
copyhelper $MAIN_CSV

ALIGN_BWAMEM_CSV=${OUTPUT_DIR}/${OUT_RUN_ROOT}-$SEQ_TYPE-run.align_bwa_mem.csv
copyhelper $ALIGN_BWAMEM_CSV

# rsync -arvh --relative --files-from=${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist1.${TIMESTAMP}.txt ${OUTPUT_DIR} $FINAL_DIR
# rsync -arvh --relative --files-from=${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist2.${TIMESTAMP}.txt ${RUN_DIR} $FINAL_DIR

if [ -d "${OUTPUT_DIR}/javatmp" ]; then
    rm -rf ${OUTPUT_DIR}/javatmp;
fi

}

function copyjob {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${RUN_ID}
if ($COPYJOB_DEPEND); then
   JOB_DEPENDENCIES="";
else
   JOB_DEPENDENCIES=$(cleandepend $FINAL_MAIN);
fi
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;

if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; copyjob_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

COMMAND=$(cat <<EOF
. ${CODE_DIR}/$(basename $BASH_SOURCE) $MODE && \
(copysetup $PROCESS_ID $RUN_DIR $OUTPUT_DIR $SAMPLE_SHEET $FINAL_DIR $TIMESTAMP $YEAR || true) && \
rsync -arvvh --relative --files-from=${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist1.${TIMESTAMP}.txt ${OUTPUT_DIR} $FINAL_DIR && \
rsync -arvvh --relative --files-from=${OUTPUT_DIR}/${OUT_RUN_ROOT}.rsynclist2.${TIMESTAMP}.txt ${RUN_DIR} $FINAL_DIR
EOF
);

echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterany:$JOB_DEPENDENCIES";
fi
copyjob_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
# qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=2:00:00:0 -q $QUEUE -l nodes=1:ppn=2 $DEP | grep "[0-9]")
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=10:00:00:0 -q $QUEUE -l nodes=1:ppn=2 $DEP | grep "[0-9]")
# qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=12:00:0 -q $QUEUE -l nodes=1:ppn=2 $DEP | grep "[0-9]")

echo -e "$copyjob_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

# stepaccumulator $copyjob_JOB_ID

}


function monitor_sub {

    PROCESS_ID=$1
    RUN_DIR=$2
    OUTPUT_DIR=$3
    SAMPLE_SHEET=$4
    FINAL_DIR=$5
    TIMESTAMP=$6
    YEAR=$7

    ALLLANES=$(readsamplesheet | awk -F, '{print $7}'  | tr '-' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

    OVERINDEX1=""; OVERINDEX2="";
    getcycles $RUN_DIR/RunInfo.xml
    parse_run_info_parameters $RUN_DIR

    RUN_ID=${INSTRUMENT}_${RUN_NUMBER}
    echo $RUN_ID

    SEQ_TYPE=$(grep "$INSTRUMENT" $INSTRUMENT_LIST | awk -F, '{print $3}')

    if [ "$READ2CYCLES" == "0" ]; then
        RUN_TYPE=SINGLE_END;
    else
        RUN_TYPE=PAIRED_END;
    fi

    if [ "$INDEX2CYCLES" == "0" ] || [ "$INDEX1CYCLES" == "0" ]; then
        INDEX_TYPE=SINGLE_INDEX;
    else
        INDEX_TYPE=DUAL_INDEX;
    fi

    while(true); do
        # start signal
        if [ -f "$OUTPUT_DIR/job_output/monitor/start" ]; then
            echo $OUTPUT_DIR/job_output/monitor/start
            break;
        fi;
        sleep 15
    done

    while(true); do
        # end signal
        echo "monitor $(date)"
        aggregate_reports
        # copy false

        if [ -f "$OUTPUT_DIR/job_output/monitor/stop" ]; then
            echo $OUTPUT_DIR/job_output/monitor/stop
            break;
        fi

        echo "sleep $MONITOR_LOOP_DELAY"
        sleep $MONITOR_LOOP_DELAY

    done

    # copy true
    echo "monitor: exit"
    rm -f $OUTPUT_DIR/job_output/monitor/start

}


function monitor {

STEP=${FUNCNAME[0]};
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_NAME=${STEP}.${RUN_ID}
JOB_DEPENDENCIES=
JOB_DONE=job_output/${STEP}/${JOB_NAME}.done;
JOB_RUNNING=job_output/${STEP}/${JOB_NAME}.running;
if [ -f $OUTPUT_DIR/$JOB_DONE ]; then echo "DONE: "$JOB_NAME; monitor_JOB_ID=""; return; else echo "RUN:  ${JOB_NAME} - ${TIMESTAMP}"; fi;
JOB_OUTPUT_RELATIVE_PATH=$STEP/${JOB_NAME}_$TIMESTAMP.o
JOB_OUTPUT=$JOB_OUTPUT_DIR/$JOB_OUTPUT_RELATIVE_PATH

COMMAND=$(cat <<EOF
. ${CODE_DIR}/$(basename $BASH_SOURCE) $MODE && \
monitor_sub $PROCESS_ID $RUN_DIR $OUTPUT_DIR $SAMPLE_SHEET $FINAL_DIR $TIMESTAMP $YEAR \
|| true
EOF
)

echo "#+ ${STEP}" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
echo "# $COMMAND" >> ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;
if ($TEXTONLY); then return; fi;
if [ "$(echo $JOB_DEPENDENCIES | sed 's/://g')" == "" ]; then  DEP="";
else                                                           DEP="-W depend=afterok:$JOB_DEPENDENCIES";
fi
monitor_JOB_ID=$(echo "set -eu -o pipefail; cd ${OUTPUT_DIR} &&  rm -f $JOB_DONE && $COMMAND;
MUGQIC_STATE=\$PIPESTATUS;
echo MUGQICexitStatus:\$MUGQIC_STATE;
if [ \$MUGQIC_STATE -eq 0 ]; then touch $JOB_DONE; fi;
exit \$MUGQIC_STATE" | \
# qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=2:00:00:0 -q $QUEUE -l nodes=1:ppn=2 $DEP | grep "[0-9]")
qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=10:00:00:0 -q $QUEUE -l nodes=1:ppn=2 $DEP | grep "[0-9]")
# qsub -m n -W umask=0002 -d $OUTPUT_DIR -j oe -o $JOB_OUTPUT -N ${TIMESTAMP}_$JOB_NAME $QOS -l walltime=12:00:0 -q $QUEUE -l nodes=1:ppn=2 $DEP | grep "[0-9]")
echo -e "$monitor_JOB_ID\t$JOB_NAME\t$JOB_DEPENDENCIES\t$JOB_OUTPUT_RELATIVE_PATH" >> $JOB_LIST

}

######################
###
###   PROGRAM START
###
######################

function bootstrap {

    LIMS_INPUT_TSV_CLARITY=$1

    if [ ! -f $LIMS_INPUT_TSV_CLARITY ]; then
        echo "$LIMS_INPUT_TSV_CLARITY not found, exit"
        return
    fi

    if [ "$(tail -n+2 "$LIMS_INPUT_TSV_CLARITY" | awk -F '\t' '{print $5}' | grep -v "^$" | sort -u | wc -l)" != "1" ]; then
        echo "More than one FCID found in $LIMS_INPUT_TSV_CLARITY, exit"
        return
    fi

    cat $LIMS_INPUT_TSV_CLARITY | tr '\t' '|' | column -t -s '|' | cut -c 1-150

    PROCESS_ID_BOOTSTRAP=$(tail -n+2 $LIMS_INPUT_TSV_CLARITY | head -n 1 | awk '{print $1}');

    FCID_CLARITY=$(tail -n+2 $LIMS_INPUT_TSV_CLARITY | awk -F '\t' '{print $5}' | grep -v "^$" | sort -u)

    FORCE_DEMULTIPLEX=0;
    FORCE_DEMUX_FLAG=$(ls $FORCE_DEMULTIPLEX_PATH/*${FCID_CLARITY}* 2>/dev/null)
    if [ -f "$FORCE_DEMUX_FLAG" ]; then
        echo "Force demux for: "$FORCE_DEMUX_FLAG;
        FORCE_DEMULTIPLEX=1;
    fi

    FORCE_MM_FLAG=$(ls $FORCE_MM_PATH/*${FCID_CLARITY}* 2>/dev/null)
    if [ -f "$FORCE_MM_FLAG" ]; then
       echo "FORCE MM FLAG DETECTED: $FORCE_MM_FLAG"
       cat $FORCE_MM_FLAG
    fi

    YEAR_BOOTSTRAP=$(tail -n+2 $LIMS_INPUT_TSV_CLARITY | head -n 1 | awk -F '\t' '{print $15}' | awk -F '-' '{print $1}')

    IFS=','
    notfound=true
    for RUN_DROP in $RUN_DROP_LIST; do
        # RUN_DIR_BOOTSTRAP=$(ls -d $RUN_DROP/*${FCID_CLARITY}* 2>/dev/null)
        # FLOWCELLDIR=$(ls -rtd $RUN_DROP/*${FCID_CLARITY}* 2>/dev/null | tail -n 1)
        RUN_DIR_BOOTSTRAP=$(ls -rtd $RUN_DROP/*${FCID_CLARITY}* 2>/dev/null | tail -n 1)
        if [ -d "$RUN_DIR_BOOTSTRAP" ]; then
            echo "Found run: "$RUN_DIR_BOOTSTRAP;
            notfound=false;
            break;
        fi
    done
    IFS=$'\n'

    if($notfound); then
       echo "ERROR: run dir not found.";
       echo "ERROR: looking for: ${FCID_CLARITY}";
       echo "ERROR: in here: ${RUN_DROP_LIST}";
       return;
    fi

    parse_run_info_parameters $RUN_DIR_BOOTSTRAP
    SEQ_TYPE=$(grep "$INSTRUMENT" $INSTRUMENT_LIST | awk -F, '{print $3}')
    SEQ_CATEGORY=$(echo $SEQ_TYPE | sed 's/4000//g' | sed 's/2500//g' | sed 's/x//g')

    TIMESTAMP_BOOTSTRAP=$(date +%FT%H.%M.%S)

    OUTPUT_DIR_BOOTSTRAP=$SCRATCH_DIR/${OUT_RUN_ROOT}-${SEQ_TYPE}

    mkdir -p $OUTPUT_DIR_BOOTSTRAP
    echo ${PROCESS_ID_BOOTSTRAP} > $OUTPUT_DIR_BOOTSTRAP/process_id.txt

    cp $LIMS_INPUT_TSV_CLARITY  $OUTPUT_DIR_BOOTSTRAP/${OUT_RUN_ROOT}.$(basename $LIMS_INPUT_TSV_CLARITY)

    SAMPLE_SHEET_LANE_SPLIT=$OUTPUT_DIR_BOOTSTRAP/${OUT_RUN_ROOT}.pipelinesamplesheet.split_on_lanes.csv

# ProcessLUID,ProjectLUID,ProjectName,ContainerLUID,ContainerName,Position,Index,LibraryLUID,LibraryProcess,ArtifactLUIDLibNorm,ArtifactNameLibNorm,SampleLUID,SampleName,Reference,Start Date,Sample Tag,
# Target Cells,Library Metadata ID,Species,UDF/Genome Size (Mb),Gender,Pool Fraction,Capture Type,CaptureLUID,Capture Name,Capture REF_BED,Capture Metadata ID,ArtifactLUIDClustering,Library Size,Library Kit Name,Capture Kit Type,Capture Bait Version

# 24-92263,AUL608,BRIDGET_Germany,27-23276,Hhasdfnk213,1:1,IDTMU762_F02-IDTMU562_F02,2-502198,WGBS Lucigen,2-502667,Test_Germany_Cap016,AUL608A36,2704288,Homo_sapiens:GRCh38,2019-03-13,N/A,N/A,122-92261,N/A,3.2,N/A,0.031,Capture,2-502597,Test_Germany_Cap016,N/A,122-92257,2-502677,N/A,NxSeq AmpFREE Low DNA libary Kit,MCC-Seq,MCC-Seq::131010_HG19_EG_immune_EPI (AKA Immune V1)

    IFS=$'\n'
    echo "#" $PROCESS_ID_BOOTSTRAP > $SAMPLE_SHEET_LANE_SPLIT
    echo "#" $RUN_DIR_BOOTSTRAP >> $SAMPLE_SHEET_LANE_SPLIT
    echo "#" $OUTPUT_DIR_BOOTSTRAP >> $SAMPLE_SHEET_LANE_SPLIT
    echo "Project ID,Project Name,Library ID,Sample Name,Sample ID,Index name,Flowcell lane,Data ID,Library Type,Library Structure,Processing Type,Genomic Database and BED Files,Expected Sample Tag,Target Cells,Library Metadata ID,Species,UDF/Genome Size (Mb),Gender,Pool Fraction,Capture Type,CaptureLUID,Capture Name,Capture REF_BED,Capture Metadata ID,ArtifactLUIDClustering,Library Size,Library Kit Name,Capture Kit Type,Capture Bait Version" >> $SAMPLE_SHEET_LANE_SPLIT

    for line in $(cat $LIMS_INPUT_TSV_CLARITY | tr -d '\r' | grep -v '^$' | grep -v "^#"| tail -n+2 | grep $FCID_CLARITY | sort -k6); do

        # echo "$line" | cut -c 1-400

        PROJECT_ID_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $2}');
        PROJECT_NAME_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $3}');
        POSITION_CLARITY=$(echo $line | awk -F'\t' '{print $6}'); LANE_CLARITY=$(echo -n $POSITION_CLARITY | awk -F':' '{print $1}' | tr -d "0")
        INDEX_CLARITY=$(echo $line | awk -F'\t' '{print $7}'); INDEX_BOOTSTRAP=$(echo $INDEX_CLARITY | awk -F' ' '{print $1}')
        LIB_ID_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $8}');
        LIBRARY_TYPE_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $9}');
        ARTIFACT_ID_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $10}');
        SAMPLE_ID_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $12}');
        SAMPLE_NAME_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $13}');
        REF_AND_BED_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $14}');

        if [ "$REF_AND_BED_BOOTSTRAP" == "N/A" ]; then
            REF_AND_BED_BOOTSTRAP="";
        fi

        DUMMY_YEAR_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $15}');
        EXPECTED_SAMPLE_TAG_BOOTSTRAP=$(echo $line | awk -F'\t' '{print $16}');

        TARGET_CELLS=$(echo $line | awk -F'\t' '{print $17}');
        LIBRARY_METADATA_ID=$(echo $line | awk -F'\t' '{print $18}');
        SPECIES=$(echo $line | awk -F'\t' '{print $19}');
        GENOME_SIZE_MB=$(echo $line | awk -F'\t' '{print $20}');
        SEX=$(echo $line | awk -F'\t' '{print $21}')

        if [ "$SEX" == '' ]; then
            SEX='N/A';
        fi
        if [ "$SEX" != 'N/A' ]; then
            SEX=$(echo "$SEX" | cut -c 1 | tr '[:lower:]' '[:upper:]');
        fi
        POOL_FRACTION=$(echo $line | awk -F'\t' '{print $22}');
        POOLING_TYPE=$(echo $line | awk -F'\t' '{print $23}' | sed 's/Pool Samples/Library Pool/g');
        POOLING_ID=$(echo $line | awk -F'\t' '{print $24}');
        CAPTURE_NAME=$(echo $line | awk -F'\t' '{print $25}');
        CAPTURE_REF_BED=$(echo $line | awk -F'\t' '{print $26}');
        CAPTURE_METADATA_ID=$(echo $line | awk -F'\t' '{print $27}');
        ARTIFACTLUIDCLUSTERING=$(echo $line | awk -F'\t' '{print $28}');
        LIBRARY_SIZE=$(echo $line | awk -F'\t' '{print $29}');
        LIBRARY_KIT_NAME=$(echo $line | awk -F'\t' '{print $30}');
        CAPTURE_KIT_TYPE=$(echo $line | awk -F'\t' '{print $31}');
        CAPTURE_BAIT_VERSION=$(echo $line | awk -F'\t' '{print $32}');
        CHIPSEQMARK=$(echo $line | awk -F'\t' '{print $33}');

        PROCESSING_TYPE_BOOTSTRAP=$(grep "^$LIBRARY_TYPE_BOOTSTRAP," $LIBRARY_PROTOCOL_LIST | awk -F',' '{print $2}')
        LIBRARY_STRUCTURE_BOOTSTRAP=$(grep "^$LIBRARY_TYPE_BOOTSTRAP," $LIBRARY_PROTOCOL_LIST | awk -F',' '{print $3}')

        if [ -z "$LIBRARY_STRUCTURE_BOOTSTRAP" ]; then
            if [[ "$INDEX_BOOTSTRAP" == SI-* ]]; then
                KEY=$INDEX_BOOTSTRAP;
            else
                KEY=$(echo "$INDEX_BOOTSTRAP" | awk -F'-' '{print $1}');
            fi
            LIBRARY_STRUCTURE_BOOTSTRAP=$( grep "^$KEY," $ADAPTER_TYPES_FILE | awk -F',' '{print $2}' | head -n 1);
        fi

        if [ "$PROCESSING_TYPE_BOOTSTRAP" == "" ]; then
           echo "error: $LIBRARY_TYPE_BOOTSTRAP not found in $LIBRARY_PROTOCOL_LIST";
           return;
        fi

        echo -n $PROJECT_ID_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 1
        echo -n $PROJECT_NAME_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 2
        echo -n $LIB_ID_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 3
        echo -n $SAMPLE_NAME_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 4
        echo -n $SAMPLE_ID_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 5
        echo -n $INDEX_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 6
        echo -n $LANE_CLARITY',' >> $SAMPLE_SHEET_LANE_SPLIT; # 7   *****
        echo -n $ARTIFACT_ID_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 8   *****
        echo -n $LIBRARY_TYPE_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 9
        echo -n $LIBRARY_STRUCTURE_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 10
        echo -n $PROCESSING_TYPE_BOOTSTRAP',' >> $SAMPLE_SHEET_LANE_SPLIT; # 11
        echo -n $REF_AND_BED_BOOTSTRAP"," >> $SAMPLE_SHEET_LANE_SPLIT; # 12
        echo -n $EXPECTED_SAMPLE_TAG_BOOTSTRAP"," >> $SAMPLE_SHEET_LANE_SPLIT; # 13
        echo -n $TARGET_CELLS"," >> $SAMPLE_SHEET_LANE_SPLIT; # 14
        echo -n $LIBRARY_METADATA_ID"," >> $SAMPLE_SHEET_LANE_SPLIT; # 15
        echo -n $SPECIES"," >> $SAMPLE_SHEET_LANE_SPLIT; # 16
        echo -n $GENOME_SIZE_MB"," >> $SAMPLE_SHEET_LANE_SPLIT; # 17
        echo -n $SEX"," >> $SAMPLE_SHEET_LANE_SPLIT; # 18
        echo -n $POOL_FRACTION"," >> $SAMPLE_SHEET_LANE_SPLIT; # 19   *****
        echo -n $POOLING_TYPE"," >> $SAMPLE_SHEET_LANE_SPLIT; # 20   *****
        echo -n $POOLING_ID"," >> $SAMPLE_SHEET_LANE_SPLIT; # 21   *****
        echo -n $CAPTURE_NAME"," >> $SAMPLE_SHEET_LANE_SPLIT; # 22   *****
        echo -n $CAPTURE_REF_BED"," >> $SAMPLE_SHEET_LANE_SPLIT; # 23   *****
        echo -n $CAPTURE_METADATA_ID"," >> $SAMPLE_SHEET_LANE_SPLIT; # 24   *****
        echo -n $ARTIFACTLUIDCLUSTERING"," >> $SAMPLE_SHEET_LANE_SPLIT; # 25   *****
        echo -n $LIBRARY_SIZE"," >> $SAMPLE_SHEET_LANE_SPLIT; # 26
        echo -n $LIBRARY_KIT_NAME"," >> $SAMPLE_SHEET_LANE_SPLIT; # 27
        echo -n $CAPTURE_KIT_TYPE"," >> $SAMPLE_SHEET_LANE_SPLIT; # 28   *****
        echo -n $CAPTURE_BAIT_VERSION"," >> $SAMPLE_SHEET_LANE_SPLIT; # 29
        echo $CHIPSEQMARK >> $SAMPLE_SHEET_LANE_SPLIT; # 30   ***** ,newline + no comma on last one

    done

    SAMPLE_SHEET_BOOTSTRAP=$OUTPUT_DIR_BOOTSTRAP/${OUT_RUN_ROOT}.pipelinesamplesheet.collapsed_lanes.csv
    echo "#" $PROCESS_ID_BOOTSTRAP > $SAMPLE_SHEET_BOOTSTRAP
    echo "#" $RUN_DIR_BOOTSTRAP >> $SAMPLE_SHEET_BOOTSTRAP
    echo "#" $OUTPUT_DIR_BOOTSTRAP >> $SAMPLE_SHEET_BOOTSTRAP
    echo "Project ID,Project Name,Library ID,Sample Name,Sample ID,Index name,Flowcell Lanes,Data ID,Library Type,Library Structure,Processing Type,Genomic Database and BED Files,Expected Sample Tag,Target Cells,Library Metadata ID,Species,UDF/Genome Size (Mb),Gender,Pool Fraction,Capture Type,CaptureLUID,Capture Name,Capture REF_BED,Capture Metadata ID,ArtifactLUIDClustering,Library Size,Library Kit Name,Capture Kit Type,Capture Bait Version,ChIPSeq Mark" >> $SAMPLE_SHEET_BOOTSTRAP

    IFS=$'\n'
    for THIS_LIB_ID in $(grep -v '^# ' $SAMPLE_SHEET_LANE_SPLIT | tail -n+2 | awk -F',' '{print $3}' | sort -u); do

        TMPVAR=$(cat $SAMPLE_SHEET_LANE_SPLIT | awk -v variable="$THIS_LIB_ID" -F"," '$3==variable {print $0}' |  awk -F',' '{print $7"\t"$8"\t"$19"\t"$20"\t"$21"\t"$22"\t"$23"\t"$24"\t"$25"\t"$28"\t"$29"\t"$30}' | sort -nk1)
        LANES_BOOTSTRAP=$(echo "$TMPVAR" | awk -F'\t' '{print $1}' | tr '\n' '-' | rev | cut -c 2- | rev)
        ARTIFACT_IDS_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $2}' | tr '\n' '|' | rev | cut -c 2- | rev)
        POOL_FRACTIONS_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $3}' | tr '\n' '|' | rev | cut -c 2- | rev)
        POOLING_TYPES_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $4}' | tr '\n' '|' | rev | cut -c 2- | rev)
        POOLING_IDS_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $5}' | tr '\n' '|' | rev | cut -c 2- | rev)
        CAPTURE_NAMES_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $6}' | tr '\n' '|' | rev | cut -c 2- | rev)
        CAPTURE_REF_BEDS_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $7}' | tr '\n' '|' | rev | cut -c 2- | rev)
        CAPTURE_METADATA_IDS_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $8}' | tr '\n' '|' | rev | cut -c 2- | rev)
        ARTIFACTLUIDCLUSTERINGS_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $9}' | tr '\n' '|' | rev | cut -c 2- | rev)
        CAPTURE_KIT_TYPES_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $10}' | tr '\n' '|' | rev | cut -c 2- | rev)
        CAPTURE_BAIT_VERSIONS_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $11}' | tr '\n' '|' | rev | cut -c 2- | rev)
        CHIPSEQMARK_BOOTSTRAP=$(echo "$TMPVAR" | awk -F '\t' '{print $12}' | tr '\n' '|' | rev | cut -c 2- | rev)

        # LANES_BOOTSTRAP=$(cat $SAMPLE_SHEET_LANE_SPLIT | awk -v variable="$THIS_LIB_ID" -F"," '$3==variable {print $0}' |  awk -F',' '{print $7}' | sort | tr '\n' '-' | rev | cut -c 2- | rev)
        cat $SAMPLE_SHEET_LANE_SPLIT | awk -v variable="$THIS_LIB_ID" -F"," '$3==variable {print $0}' | head -n 1 | \
             awk -F',' -v LANES_BOOTSTRAP=$LANES_BOOTSTRAP \
                       -v ARTIFACT_IDS_BOOTSTRAP=$ARTIFACT_IDS_BOOTSTRAP \
                       -v POOL_FRACTIONS_BOOTSTRAP=$POOL_FRACTIONS_BOOTSTRAP \
                       -v POOLING_TYPES_BOOTSTRAP=$POOLING_TYPES_BOOTSTRAP \
                       -v POOLING_IDS_BOOTSTRAP=$POOLING_IDS_BOOTSTRAP \
                       -v CAPTURE_NAMES_BOOTSTRAP=$CAPTURE_NAMES_BOOTSTRAP \
                       -v CAPTURE_REF_BEDS_BOOTSTRAP=$CAPTURE_REF_BEDS_BOOTSTRAP \
                       -v CAPTURE_METADATA_IDS_BOOTSTRAP=$CAPTURE_METADATA_IDS_BOOTSTRAP \
                       -v ARTIFACTLUIDCLUSTERINGS_BOOTSTRAP=$ARTIFACTLUIDCLUSTERINGS_BOOTSTRAP \
                       -v CAPTURE_KIT_TYPES_BOOTSTRAP=$CAPTURE_KIT_TYPES_BOOTSTRAP \
                       -v CAPTURE_BAIT_VERSIONS_BOOTSTRAP=$CAPTURE_BAIT_VERSIONS_BOOTSTRAP \
                       -v CHIPSEQMARK_BOOTSTRAP=$CHIPSEQMARK_BOOTSTRAP \
            '{print $1","$2","$3","$4","$5","$6","LANES_BOOTSTRAP","ARTIFACT_IDS_BOOTSTRAP","$9","$10","$11","$12","$13","$14","$15","$16","$17","$18","POOL_FRACTIONS_BOOTSTRAP","POOLING_TYPES_BOOTSTRAP","POOLING_IDS_BOOTSTRAP","CAPTURE_NAMES_BOOTSTRAP","CAPTURE_REF_BEDS_BOOTSTRAP","CAPTURE_METADATA_IDS_BOOTSTRAP","ARTIFACTLUIDCLUSTERINGS_BOOTSTRAP","$26","$27","CAPTURE_KIT_TYPES_BOOTSTRAP","CAPTURE_BAIT_VERSIONS_BOOTSTRAP","CHIPSEQMARK_BOOTSTRAP}';

    done | sort -t ',' -k7,7 -k22,22 -k21,21 -k3,3 >> $SAMPLE_SHEET_BOOTSTRAP

bbb="1 Project ID
2 Project Name
3 Library ID
4 Sample Name
5 Sample ID
6 Index name
7 Flowcell Lanes
8 Data ID
9 Library Type
10 Library Structure
11 Processing Type
12 Genomic Database and BED Files
13 Expected Sample Tag
14 Target Cells
15 Library Metadata ID
16 Species
17 UDF/Genome Size (Mb)
18 Gender
19 Pool Fraction
20 Capture Type
21 CaptureLUID
22 Capture Name
23 Capture REF_BED
24 Capture Metadata ID
25 ArtifactLUIDClustering
26 Library Size
27 Library Kit Name
28 Capture Kit Type
29 Capture Bait Version
30 ChIPSeq Mark"

     run $PROCESS_ID_BOOTSTRAP $RUN_DIR_BOOTSTRAP $OUTPUT_DIR_BOOTSTRAP $SAMPLE_SHEET_BOOTSTRAP $TIMESTAMP_BOOTSTRAP $YEAR_BOOTSTRAP

}

function run {

PROCESS_ID=$1
RUN_DIR=$2
OUTPUT_DIR=$3
SAMPLE_SHEET=$4
TIMESTAMP=$5
YEAR=$6

echo "PROCESS_ID: "$PROCESS_ID

JOB_OUTPUT_DIR=${OUTPUT_DIR}/job_output
JOB_LIST=${JOB_OUTPUT_DIR}/IlluminaRunProcessing_job_list_${TIMESTAMP}
mkdir -p ${OUTPUT_DIR}
TMP_DIR=${OUTPUT_DIR}/javatmp
mkdir -p ${TMP_DIR}

mkdir -p ${JOB_OUTPUT_DIR}
touch ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh

ALLLANES=$(readsamplesheet | awk -F, '{print $7}'  | tr '-' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

echo "ALLLANES: $ALLLANES"

MASK=$(getmask $RUN_DIR/RunInfo.xml)

echo "MASK: $MASK"
OVERINDEX1="";OVERINDEX2="";
getcycles $RUN_DIR/RunInfo.xml
echo  "R1,R2,I1,I2: $READ1CYCLES,$READ2CYCLES,$INDEX1CYCLES,$INDEX2CYCLES"
parse_run_info_parameters $RUN_DIR
echo "FLOWCELL BARCODE (FCID)": $FCID
echo "EXPERIMENT_NAME": $EXPERIMENT_NAME
echo "INSTRUMENT": $INSTRUMENT
echo "RUN_NUMBER": $RUN_NUMBER
echo "RUN_DATE": $RUN_DATE
echo "FC_POSITION:" $FC_POSITION
echo "OUT_RUN_ROOT": $OUT_RUN_ROOT

INDEX1CYCLESORIG=$INDEX1CYCLES;
INDEX2CYCLESORIG=$INDEX2CYCLES;

RUN_ID=${INSTRUMENT}_${RUN_NUMBER}
echo "RUN_ID": $RUN_ID

SEQ_TYPE=$(grep "$INSTRUMENT" $INSTRUMENT_LIST | awk -F, '{print $3}')
echo "SEQ_TYPE": $SEQ_TYPE

SEQ_CATEGORY=$(echo $SEQ_TYPE | sed 's/4000//g' | sed 's/2500//g' | sed 's/x//g')
echo "SEQ_CATEGORY": $SEQ_CATEGORY

FINAL_DIR=$FINAL_ROOT/$SEQ_CATEGORY/$YEAR/${OUT_RUN_ROOT}-${SEQ_TYPE};
mkdir -p ${FINAL_DIR}

# for RUN_DIR in /sb/hiseq/17*; do MASK=$(getmask $RUN_DIR/RunInfo.xml); getcycles $RUN_DIR/RunInfo.xml; echo  $RUN_DIR $MASK $READ1CYCLES $READ2CYCLES $INDEX1CYCLES $INDEX2CYCLES ; done


FINAL_MAIN=

rm -f $OUTPUT_DIR/job_output/monitor/start
rm -f $OUTPUT_DIR/job_output/monitor/stop
rm -f $OUTPUT_DIR/job_output/monitor/monitor.${RUN_ID}.done
rm -f $OUTPUT_DIR/job_output/copyjob/start
rm -f $OUTPUT_DIR/job_output/copyjob/copyjob.${RUN_ID}.done

monitor

IFS=$'\n'
for LANE in $(echo $ALLLANES | tr ' ' '\n'); do

    FORCE_MM_FLAG=$(ls $FORCE_MM_PATH/*${FCID}* 2>/dev/null)
    if [ -f "$FORCE_MM_FLAG" ]; then
       NUM_MISMATCH=$(cat $FORCE_MM_FLAG | grep "$LANE:" | awk -F ':' '{print $2}')
       if [ -z "$NUM_MISMATCH" ]; then
          NUM_MISMATCH=1;
       fi
    fi

    # haloplex samples present (dual index must be used)
    #if [ "$(readsamplesheet | grep -c 'Haloplex' )" != "0" ]; then
     #   if [ "$INDEX_TYPE" == "DUAL_INDEX" ]; then
            #    using adapter settings format create index sequence for all samples using index 1 and 2, create haloplex samples with NNN in second index
            #    split 10X samples if present (-> A B C D)
            #    check for index conflicts for single index and dual index, N is assumed not to conflict.
            #
            #    *** for other samples: remove haloplex samples
            #    generate mask according to xml
            #    create dual index sample sheet
            #    run bcl2fastq
            #    merge 10X samples if present
            #
            #    *** for haloplex samples: keep haloplex samples only
            #    generate mask according to xml make second index a read I->Y for bcl2fastq
            #    create single index sample sheet
            #    run bcl2fastq
            #    swap R3 and R2 (second index is UMI)
      #      :
      #  else
      #     echo "error: haloplex samples present (dual index must be used)";
      #     return;
      #  fi

    #else # no haloplex samples present
        # using adapter settings format create index sequence for all samples using index 1 and 2
        # split 10X samples if present (-> A B C D)
        # check for index conflicts for dual index
        # generate mask according to xml
        # create single/dual index sample sheet

        GENERATE_UMI9=0;
        if($(echo "$MASK" | grep -q -E ',I17,')); then
            GENERATE_UMI9=1;
            OVERMASK=$(echo "$MASK" | sed 's/,I17,/,I8n*,/g')
            OVERINDEX1=8; OVERINDEX2=8;
        fi

        LIBRARY_PER_LANE=0
        INDEX_COUNT_1OR2_ACCU=""
        INDEX1_LENGTH_ACCU=""
        INDEX2_LENGTH_ACCU=""
        for line in $(readsamplesheet); do
            INDEX_NAME=$(echo $line | awk -F, '{print $6}');
            LANES=$(echo $line | awk -F, '{print $7}');
            if [[ "$LANES" == *$LANE* ]]; then
		LIB_TYPE=$(echo $line | awk -F, '{print $9}');
		LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
                let LIBRARY_PER_LANE=$LIBRARY_PER_LANE+1;
		if [[ "$INDEX_NAME" == *-* ]] && [[ "$INDEX_NAME" != SI-* ]]; then
                    KEY=$(echo "$INDEX_NAME" | awk -F'-' '{print $1}');
                    KEY2=$(echo "$INDEX_NAME" | awk -F'-' '{print $2}');
		    INDEX1_LENGTH=$(awk -F',' -v key=$KEY '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX1_LENGTH_ACCU="$INDEX1_LENGTH_ACCU,$INDEX1_LENGTH"
		    INDEX2_LENGTH=$(awk -F',' -v key=$KEY2 '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX2_LENGTH_ACCU="$INDEX2_LENGTH_ACCU,$INDEX2_LENGTH"
		elif [ "$LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ]; then
                    KEY=$INDEX_NAME;
		    INDEX2_LENGTH=$(awk -F',' -v key=$KEY '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX2_LENGTH_ACCU="$INDEX2_LENGTH_ACCU,$INDEX2_LENGTH"
		else
                    KEY=$INDEX_NAME;
		    INDEX1_LENGTH=$(awk -F',' -v key=$KEY '$1 == key {print length($2)}' $INDEX_DEF_FILE)
		    INDEX1_LENGTH_ACCU="$INDEX1_LENGTH_ACCU,$INDEX1_LENGTH"
                fi
                INDEX_COUNT_1OR2=$( grep "^$KEY," $ADAPTER_TYPES_FILE | awk -F',' '{print $3}' | head -n 1);
                INDEX_COUNT_1OR2_ACCU="$INDEX_COUNT_1OR2_ACCU,$INDEX_COUNT_1OR2"
            fi
        done

	MAX_INDEX1_CYCLES=$(echo "$INDEX1_LENGTH_ACCU" | tr ',' '\n' | grep -v "^$" | sort -nr | head -n 1)
	MAX_INDEX2_CYCLES=$(echo "$INDEX2_LENGTH_ACCU" | tr ',' '\n' | grep -v "^$" | sort -nr | head -n 1)

	if [ "$MAX_INDEX1_CYCLES" != "" ]; then
	    if [ "$INDEX1CYCLESORIG" -lt "$MAX_INDEX1_CYCLES" ]; then
		MAX_INDEX1_CYCLES=$INDEX1CYCLESORIG;
	    fi
	fi
	if [ "$MAX_INDEX2_CYCLES" != "" ]; then
	    if [ "$INDEX2CYCLESORIG" -lt "$MAX_INDEX2_CYCLES" ]; then
		MAX_INDEX2_CYCLES=$INDEX2CYCLESORIG;
	    fi
	fi
	
	# only single index in lane
	I2_AS_READ2=false;
	I1_AS_READ2=false;
        if [ "$(echo "$INDEX_COUNT_1OR2_ACCU" | tr ',' '\n' | grep -v "^$" | sort -u)" == "SINGLEINDEX" ] || ( [ "$LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ] ); then
            if [ "$(echo "$MASK" | awk -F',' '{print $2}' | tr -d '0123456789')" == "I" ] && ( [ "$LIB_STRUCTURE" == "tenX_sc_RNA_v1" ] || [ "$LIB_TYPE" == "TELL-Seq" ] || [ "$LIB_TYPE" == "SHARE-Seq_ATAC" ] || [ "$LIB_TYPE" == "SHARE-Seq_RNA" ] ); then # R2 is I1
		PAD2=""; if [ "$INDEX2CYCLESORIG" != "$MAX_INDEX2_CYCLES" ]; then PAD2='n*'; fi
		# always output index 2 as read when unused
                OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",Y'$INDEX1CYCLESORIG',I'$MAX_INDEX2_CYCLES$PAD2',"$4}' | sed 's/,$//');
                OVERINDEX1=0; OVERINDEX2=$MAX_INDEX2_CYCLES;
		BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 8"
		I1_AS_READ2=true;	    
	    elif [ "$(echo "$MASK" | awk -F',' '{print $3}' | tr -d '0123456789')" == "I" ]; then # R2 is I2
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
		# always output index 2 as read when unused
                OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',Y'$INDEX2CYCLESORIG',"$4}' | sed 's/,$//');
                OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=0;
		BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 8"
		I2_AS_READ2=true;
	    else # read 3 is not index
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
                OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',"$3}' | sed 's/,$//');
                OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=0;
            fi
	else
	    # only dual index in lane or MIX
	    if [ "$(echo "$MASK" | awk -F',' '{print $3}' | tr -d '0123456789')" == "I" ]; then # read 3 is sequenced as index
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
		PAD2=""; if [ "$INDEX2CYCLESORIG" != "$MAX_INDEX2_CYCLES" ]; then PAD2='n*'; fi
		OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',I'$MAX_INDEX2_CYCLES$PAD2',"$4}' | sed 's/,$//');
		OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=$MAX_INDEX2_CYCLES;
	    else # read 3 is not index
		PAD1=""; if [ "$INDEX1CYCLESORIG" != "$MAX_INDEX1_CYCLES" ]; then PAD1='n*'; fi
		OVERMASK=$(echo "$MASK" | awk -F',' '{print $1",I'$MAX_INDEX1_CYCLES$PAD1',"$3}' | sed 's/,$//');
		OVERINDEX1=$MAX_INDEX1_CYCLES; OVERINDEX2=0;
	    fi
	fi

#        if [ "$(readsamplesheet | awk -F, -v l=$LANE '$7==l&&$9=="HaloPlex"{print $0}' | wc -l)" != "0" ]; then
#           OVERMASK=$(echo "$MASK" | sed 's/,I8,I10,/,I8,Y10,/g' | sed 's/,I8,I8,/,I8,Y8,/g')
#           OVERINDEX1=8; OVERINDEX2=0;
#           # BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 10"
#           BCL2FASTQEXTRAOPTION="--mask-short-adapter-reads 8"
#        fi

        if [ "$OVERMASKMAIN" == "" ]; then
	    :
        else
            OVERMASK=$OVERMASKMAIN
            OVERINDEX1=$OVERINDEX1MAIN; OVERINDEX2=$OVERINDEX2MAIN;
        fi


        getcycles $RUN_DIR/RunInfo.xml

        if [ "$READ2CYCLES" == "0" ]; then
            RUN_TYPE=SINGLE_END;
        else
            RUN_TYPE=PAIRED_END;
        fi

        if [ "$INDEX2CYCLES" == "0" ] || [ "$INDEX1CYCLES" == "0" ]; then
            INDEX_TYPE=SINGLE_INDEX;
        else
            INDEX_TYPE=DUAL_INDEX;
        fi

        USE_DEMULTIPLEX=0

        if [ "$LIBRARY_PER_LANE" != "1" ]; then
            USE_DEMULTIPLEX=1;
        fi

        if [ "$FORCE_DEMULTIPLEX" == "1" ]; then
            USE_DEMULTIPLEX=1;
        fi

        if [[ "$USE_DEMULTIPLEX" == "0" || "$GENERATE_UMI9" == "1" ]]; then
            # still generate indexed output anyways for stats only
            echo '[Data],,,,,,,,,,,' > ${OUTPUT_DIR}/casavasheet.$LANE.indexed.csv;
            echo 'FCID,Lane,Sample_ID,Sample_Name,SampleRef,Index,Index2,Description,Control,Recipe,Operator,Sample_Project' >> ${OUTPUT_DIR}/casavasheet.$LANE.indexed.csv;
            echo '[Data],,,,,,,,,,,' > ${OUTPUT_DIR}/casavasheet.$LANE.noindex.csv;
            echo 'FCID,Lane,Sample_ID,Sample_Name,SampleRef,Index,Index2,Description,Control,Recipe,Operator,Sample_Project' >> ${OUTPUT_DIR}/casavasheet.$LANE.noindex.csv;
        else
            # only generate indexed output
          echo '[Data],,,,,,,,,,,' > ${OUTPUT_DIR}/casavasheet.$LANE.indexed.csv;
          echo 'FCID,Lane,Sample_ID,Sample_Name,SampleRef,Index,Index2,Description,Control,Recipe,Operator,Sample_Project' >> ${OUTPUT_DIR}/casavasheet.$LANE.indexed.csv;
        fi

        EVERYSAMPLE=true

        for line in $(readsamplesheet); do
            PROJECT_ID=$(echo $line | awk -F, '{print $1}');
            PROJECT_NAME=$(echo $line | awk -F, '{print $2}');
            LIB_ID=$(echo $line | awk -F, '{print $3}');
            SAMPLE_NAME=$(echo $line | awk -F, '{print $4}');
            SAMPLE_ID=$(echo $line | awk -F, '{print $5}');
            INDEX_NAME=$(echo $line | awk -F, '{print $6}');
            LANES=$(echo $line | awk -F, '{print $7}');
            ARTIFACT_IDS=$(echo $line | awk -F, '{print $8}');
            LIB_TYPE=$(echo $line | awk -F, '{print $9}');
            LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
            PROCESSING_TYPE=$(echo $line | awk -F, '{print $11}');
            REF_and_BED=$(echo $line | awk -F, '{print $12}');
            EXPECTED_SAMPLE_TAG=$(echo $line | awk -F, '{print $13}');

            TARGET_CELLS=$(echo $line | awk -F, '{print $14}');
            LIBRARY_METADATA_ID=$(echo $line | awk -F, '{print $15}');
            SPECIES=$(echo $line | awk -F, '{print $16}');
            GENOME_SIZE_MB=$(echo $line | awk -F, '{print $17}');
            SEX=$(echo $line | awk -F, '{print $18}');
            POOL_FRACTIONS=$(echo $line | awk -F, '{print $19}');
            POOLING_TYPES=$(echo $line | awk -F, '{print $20}');
            POOLING_IDS=$(echo $line | awk -F, '{print $21}');
            CAPTURE_NAMES=$(echo $line | awk -F, '{print $22}');
            CAPTURE_REF_BEDS=$(echo $line | awk -F, '{print $23}');
            CAPTURE_METADATA_IDS=$(echo $line | awk -F, '{print $24}');
            ARTIFACTLUIDCLUSTERINGS=$(echo $line | awk -F, '{print $25}');
            LIBRARY_SIZE=$(echo $line | awk -F, '{print $26}');
            LIBRARY_KIT_NAME=$(echo $line | awk -F, '{print $27}');
            CAPTURE_KIT_TYPES=$(echo $line | awk -F, '{print $28}');
            CAPTURE_BAIT_VERSIONS=$(echo $line | awk -F, '{print $29}');
            CHIPSEQMARKS=$(echo $line | awk -F, '{print $30}');

            if [[ "$LANES" == *$LANE* ]]; then

                if [[ "$USE_DEMULTIPLEX" == "0" || "$GENERATE_UMI9" == "1" ]]; then
                    for VAL in $(getindex); do
                      BCL2FASTQ_SAMPLE_NAME=$(echo $VAL | awk -F, '{print $1}');
                      BCL2FASTQ_INDEX1=$(echo $VAL | awk -F, '{print $2}');
                      BCL2FASTQ_INDEX2=$(echo $VAL | awk -F, '{print $3}');
                    echo $FCID,$LANE,Sample_$BCL2FASTQ_SAMPLE_NAME,$BCL2FASTQ_SAMPLE_NAME,,$BCL2FASTQ_INDEX1,$BCL2FASTQ_INDEX2,$INDEX_NAME' - '$LIB_TYPE' - '$PROCESSING_TYPE,N,,,Project_${PROJECT_ID} \
                        >> ${OUTPUT_DIR}/casavasheet.$LANE.indexed.csv;
                    done;
                    if($EVERYSAMPLE); then
                      EVERYSAMPLE=false;
                      for VAL in $(getindex); do
                        BCL2FASTQ_SAMPLE_NAME=$(echo $VAL | awk -F, '{print $1}');
                        BCL2FASTQ_INDEX1=$(echo $VAL | awk -F, '{print $2}');
                        BCL2FASTQ_INDEX2=$(echo $VAL | awk -F, '{print $3}');
                        if [ "$GENERATE_UMI9" == "1" ]; then
                          echo $FCID,$LANE,Sample_ALL,ALL,,,,,N,,,Project_ALL \
                            >> ${OUTPUT_DIR}/casavasheet.$LANE.noindex.csv;
                        else
                          echo $FCID,$LANE,Sample_${SAMPLE_NAME}_${LIB_ID},${SAMPLE_NAME}_${LIB_ID},,,,$INDEX_NAME' - '$LIB_TYPE' - '$PROCESSING_TYPE,N,,,Project_${PROJECT_ID} \
                            >> ${OUTPUT_DIR}/casavasheet.$LANE.noindex.csv;
                        fi
                        break; # to skip 10X four lines
                      done;
                    fi
                else
                    for VAL in $(getindex); do
                      BCL2FASTQ_SAMPLE_NAME=$(echo $VAL | awk -F, '{print $1}');
                      BCL2FASTQ_INDEX1=$(echo $VAL | awk -F, '{print $2}');
                      BCL2FASTQ_INDEX2=$(echo $VAL | awk -F, '{print $3}');
                    echo $FCID,$LANE,Sample_$BCL2FASTQ_SAMPLE_NAME,$BCL2FASTQ_SAMPLE_NAME,,$BCL2FASTQ_INDEX1,$BCL2FASTQ_INDEX2,$INDEX_NAME' - '$LIB_TYPE' - '$PROCESSING_TYPE,N,,,Project_${PROJECT_ID} \
                        >> ${OUTPUT_DIR}/casavasheet.$LANE.indexed.csv;
                    done;
                fi
            fi

        done;

        # run index analysis
        index

        # run bcl2fastq
        fastq

    #    fi # haloplex

    # generate animated gif from thumbnails
    # thumb_anim

    COUNT=0
    for line in $(readsamplesheet); do

        PROJECT_ID=$(echo $line | awk -F, '{print $1}');
	PROJECT_NAME=$(echo $line | awk -F, '{print $2}');
	LIB_ID=$(echo $line | awk -F, '{print $3}');
	SAMPLE_NAME=$(echo $line | awk -F, '{print $4}');
	SAMPLE_ID=$(echo $line | awk -F, '{print $5}');
	INDEX_NAME=$(echo $line | awk -F, '{print $6}');
	LANES=$(echo $line | awk -F, '{print $7}');
	ARTIFACT_IDS=$(echo $line | awk -F, '{print $8}');
	LIB_TYPE=$(echo $line | awk -F, '{print $9}');
	LIB_STRUCTURE=$(echo $line | awk -F, '{print $10}');
	PROCESSING_TYPE=$(echo $line | awk -F, '{print $11}');
	REF_and_BED=$(echo $line | awk -F, '{print $12}');
	EXPECTED_SAMPLE_TAG=$(echo $line | awk -F, '{print $13}');

        TARGET_CELLS=$(echo $line | awk -F, '{print $14}');
        LIBRARY_METADATA_ID=$(echo $line | awk -F, '{print $15}');
        SPECIES=$(echo $line | awk -F, '{print $16}');
        GENOME_SIZE_MB=$(echo $line | awk -F, '{print $17}');
        SEX=$(echo $line | awk -F, '{print $18}');
        POOL_FRACTIONS=$(echo $line | awk -F, '{print $19}');
        POOLING_TYPES=$(echo $line | awk -F, '{print $20}');
        POOLING_IDS=$(echo $line | awk -F, '{print $21}');
        CAPTURE_NAMES=$(echo $line | awk -F, '{print $22}');
        CAPTURE_REF_BEDS=$(echo $line | awk -F, '{print $23}');
        CAPTURE_METADATA_IDS=$(echo $line | awk -F, '{print $24}');
        ARTIFACTLUIDCLUSTERINGS=$(echo $line | awk -F, '{print $25}');
        LIBRARY_SIZE=$(echo $line | awk -F, '{print $26}');
        LIBRARY_KIT_NAME=$(echo $line | awk -F, '{print $27}');
        CAPTURE_KIT_TYPES=$(echo $line | awk -F, '{print $28}');
        CAPTURE_BAIT_VERSIONS=$(echo $line | awk -F, '{print $29}');
        CHIPSEQMARKS=$(echo $line | awk -F, '{print $30}');

        REF=$(echo "$REF_and_BED" | awk -F';' '{print $1}' | tr ':' '.')
        BED_FILES=$(echo "$REF_and_BED" | awk -F';' '{$1=""; print $0}' | tr ' ' ';' | sed "s|;|;${BED_PATH}/|g" | cut -c 2-)

        if [ "$(echo $LANES | grep -c $LANE)" == "0" ]; then
            continue
        fi

        let COUNT=${COUNT}+1
	
	fastqc_babraham_JOB_ID="";
	sample_tag_JOB_ID="";
	align_JOB_ID="";
	picard_mark_dup_JOB_ID="";
	bvatools_covdepth_JOB_ID="";
	picard_collect_metrics_JOB_ID="";
	interval_list_JOB_ID="";
	picard_hs_metrics_JOB_ID="";
	rnaseq_qc_JOB_ID="";
	picard_rna_metrics_JOB_ID="";
	bwa_mem_r_rna_JOB_ID="";
	metrics_verify_bam_id_JOB_ID="";
	qc_graphs_JOB_ID="";
	blast_JOB_ID="";
	md5_JOB_ID="";
	cleandupbam_JOB_ID="";
	
        if [ "$PROCESSING_TYPE" == "default DNA" ]; then
            # sample_tag R1
            # qc_graphs
            fastqc_babraham
            blast
            if [ "$REF" != "" ]; then
                align_bwa_mem # dna only
                picard_mark_dup
                bvatools_covdepth
                picard_collect_metrics
                metrics_verify_bam_id # dna only
                if [ "$BED_FILES" != "" ]; then # dna only
                    interval_list
                    picard_hs_metrics
                fi
		cleandupbam
            fi
            md5
        fi
        if [ "$PROCESSING_TYPE" == "default RNA" ]; then
            # sample_tag R1
            # qc_graphs
            fastqc_babraham
            blast
            if [ "$REF" != "" ]; then
                align_star # rna only
                picard_mark_dup
                bvatools_covdepth
                picard_collect_metrics
                rnaseq_qc # rna only
                picard_rna_metrics # rna only
                bwa_mem_r_rna # rna only
		cleandupbam
            fi
            md5
        fi

        if [ "$PROCESSING_TYPE" == "default DNA no bwa" ]; then
            # qc_graphs
            fastqc_babraham
            blast
            md5
        fi
        
        if [ "$PROCESSING_TYPE" == "default RNA no bwa" ]; then
            # qc_graphs
            fastqc_babraham
            blast
            md5
        fi        

        if [ "$PROCESSING_TYPE" == "default DNA no blast" ]; then
            # sample_tag R1
            # qc_graphs
            fastqc_babraham
            if [ "$REF" != "" ]; then
                align_bwa_mem # dna only
                picard_mark_dup
                bvatools_covdepth
                picard_collect_metrics
                metrics_verify_bam_id # dna only
                if [ "$BED_FILES" != "" ]; then # dna only
                    interval_list
                    picard_hs_metrics
                fi
                cleandupbam
            fi
            md5
        fi

       if [ "$PROCESSING_TYPE" == "default RNA no blast" ]; then
            # sample_tag R1
            # qc_graphs
            fastqc_babraham
            if [ "$REF" != "" ]; then
                align_star # rna only
                picard_mark_dup
                bvatools_covdepth
                picard_collect_metrics
                rnaseq_qc # rna only
                picard_rna_metrics # rna only
                bwa_mem_r_rna # rna only
                cleandupbam
            fi
            md5
        fi


        if [ "$PROCESSING_TYPE" == "tenX DNA v2" ]; then
            # qc_graphs
            fastqc_babraham
            blast
            # align_longranger todo
            md5
        fi

        if [ "$PROCESSING_TYPE" == "tenX RNA v2" ]; then
            # qc_graphs
            fastqc_babraham
            blast
            # align_cellranger todo
            md5
        fi

        if [[ "$INDEX_NAME" == SI-* ]]; then
            let COUNT=${COUNT}+3
        fi

    done

done

copyjob

if ($TEXTONLY); then
    :;
else
    touch $OUTPUT_DIR/job_output/monitor/start;
fi;


cat ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh | sed 's/\&\&/\&\& \\\n/g' | sed 's/||/|| \\\n/g' | sed 's/--/\\\n  --/g' | sed 's/# //g' | sed 's/#+ /\n######################\n#+ /g' > \
    ${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.friendly.sh

echo "f1=${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.sh;"
echo "f2=${JOB_OUTPUT_DIR}/commands.${TIMESTAMP}.friendly.sh;"

}

