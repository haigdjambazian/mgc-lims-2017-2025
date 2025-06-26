#!/bin/bash
# /var/lib/pgsql/
# 
# before release or update tag is created:
# (eg: before 0.3.0-rc8 is created)
#
# rm DEPLOYMENT_TEXT.txt; sh sendmailscript.sh deploy_qc           release_0.3:0.3.0-rc8 0.2.10
#
# rm DEPLOYMENT_TEXT.txt; sh sendmailscript.sh deploy_qc           release_0.3:0.3.0-rc8 0.3.0-rc6
#
# rm DEPLOYMENT_TEXT.txt; sh sendmailscript.sh deploy_qc           release_0.3:0.3.3-uc2 0.3.2
#
# file=DEPLOYMENT_TEXT.txt; echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca
# 

# rm DEPLOYMENT_TEXT.txt;   sh sendmailscript.sh deploy_qc           release_0.3:0.3.11-uc2 0.3.11-uc1
#                           sh sendmailscript.sh deploy_qc           release_0.3:0.3.11-uc2 0.3.10
# file=DEPLOYMENT_TEXT.txt; echo "$file" | mailx -s "$file" -a "$file" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca              



testmode=false

function usage {

  echo "usage:  sh sendmailscript.sh <mode> <target_version> [<previous_version>]"
  echo "        mode: {deploy_dev, deploy_prod, release_notes}"
  echo
  echo "examples:"
  echo "   sh sendmailscript.sh deploy_dev          add-miseq-path"                                 # uses branch and origin
  echo "   sh sendmailscript.sh deploy_dev          magic-samples-reception"                        # uses branch and origin
  echo "   sh sendmailscript.sh deploy_dev          enabling-autopooling-on-all-sequencers:0.2.7"   # uses branch and origin
  echo "   sh sendmailscript.sh deploy_dev          add-nebnext-adapters-update-manifest:0.2.6"     # uses branch and origin

  echo "   sh sendmailscript.sh deploy_dev          master    0.2.7-rc1"                           # uses master and the most recent release tag

  echo "   sh sendmailscript.sh deploy_qc           release_0.2 0.2.7"

  echo "   sh sendmailscript.sh deploy_qc           release_0.2:0.2.7-rc1"                          # uses branch and previous tag inferred
  echo "   sh sendmailscript.sh deploy_qc           release_0.2:0.2.7-rc1 0.1.7"                    # uses branch and previous tag
  echo
  echo "   sh sendmailscript.sh pre_release         release_0.2:0.2.4"                              # uses branch and previous tag inferred
  echo "   sh sendmailscript.sh pre_release         release_0.2:0.2.0 0.1.7"                        # uses branch and previous tag
  echo
  echo "   sh sendmailscript.sh release_notes       release_0.2:0.2.4"                              # uses tag and previous tag inferred
  echo "   sh sendmailscript.sh release_notes       release_0.2:0.2.0 0.1.7"                        # uses tag and previous tag

  
}


mode=$1;
target_BRANCH=$(echo "$2" | awk -F':' '{print $1}');
target_version=$(echo "$2" | awk -F':' '{print $2}');
previous_version=$3;

# echo "mode: $mode"
# echo "target_BRANCH: $target_BRANCH"
# echo "target_version: $target_version"
# echo "previous_version: $previous_version"

