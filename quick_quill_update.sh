#!/bin/bash
## quick quilll update

#---
## show help
#---
function show_usage() {
usage="Usage: $(basename $0) -v version spells

-v|--version\t\t specify version to upgrade
-h|--help\t\t show this help
"
echo -e "$usage"
}

TEMP_OPTS=$(getopt -o 'hv:' -l 'version:,help' \
-n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then  show_usage; exit 3; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS


# process params
while true; do
  case "$1" in
   "-h"|"--help")     show_usage;      exit 2 ;;
   "-v"|"--version")  version="$2"; shift 2;;
   --)                shift;           break ;;
    *) show_usage;      exit 3 ;;
  esac
done

echo $version

for spell in $@; do


quill -u $spell <<<"00y$version
nabd"

done