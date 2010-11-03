#!/bin/bash
#---
## quick quilll update
## simple script to automate mass updates using quill
## atm only works with hashhes... or upstrem signed sources
## be sure that all spells are the same "work flow"
##
## TODO
## add more switches.
##   copy from could be usefull to change to git gr
## added option ti work with gpg signed
##   password is problematic...
#---

#---
## show help
#---
function show_usage() {
usage="Usage: $(basename $0) -v version spells

-v|--version\t\t specify version to upgrade
-k|--kde4\t\t update all kde4 spells (check script for list)
-h|--help\t\t show this help
"
echo -e "$usage"
}

#---
## list of all kde4_spells
#---
kde4_spells="kdepimlibs4 kde4-l10n kdeaccessibility4 kdeadmin4 kdeartwork4"
kde4_spells="$kde4_spells kdebase4-runtime kdebase4 kdebase-workspace4 kdebindings4"
kde4_spells="$kde4_spells kdeedu4 kdegraphics4 kdelibs4 kdemultimedia4 kdenetwork4"
kde4_spells="$kde4_spells kdeplasmoids4 kdesdk4 kdetoys4 kdeutils4 oxygen-icons kdewebdev4 kdegames4"
#kde4_spells="$kde4_spells kdepim4 kdepim4-runtime"
# uncoment this line when kdepim and kdepim-runtime get back with normal relases
# it suppose to be with kde 4.6

TEMP_OPTS=$(getopt -o 'khv:' -l 'kde4,version:,help' \
-n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then  show_usage; exit 3; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS



# process params
while true; do
  case "$1" in
   "-h"|"--help")     show_usage;                    exit 2  ;;
   "-v"|"--version")  version="$2";                  shift 2 ;;
   "-k"|"--kde4")     update_spells="$kde4_spells";  shift   ;;
   --)                shift;                         break   ;;
    *)                show_usage;                    exit 3  ;;
  esac
done

echo $version
if [[ $update_spells == "" ]]; then
  update_spells="$@"
fi

#---
# current quill work flow
#---
# (0)  The grimoire (copy from)
# (0)  Update the spell to a newer version
# Do you want to update x.y.z? [y] y
# $version
# Do you want to add SECURITY_PATCH? [n] n
# (a)  Copy it under QUILL_GIT_DIR
# (b)  Copy it back to the grimoire
# (d)  Quit  -> next spell


for spell in $update_spells; do

quill -u $spell <<<"00y$version
nabd"

done

echo "'scribe reindex-version' is maybe needed before the cast..."
