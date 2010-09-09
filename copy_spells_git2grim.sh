#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## copy spells from git to grimoire
##
## TODO
## - add param to set git_dir &grimoire
## - maybe remove run_as_root since is only from patch sorcery bug #15421
## - option to copy from grimoire to git_dir
#---

. /etc/sorcery/config
if  [  "$UID"  !=  0  ];  then
  PARAMS=$(consolidate_params "$@")
  run_as_root copy_spells_git2grim.sh "$PARAMS"
fi


copy_spells="$@"
git_dir="/home/bor/git/grimoire"
grimoire_path="/var/lib/sorcery/codex/test"

for spell in $copy_spells; do
  section=$(codex_get_spell_section_name $spell)
  cp -f $git_dir/$section/$spell/* $grimoire_path/$section/$spell/
  message "copied $git_dir/$section/$spell/* $grimoire_path/$section/$spell/"
done
