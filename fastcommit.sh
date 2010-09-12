#!/bin/bash
#---
## fastcommit.sh
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## commits changes with commit per spell
## it uses the first comment in HISTORY file for main commit msg
## others are added in detailed description
##
## ATM it only works with changes in spell paths section/spell/
## more is on todo list.
##
## TODO
## - improve multiline commits
## - get better check  to exclude changes in section in first loop
##   there are spells == section :(
## - move the code that could be used in both loops to functions
## - handle changes that aren't spell changes but the change is
##   is described in ChangeLog
##   * this could be a second for loop. changes could be obtained with:
##     git diff --numstat |sed -e "s/[0-9]*[\t]*[0-9]*[\t]*//"
##   * search in ChangeLog to get the right msg would be needed!
##   * also problematic would be the commit of changelog... since
##     it would be to commit per line.. For single change it would go...
##
#---


#---
## show help :P and exit with wanted exit code
#---
function show_usage() {
  exit_code=${1:-1}
  usage="Use it in top grimoire directory: $(basename $0)\n\n
commits changes with commit per spell\n
it uses the first comment in HISTORY file for main commit msg\n\n
Options:\n
\t-m|--multiline\t use all the lines in history and make multiline commits\n
\t-a|--amend\t amend costum message in commit msg\n
\t-h|--help\t show this help\n"
  echo -e $usage
  exit $exit_code
}

#---
## clean temp file of history or ChangeLog gotten from git diff
## @param file to clean
#---
function clean_history() {
  local file_to_clean=$1
  # now we have diff of changes. lets remove those lines that dont have + at the beginning
  sed -i '/^[^+]/d' $file_to_clean
  # and those + on the beginning of lines
  sed -i 's/^+//' $file_to_clean
  # that one line with ++ on beginning (from diff header)
  sed -i -e '/^++/d' $file_to_clean
  # now we really have only the part of the history that was changed

  # we can get rid of that date line & empty lines and one line
  # this will break in 2100 or if we have time machine :)
  sed -i -e '/^20/d' -e '/^$/d' $file_to_clean
}

##### lets check params
TEMP_OPTS=$(getopt -o mah --long amend,multiline,help \
-n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then
  show_usage 5
fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS

while true; do
  case $1 in
    "-m"|"--multiline") mutliline_mode=yes ; shift ;;
    "-a"|"--amend") costum_commit_msg=yes ; shift ;;
    "-h"|"--help")     show_usage 0 ;;
    --)          shift; break ;;
    *)      echo "$1 not recognized!"; show_usage 3 ;;

  esac
done

## vars
TEMP_DIR="/tmp/$$-fastcommit"
mkdir $TEMP_DIR
temp_history=$TEMP_DIR/history
temp_commit_msg=$TEMP_DIR/commit_msg


###### SPELL COMMIT LOOP
changed_spells_path_list=$(git diff --dirstat=0 |sed -e "s/.*% //")
for changed_spell_path in $changed_spells_path_list; do
  changed_spell=$(basename $changed_spell_path)
  changed_section=${changed_spell_path%%/*}

  # primitive check to not commit changes in section/bllll
  if [[ $changed_spell != $changed_section ]];then
    ##### get changes form history
    git diff $changed_spell_path/HISTORY > $temp_history

    # we use function to clean the history file now
    clean_history $temp_history

    # now we really have only changes in $temp_history
    # lets check how many lines of changes is there
    number_of_lines=$(wc -l $temp_history |cut -d' ' -f 1)

    # the first change in HISTORY that is CHANGED!
    # It also includes ":" (first change the important change)
    first_change_in_history=$(grep -E -m1 -o  ":.*" "$temp_history")
    if [[ $first_change_in_history == "" ]] ; then
      # we missed change. i guess it doesn't have file in front
      # lets remove spaces in front and add that : and first change
      first_change_in_history=": $(sed -n -e '1 s/^[\t\ ]*// p' $temp_history)"
    fi
    first_file_changed=$(grep -E -m1 -o  ".*:" "$temp_history")
    first_file_changed=${first_file_changed##* } # we remove that tab and *

    # main line SPELL: first change
    echo "${changed_spell}${first_change_in_history}" > $temp_commit_msg

    ##### multiline commits start here
    # do we have any more lines in temp_history? lets mentioned them in commit msg
    if [[ $number_of_lines -gt "1" ]] && [[ $multiline_mode == "yes" ]]; then
      # we don't need main change. since we added it saperatly
      sed -i '1d' $temp_history
      echo  >> $temp_commit_msg # second line is empty:)
      # http://www.kernel.org/pub/software/scm/git/docs/user-manual.html#creating-good-commit-messages
      sed -i -e 's/^[\t]*//' $temp_history # remove leading tab
      # if first isn't * there is need to add the first file change
      # ofcourse if we have it...
      if [[ $(head -c 1 $temp_history) != "*" ]] && [[ $first_file_changed != "" ]]; then
        sed -i "1 s/^[ ]/* $first_file_changed/" $temp_history
      fi
      #### this could get ugly if we have 2 changes that doesn't have file names in lines...

      # move history to commit msg
      cat $temp_history >> $temp_commit_msg
    fi

    ####### stage the changes
    # only works with adding files. not with removing...
    # this also adds the files that are not tracked by git in that directory
    git add $changed_spell_path/*
    # lets get list of removed files in our spell
    removed_files_in_spell=$(git diff --summary |grep -E -o "$changed_spell_path.*")
    # lets remove the files
    for removed_file in $removed_files_in_spell; do
      git rm -q $removed_file
    done

    # now we have staged all changes in path and we can commit
    git commit -q -F "$temp_commit_msg"

    # do we want to add any costum msg in commit ?
    if [[ $costum_commit_msg == "yes" ]]; then
      git commit -q --amend
    fi
    # we commit quietly but lets use oneline log to show what we commited
    # this will show us our last commit in nice oneline form.
    git log --oneline -1

    #lets clean temp files
    rm $temp_commit_msg
    rm $temp_history
  fi
done


##### end part
if [[ $(git log origin..@{0}) == "" ]];then
  echo "Nothing is commited."
else
  echo "Use 'git log -p origin..@{0}' to check changes before pushing them..."
fi

rm -rf $TEMP_DIR
