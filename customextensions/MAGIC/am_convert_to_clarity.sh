#!/bin/bash

#title           : am_convert_to_clarity.sh
#description     : This will validate and convert a custom excel sample sheet to clarity compatible, it will make use of study design if provided.
#author          : Haig Djambazian
#date            : 20200114
#version         : 3.0
#usage           : sh convert_to_clarity.sh outdir process-id:studydesign project-id custom-format-input-file.xlsx study-design-file.txt


# sh am_convert_to_clarity.sh ./ process-id:SD004 project-id SC3-SM_1of1-complex-full.xlsx SC3-SD_1of1-complex-full.txt;
# file=SC3-SM_1of1-complex-full.project-id.submission.html; echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca

INPROD=true

if($INPROD); then
  PATHTOADAPTERS=/opt/gls/clarity/customextensions/Common/adapter_settings_format.txt
  PATHTOLIBRARIES=/opt/gls/clarity/customextensions/Common/library_protocol_list.csv
  PATHTOMAPCODES=/opt/gls/clarity/customextensions/MAGIC/serviceitemcode-serviceitemname-map.txt
  PATHTOMAPWORKFLOW=/opt/gls/clarity/customextensions/MAGIC/serviceworkgroup-workflow-map.txt
  PATHWORKFLOWPROTOCOLS=/opt/gls/clarity/customextensions/MAGIC/workflow-protocols.txt
else
  PATHTOADAPTERS=./adapter_settings_format.txt
  PATHTOLIBRARIES=./library_protocol_list.csv
  PATHTOMAPCODES=./serviceitemcode-serviceitemname-map.txt
  PATHTOMAPWORKFLOW=./serviceworkgroup-workflow-map.txt
  PATHWORKFLOWPROTOCOLS=./workflow-protocols.txt
fi


echo "--"
echo "output directory          $1"
echo "processid:studydesignid   $2"
echo "projectid                 $3"
echo "sample manifest           $4"
echo "study design              $5"
echo "--"

function checkindex_samplesheet {

if [[ "$1" == SI-* ]]; then
    grep -c "^$1," $PATHTOADAPTERS;
else
    I1=$(echo "$1" | awk -F'-' '{print $1}')
    I2=$(echo "$1" | awk -F'-' '{print $2}')

if [ ! -z "$I2" ]; then
   echo $(( $(grep -c "^$I1," $PATHTOADAPTERS) * $(grep -c "^$I2," $PATHTOADAPTERS) ))
else
   grep -c "^$I1," $PATHTOADAPTERS
fi
fi

}

function checklibrarytype {
  grep -c "^$1," $PATHTOLIBRARIES;
}


SAMPLE_RECEP_PROC_ID="";
PROJECT_FROM_STUDYDESIGN="";
PI_FROM_STUDYDESIGN="";

OUTDIR="$1";
SAMPLE_RECEP_PROC_ID="$2";
# PROJECT_ID_FROM_STUDYDESIGN="$3";
PROJECT_ID_FROM_STUDYDESIGN=$(echo "$3" |  tr ':' '_' | tr ' ' '_' | tr -d '(' | tr -d ')');
xlsfile="$4";
studydesignfile="$5";

mkdir -p $OUTDIR

IFS=$'\n'

resultfileid1="";
resultfileid2="";
if [ -f "$xlsfile" ]; then
    if [[ "$(basename $xlsfile)" == 92-* ]]; then
        rsp2=$(echo "$(basename $xlsfile)" | awk -F'-' '{print $2}');
        resultfileid1=92-$(($rsp2+1))-;
        resultfileid2=92-$(($rsp2+2))-;
#        echo $resultfileid1
#        echo $resultfileid2
    fi
fi



FILEFAILED=false;

if [ -f "$xlsfile" ]; then

  NEWROOT=$PROJECT_ID_FROM_STUDYDESIGN;

  TMPNAME=$OUTDIR/$NEWROOT.txt
  
  COMM=$(cat <<EOF
import warnings
import os
warnings.filterwarnings("ignore", message="numpy.dtype size changed")
import pandas as pd
df = pd.read_excel("$xlsfile",index_col=False)
df = df.replace('\n',' ', regex=True)
# df = df.replace('|','', regex=True)
df.to_csv("$TMPNAME",sep='\t',index=False,header=False)
EOF
);
  
  if($INPROD); then
    echo "$COMM" | /usr/bin/python3.5
  else
    echo "$COMM" | python3
  fi


#  B=$(cat $OUTDIR/$NEWROOT.txt | awk '/Sample Name, Pool Name/ {seen = 1} seen {print}' | perl -pe 's/[^[:ascii:]]//g' | tr -d '\r' | tail -n +2 | grep -E "Tissue|Nucleic Acid|Illumina Library|Illumina Library Pool|Sample In Pool|Skip This Line" ) # Existing Sample or Library

  B=$(cat $OUTDIR/$NEWROOT.txt | awk '/Container Name/ {seen = 1} seen {print}' | tr -d '\r' | tail -n +2 | grep -E "Tissue|Nucleic Acid|Illumina Library|Illumina Library Pool|Sample In Pool|Library In Pool|Skip This Line|Existing Sample or Library" )

else
  echo "error excel file not passed";
  FILEFAILED=false;
  false
fi

