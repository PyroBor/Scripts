#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## find Nonexisting Dependencies
##
## Checks all the DEPENDS files in grimoire and looks if any spell depends
## on something (spell or provider) that doesn't exists.
##
## TODO
## * improve sub_depends handling
#---

tmp_file=/tmp/spellist.$$
grimoire_dir=$(pwd)

# paste data even if we interupt withc ctrl-c :)
trap 'message "${PROBLEM_COLOR}control-c${DEFAULT_COLOR}"; clean_exit 1' INT

# let's get sorcery goodies
. /etc/sorcery/config

function clean_exit() {
  rc=$1
  rm $tmp_file

  # report spells with problems
  if [[ $depends_bug -lt 1 ]];then
    echo "No bogus dependency found in $grimoire_dir"
    rc=${rc:-0}
  else
    echo "The following spells have bogus dependency in their DEPENDS ($(echo $spells_with_bugs|wc -w)):"
    echo "$spells_with_bugs"
    rc=${rc:-1}
  fi
  exit $rc
}

#---
## Shows usage
#---
function show_usage() {
  exit_code=${1:-1}
  usage="Usage: $(basename $0) options
  
Searches for all the spells used in DEPENDS files in path
and checks if they are existing.

Options:
\t-g, --grimoire\tset grimoire path [$grimoire_dir]
\t-h, --help\t show this help"
  echo -e "$usage"
  exit $exit_code
}


#---
## process the params
#---
TEMP_OPTS=$(getopt -o 'g:h' -l 'grimoire:,help' -n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then  show_usage; exit 3; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS

while true; do
  case "$1" in
   "-g"|"--grimoire")  grimoire_dir=$2; shift 2 ;;
   "-h"|"--help")     show_usage;      exit 2 ;;
   --)                shift;           break ;;
   *)                 show_usage;      exit 3 ;;
  esac
done


echo "Temp file is: $tmp_file"

# first we need everything that has depends line in DEPENDS file
find $grimoire_dir/ -iname DEPENDS -exec grep -H -E "depends[[:space:]]+[\"\'a-Z0-9_-]+([[:space:]]|$)" {} \; >> $tmp_file &&
echo "temp file filled... Lets clean it"
# lets get rid of lines that are comments
sed -r -i "/[[:space:]]*#/d" $tmp_file &&
# change more spaces or tab to single space
sed -r -i "s/[[:space:]]+/ /g" $tmp_file &&
# change : to " " so we will get the file simpler. 
sed  -r -i "s/:/ /g"  $tmp_file &&
# remove \ 
sed  -i 's/\\/ /g' $tmp_file &&

# nasty hack to remove "BLAAA BLAAA" -> spaces_var...
# I hope only sub dependencies and comments are like that
# BUT IT WOULD NEED IMPROVEMENT (one for "BLA BLA" and one for 'BLA BLA')
# this brings problems if spell is quoted. But there is only one such spell (e-emotion)
# sed -r -i 's,([^"]*)"([A-Z1-9\ ]+)"([^"]*),\1SUB_DEPENDENCIES\3,g' $tmp_file &&
# sed -r -i "s,([^']*)'([A-Z1-9\ ]+)'([^']*),\1SUB_DEPENDENCIES\3,g" $tmp_file &&

# cat $tmp_file
echo "lets check spells"
while read file depends spell leftover1 leftover2 leftover3; do

  # we need one extra hack for spells that have strange DEPENDS lines like:
  #   gnutls) depends gnutls "--with-ssl=gnutls"
  # now should work correctly
  if [[ $spell == depends ]]; then
    depends=$spell
    spell=$leftover1
  fi

  # depends must be known now!
  if [[ ! $depends =~ (depends) ]];then
    continue
  fi


  
  # sub dependencies bla/bla/bla depends -sub spaces_var spell blabla
  #                  file depends  spell leftover1 leftover2 leftover3
  # not working correctly
   if [[ $spell == "-sub" ]]; then
     depends="sub_depends"
     spell=$leftover2
     continue
   fi
   
   if [[ $spell == "sub_depends" ]];then
     depends="sub_depends"
     spell=$leftover1
     continue
   fi

  # just to be sure that everything is ok now
  if [[ $spell == depends ]]; then
    echo "Something went wrong with script ($(basename $0))! Problem was caused by ${file/$grimoire_dir/}"
    continue
  fi

#    if [[ $spell == "SUB_DEPENDENCIES" ]];then
#      spell=$leftover1
#    fi

  # lets clean spell now
  if [[ $spell == "\$SPELL" ]]; then
      spell=$(echo ${file/$grimoire_dir/}|cut -d/ -f3)
  fi
  spell=${spell//\"/}
  spell=${spell//\'/}
  


  # lets first check if "spell" is provider
  CANDIDATES=$( find_providers $spell)
  if [[  $CANDIDATES ]] ; then
    continue
  fi
  # lets check if spell it is existing spell
  # also we don't need that annoying output if spell doesn't exist
  if codex_does_spell_exist $spell >> /dev/null; then
    continue
  fi
   
  bogus_spell=$(echo ${file/$grimoire_dir/}|cut -d/ -f3)

  echo "Spell $bogus_spell $depends on $spell that doesn't exist"
  
  # lets make a list of broken spells.
  spells_with_bugs="$spells_with_bugs $bogus_spell"
  depends_bug=1
   
done < $tmp_file

# now lets exit script
clean_exit

