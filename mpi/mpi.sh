#!/bin/bash

export i=$1 #ignore the first $i lines 
export jobFile=$2

echo sge
export jobId=${JOB_ID}
export sshCmd=/usr/bin/ssh
echo sge

export nodeFile=.${USER}.${jobId}.mpi
echo "START $i master" $HOSTNAME "jobid" $jobId "jobfile" $jobFile "jobnode" $nodeFile
echo "NODES:"
cat $nodeFile | sort | uniq -c | sed "s/^[ ]\+//" | tr '\n' ';' 
echo; echo -

export j=0;
export k=0;
declare -A processes;
export nmachine=`cat $nodeFile | sort | uniq | wc -l`
export cpus=(`cat $nodeFile | sort | uniq -c | sed "s/^[ ]\+//" | cut -d " " -f 1`)
export machines=(`cat $nodeFile | sort | uniq`)

OIFS=$IFS;
IFS=$'\n';
export cmds=(`cat $jobFile`)
IFS=$OIFS
export ncmd=`cat $jobFile | wc -l`
let ncmd-=1

while [ $ncmd -ge 0 ]
do
   reqCPUs=`echo "${cmds[$ncmd]}" | cut -f 1`
   cmd=`echo "${cmds[$ncmd]}" | cut -f 2`
   if [ $i -le 0 ]
   then
      if [ $j -lt $nmachine ]
      then
         let cpus[$j]-=${reqCPUs}
         if [ ${cpus[$j]} -ge 0 ]
         then
            $sshCmd ${machines[$j]} "/bin/bash -c \"export pmc_job_id=${jobId}.${k}; export OUTPUT=${OUTPUT}; ${cmd}\"" &
            pid=$!
            echo "machine=[${machines[$j]}] cpu=[${cpus[$j]}] reqCPUs=[${reqCPUs}] pid=[$pid] cmd=[${cmd}] pmc_job_id=[${jobId}.${k}]"
            processes[${k}]="${pid}"
            let k+=1
            let ncmd-=1
         else
            let j+=1
         fi
      else
         break;
      fi
   fi
   let i-=1
done

echo -
echo "$k jobs running"
echo -

finished=1
while [ "${finished}" != "0" ]
do
   finished=0
   i=$k
   let i-=1
   while [ $i -ge 0 ] 
   do
      if [ "${processes[${i}]}" != "" ]
      then
         #ps aux | grep ${processes[${i}]}
         let finished+=`ps -p ${processes[${i}]} -o pid= -o comm= | wc -l`
      fi
      let i-=1
   done
#   echo -n "waiting "
   sleep 30
done

echo -
echo "END master" $HOSTNAME "jobid" $jobId "jobfile" $jobFile "jobnode" $nodeFile

