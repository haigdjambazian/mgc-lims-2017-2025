#!/bin/bash


PASSWORD=; USERNAME=; # bravoprod

# on dev
#SYSTEMPATH=/lb/robot/GeneTitan/dev/bravoprocess/system/axiomreports;
#FINALAXIOMREPORT=/lb/robot/GeneTitan/dev/bravoprocess/AxiomDetailedReport.txt;
#FINALAXIOMFASTREPORT=/lb/robot/GeneTitan/dev/bravoprocess/AxiomTableReport.html;

# on prod
SYSTEMPATH=/lb/robot/GeneTitan/bravoprocess/system/axiomreports;
FINALAXIOMREPORT=/lb/robot/GeneTitan/bravoprocess/AxiomDetailedReport.txt;
FINALAXIOMFASTREPORT=/lb/robot/GeneTitan/bravoprocess/AxiomTableReport.html;

###################################################################################
###################################             ###################################
###################################  RUN AXIOM  ###################################
###################################             ###################################
###################################################################################

function runaxiom {

axiomsteps="ax1|DNA Samples QC
ax2|Sample Normalization Generic
ax3|Sample Normalization Extra Plate
ax4|DNA Amplification McGill 1.1
ax5|Fragmentation  (Affy) McGill 1.0
ax6|Centrifugation,Drying and Resuspension McGill 1.1
ax7|Hybridization Preparation McGill 1.0
ax8|Hybridization Sample QC McGill 1.0
ax9|Denaturation and Hybridization McGill 1.0
ax10|GeneTitan Reagent tray Preparation McGill 1.0
ax11|Axiom Scanning QC
ax12|Axiom Analysis QC"


# cat axiom_report.txt | sort -t $'\t' -nk4 | tr '\t' '~' | column -s'~' -t | less -S   

# join -1 2 -2 1 -a1 -t $'\t' -o '1.1,0,2.2' <(echo "$KEY" | sort -k1 ) <(echo "$DAT" | sort -k1) 

REPORTOUT=$SYSTEMPATH/axiom_report.txt
rm -f $REPORTOUT.t0

TAB="$(printf '\t')"
IFS=$'\n'

echo "Date In
Time In
Date Out
Time Out
Incubator
Incubator Temperature, C
After Amplification
Freezer Location" \
| awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/ax4_keys

echo "gForce
Centrifugation time, min
Inverted drying time, min
Incubator
Incubator Temperature
Drying Time, min
Resuspension Buffer Volume, uL
Vortex Duration, min
Vortex Speed, rpm" \
| awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/ax6_keys

echo "Concentration
Mass" \
| awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/ax8_keys

echo "Transfer Amount, uL
Array Type
Barcode
Library Package" \
| awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/ax9_keys

echo "% of passing samples
Affymetrix Plate Barcode
Affymetrix Plate Peg Wellposition
Average Call Rate Passing Samples
DQC
QC Call Rate
QC Computed Gender
QC Het Rate" \
| awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/ax12_keys

# echo "" | awk '{printf("%i\t%s\n", NR,$0)}'  | sed 's/%/Percent/g' | sort -t $'\t' -k2 > /dev/shm/axX_keys

startstep='Sample Normalization Generic'

function init_stack {
  stack="";
}
function push_stack {
  stack=$(printf "$1\n$stack");
}
function head_stack {
  echo "$stack" | head -n 1;
}
function pop_stack {
  stack=$(echo "$stack" | tail -n+2);
}
function print_stack {
  if [ -z "$stack" ]; then 
    echo "empty stack";
  else
    echo "$stack" | awk '{print "# "$0}';
  fi
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


header=$(printf "\
Project Name\tSample Name\t\
Step1 Name\tProcess ID\tPlate Name\tWell\tArtifact ID\t\
Step2 Name\tProcess ID\tPlate Name\tWell\tArtifact ID\tKit Name\tKit Barcode\tKit Lot\t\
Date In\tTime In\tDate Out\tTime Out\tIncubator\tIncubator Temperature, C\tAfter Amplification\tFreezer Location\t\
Step3 Name\tProcess ID\tPlate Name\tWell\tArtifact ID\tKit Name\tKit Barcode\tKit Lot\tKit Name\tKit Barcode\tKit Lot\t\
Step4 Name\tProcess ID\tArtifact ID\tgForce\tCentrigugation time, min\tInverted drying time, min\tIncubator\tIncubator Temperature\t\
Drying Time, min\tResuspension Buffer Volume, uL\tVortex Duration, min\tVortex Speed, rpm\t\
Step5 Name\tProcess ID\tPlate Name\tWell\tArtifact ID\tKit Name\tKit Barcode\tKit Lot\tKit Name\tKit Barcode\tKit Lot\t\
Step6 Name\tProcess ID\tArtifact ID\tKit Name\tKit Barcode\tKit Lot\tConcentration\tMass\tQC\t\
Step7 Name\tProcess ID\tPlate Name\tWell\tArtifact ID\tTransfer Amount, uL\tArray Type\tBarcode\tLibrary Package\tQC\t\
Step8 Name\tProcess ID\tArtifact ID\tKit Name\tKit Barcode\tKit Lot\tKit Name\tKit Barcode\tKit Lot\t\
Step9 Name\tProcess ID\tArtifact ID\t\
Step10 Name\tProcess ID\tPlate Name\tWell\tArtifact ID\t%% of passing samples\tAffymetrix Plate Barcode\tAffymetrix Plate Peg Wellposition\t\
Average Call Rate Passing Samples\tDQC\tQC Call Rate\tQC Computed Gender\tQC Het Rate\tQC\
\n");



thisrootprocessoverride=24-16894

a=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select p.luid, p.workstatus, pt.displayname from process p
join processtype pt on p.typeid = pt.typeid
where pt.displayname like '$startstep' order by 1 DESC ) TO STDOUT with delimiter '$TAB';
EOF
);

