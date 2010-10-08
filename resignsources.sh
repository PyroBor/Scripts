#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## Resings sources in grimoire. Can use upstream md5 to check if
##
## WIP
## TODO
## - add params to decide what to do :)
## - give use more information
## - modify the use of --reason for both options. resing or resum
## - improve history edit. maybe we can source quill
## - rename to reverify_sources
## - investigate spells with multiple sources...
#---

. /etc/sorcery/config

# we need to be 0 for writing in /var/spool/sorcery/...
if  [  "$UID"  !=  0  ];  then
  # validate the rest of the parameters before su-ing
  PARAMS=$(consolidate_params "$@")
  run_as_root resignsources.sh "$PARAMS"
fi

. /etc/sorcery/local/guruinfo
git_dir="/home/bor/git/grimoire"
reason=""
tmp_dir="/tmp/reverify"
upstream_hash="md5"
mkdir $tmp_dir


#---
## Shows usage
#---
function show_usage() {
usage="Usage: $(basename $0) params spells
-d|--git-dir\t\t speficy your git dir (dir to change things) [$git_dir]
-u|--upstream\t\t specify upstream hash (make sure it is source_url.hash) [$upstream_hash]
-s|--hash\t\t work with default upstream hash (md5)
-r|--reason\t\t reason for rehash/resign [$reason]
-g|--gpg\t\t gpg resign [$gpg_mode]
-h|--help\t\t show this help
"
echo -e "$usage"
}


TEMP_OPTS=$(getopt -o 'gshu:r:d:' -l 'hash,git-dir:,help,gpg,reason:,upstream:' \
-n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then  show_usage; exit 3; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS


# if someone wants to see help lets print it
while true; do
  case "$1" in
   "-h"|"--help")     show_usage;             exit 2 ;;
   "-d"|"--git-dir")  git_dir=$2;             shift 2 ;;
   "-u"|"--upstream") upstream_hash=$2; hash_mode="yes"; shift 2 ;;
   "-s"|"--hash")     hash_mode="yes";        shift;;
   "-r"|"--reason")   reason=$2;              shift 2;;
   "-g"|"--gpg")      gpg_mode="yes";          shift ;;
   --)                                shift;   break ;;
    *)                show_usage;              exit 3 ;;
  esac
done

# we cant do both modes at the same time
if [[ $hash_mode == "yes" ]]; then
  gpg_mode="no"
fi



function edit_history_file() {
  local file_changed="$1"
  local history_line="$2"

  sed -i "1 s%^.*$%$(date +%Y-%d-%m) $GURU_NAME <$GURU_EMAIL>\n\t* $file_changed: $history_line\n\n&%" $git_dir/$section/$spell/HISTORY
}

#---
## gpg resign sources and add history entery with $reason
## @param spell to resign
function gpg_resign() {
  local spell=$1
  section=$(codex_get_spell_section_name $spell)
#    echo $section
  (
    codex_set_current_spell_by_name $spell
                  ## we really neeed here basename?????
    gpg_signature="$(basename $SOURCE).sig"

#   echo $section $spell
#   echo $gpg_signature
    rm $git_dir/$section/$spell/$gpg_signature
    gpg --detach-sign /var/spool/sorcery/$SOURCE
    mv /var/spool/sorcery/$gpg_signature $git_dir/$section/$spell/
    edit_history_file "$gpg_signature" "$reason"
  )
}

#---
## checks the source with upstream hash found in SOURCE_URL.$hash
## @return 0 if source is verified with upstream hash
## @return 1 if checks fails
#--
function upstream_check() {
  local spell_to_check=$1
  local sort_of_hash=$2

  
  (
    cd $tmp_dir

    codex_set_current_spell_by_name $spell_to_check
    wget -q $SOURCE_URL.$sort_of_hash
    hashsum_file=$SOURCE.$sort_of_hash
    upstream_hash=$(cut -d" " -f1 < $hashsum_file)
                       # we need to get rid of that sum if it is there
    calc_hash=$(${sort_of_hash//sum/}sum /var/spool/sorcery/$SOURCE |cut -d" " -f1)
  
  if [[ $calc_hash == $upstream_hash ]] && [[ $upstream_hash != "" ]]; then
    message "source verified"
    true
  else
    message  "source NOT verified"
    false
  fi
  )
  return $?
      
}


#---
## resums the SOURCE_HASH with new one
#---
function sha512_resum() {
  local spell=$1

  section=$(codex_get_spell_section_name $spell)
  (
    codex_set_current_spell_by_name $spell
    calc_sha512=$(sha512sum /var/spool/sorcery/$SOURCE | cut -d" " -f1)
    # lets first fix that there shouldn't exist anymore :) ofcorse if it is there
    sed -i "s/MD5\[0\]=.*/SOURCE_HASH=sha512:$calc_sha512/" $git_dir/$section/$spell/DETAILS
    # now let (re)edit the SOURCE_HASH
    sed -i "s/SOURCE_HASH=.*/SOURCE_HASH=sha512:$calc_sha512/" $git_dir/$section/$spell/DETAILS
  )
}


function modified_details_history() {
 local spell=$1
 local history_reason=$2
 
 section=$(codex_get_spell_section_name $spell)

 sed -i "1 s%^.*$%$(date +%Y-%d-%m) $GURU_NAME <$GURU_EMAIL>\n\t* DETAILS: $history_reason\n\n&%" $git_dir/$section/$spell/HISTORY
}

#---
## one for loop to work for multiple spells
#---
function resum_spells() {
  for spell in $@; do
    upstream_check $spell $upstream_hash
    if [[ $? == 0 ]]; then
      sha512_resum $spell
                                       # this will be fixed to use $reason
      modified_details_history $spell "fixed sha512 (sources checked with upstream $upstream_hash)"
    fi
  done
}

#---
## one for loop to work for multiple spells
#---
function resign_spells() {
  for spell in $@; do
    gpg_resign $spell
  done
}

# lets do the work

if [[ $hash_mode == "yes" ]]; then
  resum_spells $@
elif [[ $gpg_mode == "yes" ]]; then
  resign_spells $@
fi


cd
rm -rf $tmp_dir