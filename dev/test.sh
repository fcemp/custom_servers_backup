#!/bin/bash
var="$(cat single.yml)"
outfile="test.yml"
	spacing="    "
echo "TO_KEY" > ${outfile}
while read line; do
	echo "${spacing}${line}" >> ${outfile}
done < <(echo "$var")
