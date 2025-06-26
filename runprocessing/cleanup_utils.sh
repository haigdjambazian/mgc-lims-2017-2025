#!/bin/bash

# usage: deletescriptextra nb "/" 21
#        deletescriptextra nb "testprocessing" 21 &
#        checkrobotsizegeneral nb > LOG

# all of these generate deletion scripts an do not actually delete themselves.


function checkrobotsizegeneral {

  root=$1

  IFS=$'\n';

  rm ${root}deletelistgeneral.txt

  A=$(ls -d /$root/Research/*/*_*_*_* | grep -v -E 'iSeq|Miseq|processing')
  
  for rundir_raw in $(echo "$A") ; do
    
       rundir=$(ls -d /$root/Research/processing/$(echo $(basename $rundir_raw) | awk -F"_" '{print $1 "_" $2 "_" $3 "_" $4}')* 2>/dev/null);
       if [ ! -d "$rundir" ]; then
         echo "/$root/Research/processing of $(basename $rundir_raw) does not exist";
         continue
       fi
       
       rundir_robot=$(ls -d /lb/robot/research/processing/*/20*/$(echo $(basename $rundir_raw) | awk -F"_" '{print $1 "_" $2 "_" $3 "_" $4}')*  2>/dev/null);
       if [ ! -d "$rundir_robot" ]; then
         echo "/lb/robot/research/processing of $(basename $rundir_raw) does not exist";
         continue
       fi
       
       if [ "$(echo "$rundir" | rev | awk -F'-' '{print $1}' | rev)" == "novaseq" ]; then
           lanes="1 2 3 4"
       else
           lanes="1 2 3 4 5 6 7 8"
       fi
       
       for lane in $( echo "$lanes" | tr ' ' '\n'); do
         
         for samplefastqdir in $(ls -d $rundir/Unaligned.$lane/Project_*/Sample_* 2>/dev/null); do
           if [ -d "$samplefastqdir" ]; then
               samplename_libid=$(echo "$(basename $samplefastqdir)" | sed 's/Sample_//g')
               if [[ "$samplename_libid" == *_A ]] || [[ "$samplename_libid" == *_B ]] || [[ "$samplename_libid" == *_C ]] || [[ "$samplename_libid" == *_D ]]; then
                   continue;
               fi
               echo -n "$rundir,$lane,$samplename_libid,"
               savef=""
               readfoundmatch=0
               readonscratch=0
               readonrobot=0
               for read in 1 2; do
                   f=$(ls $samplefastqdir/${samplename_libid}_S*_L00${lane}_R${read}_001.fastq.gz 2>/dev/null);
                   v1="1"
                   if [ -f "$f" ]; then
                       let readonscratch=$readonscratch+1
                       savef="$savef $f";
                       v1=$(ls -l $f | awk '{print $5}' 2>/dev/null)
                       echo -n "R$read,"
                   else
                       echo -n "-,"
                   fi
                   # g=$(ls /lb/robot/research/processing/*/20*/$(echo $f | sed "s|/$root/Research/processing/||g") 2>/dev/null);
                   g=$(ls $rundir_robot/$(echo $samplefastqdir | sed "s|$rundir/||g")/${samplename_libid}_S*_L00${lane}_R${read}_001.fastq.gz 2>/dev/null);
                   v2="2"
                   if [ -f "$g" ]; then
                      let readonrobot=$readonrobot+1
                      v2=$(ls -l $g | awk '{print $5}' 2>/dev/null)
                      if [ "$v1" != "$v2" ]; then
                         if [ -f "$f" ]; then
                             echo -n "N,"
                         else
                             echo -n "D,"
                             let readfoundmatch=$readfoundmatch+1
                         fi
                      else
                         echo -n "Y,"
                         let readfoundmatch=$readfoundmatch+1
                      fi
                   else
                      echo -n "-,"
                   fi
                                     
               done
               
#                samplename=$(echo "$samplename_libid" |  rev | cut -d - -f 2- | cut -c 3- | rev)
               samplename=$(echo "$samplename_libid" |  rev | cut -d _ -f 2- | rev)
               f=$(ls $rundir/Aligned.$lane/alignment/$samplename/run*_*/$samplename_libid.sorted.bam 2>/dev/null)
               bamfoundmatch=0
               bamonscratch=0
               bamonrobot=0
               v1="1"
               if [ -f "$f" ]; then
                   let bamonscratch=$bamonscratch+1
                   savef="$savef $f";
                   v1=$(ls -l $f | awk '{print $5}' 2>/dev/null)
                   echo -n "B,"
               else
                   echo -n "-,"
               fi
               # g=$(ls /lb/robot/research/processing/*/20*/$(echo $f | sed "s|/$root/Research/processing/||g") 2>/dev/null);
               g=$(ls $rundir_robot/Aligned.$lane/alignment/$samplename/run*_*/$samplename_libid.sorted.bam 2>/dev/null);
               v2="2"
               if [ -f "$g" ]; then
                  let bamonrobot=$bamonrobot+1
                  v2=$(ls -l $g | awk '{print $5}' 2>/dev/null)
                  if [ "$v1" != "$v2" ]; then
                     if [ -f "$f" ]; then
                         echo -n "N"
                     else
                         echo -n "D"
                         bamfoundmatch=1
                     fi
                  else
                     echo -n "Y"
                     bamfoundmatch=1
                  fi
               else
                  echo -n "-"
               fi
               
#               if [ "$bamonscratch" == "1" ] && [ "$bamonrobot" == "1" ] && [ "$bamfoundmatch" == "1" ]; then
               if [ "$bamonrobot" == "1" ] && [ "$bamfoundmatch" == "1" ]; then
                  if [ "$bamonscratch" == "1" ]; then
                     echo "rm -v $savef" >> ${root}deletelistgeneral.txt
                 fi
                   printf "\n";
                 
#               elif [ "$readonscratch" != "0" ] && [ "$readonrobot" != "0" ] && [ "$readfoundmatch" != "0" ]; then
               elif [ "$readonrobot" != "0" ] && [ "$readfoundmatch" != "0" ]; then
                 if [ "$readonscratch" != "0" ]; then
                   echo "rm -v $savef" >> ${root}deletelistgeneral.txt
                 fi
                 printf "\n";
               else
                   if [ "$readonscratch" == "0" ] && [ "$bamonscratch" == "0" ]; then
                       printf "\n";
                   else
                       echo ",verify"
                   fi
               fi
               
           else
               echo "$rundir,$lane,-,-,-,-,-"
           fi
         done
       done
       
   done

}