header=$(printf "ProcessLUID\tProjectLUID\tProjectName\tContainerLUID\tContainerName\tPosition\tIndex\tLibraryLUID\tLibraryProcess\tArtifactLUIDLibNorm\tArtifactNameLibNorm\tSampleLUID\tSampleName\tReference\tStart Date\tSample Tag\tTarget Cells\tLibrary Metadata ID\tSpecies\tUDF/Genome Size (Mb)\tGender\tPool Fraction\tCapture Type\tCaptureLUID\tCapture Name\tCapture REF_BED\tCapture Metadata ID\tArtifactLUIDClustering\n")

if [ -f "$xlsfile" ]; then
     
     PROJECTNAME=$PROJECT_FROM_STUDYDESIGN
     PI=$PI_FROM_STUDYDESIGN
     PROJECTID=$PROJECT_ID_FROM_STUDYDESIGN

         C=$(echo "$B");
         
         tsvfile=$OUTDIR/$NEWROOT.submission.txt
         
         rm -f $tsvfile.b $tsvfile.extra
         
         printf "UDF/Sample Type\tSample/Name\tUDF/Sample Group\tUDF/Application\tUDF/Individual ID\tUDF/Cohort ID\tContainer/Type\tContainer/Name\tSample/Well Location\tUDF/Barcode\tUDF/Carrier Type\tUDF/Carrier Name\tUDF/Carrier Coordinate\tUDF/Carrier Barcode\tUDF/Species\tUDF/Genome Size\tUDF/Gender\tUDF/Reference Genome\tUDF/Tissue Type\tUDF/Nucleic Acid Type\tUDF/Nucleic Acid Size\tUDF/Library Size\tUDF/Number in Pool\tUDF/Sample Buffer\tUDF/Volume\tUDF/Volume Units\tUDF/Sample Conc.\tUDF/Sample Conc Units\tUDF/Floor\tUDF/Area\/Room\tUDF/Freezer\tUDF/Shelf\tUDF/Tray\tUDF/Comments\tUDF/BASE64POOLDATA\n" > $tsvfile.h
         
         TUBECOUNTER=0;
         stateinpool=false;
         buffer="";

         labmaptable="";
         debugtext="";
         
         for line in $(echo "$C"); do
           IFS='|' read EMPTY_CELL SAMPLETYPE SAMPLENAME SAMPLEGROUP INDIVIDUAL_ID COHORT_ID TYPE CONTAINER WELL BARCODE TUBE_CARRIER_TYPE TUBE_CARRIER_NAME TUBE_CARRIER_BARCODE SPECIES GENOMESIZE GENDER REF TISSUETYPE NUCACIDTYPE NUCACIDSIZEINKB BUFFER VOLUME CONCENTRATION CONCUNITS LIBSIZE NUMBERINPOOL LIBTYPE INDEXSERIES INDEX ADAPTERTYPE I7INDEX I5INDEX COMMENTS <<<$(echo "$line" | tr '\t' '|');


#  0 empty

#  1 Sample_Type #*
#           SAMPLETYPE=$(echo "$line" | awk -F '\t' '{print $2}' );
#  2 Sample_Name #*
#           SAMPLENAME=$(echo "$line" | awk -F '\t' '{print $3}' |  sed 's/ - /-/g' | tr ' ' '_' | tr '.' '_'  | tr '+' 'P' | tr '/' '_' |  tr -cd '[:alnum:]_-' | sed 's/__*/_/g' | sed "s/^_//g" | sed "s/_$//g");
#  3 Sample_Group #*
#            SAMPLEGROUP=$(echo "$line" | awk -F '\t' '{print $4}'| tr -d ' ')
#  4 Individual_ID
#             INDIVIDUAL_ID=$(echo "$line" | awk -F '\t' '{print $5}');
#  5 Cohort_ID
#             COHORT_ID=$(echo "$line" | awk -F '\t' '{print $6}');
#  6 Container_Type #*
#             TYPE=$(echo "$line" | awk -F '\t' '{print $7}');
#  7 Container_Name #*
#             CONTAINER=$(echo "$line" | awk -F '\t' '{print $8}');
#  8 Well #*
#             WELL=$(echo "$line" | awk -F '\t' '{print $9}');
#  9 Container_Barcode
#             BARCODE=$(echo "$line" | awk -F '\t' '{print $10}');
# 10 Tube_Carrier_Type #*
#             TUBE_CARRIER_TYPE=$(echo "$line" | awk -F '\t' '{print $11}');
# 11 Tube_Carrier_Name #*
#             TUBE_CARRIER_NAME=$(echo "$line" | awk -F '\t' '{print $12}');
# 12 Tube_Carrier_Barcode
#             TUBE_CARRIER_BARCODE=$(echo "$line" | awk -F '\t' '{print $13}');
# 13 Species #*
#             SPECIES=$(echo "$line" | awk -F '\t' '{print $14}');
# 14 Genome_Size_in_Mb #*
#             GENOMESIZE=$(echo "$line" | awk -F '\t' '{print $15}');
# 15 Gender
#             GENDER=$(echo "$line" | awk -F '\t' '{print $16}');
# 16 Reference_Genome
#             REF=$(echo "$line" | awk -F '\t' '{print $17}');
# 17 Tissue_Type #*
#             TISSUETYPE=$(echo "$line" | awk -F '\t' '{print $18}');
# 18 Nucleic_Acid_Type #*
#             NUCACIDTYPE=$(echo "$line" | awk -F '\t' '{print $19}');
# 19 Nucleic_Acid_Size_in_Kb #*
#             NUCACIDSIZEINKB=$(echo "$line" | awk -F '\t' '{print $20}');
# 20 Buffer
#             BUFFER=$(echo "$line" | awk -F '\t' '{print $21}');
# 21 Volume_in_uL #*
#             VOLUME=$(echo "$line" | awk -F '\t' '{print $22}');
# 22 Concentration #*
#             CONCENTRATION=$(echo "$line" | awk -F '\t' '{print $23}');
# 23 Concentration_Units #*
#             CONCUNITS=$(echo "$line" | awk -F '\t' '{print $24}');
# 24 Library_Size_in_bases #*
#             LIBSIZE=$(echo "$line" | awk -F '\t' '{print $25}');
# 25 Number_in_Pool #*
#             NUMBERINPOOL=$(echo "$line" | awk -F '\t' '{print $26}');
# 26 Library_Type #*
#             LIBTYPE=$(echo "$line" | awk -F '\t' '{print $27}');
# 27 Library_Index_Series #*
#             INDEXSERIES=$(echo "$line" | awk -F '\t' '{print $28}');
# 28 Library_Index_Name #*
#             INDEX=$(echo "$line" | awk -F '\t' '{print $29}')
# 29 Adapter_Type #*
#             ADAPTERTYPE=$(echo "$line" | awk -F '\t' '{print $30}');
# 30 i7_Index #*
#             I7INDEX=$(echo "$line" | awk -F '\t' '{print $31}');
# 31 i5_Index #*
#             I5INDEX=$(echo "$line" | awk -F '\t' '{print $32}');
# 32 Comments
#             COMMENTS=$(echo "$line" | awk -F '\t' '{print $33}');