function run {

if($testmode); then
    if [ "$JOB_MAIL" == "" ]; then
        echo "You must set JOB_MAIL in your ~/.bash_profile";
        false;
        return
    fi
#    echo "You are in test mode all emails will be sent to $JOB_MAIL";
fi

IFS=$'\n'

DATE=$(date +%Y-%m-%d);

if [ "$JOB_MAIL" == "" ]; then
    echo "You must set JOB_MAIL in your ~/.bash_profile";
    false;
    return
fi

if [ "$target_BRANCH" == "" ]; then
    echo "You must provide a target branch.";
    usage;
    false;
    return
fi
if [ "$mode" == "" ]; then
    echo "You must provide a mode.";
    false;
    usage;
    return
fi

if [ "$mode" == "deploy_prod" ] || [ "$mode" == "pre_release" ] || [ "$mode" == "release_notes" ]; then
   DROPDIR=/lb/bravo/bravoprod/drop
   servername=bravoprodapp
fi

if [ "$mode" == "deploy_qc" ]; then
   DROPDIR=/lb/bravo/bravoqc/drop
   servername=bravoqcapp
fi

if [ "$mode" == "deploy_dev" ]; then
   DROPDIR=/lb/bravo/bravodev/drop
   servername=bravodevapp
fi

if [ "$mode" != "release_notes" ] && [ "$mode" != "pre_release" ]; then
    instance="$(echo $mode | sed 's/deploy_/bravo/g')"
fi

if [ "${target_version}" == "" ]; then
    partial_DIR=$DATE-$(echo "${target_BRANCH}" | tr -d ' \\/()')/clarity;
    target_DIR=$DROPDIR/$DATE-$(echo "${target_BRANCH}" | tr -d ' \\/()')/clarity;
    rm -rf $DROPDIR/$DATE-$(echo "${target_BRANCH}" | tr -d ' \\/()')
else
    partial_DIR=$DATE-$(echo "${target_BRANCH}" | tr -d ' \\/()')-${target_version}/clarity;
    target_DIR=$DROPDIR/$DATE-$(echo "${target_BRANCH}" | tr -d ' \\/()')-${target_version}/clarity;
    rm -rf $DROPDIR/$DATE-$(echo "${target_BRANCH}" | tr -d ' \\/()')-${target_version}
fi

clean_version=$(echo "$target_version" | awk -F'-' '{print $1}')

mkdir -p $target_DIR;

if [ "$mode" == "deploy_prod" ] || [ "$mode" == "deploy_qc" ]; then
    if [ "$previous_version" == "" ]; then
        vp=$(echo "$clean_version" | cut -c 5-)
        if [ "$vp" == "0" ]; then
            echo "You must provide a previous version. Target version micro is 0, cannot infer previous version.";
            usage;
            false;
            return
        fi
        let vp=$vp-1;
        previous_version=$(echo $clean_version | cut -c 1-3).$vp
        echo "inferred previous verions: $previous_version"
    fi
fi

if [ "$previous_version" != "" ]; then
   previous_BRANCH=release_$(echo "$previous_version" | cut -c 1-3)
fi

if [ "$GIT_USER_NAME" == "" ]; then
#    echo "git clone -b "$target_BRANCH" https://bitbucket.org/mugqic/clarity.git $target_DIR"
    git clone -b "$target_BRANCH" https://bitbucket.org/mugqic/clarity.git $target_DIR
    if [ "$?" != "0" ]; then
        echo "failed, exit: git clone -b "$target_BRANCH" https://bitbucket.org/mugqic/clarity.git $target_DIR"
        false;
        return
    fi
else
#    echo "git clone -b "$target_BRANCH" https://$GIT_USER_NAME:$GIT_USER_PASSWORD@bitbucket.org/mugqic/clarity.git $target_DIR"
    git clone -b "$target_BRANCH" https://$GIT_USER_NAME:$GIT_USER_PASSWORD@bitbucket.org/mugqic/clarity.git $target_DIR
    if [ "$?" != "0" ]; then
        echo "failed, exit: git clone -b "$target_BRANCH" https://$GIT_USER_NAME:$GIT_USER_PASSWORD@bitbucket.org/mugqic/clarity.git $target_DIR"
        false;
        return
    fi
fi

if [ "$target_version" != "" ]; then
    pwddir=$(pwd)
    cd $target_DIR
    git checkout $target_version
    cd $pwddir
    if [ "$?" != "0" ]; then
        echo "failed, exit: git checkout $target_version"
        false;
        return
    fi
fi

# ls -l $target_DIR

P=$(pwd); cd $target_DIR


if [ "$mode" == "deploy_prod" ]; then
#    echo git diff $previous_version
    A=$(git diff $previous_version)
    if [ "$?" != "0" ]; then
        echo "failed, exit: git diff "
        cd $P
        false;
        return
    fi
#    echo "$A" | grep  "^diff" | awk '{print $3}'
fi

if [ "$mode" == "deploy_qc" ]; then
#    echo git diff $previous_version
    A=$(git diff $previous_version)
    if [ "$?" != "0" ]; then
        echo "failed, exit: git diff "
        cd $P
        false;
        return
    fi

     #   echo "$A" | grep  "^diff" | awk '{print $3}'
fi


REPOVAR=""

if [ "$mode" == "deploy_dev" ]; then

if [ "$previous_version" == "" ]; then
#    echo git diff origin

    rm -rf $target_DIR/../tmp
    mkdir $target_DIR/../tmp
    git clone -b "master" https://$GIT_USER_NAME:$GIT_USER_PASSWORD@bitbucket.org/mugqic/clarity.git $target_DIR/../tmp/clarity

    PWD=$(pwd)

    cd $target_DIR/../tmp/clarity;
    A1=$(git rev-parse --short HEAD)
    rm -rf $target_DIR/../tmp
    
    cd  $target_DIR
    B1=$(git rev-parse --short HEAD)
    A=$(git diff $A1..$B1)
    
    cd $PWD

else

    rm -rf $target_DIR/../tmp
    mkdir $target_DIR/../tmp
    git clone -b "$previous_BRANCH" https://$GIT_USER_NAME:$GIT_USER_PASSWORD@bitbucket.org/mugqic/clarity.git $target_DIR/../tmp/clarity

    PWD=$(pwd)

    cd $target_DIR/../tmp/clarity;
    v=$(git checkout $previous_version)
    A1=$(git rev-parse --short HEAD)    
    rm -rf $target_DIR/../tmp
    
    cd  $target_DIR
    B1=$(git rev-parse --short HEAD)
    A=$(git diff $A1..$B1)
    
    cd $PWD

fi

    if [ "$?" != "0" ]; then
        echo "failed, exit: git diff "
        cd $P
        false;
        return
    fi

#    echo "$A" | grep  "^diff" | awk '{print $3}'

   REPOVAR=$(echo "$target_DIR" | sed "s|$DROPDIR|/mnt/drop|g" | sed 's/clarity//g')

fi


cd $P

file=$target_DIR/CHANGELOG.md;

HTML=$(printf "<!DOCTYPE html>\n";
printf "<html>\n";

printf "<head>\n";
printf "</head>\n";

printf "<body>\n";


if [ "$mode" == "release_notes" ]; then
    printf "For LIMS related issues or questions please email: hercules@mcgill.ca<br>\n";
    printf "<h2>McGill Genome Centre LIMS version $target_version is now deployed in production.</h2>\n"
    printf "<h2>The most up to date sample manifest is attached to this email.</h2>\n"
    printf "<h2>Changes in version $target_version are listed below and the full change log is attached.</h2>\n"
fi

if [ "$mode" == "pre_release" ]; then
    printf "For LIMS related issues or questions please email: hercules@mcgill.ca<br>\n";
    printf "<h2>McGill Genome Centre LIMS version $target_version passed final acceptance (in bravoqc) and will be released in two working days from $DATE*.</h2>\n"
    printf "* Expect a shorter wait if changes only affect adapter definitions, the sample manifest or other exceptions.<br>\n"
    printf "<h2>Changes in version $target_version are listed below.</h2>\n"
fi

if [ "$mode" != "release_notes" ] && [ "$mode" != "pre_release" ]; then
    printf "<h2>McGill Genome Centre LIMS branch $target_BRANCH:$target_version</h2>\n"
    printf "Changes are listed below.\n"
fi


if [ "$mode" == "deploy_dev" ]; then
   tmp_target_version=Unreleased
else
   tmp_target_version=$(echo "$clean_version")
fi

inlist=false
for line in $(cat $file | grep -v '\[see changes\]' | sed 's/__//g' | sed -n "/\[$tmp_target_version\]/,/\[/p" | head -n -1| grep -v '^$'); do

    if [ "$(echo $line | awk '{print $1}')" == "##" ]; then
         if($inlist); then
             inlist=false;
             printf "    </ul>\n";
         fi
         printf "<h2>";
         echo "$line" | cut -c 4-;
         printf "</h2>";
    fi
    
    if [ "$(echo $line | awk '{print $1}')" == "###" ]; then
         if($inlist); then
             inlist=false;
             printf "    </ul>\n";
         fi
         printf "  <h3>";
         echo "$line" | cut -c 5-;
         printf "  </h3>";
    fi
    
    if [ "$(echo $line | awk '{print $1}')" == "-" ]; then
         if($inlist); then
            :
         else
             inlist=true;
             printf "    <ul>\n";
         fi
         printf "      <li>";
         echo "$line" | cut -c 3-;
         printf "      </li>";
    fi

done

if($inlist); then
    inlist=false;
    printf "    </ul>\n";
fi


printf "</body>\n";
printf "</html>\n";
)


HTMLFULL=$(printf "<!DOCTYPE html>\n";
printf "<html>\n";

printf "<head>\n";
printf "</head>\n";

printf "<body>\n";

printf "<h2>McGill Genome Centre LIMS Change Log</h2>\n"

inlist=false
for line in $(cat $file | sed 's/__//g' | grep -v '^$' | grep -v "see changes" | grep -v "Unreleased"); do

    if [ "$(echo $line | awk '{print $1}')" == "##" ]; then
         if($inlist); then
             inlist=false;
             printf "    </ul>\n";
         fi
         printf "<h2>";
         echo -n "$line" | cut -c 4- | tr -d '\n';
         printf "</h2>";
    fi
    
    if [ "$(echo $line | awk '{print $1}')" == "###" ]; then
         if($inlist); then
             inlist=false;
             printf "    </ul>\n";
         fi
         printf "  <h3>";
         echo -n "$line" | cut -c 5- | tr -d '\n';
         printf "  </h3>";
    fi
    
    if [ "$(echo $line | awk '{print $1}')" == "-" ]; then
         if($inlist); then
            :
         else
             inlist=true;
             printf "    <ul>\n";
         fi
         printf "      <li>";
         echo "$line" | cut -c 3- | tr -d '\n';
         printf "      </li>";
    fi

done
printf "    </ul>\n";

printf "</body>\n";
printf "</html>\n";
)


HTMLDEPLOYINSTRUCTIONS=$(
printf "<!DOCTYPE html>\n";
printf "<html>\n";
printf "<head>\n";
printf "<style>\n";
printf "code { \n";
printf "  background-color: #eee;\n";
printf "  border: 1px solid #999;\n";
printf "  display: block;\n";
printf "  padding: 20px;\n";
printf "  font-family: monospace;\n";
# printf "  white-space: nowrap;\n";
printf "}\n";
printf "</style>\n";
printf "</head>\n";
printf "<body>\n";
printf "<h2>Deployment Instructions for branch:tag $target_BRANCH:$target_version</h2>\n"

# lines=$(echo "$A" | grep  "^+++" | awk '{print $2}' | grep -v "^/dev/null" | cut -c 3- | grep "^config_slicer/protocols" | wc -l)
lines=$(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep "^config_slicer/protocols" | wc -l)


printf "<h3>Get the files from the repository</h3>\n"
printf "To get the files define LOCALREPO and run the following commands:<br>\n"
printf "<code>ssh $servername.genome.mcgill.ca<br>\n"
printf "LOCALREPO=\"$REPOVAR\";<br>\n"
printf "cd \$LOCALREPO;<br>\n"
printf "git clone -b $target_BRANCH https://itgenome@bitbucket.org/mugqic/clarity.git;<br>\n"
printf "cd \$LOCALREPO/clarity;<br>\n"
printf "git checkout $target_version;<br>\n"
printf "</code><br>\n"

ADMINPASS=''

printf "<h3>LIMS Workflow Configuration</h3>\n"
if [ "$lines" == "0" ] ; then
    printf "Up to date.<br>\n"
else
    printf "Apply these xml files<br><br>\n"
    printf "<code>sudo su - glsjboss;<br><br>\n"
    printf "ADMINPASS=\"$ADMINPASS\";<br><br>\n"
    printf "LIMSSERVER=\"$servername.genome.mcgill.ca\";<br><br>\n"
    for line in $(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep "^config_slicer/protocols" | grep '.txt.xml'); do
       printf "java -jar /opt/gls/clarity/tools/config-slicer/config-slicer-3.2.0.7.jar -o importAndOverwrite -s \$LIMSSERVER -u admin -p \"\$ADMINPASS\" -k \$LOCALREPO/clarity/$line;<br><br>\n";
    done
    printf "</code>\n";
fi
printf "<br>\n";

lines=$(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep -E "^customextensions|adapter_|library_protocol_list.csv"  | wc -l)
printf "<h3>LIMS Workflow Scripts</h3>\n"
if [ "$lines" == "0" ] ; then
    printf "Up to date.<br>\n"
else
    printf "Update these files<br><br>\n"
    printf "<code>sudo su - glsai<br><br>\n"
    for line in $(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep -E "^customextensions|adapter_|library_protocol_list.csv" ); do
        if [ -f "$target_DIR/$line" ]; then
            printf "cp \$LOCALREPO/clarity/$line "$(echo /opt/gls/clarity/$line | sed 's|runprocessing|customextensions/Common|g')";<br><br>\n";
        else
            printf "rm /opt/gls/clarity/$line;<br><br>\n";
        fi
    done
    printf "</code>\n";
fi
printf "<br>\n";

lines=$(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep -E "^reportscripts" | wc -l)
printf "<h3>LIMS stand alone reporting scripts</h3>\n"
if [ "$lines" == "0" ] ; then
    printf "Up to date.<br>\n"
else
    printf "Update these files<br><br>\n"
    printf "<code>\n"
    for line in $(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- |  grep -E "^reportscripts" ); do
        if [ -f "$target_DIR/$line" ]; then
            printf "cp \$LOCALREPO/clarity/$line "$(echo /var/lib/pgsql/$line | sed 's|reportscripts/||g')";<br><br>\n";
        else
            printf "rm /opt/gls/clarity/$line;<br><br>\n";
        fi
    done
    printf "</code>\n";
fi
printf "<br>\n";

lines=$(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep "^INSTALLATION.md" | grep -v "^#" | wc -l)
printf "<h3>LIMS application and Python Configuration</h3>\n";
if [ "$lines" == "0" ] ; then
    printf "Up to date.<br>\n"
else
    for line in $(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep "^INSTALLATION.md" | grep -v "^#" ); do
        :
        # printf "$line<br>\n";
    done
    l2=$(echo "$A" |  sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep  "permissions-tool.jar" | awk '{print $0"<br>"}' | wc -l);
    if [ "$l2" != "0" ] ; then
      printf "Apply these changes to the application:<br>\n";
      printf "<code>sudo su - glsjboss;<br><br>\n";
      echo "$A" |  sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep "permissions-tool.jar" | awk '{print $0"<br>"}'      
      printf "</code>\n";
    fi
    l2=$(echo "$A" | sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep "==" | awk '{print $0"<br>"}' | wc -l);
    if [ "$l2" != "0" ] ; then
      printf "Install these python libraries:<br>\n";
      printf "<code>\n";
      echo "$A" | sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep "==" | awk '{print $0"<br>"}'
      printf "</code>\n";
    fi
    l2=$(echo "$A" | sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep "run_processing" | awk '{print $0"<br>"}' | wc -l);
    if [ "$l2" != "0" ] ; then
      printf "Install genpipes for mgi runprocessing:<br>\n";
      printf "<code>LIMSUSER=bravolims-qc; # LIMSUSER=bravolims # for prod<br>\n"
      echo "$A" | sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep "run_processing" | awk '{print $0"<br>"}'
      printf "</code>\n";
    fi
    l2=$(echo "$A" | sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep "covseq_ont" | awk '{print $0"<br>"}' | wc -l);
    if [ "$l2" != "0" ] ; then
      printf "Install genpipes for mgi runprocessing:<br>\n";
      printf "<code>LIMSUSER=bravolims-qc; # LIMSUSER=bravolims # for prod<br>\n"
      echo "$A" | sed -n '/INSTALLATION.md/,/diff/p' | grep -v '+++' | grep "^+" | tr -d '+' | grep -v "#" |  sed 's/    //g' | grep -v "^$" | grep "covseq_ont" | awk '{print $0"<br>"}'
      printf "</code>\n";
    fi

fi
printf "<br>\n";

lines=$(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep "^samplesubmissiontemplates" | wc -l)
printf "<h3>Sample Manifest</h3>\n";
if [ "$lines" == "0" ] ; then
    printf "Up to date.<br>\n"
else
    for line in $(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep "^samplesubmissiontemplates"); do
        :
        # printf "$line<br>\n";
    done
    printf "Update these files and lims properties:<br>\n"
    printf "<code>sudo su - glsjboss;<br><br>\n"
    printf "cp \$LOCALREPO/clarity/$line /opt/gls/clarity/glscontents/lablink/downloads/MGC_Sample_Submission_Template_BLANK_v$clean_version.xlsx;<br><br>\n"
    printf "java -jar /opt/gls/clarity/tools/propertytool/omxprops-ConfigTool.jar set clarity.exampleSampleSheet.uri '/glsstatic/lablink/downloads/MGC_Sample_Submission_Template_BLANK_v$clean_version.xlsx';<br>\n";
    printf "</code>\n";

fi
printf "<br>\n";

lines=$(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep -E "^runprocessing|^mgirunprocessing|^ontcovidrunprocessing" | wc -l)
printf "<h3>Run processing</h3>\n"
if [ "$lines" == "0" ] ; then
    printf "Up to date.<br>\n"
else
    printf "<code>LIMSUSER=bravolims-qc; # LIMSUSER=bravolims # for prod<br>\n"
    printf "ssh \$LIMSUSER@abacus3.genome.mcgill.ca;<br>\n";
    printf "LOCALREPO=\"$REPOVAR\";<br>\n"
    printf "cd \$LOCALREPO;<br>\n"
    printf "git clone -b $target_BRANCH https://itgenome@bitbucket.org/mugqic/clarity.git;<br>\n"
    printf "cd \$LOCALREPO/clarity;<br>\n"
    printf "git checkout $target_version;<br>\n"
    run_update_merged_barcode_table=false
    for line in $(echo "$A" | grep  "^diff" | awk '{print $3}' | grep -v "^/dev/null" | cut -c 3- | grep -E "^runprocessing|^mgirunprocessing|^ontcovidrunprocessing"); do
#        if [ "$line" == "runprocessing/event_service.sh" ] || [ "$line" == "runprocessing/email_config.csv" ]; then
        if [ -f "$target_DIR/$line" ]; then
            if [ "$line" == "runprocessing/event_service.sh" ]; then
		printf "cd /home/\$LIMSUSER/runprocessing;<br>\n";
		printf "sh event_service.sh stop;<br>\n";
		printf "cp \$LOCALREPO/clarity/$line /home/\$LIMSUSER/$line;<br>\n";
		printf "sh event_service.sh start;<br><br>\n";
            else
		printf "cp \$LOCALREPO/clarity/$line /home/\$LIMSUSER/$line;<br><br>\n"; 
            fi
	    
            if [ "$line" == "runprocessing/adapter_settings_format.txt" ] || [ "$line" == "runprocessing/adapter_settings_format.txt" ] || [ "$line" == "runprocessing/update_merged_barcode_table.rb" ]; then
		run_update_merged_barcode_table=true;
	    fi
	else
	    printf "rm /home/\$LIMSUSER/$line;<br>\n";
	fi
    done
    if $run_update_merged_barcode_table; then
	printf "cd /home/\$LIMSUSER/runprocessing;<br>\n";
	printf "ruby update_merged_barcode_table.rb;<br>\n";
    fi
    printf "</code>\n";
fi
printf "<br>\n";

printf "</body>\n";
printf "</html>\n";
)

if($testmode); then
    EMAILSRN=$(cat <<EOF
"$USER" <$JOB_MAIL>
EOF
);
else
    EMAILSRN=$(cat <<EOF
"Janick St-Cyr, Mrs" <janick.st-cyr@mcgill.ca>
"Elizabeth Caron, Mrs" <elizabeth.caron2@mcgill.ca>
"Thay Leng Tony Tir, Mr" <thay.tir@mcgill.ca>
"Patrick Willett, Mr" <patrick.willett@mcgill.ca>
"Marlon Salim Amersi, Mr" <marlon.amersi@mcgill.ca>
"Pierre Berube" <pierre.berube@mcgill.ca>
"Sherry Chen" <shu-huang.chen@mcgill.ca>
"Yu Chang Wang, Mr" <yc.wang@mcgill.ca>
"Mhd Fadi Al Kayal, Mr" <fadi.alkayal@mcgill.ca>
"Nimara Bader Asbah, Miss" <nimara.asbah@mcgill.ca>
"Timoth�e Revil, Dr" <timothee.revil@mcgill.ca>
"Corinne Darmond" <corinne.darmond@mcgill.ca>
"Ariane Boisclair, Mrs" <ariane.boisclair@mcgill.ca>
"Lena Li Chun Fong, Miss" <lena.lichunfong@mcgill.ca>
"Marie-Michelle Simon, Mrs" <marie-michelle.simon@mcgill.ca>
"Sarah Julia Reiling, Dr" <sarah.reiling@mcgill.ca>
"Ashot Harutyunyan, Dr" <ashot.harutyunyan@mcgill.ca>
"Anne-Marie Roy, Ms" <anne-marie.roy@mcgill.ca>
"Brent E. Brookes, Mr" <brent.brookes@mcgill.ca>
"David Bujold, Mr" <david.bujold@mcgill.ca>
"Antoine Paccard, Dr" <antoine.paccard@mcgill.ca>
"Tony Kwan, Dr." <tony.kwan@mcgill.ca>
"Ioannis Ragoussis, Dr" <ioannis.ragoussis@mcgill.ca>
"Haig Hugo Vrej Djambazian, Mr" <haig.djambazian@mcgill.ca>
"Robert Andrew Syme, M" <robert.syme@mcgill.ca>
"Francois Lefebvre, M" <francois.lefebvre@mcgill.ca>
"Ulysse Fortier Gauthier, Mr" <ulysse.fortiergauthier@mcgill.ca>
"Jose Hector Galvez Lopez, Mr" <jose.galvezlopez@mcgill.ca>
"Romain Gr�goire, Mr" <romain.gregoire@mcgill.ca>
"Andres Tocasuche, Mr" <andres.tocasuche@mcgill.ca>
"Terrance McQuilkin, Mr" <terrance.mcquilkin2@mcgill.ca>
"Raul Baldin, Mr" <raul.baldin@mcgill.ca>
"Andras Frankel, Mr" <andras.frankel@mcgill.ca>
"Haiyong You, Mr" <haiyong.you@mcgill.ca>
EOF
);


fi

if [ "$mode" == "release_notes" ] || [ "$mode" == "pre_release" ]; then

(
# echo "From: hercules@mcgill.ca"
# echo "From: bravo.genome@mcgill.ca"
echo "Reply-To: hercules@mcgill.ca"
echo "To: $(echo "$EMAILSRN" | tr '\n' ',' | rev | cut -c 2- | rev)"
echo "MIME-Version: 1.0"
if [ "$mode" == "release_notes" ]; then
    echo "Subject: McGill Genome Centre LIMS version $target_version is now deployed in production."
else
    echo "Subject: McGill Genome Centre LIMS version $target_version passed final acceptance."
fi
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo
echo "$HTML"
if [ "$mode" == "release_notes" ]; then
    echo '---q1w2e3r4t5'
    echo "Content-Type: text/plain; charset=utf-8; name=CHANGELOG.html"
    echo 'Content-Transfer-Encoding: base64'
    echo "Content-Disposition: attachment; filename=CHANGELOG.html"
    echo
    echo "$HTMLFULL"  | base64
    echo '---q1w2e3r4t5'
    echo "Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; name=MGC_Sample_Submission_Template_BLANK.xlsx"
    echo 'Content-Transfer-Encoding: base64'
    echo "Content-Disposition: attachment; filename=MGC_Sample_Submission_Template_BLANK.xlsx"
    echo
    base64 "$target_DIR/samplesubmissiontemplates/MGC_Sample_Submission_Template_BLANK.xlsx"
    echo '---q1w2e3r4t5--'
fi
) | sendmail -t -f bravo.genome@mcgill.ca && echo "$mode email sent to "$(echo "$EMAILSRN" | tr '\n' ',')" for branch: $target_BRANCH, version: $target_version."

fi


if [ "$mode" != "release_notes" ] && [ "$mode" != "pre_release" ]; then

if [ "$mode" == "$deploy_dev" ]; then
    DEPLOYEMAIL=$(cat <<EOF
"$USER" <$JOB_MAIL>
EOF
);
else
    if($testmode); then
        DEPLOYEMAIL=$(cat <<EOF
"$USER" <$JOB_MAIL>
EOF
);
    else
# "It Genome" <it.genome@mail.mcgill.ca>
        DEPLOYEMAIL=$(cat <<EOF
"$USER" <$JOB_MAIL>
EOF
);


    fi

fi


# (  
# # echo "From: bravo.genome@mcgill.ca"
# # echo "From: abacus.genome@mail.mcgill.ca"
# echo "To: $(echo "$DEPLOYEMAIL" | tr '\n' ',' | rev | cut -c 2- | rev)"
# echo "Reply-To: hercules@mcgill.ca"
# echo "MIME-Version: 1.0"
# echo "Subject: Deployment Instructions for $instance, branch: $target_BRANCH:$target_version"
# echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
# echo
# echo '---q1w2e3r4t5'
# echo "Content-Type: text/html"
# echo
# echo "$HTML"
# echo
# echo "$HTMLDEPLOYINSTRUCTIONS"
# ) | sendmail -t -f bravo.genome@mcgill.ca && echo "Deployment instructions email sent to "$(echo "$DEPLOYEMAIL" | tr '\n' ',')" for branch: $target_BRANCH, version: $target_version on instance: $instance."

# printf "$HTMLDEPLOYINSTRUCTIONS\n$HTML" | mailx -s "Deployment Instructions for $instance, branch: $target_BRANCH, version: $target_version" -r "abacus.genome@mail.mcgill.ca" haig.djambazian@mcgill.ca

(
echo "## [$target_version] deployed from [$previous_version] - $DATE"

if [ "$mode" == "deploy_dev" ]; then
echo "$HTMLDEPLOYINSTRUCTIONS" | sed 's|<br>||g'  | sed 's|</h3>||g'  | sed 's|</h2>||g'  | sed 's|</code>|\n```\n|g'  | sed 's|<code>|\n```\n|g' | sed 's|<h3>|\n### |g' | sed 's|<h2>|\n## |g'   | grep -v -E 'body|html|head' | awk '/<\/style>/ {seen = 1} seen {print}' | tail -n +2 | grep -v '^$'  
else
echo "$HTMLDEPLOYINSTRUCTIONS" | sed 's|<br>||g'  | sed 's|</h3>||g'  | sed 's|</h2>||g'  | sed 's|</code>|\n```\n|g'  | sed 's|<code>|\n```\n|g' | sed 's|<h3>|\n### |g' | sed 's|<h2>|\n## |g'   | grep -v -E 'body|html|head' | awk '/<\/style>/ {seen = 1} seen {print}' | tail -n +2 | grep -v '^$' | sed "s|/mnt/drop/$partial_DIR|\$LOCALREPO|g" | sed "s|$target_DIR|\$LOCALREPO|g" 
fi

echo "###"
echo "[see changes](https://bitbucket.org/mugqic/clarity/branches/compare/$target_version%0D$previous_version#diff)"
echo
) >> DEPLOYMENT_TEXT.txt
fi




} # run

run

