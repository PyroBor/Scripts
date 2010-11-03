#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## Prepares info of spell for wiki
#---

# let's get sorcery goodies
. /etc/sorcery/config

## mass info from spells

for spell in "$@"; do
  (
   codex_set_current_spell_by_name $spell
   ########## edit this line
   message "|| [[http://www.google.com/search?q=$spell|$spell]] || $VERSION || $WEB_SITE ||  ||"
   #########
  )
done