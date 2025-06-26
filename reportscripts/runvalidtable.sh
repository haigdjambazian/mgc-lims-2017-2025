#!/bin/bash

TIMESTAMP_BOOTSTRAP=$1

# TIMESTAMP_BOOTSTRAP=2019-03-19T17.50.27

failicon="iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAmxJREFUeNqEU21IU1EYfu7dILepWx+bKV67mhZpxS2i8IeEECmF9qtfBU0oTKNRGn38KSX6YWQGKX0RriKKfgRKCOEP/Z8tBwVpbk5XxtS5zdic+7i3c45e0bbwgYdz3/ec85znfXkv13yrzQTAS5iJ9TF8r+XqPjXgOA5asvbl5pgzj1SUo3RnMUumg8vjxYf+AelKy90v7a3XVkR4wvKKQwcgFgiILCwiHImm5VaLGSdrqukdSVEUqKQOUFIkQpZl3HnwaOXFC3Wn0NX9eiW+bquHQa9PcUYdsMuUFDfIQQqdLoOtTfV1LMf9pylaVUCF+k3tLUFZs7+ug7bOZ0sdXj5w/4md5XieTyu07CDJgubzVra2P7azHI3Doz8w0tCIKcGCLcePIW9sFP3bigPkgcpQT+0wc5AkyqvJREkJYZcLI02XUNZQg5nupxhvvY3DugT2vOww8VmZA8YTvdKaElTazp5GYiEK57l67K4pg5GM2t6GahjgR/GZo9Abeey42WgiTw2kNFFFTJFRYLsIz/vnKDWQZukMEA4KkKfcSPIb4HrYAxnKZSaQTKYKaDRabKqqQsjhwOSnr8jdlQNtRggaIjTW/x3zE7/ttV63nZXgnvCmlEHp6+tD4vMgsrMURGcDhHOIzkxD2G+BbrPe2isUWanA4JDzG9yTPxFPxEnzZMbYn3mMd3ZhYzaPxdkwIr4QPI5fiPoDiJO9PCJCfHdwdGDIDxIgQqZ/y9D5Z1HysRfbzRx80zHMGS3DBVxQsggGeJzBoBKXK1dNXHrY80XpRb4YeJUvsiF5I4jWt0Jh4J1QKNH4rwADABgeNpSsbOY5AAAAAElFTkSuQmCC"

passicon="iVBORw0KGgoAAAANSUhEUgAAABIAAAAQCAYAAAAbBi9cAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAkpJREFUeNqck0toE1EUhv95prS2loLWVKIxNKRWGkdQgoXIRAy4cNOVGxeOiq9FUIoUcSEiVooERQSVboKblipVhOpCJakBJVWKKaRNfARaxVKjmBjyaJKZMTN2QkwaIp7hcOec8/Pd/15miP6LQ60AHhaTR/3wFbPPfWkgXjmgFYi+fR2/z74b27rMNQmh8Ac897/mF5diyqaOyjmpOLHbdsK4yYBUOlszlbmiq+VccQSzyQhJknDlxu3S4MKZU1W1YaO+pmMVpEC0OO86gas375Z6Sq1pWIb5d5D2XrnWiyrQ0K3hvwBafe700ZLm8oSzldIVvCQtxwnIfQP8ZHwFJKqC/pOH1dV9x6P2tLpcQ5AFiFnW27XeyhG0hPexoHfwmcOhgsRV7Gu9UPQNCALo3rILy/kMmPYIOtvM3F7L/mKfglwgufC3GS+92j24jh1SezPht3gRGAXFEkhnMoh8mYJhA4EeE4PvyQAa2Q5QYpPi8B1d60KngwE88Y3CdiAPhqbge/kIHZsJWLbq8CuXQLaQhnf6ExZiSc/gkQnhz9HEatD98RFY9qRANEmQKRKcM4dGHVWE5MCSDMJBCl+XRI/77ANB+7IRnf+suirP44ILcz4WPxZk5DIi8tIykrkMErkUpvx5RMMKZETQNqZ6eScfTySNDQ06rG1ZA3nlaW5uQaepG+P3XqFNL4LVAXLR+Owkg8WPtGf42phQfgKi3t+fSsYRCfnBH2SwMEciNs96Ho89FfA/YeV6uO07rD977bbrtTS/BRgA4Mod+em2wpgAAAAASUVORK5CYII="

