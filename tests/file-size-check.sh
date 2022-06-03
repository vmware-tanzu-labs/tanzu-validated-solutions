#!/bin/bash

MAX_FILE_SIZE=5000
FILES=$1
FAILED=0

for F in $FILES; do 
	size=$(du -k $F | cut -f1)
    	if [ $size -ge $MAX_FILE_SIZE ]; then
	    FAILED=1
	    echo "$F exceeds maximum file size."
    	fi
done

if [ $FAILED -ne 0 ]; then
	exit -1
fi;