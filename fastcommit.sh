#!/bin/bash

## fastcommit.sh
# commits changes with commit per spell
# it uses the first comment in HISTORY file for commit msg

. /etc/sorcery/config # needed for colors in one message line. A bit overkill. But why not :P

changed_spells_path_list=$(git diff --dirstat=0 |sed -e "s/.*% //")

for changed_spell_path in $changed_spells_path_list; do
  changed_spell=$(basename $changed_spell_path)
  # getthe first change in HISTORY. It also includes ":"
  first_change_in_history=$(grep -E -m1 -o  ":.*" "$changed_spell_path/HISTORY")

  # only works with adding files. not with removing... 
  git add $changed_spell_path/*
  
  # lets get list of removed files in our spell
  removed_files_in_spell=$(git diff --summary |grep -E -o "$changed_spell_path.*")
  # lets remove the files
  for removed_file in $removed_files_in_spell; do
    git rm -q $removed_file
  done

  # now we have staged all changes in path and we can commit
  git commit -q -m "${changed_spell}${first_change_in_history}"
  message "${MESSAGE_COLOR}Commited - ${SPELL_COLOR}${changed_spell}${FILE_COLOR}${first_change_in_history}${DEFAULT_COLOR}"
done

message "${MESSAGE_COLOR}Use ${SPELL_COLOR}git log -p origin..@{0}${MESSAGE_COLOR} to check changes before pushing them...${DEFAULT_COLOR}"
