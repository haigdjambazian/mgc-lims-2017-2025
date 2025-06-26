
# usage:
# sh sendtoscratch-or-sftp.sh A00266_0343 ZOG910 'apacis'
# sh sendtoscratch-or-sftp.sh A00266_0343 ZOG910 'apacis' deliver-index
# sh sendtoscratch-or-sftp.sh A00266_0343 ZOG910 'sftpuser:sftppassword'
# sh sendtoscratch-or-sftp.sh A00266_0343 ZOG910 'sftpuser:sftppassword' deliver-index


function htmltable {
    a="$(cat - )";
    echo "<table border=\"1\" class=\"$1\">"
    echo "$a" | head -n 1 | awk '{print "<tr><th>"$0"</th></tr>"}' | sed 's|,|</th><th>|g'
    echo "$a" | tail -n+2 | awk '{print "<tr><td>"$0"</td></tr>"}' | sed 's|,|</td><td>|g'
    echo "</table>"
}

runid="$1";
project="$2";
userpass="$3";
deliverindex="$4";

echo "runid='$runid'";
echo "project='$project'";
echo "userpass='$userpass'";

sftpuser=$(echo "$userpass" | awk -F':' '{print $1}');
sftppass=$(echo "$userpass" | awk -F':' '{print $2}');

TMPCOPYDIR=/lb/scratch/$USER/datashare/$sftpuser;

echo TMPCOPYDIR=/lb/scratch/$USER/datashare/$sftpuser;

mkdir -p $TMPCOPYDIR/$project/$runid

# cp -rv /lb/robot/research/processing/*/*/*$runid*/Unaligned*/*$project*/*/*R[12]_001.fastq.gz* $TMPCOPYDIR/$project/$runid/
# if [ "$deliverindex" == "deliver-index" ]; then
#   cp -rv /lb/robot/research/processing/*/*/*$runid*/Unaligned*/*$project*/*/*I[12]_001.fastq.gz* $TMPCOPYDIR/$project/$runid/
# fi


for d in /lb/robot/research/processing/*/*/*$runid*/Unaligned.*/*$project*/Sample_*; do
    samplelibname=$(echo $(basename $d) | cut -c 8-);
    lib=$(echo $samplelibname | rev | cut -d "_" -f1 | rev);
    samplename=$(echo $samplelibname | sed "s/_$lib//g");
    lane=$(echo $(dirname $(dirname $d)) | cut -d '.' -f2);
    
    fastq="/lb/robot/research/processing/*/*/*$runid*/Unaligned.$lane/*$project*/*/$samplelibname*R1_001.fastq.gz"
    
    if [ -f $fastq ]; then
	cp -v /lb/robot/research/processing/*/*/*$runid*/Unaligned.$lane/*$project*/*/$samplelibname*R[12]_001.fastq.gz* $TMPCOPYDIR/$project/$runid/
	cp -v /lb/robot/research/processing/*/*/*$runid*/Unaligned.$lane/*$project*/*/$samplelibname*R2_001.fastq.gz* $TMPCOPYDIR/$project/$runid/
	if [ "$deliverindex" == "deliver-index" ]; then
	    cp -v /lb/robot/research/processing/*/*/*$runid*/Unaligned.$lane/*$project*/*/$samplelibname*I[12]_001.fastq.gz* $TMPCOPYDIR/$project/$runid/
	fi
    else
	bam="/lb/robot/research/processing/*/*/*$runid*/Aligned.$lane/alignment/$samplename/*/*.sorted.bam"
	cp -v $bam $TMPCOPYDIR/$project/$runid/$(echo $(basename $bam) | sed "s/.sorted.bam/.Lane$lane.sorted.bam/g")
	cp -v $bam.md5 $TMPCOPYDIR/$project/$runid/$(echo $(basename $bam) | sed "s/.sorted.bam/.Lane$lane.sorted.bam.md5/g")
    fi
    
done

find $TMPCOPYDIR -type d -exec chmod 755 {} \;
find $TMPCOPYDIR -type f -exec chmod 644 {} \;

PWD=$(pwd);
cd $TMPCOPYDIR/$project/$runid;
GG=$(ls -lh *.gz | awk '{print $9 "," $5}');
cd $PWD;


html=$TMPCOPYDIR/$project/$runid/info.html
rm -f $html;
HTML=$(cat <<EOF
<!doctype html><html><head><title>$project/$runid</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table.style1 { border-collapse: collapse; border: 1px solid black; border-style: solid; font-size: 12px; }
table.style1 th { text-align: center; border: 1px solid black; border-style: solid; padding: 3px;width: 40px; height: 40px }
table.style1 td { text-align: center; border: 1px solid black; border-style: solid; padding: 3px;width: 40px; height: 40px  }
table.style2 { border-collapse: collapse; border: 1px solid #A0A0A0; border-style: solid; font-size: 12px;}
table.style2 th { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
table.style2 td { text-align: center; border: 1px solid #A0A0A0; padding: 1px; white-space: nowrap;}
body {font-family: Arial;}
</style>
</head>
<body>
EOF
);
echo "$HTML" >> $html;
echo "<h1>$project/$runid</h1>" >> $html;
F=$(ls /lb/robot/research/processing/*/*/*$runid*/*-run.csv);

echo "Your data is accessible here:<br>" >> $html;
if [  "$sftppass" == "" ]; then
    echo "$TMPCOPYDIR/$project/$runid/<br>" >> $html;
    echo "Please make a copy it will be erased from this location in 30 days.<br>" >> $html;
else 
    echo "sftp server = sftp.mcgillgenomecentre.ca<br>" >> $html;
    echo "sftp port = 22<br>" >> $html;
    echo "sftp username = $sftpuser<br>" >> $html;
    echo "sftp password = $sftppass<br>" >> $html;
fi
echo "<br>" >> $html;

(head -n 1 $F; cat $F | grep "$project" ) | cut -d ',' -f 1-20 | htmltable style2 >> $html;
echo "<br>" >> $html

(echo "File Name, File Size"; echo "$GG") | grep -v "^$" | htmltable style2 >> $html;
HTML=$(cat <<EOF
</body>
</html> 
EOF
);
echo "$HTML" >> $html;

if [  "$sftppass" == "" ]; then
    :
else
    lftp -e "mirror -RL $TMPCOPYDIR/$project; chmod -R 0777 $project; bye" -u "$userpass" sftp://sftp.mcgillgenomecentre.ca
fi

EMAILS=$(cat <<EOF
"$USER" <$JOB_MAIL>
EOF
);


(  
echo "To: $(echo "$EMAILS" | tr '\n' ',' | rev | cut -c 2- | rev)"
echo "Reply-To: magic@mcgill.ca"
echo "MIME-Version: 1.0"
if [  "$sftppass" == "" ]; then
    echo "Subject: Data copied to scratch for $project/$runid"
else
    echo "Subject: Data copied to sftp for $project/$runid"
fi
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
cat "$html"
echo
) | sendmail -t -f bravo.genome@mcgill.ca


if [  "$sftppass" == "" ]; then
    :
else
    rm -rv $TMPCOPYDIR/
fi