SAMPLENAMETEST=$(echo "$SAMPLENAME" | tr -cd '[:alnum:]-_' ); # underscores and dash allowed

if [ "$SAMPLENAMETEST" != "$SAMPLENAME" ]; then
    echo "Import failed due to illegal character in sample name: \"$SAMPLENAME\""
    FILEFAILED=true;
fi

MAXSNLEN=60;

if [ "${#SAMPLENAME}" -gt "$MAXSNLEN" ]; then
    echo "Import failed due to sample name longer than $MAXSNLEN characters: \"$SAMPLENAME\""
    FILEFAILED=true;
fi

if ( [ "$SAMPLETYPE" == "Illumina Library" ] || [ "$SAMPLETYPE" == "Sample In Pool" ] || [ "$SAMPLETYPE" == "Library In Pool" ] || [ "$SAMPLETYPE" == "Nucleic Acid" ] || [ "$SAMPLETYPE" == "Tissue" ] ) && [ "$SPECIES" == "" ]; then
    echo "Import failed due to species field missing"
    FILEFAILED=true;
fi

# No manual fixing
# SAMPLENAME=$(echo "$SAMPLENAME" |  sed 's/ - /-/g' | tr ' ' '_' | tr '.' '_'  | tr '+' 'P' | tr '/' '_' |  tr -cd '[:alnum:]_-' | sed 's/__*/_/g' | sed "s/^_//g" | sed "s/_$//g");

if [ "$SAMPLEGROUP" != "" ]; then
   SAMPLEGROUP=$(echo "$line" | awk -F '\t' '{print $4}' | tr -d ' '| sed -e 's/\(.\)/\1\n/g' | grep -v "^$" | awk '{print "'$SAMPLE_RECEP_PROC_ID':"$0}' | tr '\n' ',' | rev | cut -c 2- | rev);
fi

LIBTYPE=$(echo "$LIBTYPE" | awk -F' / ' '{print $1}'); # remove extra information

function mapworkflow {
    cat $PATHTOMAPWORKFLOW | grep -v "^#" | awk -F'\t' '$1=="'$1'"{print $2}'
}

function convertcodes {
   cat $PATHTOMAPCODES | grep -v "^#" | awk -F'\t' '$2=="'$1'"{print $1}'
}


labmaptableline="";


