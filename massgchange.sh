#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## one mass change in grimoire i needed...
## just in case i will need something like that in the furure
#---

details_w_sigfile=$(grep -r -E "^ *SOURCE2=.*[(sig)|(asc)|(sign)]$" ./* | cut -f1 -d:)

for details in $details_w_sigfile; do
  section=$(echo $details |cut -f2 -d/)
  spell=$(echo $details |cut -f3 -d/)
  sigignore=$(grep -r -E "^ *SOURCE2_IGNORE=" $details)
  if [[ $sigignore == "" ]]; then
#      sed -i -e "s/^ *SOURCE2=.*[(sig)|(asc)|(sign)]$/&\n  SOURCE2_IGNORE=signature/" $details
#      sed -i "1 s%^.*$%2010-06-15 Bor Kraljič <pyrobor@ver.si>\n\t* DETAILS: added SOURCE2_IGNORE for signature\n\n&%" ./$section/$spell/HISTORY
#     echo "\t* DETAILS: added SOURCE2_IGNORE for signature"
    
    echo $details
  fi
  unset sigignore
done
