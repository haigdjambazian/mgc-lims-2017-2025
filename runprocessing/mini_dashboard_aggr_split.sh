# screen -S mini_dashboard_aggr_split
# . ./mini_dashboard_aggr_split.sh; restart_all

function restart_all {


 while(true); do . ./mini_dashboard_aggr_split.sh; aggregate_runs hiseqx; sleep 3600; done &

 while(true); do . ./mini_dashboard_aggr_split.sh; aggregate_runs novaseq; sleep 3600; done &

 while(true); do . ./mini_dashboard_aggr_split.sh; aggregate_runs iSeq; sleep 3600; done &

 while(true); do . ./mini_dashboard_aggr_split.sh; aggregate_runs miseq; sleep 3600; done &

 while(true); do . ./mini_dashboard_aggr_split.sh; aggregate_runs ontcovidseq; sleep 3600; done &

 while(true); do . ./mini_dashboard_aggr_split.sh; aggregate_runs dnbseqg400; sleep 3600; done &

 while(true); do . ./mini_dashboard_aggr_split.sh; aggregate_runs illumcovidseq; sleep 3600; done &

./Olink_alert_script.sh &

./run_illumcovidanalysis.sh &

# sh runvalidcompletemonitor.sh &

while(true); do
  mkdir -p /lb/robot/research/processing/hiseq/runtracking/axiomreports;
  cp /lb/robot/GeneTitan/bravoprocess/system/axiomreports/table.html /lb/robot/research/processing/hiseq/runtracking/axiomreports/AxiomTableReport.html;
  cp /lb/robot/GeneTitan/bravoprocess/system/axiomreports/axiom_report.txt.string.txt /lb/robot/research/processing/hiseq/runtracking/axiomreports/AxiomDetailedReport.txt;
  sleep 3600;
done &

while(true); do
   d=$(ls -rtd /lb/robot/GeneTitan/bravoprocess/system/illuminareports/*-*-*T*.*.*[0-9] | tail -n 1);
   cp -r $d/projects /lb/robot/research/processing/hiseq/runtracking/projects.new;
   mv /lb/robot/research/processing/hiseq/runtracking/projects /lb/robot/research/processing/hiseq/runtracking/projects.old;
   mv /lb/robot/research/processing/hiseq/runtracking/projects.new /lb/robot/research/processing/hiseq/runtracking/projects;
   rm -r /lb/robot/research/processing/hiseq/runtracking/projects.old;
   sleep 3600;
done &


}

function aggregate_runs {

mkdir -p /lb/robot/research/processing/hiseq/runtracking/allrunreports

sequencer=$1
STUB="";

if [ "$sequencer" == "ontcovidseq" ]; then
    STUB="-$sequencer"
fi

if [ "$sequencer" == "illumcovidseq" ]; then
    STUB="-$sequencer"
fi

if [ "$sequencer" == "dnbseqg400" ]; then
    STUB="-$sequencer"
fi


N=30
echo "aggregate_runs (split) $sequencer"

if [ "$sequencer" == "hiseqx" ]; then
    OUT=/lb/robot/research/processing/hiseq/runtracking/master_run_progress.html
else
    OUT=/lb/robot/research/processing/hiseq/runtracking/master_run_progress-$sequencer.html
fi

if [ "$sequencer" == "ontcovidseq" ]; then
    YEARS=$(ls -r /lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/*$sequencer-run.html | sed "s|/lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/||g" \
	| awk -F'.' '{print $2}' | cut -c 3-4 | sort -u);
else
    YEARS=$(ls -r /lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/*$sequencer-run.html | sed "s|/lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/||g" \
	| cut -c 1-2 | sort -u);
fi

THEDATE=$(date)

EXTRA=$(echo "$YEARS" | tail -n 1)-last$N

for YEAR in $YEARS $EXTRA; do

    OUTYEAR=/lb/robot/research/processing/hiseq/runtracking/master_run_progress-$sequencer-20$YEAR.html

echo "<html> <head>
<style>
table.style1 { border-collapse: collapse; border: 1px solid black; border-style: solid; }
table.style1 th { white-space: nowrap; text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }
table.style1 td { white-space: nowrap; text-align: left; border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }
table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: fixed; }
table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }
table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }

table.style3 { border-collapse: collapse; border: 1px solid black; border-style: solid; }
table.style3 th { text-align: center; border: 0px solid black; border-style: solid; padding: 0px; background: #D0D0D0; font-size:20%;}
table.style3 td { text-align: center; border: 0px solid black; border-style: solid; padding: 0px; font-size:20%; }

table.style4 {  font-size:60%;}

</style>
</head> <body>" > $OUTYEAR.t0

echo "Report generated on $THEDATE.<br>" >> $OUTYEAR.t0

for _YEAR in $YEARS $EXTRA; do
    echo '<a href="master_run_progress-'$sequencer'-20'$_YEAR'.html">20'$_YEAR'</a>&nbsp' >> $OUTYEAR.t0
done
echo "<br>"  >> $OUTYEAR.t0

echo "$sequencer processing list (year: 20$YEAR)<br>" >> $OUTYEAR.t0
echo "<br>" >> $OUTYEAR.t0

echo "Currently monitored runs (all sequencers):<br>" >> $OUTYEAR.t0

# echo "<pre style=\"font-size: 8px\">" >>  $OUTYEAR.t0
echo "<table class=\"style1\">" >>  $OUTYEAR.t0 

vv=$(sh show_all_active_monitors.sh)
echo "$vv" | head -n 1 | sed 's|,|</th><th>|g' | awk '{print "<tr><th>"$0"</th></tr>"}' >> $OUTYEAR.t0
echo "$vv" | tail -n +2 | sed 's|,|</td><td>|g' | awk '{print "<tr><td>"$0"</td></tr>"}' >> $OUTYEAR.t0
echo "</table>" >>  $OUTYEAR.t0
# echo "</pre>" >>  $OUTYEAR.t0

# i=$(grep -B1 process /lb/robot/research/processing/events/system/event.log | awk -F': ' '{print $2}' | sed 's/\.\.\. New event -> start job\.//g' | grep -v "^$");
# IFS=$'\n';
# for j in $(echo "$i" | paste - -); do
#     eve=$(echo "$j" | awk '{print $1}')
#     proc=$(echo "$j" | awk '{print $2}')
#     v=$(ps aux | awk '$2=='$proc'{print $0}');
#     if [ "$v" != "" ]; then
#         # echo $v;
#         echo "$j<br>"
#         f=$(ls /lb/robot/research/processing/events/system/20*/*-valid/$eve);
#         d=$(dirname $f);
#         log=$(echo $(basename $d) | sed 's/-valid//g').run_processing.o
#         echo $d/$eve | awk '{print $0"<br>"}';
#         cat $d/$log | awk '{print $0"<br>"}' 2> /dev/null | head -n 2;
# 	echo "...<br>";
#     fi
# done >> $OUTYEAR.t0
echo "<br>" >> $OUTYEAR.t0

echo "<table class=\"style4\">" >> $OUTYEAR.t0
echo "<tr>" >> $OUTYEAR.t0

i=0

if [ "$sequencer" == "ontcovidseq" ]; then
    if [ "$YEAR" == "$EXTRA" ]; then
	_YEAR=$(echo "$YEARS" | tail -n 1);
	LIST=$(ls -r /lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/*.20$_YEAR*$sequencer-run.html | sort -t '.' -r -k2 | head -n $N)
    else
	LIST=$(ls -r /lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/*.20$YEAR*$sequencer-run.html | sort -t '.' -r -k2 )
    fi
else
    if [ "$YEAR" == "$EXTRA" ]; then
	_YEAR=$(echo "$YEARS" | tail -n 1);
	LIST=$(ls -r /lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/$_YEAR*$sequencer-run.html | head -n $N)
    else
	LIST=$(ls -r /lb/robot/research/processing/hiseq/runtracking/allrunreports${STUB}/$YEAR*$sequencer-run.html)
    fi
fi

for f in $LIST; do

let i=$i+1

# echo $f;
echo "<td valign=\"top\" align=\"center\">" >> $OUTYEAR.t0
if [ "$sequencer" == "ontcovidseq" ]; then
    echo '<a href="allrunreports'${STUB}'/'$(basename $f)'"\>'$(echo $(basename $f) | sed "s/-$sequencer-run.html//g" | awk -F'.' '{print $1"<br>"$2"<br>"$3"<br>"$4 }')'</a>' >> $OUTYEAR.t0
elif [ "$sequencer" == "illumcovidseq" ]; then
    echo '<a href="allrunreports'${STUB}'/'$(basename $f)'"\>'$(echo $(basename $f) | sed "s/-$sequencer-run.html//g" | awk -F'.' '{print $1"<br>"$2"<br>"$3"<br>"$4 }')'</a>' >> $OUTYEAR.t0
else
    echo '<a href="allrunreports'${STUB}'/'$(basename $f)'"\>'$(echo $(basename $f) | sed "s/-$sequencer-run.html//g" | awk -F'_' '{print $1"<br>"$2"_"$3"<br>"$4"<br>"$5 }')'</a>' >> $OUTYEAR.t0
fi
echo "<br>" >> $OUTYEAR.t0


if [ "$sequencer" == "ontcovidseq" ]; then
    if [ "$(cat $f | grep -c Processing)" == "2" ]; then
	cat $f | awk '/Processing Status/,EOF' | tail -n +2 | awk '/Processing Status/,EOF' | grep -v 'Processing Status'  | grep -v -E 'html>|body>|div>' | sed 's/, /, ~/g' | tr '~' '\n' | sed 's/href=".*"//'  | tr -d '\n' >> $OUTYEAR.t0
    else		
	cat $f | awk '/Processing/,EOF' | grep -v 'Processing'  | grep -v -E 'html>|body>' | sed 's/, /, ~/g' | tr '~' '\n' | sed 's/href=".*"//'  | tr -d '\n' >> $OUTYEAR.t0
    fi
elif [ "$sequencer" == "illumcovidseq" ]; then
    cat $f | awk '/Processing/,EOF' | tail -n +2 | awk '/Processing/,EOF' | grep -v 'Processing' | grep -v -E 'html>|body>|div>' | sed 's/, /, ~/g' | tr '~' '\n' | sed 's/href=".*"//'  | tr -d '\n' >> $OUTYEAR.t0
else
    cat $f | awk '/Processing Status/,EOF' | grep -v 'Processing Status'  | grep -v -E 'html>|body>' | sed 's/, /, ~/g' | tr '~' '\n' | sed 's/href=".*"//'  | tr -d '\n' >> $OUTYEAR.t0
fi

echo "</td>" >> $OUTYEAR.t0

if [ "$sequencer" == "hiseqx" ]; then
  if [ "$(($i%8))" == 0 ]; then
    echo "</tr>" >> $OUTYEAR.t0
    echo "<tr>" >> $OUTYEAR.t0
  fi
fi

done

echo "</tr>" >> $OUTYEAR.t0
echo "</table>" >> $OUTYEAR.t0

echo "</body> </html> " >> $OUTYEAR.t0

mv $OUTYEAR.t0 $OUTYEAR
chmod 770 $OUTYEAR

done

cp $OUTYEAR $OUT

}
