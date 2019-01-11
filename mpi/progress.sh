jobID=$1
hitDir=$2
seqDir=$3
list=$4
gridRunTimeScript=$5
resume=$6

j=1

while read i;
do
   seq=""
   pos=1

   if [ -f ${hitDir}/${i}.blast.out ]
   then
      seq=`tail -n1 ${hitDir}/${i}.blast.out | cut -f 1`;
   fi

   if [ "$seq" == "" ]
   then
      echo -n ""
   else
      pos=`grep -m1 -n "${seq}" ${seqDir}/${i} | cut -d ":" -f 1 | awk '{print ($1 +1)/2}'`;
      total=`cat ${seqDir}/${i} | wc -l | awk '{print $1 /2}'`;
      jID=`echo "${jobID}" | sed "s/#/${j}/" `
      seconds=`bash ${gridRunTimeScript} ${jID}`;
      running=`echo "${seconds}" | cut -f 2`
      seconds=`echo "${seconds}" | cut -f 1`
      hours=`echo ${seconds} | awk '{print ($1)/(60 * 60)}'`;
      if [ "$hours" == "0" ] || [ "$running" == "0" ]
      then
         echo "${pos} ${total} ${hours} ${i} ${seq} ${jID}" | awk '{print "file:" $4 " " $1 "/" $2 " seq:"$5" - " $3 " hours_consumed jobId:"$6}';
      else
         echo "${pos} ${total} ${hours} ${i} ${seq} ${jID}" | awk '{print "file:" $4 " " $1 "/" $2 " seq:"$5" - "$2 * $3 / ($1 * 24) " days_needed " $3 " hours_consumed " ($2 * $3 / $1) -$3 " hours_left jobId:"$6}';
      fi
   fi

   if [ -n "$resume" ]
   then
      echo "#resume ${seqDir}/${i} ${pos} to ${resume}/${i}"
      awk -v pos=${pos} -v seqDir=${seqDir} -v i=${i} 'NR >= (2 * pos) -1' ${seqDir}/${i} > ${resume}/${i}
   fi

   let j+=1
done < ${list}

if [ -n "$resume" ]
then
   ls -C1 ${resume}/ | sort > ${resume}/${list}
fi