questionicon="iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAB3ElEQVR42mNkwAHit32aICDKno8s9vzZh9ZV/uI1yGKM2DRHbP7UmmDEXcTOzMjxjQmo5P9/BtZ/DAxH7n18te3ip8YzWfLTcBoQu/VTSa8Hb/fJdwwMP/4yMPz+z8DwHYhZgCql+RkY1p95/+Xu4x8Ld0RL5WA1IHj9u3vF3oKKtz8wMJz9AFGgx8vA8OHbfwYONkaGr19/M9x8/PX9XFdBIawGuK58/d1Qno/j2vOP57YEihmDxNJWPPyvbyvH8OMXA8Onz38YXn369mW6DT8vzjBAB6mrH/3XMJVlYAJ65T3QBTfufPi3KkCMmSgDDHtu/l+SpcYw6+ovBj4pNoYrx168fP7wff2JEq2ZBA0AaZ6cqcbQdPEfw0eg0ifXPjE8nbRHj+FSyGW80QgG5tvNDEOVTopaqYC5jx98Yrjet8uK4Uz4cYLpAAT4+p7niqsKTYLxX95+t+9TkaQzujp8BiQAKVBKfAvEPEC8AmjABKINIBbgNcC87vQjIQNF2ZvHb7++t+2CNMPVzN9EG2Bdd/6mRbaB2urTDAyPrr9iYDx4+sX/LT6SRBtgOvP+/6fs4gzPnn5hYHj2mYHh84tPDIus+UnyguTCz4+eP3oly/Dp11OGbk0ZbGoA9qfAETkQhkkAAAAASUVORK5CYII="

url='https://bravoprodapp.genome.mcgill.ca/clarity/work-details/'

OUTFILE=$TIMESTAMP_BOOTSTRAP/projects/run-validation-table.html

IFS=$'\n'

function mktable {

lanes=$1
ceiling=$2

C=$(for _LIBNORMPROC in $(echo "$B" | awk -F $'\t' '{print substr($8,4)}' | sort -u | sort -nr | head -n $ceiling); do
   FIRSTLINE=true
   cnt=0
   for line in $(echo "$B" | grep "24-$_LIBNORMPROC" ); do 
       STEPNAME=$(echo "$line" | awk -F $'\t' '{print $1}')
       LIBNORMPROC=$(echo "$line" | awk -F $'\t' '{print $2}' | sed 's/24-//g')
       STRIPTUBENAME=$(echo "$line" | awk -F $'\t' '{print $3}')
       FCID=$(echo "$line" | awk -F $'\t' '{print $4}')
       LANE=$(echo "$line" | awk -F $'\t' '{print $5}')
       DATE=$(echo "$line" | awk -F $'\t' '{print $6}')
       RUNID=$(echo "$line" | awk -F $'\t' '{print $7}')
       SEQPROC=$(echo "$line" | awk -F $'\t' '{print $8}' | sed 's/24-//g')
       QCFLAG=$(echo "$line" | awk -F $'\t' '{print $9}')
       STATUS=$(echo "$line" | awk -F $'\t' '{print $10}')
       COMMENTS=$(echo "$line" | awk -F $'\t' '{print $11}' | tr -d '%')
       if ($FIRSTLINE); then
          FIRSTLINE=false;
          printf "u|$SEQPROC\tu|$LIBNORMPROC\tt|$STRIPTUBENAME\tt|$FCID\ti|$QCFLAG"
          let cnt=$cnt+1
       else
          printf "\ti|$QCFLAG"
          let cnt=$cnt+1
       fi
    done

    if [ "$cnt" == "2" ]; then
        printf "\tt|\tt|\tt|\tt|\tt|\tt|\tt|$COMMENTS\n"
    elif [ "$cnt" == "4" ]; then
        printf "\tt|\tt|\tt|\tt|\tt|$COMMENTS\n"
    else
        printf "\tt|$COMMENTS\n"
    fi
done | sort -k3)

# echo "$C"

printf "<tr><th>Sequencing Step</th><th>Lib Norm Step</th><th>Run Counter</th><th>Flowcell ID</th>" >> $OUTFILE

for lane in $(echo "$lanes" | tr '-' '\n'); do
  printf "<th>L00$lane</th>\n"
done >> $OUTFILE

printf "<th>Comments</th>\n" >> $OUTFILE

printf "\n" >> $OUTFILE

for line in $(echo "$C" ); do 

 printf "<tr>"

   for el in $(echo "$line" | tr '\t' '\n'); do
   p1=$(echo "$el" | awk -F'|' '{print $1}')
   p2=$(echo "$el" | awk -F'|' '{print $2}')
   if [ "$p1" == "t" ]; then
       printf "<td>$p2</td>"
   fi
   if [ "$p1" == "i" ]; then
       if [ "$p2" == "0" ]; then
           printf "<td><img src=\"data:image/png;base64,$questionicon\"></td>\n"
       fi
       if [ "$p2" == "1" ]; then
           printf "<td><img src=\"data:image/png;base64,$passicon\"></td>\n"
       fi
       if [ "$p2" == "2" ]; then
           printf "<td><img src=\"data:image/png;base64,$failicon\"></td>\n"
       fi
   fi
   if [ "$p1" == "u" ]; then   
       printf "<td><a href=\"$url$p2\">24-$p2</a></td>\n"
   fi
   done
   printf "</tr>\n"
done >> $OUTFILE


}


