#!/bin/bash
#$ -S /bin/bash
#$ -V
#$ -cwd

#$ -q short.q
#$ -pe openmpi 100
#$ -M rocha1biologie.ens.fr
#$ -m bea
#$ -l mem_free=4G
#$ -l h_vmem=5G 

WORK_DIR="/scratch/externe/ens/frochajimenezvi/"
cd $WORK_DIR

echo sge
echo "$SGE_O_WORKDIR - $TMPDIR - $JOB_NAME - $JOB_ID"
export nodeFile=${PE_HOSTFILE}
export jobId=${JOB_ID}
export sshCmd=ssh
echo -n "" > .${USER}.${jobId}.mpi
while read host
do
   machine=`echo "$host" | cut -d " " -f 1`
   PBS_NUM_PPN=`echo "$host" | cut -d " " -f 2`

   for ncore in `seq 1 $PBS_NUM_PPN`
   do
      echo "${machine}" >> .${USER}.${jobId}.mpi
   done
done < ${nodeFile}
nodeFile=.${USER}.${jobId}.mpi
echo sge

echo ${PE_HOSTFILE}
cat ${PE_HOSTFILE} 
echo $nodeFile
cat $nodeFile

export OUTPUT=/scratch/externe/ens/frochajimenezvi/logs/$JOB_NAME.$JOB_ID.$USER.output
mpirun -np 100 /bin/bash /scratch/externe/ens/frochajimenezvi/mpi/mpi.sh 0 /scratch/externe/ens/frochajimenezvi/mpi/alpha/jobs.1.tsv 1> ${OUTPUT}.pbs 2>&1 
