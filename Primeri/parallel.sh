#!/bin/bash

function process {
st_proces=$1
cakanje=$2
    echo "to je proces st. $st_proces in bo spal $cakanje sekund"
    sleep $cakanje
    echo "proces st. $st_proces je nehal spat in je končal"
}

echo "zacetek"
process 1 3 
process 2 15 &
process 3 20 &
jobs
wait "%process 2"
kill "%process 3"
echo "konec... mora vsi procesi končat do tuki"