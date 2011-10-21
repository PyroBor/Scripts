#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## copy spells from git to grimoire
## or back
##
#---

#---
## show help
#---
function show_usage() {
usage="Usage: $(basename $0) spell(s)
-r, --reverse\t copy spells from grimoire to git
\t-h, --help\t show this help"

echo -e "$usage"
}

TEMP_OPTS=$(getopt -o 'rh' -l 'reverse,help' -n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then  show_usage; exit 3; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS


while true; do
  case "$1" in
   "-r"|"--reverse")  mode="reverse";     shift ;;
   "-h"|"--help")     show_usage;      exit 2 ;;
   --)                shift;           break ;;
   -*)                 show_usage;      exit 3 ;;
  esac
done


copy_spells="$@"

if [[ $mode == "reverse" ]]; then
  for spell in $copy_spells; do
    quill -u $spell <<<"0ad" &> /dev/null &&
    echo "Copied $spell from grimoire to git with quill"
  done
else
  for spell in $copy_spells; do
    quill -u $spell <<<"1bd" &> /dev/null &&
    echo "Copied $spell from git to grimoire with quill"
  done
fi