for thisrootprocess in $( echo "$a" | awk '{print $1}'); do

# grep -v -E "24-11660|24-11681|24-29423|24-6518|24-6518|24-30226|24-29945|24-28937|24-30226|24-28932"
# thisrootprocess=$thisrootprocessoverride

b=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
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

thisprocess=$thisrootprocess;

for thisrootline in $( echo "$b"); do

printf "\n"

init_stack

thisinputanalyte=$(echo "$thisrootline" | awk '{print $2}');
thisoutputanalyte=$(echo "$thisrootline" | awk '{print $3}');

csuba=$(psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select a.luid, s.name, p.name as "Project name:" from sample s
join project p using (projectid)
join artifact_sample_map asm using (processid)
join artifact a using (artifactid)
where a.luid = '$thisoutputanalyte' ) TO STDOUT with delimiter '$TAB';
EOF
);
echo "$csuba"


if [ -z "$csuba" ]; then
csuba=$(psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select a.luid, s.name from sample s
join artifact_sample_map asm using (processid)
join artifact a using (artifactid)
where a.luid = '$thisoutputanalyte' ) TO STDOUT with delimiter '$TAB';
EOF
);
  SAMPLENAME=$(echo "$csuba" | awk -F'\t' '{print $2}')
  PROJECTNAME="-";
else
  SAMPLENAME=$(echo "$csuba" | awk -F'\t' '{print $2}')
  PROJECTNAME=$(echo "$csuba" | awk -F'\t' '{print $3}')
fi;

c=$thisrootline

push_stack "2-$thisinputanalyte|$(echo "$c" | grep $thisoutputanalyte)|"$(printf -- "$PROJECTNAME\t$SAMPLENAME")"||||||||||"

while(true); do

line=$(head_stack)
# print_stack
pop_stack


thisinputanalyte=$(echo "$line" | awk -F'|' '{print $1}');
nextline=$(echo "$line" | awk -F'|' '{print $2}');
VAL_AX1=$(echo "$line" | awk -F'|' '{print $3}');
VAL_AX2=$(echo "$line" | awk -F'|' '{print $4}');
VAL_AX4=$(echo "$line" | awk -F'|' '{print $5}');
VAL_AX5=$(echo "$line" | awk -F'|' '{print $6}');
VAL_AX6=$(echo "$line" | awk -F'|' '{print $7}');
VAL_AX7=$(echo "$line" | awk -F'|' '{print $8}');
VAL_AX8=$(echo "$line" | awk -F'|' '{print $9}');
VAL_AX9=$(echo "$line" | awk -F'|' '{print $10}');
VAL_AX10=$(echo "$line" | awk -F'|' '{print $11}');
VAL_AX11=$(echo "$line" | awk -F'|' '{print $12}');
VAL_AX12=$(echo "$line" | awk -F'|' '{print $13}');

thisprocess=$(echo "$nextline" | awk '{print $1}');
thisoutputanalyte=$( echo "$nextline" | awk '{print $3}');
thisprocessname=$(echo "$nextline" | awk -F'\t' '{print $6}' | head -n 1);
tmpthisprocess=$(echo "$thisprocess" | awk -F'-' '{print $2}')

csuba=$(psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select a.luid, s.name, p.name as "Project name:" from sample s
join project p using (projectid)
join artifact_sample_map asm using (processid)
join artifact a using (artifactid)
where a.luid = '$thisoutputanalyte' ) TO STDOUT with delimiter '$TAB';
EOF
);

echo "$nextline"

