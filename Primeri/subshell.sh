#!/bin/bash
bla="neki"

echo "bla pred subshell: $bla"
(
  bla="$bla pa se neki"
  false
)
echo $?
echo "bla po subshell: $bla"