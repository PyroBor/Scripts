#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
#---
for i in /usr/bin/*; do
[[ ! -L $i ]] || continue
file $i | grep-q 32-bit && \
path_file=$(grep -l $i /root/all-logs/*| head -n1) && \
path_file1=${path_file##*/} && path_file2=${path_file1%-*} && echo "$i from spell: $path_file2"
done