if [ "$(echo "nextline" | grep -v Analyte | wc -l)" != "0" ]; then
    tmpthisoutputanalyte=$(echo "$thisoutputanalyte" | sed 's/2-//g')

###########################################################################
if [[ "$thisprocessname" == "Sample Normalization Generic" ]]; then
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}')
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'))
   VAL_AX2=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL\t$thisoutputanalyte")
fi
#######################################################################
if [[ "$thisprocessname" == "DNA Amplification McGill 1.1" ]]; then
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
    csub1=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
join reagentkit rk on rk.reagentkitid = r.reagentkitid
WHERE rs.processid = $tmpthisprocess) TO STDOUT with delimiter '$TAB';
EOF
);
    csub2=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (SELECT * FROM process_udf_view WHERE processid = $tmpthisprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);
   VALS=$(echo "$csub2" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/ax4_tmp;
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX4=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL\t$thisoutputanalyte\t")$(echo "$csub1")$(printf "\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/ax4_keys /dev/shm/ax4_tmp | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' \
| tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g');

fi
#######################################################################
if [[ "$thisprocessname" == "Fragmentation  (Affy) McGill 1.0" ]]; then
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
    csub1=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
join reagentkit rk on rk.reagentkitid = r.reagentkitid
WHERE rs.processid = $tmpthisprocess) TO STDOUT with delimiter '$TAB';
EOF
);
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}')
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'))
   VAL_AX5=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL\t$thisoutputanalyte\t")$(echo "$csub1" | tr '\n' '\t' | rev | cut -c 2- |rev)
fi
#######################################################################
if [[ "$thisprocessname" == "Hybridization Preparation McGill 1.0" ]]; then
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
    csub1=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
join reagentkit rk on rk.reagentkitid = r.reagentkitid
WHERE rs.processid = $tmpthisprocess) TO STDOUT with delimiter '$TAB';
EOF
);
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX7=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL\t$thisoutputanalyte\t")$(echo "$csub1" | tr '\n' '\t' | rev | cut -c 2- |rev);
fi
#######################################################################
if [[ "$thisprocessname" == "Denaturation and Hybridization McGill 1.0" ]]; then
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
    csub2=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (SELECT * FROM process_udf_view WHERE processid = $tmpthisprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);
    csub4=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select ast.qcflag, atp.displayname as type
from artifact a
join artifactstate ast ON a.currentstateid = ast.stateid
join artifacttype atp ON atp.typeid = a.artifacttypeid
where a.artifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
   QC=$(echo "$csub4" | grep -v "^$" | awk -F'\t' '{print $1}');
   VALS=$(echo "$csub2" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/ax9_tmp;
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX9=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL\t$thisoutputanalyte")$(printf "\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/ax9_keys /dev/shm/ax9_tmp | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' \
| tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')\
$(printf "\t")$QC;

fi
#######################################################################
if [[ "$thisprocessname" == "Axiom Analysis QC" ]]; then
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
    csub3=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisoutputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);
    csub4=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select ast.qcflag, atp.displayname as type
from artifact a
join artifactstate ast ON a.currentstateid = ast.stateid
join artifacttype atp ON atp.typeid = a.artifacttypeid
where a.artifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
   QC=$(echo "$csub4" | grep -v "^$" | awk -F'\t' '{print $1}')

   VALS=$(echo "$csub3" | awk -F'\t' '{print $4"\t"$6}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
   echo "$VALS" > /dev/shm/ax12_tmp;
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX12=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME\t$WELL\t$thisoutputanalyte")$(printf "\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/ax12_keys /dev/shm/ax12_tmp | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' \
| tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')$(printf "\t")$QC;
fi

fi

c=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
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
  tmpprocess=$(echo "$process" | awk -F'-' '{print $2}')
  cc=$(echo "$c" | grep $process)

  if [ ! -z "$cc" ]; then
    echo "$cc" | head -n 1 | awk '{printf $0"\t"}'; 
    echo "(-)"; 
  fi;

  first=true;
  
  for tmpthisoutputanalyte in $(echo "$c" | grep -v "$thisprocess" | awk '{print $3}' | grep -v '\N' | sed 's/92-//g'); do 
    if [ ! -z "$tmpthisoutputanalyte" ]; then
      ccprocessname=$(echo "$cc" | grep $process | awk -F'\t' '{print $6}' | head -n 1);
      #######################################################################
      if [[ "$ccprocessname" == "Centrifugation,Drying and Resuspension McGill 1.1" ]]; then
    csub1=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
