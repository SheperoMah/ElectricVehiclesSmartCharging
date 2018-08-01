#!/bin/bash
# EXAMPLE RUN
#./extractData.sh results20162017.tex resultsCleaned.txt 1 7 9

FILENAME=$1
NEWFILENAME=$2
varNum1=$3
varNum2=$4
varNum3=$5

if [ ! -f "$NEWFILENAME" ]; then
 echo "caseName optimizedPeak dumbPeak computationTime" > $NEWFILENAME
fi
 

awk -v var1="${varNum1}" -v var2="${varNum2}" -v var3="${varNum3}" '{
if (NF)
    { n=split($var2, array, ",");
      print $var1, array[1], array[2], $var3}
}' $FILENAME >> $NEWFILENAME

grep --color -v "t/o" resultsCleaned.txt > completedResultsCleaned.txt
 
