#!/bin/bash
bla="neki"

echo "bla pred subshell: $bla"
(
  bla="$bla pa se neki"
  ena=1
  dva=1
  if [[ $ena == $dva ]];then
    true
  else
    false
  fi
  
)
echo $?
echo "bla po subshell: $bla"