join reagentkit rk on rk.reagentkitid = r.reagentkitid
WHERE rs.processid = $tmpprocess) TO STDOUT with delimiter '$TAB';
EOF
);
    csub2=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (SELECT * FROM process_udf_view WHERE processid = $tmpprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);
          VALS=$(echo "$csub2" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
          echo "$VALS" > /dev/shm/ax6_tmp;
          VAL_AX6=$(printf "$ccprocessname\t$process\t$tmpthisoutputanalyte")$(printf "\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/ax6_keys /dev/shm/ax6_tmp | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' \
| tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g');
fi
      #######################################################################
      if [[ "$ccprocessname" == "Hybridization Sample QC McGill 1.0" ]]; then
    csub3=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisoutputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
EOF
);
    csub4=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select ast.qcflag, atp.displayname as type
from artifact a
join artifactstate ast ON a.currentstateid = ast.stateid
join artifacttype atp ON atp.typeid = a.artifacttypeid
where a.artifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
   QC=$(echo "$csub4" | grep -v "^$" | awk -F'\t' '{print $1}')
   VALS=$(echo "$csub3" | awk -F'\t' '{print $4"\t"$6}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
          echo "$VALS" > /dev/shm/ax8_tmp;
          doit=false;
          if ($first); then first=false; doit=true; fi
          if [ ! -z "$csub3" ]; then doit=true; fi
          if($doit); then
              VAL_AX8=$(printf "$ccprocessname\t$process\t$tmpthisoutputanalyte\t")$(echo "$csub1" | grep "Axiom 2.0 Reagent Kit - Module 2-2")$(printf "\t")\
$(join -1 2 -2 1 -a1 -t "$TAB" -o '1.1,0,2.2' -e '\N' /dev/shm/ax8_keys /dev/shm/ax8_tmp | sort -nk1 | awk -F'\t' '{print $2 "\t" $3}' | awk -F'\t' '{print $2}' \
| tr '\n' '\t' |  rev | cut -c 2- | rev | sed 's/Percent/%/g')$(printf "\t")$QC;
          fi
      fi
      #######################################################################
      if [[ "$ccprocessname" == "GeneTitan Reagent tray Preparation McGill 1.0" ]]; then
          csub1=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
join reagentkit rk on rk.reagentkitid = r.reagentkitid
WHERE rs.processid = $tmpprocess) TO STDOUT with delimiter '$TAB';
EOF
);
          VAL_AX10=$(printf "$ccprocessname\t$process\t$tmpthisoutputanalyte\t")$(echo "$csub1" | tr '\n' '\t' | rev | cut -c 2- |rev);
      fi
      #######################################################################
      if [[ "$ccprocessname" == "Axiom Scanning QC" ]]; then
          VAL_AX11=$(printf "$ccprocessname\t$process\t$tmpthisoutputanalyte");
      fi
            
    fi
  done

done

if [ "$(echo "$c" | grep Analyte | grep -v $thisoutputanalyte | wc -l)" != "0" ]; then
  thisinputanalyte=$thisoutputanalyte;
  for line in $( echo "$c" | grep Analyte | grep -v $thisoutputanalyte  ); do
      push_stack "$thisinputanalyte|$line|$VAL_AX1|$VAL_AX2|$VAL_AX4|$VAL_AX5|$VAL_AX6|$VAL_AX7|$VAL_AX8|$VAL_AX9|$VAL_AX10|$VAL_AX11|$VAL_AX12"
  done
else
  printf -- "$VAL_AX1\t$VAL_AX2\t$VAL_AX4\t$VAL_AX5\t$VAL_AX6\t$VAL_AX7\t$VAL_AX8\t$VAL_AX9\t$VAL_AX10\t$VAL_AX11\t$VAL_AX12\n" >> $REPORTOUT.t0
  if [ -z "$stack" ]; then
    break;
  fi
fi

done | tr '\t' '~' | column -s '~' -t

done

done


echo "$header" > $REPORTOUT
cat $REPORTOUT.t0 | sort -t $'\t' -k5,5 -k6,6 >> $REPORTOUT
rm $REPORTOUT.t0

blacklist=$(cat $REPORTOUT | grep "^AM" | awk -F'\t' '{print $4"\t"}' | sort -u | tr '\n' '|' | rev | cut -c 2- | rev)
echo "$blacklist"

if [ ! -z "$blacklist" ]; then
  cat $REPORTOUT | grep -v -E "$blacklist" > $REPORTOUT.notest.txt
else
  cp $REPORTOUT $REPORTOUT.notest.txt
fi

cat $REPORTOUT.notest.txt | sed 's/\t/"\t="/g' | awk '{print "=\""$0"\""}' > $REPORTOUT.string.txt

cp $REPORTOUT.string.txt $FINALAXIOMREPORT

}

###################################################################################
#################################                  ################################
#################################  RUN AXIOM FAST  ################################
#################################                  ################################
###################################################################################


