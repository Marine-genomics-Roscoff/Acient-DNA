#!/bin/bash

echo debug sge
#roscoff
blast="/scratch/externe/ens/frochajimenezvi/ncbi-blast-2.7.1+/bin/blastx"
echo "id $ARRAYID job $PBS_JOBID name $PBS_JOBNAME work $PBS_O_WORKDIR arrayID $PBS_ARRAYID"
if [ -z "$pmc_job_id" ]
then
   ARRAYID=`echo "$JOB_ID" | cut -f 2 -d "[" | cut -f 1 -d "]"`
else
   ARRAYID=`echo "$pmc_job_id" | cut -f 3 -d "."`
fi
echo debug sge

exec 3>&1 4>&2 >${OUTPUT}.${ARRAYID} 2>&1

echo -n "#started "; date '+%Y-%m-%d %H:%M:%S'

list=${1}
dbName=${2}
duration=${3}
seqDir=${4}
hitDir=${5}
cores=${6}
HOME_DIR=${7}
LOCAL_DIR=${8}

if [ -z "$LOCAL_DIR" ]
then
   LOCAL_DIR=`ls -lhta ${localDir}/* | grep $USER | rev | cut -d " " -f 1 | rev`
fi
position=$(($ARRAYID + 1))
input=`head -n $position ${list} | tail -n1`
database=`find ${LOCAL_DIR} -name "$dbName"`

if [ ! -d $LOCAL_DIR/${seqDir} ]
then
   mkdir -v $LOCAL_DIR/${seqDir} || exit 1
fi

if [ "${database}" == "" ]
then
   echo "#coping [${dbName}]"
   cp -rv $HOME_DIR/${dbName} $LOCAL_DIR  || exit 1
   echo -n "" > $LOCAL_DIR/${dbName}/end  || exit 1
   database=$LOCAL_DIR/${dbName} 
fi

database=${database}/$dbName
file="$LOCAL_DIR/${seqDir}/$input"

if [ ! -f $file ]
then
   echo "#coping [${seqDir}]"
   cp -v $HOME_DIR/${seqDir}/$input ${file}  || exit 1
   find $LOCAL_DIR/
fi

echo debug
echo file $file job $pmc_job_id user $USER host $HOSTNAME current $PWD tmp $TMPDIR db $database $input 
echo debug

while [ ! -f $LOCAL_DIR/${dbName}/end ]
do
   sleep 30
   echo -n "waiting db... "
done
echo

echo -n "#blast started "; date '+%Y-%m-%d %H:%M:%S'

#timeout $duration sleep 30  || exit 1
timeout $duration $blast -num_threads $cores -query ${file} -db ${database} -out ${file}.blast.out -max_hsps 10 -evalue 0.0000000001 -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen"
if [ ! $? == 0 ];
then
   echo "#killed";
fi

echo -n "#blast ended "; date '+%Y-%m-%d %H:%M:%S'

cp -v ${file}.blast.out $HOME_DIR/${hitDir}/ || exit 1
rm -vf ${file}.blast.out

echo -n "#finished "; date '+%Y-%m-%d %H:%M:%S'
