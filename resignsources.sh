#!/bin/bash

. /etc/sorcery/config

# we need to be 0 for writing in /var/spool/sorcery/...
if  [  "$UID"  !=  0  ];  then
  # validate the rest of the parameters before su-ing
  PARAMS=$(consolidate_params "$@")
  run_as_root resignsources.sh "$PARAMS"
fi

. /etc/sorcery/local/guruinfo
git_dir="/home/bor/git/grimoire"
reason="history reason"
tmp_dir="/tmp/reverify"
mkdir $tmp_dir




# process the params
while [[ "$1" == -* ]] # 2) params
  do
  case "$1" in
     "-r"|"--reason") reason=$2; shift 2;;
     "-h"|"--help"|*) show_usage; exit 2 ;;
  esac
done



spells_to_fix="$@"


function edit_history_file() {
  local file_changed="$1"
  local history_line="$2"

  sed -i "1 s%^.*$%$(date +%Y-%d-%m) $GURU_NAME <$GURU_EMAIL>\n\t* $file_changed: $history_line\n\n&%" $git_dir/$section/$spell/HISTORY
}

function gpg_resign() {
  local spells_for_resign=$1
  for spell in $spells_for_resign; do
    section=$(codex_get_spell_section_name $spell)
#    echo $section
    (
      codex_set_current_spell_by_name $spell
      gpg_signature="$(basename $SOURCE).sig"

#      echo $section $spell
#     echo $gpg_signature
      rm $git_dir/$section/$spell/$gpg_signature
      gpg --detach-sign /var/spool/sorcery/$SOURCE
      mv /var/spool/sorcery/$gpg_signature $git_dir/$section/$spell/
      edit_history_file "$gpg_signature" "$reason"
    )
  done
}

function sha512_resum() {
  local spell_for_resum=$1
  local hash=$2
    section=$(codex_get_spell_section_name $spell_for_resum)
    (
    
    cd $tmp_dir
    codex_set_current_spell_by_name $spell_for_resum
    wget -q $SOURCE_URL.$hash
    hashsum_file=$SOURCE.$hash
    upstream_hash=$(cut -d" " -f1 < $hashsum_file)
    calc_hash=$(md5sum /var/spool/sorcery/$SOURCE |cut -d" " -f1)
    if [[ $calc_hash == $upstream_hash ]]; then
      message "source verified: editing DETAILS"
      calc_sha512=$(sha512sum /var/spool/sorcery/$SOURCE | cut -d" " -f1)
      sed -i "s/SOURCE_HASH=sha512:.*/SOURCE_HASH=sha512:$calc_sha512/" $git_dir/$section/$spell_for_resum/DETAILS
      edit_history_file "DETAILS" "fixed sha512 (sources checked with upstream $hash)"
    else
      echo "source not verified"
    fi
    
    )

}

function resum_spells() {
  for spell in $spells_to_fix; do
    sha512_resum $spell md5
  done
}

resum_spells

#gpg_resign
cd
rm -rf $tmp_dir