function runaxiomfast {

axiomsteps="ax1|DNA Samples QC
ax2|Sample Normalization Generic
ax3|Sample Normalization Extra Plate
ax4|DNA Amplification McGill 1.1
ax5|Fragmentation  (Affy) McGill 1.0
ax6|Centrifugation,Drying and Resuspension McGill 1.1
ax7|Hybridization Preparation McGill 1.0
ax8|Hybridization Sample QC McGill 1.0
ax9|Denaturation and Hybridization McGill 1.0
ax10|GeneTitan Reagent tray Preparation McGill 1.0
ax11|Axiom Scanning QC
ax12|Axiom Analysis QC"


# cat axiom_report.txt | sort -t $'\t' -nk4 | tr '\t' '~' | column -s'~' -t | less -S   

# join -1 2 -2 1 -a1 -t $'\t' -o '1.1,0,2.2' <(echo "$KEY" | sort -k1 ) <(echo "$DAT" | sort -k1) 


REPORTOUT=$SYSTEMPATH/axiom_report_fast.txt
rm -f $REPORTOUT.t0


TAB="$(printf '\t')"
IFS=$'\n'

startstep='Sample Normalization Generic'

function init_stack {
  stack="";
}
function push_stack {
  stack=$(printf "$1\n$stack");
}
function head_stack {
  echo "$stack" | head -n 1;
}
function pop_stack {
  stack=$(echo "$stack" | tail -n+2);
}
function print_stack {
  if [ -z "$stack" ]; then 
    echo "empty stack";
  else
    echo "$stack" | awk '{print "# "$0}';
  fi
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



header=$(printf "\
Project Name\tSample Name\t\
Step2 Name\tProcess ID\tPlate Name\t\
Step4 Name\tProcess ID\t\
Step5 Name\tProcess ID\t\
Step6 Name\tProcess ID\t\
Step7 Name\tProcess ID\t\
Step8 Name\tProcess ID\t\
Step9 Name\tProcess ID\t\
Step10 Name\tProcess ID\t\
Step11 Name\tProcess ID\t\
Step12 Name\tProcess ID\n");

thisrootprocessoverride=24-16894

a=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select p.luid, p.workstatus, pt.displayname from process p
join processtype pt on p.typeid = pt.typeid
where pt.displayname like '$startstep' order by 1 DESC ) TO STDOUT with delimiter '$TAB';
EOF
);

for thisrootprocess in $( echo "$a" | awk '{print $1}'); do

# grep -v -E "24-11660|24-11681|24-29423|24-6518|24-6518|24-30226|24-29945|24-28937|24-30226|24-28932"
# thisrootprocess=$thisrootprocessoverride

b=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
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

thisprocess=$thisrootprocess;

for thisrootline in $( echo "$b"); do


init_stack

thisinputanalyte=$(echo "$thisrootline" | awk '{print $2}');
thisoutputanalyte=$(echo "$thisrootline" | awk '{print $3}');

tmpthisoutputanalyte=$(echo "$thisoutputanalyte" | sed 's/2-//g')
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);

   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));

if [[ "$WELL" != "B01" && "$WELL" != "C01" && "$WELL" != "D01" ]] ; then
  continue;
fi

printf "\n"

csuba=$(psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select a.luid, s.name, p.name as "Project name:" from sample s
join project p using (projectid)
join artifact_sample_map asm using (processid)
join artifact a using (artifactid)
where a.luid = '$thisoutputanalyte' ) TO STDOUT with delimiter '$TAB';
EOF
);
echo "$csuba"


if [ -z "$csuba" ]; then
csuba=$(psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select a.luid, s.name from sample s
join artifact_sample_map asm using (processid)
join artifact a using (artifactid)
where a.luid = '$thisoutputanalyte' ) TO STDOUT with delimiter '$TAB';
EOF
);
  SAMPLENAME=$(echo "$csuba" | awk -F'\t' '{print $2}')
  PROJECTNAME="-";
else
  SAMPLENAME=$(echo "$csuba" | awk -F'\t' '{print $2}')
  PROJECTNAME=$(echo "$csuba" | awk -F'\t' '{print $3}')
fi;

c=$thisrootline

push_stack "2-$thisinputanalyte|$(echo "$c" | grep $thisoutputanalyte)|"$(printf -- "$PROJECTNAME\t$SAMPLENAME")"||||||||||"

while(true); do

line=$(head_stack)
# print_stack
pop_stack