function setapplication {

APPLICATION="";
if [ -f "$studydesignfile" ]; then

  SAMPLESETCOL=$(cat $studydesignfile | sed 's/","/\t/g' | cut -c 2- | rev | cut -c 2- | rev | head -n 1 | tr '\t' '\n' | awk '{print NR"|"$0}' | grep '|Sample Set$' | awk -F'|' '{print $1}');

  SERVICEITEMCODECOL=$(cat $studydesignfile | sed 's/","/\t/g' | cut -c 2- | rev | cut -c 2- | rev | head -n 1 | tr '\t' '\n' | \
  awk '{print NR"|"$0}' | grep '|Service Item Code$' | awk -F'|' '{print $1}');

  QUOTENUMBERCOL=$(cat $studydesignfile | sed 's/","/\t/g' | cut -c 2- | rev | cut -c 2- | rev | head -n 1 | tr '\t' '\n' | \
  awk '{print NR"|"$0}' | grep '|Quote Number$' | awk -F'|' '{print $1}');

  cols=$(cat $studydesignfile | sed 's/","/\t/g' | cut -c 2- | rev | cut -c 2- | rev | grep -v "^$" | tail -n+2 | awk -F'\t' '{print $'$SAMPLESETCOL'"\t"$'$SERVICEITEMCODECOL'"\t"$'$QUOTENUMBERCOL'}');

   if [ "$SAMPLEGROUP" != "" ]; then

      debugtext=$(printf "$debugtext\n$SAMPLENAME:$SAMPLEGROUP:$TYPE:$CONTAINER:$WELL\n");
      
      SAMPLEGROUPtmp=$(echo "$SAMPLEGROUP"| sed "s/$SAMPLE_RECEP_PROC_ID://g" | tr -d ',')
      
      labmaptablelinetmp="$SAMPLETYPE|$TYPE|$CONTAINER|$WELL|$SAMPLEGROUPtmp|$SAMPLENAME";

      for sg in $(echo "$1" | tr ',' '\n' | awk -F':' '{print $3}' | grep -v "^$"); do
           
           QUOTEtmp=$(echo "$cols" | awk -F'\t' '$1=="'$sg'"{print $3}' | sort -u)
           
           scs=$(for sc in $(echo "$cols" | awk -F'\t' '$1=="'$sg'"{print $2}' ); do
               convertcodes $sc;
           done | sort | tr '\n' '+' | rev | cut -c 2- | rev);

           scs_tmp=$(for sc in $(echo "$cols" | awk -F'\t' '$1=="'$sg'"{print $2}' ); do
               convertcodes $sc;
           done | sort)

           wn=$(for scn in $(echo "$scs"); do
               mapworkflow $scn;
           done | grep -v "^$" | tr '\n' ',' | rev | cut -c 2- | rev);

           wn_tmp=$(for scn in $(echo "$scs"); do
               mapworkflow $scn;
           done | grep -v "^$");

           if [ "$wn" != "" ]; then           
               DT=$(for l in $(echo "$cols" | awk -F'\t' '$1=="'$sg'"{print $2}'); do
                   echo "($l) $(   cat $PATHTOMAPCODES | grep -v "^#" | awk -F'\t' '$2=="'$l'"{print $3}')";
               done | awk '{print "\t"$0}';
               echo "$scs_tmp" | awk '{print "\t\t"$0}';
               echo "$scs" | awk '{print "\t\t\t"$0}';
               echo "$wn_tmp" | awk '{print "\t\t\t\t" $0}';
               echo " ";
             );
             debugtext=$(printf "$debugtext\n$DT\n");
           fi

           if [ "$wn" != "" ]; then
               if [ "$APPLICATION" == "" ]; then
                   if [ "$(echo "$wn" | tr ',' '\n' | grep -c 'Aggregate')" == "1" ]; then
                       APPLICATION=$(echo "$wn" | tr ',' '\n' | grep 'Aggregate');
                   else
                       APPLICATION=$wn;
                   fi
               else
                   if [ "$(echo "$wn" | tr ',' '\n' | grep -c 'Aggregate')" == "1" ]; then
                       APPLICATION=$APPLICATION,$(echo "$wn" | tr ',' '\n' | grep 'Aggregate');
                   else
                       APPLICATION=$APPLICATION,$wn;
                   fi

               fi
               wfname=$(echo "$wn" | awk -F':' '{print $1}' | sort -u);          
               labmaptableline="$labmaptablelinetmp|$wn|$wfname|$QUOTEtmp";
           else
               labmaptableline="$labmaptablelinetmp|N/A|N/A|$QUOTEtmp";
           fi
           labmaptable=$(printf "$labmaptable\n$labmaptableline")

       done
   fi

fi
}


if [ ! -z "$VOLUME" ]; then
  VOLUNITS="uL"
else
  VOLUNITS=""
fi

WELLCARRIER=""

             if [ "$SAMPLETYPE" == "" ]; then
                 continue
             fi

             if [ "$SAMPLETYPE" == "Existing Sample or Library" ]; then
                  setapplication $SAMPLEGROUP
                  printf "$SAMPLETYPE\t$SAMPLENAME\t$SAMPLEGROUP\t$APPLICATION\n" >> $tsvfile.extra
             fi

             if [ "$SAMPLETYPE" == "Skip This Line" ]; then
                 continue
             fi

