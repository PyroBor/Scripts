#!/bin/bash
# e v math.h je prekratek, zato poberimo prvih par
# tisoč decimalk z interneta in počistimo
tempfajl="/tmp/numbers-temp"
timetokill="no"
function delaj {
e=$(wget -O - http://www-groups.dcs.st-and.ac.uk/~history/HistTopics/e_10000.html 2>/dev/null | sed -n '/2.718/,/905198/ { s,2.718,2718,; s,\s*,,g; p}' | tr -d '\n')
i=$1

# potujoče okno desetih števk
while true; do
  num=${e:$i:31}
   if [[ ${#num} != 31 ]]; then
      echo reached end of known e digits
      echo $i
      break
   fi

# v coreutils je program factor, ki za podano številko vrne faktorje
# rezultat shranimo v polje in če je njegovih članov preveč,
# vemo da nimamo praštevila (število članov == število faktorjev+1)
  nfactors=( $(factor $num) )
   if [[ ${#nfactors[@]} == 2 ]]; then
      echo $i:$num
		touch $tempfajl
		break
   fi
    ((i=i+4))
done
}
delaj 0 &
delaj 1 &
delaj 2 &
delaj 3 &
until [[ -f $tempfajl ]]; do
	sleep 1
done

kill "%delaj 0" 2>/dev/null
kill "%delaj 1" 2>/dev/null
kill "%delaj 2" 2>/dev/null
kill "%delaj 3"  2>/dev/null


rm $tempfajl
# wait "%delaj 0" || wait "%delaj 1"
# echo "ali ali?"


# Poženemo in preverimo rezultat:
# 
# ...
# 99:7427466391
# navaden@lynxlynx ~ 128 $ factor 7427466391
# 7427466391: 7427466391
# 
# Naslednji izziv je pi, algoritem pa enak.
# 
# ...
# 4:5926535897
# navaden@lynxlynx ~ 0 $ factor 5926535897
# 5926535897: 5926535897