function deletescriptextra {


   root=$1
   ONTEST=$2
   DATE=$3

printf "root=$1\nONTEST=$2\nDATE=$3\n"

   ONTESTstr=$(echo $ONTEST | tr -d '/')

   echo "# delete list" > ${root}${DATE}${ONTESTstr}deletelistextra.txt

   A=$(ls -d /$root/Research/processing/$ONTESTstr/$DATE*_*_*_* | grep -v -E 'iSeq|Miseq' | awk -F'_' '{print $4}')

echo "$A" | head 

   for runid in $(echo "$A"); do
       for d in $(ls -d /$root/Research/processing/$ONTESTstr/*${runid}*/javatmp 2>/dev/null); do
           if [ -d "$d" ]; then
             echo "rm -r $d" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done
   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*/Project_*/Sample_*/*.fastq.gz.orig 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done
   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*.indexed/*.fastq.gz 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done
   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*/*.fastq.gz 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done

   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*.indexed/P*/S*/*.fastq.gz 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done


   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*/P*/S*/sample_tag*/*.fastq 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done
   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*/P*/S*/sample_tag*/*.fasta 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done
   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*/P*/S*/sample_tag*/*.qual 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done

#   for runid in $(echo "$A"); do
#       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*.noindex/*.fastq.gz 2>/dev/null); do
#           if [ -f "$f" ]; then
#             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
#           fi
#       done
#   done
#   for runid in $(echo "$A"); do
#       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Unaligned.*.noindex/P*/S*/*.fastq.gz 2>/dev/null); do
#           if [ -f "$f" ]; then
#             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
#           fi
#       done
#   done

   for runid in $(echo "$A"); do
       for f in $(ls /$root/Research/processing/$ONTESTstr/*${runid}*/Aligned.*/alignment/*/run*_*/*dup.bam 2>/dev/null); do
           if [ -f "$f" ]; then
             echo "rm -v $f" >> ${root}${DATE}${ONTESTstr}deletelistextra.txt
printf "."
           fi
       done
   done
  
}
