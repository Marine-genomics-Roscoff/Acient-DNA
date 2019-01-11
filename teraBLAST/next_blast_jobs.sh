#!/bin/bash

tries=$1
tolerance=$2
qtd=$3
maxJobs=$4

if [ "$tolerance" == "" ]
then
   tolerance=0
fi

if [ "$tries" == "" ]
then
   tries=1
fi

if [ "$qtd" == "" ]
then
   qtd=20
fi

if [ "$maxJobs" == "" ]
then
   maxJobs=20
fi


echo "tolerance $tolerance tries $tries qtd $qtd maxJobs $maxJobs"

cd /scratch/externe/ens/frochajimenezvi/mpi/alpha
for k in `seq 1 $tries`
do

jobs=`qstat | grep ${USER:0:10} | grep "^[0-9]" | grep -v " qw " | wc -l`

if [ $jobs -le $tolerance ]
then
   echo "running..."
   cat /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.[0-9]* > /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.running
   echo "doning..."
   ls -lht ~/hits/2/*.blast.out | rev | cut -d "/" -f 1 | cut -d "." -f 3- | rev > /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.done
   echo "candidating..."
   ls -c1 /scratch/externe/ens/frochajimenezvi/seqs/2/*.fna | rev | cut -d "/" -f 1 | rev | sort | grep -v -F -f /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.done | grep -F -v -f /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.running > /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.candidates
   echo "listing..."

   rm /scratch/externe/ens/frochajimenezvi/mpi/alpha/*.list /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.splitted.*
   qtdJobs=$(($qtd * $maxJobs))
   head -n $qtdJobs /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.candidates > /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.candidates.tmp 
   split -l $qtd /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.candidates.tmp list.splitted.
   rm /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.[0-9] /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.[0-9][0-9]
   rm /scratch/externe/ens/frochajimenezvi/mpi/alpha/jobs.[0-9].tsv /scratch/externe/ens/frochajimenezvi/mpi/alpha/jobs.[0-9][0-9].tsv
   rm /scratch/externe/ens/frochajimenezvi/mpi/alpha/pbs_search_sub.[0-9].sh /scratch/externe/ens/frochajimenezvi/mpi/alpha/pbs_search_sub.[0-9][0-9].sh

   i=0
   while read list
   do
      mv -v ${list} /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.$i
      numRows=`cat /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.$i | wc -l`
      for j in `seq 1 ${numRows}`; 
      do 
         head -n1 /scratch/externe/ens/frochajimenezvi/mpi/aux/jobs.tsv | sed "s/@/${i}/g" >> /scratch/externe/ens/frochajimenezvi/mpi/alpha/jobs.$i.tsv; 
      done
      let i+=1
   done < <(ls -C1 /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.splitted.* | sort | head -n $qtd)

#   qtd=20;for i in `seq 0 19`; do j=$((($i*${qtd}) + ${qtd})); echo "$j $i"; head -n $j /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.candidates | tail -n ${qtd} > /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.$i; done

   echo "submiting..."
   let maxJobs-=1
   for i in `seq 0 $maxJobs`; 
   do 
      cat /scratch/externe/ens/frochajimenezvi/mpi/aux/pbs_search_sub.sh | sed "s/@/${i}/g" > /scratch/externe/ens/frochajimenezvi/mpi/alpha/pbs_search_sub.$i.sh;
      echo qsub /scratch/externe/ens/frochajimenezvi/mpi/alpha/pbs_search_sub.$i.sh; 
      if [ ! $? -eq 0 ]
      then
         rm -v /scratch/externe/ens/frochajimenezvi/mpi/alpha/list.$i
      fi
   done
   break
else
   if [ $k -gt 1 ]
   then
      echo -n "trying $k... "
      sleep 900
   fi
fi

done