thisinputanalyte=$(echo "$line" | awk -F'|' '{print $1}');
nextline=$(echo "$line" | awk -F'|' '{print $2}');
VAL_AX1=$(echo "$line" | awk -F'|' '{print $3}');
VAL_AX2=$(echo "$line" | awk -F'|' '{print $4}');
VAL_AX4=$(echo "$line" | awk -F'|' '{print $5}');
VAL_AX5=$(echo "$line" | awk -F'|' '{print $6}');
VAL_AX6=$(echo "$line" | awk -F'|' '{print $7}');
VAL_AX7=$(echo "$line" | awk -F'|' '{print $8}');
VAL_AX8=$(echo "$line" | awk -F'|' '{print $9}');
VAL_AX9=$(echo "$line" | awk -F'|' '{print $10}');
VAL_AX10=$(echo "$line" | awk -F'|' '{print $11}');
VAL_AX11=$(echo "$line" | awk -F'|' '{print $12}');
VAL_AX12=$(echo "$line" | awk -F'|' '{print $13}');

thisprocess=$(echo "$nextline" | awk '{print $1}');
thisoutputanalyte=$( echo "$nextline" | awk '{print $3}');
thisprocessname=$(echo "$nextline" | awk -F'\t' '{print $6}' | head -n 1);
tmpthisprocess=$(echo "$thisprocess" | awk -F'-' '{print $2}')

csuba=$(psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
COPY (select a.luid, s.name, p.name as "Project name:" from sample s
join project p using (projectid)
join artifact_sample_map asm using (processid)
join artifact a using (artifactid)
where a.luid = '$thisoutputanalyte' ) TO STDOUT with delimiter '$TAB';
EOF
);

echo "$nextline"

if [ "$(echo "nextline" | grep -v Analyte | wc -l)" != "0" ]; then
    tmpthisoutputanalyte=$(echo "$thisoutputanalyte" | sed 's/2-//g')

###########################################################################
if [[ "$thisprocessname" == "Sample Normalization Generic" ]]; then
    csub0=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
EOF
);
   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}')
   VAL_AX2=$(printf "$thisprocessname\t$thisprocess\t$PLATENAME")

fi
#######################################################################
if [[ "$thisprocessname" == "DNA Amplification McGill 1.1" ]]; then

#    csub0=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
#COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
#join container c on c.containerid = cp.containerid
#join containertype ct on ct.typeid = c.typeid
#where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub1=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
#JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
#join reagentkit rk on rk.reagentkitid = r.reagentkitid
#WHERE rs.processid = $tmpthisprocess) TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub2=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (SELECT * FROM process_udf_view WHERE processid = $tmpthisprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
#EOF
#);
#   VALS=$(echo "$csub2" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
#   echo "$VALS" > /dev/shm/ax4_tmp;
#   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
#   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX4=$(printf "$thisprocessname\t$thisprocess");

fi
#######################################################################
if [[ "$thisprocessname" == "Fragmentation  (Affy) McGill 1.0" ]]; then
#    csub0=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
#COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
#join container c on c.containerid = cp.containerid
#join containertype ct on ct.typeid = c.typeid
#where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub1=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
#JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
#join reagentkit rk on rk.reagentkitid = r.reagentkitid
#WHERE rs.processid = $tmpthisprocess) TO STDOUT with delimiter '$TAB';
#EOF
#);
#   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}')
#   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'))
   VAL_AX5=$(printf "$thisprocessname\t$thisprocess")
fi
#######################################################################
if [[ "$thisprocessname" == "Hybridization Preparation McGill 1.0" ]]; then
#    csub0=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
#COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
#join container c on c.containerid = cp.containerid
#join containertype ct on ct.typeid = c.typeid
#where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub1=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
#JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
#join reagentkit rk on rk.reagentkitid = r.reagentkitid
#WHERE rs.processid = $tmpthisprocess) TO STDOUT with delimiter '$TAB';
#EOF
#);
#   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
#   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX7=$(printf "$thisprocessname\t$thisprocess");
fi
#######################################################################
if [[ "$thisprocessname" == "Denaturation and Hybridization McGill 1.0" ]]; then
#    csub0=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
#COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
#join container c on c.containerid = cp.containerid
#join containertype ct on ct.typeid = c.typeid
#where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub2=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (SELECT * FROM process_udf_view WHERE processid = $tmpthisprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub4=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (select ast.qcflag, atp.displayname as type
#from artifact a
#join artifactstate ast ON a.currentstateid = ast.stateid
#join artifacttype atp ON atp.typeid = a.artifacttypeid
#where a.artifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#   QC=$(echo "$csub4" | grep -v "^$" | awk -F'\t' '{print $1}');
#   VALS=$(echo "$csub2" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
#   echo "$VALS" > /dev/shm/ax9_tmp;
#   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
#   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX9=$(printf "$thisprocessname\t$thisprocess");

