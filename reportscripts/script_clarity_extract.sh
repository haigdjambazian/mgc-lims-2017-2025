#!/bin/bash

# for bravoprodapp /lb/bravo/bravoprod/drop is mounted as /mnt/drop

mkdir -p /mnt/drop/claritydump
mkdir -p /mnt/drop/claritydump.tmp

# date > /mnt/drop/claritydump.tmp/TIMESTAMP

DATABASECRED=ClarityLIMS

IFS=$'\n';
TAB="$(printf '\t')";

###############################################
# GET MAIN MAPPING

echo -n "GET PROCESSIOTRACKER DATA ... "

a=$(psql  $DATABASECRED << EOF
COPY ( select inputart.artifactid as inid, outputart.artifactid as outid, inputart.isoriginal, pt.displayname as pname, pt.typename as ptypename, p.processid as pid, 
p.luid as pluid, p.workstatus as pworkstatus, inputart.luid as inputluid, outputart.luid as outputluid, tin.displayname as intype, tout.displayname as outtype,
p.daterun as daterun
from processiotracker io
join artifact a on a.artifactid = io.inputartifactid
left join outputmapping om on om.trackerid = io.trackerid
left join artifact outputart on om.outputartifactid = outputart.artifactid
join artifact inputart on io.inputartifactid = inputart.artifactid
join process p on p.processid = io.processid
join processtype pt on p.typeid = pt.typeid
left join artifacttype tout on tout.typeid = outputart.artifacttypeid
left join artifacttype tin on tin.typeid = inputart.artifacttypeid
) TO STDOUT with delimiter '$TAB';
EOF
);

DATA=/mnt/drop/claritydump.tmp/artifact_graph.txt;
HEADER=$(printf "a_inid,b_outid,c_isoriginal,d_pname,e_ptypename,f_pid,g_pluid,h_pworkstatus,i_inputluid,j_outputluid,k_intype,l_outtype,m_daterun" | tr ',' '\t');
(printf "$HEADER\n"; echo "$a" | grep "$(printf "Analyte\tAnalyte")") > $DATA;

DATA=/mnt/drop/claritydump.tmp/resultfile_graph.txt;
HEADER=$(printf "a_inid,b_outid,c_isoriginal,d_pname,e_ptypename,f_pid,g_pluid,h_pworkstatus,i_inputluid,j_outputluid,k_intype,l_outtype,m_daterun" | tr ',' '\t');
(printf "$HEADER\n"; echo "$a" | grep -v "$(printf "Analyte\tAnalyte")") > $DATA;

echo "done.";

###############################################
# GET ARTIFACT UDF

echo -n "GET ARTIFACT UDF ... "
DATA=/mnt/drop/claritydump.tmp/artifact_udf.txt;
HEADER=$(printf "artifactid,udfid,udfname,udftype,udfvalue" | tr ',' '\t');
printf "$HEADER\n" > $DATA;
(psql  $DATABASECRED << EOF
COPY (SELECT artifactid, udfid, udfname, udftype, udfvalue FROM artifact_udf_view WHERE udfvalue != ''
) TO STDOUT with delimiter '$TAB';
EOF
) >> $DATA;

echo "done.";

########################################
# GET PROTOCOL UDF

echo -n "GET PROTOCOL UDF ... "
DATA=/mnt/drop/claritydump.tmp/process_udf.txt;
HEADER=$(printf "processid,typeid,udtname,udfid,udfname,udftype,udfvalue,udfunitlabel" | tr ',' '\t');
printf "$HEADER\n" > $DATA;
(psql  $DATABASECRED << EOF
COPY (SELECT processid, typeid, udtname, udfid, udfname, udftype, udfvalue, udfunitlabel FROM process_udf_view WHERE udfvalue != ''
) TO STDOUT with delimiter '$TAB';
EOF
) >> $DATA;

echo "done.";

###############################################
# GET REAGENT LABEL

echo -n "GET REAGENT LABEL ... "
DATA=/mnt/drop/claritydump.tmp/artifact_reagentlabel.txt;
HEADER=$(printf "alm.artifactid,r.name" | tr ',' '\t');
printf "$HEADER\n" > $DATA;
(psql  $DATABASECRED << EOF
COPY (SELECT alm.artifactid, r.name
FROM reagentlabel r
JOIN artifact_label_map alm ON alm.labelid = r.labelid
) TO STDOUT with delimiter '$TAB';
EOF
) >> $DATA;

echo "done."

###############################################
# GET PROCESS REAGENT KIT

echo -n "GET PROCESS REAGENT KIT ... "
DATA=/mnt/drop/claritydump.tmp/process_reagentkit.txt;
HEADER=$(printf "rs.processid,rk.name,r.name,r.lotnumber" | tr ',' '\t');
printf "$HEADER\n" > $DATA;
(psql  $DATABASECRED << EOF
COPY ( SELECT rs.processid, rk.name, r.name, r.lotnumber FROM reagentlot r
JOIN reagentlotselection rs on rs.reagentlotid = r.reagentlotid
JOIN reagentkit rk on rk.reagentkitid = r.reagentkitid
) TO STDOUT with delimiter '$TAB';
EOF
) >> $DATA;

