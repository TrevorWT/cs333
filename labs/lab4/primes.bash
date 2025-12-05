#!/bin/bash

# Trevor Thompson tthompso
# Andrew Lam Ho alh24

PARAM="${1:-100}"

for i in $(seq 2 $PARAM) ; do 
    out=$(factor $i)
    rest="${out#*: }"
    if [[ "$rest" != *" "* ]]; then
        echo "$i"
    fi
done
