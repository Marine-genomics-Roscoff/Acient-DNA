qstat | grep " R " | cut -f 1 -d " " | while read jobID; do resource=`qstat -f $jobID | grep "Resource_List.walltime\|Resource_List.ncpus\|Job_Owner" | sed "s/^[ ]\+//" | tr '\n' ' '`; echo "$resource $jobID" ; done

