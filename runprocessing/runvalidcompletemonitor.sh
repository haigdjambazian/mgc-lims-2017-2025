# screen -S runvalidcompletemonitor
# sh runvalidcompletemonitor.sh



function dnr {
    LIST=$(cat ./runvalidcompletemonitor.system/list.done);
    for el in $(echo "$LIST"); do
	d=$(ls -d /nb/Research/processing/*$(echo "$el" | awk -F',' '{print $3}')*); 
	if [ -d "$d" ]; then 
	    echo "$d,$el"; 
	else
	    echo "none,$el"; 
	fi;
    done | sort > tmp.txt 

}

file=/lb/robot/research/processing/hiseq/runtracking/projects/ALL_PROJECTS_Validated/illumina_report_filt_ALL_PROJECTS_Validated.full.txt

EMAIL_LIST_UPDATE="sequencing-runs@computationalgenomics.ca,ioannis.ragoussis@mcgill.ca,janick.st-cyr@mcgill.ca,antoine.paccard@mcgill.ca,tony.kwan@mcgill.ca,haig.djambazian@mcgill.ca";
# EMAIL_LIST_UPDATE="haig.djambazian@mcgill.ca";

mkdir -p runvalidcompletemonitor.system

cat $file | awk -F'\t' '{print $133","$136","$91}' | sort -u | grep COMPLETE > ./runvalidcompletemonitor.system/list.done
# awk -F'\t' '{print $12","$136}'

#echo "edit file (sleep 1 second), press ctrl+x to exit"
#sleep 1
#nano ./runvalidcompletemonitor.system/list.done
echo "start valid data monitor"

while(true); do

if [ ! -f "$file" ]; then
    echo "ALERT $(basename  $file) not found";
    echo "ALERT $(basename  $file) not found" | mailx -s "ALERT $(basename  $file) not found" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca
    sleep 3600
    continue
fi
if [ ! -f "./runvalidcompletemonitor.system/list.done" ]; then
    echo "ALERT ./runvalidcompletemonitor.system/list.done not found";
    echo "ALERT ./runvalidcompletemonitor.system/list.done not found" | mailx -s "ALERT ./runvalidcompletemonitor.system/list.done not found" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca
    sleep 3600
    continue
fi

cat $file | awk -F'\t' '{print $133","$136","$91}' | sort -u | grep COMPLETE > ./runvalidcompletemonitor.system/list.new
A=$(diff ./runvalidcompletemonitor.system/list.done ./runvalidcompletemonitor.system/list.new  | grep -v '< ' | grep COMPLETE | sed 's/> //g' | awk -F',' '{print $1}')
mv ./runvalidcompletemonitor.system/list.new ./runvalidcompletemonitor.system/list.done

L=$(echo "$A" | wc -l)

if [ "$L" -gt 30 ]; then
    echo "ALERT too many runs validated at once ($L)";
    echo "ALERT too many runs validated at once ($L)" | mailx -s "ALERT too many runs validated at once ($L)" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca
    sleep 3600
    continue
fi



for pid in $(echo "$A"); do
    echo $pid;
    
for PROJECTID in $(grep "$pid$(printf "\t")" $file | awk -F'\t' '{print $1}' | sort -u); do 

EXTRA=$(grep $PROJECTID /lb/robot/research/processing/hiseq/runtracking/Validation_emails.txt | awk -F'\t' '{print $4}');

### if [ ! -z "$EXTRA" ]; then
###     EMAIL_LIST_UPDATE="$EMAIL_LIST_UPDATE;$EXTRA"
### fi

TESTMSG="";

FLOWCELLDIR=$(grep "$pid$(printf "\t")" $file | grep "$PROJECTID$(printf "\t")"| head -n 1 | awk -F'\t' '{print $17}');
PROJECTNAME=$(grep "$pid$(printf "\t")" $file | grep "$PROJECTID$(printf "\t")"| head -n 1 | awk -F'\t' '{print $2}');


  RUNDIR=$(basename $FLOWCELLDIR);
  
# $(head -n 1 $file | awk -F'\t' '{print $1","$2","$18","$3","$92","$4","$6","$8","$22","$23","$26","$28}'| awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|,|</td><td>|g');
HTML=$(cat <<EOF
<html><head><title>$RUNDIR</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table.style2 { border-collapse: collapse; border: 1px solid #A0A0A0; border-style: solid; font-size: 12px;}
table.style2 th { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
table.style2 td { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
body {font-family: Arial;}
</style>
</head>
<body>
<h2>Run: $RUNDIR</h2>
<h2>Project Name: $PROJECTNAME</h2>
<h2>Project ID: $PROJECTID</h2>
<h2>Sequencing Step Process ID: $pid</h2>
${TESTMSG}This is an automated message sent to inform you that the run processing <b><em>and validation</em></b> has been completed for this run and project. You can share the data or start the analysis on these datasets.
<h2>Run Metrics</h2>
<table border="1" class="style2">
$(printf "Project ID,Project Name,Run ID,Flowcell Lane,Sample Name,Library Type,Index Name,Clusters,Bases,R1 Top Blast Hit Name,R2 Top Blast Hit Name\n" | \
   awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|,|</td><td>|g')
$(grep "$pid$(printf "\t")" $file | grep "$PROJECTID$(printf "\t")" | awk -F'\t' '{print $1","$2","$18","$92","$3","$4","$8","$22","$23","$26","$28}'| sort -t ',' -nk4,4 | \
   awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|,|</td><td>|g')
</table>
EOF
);

TESTMSG=""
  
(  
echo "To: $EMAIL_LIST_UPDATE"
echo "Reply-To: hercules@mcgill.ca"
echo "MIME-Version: 1.0"
echo "Subject: ${TESTMSG}Run processing and validation complete for $RUNDIR project: $PROJECTNAME ($PROJECTID)"
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
echo
) | sendmail -t -f bravo.genome@mcgill.ca

echo "Subject: ${TESTMSG}Run processing and validation complete for $RUNDIR project: $PROJECTNAME ($PROJECTID)"
echo "Email to: $EMAIL_LIST_UPDATE"

echo "Subject: ${TESTMSG}Run processing and validation complete for $RUNDIR project: $PROJECTNAME ($PROJECTID)" >> runvalidcompletemonitor.system/log.txt
echo "Email to: $EMAIL_LIST_UPDATE" >> runvalidcompletemonitor.system/log.txt

  done

done
sleep 3600

done
