grep "^#started\|^#finished" ../logs/*.[0-9]* | sed "s/:#started /@:#started /" | tr '\n' '$' | tr '@' '\n' | awk -F "$" '{print $2$1}' | grep "finished.*started" | sed "s/:#/"$'\t'"/g" | sed "s/-/ /g" | sed "s/:/ /g" | sed "s/finished //" | sed "s/started //" | awk -F"\t" '{total=mktime($2) - mktime($3); print $1" : "$3" -> "$2" - "strftime("%H:%M:%S" ,mktime($2) - mktime($3))}' | awk -F"[: ]" '{print $0" = "(($17 * 60 * 60) + ($18 * 60) + ($19))/ 60" hours"}'