A=$(cat $TIMESTAMP_BOOTSTRAP/illumina_report_HiSeqX.txt $TIMESTAMP_BOOTSTRAP/illumina_report_NovaSeq.txt | grep RECORD_DETAILS | \
  awk -F'\t' '{print $132"\t"$12"\t"$87"\t"$91"\t"$92"\t"$93"\t"$18"\t"$133"\t"$135"\t"$136"\t"$137}' | sort -u)

D=$(cat $TIMESTAMP_BOOTSTRAP/illumina_report_HiSeqX.txt $TIMESTAMP_BOOTSTRAP/illumina_report_NovaSeq.txt | grep COMPLETE | \
  awk -F'\t' '{print $132"\t"$12"\t"$87"\t"$91"\t"$92"\t"$93"\t"$18"\t"$133"\t"$135"\t"$136"\t"$137}' | sort -u)


rm -f $OUTFILE

echo "<!doctype html><html><head><title>Run Validation Page</title>
<style>
table.style2 { border-collapse: collapse; border: 1px solid black; border-style: solid; table-layout: auto; width:100%}
table.style2 th { border: 1px solid black; border-style: solid; padding: 3px; background: #D0D0D0; color: #000000; }
table.style2 td { border: 1px solid black; border-style: solid; padding: 3px; background: #FFFFFF; color: #000000; }
</style>
</head>
<body>" >> $OUTFILE

printf "<table class=\"style2\">\n" >> $OUTFILE

echo "<tr><th>HiSeq X runs to be Validated/Released</th></tr>" >> $OUTFILE
B=$(echo "$A" | grep "HiSeq X" )
mktable 1-2-3-4-5-6-7-8 1000000

echo "<tr><th>NovaSeq runs to  be Validated/Released</th></tr>" >> $OUTFILE
B=$(echo "$A" | grep "NovaSeq" )
mktable 1-2-3-4-5-6-7-8 1000000

echo "<tr><th>HiSeq X already Validated (last 40 shown)</th></tr>" >> $OUTFILE
B=$(echo "$D" | grep "HiSeq X")
mktable 1-2-3-4-5-6-7-8 40

echo "<tr><th>NovaSeq already validated (last 40 shown)</th></tr>" >> $OUTFILE
B=$(echo "$D" | grep "NovaSeq")
mktable 1-2-3-4-5-6-7-8 40

printf "</table>\n" >> $OUTFILE


echo "</body></html>" >> $OUTFILE
