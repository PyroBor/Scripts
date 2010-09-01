#!/bin/bash

## fastcommit.sh
# commits changes with commit per spell
# it uses the first comment in HISTORY file for main commit msg
# others are added in detailed description

## TODO
# - improve multiline commits
# - handle changes that aren't spell changes but the change is
#   is described in ChangeLog
# - loading whole sorcery functions is really a bit overkill... maybe remove colors...


. /etc/sorcery/config # needed for colors in one message line. A bit overkill. But why not :P

TEMP_DIR="/tmp/$$-fastcommit"
mkdir $TEMP_DIR

changed_spells_path_list=$(git diff --dirstat=0 |sed -e "s/.*% //")

for changed_spell_path in $changed_spells_path_list; do
  changed_spell=$(basename $changed_spell_path)

  ####### part to get info from history
  # lets move the last history entry in one file for easier manipulation
  # get the first empty line
  grep_for_end=$(grep -m1 -n "^$" $changed_spell_path/HISTORY);
  number_of_lines=${grep_for_end%%:*}
  # we dont need the empty line at the end
  number_of_lines=$(( $number_of_lines - 1 ))

  # now lets move the important part
  temp_history=$TEMP_DIR/history
  head -n $number_of_lines $changed_spell_path/HISTORY > $temp_history
  # we dont really need the first line... we only need the changes
  sed -i '1d' $temp_history && number_of_lines=$(( $number_of_lines - 1 ))
  # the first change in HISTORY. It also includes ":" (first change the important change)
  first_change_in_history=$(grep -E -m1 -o  ":.*" "$temp_history")
  first_file_changed=$(grep -E -m1 -o  ".*:" "$temp_history")
  first_file_changed=${first_file_changed##* }
  # we don't need main change. since we will add it saperatly
  sed -i '1d' $temp_history && number_of_lines=$(( $number_of_lines - 1 ))
  temp_commit_msg=$TEMP_DIR/commit_msg
  # main line SPELL: first change
  echo "${changed_spell}${first_change_in_history}" > $temp_commit_msg

  # do we have any more lines in temp_history? lets mentioned them in commit msg
  if [[ $number_of_lines -gt "0" ]]; then
    echo  >> $temp_commit_msg # second line is empty:)
    sed -i -e 's/^[\t]*//' $temp_history # remove leading tab
    # if first isn't * there is need to add the first file change
    if [[ $(head -c 1 $temp_history) != "*" ]]; then
      sed -i "1 s/^[ ]/* $first_file_changed/" $temp_history
    fi
    # move history to commit msg
    cat $temp_history >> $temp_commit_msg
  fi
  
  ####### stage the changes
  # only works with adding files. not with removing... 
  git add $changed_spell_path/*
  # lets get list of removed files in our spell
  removed_files_in_spell=$(git diff --summary |grep -E -o "$changed_spell_path.*")
  # lets remove the files
  for removed_file in $removed_files_in_spell; do
    git rm -q $removed_file
  done

  # now we have staged all changes in path and we can commit
  git commit -q -F "$temp_commit_msg"
  message "${MESSAGE_COLOR}Commited - ${SPELL_COLOR}${changed_spell}${FILE_COLOR}${first_change_in_history}${DEFAULT_COLOR}"
done

message "${MESSAGE_COLOR}Use ${SPELL_COLOR}git log -p origin..@{0}${MESSAGE_COLOR} to check changes before pushing them...${DEFAULT_COLOR}"

rm -rf $TEMP_DIR
