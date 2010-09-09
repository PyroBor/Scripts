#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## somekind of mirror checking script. far from functional
#---
mirrors_file=

while [[ "$1" == -* ]] # 2) params
do
case "$1" in
   "-r"|"--resolve-ip")  RESOLVE_IP_TEST="yes";          shift  ;;
   "-f"|"--file")        mirrors_file=$2;                shift 2 ;;
   "-s"|"--spider-check") WGET_SPIDER_TEST="yes";        shift ;;
  esac
done

for mirror_url in $(grep -o -E "(http|ftp).*" $mirrors_file); do

  ## resolve the host test
  if [[ $RESOLVE_IP_TEST == yes ]]; then
  mirror_host=$(sed -e s#ftp:\/\/##g -e s#http:\/\/##g -e s#\/.*## <<< $mirror_url)
    resolveip $mirror_host
    rc=$?
    if [[ $rc == 2 ]]; then
      # delete that line!
    fi
  fi

  #gaze spider test
  if [[ $WGET_SPIDER_TEST == yes ]]
    wget -q --spider mirror_url
    rc=$?

    if [ $rc != 0 ]; then
      # delete that line!
    fi
  fi

done