fi
#######################################################################
if [[ "$thisprocessname" == "Axiom Analysis QC" ]]; then
#    csub0=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
#COPY (select c.name, cp.containerid, ct.name, cp.wellyposition, ct.isyalpha, cp.wellxposition, ct.isxalpha from containerplacement cp
#join container c on c.containerid = cp.containerid
#join containertype ct on ct.typeid = c.typeid
#where processartifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub3=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisoutputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub4=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (select ast.qcflag, atp.displayname as type
#from artifact a
#join artifactstate ast ON a.currentstateid = ast.stateid
#join artifacttype atp ON atp.typeid = a.artifacttypeid
#where a.artifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#   QC=$(echo "$csub4" | grep -v "^$" | awk -F'\t' '{print $1}')

#   VALS=$(echo "$csub3" | awk -F'\t' '{print $4"\t"$6}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
#   echo "$VALS" > /dev/shm/ax12_tmp;
#   PLATENAME=$(echo "$csub0" | awk -F'\t' '{print $1}');
#   WELL=$(wellcoord $(echo "$csub0" | awk -F'\t' '{print $3}') $(echo "$csub0" | awk -F'\t' '{print $4}') $(echo "$csub0" | awk -F'\t' '{print $6}'));
   VAL_AX12=$(printf "$thisprocessname\t$thisprocess")


fi

fi

c=$(
psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS << EOF
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
  tmpprocess=$(echo "$process" | awk -F'-' '{print $2}')
  cc=$(echo "$c" | grep $process)

  if [ ! -z "$cc" ]; then
    echo "$cc" | head -n 1 | awk '{printf $0"\t"}'; 
    echo "(-)"; 
  fi;

  first=true;
  
  for tmpthisoutputanalyte in $(echo "$c" | grep -v "$thisprocess" | awk '{print $3}' | grep -v '\N' | sed 's/92-//g'); do 
    if [ ! -z "$tmpthisoutputanalyte" ]; then
      ccprocessname=$(echo "$cc" | grep $process | awk -F'\t' '{print $6}' | head -n 1);
      #######################################################################
      if [[ "$ccprocessname" == "Centrifugation,Drying and Resuspension McGill 1.1" ]]; then
#    csub1=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
#JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
#join reagentkit rk on rk.reagentkitid = r.reagentkitid
#WHERE rs.processid = $tmpprocess) TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub2=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (SELECT * FROM process_udf_view WHERE processid = $tmpprocess and udfvalue != '') TO STDOUT with delimiter '$TAB';
#EOF
#);
#          VALS=$(echo "$csub2" | awk -F'\t' '{print $5"\t"$7}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
#          echo "$VALS" > /dev/shm/ax6_tmp;
          VAL_AX6=$(printf "$ccprocessname\t$process");
fi
      #######################################################################
      if [[ "$ccprocessname" == "Hybridization Sample QC McGill 1.0" ]]; then
#    csub3=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (SELECT * FROM artifact_udf_view WHERE artifactid = $tmpthisoutputanalyte and udfvalue != '') TO STDOUT with delimiter '$TAB';
#EOF
#);
#    csub4=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY (select ast.qcflag, atp.displayname as type
#from artifact a
#join artifactstate ast ON a.currentstateid = ast.stateid
#join artifacttype atp ON atp.typeid = a.artifacttypeid
#where a.artifactid = $tmpthisoutputanalyte) TO STDOUT with delimiter '$TAB';
#EOF
#);
#   QC=$(echo "$csub4" | grep -v "^$" | awk -F'\t' '{print $1}')
#   VALS=$(echo "$csub3" | awk -F'\t' '{print $4"\t"$6}' | sed 's/%/Percent/g' | sort -t $'\t' -k1 );
#          echo "$VALS" > /dev/shm/ax8_tmp;
#          doit=false;
#          if ($first); then first=false; doit=true; fi
#          if [ ! -z "$csub3" ]; then doit=true; fi
#          if($doit); then
              VAL_AX8=$(printf "$ccprocessname\t$process");
#          fi
      fi
      #######################################################################
      if [[ "$ccprocessname" == "GeneTitan Reagent tray Preparation McGill 1.0" ]]; then
#          csub1=$(
#psql  postgresql://$USERNAME:$PASSWORD@127.0.0.1/ClarityLIMS <<EOF
#COPY ( SELECT rk.name, r.name, r.lotnumber FROM reagentlot r
#JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
#join reagentkit rk on rk.reagentkitid = r.reagentkitid
#WHERE rs.processid = $tmpprocess) TO STDOUT with delimiter '$TAB';
#EOF
#);
          VAL_AX10=$(printf "$ccprocessname\t$process");
      fi
      #######################################################################
      if [[ "$ccprocessname" == "Axiom Scanning QC" ]]; then
          VAL_AX11=$(printf "$ccprocessname\t$process");
      fi
            
    fi
  done

done

if [ "$(echo "$c" | grep Analyte | grep -v $thisoutputanalyte | wc -l)" != "0" ]; then
  thisinputanalyte=$thisoutputanalyte;
  for line in $( echo "$c" | grep Analyte | grep -v $thisoutputanalyte  ); do
      push_stack "$thisinputanalyte|$line|$VAL_AX1|$VAL_AX2|$VAL_AX4|$VAL_AX5|$VAL_AX6|$VAL_AX7|$VAL_AX8|$VAL_AX9|$VAL_AX10|$VAL_AX11|$VAL_AX12"
  done
else
  printf -- "$VAL_AX1\t$VAL_AX2\t$VAL_AX4\t$VAL_AX5\t$VAL_AX6\t$VAL_AX7\t$VAL_AX8\t$VAL_AX9\t$VAL_AX10\t$VAL_AX11\t$VAL_AX12\n" >> $REPORTOUT.t0
  if [ -z "$stack" ]; then
    break;
  fi
fi

done | tr '\t' '~' | column -s '~' -t

done

done


echo "$header" > $REPORTOUT
cat $REPORTOUT.t0 >> $REPORTOUT
rm $REPORTOUT.t0


html_plate_report

}