#             if [ -z "$(echo $INDEXSERIES | grep IDT )" ]; then
#                 :
#             else
#                 INDEXtmp=$INDEX;
#                 INDEX="IDT7"$(printf '%02i' "$INDEXtmp")"-IDT5"$(printf '%02i' "$INDEXtmp")
#             fi

             if ($stateinpool); then
               if [ "$SAMPLETYPE" != "Sample In Pool" ] && [ "$SAMPLETYPE" != "Library In Pool" ]; then

                 # exitpool
                 BASE64POOLDATA='data:text/txt;base64,'$(echo "$buffer" | base64 | tr -d '\n' | tr -d ' ');
                 if [ "$TYPE_P" == "Tube" ]; then
                     WELLCLARITY="1:1"
                     let TUBECOUNTER=$TUBECOUNTER+1;
                     if [ "$TUBE_CARRIER_TYPE_P" == "96 tubes rack" ]; then
                        WELLCARRIER=$(echo "$WELL_P" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     else
                        if [ "$CONTAINER_P" == "" ]; then
                            CONTAINER_P=$(printf '%04i' "$TUBECOUNTER")_$SAMPLENAME_P
                        fi
                     fi
                     if [ "$TUBE_CARRIER_TYPE_P" == "Box (10x10)" ] || [ "$TUBE_CARRIER_TYPE_P" == "Box (9x9)" ]; then
                        WELLCARRIER=$WELL_P;  
                     fi
                 else
                     WELLCLARITY=$(echo "$WELL_P" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     WELLCARRIER=""
                 fi
                 printf "$SAMPLETYPE_P\t$SAMPLENAME_P\t$SAMPLEGROUP_P\t$APPLICATION_P\t$INDIVIDUAL_ID_P\t$COHORT_ID_P\t$TYPE_P\t$CONTAINER_P\t$WELLCLARITY\t$BARCODE_P\t$TUBE_CARRIER_TYPE_P\t$TUBE_CARRIER_NAME_P\t$WELLCARRIER\t$TUBE_CARRIER_BARCODE_P\t\t\t\t\t\t\t\t$LIBSIZE_P\t$NUMBERINPOOL_P\t$BUFFER_P\t$VOLUME_P\t$VOLUNITS_P\t$CONCENTRATION_P\t$CONCUNITS_P\t\t\t\t\t\t$COMMENTS_P\t$BASE64POOLDATA\n" >> $tsvfile.b
                 stateinpool=false
                 buffer=""

               fi
             
             fi

             if [ "$SAMPLETYPE" == "Illumina Library Pool" ]; then
                   # enterpool
                   stateinpool=true
                   buffer="$header"
                   
                   setapplication $SAMPLEGROUP

                   SAMPLETYPE_P=$SAMPLETYPE;
                   SAMPLENAME_P=$SAMPLENAME;
                   SAMPLEGROUP_P=$SAMPLEGROUP;
                   APPLICATION_P=$APPLICATION
                   TYPE_P=$TYPE;
                   CONTAINER_P=$CONTAINER;
                   WELL_P=$WELL;
                   BARCODE_P=$BARCODE;
                   REF_P=$REF;
                   VOLUME_P=$VOLUME;
                   VOLUNITS_P=$VOLUNITS
                   NUMBERINPOOL_P=$NUMBERINPOOL;
                   CONCENTRATION_P=$CONCENTRATION;
                   CONCUNITS_P=$CONCUNITS;
                   BARCODE_P=$BARCODE;
                   LIBSIZE_P=$LIBSIZE;
                   TUBE_CARRIER_TYPE_P=$TUBE_CARRIER_TYPE;
                   TUBE_CARRIER_NAME_P=$TUBE_CARRIER_NAME;
                   TUBE_CARRIER_BARCODE_P=$TUBE_CARRIER_BARCODE;
                   COMMENTS_P=$COMMENTS;
                   BUFFER_P=$BUFFER;
                   FRACTION=$( echo "scale=6; 1/$NUMBERINPOOL_P" | bc |  awk '{printf "%0.6f", $0}' );
                   
                   # LIBTYPE_P=$LIBTYPE;
                   # INDEXSERIES_P=$INDEXSERIES;
                   # INDEX_P=$INDEX;
                   
             fi

             if [ "$SAMPLETYPE" == "Sample In Pool" ] || [ "$SAMPLETYPE" == "Library In Pool" ]; then
                 if [ "$(checkindex_samplesheet $INDEX)" == "0" ]; then
                    echo "Import failed due to undefined index: \"$INDEX\""
                    FILEFAILED=true;
                 fi
                 if [ "$(checklibrarytype $LIBTYPE)" == "0" ]; then
                    echo "Import failed due to undefined library type: \"$LIBTYPE\""
                    FILEFAILED=true;
                 fi

                  buffer="$buffer"$(printf "\nN/A\tN/A\tN/A\tN/A\tN/A\tN/A\t$INDEX\tN/A\t$LIBTYPE\tN/A\tN/A\tN/A\t$SAMPLENAME\t$REF\tN/A\tN/A\tN/A\tN/A\t$SPECIES\t$GENOMESIZE\t$GENDER\t$FRACTION\tLibrary Pool\tN/A\tN/A\tN/A\tN/A\tN/A");

             fi
           
             if [ "$SAMPLETYPE" == "Illumina Library" ]; then
                 FRACTION=1
                 if [ "$(checkindex_samplesheet $INDEX)" == "0" ]; then
                    echo "Import failed due to undefined index: \"$INDEX\""
                    FILEFAILED=true;
                 fi
                 if [ "$(checklibrarytype $LIBTYPE)" == "0" ]; then
                    echo "Import failed due to undefined library type: \"$LIBTYPE\""
                    FILEFAILED=true;
                 fi
                 BASE64POOLDATA='data:text/txt;base64,'$(printf "$header\nN/A\tN/A\tN/A\tN/A\tN/A\tN/A\t$INDEX\tN/A\t$LIBTYPE\tN/A\tN/A\tN/A\t$SAMPLENAME\t$REF\tN/A\tN/A\tN/A\tN/A\t$SPECIES\t$GENOMESIZE\t$GENDER\t$FRACTION\tN/A\tN/A\tN/A\tN/A\tN/A\tN/A" | base64 | tr -d '\n' | tr -d ' ');

                 if [ "$TYPE" == "Tube" ]; then
                     WELLCLARITY="1:1"
                     let TUBECOUNTER=$TUBECOUNTER+1;
                     if [ "$TUBE_CARRIER_TYPE" == "96 tubes rack" ]; then
                        WELLCARRIER=$(echo "$WELL" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     else
                        if [ "$CONTAINER" == "" ]; then
                            CONTAINER=$(printf '%04i' "$TUBECOUNTER")_$SAMPLENAME
                        fi
                     fi
                     if [ "$TUBE_CARRIER_TYPE" == "Box (10x10)" ] || [ "$TUBE_CARRIER_TYPE" == "Box (9x9)" ]; then                     
                        WELLCARRIER=$WELL;
                     fi
                 else
                     WELLCLARITY=$(echo "$WELL" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     WELLCARRIER=""
                 fi

                 setapplication $SAMPLEGROUP

                 printf "$SAMPLETYPE\t$SAMPLENAME\t$SAMPLEGROUP\t$APPLICATION\t$INDIVIDUAL_ID\t$COHORT_ID\t$TYPE\t$CONTAINER\t$WELLCLARITY\t$BARCODE\t$TUBE_CARRIER_TYPE\t$TUBE_CARRIER_NAME\t$WELLCARRIER\t$TUBE_CARRIER_BARCODE\t$SPECIES\t$GENOMESIZE\t$GENDER\t$REF\t$TISSUETYPE\t$NUCACIDTYPE\t$NUCACIDSIZEINKB\t$LIBSIZE\t1\t$BUFFER\t$VOLUME\t$VOLUNITS\t$CONCENTRATION\t$CONCUNITS\t\t\t\t\t\t$COMMENTS\t$BASE64POOLDATA\n" >> $tsvfile.b

             fi

             if [ "$SAMPLETYPE" == "Nucleic Acid" ]; then
                 BASE64POOLDATA=""
                 if [ "$TYPE" == "Tube" ]; then
                     WELLCLARITY="1:1"
                     let TUBECOUNTER=$TUBECOUNTER+1;
                     if [ "$TUBE_CARRIER_TYPE" == "96 tubes rack" ]; then
                        WELLCARRIER=$(echo "$WELL" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     else
                        if [ "$CONTAINER" == "" ]; then
                            CONTAINER=$(printf '%04i' "$TUBECOUNTER")_$SAMPLENAME
                        fi
                     fi
                     if [ "$TUBE_CARRIER_TYPE" == "Box (10x10)" ] || [ "$TUBE_CARRIER_TYPE" == "Box (9x9)" ]; then                     
                        WELLCARRIER=$WELL;
                     fi
                 else
                     WELLCLARITY=$(echo "$WELL" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     WELLCARRIER=""
                 fi

                 setapplication $SAMPLEGROUP

                 printf "$SAMPLETYPE\t$SAMPLENAME\t$SAMPLEGROUP\t$APPLICATION\t$INDIVIDUAL_ID\t$COHORT_ID\t$TYPE\t$CONTAINER\t$WELLCLARITY\t$BARCODE\t$TUBE_CARRIER_TYPE\t$TUBE_CARRIER_NAME\t$WELLCARRIER\t$TUBE_CARRIER_BARCODE\t$SPECIES\t$GENOMESIZE\t$GENDER\t$REF\t$TISSUETYPE\t$NUCACIDTYPE\t$NUCACIDSIZEINKB\t\t\t$BUFFER\t$VOLUME\t$VOLUNITS\t$CONCENTRATION\t$CONCUNITS\t\t\t\t\t\t$COMMENTS\t\n" >> $tsvfile.b

             fi

             if [ "$SAMPLETYPE" == "Tissue" ]; then
                 BASE64POOLDATA=""
                 if [ "$TYPE" == "Tube" ]; then
                     WELLCLARITY="1:1"
                     let TUBECOUNTER=$TUBECOUNTER+1;
                     if [ "$TUBE_CARRIER_TYPE" == "96 tubes rack" ]; then
                        WELLCARRIER=$(echo "$WELL" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     else
                        if [ "$CONTAINER" == "" ]; then
                            CONTAINER=$(printf '%04i' "$TUBECOUNTER")_$SAMPLENAME
                        fi
                     fi
                     if [ "$TUBE_CARRIER_TYPE" == "Box (10x10)" ] || [ "$TUBE_CARRIER_TYPE" == "Box (9x9)" ]; then                     
                        WELLCARRIER=$WELL;
                     fi
                 else
                     WELLCLARITY=$(echo "$WELL" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     WELLCARRIER=""
                 fi

                 setapplication $SAMPLEGROUP

                 printf "$SAMPLETYPE\t$SAMPLENAME\t$SAMPLEGROUP\t$APPLICATION\t$INDIVIDUAL_ID\t$COHORT_ID\t$TYPE\t$CONTAINER\t$WELLCLARITY\t$BARCODE\t$TUBE_CARRIER_TYPE\t$TUBE_CARRIER_NAME\t$WELLCARRIER\t$TUBE_CARRIER_BARCODE\t$SPECIES\t$GENOMESIZE\t$GENDER\t$REF\t$TISSUETYPE\t$NUCACIDTYPE\t$NUCACIDSIZEINKB\t\t\t$BUFFER\t$VOLUME\t$VOLUNITS\t$CONCENTRATION\t$CONCUNITS\t\t\t\t\t\t$COMMENTS\t\n" >> $tsvfile.b
             fi

         done

         # found last line
         
         if ($stateinpool); then
                 
                 # exitpool
                 BASE64POOLDATA='data:text/txt;base64,'$(echo "$buffer" | base64 | tr -d '\n' | tr -d ' ');

                 if [ "$TYPE_P" == "Tube" ]; then
                     WELLCLARITY="1:1"
                     let TUBECOUNTER=$TUBECOUNTER+1;
                     if [ "$TUBE_CARRIER_TYPE_P" == "96 tubes rack" ]; then
                        WELLCARRIER=$(echo "$WELL_P" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     else
                        if [ "$CONTAINER_P" == "" ]; then
                            CONTAINER_P=$(printf '%04i' "$TUBECOUNTER")_$CONTAINER_P
                        fi
                     fi
                     if [ "$TUBE_CARRIER_TYPE_P" == "Box (10x10)" ] || [ "$TUBE_CARRIER_TYPE" == "Box (9x9)" ]; then
                        WELLCARRIER=$WELL_P;
                     fi
                 else
                     WELLCLARITY=$(echo "$WELL_P" | sed 's/10/1~/g' | tr '0' ':' | sed 's/1~/:10/g' | sed 's/11/:11/g' | sed 's/12/:12/g')
                     WELLCARRIER=""
                 fi
                 
                 printf "$SAMPLETYPE_P\t$SAMPLENAME_P\t$SAMPLEGROUP_P\t$APPLICATION_P\t$INDIVIDUAL_ID_P\t$COHORT_ID_P\t$TYPE_P\t$CONTAINER_P\t$WELLCLARITY\t$BARCODE_P\t$TUBE_CARRIER_TYPE_P\t$TUBE_CARRIER_NAME_P\t$WELLCARRIER\t$TUBE_CARRIER_BARCODE_P\t\t\t\t\t\t\t\t$LIBSIZE_P\t$NUMBERINPOOL_P\t$BUFFER_P\t$VOLUME_P\t$VOLUNITS_P\t$CONCENTRATION_P\t$CONCUNITS_P\t\t\t\t\t\t$COMMENTS_P\t$BASE64POOLDATA\n" >> $tsvfile.b
                 stateinpool=false
                 buffer=""
             
         fi

if [ -f "$studydesignfile" ]; then
   printf "<!DOCTYPE html>\n" > ${tsvfile%.*}.html.tmp; # first write erases the file
   printf "<html>\n<head>\n" >> ${tsvfile%.*}.html.tmp;
   printf "<style>\n" >> ${tsvfile%.*}.html.tmp;
   printf "table, th, td {border: 1px solid black;\n border-collapse: collapse;}\n" >> ${tsvfile%.*}.html.tmp;
   printf "table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; font-size:75%%; }\n" >> ${tsvfile%.*}.html.tmp;
   printf "table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }\n" >> ${tsvfile%.*}.html.tmp;
   printf "table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }\n" >> ${tsvfile%.*}.html.tmp;
   printf "</style>\n" >> ${tsvfile%.*}.html.tmp;

   echo "<script type=\"text/javascript\">" >> ${tsvfile%.*}.html.tmp;
   echo "function popBase64(base64URL){" >> ${tsvfile%.*}.html.tmp;
   echo "    var win = window.open();" >> ${tsvfile%.*}.html.tmp;
   echo "    win.document.write('<iframe src=\"' + base64URL  + '\" frameborder=\"0\" style=\"border:0; top:0px; left:0px; bottom:0px; right:0px; width:100%; height:100%;\" allowfullscreen></iframe>');" >> ${tsvfile%.*}.html.tmp;
   echo "    win.document.close();" >> ${tsvfile%.*}.html.tmp;
   echo "}" >> ${tsvfile%.*}.html.tmp;
   echo "</script>" >> ${tsvfile%.*}.html.tmp;
   
   printf "</head>\n" >> ${tsvfile%.*}.html.tmp;
   printf "<body>\n" >> ${tsvfile%.*}.html.tmp;


   printf "<!DOCTYPE html>\n" > ${tsvfile%.*}.html.tmp222; # first write erases the file
   printf "<html>\n<head>\n" >> ${tsvfile%.*}.html.tmp222;
   printf "<style>\n" >> ${tsvfile%.*}.html.tmp222;
   printf "table, th, td {border: 1px solid black;\n border-collapse: collapse;}\n" >> ${tsvfile%.*}.html.tmp222;
   printf "table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; font-size:75%%; }\n" >> ${tsvfile%.*}.html.tmp222;
   printf "table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }\n" >> ${tsvfile%.*}.html.tmp222;
   printf "table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }\n" >> ${tsvfile%.*}.html.tmp222;
   printf "</style>\n" >> ${tsvfile%.*}.html.tmp222;
   printf "</head>\n" >> ${tsvfile%.*}.html.tmp222;
   printf "<body>\n" >> ${tsvfile%.*}.html.tmp222;
   printf "<table class=\"style2\">\n" >> ${tsvfile%.*}.html.tmp222;
   printf "<tr><td colspan=\"20\" height=\"50\">LIMS Sample Reception process ID: $(echo "$SAMPLE_RECEP_PROC_ID" | awk -F":" '{print $1}')<br>Study Design ID: $(echo "$SAMPLE_RECEP_PROC_ID" | awk -F":" '{print $2}')</td></tr>\n">> ${tsvfile%.*}.html.tmp222;
   printf "<tr><td colspan=\"20\">Study Design: $(basename $studydesignfile)</td></tr>\n" >> ${tsvfile%.*}.html.tmp222;
   cat "$studydesignfile" | head -n 1 | cut -c 2- | rev | cut -c 2- | rev | sed 's|","|</th><th>|g' | awk '{print "<tr><th>"$0"</th></tr>"}' >> ${tsvfile%.*}.html.tmp222;
   cat "$studydesignfile" | tail -n +2 | cut -c 2- | rev | cut -c 2- | rev | sed 's|","|</td><td>|g' | awk '{print "<tr><td>"$0"</td></tr>"}' >> ${tsvfile%.*}.html.tmp222;
   printf "</table>\n" >> ${tsvfile%.*}.html.tmp222;
   printf "</body></html>\n" >> ${tsvfile%.*}.html.tmp222;


   printf "<!DOCTYPE html>\n" > ${tsvfile%.*}.html.tmp333; # first write erases the file
   printf "<html>\n<head>\n" >> ${tsvfile%.*}.html.tmp333;
   printf "</head>\n" >> ${tsvfile%.*}.html.tmp333;
   printf "<body>\n" >> ${tsvfile%.*}.html.tmp333;
   printf "<pre>\n" >> ${tsvfile%.*}.html.tmp333;
   echo "$debugtext" >> ${tsvfile%.*}.html.tmp333;
   printf "</pre>\n" >> ${tsvfile%.*}.html.tmp333;
   printf "</body></html>\n" >> ${tsvfile%.*}.html.tmp333;


   TOTALWF=$(echo "$labmaptable" | awk -F'|' '{print $8}' | sort -u | grep -v "^$"| wc -l);
   WFi=1;
   printf "<table class=\"style2\">\n" >> ${tsvfile%.*}.html.tmp;

       printf "<tr><td colspan=\"9\" height=\"50\">"$(date)"<br>LIMS Sample Reception process ID: $(echo "$SAMPLE_RECEP_PROC_ID" | awk -F":" '{print $1}')<br>Study Design ID: $(echo "$SAMPLE_RECEP_PROC_ID" | awk -F":" '{print $2}')<br>\n" >> ${tsvfile%.*}.html.tmp;

       printf "<button style=\"padding: 1px 2px;cursor: pointer;\" type=\"button\" onclick=\"popBase64('data:text/html;base64,"$(base64 ${tsvfile%.*}.html.tmp222 | tr -d '\n')"')\">Show Study Design</button><br>\n" >> ${tsvfile%.*}.html.tmp;

       printf "<button style=\"padding: 1px 2px;cursor: pointer;\" type=\"button\" onclick=\"popBase64('data:text/html;base64,"$(base64 ${tsvfile%.*}.html.tmp333 | tr -d '\n')"')\">Debug Trace</button><br>\n" >> ${tsvfile%.*}.html.tmp;

       printf "</td></tr>\n">> ${tsvfile%.*}.html.tmp;

       printf "<tr><th>Containers<br>Shipped</th><td colspan=\"8\">$(echo "$labmaptable" | grep -v "^$" | awk -F'|'  '{print $3 " (" $2")"}' | sort -u | awk '{print $0"<br>"}')</td></tr>\n" >> ${tsvfile%.*}.html.tmp;

   for WF in $(echo "$labmaptable" | awk -F'|' '{print $8}' | sort -u); do
       printf "<tr><td colspan=\"9\" height=\"50\">Workflow ($WFi/$TOTALWF)</td></tr>\n" >> ${tsvfile%.*}.html.tmp;
       let WFi=$WFi+1;
       printf "<tr><th>Workflow<br>Name</th><td colspan=\"9\">$WF</td></tr>\n" >> ${tsvfile%.*}.html.tmp;
       printf "<tr><th>Workflow<br>Protocols</th><td colspan=\"9\">$(cat $PATHWORKFLOWPROTOCOLS | awk -F'\t' '$1=="'$WF'"{print $2}' | sed 's|:|<br>|g')</td></tr>\n" >> ${tsvfile%.*}.html.tmp;
       cnt=1;
       totalcnt=$(echo "$labmaptable" | awk -F'|' '$8=="'$WF'"{print $0}' | wc -l)
       printf "<tr><td>$totalcnt samples</td><th>Sample Type</th><th>Container Type</th><th>Container Name</th><th>Well</th><th>Sample Group</th><th>Sample Name</th><th>Starting Workflow:Protocol:Step</th><th>Quote Number</th></tr>\n" >> ${tsvfile%.*}.html.tmp;
       for aline in $(echo "$labmaptable" | awk -F'|' '$8=="'$WF'"{print $1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7"|"$9}'); do
           printf "<tr><td>$cnt</td><td>"$(echo "$aline" | sed "s/|/<\/td><td>/g" | sed "s|,|<br>|g")"</td></tr>\n" >> ${tsvfile%.*}.html.tmp;
           let cnt=$cnt+1;
       done
   done;
   printf "</table>\n" >> ${tsvfile%.*}.html.tmp;

   printf "</body></html>\n" >> ${tsvfile%.*}.html.tmp;

   rm ${tsvfile%.*}.html.tmp222
   rm ${tsvfile%.*}.html.tmp333
   
fi

echo "<TABLE HEADER>" > $tsvfile
cat $tsvfile.h >> $tsvfile
echo "</TABLE HEADER>" >> $tsvfile
echo "<SAMPLE ENTRIES>" >> $tsvfile
if [ -f "$tsvfile.b" ];then
   cat $tsvfile.b >> $tsvfile
fi
echo "</SAMPLE ENTRIES>" >> $tsvfile
if [ -f "$tsvfile.extra" ];then
    cat $tsvfile.extra >> $tsvfile
fi
xlsxfile=${tsvfile%.*}.xlsx

NCOL=$(cat $tsvfile | tail -n +2 | head -n 1 | tr '\t' '\n' | wc -l)

COMM=$(cat <<EOF
import warnings
warnings.filterwarnings("ignore", message="numpy.dtype size changed")
import pandas as pd
df = pd.read_csv("$tsvfile", sep='\t', header=None,index_col=False,names=list(range($NCOL)))
df.to_excel("$xlsxfile",index=False,header=False)
EOF
);

if($FILEFAILED); then
  :
else

  if($INPROD); then
    echo "$COMM" | /usr/bin/python3.5
  else
    echo "$COMM" | python3;
  fi
  mv $xlsxfile $resultfileid1$(basename $xlsxfile);
  if [ -f "${tsvfile%.*}.html.tmp" ];then
      mv ${tsvfile%.*}.html.tmp $resultfileid2$(basename ${tsvfile%.*}).html
      rm -f ${tsvfile%.*}.html.tmp
  fi
fi

rm -f $tsvfile $tsvfile.h $tsvfile.b $tsvfile.extra
rm -f $TMPNAME 

if($FILEFAILED); then
  false
else
  true
fi

fi

