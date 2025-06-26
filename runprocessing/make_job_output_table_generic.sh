
function dnr {
    cd /home/bravolims/runprocessing;
    for d in /nb/Research/processingontscratch/*; do
	. ./make_job_output_table_generic.sh;
	makejobtable ./ NanoporeCoVSeq_job_list $d;file=$(basename $d)-run.html;
	echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca;
    done

    cd /home/bravolims/runprocessing;
    for d in /nb/Research/processingmgiscratch/processing/*1011[89]*; do
	. ./make_job_output_table_generic.sh;makejobtable ./  RunProcessing_job_list $d;file=$(basename $d)-run.html;
	echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca;
    done
    
}


function makejobtable {

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


OUTPUT_DIR=$1
JOBLISTSTUB=$2;
THIS_BATCH=$3;

mkdir -p $OUTPUT_DIR;

checkfile=$(ls -t $THIS_BATCH/job_output/${JOBLISTSTUB}_* 2>/dev/null  | head -n 1)
if [ ! -f "$checkfile" ]; then
    continue;
fi

echo $checkfile

THIS_HTML_REPORT=$OUTPUT_DIR/$(basename $THIS_BATCH)-run.html

echo "<html>" > $THIS_HTML_REPORT.t0;
echo "<head>" >> $THIS_HTML_REPORT.t0;
echo "<title>$(basename $THIS_HTML_REPORT)</title>" >> $THIS_HTML_REPORT.t0;
echo "<style>" >> $THIS_HTML_REPORT.t0;
echo "table.style3 { border-collapse: collapse; border: 1px solid black; border-style: solid; }" >> $THIS_HTML_REPORT.t0;
echo "table.style3 th { text-align: center; border: 1px solid black; border-style: solid; padding: 1px; background: #D0D0D0; font-size:100%;}" >> $THIS_HTML_REPORT.t0;
echo "table.style3 td { text-align: center; vertical-align: top; border: 1px solid black; border-style: solid; padding: 1px; font-size:100%;}" >> $THIS_HTML_REPORT.t0;
echo "</style>" >> $THIS_HTML_REPORT.t0;
echo "</head>" >> $THIS_HTML_REPORT.t0;
echo "<body>" >> $THIS_HTML_REPORT.t0;
echo "<h1>Processing Status</h1>" >> $THIS_HTML_REPORT.t0;
echo "$(date)<br>" >> $THIS_HTML_REPORT.t0;


STEP_LIST="$(cat $THIS_BATCH/job_output/${JOBLISTSTUB}_* | awk -F'\t' '{print $2}' | awk -F'.' '{print $1}' | cat -n | sort -uk2 | sort -nk1 | cut -f2-)"

FILE=$( echo "Step Name,Date,Job Name,Job ID,Exit Status,Job Epilog,Job State";
IFS=$'\n'
for THIS_STEP in $(echo "$STEP_LIST"); do

for job in $(cat $THIS_BATCH/job_output/${JOBLISTSTUB}_* | grep -w "$THIS_STEP" | tr '\t' ',' | awk -F',' '{print $2}' | sort -u  2>/dev/null ); do

      # last job
      line=$(cat $THIS_BATCH/job_output/${JOBLISTSTUB}_* | grep -w "$THIS_STEP" |  awk '$2=="'$job'"{print $0}' | tr '\t' ',' | sort -t ',' -k4 | tail -n 1);

      JOB_ID=$(echo $line | awk -F',' '{print $1}' | awk -F'.' '{print $1}')
      # JOB_NAME=$(echo $line | awk -F ',' '{print $2}' | fold -w 60 | paste -sd' ' -)
      JOB_NAME=$(echo $line | awk -F ',' '{print $2}')
      JOB_DEP=$(echo $line | awk -F ',' '{print $3}')
      JOB_REL_DIR=$(echo $line | awk -F ',' '{print $4}')
      DATE=$(echo "$JOB_REL_DIR" | awk -F'_' '{print $NF}' | sed 's/\.o//g')
#       echo -n $THIS_STEP; echo -n ","$DATE;  echo -n ","$(echo $JOB_NAME | cut -d"." -f2-);
      echo -n $THIS_STEP; echo -n ","$DATE;  echo -n ","$JOB_NAME;

      fj=$THIS_BATCH/job_output/$JOB_REL_DIR

      echo -n ","$JOB_ID

      STR=""
      for line2 in $(cat $THIS_BATCH/job_output/${JOBLISTSTUB}_* | grep -w "$THIS_STEP" | awk '$2=="'$job'"{print $0}' | tr '\t' ',' | sort -t ',' -k4 | tail -n 2 ); do
          JOB_REL_DIR2=$(echo $line2 | awk -F ',' '{print $4}')
          fj2=$THIS_BATCH/job_output/$JOB_REL_DIR2
          V=""
          if [ -f "$fj2" ]; then
              V=$(cat $fj2 | sed 's/MUGQICexitStatus/\nMUGQICexitStatus/g' | grep MUGQICexitStatus)
          fi
          if [ "$V" == "" ]; then
              if [ "$STR" == "" ]; then STR="-|$fj2"; else STR="$STR -|$fj2"; fi;
          else
              if [ "$STR" == "" ]; then STR="$(echo $V | sed 's/MUGQICexitStatus://g')|$fj2";
	      else STR="$STR $(echo $V | sed 's/MUGQICexitStatus://g')|$fj2"; 
	      fi;
          fi
      done
      echo -n ",$STR"

      if [ -f "$fj" ]; then
        D="0"
        if [[ "$(grep -c Epilogue $fj)" -gt "0" ]]; then
            D="1";
        fi
        V=$(cat $fj | sed 's/MUGQICexitStatus/\nMUGQICexitStatus/g' | grep MUGQICexitStatus)
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

done | sort -t ',' -nk4,4);

first=true
TABLE=$(
echo "<table class=\"style3\">";
IFS=$'\n'
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

        case $STATUS in
        "Idle/Hold")
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

# td nowrap

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
            if [ -f "$f2" ]; then
		if [ "$STATUS" == "Incomplete" ]; then
                    echo -n "$spacer"'<a target="_blank" href="data:text/html;base64,'$(clip200 $f2 | awk '{print $0 "<br>"}' | base64)'" >'"$f1"'</a>';
		else
                    echo -n "$spacer$f1";
		fi
            else
                echo -n "$spacer$f1";
            fi;
            spacer=',';
        done
        echo -n '</td>'
        
        echo "$line" | awk -F',' '{print "<td nowrap>"$6"</td>"}' | tr -d '\n';
        
        echo -n "<td nowrap>$STATUS</td>"
        
        echo -n "</tr>"
    fi
    echo ""
done;
echo "</table>";
)


echo "$TABLE" >> $THIS_HTML_REPORT.t0
echo "</body></html>" >> $THIS_HTML_REPORT.t0;

mv $THIS_HTML_REPORT.t0 $THIS_HTML_REPORT

}