function html_plate_report {

# head -n 2 axiom_report_fast.txt | tail -n 1  | tr '\t' '\n' |  awk -F'\t' '{print NR"\t"$0}' 

# 1       AM_PROD_TEST
# 2       P2018-04-30A-S19

# 3       Sample Normalization Generic
# 4       24-11660
# 5       AXTEST_AX001

# 6       DNA Amplification McGill 1.1
# 7       24-11662

# 8       Fragmentation  (Affy) McGill 1.0
# 9       24-11663

# 10      Centrifugation,Drying and Resuspension McGill 1.1
# 11      24-11664

# 12      Hybridization Preparation McGill 1.0
# 13      24-11665

# 14      Hybridization Sample QC McGill 1.0
# 15      24-11666

# 16      Denaturation and Hybridization McGill 1.0
# 17      24-11667

# 18      GeneTitan Reagent tray Preparation McGill 1.0
# 19      24-11668

# 20      Axiom Scanning QC
# 21      24-11669

# 22      Axiom Analysis QC
# 23      24-11680

LIST=$(tail -n+2 $SYSTEMPATH/axiom_report_fast.txt | awk -F'\t' '{print $5"\t"$1"\t"$3"\t"$4"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13"\t"$14"\t"$15"\t"$16"\t"$17\
"\t"$18"\t"$19"\t"$20"\t"$21"\t"$22"\t"$23}' | sort -u);

( 
echo "<"'!'"doctype html><html><head><title>Axiom Process Table</title>"
echo "<style>";
echo "table.style3 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }";
echo "table.style3 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; }";
echo "table.style3 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px; }";
echo "table.style3 tr:nth-child(odd){ background: #dae5f4; }";
echo "table.style3 tr:nth-child(even){ background: #FFFFFF; }";
echo "</style>";

echo "<body>";
echo "$(date)<br>";

for project in $(echo "$LIST" | awk -F'\t' '{print $2}'  | grep -v '-' | grep -v 'AM_PROD_TEST' | sort -u); do
echo "<h3>Project Name: $project</h3>";
echo "<table class=\"style3\">";
echo "<tr>
<th>Plate</th>
<th>Sample Normalization Generic</th>
<th>DNA Amplification McGill 1.1</th>
<th>Fragmentation  (Affy) McGill 1.0</th>
<th>Centrifugation,Drying and Resuspension McGill 1.1</th>
<th>Hybridization Preparation McGill 1.0</th>
<th>Hybridization Sample QC McGill 1.0</th>
<th>Denaturation and Hybridization McGill 1.0</th>
<th>GeneTitan Reagent tray Preparation McGill 1.0</th>
<th>Axiom Scanning QC</th>
<th>Axiom Analysis QC</th>
</tr>"
for line in $(echo "$LIST" | grep "$project" | sort -r); do
  echo "<tr><td>";
  echo "$line" | awk -F'\t' '{ print $1 }';
  echo "</td><td>";
  echo "$line" | sed 's/24-//g' | awk -F'\t' '{ print $4"\t"$6"\t"$8"\t"$10"\t"$12"\t"$14"\t"$16"\t"$18"\t"$20"\t"$22 }' | tr '\t' '\n' | \
     awk -F'\t' 'function l(A) { if (A == "") printf ""; else printf "<a href=\"https://bravoprodapp.genome.mcgill.ca/clarity/work-details/"A"\">"A"</a>"; } \
      { print l($1) }' | tr '\n' '~' | rev | cut -c 2- | rev | sed 's|~|</td><td>|g';  
  echo "</td></tr>";
done;
echo "</table>";
done

echo "<body>";


) > $SYSTEMPATH/table.html 

cp $SYSTEMPATH/table.html $FINALAXIOMFASTREPORT;

}
