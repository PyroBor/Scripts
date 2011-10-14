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
usage="Usage: $(basename $0) spells
Must use -v or -e to really do something.

-v, --version\t\t specify version to upgrade
-k, --kde4\t\t update all kde4 spells (check script for list)
-e, --history\t\t add history entry
-p, --patchlevel\t\t increase patchlevel for all the spells
-s, --signature\t\t convert to upstream gpg signature checking
-g, --git-changes\t apply history to all spells changed in grimoire (current dir)
\t\t\t usefull when there was some massive change in grimoire
-h, --help\t\t show this help
"
echo -e "$usage"
}

#---
## list of all kde4_spells
#---
kde47_core="kde4-l10n kdebase4  kdebase4-runtime kdebase-workspace4 kdeaccessibility4 kdeadmin4 kdeartwork4"
kde47_core="$kde47_core kdelibs4 kdemultimedia4 kdegames4 kdenetwork4 kdepim4 kdepim4-runtime kdepimlibs4"
kde47_core="$kde47_core kdeplasmoids4 kdesdk4 kdetoys4 kdeutils4 kdewebdev4 oxygen-icons"
kde47_spells="$kde47_core blinken cantor kde-wallpapers gwenview4 kalgebra kalzium kamera kanagram kate kbruch kcolorchooser"
kde47_spells="$kde47_spells  kdegraphics-strigi-analyzer kdegraphics-thumbnailers "
kde47_spells="$kde47_spells  kgamma kgeography khangman kig kimono kiten klettres kmplot kolourpaint konsole"
kde47_spells="$kde47_spells korundum kross-interpreters kruler ksaneplugin ksnapshot kstars ktouch kturtle kwordquiz"
kde47_spells="$kde47_spells libkdcraw4 libkdeedu libkexiv24 libkipi4 libksane marble mobipocket okular  parley"
kde47_spells="$kde47_spells perlkde perlqt4 pykde4 qtruby qyoto rocs smokegen smokekde smokeqt step svgpart"


TEMP_OPTS=$(getopt -o 'e:kghv:ps' -l 'git-changeshistory:,kde4,version:,help,patchlevel,signature' \
-n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then  show_usage; exit 3; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS



# process params
while true; do
  case "$1" in
   "-h"|"--help")     show_usage;                    exit 2  ;;
   "-g"|"--git-changes") git_changes="yes"; shift            ;;
   "-e"|"--history")  history_line="$2"; mode="history_edit"; shift 2 ;;
   "-v"|"--version")  version="$2"; mode="version_bump";  shift 2 ;;
   "-s"|"--signature") mode="upstream_sig" ; shift ;;
   "-k"|"--kde4")     spells="$kde47_spells";         shift   ;;
   "-p"|"--patchlevel") mode="increase_patchlevel"; shift ;;
   --)                shift;                         break   ;;
    *)                show_usage;                    exit 3  ;;
  esac
done

if [[ $spells == "" ]]; then
  spells="$@"
fi

# just simple functions so the code is nicer

#---
## quill_version_bump
#---
# (1)  Git (copy from)
# (0)  Update the spell to a newer version
# Do you want to update x.y.z? [y] y
# $version
# Do you want to add SECURITY_PATCH? [n] n
# (a)  Copy it under QUILL_GIT_DIR
# (b)  Copy it back to the grimoire
# (d)  Quit  -> next spell
function quill_version_bump() {
  quill -u $spell <<<"10y$version
nabd"
}

#---
## quill_history_edit
#---
# (1)  Git (copy from)
# (1)  Add arbitrary HISTORY entries
# $history_line What do you want to add?
# (blank line) What do you want to add? 
# (n)   Do you want to review the HISTORY changes? [n]
# (a)  Copy it under QUILL_GIT_DIR
# (b)  Copy it back to the grimoire
# (d)  Quit  -> next spell
function quill_history_edit() {
  quill -u $spell <<<"11$history_line

nabd"
}

#---
## quill_increase_patchlevel
#---
# (1)  Git (copy from)
# (2)  Increment/add PATCHLEVEL or SECURITY_PATCH
# Do you want to do it for X.Y.Z? [y] y
# Do you want to increment/add PATCHLEVEL? [n] y
# Do you want to increment/add SECURITY_PATCH? [n] n
# (a)  Copy it under QUILL_GIT_DIR
# (b)  Copy it back to the grimoire
# (d)  Quit  -> next spell
function quill_increase_patchlevel() {
  quill -u $spell <<<"12yynabd"
}

#---
## quill_convert_to_upstream_signature
#---
#         (1)  QUILL_GIT_DIR
#         (3)  Switch to upstream gpg verification
# Do you want to do it for 1.3.3e? [y]y
# Is ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.3e.tar.bz2.asc the proper signature url? [y] y
# Is the appropriate keyring already in the grimoire? [n] n
# Is there a more complete keyring available? [y] n
# Do you want to remove old signatures (if there are any)? [y]
# Do you want to do it interactively? [y] n
# Do you want to try if the new verification system works? [y] n (We will copy it and use hashcheck script to test)
# (a)  Copy it under QUILL_GIT_DIR
# (b)  Copy it back to the grimoire
# (d)  Quit  -> next spell
function quill_convert_to_upstream_signature() {
  quill -u $spell <<<"13yynnynnabd"
}

if [[ "$mode" == "version_bump" ]]; then

  for spell in $spells; do
    quill_version_bump
  done
  echo "'scribe reindex-version' is maybe needed before the cast..."

elif [[ "$mode" == "history_edit" ]]; then

  if [[ $git_changes == "yes" ]]; then
    changed_spells_path_list=$(git diff --dirstat=0 |sed -e "s/.*% //")
    for changed_spell_path in $changed_spells_path_list; do
      spell=$(basename $changed_spell_path)
      quill_history_edit
    done
  else
    for spell in $spells; do
      quill_history_edit
    done 
  fi
  
elif [[ "$mode" == "increase_patchlevel" ]]; then

  for spell in $spells; do
    quill_increase_patchlevel
  done
  
elif [[ "$mode" == "upstream_sig" ]]; then

  for spell in $spells; do
    quill_convert_to_upstream_signature
  done

else

  echo "this is script error... "
  
fi