echo "done."

###############################################
# GET SUBMITTED SAMPLE UDF

echo -n "GET SUBMITTED SAMPLE UDF ... "
DATA=/mnt/drop/claritydump.tmp/sample_udf.txt;
HEADER=$(printf "artifactid,udfname,udfvalue" | tr ',' '\t');
printf "$HEADER\n" > $DATA
( psql  $DATABASECRED << EOF
COPY (SELECT a.artifactid, suv.udfname, suv.udfvalue FROM artifact a
join artifact_sample_map asm on asm.artifactid = a.artifactid
join sample s on s.processid = asm.processid
join sample_udf_view suv on suv.sampleid = s.sampleid
where suv.udfvalue != ''
) TO STDOUT with delimiter '$TAB'
EOF
) >> $DATA

echo "done."

###############################################
# GET ARTIFACT CONTAINER

echo -n "GET ARTIFACT CONTAINER ... "
DATA=/mnt/drop/claritydump.tmp/artifact_container.txt;
HEADER=$(printf "processartifactid,containertype,containerid,containername,wellxposition,numxpositions,isxalpha,wellyposition,numypositions,isyalpha" | tr ',' '\t');
printf "$HEADER\n" > $DATA
(psql  $DATABASECRED << EOF
COPY (SELECT cp.processartifactid, ct.name, cp.containerid, c.name, cp.wellxposition, ct.numxpositions, ct.isxalpha, cp.wellyposition, ct.numypositions, ct.isyalpha from containerplacement cp
join container c on c.containerid = cp.containerid
join containertype ct on ct.typeid = c.typeid
) TO STDOUT with delimiter '$TAB'
EOF
) >> $DATA

echo "done."

###############################################
# GET PROJECT DETAILS

echo -n "GET PROJECT DETAILS ... "
DATA=/mnt/drop/claritydump.tmp/project_details.txt;
HEADER=$(printf "artifactid,p.projectid,p.name,p.luid,r.firstname,r.lastname,sampleid,samplename,datereceived" | tr ',' '\t');
printf "$HEADER\n" > $DATA
(psql  $DATABASECRED << EOF
COPY (SELECT asm.artifactid, p.projectid, p.name, p.luid, r.firstname, r.lastname, s.sampleid, s.name, s.datereceived FROM sample s
join artifact_sample_map asm on s.processid = asm.processid
join project p on p.projectid = s.projectid
join researcher r on r.researcherid = p.researcherid
) TO STDOUT with delimiter '$TAB';
EOF
) >> $DATA

echo "done."  

###############################################
# GET QC FLAGS

echo -n "GET QC FLAGS ... "
DATA=/mnt/drop/claritydump.tmp/qc_flags.txt;
HEADER=$(printf "artifactid,qcflag" | tr ',' '\t');
printf "$HEADER\n" > $DATA
(psql  $DATABASECRED << EOF
COPY (select a.artifactid, ast.qcflag
from artifact a
join artifactstate ast ON a.currentstateid = ast.stateid
where ast.qcflag != 0
) TO STDOUT with delimiter '$TAB';
EOF
) >> $DATA

echo "done."

###############################################
# GET FILES

echo -n "GET FILES ... "
DATA=/mnt/drop/claritydump.tmp/artifact_files.txt;
HEADER=$(printf "artifactid,typeofoutputgeneration,filelabel,gls.contenturi,gls.originallocation" | tr ',' '\t');
printf "$HEADER\n" > $DATA
(psql  $DATABASECRED << EOF
COPY (SELECT rf.artifactid, pot.typeofoutputgeneration, a.name, gls.contenturi, gls.originallocation FROM glsfile gls
join resultfile rf ON rf.glsfileid = gls.fileid
join artifact a ON a.artifactid = rf.artifactid
join processoutputtype pot ON pot.typeid = a.processoutputtypeid
) TO STDOUT with delimiter '$TAB'
EOF
) >> $DATA

echo "done."


###############################################
# GET FILES

echo -n "GET PROJECT UDF ... "
DATA=/mnt/drop/claritydump.tmp/project_udf.txt;
HEADER=$(printf "projectid,udfname,udfvalue" | tr ',' '\t');
printf "$HEADER\n" > $DATA
(psql  $DATABASECRED << EOF
COPY (SELECT pj.projectid, euv.udfname, euv.udfvalue FROM project pj
left outer join entity_udf_view euv on euv.attachtoid = pj.projectid and euv.attachtoclassid = 83 WHERE euv.udfvalue != ''
) TO STDOUT with delimiter '$TAB'
EOF
) >> $DATA

echo "done."

###############################################
# DO FINAL MOVE

mv /mnt/drop/claritydump            /mnt/drop/claritydump.old
mv /mnt/drop/claritydump.tmp        /mnt/drop/claritydump
date > /mnt/drop/claritydump/TIMESTAMP

rm -r /mnt/drop/claritydump.old
